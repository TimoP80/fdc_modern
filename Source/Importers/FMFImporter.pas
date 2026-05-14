(*
  FMF Import Parser for Fallout Dialogue Creator
  Parses .fmf (Fan Made Fallout) dialogue script files from older
  versions of the dialogue creator tool and creates TDialogueProject nodes.
*)

unit FMFImporter;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.StrUtils, System.IOUtils, System.Math,
  uDialogueTypes;

type
  TFMFImportResult = record
    Success: Boolean;
    Errors: TStringList;
    WarningCount: Integer;
    NodeCount: Integer;
    Project: TDialogueProject;
  end;

  TFMFImporter = class
  private
    FLines: TStringList;
    FPos: Integer;
    FProject: TDialogueProject;
    FErrors: TStringList;
    FWarnings: Integer;
    FNodeMap: TDictionary<string, TDialogueNode>;
    FTempSkillChecks: TList<TPair<string, TSkillCheck>>;
    FCurrentNode: TDialogueNode;
    FGlobalVars: TStrings;
    FStartConditions: TStringList;
    FStartNodeID: string;

    function LineText: string;
    function LineTextL: string;
    procedure Err(const AMsg: string);
    procedure Warn(const AMsg: string);

    // Parsing helpers
    function SkipWhitespace(const S: string; Pos: Integer): Integer;
    function ParseQuotedString(const S: string; var Pos: Integer): string;
    function ParseNumberFrom(const S: string; var Pos: Integer): Integer;
    function ExtractAfterToken(const S, Token: string; out Remainder: string): string;

// Top-level parse
    procedure ParseFile;

    // Block handlers
    procedure ParseVars(var APos: Integer);
    procedure ParseStartConditions(var APos: Integer);
    procedure ParseFloatNode(var APos: Integer);
    procedure ParseNodeBlock(var APos: Integer);
    procedure ParseNodeOptions(var APos: Integer);
    procedure ParseNPCText(const AText: string);
    procedure ParseOptionLine(const ALine: string; ASource: string);
    procedure ParseInlineConditions(const S: string; AOption: TPlayerOption);
    procedure ParseDefineSkillCheck(var APos: Integer);
    procedure ParseInsertCustomCode(var APos: Integer);

    // Post-processing
    procedure PostProcess;
  public
    constructor Create;
    destructor Destroy; override;
    function ImportFromText(const AText: string; out AProject: TDialogueProject): TFMFImportResult;
    function ImportFromFile(const APath: string; out AProject: TDialogueProject): TFMFImportResult;
  end;

implementation

{ TFMFImporter }

constructor TFMFImporter.Create;
begin
  inherited Create;
  FErrors := TStringList.Create;
  FNodeMap := TDictionary<string, TDialogueNode>.Create;
  FTempSkillChecks := TList<TPair<string, TSkillCheck>>.Create;
  FGlobalVars := TStringList.Create;
  FStartConditions := TStringList.Create;
end;

destructor TFMFImporter.Destroy;
begin
  FStartConditions.Free;
  FGlobalVars.Free;
  FTempSkillChecks.Free;
  FNodeMap.Free;
  FErrors.Free;
  inherited Destroy;
end;

function TFMFImporter.LineText: string;
begin
  if FPos < FLines.Count then
    Result := Trim(FLines[FPos])
  else
    Result := '';
end;

function TFMFImporter.LineTextL: string;
begin
  Result := LowerCase(LineText);
end;

procedure TFMFImporter.Err(const AMsg: string);
begin
  FErrors.Add('Line ' + IntToStr(FPos + 1) + ': ' + AMsg);
end;

procedure TFMFImporter.Warn(const AMsg: string);
begin
  Inc(FWarnings);
end;

