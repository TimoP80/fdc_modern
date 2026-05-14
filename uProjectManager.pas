unit uProjectManager;

// uProjectManager - Compatibility wrapper for the main form
// Delegates to uDialogueTypes.TDialogueProject for core functionality

interface

uses
  System.SysUtils, System.Classes, System.Math, System.IOUtils,
  Vcl.Dialogs,
  uDialogueTypes;

type
  TRecentProject = record
    Path: string;
    Name: string;
    LastOpened: TDateTime;
  end;

  TProjectManager = class
  private
    FRecentProjects: TArray<TRecentProject>;
    FRecentFile: string;
    procedure LoadRecent;
    procedure SaveRecent;
    procedure AddToRecentInternal(const path, name: string);
  public
    constructor Create;
    destructor Destroy; override;

    function NewProject: TDialogueProject;
    function OpenProject(const path: string = ''): TDialogueProject;
    function SaveProject(project: TDialogueProject; saveAs: Boolean = False): Boolean;
    function CreateSampleProject: TDialogueProject;
    procedure AddToRecent(const path, name: string);
    function GetRecent: TArray<TRecentProject>;
  end;

implementation

{ TProjectManager }

constructor TProjectManager.Create;
begin
  inherited;
  FRecentFile := ChangeFileExt(ParamStr(0), '.recent');
  LoadRecent;
end;

destructor TProjectManager.Destroy;
begin
  inherited;
end;

procedure TProjectManager.LoadRecent;
var
  sl: TStringList;
  i: Integer;
begin
  SetLength(FRecentProjects, 0);
  if not FileExists(FRecentFile) then Exit;
  sl := TStringList.Create;
  try
    sl.LoadFromFile(FRecentFile);
    SetLength(FRecentProjects, sl.Count);
    for i := 0 to sl.Count - 1 do
    begin
      FRecentProjects[i].Path := sl.Names[i];
      FRecentProjects[i].Name := sl.ValueFromIndex[i];
      FRecentProjects[i].LastOpened := Now;
    end;
  finally
    sl.Free;
  end;
end;

procedure TProjectManager.SaveRecent;
var
  sl: TStringList;
  i, count: Integer;
begin
  sl := TStringList.Create;
  try
    count := Min(High(FRecentProjects) + 1, 10);
    for i := 0 to count - 1 do
      sl.Add(FRecentProjects[i].Path + '=' + FRecentProjects[i].Name);
    sl.SaveToFile(FRecentFile);
  finally
    sl.Free;
  end;
end;

procedure TProjectManager.AddToRecentInternal(const path, name: string);
var
  arr: TArray<TRecentProject>;
  i: Integer;
begin
  SetLength(arr, 0);
  for i := 0 to High(FRecentProjects) do
    if FRecentProjects[i].Path <> path then
    begin
      SetLength(arr, Length(arr) + 1);
      arr[High(arr)] := FRecentProjects[i];
    end;
  SetLength(FRecentProjects, Length(arr) + 1);
  FRecentProjects[0].Path := path;
  FRecentProjects[0].Name := name;
  FRecentProjects[0].LastOpened := Now;
  for i := 0 to High(arr) do
    FRecentProjects[i + 1] := arr[i];
  SaveRecent;
end;

procedure TProjectManager.AddToRecent(const path, name: string);
begin
  AddToRecentInternal(path, name);
end;

function TProjectManager.GetRecent: TArray<TRecentProject>;
begin
  Result := FRecentProjects;
end;

function TProjectManager.NewProject: TDialogueProject;
begin
  Result := TDialogueProject.Create;
  Result.Name := 'New Dialogue';
end;

function TProjectManager.OpenProject(const path: string): TDialogueProject;
var
  dlg: TOpenDialog;
  filePath: string;
  proj: TDialogueProject;
begin
  Result := nil;
  filePath := path;
  if filePath = '' then
  begin
    dlg := TOpenDialog.Create(nil);
    try
      dlg.Filter := 'Fallout Dialogue Creator|*.fdc;*.json|All Files|*.*';
      dlg.Title := 'Open Dialogue Project';
      if not dlg.Execute then Exit;
      filePath := dlg.FileName;
    finally
      dlg.Free;
    end;
  end;
  if not FileExists(filePath) then Exit;
  proj := TDialogueProject.Create;
  if proj.LoadFromFile(filePath) then
  begin
    AddToRecent(filePath, proj.Name);
    Result := proj;
  end
  else
  begin
    proj.Free;
    // Silently fail - caller checks for nil
  end;
end;

function TProjectManager.SaveProject(project: TDialogueProject; saveAs: Boolean): Boolean;
var
  dlg: TSaveDialog;
  filePath: string;
