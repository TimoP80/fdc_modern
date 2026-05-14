unit uExportManager;

// uExportManager - Export dialogue projects to various formats
// Supports Fallout .SSL, .MSG, JSON, localization packs, and engine packages

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.JSON, System.IOUtils, System.TypInfo, System.Math,
  uDialogueTypes;

type
  TExportFormat = (efJSON, efMSG, efSSL, efLocalization, efPackage);

  TExportOptions = record
    Format: TExportFormat;
    OutputPath: string;
    IncludeComments: Boolean;
    IncludeMetadata: Boolean;
    MinifyJSON: Boolean;
    SplitFiles: Boolean;
    Encoding: string;   // 'UTF-8', 'ASCII', 'WIN1252'
    LineEnding: string; // 'CRLF', 'LF'
    MsgFilePrefix: string;
    SSLClassName: string;
    IncludeFloatMessages: Boolean;
    LocaleFilter: string;
  end;

  TExportResult = record
    Success: Boolean;
    FilesGenerated: TArray<string>;
    Warnings: TArray<string>;
    Errors: TArray<string>;
    NodeCount: Integer;
    LineCount: Integer;
  end;

  TExportManager = class
  private
    FProject: TDialogueProject;
    FLog: TStringList;

function ExportToJSON(const opts: TExportOptions): TExportResult;
     function ExportToMSG(const opts: TExportOptions): TExportResult;
     function ExportToSSL(const opts: TExportOptions): TExportResult;
     function ExportToLocalization(const opts: TExportOptions): TExportResult;
     function ExportPackage(const opts: TExportOptions): TExportResult;

     function GenerateMSGContent: TStringList;
     function GenerateSSLContent: TStringList;
     function GenerateSSLNode(node: TDialogueNode; indent: Integer): string;
     function GenerateConditionSSL(const cond: TCondition): string;
     function GenerateSkillCheckSSL(const sk: TSkillCheck; const optID: string): string;

     procedure AddLog(const msg: string);
     procedure AddError(var result: TExportResult; const msg: string);

     function EnsureDir(const path: string): Boolean;
     function SafeWriteStringToFile(const path, content: string; const encoding: string): Boolean;
     function IndentStr(level: Integer): string;
     function EscapeMSGText(const s: string): string;
   public
    constructor Create(project: TDialogueProject);
    destructor Destroy; override;

    function Export(const opts: TExportOptions): TExportResult;
    function ValidateBeforeExport: TStringList;

    class function DefaultOptions: TExportOptions;
    class function FormatName(fmt: TExportFormat): string;

    property Log: TStringList read FLog;
  end;

// Helper function - sanitizes node ID for use in SSL/MSG labels
function SafeStr(const s: string): string;

implementation

uses
  System.StrUtils, System.DateUtils;

const
  SSL_HEADER =
    '/* ============================================================' + sLineBreak +
    ' * Fallout Dialogue Creator - Auto-generated SSL Script' + sLineBreak +
    ' * DO NOT EDIT MANUALLY - regenerate from FDC project file' + sLineBreak +
    ' * ============================================================ */' + sLineBreak;

  MSG_HEADER =
    '# Fallout Dialogue Creator - Auto-generated Message File' + sLineBreak +
    '# Format: {line_number}{nul}{sound_file}{nul}{text}' + sLineBreak;

function SafeStr(const s: string): string;
begin
  Result := StringReplace(s, '-', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '{', '', [rfReplaceAll]);
  Result := StringReplace(Result, '}', '', [rfReplaceAll]);
  Result := Copy(Result, 1, 16);
end;

{ TExportManager }

constructor TExportManager.Create(project: TDialogueProject);
begin
  inherited Create;
  FProject := project;
  FLog := TStringList.Create;
end;

destructor TExportManager.Destroy;
begin
  FLog.Free;
  inherited;
end;

class function TExportManager.DefaultOptions: TExportOptions;
begin
  Result.Format := efJSON;
  Result.OutputPath := '';
  Result.IncludeComments := True;
  Result.IncludeMetadata := True;
  Result.MinifyJSON := False;
  Result.SplitFiles := False;
  Result.Encoding := 'UTF-8';
  Result.LineEnding := 'CRLF';
  Result.MsgFilePrefix := 'dialog_';
  Result.SSLClassName := '';
  Result.IncludeFloatMessages := True;
  Result.LocaleFilter := '';