function TFMFImporter.SkipWhitespace(const S: string; Pos: Integer): Integer;
begin
  Result := Pos;
  while (Result <= Length(S)) and (S[Result] in [#9, #32]) do
    Inc(Result);
end;

function TFMFImporter.ParseQuotedString(const S: string; var Pos: Integer): string;
var
  startPos: Integer;
begin
  Result := '';
  Pos := SkipWhitespace(S, Pos);
  if (Pos > Length(S)) or (S[Pos] <> '"') then Exit;
  Inc(Pos);
  startPos := Pos;
  while (Pos <= Length(S)) and (S[Pos] <> '"') do
  begin
    if (S[Pos] = '\') and (Pos < Length(S)) then
      Inc(Pos);
    Inc(Pos);
  end;
  Result := Copy(S, startPos, Pos - startPos);
  if (Pos <= Length(S)) and (S[Pos] = '"') then
    Inc(Pos);
end;

{ Parse an integer starting at Pos, returns value, updates Pos past the number }
function TFMFImporter.ParseNumberFrom(const S: string; var Pos: Integer): Integer;
var
  startPos: Integer;
  neg: Boolean;
begin
  Result := 0;
  Pos := SkipWhitespace(S, Pos);
  if (Pos > Length(S)) then Exit;
  neg := False;
  if S[Pos] = '-' then
  begin
    neg := True;
    Inc(Pos);
  end;
  if (Pos > Length(S)) or not (S[Pos] in ['0'..'9']) then Exit;
  startPos := Pos;
  while (Pos <= Length(S)) and (S[Pos] in ['0'..'9']) do
    Inc(Pos);
  Result := StrToIntDef(Copy(S, startPos, Pos - startPos), 0);
  if neg then Result := -Result;
end;

{ Find a token in the string and return the text after it.
  The token text itself is excluded. Remainder points past the token and any following whitespace/comma. }
function TFMFImporter.ExtractAfterToken(const S, Token: string; out Remainder: string): string;
var
  p: Integer;
begin
  Result := '';
  Remainder := '';
  p := Pos(LowerCase(Token), LowerCase(S));
  if p = 0 then Exit;
  p := p + Length(Token);
  // skip whitespace and commas after token
  while (p <= Length(S)) and (S[p] in [#9, #32, ',']) do
    Inc(p);
  Remainder := Trim(Copy(S, p, MaxInt));
end;

procedure TFMFImporter.ParseFile;
begin
  FPos := 0;
  while FPos < FLines.Count do
  begin
    var L := LineTextL;

    // Skip comments and empty lines
    if (L = '') or (L[1] = '/') or (L[1] = '*') or (L[1] = '#') then
    begin
      Inc(FPos);
      Continue;
    end;

    // Skip // comments
    if (Length(L) >= 2) and (L[1] = '/') and (L[2] = '/') then
    begin
      Inc(FPos);
      Continue;
    end;

    if Pos('vars', L) = 1 then
    begin
      ParseVars(FPos);
      Continue;
    end;

    if Pos('npcname', L) = 1 then
    begin
      var p := Pos('"', FLines[FPos]);
      if p > 0 then
        FProject.NPCName := ParseQuotedString(FLines[FPos], p);
      Inc(FPos);
      Continue;
    end;

    if Pos('location', L) = 1 then
    begin
      var p := Pos('"', FLines[FPos]);
      if p > 0 then
        FProject.NPCScript := ParseQuotedString(FLines[FPos], p);
      Inc(FPos);
      Continue;
    end;

    if Pos('description', L) = 1 then
    begin
      var p := Pos('"', FLines[FPos]);
      if p > 0 then
        FProject.Description := ParseQuotedString(FLines[FPos], p);
      Inc(FPos);
      Continue;
    end;

    if Pos('unknown_desc', L) = 1 then
    begin
      Inc(FPos);
      Continue;
    end;

    if Pos('known_desc', L) = 1 then
    begin
      Inc(FPos);
      Continue;
    end;

    if Pos('detailed_desc', L) = 1 then
    begin
      Inc(FPos);
      Continue;
    end;

    if Pos('start_conditions', L) = 1 then
    begin
      ParseStartConditions(FPos);
      Continue;
    end;

    if Pos('floatnode', L) = 1 then
    begin
      ParseFloatNode(FPos);
      Continue;
    end;

    if Pos('node ', L) = 1 then
    begin
      ParseNodeBlock(FPos);
      Continue;
    end;

    // Skip unknown top-level keywords
    Inc(FPos);
  end;
end;

procedure TFMFImporter.ParseVars(var APos: Integer);
var
  line: string;
  rest, varName, notes: string;
  p, p2: Integer;
begin
  Inc(APos); // skip 'vars' keyword

  while APos < FLines.Count do
  begin
    line := Trim(FLines[APos]);

    if line = '' then
    begin
      Inc(APos);
      Continue;
    end;

    if line[1] = '}' then
    begin
      Inc(APos);
      Exit;
    end;

    if Pos('local var', LowerCase(line)) = 1 then
    begin
      rest := line;
      Delete(rest, 1, 9);
      rest := Trim(rest);

      // Extract variable name (up to first space)
      p := Pos(' ', rest);
      if p > 0 then
      begin
        varName := Copy(rest, 1, p - 1);
        rest := Trim(Copy(rest, p + 1, MaxInt));
      end
      else
      begin
        varName := rest;
        rest := '';
      end;

      // Extract notes value
      notes := '';
      p := Pos('notes', LowerCase(rest));
      if p > 0 then
      begin
        Delete(rest, 1, p + 5);
        rest := Trim(rest);
        if (rest <> '') and (rest[1] = '"') then
        begin
          p2 := PosEx('"', rest, 2);
          if p2 > 0 then
            notes := Copy(rest, 2, p2 - 2);
        end
        else if rest <> '' then
          notes := rest;
      end;

      if (notes <> '') and (notes[Length(notes)] = ';') then
        SetLength(notes, Length(notes) - 1);

      FGlobalVars.Add(varName + '=' + notes);
    end;

    Inc(APos);
  end;
end;

procedure TFMFImporter.ParseStartConditions(var APos: Integer);
var
  line: string;
begin
  FStartConditions.Clear;

  while APos < FLines.Count do
  begin
    line := Trim(FLines[APos]);

    if line = '' then
    begin
      Inc(APos);
      Continue;
    end;

    // End of block
    if Pos('};', line) = 1 then
    begin
      Inc(APos);
      Exit;
    end;

    if Pos('default_condition', line) > 0 then
    begin
      var p := Pos('=', line);
      if p > 0 then
        FStartConditions.Add('default=' + Trim(Copy(line, p + 1, MaxInt)));
    end;

    if Pos('cond target_node', line) > 0 then
    begin
      var p := Pos('"', line);
      var targetNode := ParseQuotedString(line, p);
      FStartConditions.Add('target=' + targetNode);
    end;

    Inc(APos);
  end;
end;

procedure TFMFImporter.ParseFloatNode(var APos: Integer);
var
  floatNode: TFloatMessage;
  line: string;
  nodeName: string;
begin
  // Line is: Floatnode "Name"
  line := Trim(FLines[FPos]);
  var p := Pos('"', line);
  nodeName := ParseQuotedString(line, p);
  Inc(APos);

  floatNode := TFloatMessage.Create;
  floatNode.ID := nodeName;

  while APos < FLines.Count do
  begin
    line := Trim(FLines[APos]);

    if line = '' then
    begin
      Inc(APos);
      Continue;
    end;

    if line[1] = '}' then
    begin
      Inc(APos);
      Break;
    end;

    if Pos('notes', LowerCase(line)) = 1 then
    begin
      // Skip notes field (description of float node)
      Inc(APos);
      Continue;
    end;

    // Parse message lines: "message text",
    if (line <> '') and (line[1] = '"') then
    begin
      var msgP := 1;
      var msg := ParseQuotedString(line, msgP);
      if floatNode.Text <> '' then
        floatNode.Text := floatNode.Text + ' | ' + msg
      else
        floatNode.Text := msg;
    end;

    Inc(APos);
  end;

  floatNode.Category := 'FloatHostile';
  floatNode.Priority := 5;
  floatNode.Weight := 1;
  floatNode.TimedDuration := 3.0;
  floatNode.IsAmbient := False;
  floatNode.IsCombatTaunt := True;

  FProject.FloatMessages.Add(floatNode);
end;

procedure TFMFImporter.ParseNodeBlock(var APos: Integer);
var
  nodeName, line: string;
begin
  // Line is: Node "NodeName"
  line := Trim(FLines[FPos]);
  Inc(APos); // skip 'Node' keyword

  var p := Pos('"', line);
  nodeName := ParseQuotedString(line, p);

// Check if we already have this node
   if not FNodeMap.TryGetValue(nodeName, FCurrentNode) then
   begin
     FCurrentNode := FProject.AddNode(ntNPCDialogue);
     FCurrentNode.ID := nodeName;
     FCurrentNode.Speaker := FProject.NPCName;
     FNodeMap.Add(nodeName, FCurrentNode);
   end;

  if FStartNodeID = '' then
    FStartNodeID := nodeName;

  while APos < FLines.Count do
  begin
    line := Trim(FLines[APos]);

    if line = '' then
    begin
      Inc(APos);
      Continue;
    end;

    // End of node block
    if line[1] = '}' then
    begin
      Inc(APos);
      Break;
    end;

    // Parse notes
    if Pos('notes', LowerCase(line)) = 1 then
    begin
      var qp := Pos('"', line);
      if qp > 0 then
        FCurrentNode.Notes := ParseQuotedString(line, qp);
      Inc(APos);
      Continue;
    end;

    // Parse is_wtg
    if Pos('is_wtg', LowerCase(line)) = 1 then
    begin
      Inc(APos);
      Continue;
    end;

    // Parse NPCText
    if Pos('npctext', LowerCase(line)) = 1 then
    begin
      ParseNPCText(line);
      Inc(APos);
      Continue;
    end;

    // Parse NPCFemaleText
    if Pos('npcfemaletext', LowerCase(line)) = 1 then
    begin
      var qp := Pos('"', line);
      if qp > 0 then
      begin
        var femaleText := ParseQuotedString(line, qp);
        if (femaleText <> '') and (FCurrentNode.Text <> '') then
          FCurrentNode.Notes := FCurrentNode.Notes + sLineBreak + '[Female]: ' + femaleText;
      end;
      Inc(APos);
      Continue;
    end;

    // Parse insert_custom_code
    if Pos('insert_custom_code', LowerCase(line)) = 1 then
    begin
      ParseInsertCustomCode(APos);
      Continue;
    end;

    // Parse define_skill_check
    if Pos('define_skill_check', LowerCase(line)) = 1 then
    begin
      ParseDefineSkillCheck(APos);
      Continue;
    end;

    // Parse options block
    if Pos('options', LowerCase(line)) = 1 then
    begin
      ParseNodeOptions(APos);
      Continue;
    end;

    // Skip unknown keywords
    Inc(APos);
  end;
end;

{ ===== Parse NPC Text ===== }

procedure TFMFImporter.ParseNPCText(const AText: string);
var
  p: Integer;
  msg: string;
begin
  p := Pos('"', AText);
  if p = 0 then Exit;
  var pVar := p;
  msg := ParseQuotedString(AText, pVar);
  if FCurrentNode.Text = '' then
    FCurrentNode.Text := msg
  else
    FCurrentNode.Text := FCurrentNode.Text + sLineBreak + msg;
end;

{ ===== Parse Options ===== }

procedure TFMFImporter.ParseNodeOptions(var APos: Integer);
var
  line: string;
begin
  Inc(APos); // skip 'options' line

  while APos < FLines.Count do
  begin
    line := Trim(FLines[APos]);

    if line = '' then
    begin
      Inc(APos);
      Continue;
    end;

    // End of options block
    if line[1] = '}' then
    begin
      Inc(APos);
      Exit;
    end;

    // Parse each option line
    if Pos('int=', line) = 1 then
      ParseOptionLine(line, '');

    Inc(APos);
  end;
end;

procedure TFMFImporter.ParseOptionLine(const ALine: string; ASource: string);
var
  opt: TPlayerOption;
  s, rest, fragment: string;
  p: Integer;
  reaction: Integer;
  targetNode, playertext, notesStr, genderStr: string;
  hasConditions: Boolean;
  condStr: string;
begin
  s := ALine;

  // Parse reaction
  reaction := 4; // default neutral
  p := Pos('reaction=', LowerCase(s));
  if p > 0 then
  begin
    Delete(s, 1, p + 8);
    var rp := 1;
    reaction := ParseNumberFrom(s, rp);
    // We need to scan more carefully - extract the number after reaction=
    var rx := LowerCase(ALine);
    var rxp := Pos('reaction=', rx);
    var numStart := rxp + 9;
    var numStr := '';
    while (numStart <= Length(ALine)) and (ALine[numStart] in ['0'..'9', '-']) do
    begin
      numStr := numStr + ALine[numStart];
      Inc(numStart);
    end;
    if numStr <> '' then
      reaction := StrToIntDef(numStr, 4);
  end;

  // Parse gender
  genderStr := '';
  if Pos('gender=male', LowerCase(s)) > 0 then
    genderStr := 'MALE'
  else if Pos('gender=female', LowerCase(s)) > 0 then
    genderStr := 'FEMALE';

  // Extract playertext
  playertext := '';
  p := Pos('playertext', LowerCase(s));
  if p > 0 then
  begin
    rest := Copy(s, p + 10, MaxInt);
    var pp := 1;
    playertext := ParseQuotedString(rest, pp);
  end;

  // Extract linkto
  targetNode := '';
  p := Pos('linkto', LowerCase(s));
  if p > 0 then
  begin
    rest := Copy(s, p + 6, MaxInt);
    var pp := 1;
    targetNode := ParseQuotedString(rest, pp);
  end;

  // Check for conditions (inline or block)
  hasConditions := Pos('conditions', LowerCase(s)) > 0;
  condStr := '';
  if hasConditions then
  begin
    // Extract the conditions portion
    p := Pos('conditions', LowerCase(s));
    condStr := Copy(s, p, MaxInt);
  end;

  // Extract notes
  notesStr := '';
  p := Pos('notes', LowerCase(s));
  if p > 0 then
  begin
    rest := Copy(s, p + 5, MaxInt);
    var pp := 1;
    notesStr := ParseQuotedString(rest, pp);
  end;

  // Create the option
  opt := TPlayerOption.Create;
  opt.Text := playertext;
  opt.TargetNodeID := targetNode;

  if reaction < 0 then
    opt.IsHidden := True;

  // Parse inline conditions if present
  if hasConditions and (condStr <> '') then
    ParseInlineConditions(condStr, opt);

  // Store gender as notes
  if genderStr <> '' then
  begin
    if notesStr <> '' then
      notesStr := genderStr + ' only. ' + notesStr
    else
      notesStr := genderStr + ' only.';
    opt.IsHidden := True; // Gender-specific options are conditional
  end;

  FCurrentNode.PlayerOptions.Add(opt);
end;

procedure TFMFImporter.ParseInlineConditions(const S: string; AOption: TPlayerOption);
var
  inner, condStr, varName, opStr, valStr, junk: string;
  p, p2: Integer;
  cond: TCondition;
begin
  // Extract content between { and }
  p := Pos('{', S);
  if p = 0 then Exit;
  inner := Copy(S, p + 1, MaxInt);
  p := Pos('}', inner);
  if p > 0 then
    inner := Copy(inner, 1, p - 1);

  // Split by comma and parse each condition
  // Format: LOCAL_VARIABLE VarName OP Value link_next AND/NONE
  while inner <> '' do
  begin
    p := Pos(',', inner);
    if p > 0 then
    begin
      condStr := Trim(Copy(inner, 1, p - 1));
      Delete(inner, 1, p);
    end
    else
    begin
      condStr := Trim(inner);
      inner := '';
    end;

    if condStr = '' then Continue;

    // Parse LOCAL_VARIABLE
    if Pos('LOCAL_VARIABLE', UpperCase(condStr)) = 1 then
    begin
      Delete(condStr, 1, 15);
      condStr := Trim(condStr);

      // Extract variable name
      p2 := Pos(' ', condStr);
      if p2 > 0 then
      begin
        varName := Copy(condStr, 1, p2 - 1);
        condStr := Trim(Copy(condStr, p2 + 1, MaxInt));
      end
      else
      begin
        varName := condStr;
        condStr := '';
      end;

      // Extract operator
      if Pos('>=', condStr) = 1 then
      begin
        cond.Operator := coGTE;
        Delete(condStr, 1, 2);
      end
      else if Pos('<=', condStr) = 1 then
      begin
        cond.Operator := coLTE;
        Delete(condStr, 1, 2);
      end
      else if Pos('>', condStr) = 1 then
      begin
        cond.Operator := coGT;
        Delete(condStr, 1, 1);
      end
      else if Pos('<', condStr) = 1 then
      begin
        cond.Operator := coLT;
        Delete(condStr, 1, 1);
      end
      else if Pos('==', condStr) = 1 then
      begin
        cond.Operator := coEQ;
        Delete(condStr, 1, 2);
      end
      else
      begin
        cond.Operator := coEQ;
      end;

      condStr := Trim(condStr);

      // Extract value (up to next keyword like link_next)
      p2 := Pos('link_next', LowerCase(condStr));
      if p2 > 0 then
      begin
        valStr := Trim(Copy(condStr, 1, p2 - 1));
        // Skip "link_next AND/NONE" - not needed for our model
      end
      else
        valStr := condStr;

      cond.Variable := varName;
      cond.Value := valStr;
      cond.CondType := ctLocalVar;
      cond.BoolOp := boAND;

      var NewLen := Length(AOption.Conditions);
      SetLength(AOption.Conditions, NewLen + 1);
      AOption.Conditions[NewLen] := cond;
    end
    else
    begin
      // Skip unknown condition format
    end;
  end;
end;

procedure TFMFImporter.ParseDefineSkillCheck(var APos: Integer);
var
  sc: TSkillCheck;
  scName, line: string;
  key, val: string;
  p: Integer;
begin
  line := Trim(FLines[FPos]);
  Delete(line, 1, Length('define_skill_check'));
  line := Trim(line);

  // Extract name
  p := Pos(' ', line);
  if p > 0 then
    scName := Copy(line, 1, p - 1)
  else
    scName := line;
  scName := Trim(scName);

  Inc(APos); // skip to opening brace

  FillChar(sc, SizeOf(sc), 0);
  sc.Difficulty := 50;

  while APos < FLines.Count do
  begin
    line := Trim(FLines[APos]);

    if line = '' then
    begin
      Inc(APos);
      Continue;
    end;

    if line[1] = '}' then
    begin
      Inc(APos);
      Break;
    end;

    p := Pos('=', line);
    if p > 0 then
    begin
      key := Trim(Copy(line, 1, p - 1));
      val := Trim(Copy(line, p + 1, MaxInt));
      if (val <> '') and (val[Length(val)] = ';') then
        SetLength(val, Length(val) - 1);
      val := Trim(val);

      if SameText(key, 'skill_num') then
        sc.Skill := TSkillType(StrToIntDef(val, Ord(skSpeech)))
      else if SameText(key, 'difficulty_modifier') then
        sc.Difficulty := StrToIntDef(val, 50)
      else if SameText(key, 'onsuccess') then
        sc.SuccessNodeID := val
      else if SameText(key, 'onfailure') then
        sc.FailureNodeID := val;
    end;

    Inc(APos);
  end;

  FTempSkillChecks.Add(TPair<string, TSkillCheck>.Create(scName, sc));
end;

procedure TFMFImporter.ParseInsertCustomCode(var APos: Integer);
var
  line: string;
  script: TNodeScript;
begin
  script := TNodeScript.Create;
  script.EventType := seOnNodeEnter;
  script.IsEnabled := True;
  script.ScriptCode := '';

  Inc(APos); // skip to opening brace

  while APos < FLines.Count do
  begin
    line := Trim(FLines[APos]);

    if line = '' then
    begin
      Inc(APos);
      Continue;
    end;

    if line[1] = '}' then
    begin
      Inc(APos);
      Break;
    end;

    if (line <> '') and (line[1] = '"') then
    begin
      var pp := 1;
      var code := ParseQuotedString(line, pp);
      if script.ScriptCode <> '' then
        script.ScriptCode := script.ScriptCode + sLineBreak;
      script.ScriptCode := script.ScriptCode + code;
    end;

    Inc(APos);
  end;

  if script.ScriptCode <> '' then
    FCurrentNode.Scripts.Add(script);
end;

{ ===== Post-Processing ===== }

procedure TFMFImporter.PostProcess;
var
  pair: TPair<string, TSkillCheck>;
  node: TDialogueNode;
  nodeName: string;
  i: Integer;
begin
  // Attach skill checks to matching nodes
  for pair in FTempSkillChecks do
  begin
    nodeName := pair.Key;

    // Try exact match first
    node := nil;
    if not FNodeMap.TryGetValue(nodeName, node) then
    begin
      // Strip "SkillCheck_N_" prefix patterns
      if Pos('skillcheck_', LowerCase(nodeName)) = 1 then
        nodeName := Copy(nodeName, 12, MaxInt);

      // Try matching by node name contains
      for var tryNode in FNodeMap do
      begin
        if Pos(UpperCase(tryNode.Key), UpperCase(nodeName)) > 0 then
        begin
          node := tryNode.Value;
          Break;
        end;
      end;
    end;

    if not Assigned(node) then Continue;

    if node.PlayerOptions.Count > 0 then
    begin
      var firstOpt := node.PlayerOptions[0];
      if (pair.Value.SuccessNodeID <> '') or (pair.Value.FailureNodeID <> '') then
      begin
        firstOpt.HasSkillCheck := True;
        firstOpt.SkillCheck := pair.Value;
      end;
    end;
  end;

// Set start node from start conditions
  for i := 0 to FStartConditions.Count - 1 do
  begin
    var entry := FStartConditions[i];
    if Pos('target=', entry) = 1 then
    begin
      FStartNodeID := Copy(entry, Length('target=') + 1, MaxInt);
      Break;
    end;
  end;

// Store global vars as project-level
   for i := 0 to FGlobalVars.Count - 1 do
     FProject.GlobalVars.Add(FGlobalVars.Names[i], FGlobalVars.ValueFromIndex[i]);

  // Set start node
  if FStartNodeID <> '' then
  begin
    FProject.StartNodeID := FStartNodeID;
    var startNode := FProject.FindNode(FStartNodeID);
    if Assigned(startNode) then
      startNode.IsStartNode := True;
  end
  else if FProject.Nodes.Count > 0 then
  begin
    FProject.Nodes[0].IsStartNode := True;
    FProject.StartNodeID := FProject.Nodes[0].ID;
  end;
end;

{ ===== Public API ===== }

function TFMFImporter.ImportFromText(const AText: string; out AProject: TDialogueProject): TFMFImportResult;
begin
  FLines := TStringList.Create;
  try
    FLines.Text := AText;

    FErrors.Clear;
    FWarnings := 0;
    FNodeMap.Clear;
    FTempSkillChecks.Clear;
    FCurrentNode := nil;
    FGlobalVars.Clear;
    FStartConditions.Clear;
    FStartNodeID := '';

    FProject := TDialogueProject.Create;
    FProject.Name := 'Imported from .FMF';

    ParseFile;
    PostProcess;

    // Auto-layout the nodes for proper visual arrangement
    if FProject.Nodes.Count > 0 then
    begin
      var colW := 280;
      var rowH := 160;
      var marginX := 40;
      var marginY := 40;
      var col := 0;
      var row := 0;
      var startNode := FProject.FindNode(FProject.StartNodeID);
      if Assigned(startNode) then
      begin
        startNode.X := marginX;
        startNode.Y := marginY;
      end;
      for var i := 0 to FProject.Nodes.Count - 1 do
      begin
        var node := FProject.Nodes[i];
        if node = startNode then Continue;
        node.X := marginX + col * (colW + marginX);
        node.Y := marginY + row * (rowH + marginY);
        Inc(col);
        if col >= 4 then
        begin
          col := 0;
          Inc(row);
        end;
      end;
    end;

    AProject := FProject;
    Result.Success := (FErrors.Count = 0);
    Result.Errors := TStringList.Create;
    Result.Errors.Assign(FErrors);
    Result.WarningCount := FWarnings;
    Result.NodeCount := FProject.Nodes.Count;
    Result.Project := AProject;
  finally
    FLines.Free;
  end;
end;

function TFMFImporter.ImportFromFile(const APath: string; out AProject: TDialogueProject): TFMFImportResult;
var
  content: string;
begin
  content := TFile.ReadAllText(APath);
  Result := ImportFromText(content, AProject);
  if Result.Success and (FProject <> nil) then
    FProject.Name := ChangeFileExt(ExtractFileName(APath), '');
end;

end.