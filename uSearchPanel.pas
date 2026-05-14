unit uSearchPanel;

interface

uses System.SysUtils, System.Classes, uDialogueTypes;

type
  TSearchResult = record
    NodeID: string;
    Field: string;
    Context: string;
  end;

  TSearchHelper = class
    class function SearchProject(project: TDialogueProject; const query: string;
      caseSensitive: Boolean = False): TArray<TSearchResult>;
  end;

implementation

class function TSearchHelper.SearchProject(project: TDialogueProject;
  const query: string; caseSensitive: Boolean): TArray<TSearchResult>;
var
  results: TArray<TSearchResult>;
  node: TDialogueNode;
  q: string;
  i: Integer;
  opt: TPlayerOption;
  sc: TNodeScript;
  msg: TFloatMessage;

  procedure AddResult(const nodeID, field, ctx: string);
  begin
    SetLength(results, Length(results) + 1);
    results[High(results)].NodeID := nodeID;
    results[High(results)].Field := field;
    results[High(results)].Context := ctx;
  end;

  function Match(const s: string): Boolean;
  begin
    if caseSensitive then Result := Pos(q, s) > 0
    else Result := Pos(LowerCase(q), LowerCase(s)) > 0;
  end;

begin
  q := query;
  SetLength(results, 0);
  if not Assigned(project) or (Trim(q) = '') then begin Result := results; Exit; end;

  for node in project.Nodes do
  begin
    if Match(node.Text) then AddResult(node.ID, 'Text', Copy(node.Text, 1, 80));
    if Match(node.Speaker) then AddResult(node.ID, 'Speaker', node.Speaker);
    if Match(node.Tag) then AddResult(node.ID, 'Tag', node.Tag);
    if Match(node.QuestID) then AddResult(node.ID, 'QuestID', node.QuestID);
    if Match(node.Notes) then AddResult(node.ID, 'Notes', Copy(node.Notes, 1, 80));
    for i := 0 to node.PlayerOptions.Count - 1 do
    begin
      opt := node.PlayerOptions[i];
      if Match(opt.Text) then AddResult(node.ID, 'Option', Copy(opt.Text, 1, 80));
      if Match(opt.ItemRequired) then AddResult(node.ID, 'ItemReq', opt.ItemRequired);
    end;
    for i := 0 to node.Scripts.Count - 1 do
    begin
      sc := node.Scripts[i];
      if Match(sc.ScriptCode) then AddResult(node.ID, 'Script', Copy(sc.ScriptCode, 1, 80));
    end;
  end;

  for i := 0 to project.FloatMessages.Count - 1 do
  begin
    msg := project.FloatMessages[i];
    if Match(msg.Text) then AddResult('FLOAT:' + msg.ID, 'FloatMsg', Copy(msg.Text, 1, 80));
  end;

  Result := results;
end;

end.