end;

class function TExportManager.FormatName(fmt: TExportFormat): string;
begin
  case fmt of
    efJSON:         Result := 'Dialogue JSON';
    efMSG:          Result := 'Fallout .MSG File';
    efSSL:          Result := 'Fallout .SSL Script';
    efLocalization: Result := 'Localization Pack';
    efPackage:      Result := 'Engine Package';
  end;
end;

procedure TExportManager.AddLog(const msg: string);
begin
  FLog.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + msg);
end;

procedure TExportManager.AddError(var result: TExportResult; const msg: string);
begin
  var arr := result.Errors;
  SetLength(arr, Length(arr) + 1);
  arr[High(arr)] := msg;
  result.Errors := arr;
  AddLog('ERROR: ' + msg);
end;

function TExportManager.EnsureDir(const path: string): Boolean;
begin
  if not DirectoryExists(path) then
    Result := ForceDirectories(path)
  else
    Result := True;
end;

function TExportManager.SafeWriteStringToFile(const path, content: string; const encoding: string): Boolean;
var
  fs: TFileStream;
  bytes: TBytes;
begin
  Result := False;
  try
    EnsureDir(ExtractFilePath(path));
    if encoding = 'UTF-8' then
      bytes := TEncoding.UTF8.GetBytes(content)
    else if encoding = 'ASCII' then
      bytes := TEncoding.ASCII.GetBytes(content)
    else
      bytes := TEncoding.Default.GetBytes(content);
    fs := TFileStream.Create(path, fmCreate);
    try
      if Length(bytes) > 0 then
        fs.WriteBuffer(bytes[0], Length(bytes));
      Result := True;
    finally
      fs.Free;
    end;
  except
    Result := False;
  end;
end;

function TExportManager.IndentStr(level: Integer): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to level do
    Result := Result + '  ';
end;

function TExportManager.EscapeMSGText(const s: string): string;
begin
  Result := s;
  Result := StringReplace(Result, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '  ', [rfReplaceAll]);
end;

// ==================== JSON Export ====================

function TExportManager.ExportToJSON(const opts: TExportOptions): TExportResult;
var
  sl: TStringList;
begin
  FillChar(Result, SizeOf(Result), 0);
  sl := TStringList.Create;
  try
    sl.Text := FProject.ToJSON.Format(2);
    if not SafeWriteStringToFile(opts.OutputPath, sl.Text, opts.Encoding) then
      AddError(Result, 'Failed to write JSON to: ' + opts.OutputPath)
    else
      AddLog('Exported JSON: ' + opts.OutputPath);
  finally
    sl.Free;
  end;
  Result.Success := Length(Result.Errors) = 0;
end;

// ==================== MSG Export ====================

function TExportManager.GenerateMSGContent: TStringList;
var
  node: TDialogueNode;
  i, lineNum: Integer;
begin
  Result := TStringList.Create;
  lineNum := 0;
  for node in FProject.Nodes do
  begin
    Inc(lineNum);
    Result.Add('{' + IntToStr(lineNum) + '}{}{' + EscapeMSGText(node.Text) + '}');
    for i := 0 to node.PlayerOptions.Count - 1 do
    begin
      Inc(lineNum);
      Result.Add('{' + IntToStr(lineNum) + '}{}{' + EscapeMSGText(node.PlayerOptions[i].Text) + '}');
    end;
  end;
end;

function TExportManager.ExportToMSG(const opts: TExportOptions): TExportResult;
var
  content: TStringList;
begin
  FillChar(Result, SizeOf(Result), 0);
  content := GenerateMSGContent;
  try
    if not SafeWriteStringToFile(opts.OutputPath, content.Text, opts.Encoding) then
      AddError(Result, 'Failed to write MSG to: ' + opts.OutputPath)
    else
      AddLog('Exported MSG: ' + opts.OutputPath);
  finally
    content.Free;
  end;
  Result.Success := Length(Result.Errors) = 0;
end;

// ==================== SSL Export ====================

