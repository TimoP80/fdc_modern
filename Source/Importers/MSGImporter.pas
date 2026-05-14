(*
  MSG Import Parser for Fallout Dialogue Creator
  Parses Fallout .msg dialogue files and creates a TDialogueProject.

  MSG file format:
    {message_id}{}{text}
    Messages are keyed by numeric ID (e.g. {100}{}{Hello there})
    Consecutive message IDs are linked as a linear dialogue chain.
*)

unit MSGImporter;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.StrUtils, System.IOUtils,
  uDialogueTypes;

type
  TMSGImportResult = record
    Success: Boolean;
    Errors: TStringList;
    WarningCount: Integer;
    NodeCount: Integer;
    Project: TDialogueProject;
  end;

  TMSGImporter = class
  private
    FLines: TStringList;
    FErrors: TStringList;
    FWarnings: Integer;
    FNodeMap: TDictionary<Integer, TDialogueNode>;

    function ParseLine(const ALine: string; out MsgID: Integer; out MsgText: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function ImportFromText(const AText: string; out AProject: TDialogueProject): TMSGImportResult;
    function ImportFromFile(const AFilePath: string; out AProject: TDialogueProject): TMSGImportResult;
  end;

implementation

{ TMSGImporter }

constructor TMSGImporter.Create;
begin
  inherited;
  FErrors := TStringList.Create;
  FNodeMap := TDictionary<Integer, TDialogueNode>.Create;
end;

destructor TMSGImporter.Destroy;
begin
  FNodeMap.Free;
  FErrors.Free;
  inherited;
end;

function TMSGImporter.ParseLine(const ALine: string; out MsgID: Integer; out MsgText: string): Boolean;
var
  p1, p2, p3: Integer;
  idStr: string;
begin
  Result := False;
  MsgID := -1;
  MsgText := '';

  // Format: {id}{}{text}  or  {id}{sound}{text}
  p1 := Pos('{', ALine);
  if p1 = 0 then Exit;

  p2 := PosEx('}', ALine, p1 + 1);
  if p2 = 0 then Exit;

  idStr := Trim(Copy(ALine, p1 + 1, p2 - p1 - 1));
  if not TryStrToInt(idStr, MsgID) then Exit;

  // Find second {} pair (sound reference, usually empty)
  p1 := PosEx('{', ALine, p2 + 1);
  if p1 = 0 then Exit;
  p2 := PosEx('}', ALine, p1 + 1);
  if p2 = 0 then Exit;

  // p2+1 is start of text section; look for closing brace
  p3 := PosEx('}', ALine, p2 + 1);
  if p3 > p2 then
  begin
    // Third pair exists: {}{}{text}
    MsgText := Trim(Copy(ALine, p2 + 1, p3 - p2 - 1));
  end
  else
  begin
    // No closing brace for text section — take rest after second }
    MsgText := Trim(Copy(ALine, p2 + 1, Length(ALine)));
  end;

  // Unescape braces
  MsgText := StringReplace(MsgText, '\}', '}', [rfReplaceAll]);
  MsgText := StringReplace(MsgText, '\{', '{', [rfReplaceAll]);

  Result := MsgText <> '';
end;

function TMSGImporter.ImportFromText(const AText: string; out AProject: TDialogueProject): TMSGImportResult;
var
  idList: TList<Integer>;
  i, msgID: Integer;
  msgText: string;
  sorted: Boolean;
  node, prevNode: TDialogueNode;
  startNodeID: string;
begin
  FLines := TStringList.Create;
  idList := TList<Integer>.Create;
  try
    FLines.Text := AText;
    FErrors.Clear;
    FWarnings := 0;
    FNodeMap.Clear;

    // First pass: parse all messages
    for i := 0 to FLines.Count - 1 do
    begin
      var line := Trim(FLines[i]);
      if line = '' then Continue;
      if Length(line) >= 1 then
      begin
        if line[1] = '#' then Continue;
        if (Length(line) >= 2) and (line[1] = '/') and (line[2] = '/') then Continue;
        if line[1] <> '{' then Continue;
      end;

      if ParseLine(line, msgID, msgText) then
      begin
        if msgID >= 0 then
        begin
          idList.Add(msgID);
          FNodeMap.Add(msgID, nil); // placeholder
        end;
      end
      else if line <> '' then
      begin
        FErrors.Add('Line ' + IntToStr(i + 1) + ': Could not parse: ' + Copy(line, 1, 60));
      end;
    end;

    // Sort IDs to build linear chain
    sorted := True;
    for i := 0 to idList.Count - 2 do
      if idList[i] > idList[i + 1] then begin sorted := False; Break; end;
    if not sorted then idList.Sort;

    // Second pass: create nodes in ID order
    AProject := TDialogueProject.Create;
    prevNode := nil;
    startNodeID := '';

    for i := 0 to idList.Count - 1 do
    begin
      msgID := idList[i];
      // Find the text for this ID (re-parse or cache earlier)
      msgText := '';
      for var j := 0 to FLines.Count - 1 do
      begin
        var findID: Integer;
        var findText: string;
        if ParseLine(Trim(FLines[j]), findID, findText) and (findID = msgID) then
        begin
          msgText := findText;
          Break;
        end;
      end;

      if msgText = '' then
      begin
        FWarnings := FWarnings + 1;
        Continue;
      end;

      node := AProject.AddNode(ntNPCDialogue);
      node.ID := 'MSG_' + IntToStr(msgID);
      node.Text := msgText;
      node.Speaker := 'NPC';
      FNodeMap[msgID] := node;

      if startNodeID = '' then
        startNodeID := node.ID;

      // Link previous node to this one
      if Assigned(prevNode) then
        prevNode.NextNodeID := node.ID;

      prevNode := node;
    end;

    AProject.StartNodeID := startNodeID;
    AProject.Name := 'Imported from .MSG';

    Result.Project := AProject;
    Result.Success := (FErrors.Count = 0);
    Result.Errors := TStringList.Create;
    Result.Errors.Assign(FErrors);
    Result.WarningCount := FWarnings;
    Result.NodeCount := AProject.Nodes.Count;
  finally
    idList.Free;
    FLines.Free;
  end;
end;

function TMSGImporter.ImportFromFile(const AFilePath: string; out AProject: TDialogueProject): TMSGImportResult;
var
  content: string;
begin
  content := TFile.ReadAllText(AFilePath);
  Result := ImportFromText(content, AProject);
  if Result.Success and (AProject <> nil) then
    AProject.Name := ChangeFileExt(ExtractFileName(AFilePath), '');
end;

end.