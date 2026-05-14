unit MSGExporter;

interface

uses
   System.SysUtils, System.Classes, System.Generics.Collections, uDialogueTypes;

type
  TMSGExporter = class
  public
    class function ExportProject(AProject: TDialogueProject; const AFilePath: string): Boolean;
  end;

implementation

{ TMSGExporter }

class function TMSGExporter.ExportProject(AProject: TDialogueProject; const AFilePath: string): Boolean;
var
  Lines: TStringList;
  Node: TDialogueNode;
  Opt: TPlayerOption;
  LineNum: Integer;
  UsedIDs: TList<Integer>;
  text: string;
begin
  Result := False;
  Lines := TStringList.Create;
  UsedIDs := TList<Integer>.Create;
  try
    Lines.Add('# Fallout Dialogue Creator - Auto-generated Message File');
    Lines.Add('# Format: {line_number}{nul}{sound_file}{nul}{text}');
    Lines.Add('');

    LineNum := 100;
    for Node in AProject.Nodes do
    begin
      if Node.NodeType = ntComment then Continue;

      // NPC dialogue text
      if (Node.NodeType = ntNPCDialogue) and (Trim(Node.Text) <> '') then
      begin
        while UsedIDs.Contains(LineNum) do Inc(LineNum);
        text := StringReplace(Node.Text, '}', '\}', [rfReplaceAll]);
        text := StringReplace(text, '{', '[', [rfReplaceAll]);
        Lines.Add(Format('{%d}{}{%s}', [LineNum, text]));
        UsedIDs.Add(LineNum);
        Inc(LineNum, 10);
      end;

      // Player options
      for Opt in Node.PlayerOptions do
      begin
        if Trim(Opt.Text) = '' then Continue;
        while UsedIDs.Contains(LineNum) do Inc(LineNum);
        text := StringReplace(Opt.Text, '}', '\}', [rfReplaceAll]);
        text := StringReplace(text, '{', '[', [rfReplaceAll]);
        Lines.Add(Format('{%d}{}{%s}', [LineNum, text]));
        UsedIDs.Add(LineNum);
        Inc(LineNum, 10);

        if Opt.HasSkillCheck then
        begin
          if Opt.SkillCheck.SuccessMessage <> '' then
          begin
            while UsedIDs.Contains(LineNum) do Inc(LineNum);
            text := StringReplace(Opt.SkillCheck.SuccessMessage, '}', '\}', [rfReplaceAll]);
            Lines.Add(Format('{%d}{}{%s}', [LineNum, text]));
            UsedIDs.Add(LineNum);
            Inc(LineNum, 10);
          end;
          if Opt.SkillCheck.FailureMessage <> '' then
          begin
            while UsedIDs.Contains(LineNum) do Inc(LineNum);
            text := StringReplace(Opt.SkillCheck.FailureMessage, '}', '\}', [rfReplaceAll]);
            Lines.Add(Format('{%d}{}{%s}', [LineNum, text]));
            UsedIDs.Add(LineNum);
            Inc(LineNum, 10);
          end;
        end;
      end;
      Inc(LineNum, 10);
    end;

    // Float messages
    if AProject.FloatMessages.Count > 0 then
    begin
      Lines.Add('');
      Lines.Add('# ====== Float Messages ======');
      for var msg in AProject.FloatMessages do
      begin
        if Trim(msg.Text) = '' then Continue;
        text := StringReplace(msg.Text, '}', '\}', [rfReplaceAll]);
        Lines.Add(Format('{%d}{}{%s}', [LineNum, text]));
        Inc(LineNum, 10);
      end;
    end;

    Lines.SaveToFile(AFilePath, TEncoding.UTF8);
    Result := True;
  finally
    Lines.Free;
    UsedIDs.Free;
  end;
end;

end.