function TExportManager.GenerateConditionSSL(const cond: TCondition): string;
begin
  Result := '';
  // Simplified condition -> SSL conversion
  case cond.CondType of
    ctSkillCheck:
      Result := '  has_skill(dude, SKILL_' + UpperCase(cond.Variable) + ')';
    ctStatCheck:
      Result := '  stat_level(dude, ' + cond.Variable + ') ' + OPERATOR_NAMES[cond.Operator] + ' ' + cond.Value;
    ctGlobalVar:
      Result := '  global_var(' + cond.Variable + ') ' + OPERATOR_NAMES[cond.Operator] + ' ' + cond.Value;
    ctLocalVar:
      Result := '  local_var(' + cond.Variable + ') ' + OPERATOR_NAMES[cond.Operator] + ' ' + cond.Value;
    ctQuestFlag:
      Result := '  quest_state(' + cond.Variable + ') ' + OPERATOR_NAMES[cond.Operator] + ' ' + cond.Value;
    ctKarma:
      Result := '  karma_level(dude) ' + OPERATOR_NAMES[cond.Operator] + ' ' + cond.Value;
    ctReputation:
      Result := '  reputation(dude) ' + OPERATOR_NAMES[cond.Operator] + ' ' + cond.Value;
    ctInventory:
      Result := '  obj_is_carrying_obj(dude, ' + cond.Variable + ') ' + OPERATOR_NAMES[cond.Operator] + ' ' + cond.Value;
    ctTimeOfDay:
      Result := '  game_time_hour ' + OPERATOR_NAMES[cond.Operator] + ' ' + cond.Value;
    ctCompanion:
      Result := '  is_success(' + cond.Variable + ')';
    ctRandom:
      Result := '  random(100) < ' + cond.Value;
  end;
end;

function TExportManager.GenerateSkillCheckSSL(const sk: TSkillCheck; const optID: string): string;
begin
  Result := '';
  if not sk.SuccessNodeID.IsEmpty then
    Result := Result + '      goto_node_' + SafeStr(sk.SuccessNodeID) + ';' + sLineBreak;
  if not sk.FailureNodeID.IsEmpty then
    Result := Result + '      goto_node_' + SafeStr(sk.FailureNodeID) + ';' + sLineBreak;
end;

function TExportManager.GenerateSSLNode(node: TDialogueNode; indent: Integer): string;
var
  ind: string;
  s: string;
  i: Integer;
  opt: TPlayerOption;
