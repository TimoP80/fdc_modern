unit uValidationTools;

interface

uses
   System.SysUtils, System.Classes, VCL.Dialogs, System.Generics.Collections, System.StrUtils,
   Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls,
   Vcl.ExtCtrls, Vcl.Graphics, Vcl.Buttons,
   uDialogueTypes, uThemeManager;

type
   TValidationForm = class(TForm)
   private
     FProject: TDialogueProject;
     pnlTop: TPanel;
     lblTitle: TLabel;
     pnlBottom: TPanel;
     btnRun: TButton;
     btnClose: TButton;
     pcTools: TPageControl;
     tsValidation: TTabSheet;
     tsFlowAnalysis: TTabSheet;
     tsSearch: TTabSheet;
     lstIssues: TListView;
     memoFlowReport: TMemo;
     pnlSearchBar: TPanel;
     edtSearch: TEdit;
     btnSearch: TButton;
     cmbSearchIn: TComboBox;
     lstSearchResults: TListView;
     lblIssueCount: TLabel;
     btnFixAll: TButton;
     FOnNodeSelected: TProc<string>;
     procedure BuildLayout;
     procedure StyleForm;
     procedure RunValidation;
     procedure RunFlowAnalysis;
     procedure RunSearch;
     procedure btnRunClick(Sender: TObject);
     procedure btnCloseClick(Sender: TObject);
     procedure btnSearchClick(Sender: TObject);
     procedure btnFixAllClick(Sender: TObject);
     procedure lstIssuesDblClick(Sender: TObject);
     procedure FormCreate(Sender: TObject);
     procedure FormShow(Sender: TObject);
   public
     class procedure Execute(AOwner: TComponent; aProject: TDialogueProject);
property OnNodeSelected: TProc<string> read FOnNodeSelected write FOnNodeSelected;
      property Project: TDialogueProject read FProject write FProject;
    end;

implementation

type
  TControlHack = class(TControl) end;

class procedure TValidationForm.Execute(AOwner: TComponent; aProject: TDialogueProject);
var frm: TValidationForm;
begin
   frm := TValidationForm.CreateNew(AOwner);
   try
     frm.FProject := aProject;
     frm.BuildLayout;
     frm.StyleForm;
     frm.ShowModal;
   finally frm.Free; end;
end;

procedure TValidationForm.FormCreate(Sender: TObject);
begin BuildLayout; StyleForm; end;

procedure TValidationForm.FormShow(Sender: TObject);
begin RunValidation; end;

procedure TValidationForm.BuildLayout;
var
  searchLbl: TLabel;
