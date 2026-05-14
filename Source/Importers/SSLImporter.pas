(*
  SSL Import Parser for Fallout Dialogue Creator
  Parses Fallout .ssl dialogue scripts and creates TDialogueProject nodes.
*)

unit SSLImporter;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.StrUtils, System.IOUtils,
  uDialogueTypes;

type
  TSSLImportResult = record
    Success: Boolean;
    Errors: TStringList;
    WarningCount: Integer;
    NodeCount: Integer;
  end;

  TSSLImporter = class
  private
    FLines: TStringList;
    FPos: Integer;
    FProject: TDialogueProject;
    FErrors: TStringList;
    FWarnings: Integer;
    FNodeMap: TDictionary<string, TDialogueNode>;
    FCurrentNode: TDialogueNode;
    FTempSkillChecks: TList<TPair<string, TSkillCheck>>;
    FMaxIterations: Integer;

    function LineText: string;
    function LineTextL: string;
    procedure Err(const Msg: string);
    procedure Warn(const Msg: string);
    procedure ParseFile;
    procedure ParseBody(Depth: Integer);
    function TryReply: Boolean;
    function TryDisplayMsg: Boolean;
    function TryGSayReply: Boolean;
    function TryGSayMessage: Boolean;
    function TryOption: Boolean;
    function TryCall: Boolean;
    function TryIf: Boolean;
    function TrySetStmt: Boolean;
    function ExtractInt(const S: string; out V: Integer): Boolean;
    function ExtractTwo(const S: string; out A, B: string): Boolean;
    function ExtractFive(const S: string; out A1, A2, A3, A4, A5: string): Boolean;
    function SkillEnum(const N: string): TSkillType;
    procedure PostProcess;
    function Norm(const S: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    function ImportFromText(const Text: string; out Proj: TDialogueProject): TSSLImportResult;
    function ImportFromFile(const Path: string; out Proj: TDialogueProject): TSSLImportResult;
  end;

implementation

{ TSSLImporter }

constructor TSSLImporter.Create;
begin
  inherited Create;
  FErrors := TStringList.Create;
  FNodeMap := TDictionary<string, TDialogueNode>.Create;
  FTempSkillChecks := TList<TPair<string, TSkillCheck>>.Create;
end;

destructor TSSLImporter.Destroy;
begin
  FTempSkillChecks.Free;
  FNodeMap.Free;
  FErrors.Free;
  inherited Destroy;
end;

function TSSLImporter.LineText: string;
begin
  if FPos < FLines.Count then
    Result := Trim(FLines[FPos])
  else
    Result := '';
end;

function TSSLImporter.LineTextL: string;
begin
  Result := LowerCase(LineText);
end;

procedure TSSLImporter.Err(const Msg: string);
begin
  FErrors.Add('Line ' + IntToStr(FPos + 1) + ': ' + Msg);
end;

procedure TSSLImporter.Warn(const Msg: string);
begin
  Inc(FWarnings);
end;

function TSSLImporter.Norm(const S: string): string;
begin
  Result := LowerCase(Trim(S));
end;

function TSSLImporter.ExtractInt(const S: string; out V: Integer): Boolean;
var
  p, j: Integer;
  n: string;
begin
  Result := False;
  V := 0;
  p := Pos('(', S);
  if p = 0 then Exit;
  Inc(p);
  while (p <= Length(S)) and not CharInSet(S[p], ['0'..'9', '-']) do Inc(p);
  if p > Length(S) then Exit;
  j := p;
  while (j <= Length(S)) and CharInSet(S[j], ['0'..'9', '-']) do Inc(j);
  n := Copy(S, p, j - p);
  Result := TryStrToInt(n, V);
end;

function TSSLImporter.ExtractTwo(const S: string; out A, B: string): Boolean;

  function Clean(const T: string): string;
  begin
    Result := Trim(T);
    if (Length(Result) >= 2) and (Result[1] = '"') and (Result[Length(Result)] = '"') then
      Result := Copy(Result, 2, Length(Result) - 2);
    while (Result <> '') and (Result[Length(Result)] = ';') do
      SetLength(Result, Length(Result) - 1);
  end;

  function MatchCloseParen(const T: string; Start: Integer): Integer;
  var d, i: Integer;
  begin
    Result := 0; d := 0;
    for i := Start to Length(T) do
    begin
      if T[i] = '(' then Inc(d);
      if T[i] = ')' then begin Dec(d); if d = 0 then Exit(i); end;
    end;
  end;

var
  po, pc: Integer;
  content: string;
begin
  Result := False;
  if Pos('(', S) = 0 then Exit;
  pc := MatchCloseParen(S, Pos('(', S));
  if pc = 0 then Exit;
  content := Copy(S, Pos('(', S) + 1, pc - Pos('(', S) - 1);
  po := Pos(',', content);
  if po = 0 then Exit;
  A := Clean(Copy(content, 1, po - 1));
  B := Clean(Copy(content, po + 1, Length(content)));
  Result := A <> '';
end;

function TSSLImporter.ExtractFive(const S: string; out A1, A2, A3, A4, A5: string): Boolean;

  function Clean(const T: string): string;
  begin
    Result := Trim(T);
    if (Length(Result) >= 2) and (Result[1] = '"') and (Result[Length(Result)] = '"') then
      Result := Copy(Result, 2, Length(Result) - 2);
    while (Result <> '') and (Result[Length(Result)] = ';') do
      SetLength(Result, Length(Result) - 1);
  end;

  function MatchCloseParen(const T: string; Start: Integer): Integer;
  var d, i: Integer;
  begin
    Result := 0; d := 0;
    for i := Start to Length(T) do
    begin
      if T[i] = '(' then Inc(d);
      if T[i] = ')' then begin Dec(d); if d = 0 then Exit(i); end;
    end;
  end;

var
  pc: Integer;
  content: string;
  commas: array[0..4] of Integer;
  i, found: Integer;
begin
  Result := False;
  A1 := ''; A2 := ''; A3 := ''; A4 := ''; A5 := '';
  if Pos('(', S) = 0 then Exit;
  pc := MatchCloseParen(S, Pos('(', S));
  if pc = 0 then Exit;
  content := Copy(S, Pos('(', S) + 1, pc - Pos('(', S) - 1);

  found := 0;
  commas[0] := 0;
  for i := 1 to Length(content) do
    if content[i] = ',' then
    begin
      Inc(found);
      if found > 4 then Break;
      commas[found] := i;
    end;
  if found < 4 then Exit;

  A1 := Clean(Copy(content, 1, commas[1] - 1));
  A2 := Clean(Copy(content, commas[1] + 1, commas[2] - commas[1] - 1));
  A3 := Clean(Copy(content, commas[2] + 1, commas[3] - commas[2] - 1));
  A4 := Clean(Copy(content, commas[3] + 1, commas[4] - commas[3] - 1));
  A5 := Clean(Copy(content, commas[4] + 1, Length(content)));
  Result := (A1 <> '') and (A4 <> '');
end;

function TSSLImporter.SkillEnum(const N: string): TSkillType;
var
  L: string;
begin
  L := Norm(N);
  if Pos('sk', L) = 1 then Delete(L, 1, 2);
  if Pos('speech', L) > 0 then Result := skSpeech
  else if Pos('barter', L) > 0 then Result := skBarter
  else if Pos('science', L) > 0 then Result := skScience
  else if Pos('repair', L) > 0 then Result := skRepair
  else if Pos('lockpick', L) > 0 then Result := skLockpick
  else if Pos('sneak', L) > 0 then Result := skSneak
  else if Pos('medicine', L) > 0 then Result := skMedicine
  else if Pos('survival', L) > 0 then Result := skSurvival
  else if Pos('gambling', L) > 0 then Result := skGambling
  else if Pos('energy', L) > 0 then Result := skEnergyWeapons
  else if Pos('small', L) > 0 then Result := skSmallGuns
  else if Pos('big', L) > 0 then Result := skBigGuns
  else Result := skSpeech;
end;

function TSSLImporter.TryReply: Boolean;
var V: Integer;
begin
  Result := False;
  if Pos('reply(', LineTextL) <> 1 then Exit;
  if ExtractInt(LineText, V) and Assigned(FCurrentNode) then
    FCurrentNode.Text := Format('[MSG:%d]', [V]);
  Inc(FPos);
  Result := True;
end;

function TSSLImporter.TryDisplayMsg: Boolean;
var p1, p2: Integer; S: string;
begin
  Result := False;
  S := LineText;
  if Pos('display_msg', LineTextL) <> 1 then Exit;
  p1 := Pos('"', S); if p1 = 0 then Exit;
  p2 := PosEx('"', S, p1 + 1); if p2 = 0 then Exit;
  if Assigned(FCurrentNode) then
  begin
    S := Copy(S, p1 + 1, p2 - p1 - 1);
    if FCurrentNode.Text = '' then
      FCurrentNode.Text := S
    else
      FCurrentNode.Text := FCurrentNode.Text + ' ' + S;
  end;
  Inc(FPos);
  Result := True;
end;

function TSSLImporter.TryGSayReply: Boolean;
var V: Integer;
begin
  Result := False;
  if Pos('gsay_reply(', LineTextL) <> 1 then Exit;
  if ExtractInt(LineText, V) and Assigned(FCurrentNode) then
    FCurrentNode.Text := Format('[MSG:%d]', [V]);
  Inc(FPos);
  Result := True;
end;

function TSSLImporter.TryGSayMessage: Boolean;
var V: Integer;
begin
  Result := False;
  if Pos('gsay_message(', LineTextL) <> 1 then Exit;
  if ExtractInt(LineText, V) and Assigned(FCurrentNode) then
    FCurrentNode.Text := Format('[MSG:%d]', [V]);
  Inc(FPos);
  Result := True;
end;

function TSSLImporter.TryOption: Boolean;
var
  isGiq, isGood, isBad: Boolean;
  A1, A2, A3, A4, A5: string;
  msgStr, targetNode: string;
  reaction: Integer;
  opt: TPlayerOption;
begin
  Result := False;

  isGiq := Pos('giq_option(', LineTextL) = 1;
  isGood := Pos('goption(', LineTextL) = 1;
  isBad := Pos('boption(', LineTextL) = 1;

  if not (isGiq or isGood or isBad) then
  begin
    if Pos('noption(', LineTextL) = 1 then
      isGiq := False
    else
      Exit;
  end;

  if isGiq then
  begin
    if ExtractFive(LineText, A1, A2, A3, A4, A5) then
    begin
      reaction := StrToIntDef(A1, 4);
      isGood := (reaction = 0);
      isBad := (reaction = 1);
      msgStr := A3;
      targetNode := Norm(A4);
    end
    else if ExtractTwo(LineText, msgStr, targetNode) then
    begin
      // Fallback: 2-arg parse
    end
    else
    begin
      Err('giq_option syntax');
      Inc(FPos);
      Result := True;
      Exit;
    end;
  end
  else
  begin
    if not ExtractTwo(LineText, msgStr, targetNode) then
    begin
      Err('option syntax');
      Inc(FPos);
      Result := True;
      Exit;
    end;
    targetNode := Norm(targetNode);
  end;

  if Assigned(FCurrentNode) then
  begin
    opt := TPlayerOption.Create;
    opt.TargetNodeID := targetNode;
    opt.Text := Format('[MSG:%s]', [msgStr]);
    if isBad or isGood then
      opt.HasSkillCheck := True;
    FCurrentNode.PlayerOptions.Add(opt);
  end;

  Inc(FPos);
  Result := True;
end;

function TSSLImporter.TryCall: Boolean;
var target: string; p1, p2: Integer;
begin
  Result := False;
  if (Pos('call ', LineTextL) <> 1) and (Pos('call(', LineTextL) <> 1) then Exit;

  if LineTextL[5] = '(' then
  begin
    p1 := Pos('(', LineText);
    p2 := PosEx(')', LineText, p1 + 1);
    if (p1 > 0) and (p2 > p1) then
    begin
      target := Trim(Copy(LineText, p1 + 1, p2 - p1 - 1));
      if (Length(target) >= 2) and (target[1] = '"') and
         (target[Length(target)] = '"') then
        target := Copy(target, 2, Length(target) - 2);
      if Assigned(FCurrentNode) then
        FCurrentNode.NextNodeID := Norm(target);
    end;
  end
  else
  begin
    target := Trim(Copy(LineText, 6, MaxInt));
    if (target <> '') and (target[Length(target)] = ';') then
      SetLength(target, Length(target) - 1);
    if Assigned(FCurrentNode) then
      FCurrentNode.NextNodeID := Norm(Trim(target));
  end;

  Inc(FPos);
  Result := True;
end;

function TSSLImporter.TryIf: Boolean;
var
  depth: Integer;
  sk: TSkillCheck;
  inner: string;
  parts: TArray<string>;
  numStr: string;
begin
  Result := False;
  if Pos('skill_check(', LineTextL) = 0 then Exit;

  FillChar(sk, SizeOf(sk), 0);
  sk.Difficulty := 50;

  // Find skill_check() and extract inner args
  var dp := Pos('skill_check(', LineText);
  if dp > 0 then
  begin
    var match := 0;
    for var i := dp to Length(LineText) do
    begin
      if LineText[i] = '(' then Inc(match);
      if LineText[i] = ')' then begin Dec(match); if match = 0 then
        begin inner := Copy(LineText, dp + 12, i - dp - 12); Break; end;
      end;
    end;

    if inner <> '' then
    begin
      parts := inner.Split([',']);
      if Length(parts) >= 3 then
      begin
        sk.Skill := SkillEnum(Trim(parts[1]));
        numStr := '';
        for var ch in Trim(parts[2]) do
          if CharInSet(ch, ['0'..'9', '-']) then numStr := numStr + ch;
        TryStrToInt(numStr, sk.Difficulty);
      end;
    end;
  end;

  if Assigned(FCurrentNode) then
    FTempSkillChecks.Add(TPair<string, TSkillCheck>.Create(FCurrentNode.ID, sk));

  Inc(FPos);

  // Skip entire if/else block tracking depth (if/elseif nesting, begin/end blocks)
  depth := 1;
  while FPos < FLines.Count do
  begin
    var L := LineTextL;
    if (Pos('if(', L) = 1) or (Pos('if ', L) = 1) then
    begin
      Inc(depth);
      Inc(FPos);
      Continue;
    end;
    if SameText(LineText, 'begin') then
    begin
      Inc(FPos);
      Continue;
    end;
    if Copy(LineTextL, 1, 3) = 'end' then
    begin
      // If depth=1 and an 'else' follows, this 'end' closes the 'then' block but the if-else continues.
      // Do not decrement depth yet; consume this 'end' and continue to process 'else'.
      if (depth = 1) and (FPos + 1 < FLines.Count) and SameText(Trim(FLines[FPos + 1]), 'else') then
      begin
        Inc(FPos);
        Continue;
      end;

      Dec(depth);
      Inc(FPos);
      if depth = 0 then Break;
      Continue;
    end;
    if SameText(LineText, 'else') then
    begin
      Inc(FPos);
      // If else is followed by 'begin' on same line? Unlikely, but check next line
      if (FPos < FLines.Count) and SameText(LineText, 'begin') then
      begin
        Inc(FPos); // skip 'begin'
      end;
      Continue;
    end;
    Inc(FPos);
  end;

   Result := True;
 end;

function TSSLImporter.TrySetStmt: Boolean;
var L: string;
begin
  Result := False;
  L := LineTextL;
  if Length(L) = 0 then Exit;
  case L[1] of
    's': if (Pos('set_', L) = 1) or (Pos('set_skill', L) = 1) or
            (Pos('set_global', L) = 1) or (Pos('set_local', L) = 1) then Exit(True);
    'g': if (Pos('gset_', L) = 1) or (Pos('give_', L) = 1) then Exit(True);
    'i': if Pos('inc_', L) = 1 then Exit(True);
    'd': if Pos('dec_', L) = 1 then Exit(True);
    'r': if Pos('remove_', L) = 1 then Exit(True);
    'p': if Pos('party_', L) = 1 then Exit(True);
    'c': if Pos('critter_', L) = 1 then Exit(True);
    'f': if Pos('float_msg', L) = 1 then Exit(True); // only float_msg
  end;
end;

procedure TSSLImporter.ParseBody(Depth: Integer);
begin
  while FPos < FLines.Count do
  begin
    if FPos > FMaxIterations then
    begin
      Err('Parser exceeded maximum iterations - possible infinite loop in ParseBody');
      Exit;
    end;

    if LineText = '' then begin Inc(FPos); Continue; end;

    var L := LineTextL;
    if (Length(LineText) >= 1) then
      if (LineText[1] = '/') or (LineText[1] = '*') or (LineText[1] = '#') then
      begin Inc(FPos); Continue; end;

    if (Pos('#include', L) = 1) or (Pos('#define', L) = 1) or
       (Pos('variable', L) = 1) or (Pos('//', L) = 1) then
    begin Inc(FPos); Continue; end;

    if Copy(LineTextL, 1, 3) = 'end' then
    begin Inc(FPos); Exit; end;

    if TrySetStmt then begin Inc(FPos); Continue; end;
    if TryReply then Continue;
    if TryDisplayMsg then Continue;
    if TryGSayReply then Continue;
    if TryGSayMessage then Continue;
    if TryOption then Continue;
    if TryCall then Continue;
    if (Pos('if(', L) = 1) or (Pos('if ', L) = 1) then
    begin TryIf; Continue; end;

    if (Pos('start_gdialog(', L) = 1) or (Pos('gsay_start', L) = 1) or
        (Pos('gsay_end', L) = 1) or (Pos('end_dialogue', L) = 1) or
        (Pos('set_global_var(', L) = 1) or (Pos('debug_msg(', L) = 1) or
        (Pos('debug_print(', L) = 1) or (Pos('only_once', L) = 1) or
        (Pos('critter_add_trait', L) = 1) or (Pos('dude_rep', L) = 1) or
        (Pos('temp_', L) = 1) or (Pos('exit_line', L) = 1) or
        (Pos('script_is_running', L) = 1) or (Pos('hostile', L) = 1) then
    begin Inc(FPos); Continue; end;

    Inc(FPos);
  end;
end;

procedure TSSLImporter.ParseFile;
var
  procName: string;
begin
  FPos := 0;

  while FPos < FLines.Count do
  begin
    if FPos > FMaxIterations then
    begin
      Err('Parser exceeded maximum iterations - possible infinite loop in ParseFile');
      Exit;
    end;

    if Trim(LineText) = '' then begin Inc(FPos); Continue; end;

    var L := LineTextL;
    if (Length(LineText) >= 1) and
       ((LineText[1] = '/') or (LineText[1] = '*') or (LineText[1] = '#')) then
    begin Inc(FPos); Continue; end;

    if (Pos('#include', L) = 1) or (Pos('#define', L) = 1) or
       (Pos('variable', L) = 1) then
    begin Inc(FPos); Continue; end;

    if Pos('procedure ', L) = 1 then
    begin
      if (Pos(';', LineText) > 0) and (Pos('begin', L) = 0) then
      begin Inc(FPos); Continue; end;
    end;

    if Pos('procedure ', L) = 1 then
    begin
      var hasBegin := Pos(' begin', L) > 0;

      if hasBegin then
      begin
        var p1 := Pos('procedure ', L) + 10;
        var p2 := Pos(' begin', L);
        procName := Norm(Copy(LineText, p1, p2 - p1));
      end
      else
      begin
        var p1 := Pos('procedure ', L) + 10;
        var p2 := Pos(';', LineText);
        if p2 = 0 then p2 := Length(LineText) + 1;
        procName := Norm(Copy(LineText, p1, p2 - p1));
      end;

      var node: TDialogueNode;
      if not FNodeMap.TryGetValue(procName, node) then
      begin
        node := FProject.AddNode(ntNPCDialogue);
        node.ID := procName;
        node.Speaker := 'NPC';
        FNodeMap.Add(procName, node);
      end;
      FCurrentNode := node;

      if hasBegin then
      begin
        Inc(FPos);
        ParseBody(1);
      end
      else
      begin
        Inc(FPos);
        while FPos < FLines.Count do
        begin
          if SameText(LineText, 'begin') then
          begin Inc(FPos); Break; end;
          if Pos('procedure ', LineTextL) = 1 then Exit;
          Inc(FPos);
        end;
        ParseBody(1);
      end;
    end else
    begin
      Inc(FPos);
    end;
  end;
end;

procedure TSSLImporter.PostProcess;
var
  pair: TPair<string, TSkillCheck>;
  node: TDialogueNode;
begin
  for pair in FTempSkillChecks do
  begin
    node := nil;
    if not FNodeMap.TryGetValue(pair.Key, node) then Continue;
    if not Assigned(node) then Continue;
    if node.PlayerOptions.Count > 0 then
    begin
      node.PlayerOptions[0].HasSkillCheck := True;
      node.PlayerOptions[0].SkillCheck := pair.Value;
    end;
  end;

  for node in FProject.Nodes do
  begin
    if (node.NextNodeID <> '') and not FNodeMap.ContainsKey(node.NextNodeID) then
      Warn('Node ' + node.ID + ' -> unknown: ' + node.NextNodeID);
    for var opt in node.PlayerOptions do
      if (opt.TargetNodeID <> '') and not FNodeMap.ContainsKey(opt.TargetNodeID) then
        Warn('Node ' + node.ID + ' option -> unknown: ' + opt.TargetNodeID);
  end;
end;

function TSSLImporter.ImportFromText(const Text: string; out Proj: TDialogueProject): TSSLImportResult;
begin
  FLines := TStringList.Create;
  try
    FLines.Text := Text;
    FPos := 0;
    FErrors.Clear;
    FWarnings := 0;
    FNodeMap.Clear;
    FTempSkillChecks.Clear;
    FCurrentNode := nil;
    FMaxIterations := FLines.Count * 1000; // generous safety margin

    FProject := TDialogueProject.Create;
    ParseFile;
    PostProcess;

    Proj := FProject;
    Result.Success := (FErrors.Count = 0);
    Result.Errors := TStringList.Create;
    Result.Errors.Assign(FErrors);
    Result.WarningCount := FWarnings;
    Result.NodeCount := FProject.Nodes.Count;
  finally
    FLines.Free;
  end;
end;

function TSSLImporter.ImportFromFile(const Path: string; out Proj: TDialogueProject): TSSLImportResult;
var
  content: string;
begin
  content := TFile.ReadAllText(Path);
  Result := ImportFromText(content, Proj);
  if Result.Success and (FProject <> nil) then
    FProject.Name := ChangeFileExt(ExtractFileName(Path), '');
end;

end.