begin
  ind := IndentStr(indent);
  s := '';

  s := s + ind + '(* NODE: ' + NODE_TYPE_NAMES[node.NodeType];
  if node.Speaker <> '' then s := s + '  Speaker: ' + node.Speaker;
  s := s + ' *)' + sLineBreak;
  s := s + ind + 'node_' + SafeStr(node.ID) + ':' + sLineBreak;
  s := s + ind + 'begin' + sLineBreak;

  // Conditions
  if node.Conditions.Count > 0 then
  begin
    s := s + ind + '  (* Conditions *)' + sLineBreak;
    for i := 0 to node.Conditions.Count - 1 do
      s := s + GenerateConditionSSL(node.Conditions[i]) + ';' + sLineBreak;
  end;

  case node.NodeType of
    ntNPCDialogue:
    begin
      s := s + ind + '  display_msg(' + IntToStr(Length(node.Text)) + ');' + sLineBreak;
      s := s + ind + '  reply_msg(node_' + SafeStr(node.ID) + '_text);' + sLineBreak;
    end;
    ntPlayerReply:
    begin
      s := s + ind + '  reply_msg(node_' + SafeStr(node.ID) + '_text);' + sLineBreak;
      for i := 0 to node.PlayerOptions.Count - 1 do
      begin
        opt := node.PlayerOptions[i];
        s := s + ind + '  Option(' + IntToStr(i) + ', node_' + SafeStr(node.ID) + '_opt' + IntToStr(i) + '_text';
        if opt.HasSkillCheck then
          s := s + ', ' + SKILL_NAMES[opt.SkillCheck.Skill];
        s := s + ');' + sLineBreak;
        if opt.HasSkillCheck then
          s := s + GenerateSkillCheckSSL(opt.SkillCheck, SafeStr(node.ID));
      end;
    end;
    ntConditional:
    begin
      for i := 0 to node.PlayerOptions.Count - 1 do
      begin
        opt := node.PlayerOptions[i];
        s := s + ind + '  if ' + GenerateConditionSSL(opt.Conditions[0]) + ' then begin' + sLineBreak;
        if opt.TargetNodeID <> '' then
          s := s + ind + '    goto_node_' + SafeStr(opt.TargetNodeID) + ';' + sLineBreak;
        s := s + ind + '  end;' + sLineBreak;
      end;
    end;
    ntScript:
    begin
      for var sc in node.Scripts do
        if sc.IsEnabled and (Trim(sc.ScriptCode) <> '') then
        begin
          s := s + ind + '  (* Event: ' + GetEnumName(TypeInfo(TScriptEvent), Ord(sc.EventType)) + ' *)' + sLineBreak;
          // Add the script code lines indented
          var codeLines := sc.ScriptCode.Split([sLineBreak]);
          for var line in codeLines do
            s := s + ind + '  ' + line + sLineBreak;
        end;
    end;
    ntQuestUpdate:
    begin
      s := s + ind + '  (* Quest update *)' + sLineBreak;
      if node.QuestID <> '' then
        s := s + ind + '  set_quest_state(QUEST_' + UpperCase(node.QuestID) + ', ' +
          IfThen(node.QuestFlag <> '', node.QuestFlag, '1') + ');' + sLineBreak;
    end;
    ntTrade:
    begin
      s := s + ind + '  (* Trade screen *)' + sLineBreak;
      s := s + ind + '  start_gdialog(self, BARTER_SCRIPT, BARTER_BARTER, -1, -1);' + sLineBreak;
    end;
    ntEndDialogue:
    begin
      s := s + ind + '  (* End dialogue *)' + sLineBreak;
    end;
    ntComment:
    begin
      s := s + ind + '  (* ' + node.Comment + ' *)' + sLineBreak;
    end;
    ntCombatTrigger:
    begin
      s := s + ind + '  attack_complex(self, 8, 0, -1, -1, 0, 0);' + sLineBreak;
    end;
    ntRandom:
    begin
      // Random node: pick random next
      if node.PlayerOptions.Count > 0 then
      begin
        s := s + ind + '  (* Random branch *)' + sLineBreak;
        for i := 0 to node.PlayerOptions.Count - 1 do
        begin
          opt := node.PlayerOptions[i];
          s := s + ind + '  if random(' + IntToStr(node.PlayerOptions.Count) + ') = ' + IntToStr(i) + ' then '
            + 'goto_node_' + SafeStr(opt.TargetNodeID) + ';' + sLineBreak;
        end;
      end;
    end;
  end;

  // Next node link for simple linear nodes
  if node.NextNodeID <> '' then
    s := s + ind + '  goto node_' + SafeStr(node.NextNodeID) + ';' + sLineBreak;

  s := s + ind + 'end;' + sLineBreak;
  s := s + sLineBreak;
  Result := s;
end;

function TExportManager.GenerateSSLContent: TStringList;
begin
  Result := TStringList.Create;
  Result.Add(SSL_HEADER);
  Result.Add('procedure start begin');
  Result.Add('  (* Script initialization *)');
  Result.Add('end');
  Result.Add('');
  Result.Add('procedure talk begin');
  Result.Add('  if (dialogue_reaction(dude_reaction_to_me) > 25) then begin');
  if FProject.StartNodeID <> '' then
    Result.Add('    goto node_' + SafeStr(FProject.StartNodeID) + ';')
  else if FProject.Nodes.Count > 0 then
    Result.Add('    goto node_' + SafeStr(FProject.Nodes[0].ID) + ';');
  Result.Add('  end');
  Result.Add('end');
  Result.Add('');
  Result.Add('// =============== Node Definitions ===============');

  // Start node marker
  if FProject.StartNodeID <> '' then
    Result.Add('// START NODE: ' + FProject.StartNodeID);

  // Define all nodes
  var node: TDialogueNode;
  for node in FProject.Nodes do
  begin
    if node.NodeType = ntComment then Continue;
    Result.Add(GenerateSSLNode(node, 0));
  end;

  // Add float messages
  if FProject.FloatMessages.Count > 0 then
  begin
    Result.Add('// =============== Float Messages ===============');
    var i: Integer;
    for i := 0 to FProject.FloatMessages.Count - 1 do
      Result.Add('// Float: ' + FProject.FloatMessages[i].Text);
  end;
end;

function TExportManager.ExportToSSL(const opts: TExportOptions): TExportResult;
var
  content: TStringList;