begin
  Width := 760; Height := 560;
  Caption := 'Validation & Analysis Tools';
  Position := poMainFormCenter;
  OnCreate := FormCreate; OnShow := FormShow;

  pnlTop := TPanel.Create(Self); pnlTop.Parent := Self;
  pnlTop.Align := alTop; pnlTop.Height := 40; pnlTop.BevelOuter := bvNone;
  lblTitle := TLabel.Create(Self); lblTitle.Parent := pnlTop;
  lblTitle.Left := 10; lblTitle.Top := 8;
  lblTitle.Caption := 'PROJECT VALIDATION & ANALYSIS';
  lblTitle.Font.Size := 12; lblTitle.Font.Style := [fsBold];

  pnlBottom := TPanel.Create(Self); pnlBottom.Parent := Self;
  pnlBottom.Align := alBottom; pnlBottom.Height := 42; pnlBottom.BevelOuter := bvNone;

  btnRun := TButton.Create(Self); btnRun.Parent := pnlBottom;
  btnRun.Caption := 'Run All Checks'; btnRun.Left := 6; btnRun.Top := 7;
  btnRun.Width := 130; btnRun.Height := 28; btnRun.OnClick := btnRunClick;

  btnFixAll := TButton.Create(Self); btnFixAll.Parent := pnlBottom;
  btnFixAll.Caption := 'Auto-Fix Warnings'; btnFixAll.Left := 142; btnFixAll.Top := 7;
  btnFixAll.Width := 130; btnFixAll.Height := 28; btnFixAll.OnClick := btnFixAllClick;

  lblIssueCount := TLabel.Create(Self); lblIssueCount.Parent := pnlBottom;
  lblIssueCount.Left := 286; lblIssueCount.Top := 12;
  lblIssueCount.Caption := 'No issues found'; lblIssueCount.Width := 200;

  btnClose := TButton.Create(Self); btnClose.Parent := pnlBottom;
  btnClose.Caption := 'Close'; btnClose.ModalResult := mrOk;
  btnClose.Anchors := [akRight, akTop];
  btnClose.Left := pnlBottom.Width - 96; btnClose.Top := 7;
  btnClose.Width := 90; btnClose.Height := 28; btnClose.OnClick := btnCloseClick;

  pcTools := TPageControl.Create(Self); pcTools.Parent := Self;
  pcTools.Align := alClient;

  tsValidation := TTabSheet.Create(pcTools);
  tsValidation.PageControl := pcTools; tsValidation.Caption := 'Validation Issues';

  lstIssues := TListView.Create(Self); lstIssues.Parent := tsValidation;
  lstIssues.Align := alClient; lstIssues.ViewStyle := vsReport;
  lstIssues.RowSelect := True; lstIssues.GridLines := True;
  lstIssues.OnDblClick := lstIssuesDblClick;
  with lstIssues.Columns.Add do begin Caption := 'Severity'; Width := 70; end;
  with lstIssues.Columns.Add do begin Caption := 'Issue'; Width := 400; end;
  with lstIssues.Columns.Add do begin Caption := 'Node ID'; Width := 160; end;

  tsFlowAnalysis := TTabSheet.Create(pcTools);
  tsFlowAnalysis.PageControl := pcTools; tsFlowAnalysis.Caption := 'Flow Analysis';
  memoFlowReport := TMemo.Create(Self); memoFlowReport.Parent := tsFlowAnalysis;
  memoFlowReport.Align := alClient; memoFlowReport.ReadOnly := True;
  memoFlowReport.ScrollBars := ssBoth; memoFlowReport.WordWrap := False;
  memoFlowReport.Font.Name := 'Courier New'; memoFlowReport.Font.Size := 9;

  tsSearch := TTabSheet.Create(pcTools);
  tsSearch.PageControl := pcTools; tsSearch.Caption := 'Search Nodes';

  pnlSearchBar := TPanel.Create(Self); pnlSearchBar.Parent := tsSearch;
  pnlSearchBar.Align := alTop; pnlSearchBar.Height := 38; pnlSearchBar.BevelOuter := bvNone;

  searchLbl := TLabel.Create(Self); searchLbl.Parent := pnlSearchBar;
  searchLbl.Left := 4; searchLbl.Top := 10; searchLbl.Caption := 'Search:';

  edtSearch := TEdit.Create(Self); edtSearch.Parent := pnlSearchBar;
  edtSearch.Left := 56; edtSearch.Top := 7;
  edtSearch.Width := 280;

  cmbSearchIn := TComboBox.Create(Self); cmbSearchIn.Parent := pnlSearchBar;
  cmbSearchIn.Left := 344; cmbSearchIn.Top := 7;
  cmbSearchIn.Width := 160; cmbSearchIn.Style := csDropDownList;
  cmbSearchIn.Items.AddStrings(['All Fields', 'Node Text', 'Speaker', 'Node ID', 'Tag', 'Script Code']);

  btnSearch := TButton.Create(Self); btnSearch.Parent := pnlSearchBar;
  btnSearch.Caption := 'Search'; btnSearch.Left := 512; btnSearch.Top := 6;
  btnSearch.Width := 90; btnSearch.Height := 26; btnSearch.OnClick := btnSearchClick;

  lstSearchResults := TListView.Create(Self); lstSearchResults.Parent := tsSearch;
  lstSearchResults.Align := alClient; lstSearchResults.ViewStyle := vsReport;
  lstSearchResults.RowSelect := True; lstSearchResults.GridLines := True;
  with lstSearchResults.Columns.Add do begin Caption := 'Node ID'; Width := 150; end;
  with lstSearchResults.Columns.Add do begin Caption := 'Type'; Width := 100; end;
  with lstSearchResults.Columns.Add do begin Caption := 'Speaker'; Width := 100; end;
  with lstSearchResults.Columns.Add do begin Caption := 'Match'; Width := 340; end;
end;