begin
  Result := False;
  if not Assigned(project) then Exit;
  filePath := project.FilePath;
  if saveAs or (filePath = '') then
  begin
    dlg := TSaveDialog.Create(nil);
    try
      dlg.Filter := 'Fallout Dialogue Creator|*.fdc|JSON File|*.json|All Files|*.*';
      dlg.Title := 'Save Dialogue Project';
      dlg.DefaultExt := 'fdc';
      dlg.FileName := ChangeFileExt(ExtractFileName(project.Name), '');
      if not dlg.Execute then Exit;
      filePath := dlg.FileName;
    finally
      dlg.Free;
    end;
  end;
  Result := project.SaveToFile(filePath);
  if Result then
    AddToRecent(filePath, project.Name);
end;

function TProjectManager.CreateSampleProject: TDialogueProject;
var
  proj: TDialogueProject;
  node1, node2, node3, node4, node5, node6: TDialogueNode;
  opt1, opt2, opt3: TPlayerOption;
  float1, float2, float3: TFloatMessage;
begin
  proj := TDialogueProject.Create;
  proj.Name := 'Sample Dialogue - Harold the Ghoul';
  proj.NPCName := 'Harold';
  proj.NPCScript := 'harold_dialogue';
  proj.Description := 'A sample branching dialogue tree demonstrating FDC features.';
  proj.Author := 'Fallout Dialogue Creator';
  proj.Version := '1.0';

  // Initial greeting node
  node1 := proj.AddNode(ntNPCDialogue);
  node1.Speaker := 'Harold';
  node1.Text := 'Oh, another wanderer passing through the wasteland. Guess you''re not here to trade, or you would''ve said so by now. What do you want?';
  node1.X := 60; node1.Y := 80;
  node1.Width := 280; node1.Height := 120;
  node1.Color := $002B1F0F;
  node1.IsStartNode := True;
  proj.StartNodeID := node1.ID;
  node1.Comment := 'Opening node - first contact with Harold';

  // Player reply node
  node2 := proj.AddNode(ntPlayerReply);
  node2.Speaker := 'Player';
  node2.X := 420; node2.Y := 80;
  node2.Width := 280; node2.Height := 180;
  node1.NextNodeID := node2.ID;

  opt1 := TPlayerOption.Create;
  opt1.Text := 'I''m looking for information about the vault.';
  opt1.TargetNodeID := ''; // Will be set below
  node2.PlayerOptions.Add(opt1);

  opt2 := TPlayerOption.Create;
  opt2.Text := '[Speech 60%] Maybe we can help each other out. I have caps.';
  opt2.HasSkillCheck := True;
  opt2.SkillCheck.Skill := skSpeech;
  opt2.SkillCheck.Difficulty := 60;
  opt2.SkillCheck.CritSuccessBonus := 10;
  opt2.SkillCheck.XPReward := 50;
  opt2.SkillCheck.SuccessMessage := 'Your silver tongue works its magic on the old ghoul.';
  opt2.SkillCheck.FailureMessage := 'Harold sees right through your silver-tongued act.';
  node2.PlayerOptions.Add(opt2);

  opt3 := TPlayerOption.Create;
  opt3.Text := 'Never mind. Goodbye.';
  opt3.TargetNodeID := ''; // Will be set below
  node2.PlayerOptions.Add(opt3);

  // Vault info response
  node3 := proj.AddNode(ntNPCDialogue);
  node3.Speaker := 'Harold';
  node3.Text := 'The vault? Heh, you and half the wasteland. Word is there''s an old Vault-Tec facility east of here, past the rad scorpion territory. Can''t miss it — look for the mountain with the big crack in it. But I wouldn''t go there alone if I were you.';
  node3.X := 780; node3.Y := 40;
  node3.Width := 280; node3.Height := 160;
  node3.Color := $002B1F0F;
  opt1.TargetNodeID := node3.ID;
  node3.Comment := 'Harold gives vault location info';
  node3.QuestID := 'FIND_THE_VAULT';

  // Speech success node
  node4 := proj.AddNode(ntNPCDialogue);
  node4.Speaker := 'Harold';
  node4.Text := 'Ha! Now you''re talking my language. Alright, I''ll tell you what I know — and believe me, Harold knows plenty. Pull up a rock and sit down. It''s a long story, and Bob here gets cranky if I rush it.';
  node4.X := 1060; node4.Y := 40;
  node4.Width := 280; node4.Height := 140;
  node4.Color := $002B1F0F;
  opt2.SkillCheck.SuccessNodeID := node4.ID;
  node4.Comment := 'Harold opens up after successful speech check';
  var sc1 := TNodeScript.Create;
  sc1.EventType := seOnNodeEnter;
  sc1.ScriptCode := 'procedure OnNodeEnter(npc, player: TEntity; nodeID: string);' + sLineBreak +
    'begin' + sLineBreak +
    '  modify_rep("HAROLD_FACTION", 10);' + sLineBreak +
    'end;';
  sc1.IsEnabled := True;
  node4.Scripts.Add(sc1);

  // Speech fail node
  node5 := proj.AddNode(ntNPCDialogue);
  node5.Speaker := 'Harold';
  node5.Text := 'Caps? You think Harold can be bought that easy? I''ve been around since before you were a twinkle in your daddy''s eye. Go peddle that somewhere else, kid.';
  node5.X := 1060; node5.Y := 220;
  node5.Width := 280; node5.Height := 120;
  node5.Color := $002B1F0F;
  opt2.SkillCheck.FailureNodeID := node5.ID;
  node5.Comment := 'Harold rejects the player''s bribery attempt';
  var cond1: TCondition;
  cond1.CondType := ctReputation;
  cond1.Variable := 'HAROLD_FACTION';
  cond1.Operator := coLTE;
  cond1.Value := '-50';
  cond1.BoolOp := boAND;
  node5.Conditions.Add(cond1);

  // Quest update node after vault info
  node6 := proj.AddNode(ntQuestUpdate);
  node6.QuestID := 'FIND_THE_VAULT';
  node6.QuestFlag := '1';
  node6.X := 780; node6.Y := 220;
  node6.Width := 200; node6.Height := 80;
  node3.NextNodeID := node6.ID;
  var sc2 := TNodeScript.Create;
  sc2.EventType := seOnQuestUpdate;
  sc2.ScriptCode := 'procedure OnQuestUpdate(questID: string; state: Integer);' + sLineBreak +
    'begin' + sLineBreak +
    '  set_global_var("GVAR_VAULT_LOCATION_KNOWN", 1);' + sLineBreak +
    '  add_journal(questID, state);' + sLineBreak +
    '  give_xp(100);' + sLineBreak +
    'end;';
  sc2.IsEnabled := True;
  node6.Scripts.Add(sc2);

  // End node
  var nodeEnd := proj.AddNode(ntEndDialogue);
  nodeEnd.X := 1340; nodeEnd.Y := 200;
  nodeEnd.Width := 160; nodeEnd.Height := 60;
  node6.NextNodeID := nodeEnd.ID;
  node5.NextNodeID := nodeEnd.ID;
  opt3.TargetNodeID := nodeEnd.ID;
  var sc3 := TNodeScript.Create;
  sc3.EventType := seOnDialogueEnd;
  sc3.ScriptCode := 'procedure OnDialogueEnd(npc, player: TEntity);' + sLineBreak +
    'begin' + sLineBreak +
    '  set_global_var("GVAR_SPOKE_TO_HAROLD", 1);' + sLineBreak +
    'end;';
  sc3.IsEnabled := True;
  nodeEnd.Scripts.Add(sc3);

  // Trade node
  var nodeTrade := proj.AddNode(ntTrade);
  nodeTrade.Speaker := 'Harold';
  nodeTrade.Text := 'Fine, let''s see what you''ve got. But don''t try to cheat old Harold — I''ve been around long enough to know a bad deal when I see one.';
  nodeTrade.X := 780; nodeTrade.Y := 380;
  nodeTrade.Width := 240; nodeTrade.Height := 100;
  nodeTrade.TradeInventory := 'RadAway x3; Stimpak x5; Brahmin Jerky x10';

  // Float messages
  float1 := TFloatMessage.Create;
  float1.ID := 'FLOAT_AMBIENT_001';
  float1.Text := 'Damned rad scorpions... they''re getting worse every year.';
  float1.Category := 'Ambient';
  float1.Priority := 5;
  float1.Weight := 3;
  float1.TimedDuration := 4.0;
  float1.IsAmbient := True;
  float1.LocaleKey := 'harold_bark_scorpions';
  proj.FloatMessages.Add(float1);

  float2 := TFloatMessage.Create;
  float2.ID := 'FLOAT_AMBIENT_002';
  float2.Text := 'I''ve seen things that would make your hair fall out. Not that mine didn''t already.';
  float2.Category := 'Ambient';
  float2.Priority := 6;
  float2.Weight := 2;
  float2.TimedDuration := 4.5;
  float2.IsAmbient := True;
  float2.LocaleKey := 'harold_bark_hair';
  proj.FloatMessages.Add(float2);

  float3 := TFloatMessage.Create;
  float3.ID := 'FLOAT_COMBAT_001';
  float3.Text := 'Don''t make me call Bob!';
  float3.Category := 'Combat Taunt';
  float3.Priority := 8;
  float3.Weight := 1;
  float3.TimedDuration := 2.5;
  float3.IsCombatTaunt := True;
  float3.LocaleKey := 'harold_taunt_bob';
  proj.FloatMessages.Add(float3);

  // Global vars
  proj.GlobalVars.Add('GVAR_MET_HAROLD', '0');
  proj.GlobalVars.Add('GVAR_SPOKE_TO_HAROLD', '0');
  proj.GlobalVars.Add('GVAR_VAULT_LOCATION_KNOWN', '0');
  proj.GlobalVars.Add('GVAR_HAROLD_ATTITUDE', '50');

  // Locales
  proj.Locales.Clear;
  proj.Locales.Add('en-US');
  proj.Locales.Add('de-DE');
  proj.Locales.Add('fr-FR');
  proj.Locales.Add('ru-RU');
  proj.ActiveLocale := 'en-US';
  proj.Tags.CommaText := 'sample,harold,ghoul,demo';

  proj.Modified := False;
  Result := proj;
end;

end.