begin
  FillChar(Result, SizeOf(Result), 0);
  content := GenerateSSLContent;
  try
    if not SafeWriteStringToFile(opts.OutputPath, content.Text, opts.Encoding) then
      AddError(Result, 'Failed to write SSL to: ' + opts.OutputPath)
    else
      AddLog('Exported SSL: ' + opts.OutputPath);
  finally
    content.Free;
  end;
  Result.Success := Length(Result.Errors) = 0;
end;

// ==================== Localization Export ====================

function TExportManager.ExportToLocalization(const opts: TExportOptions): TExportResult;
var
  stringsArr: TJSONArray;
  node: TDialogueNode;
  opt: TPlayerOption;
  obj: TJSONObject;
  sl: TStringList;
  var i: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  stringsArr := TJSONArray.Create;
  try
    for node in FProject.Nodes do
    begin
      if node.NodeType = ntComment then Continue;
      if Trim(node.Text) = '' then Continue;

      obj := TJSONObject.Create;
      obj.AddPair('key', 'node_' + node.ID + '_text');
      obj.AddPair('context', NODE_TYPE_NAMES[node.NodeType] +
        IfThen(node.Speaker <> '', ' (' + node.Speaker + ')', ''));
      obj.AddPair('source', node.Text);
      obj.AddPair('translation', node.Text); // Placeholder
      stringsArr.Add(obj);

      for i := 0 to node.PlayerOptions.Count - 1 do
      begin
        opt := node.PlayerOptions[i];
        if Trim(opt.Text) = '' then Continue;
        obj := TJSONObject.Create;
        obj.AddPair('key', 'node_' + node.ID + '_opt' + IntToStr(i) + '_text');
        obj.AddPair('context', 'Player option');
        obj.AddPair('source', opt.Text);
        obj.AddPair('translation', opt.Text);
        stringsArr.Add(obj);
      end;
    end;

    sl := TStringList.Create;
    try
      sl.Text := stringsArr.Format(2);
      if not SafeWriteStringToFile(opts.OutputPath, sl.Text, opts.Encoding) then
        AddError(Result, 'Failed to write localization: ' + opts.OutputPath)
      else
        AddLog('Exported localization: ' + opts.OutputPath);
    finally
      sl.Free;
    end;
  finally
    stringsArr.Free;
  end;
  Result.Success := Length(Result.Errors) = 0;
end;

// ==================== Package Export ====================

function TExportManager.ExportPackage(const opts: TExportOptions): TExportResult;
var
  jsonOpts, sslOpts: TExportOptions;
  allFiles: TStringList;
  jsonRes, sslRes: TExportResult;
begin
  FillChar(Result, SizeOf(Result), 0);
  allFiles := TStringList.Create;
  try
    // Export JSON
    jsonOpts := Self.DefaultOptions;
    jsonOpts.OutputPath := ChangeFileExt(opts.OutputPath, '.json');
    jsonRes := Self.ExportToJSON(jsonOpts);
    if jsonRes.Success then
      allFiles.Add(jsonOpts.OutputPath);

    // Export SSL
    sslOpts := Self.DefaultOptions;
    sslOpts.OutputPath := ChangeFileExt(opts.OutputPath, '.ssl');
    sslRes := Self.ExportToSSL(sslOpts);
    if sslRes.Success then
      allFiles.Add(sslOpts.OutputPath);

    Result.Success := (Length(jsonRes.Errors) = 0) and (Length(sslRes.Errors) = 0);
    Self.AddLog('Package complete: ' + IntToStr(allFiles.Count) + ' files generated.');
  finally
    allFiles.Free;
  end;
end;

// ==================== Main Export Entry Point ====================

function TExportManager.Export(const opts: TExportOptions): TExportResult;
begin
  FillChar(Result, SizeOf(Result), 0);
  case opts.Format of
    efJSON:         Result := ExportToJSON(opts);
    efMSG:          Result := ExportToMSG(opts);
    efSSL:          Result := ExportToSSL(opts);
    efLocalization: Result := ExportToLocalization(opts);
    efPackage:      Result := ExportPackage(opts);
  end;
end;

function TExportManager.ValidateBeforeExport: TStringList;
begin
  Result := FProject.ValidateProject;
end;

end.