procedure TValidationForm.StyleForm;
var t: TFDCTheme;
begin
  t := TThemeManager.Current;
  TControlHack(Self).Color := t.BgDark; Font.Color := t.TextPrimary; Font.Name := t.FontName;
  pnlTop.Color := t.BgMedium; pnlBottom.Color := t.BgMedium;
  lblTitle.Font.Color := t.AccentPrimary;
  lblIssueCount.Font.Color := t.TextSecondary;
  memoFlowReport.Color := t.BgDark; memoFlowReport.Font.Color := t.TextPrimary;
  lstIssues.Color := t.BgDark; lstIssues.Font.Color := t.TextPrimary;
  lstSearchResults.Color := t.BgDark; lstSearchResults.Font.Color := t.TextPrimary;
  edtSearch.Color := t.BgLight; edtSearch.Font.Color := t.TextPrimary;
  cmbSearchIn.Color := t.BgLight;
pnlSearchBar.Color := t.BgMedium;
   TControlHack(pcTools).Color := t.BgDark;
   TThemeManager.ApplyToForm(Self);
end;

procedure TValidationForm.RunValidation;
var
  issues: TStringList;
  item: TListItem;
  sev, msg, nodeID: string;
  t: TFDCTheme;
  errCount, warnCount: Integer;
  p: Integer;
  i: Integer;
begin
  if not Assigned(FProject) then Exit;
  t := TThemeManager.Current;
  lstIssues.Items.Clear;
  issues := FProject.ValidateProject;
  try
    errCount := 0;
    warnCount := 0;
    for i := 0 to issues.Count - 1 do
    begin
      item := lstIssues.Items.Add;
      if issues[i].StartsWith('ERROR:') then
      begin
        sev := 'ERROR'; msg := Copy(issues[i], 8, MaxInt); Inc(errCount);
        item.ImageIndex := 0;
      end else if issues[i].StartsWith('WARNING:') then
      begin
        sev := 'WARN'; msg := Copy(issues[i], 10, MaxInt); Inc(warnCount);
      end else
      begin
        sev := 'INFO'; msg := issues[i];
      end;
      item.Caption := sev;
      item.SubItems.Add(Trim(msg));
      p := Pos('node: ', LowerCase(issues[i]));
      if p > 0 then
        nodeID := Copy(issues[i], p + 6, 20)
      else
        nodeID := '';
      item.SubItems.Add(nodeID);
    end;

    if errCount > 0 then
      lblIssueCount.Caption := IntToStr(errCount) + ' error(s), ' + IntToStr(warnCount) + ' warning(s)'
    else if warnCount > 0 then
      lblIssueCount.Caption := 'No errors, ' + IntToStr(warnCount) + ' warning(s)'
    else
      lblIssueCount.Caption := 'All checks passed!';

    RunFlowAnalysis;
  finally
    issues.Free;
  end;
end;

procedure TValidationForm.RunFlowAnalysis;
var
  node, connected: TDialogueNode;
  connList: TList<TDialogueNode>;
  visited: TDictionary<string, Boolean>;
  queue: TQueue<TDialogueNode>;
  report: TStringList;
  orphanCount, endCount, loopRisk: Integer;
  npcCount, playerCount, condCount, scriptCount: Integer;
  totalOptions, skillCheckCount: Integer;
  startNode: TDialogueNode;
  i: Integer;
  opt: TPlayerOption;
begin
  if not Assigned(FProject) then Exit;
  report := TStringList.Create;
  visited := TDictionary<string, Boolean>.Create;
  queue := TQueue<TDialogueNode>.Create;
  try
    report.Add('=== DIALOGUE FLOW ANALYSIS ===');
    report.Add('Project: ' + FProject.Name);
    report.Add('Total nodes: ' + IntToStr(FProject.Nodes.Count));
    report.Add('Float messages: ' + IntToStr(FProject.FloatMessages.Count));
    report.Add('');

    orphanCount := 0; endCount := 0; loopRisk := 0;
    if FProject.StartNodeID <> '' then
    begin
      startNode := FProject.FindNode(FProject.StartNodeID);
      if Assigned(startNode) then
      begin
        queue.Enqueue(startNode);
        visited.Add(startNode.ID, True);
        report.Add('=== Reachability from Start Node ===');
        while queue.Count > 0 do
        begin
node := queue.Dequeue;
          if node.Speaker <> '' then
            report.Add('  [' + NODE_TYPE_NAMES[node.NodeType] + '] ' + Copy(node.ID, 1, 14) + ' (' + node.Speaker + ')')
          else
            report.Add('  [' + NODE_TYPE_NAMES[node.NodeType] + '] ' + Copy(node.ID, 1, 14));
          if node.NodeType = ntEndDialogue then Inc(endCount);
          connList := FProject.GetConnectedNodes(node.ID);
          try
            for connected in connList do
              if not visited.ContainsKey(connected.ID) then
              begin
                visited.Add(connected.ID, True);
                queue.Enqueue(connected);
              end else
                Inc(loopRisk);
          finally
            connList.Free;
          end;
        end;
      end;
    end;
    report.Add('');
    report.Add('Reachable nodes: ' + IntToStr(visited.Count) + ' / ' + IntToStr(FProject.Nodes.Count));

    for node in FProject.Nodes do
      if not visited.ContainsKey(node.ID) and not node.IsStartNode then
        Inc(orphanCount);

    report.Add('Orphaned (unreachable) nodes: ' + IntToStr(orphanCount));
    report.Add('End dialogue nodes: ' + IntToStr(endCount));
    report.Add('Potential loops detected: ' + IntToStr(loopRisk));
    report.Add('');

    npcCount := 0; playerCount := 0; condCount := 0; scriptCount := 0;
    totalOptions := 0; skillCheckCount := 0;
    for node in FProject.Nodes do
    begin
      case node.NodeType of
        ntNPCDialogue:   Inc(npcCount);
        ntPlayerReply:   Inc(playerCount);
        ntConditional:   Inc(condCount);
        ntScript:        Inc(scriptCount);
      end;
      Inc(totalOptions, node.PlayerOptions.Count);
      for i := 0 to node.PlayerOptions.Count - 1 do
      begin
        opt := node.PlayerOptions[i];
        if opt.HasSkillCheck then Inc(skillCheckCount);
      end;
    end;

    report.Add('=== NODE TYPE BREAKDOWN ===');
    report.Add('  NPC Dialogue nodes:  ' + IntToStr(npcCount));
    report.Add('  Player Reply nodes:  ' + IntToStr(playerCount));
    report.Add('  Conditional nodes:   ' + IntToStr(condCount));
    report.Add('  Script nodes:        ' + IntToStr(scriptCount));
    report.Add('  Total player options: ' + IntToStr(totalOptions));
    report.Add('  Skill checks:        ' + IntToStr(skillCheckCount));
    report.Add('');

    if orphanCount > 0 then
    begin
      report.Add('=== ORPHANED NODES ===');
      for node in FProject.Nodes do
        if not visited.ContainsKey(node.ID) and not node.IsStartNode then
        begin
          if Trim(node.Text) <> '' then
            report.Add('  ' + node.ID + '  [' + NODE_TYPE_NAMES[node.NodeType] + ']  "' + Copy(node.Text, 1, 40) + '"')
          else
            report.Add('  ' + node.ID + '  [' + NODE_TYPE_NAMES[node.NodeType] + ']');
        end;
    end;

    memoFlowReport.Lines.Assign(report);
  finally
    report.Free;
    visited.Free;
    queue.Free;
  end;
end;

procedure TValidationForm.RunSearch;
var
  node: TDialogueNode;
  searchText: string;
  searchIn: Integer;
  item: TListItem;
  matchField, matchText: string;
  found: Boolean;
  i: Integer;
  opt: TPlayerOption;
  sc: TNodeScript;

  function MatchesSearch(const s: string): Boolean;
  begin
    Result := ContainsText(s, searchText);
  end;

begin
  searchText := Trim(edtSearch.Text);
  if searchText = '' then Exit;
  searchIn := cmbSearchIn.ItemIndex;
  lstSearchResults.Items.Clear;

  for node in FProject.Nodes do
  begin
    found := False; matchField := ''; matchText := '';
    case searchIn of
      0:
      begin
        if MatchesSearch(node.Text) then begin found := True; matchField := 'Text'; matchText := node.Text; end
        else if MatchesSearch(node.Speaker) then begin found := True; matchField := 'Speaker'; matchText := node.Speaker; end
        else if MatchesSearch(node.ID) then begin found := True; matchField := 'ID'; matchText := node.ID; end
        else if MatchesSearch(node.Tag) then begin found := True; matchField := 'Tag'; matchText := node.Tag; end
        else if MatchesSearch(node.QuestID) then begin found := True; matchField := 'Quest'; matchText := node.QuestID; end;
        if not found then
          for i := 0 to node.PlayerOptions.Count - 1 do
          begin
            opt := node.PlayerOptions[i];
            if MatchesSearch(opt.Text) then begin found := True; matchField := 'Option'; matchText := opt.Text; Break; end;
          end;
        if not found then
          for i := 0 to node.Scripts.Count - 1 do
          begin
            sc := node.Scripts[i];
            if MatchesSearch(sc.ScriptCode) then begin found := True; matchField := 'Script'; matchText := Copy(sc.ScriptCode, 1, 60); Break; end;
          end;
      end;
      1: if MatchesSearch(node.Text) then begin found := True; matchField := 'Text'; matchText := node.Text; end;
      2: if MatchesSearch(node.Speaker) then begin found := True; matchField := 'Speaker'; matchText := node.Speaker; end;
      3: if MatchesSearch(node.ID) then begin found := True; matchField := 'ID'; matchText := node.ID; end;
      4: if MatchesSearch(node.Tag) then begin found := True; matchField := 'Tag'; matchText := node.Tag; end;
      5: for i := 0 to node.Scripts.Count - 1 do
         begin
           sc := node.Scripts[i];
           if MatchesSearch(sc.ScriptCode) then begin found := True; matchField := 'Script'; matchText := Copy(sc.ScriptCode, 1, 80); Break; end;
         end;
    end;

    if found then
    begin
      item := lstSearchResults.Items.Add;
      item.Caption := Copy(node.ID, 1, 16);
      item.SubItems.Add(NODE_TYPE_NAMES[node.NodeType]);
      item.SubItems.Add(node.Speaker);
      item.SubItems.Add('[' + matchField + '] ' + Copy(matchText, 1, 80));
      item.Data := node;
    end;
  end;

  lblIssueCount.Caption := 'Found: ' + IntToStr(lstSearchResults.Items.Count) + ' result(s)';
end;

procedure TValidationForm.btnRunClick(Sender: TObject); begin RunValidation; end;
procedure TValidationForm.btnCloseClick(Sender: TObject); begin Close; end;
procedure TValidationForm.btnSearchClick(Sender: TObject); begin RunSearch; end;

procedure TValidationForm.btnFixAllClick(Sender: TObject);
var
  fixed: Integer;
  node: TDialogueNode;
  i: Integer;
  opt: TPlayerOption;
begin
  if not Assigned(FProject) then Exit;
  fixed := 0;
  for node in FProject.Nodes do
  begin
    if (node.NextNodeID <> '') and not Assigned(FProject.FindNode(node.NextNodeID)) then
    begin node.NextNodeID := ''; Inc(fixed); end;
    for i := 0 to node.PlayerOptions.Count - 1 do
    begin
      opt := node.PlayerOptions[i];
      if (opt.TargetNodeID <> '') and not Assigned(FProject.FindNode(opt.TargetNodeID)) then
      begin opt.TargetNodeID := ''; Inc(fixed); end;
      if opt.HasSkillCheck then
      begin
        if (opt.SkillCheck.SuccessNodeID <> '') and not Assigned(FProject.FindNode(opt.SkillCheck.SuccessNodeID)) then
        begin opt.SkillCheck.SuccessNodeID := ''; Inc(fixed); end;
        if (opt.SkillCheck.FailureNodeID <> '') and not Assigned(FProject.FindNode(opt.SkillCheck.FailureNodeID)) then
        begin opt.SkillCheck.FailureNodeID := ''; Inc(fixed); end;
      end;
    end;
  end;
  if fixed > 0 then
  begin
    FProject.Modified := True;
    ShowMessage('Auto-fixed ' + IntToStr(fixed) + ' broken link(s).');
    RunValidation;
  end else
    ShowMessage('No auto-fixable issues found.');
end;

procedure TValidationForm.lstIssuesDblClick(Sender: TObject);
var
  item: TListItem;
  nodeID: string;
begin
  item := lstIssues.Selected;
  if not Assigned(item) then Exit;
  if item.SubItems.Count < 2 then Exit;
  nodeID := Trim(item.SubItems[1]);
  if (nodeID <> '') and Assigned(FOnNodeSelected) then
    FOnNodeSelected(nodeID);
end;

initialization
  RegisterClass(TValidationForm);

end.