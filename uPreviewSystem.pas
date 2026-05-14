unit uPreviewSystem;

// uPreviewSystem - Dialogue simulation preview form

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Math, System.TypInfo, System.StrUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Buttons, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.PNGImage,
  Winapi.Windows,
  Vcl.Graphics,
  uDialogueTypes, uThemeManager;

type
  TSimVariable = record
    Name: string;
    Value: Integer;
  end;

  TPreviewHistory = record
    NodeID: string;
    NodeType: TNodeType;
    Speaker: string;
    Text: string;
    ChoiceMade: string;
  end;

  TPreviewForm = class(TForm)
  private
    FProject: TDialogueProject;
    FCurrentNode: TDialogueNode;
    FHistory: TList<TPreviewHistory>;
    FSimVars: TDictionary<string, Integer>;
    FSimSkills: TDictionary<string, Integer>;
    FSimInventory: TStringList;
    FSimKarma: Integer;
    FSimReputation: Integer;
    FSimQuestFlags: TDictionary<string, Integer>;
    FOnFinished: TNotifyEvent;

    // UI panels
    pnlMain: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    splitter: TSplitter;

    // Left: game view
    pnlGameView: TPanel;
    pnlPortrait: TPanel;
    imgPortrait: TImage;
    lblNPCName: TLabel;
    pnlDialogue: TPanel;
    memoDialogue: TMemo;
    pnlOptions: TPanel;
    scrollOptions: TScrollBox;
    pnlHistory: TPanel;
    lblHistoryTitle: TLabel;
    lstHistory: TListBox;
    pnlControls: TPanel;
    btnRestart: TButton;
    btnStepBack: TButton;
    btnClose: TButton;
    chkAutoAdvance: TCheckBox;
    lblNodeInfo: TLabel;

    // Right: variable inspector
    pnlInspector: TPanel;
    lblInspTitle: TLabel;
    pcInspector: TPageControl;
    tsVars: TTabSheet;
    tsSkills: TTabSheet;
    tsInventory: TTabSheet;
    tsQuests: TTabSheet;

    // Variable editors
    lvVars: TListView;
    lvSkills: TListView;
    lstInventory: TListBox;
    lvQuests: TListView;
    edtAddItem: TEdit;
    btnAddItem: TButton;
    btnRemItem: TButton;

    // Option buttons (dynamically created)
    FOptionButtons: TList<TButton>;

    procedure BuildLayout;
    procedure StyleUI;
    procedure InitSimulation;
    procedure NavigateToNode(const nodeID: string);
    procedure DisplayNode(node: TDialogueNode);
    procedure BuildOptionButtons(node: TDialogueNode);
    procedure ClearOptionButtons;
    procedure AddHistoryEntry(node: TDialogueNode; const choice: string);
    procedure UpdateInspector;
    procedure UpdateSkillsView;
    procedure UpdateVarsView;
    procedure UpdateQuestsView;

    function EvaluateCondition(const cond: TCondition): Boolean;
    function EvaluateAllConditions(node: TDialogueNode): Boolean;
    function EvaluateOptionConditions(opt: TPlayerOption): Boolean;
    function SimulateSkillCheck(const sk: TSkillCheck): Boolean;
    function GetSkillValue(const skillName: string): Integer;
    function GetSimVar(const name: string): Integer;

    procedure OptionButtonClick(Sender: TObject);
    procedure btnRestartClick(Sender: TObject);
    procedure btnStepBackClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddItemClick(Sender: TObject);
    procedure btnRemItemClick(Sender: TObject);
    procedure lvSkillsDblClick(Sender: TObject);
    procedure lvVarsDblClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DrawPortraitPlaceholder;
    procedure LoadPortrait(const filename: string);
    procedure AddStatusMessage(const msg: string; color: TColor);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    class procedure RunPreview(AOwner: TComponent; project: TDialogueProject;
      const startNodeID: string = ''; AOnFinished: TNotifyEvent = nil);
  end;

implementation

type
  TControlHack = class(TControl) end;

{ TPreviewForm }

constructor TPreviewForm.Create(AOwner: TComponent);
begin
   inherited CreateNew(AOwner);
   FHistory := TList<TPreviewHistory>.Create;
   FSimVars := TDictionary<string, Integer>.Create;
   FSimSkills := TDictionary<string, Integer>.Create;
   FSimInventory := TStringList.Create;
   FSimQuestFlags := TDictionary<string, Integer>.Create;
   FOptionButtons := TList<TButton>.Create;
   FSimKarma := 0;
   FSimReputation := 0;
   BuildLayout;
   StyleUI;
   KeyPreview := True;
   OnKeyDown := FormKeyDown;
end;

destructor TPreviewForm.Destroy;
begin
  FHistory.Free;
  FSimVars.Free;
  FSimSkills.Free;
  FSimInventory.Free;
  FSimQuestFlags.Free;
  FOptionButtons.Free;
  inherited;
end;

class procedure TPreviewForm.RunPreview(AOwner: TComponent; project: TDialogueProject;
  const startNodeID: string; AOnFinished: TNotifyEvent);
var
  frm: TPreviewForm;
begin
  frm := TPreviewForm.Create(AOwner);
  try
    frm.FProject := project;
    frm.FOnFinished := AOnFinished;
    frm.Caption := 'Dialogue Preview  -  ' + project.Name;
    frm.InitSimulation;
    if startNodeID <> '' then
      frm.NavigateToNode(startNodeID)
    else if project.StartNodeID <> '' then
      frm.NavigateToNode(project.StartNodeID)
    else if project.Nodes.Count > 0 then
      frm.NavigateToNode(project.Nodes[0].ID);
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;

procedure TPreviewForm.BuildLayout;
var
  skill: TSkillType;
  ct: TConditionType;
  co: TConditionOperator;
  se: TScriptEvent;
  lbl: TLabel;
  btn: TButton;
begin
  Width := 1100;
  Height := 700;
  Position := poMainFormCenter;
  Caption := 'Dialogue Preview';
  BorderStyle := bsSizeable;

  // Main panel
  pnlMain := TPanel.Create(Self);
  pnlMain.Parent := Self;
  pnlMain.Align := alClient;
  pnlMain.BevelOuter := bvNone;

  // Left panel (game view)
  pnlLeft := TPanel.Create(Self);
  pnlLeft.Parent := pnlMain;
  pnlLeft.Align := alLeft;
  pnlLeft.Width := 680;
  pnlLeft.BevelOuter := bvNone;

  splitter := TSplitter.Create(Self);
  splitter.Parent := pnlMain;
  splitter.Align := alLeft;
  splitter.Width := 5;

  // Right panel (inspector)
  pnlRight := TPanel.Create(Self);
  pnlRight.Parent := pnlMain;
  pnlRight.Align := alClient;
  pnlRight.BevelOuter := bvNone;

  // ==== GAME VIEW (left) ====

  // Controls bar at bottom of left
  pnlControls := TPanel.Create(Self);
  pnlControls.Parent := pnlLeft;
  pnlControls.Align := alBottom;
  pnlControls.Height := 44;
  pnlControls.BevelOuter := bvNone;

  btnRestart := TButton.Create(Self);
  btnRestart.Parent := pnlControls;
  btnRestart.Caption := 'Restart';
  btnRestart.Left := 6; btnRestart.Top := 8;
  btnRestart.Width := 90; btnRestart.Height := 28;
  btnRestart.OnClick := btnRestartClick;

  btnStepBack := TButton.Create(Self);
  btnStepBack.Parent := pnlControls;
  btnStepBack.Caption := 'Back';
  btnStepBack.Left := 102; btnStepBack.Top := 8;
  btnStepBack.Width := 80; btnStepBack.Height := 28;
  btnStepBack.OnClick := btnStepBackClick;

  chkAutoAdvance := TCheckBox.Create(Self);
  chkAutoAdvance.Parent := pnlControls;
  chkAutoAdvance.Caption := 'Auto-advance NPC';
  chkAutoAdvance.Left := 194; chkAutoAdvance.Top := 12;
  chkAutoAdvance.Width := 160;

  lblNodeInfo := TLabel.Create(Self);
  lblNodeInfo.Parent := pnlControls;
  lblNodeInfo.Left := 360; lblNodeInfo.Top := 12;
  lblNodeInfo.Caption := 'Node: -';
  lblNodeInfo.Width := 280;

  btnClose := TButton.Create(Self);
  btnClose.Parent := pnlControls;
  btnClose.Caption := 'Close';
  btnClose.Anchors := [akRight, akTop];
  btnClose.Left := pnlControls.Width - 92; btnClose.Top := 8;
  btnClose.Width := 86; btnClose.Height := 28;
  btnClose.ModalResult := mrCancel;
  btnClose.OnClick := btnCloseClick;

  // History panel at bottom of game area
  pnlHistory := TPanel.Create(Self);
  pnlHistory.Parent := pnlLeft;
  pnlHistory.Align := alBottom;
  pnlHistory.Height := 130;
  pnlHistory.BevelOuter := bvNone;

  lblHistoryTitle := TLabel.Create(Self);
  lblHistoryTitle.Parent := pnlHistory;
  lblHistoryTitle.Left := 6; lblHistoryTitle.Top := 4;
  lblHistoryTitle.Caption := 'CONVERSATION LOG';
  lblHistoryTitle.Font.Style := [fsBold];

  lstHistory := TListBox.Create(Self);
  lstHistory.Parent := pnlHistory;
  lstHistory.Align := alClient;
  lstHistory.Style := lbOwnerDrawFixed;
  lstHistory.ItemHeight := 20;

  // Options panel
  pnlOptions := TPanel.Create(Self);
  pnlOptions.Parent := pnlLeft;
  pnlOptions.Align := alBottom;
  pnlOptions.Height := 220;
  pnlOptions.BevelOuter := bvNone;

  scrollOptions := TScrollBox.Create(Self);
  scrollOptions.Parent := pnlOptions;
  scrollOptions.Align := alClient;
  scrollOptions.BorderStyle := bsNone;
  scrollOptions.VertScrollBar.Smooth := True;

  // Portrait + dialogue area
  pnlGameView := TPanel.Create(Self);
  pnlGameView.Parent := pnlLeft;
  pnlGameView.Align := alClient;
  pnlGameView.BevelOuter := bvNone;

  pnlPortrait := TPanel.Create(Self);
  pnlPortrait.Parent := pnlGameView;
  pnlPortrait.Align := alLeft;
  pnlPortrait.Width := 140;
  pnlPortrait.BevelOuter := bvNone;

  imgPortrait := TImage.Create(Self);
  imgPortrait.Parent := pnlPortrait;
  imgPortrait.Align := alTop;
  imgPortrait.Height := 140;
  imgPortrait.Stretch := True;
  imgPortrait.Proportional := True;
  imgPortrait.Center := True;

  lblNPCName := TLabel.Create(Self);
  lblNPCName.Parent := pnlPortrait;
  lblNPCName.Align := alTop;
  lblNPCName.AlignWithMargins := True;
  lblNPCName.Margins.Top := 4;
  lblNPCName.Alignment := taCenter;
  lblNPCName.Caption := 'NPC';
  lblNPCName.Font.Style := [fsBold];
  lblNPCName.Font.Size := 10;
  lblNPCName.WordWrap := True;

  pnlDialogue := TPanel.Create(Self);
  pnlDialogue.Parent := pnlGameView;
  pnlDialogue.Align := alClient;
  pnlDialogue.BevelOuter := bvNone;
  pnlDialogue.BevelInner := bvLowered;

  memoDialogue := TMemo.Create(Self);
  memoDialogue.Parent := pnlDialogue;
  memoDialogue.Align := alClient;
  memoDialogue.ReadOnly := True;
  memoDialogue.WordWrap := True;
  memoDialogue.Font.Size := 12;
  memoDialogue.BorderStyle := bsNone;

  // ==== INSPECTOR (right) ====
  pnlInspector := TPanel.Create(Self);
  pnlInspector.Parent := pnlRight;
  pnlInspector.Align := alClient;
  pnlInspector.BevelOuter := bvNone;

  lblInspTitle := TLabel.Create(Self);
  lblInspTitle.Parent := pnlInspector;
  lblInspTitle.Align := alTop;
  lblInspTitle.AlignWithMargins := True;
  lblInspTitle.Margins.Top := 6;
  lblInspTitle.Margins.Left := 8;
  lblInspTitle.Caption := 'VARIABLE INSPECTOR';
  lblInspTitle.Font.Style := [fsBold];

  pcInspector := TPageControl.Create(Self);
  pcInspector.Parent := pnlInspector;
  pcInspector.Align := alClient;

  tsVars := TTabSheet.Create(pcInspector);
  tsVars.PageControl := pcInspector;
  tsVars.Caption := 'Global Vars';

  lvVars := TListView.Create(Self);
  lvVars.Parent := tsVars;
  lvVars.Align := alClient;
  lvVars.ViewStyle := vsReport;
  lvVars.RowSelect := True;
  lvVars.GridLines := True;
  lvVars.OnDblClick := lvVarsDblClick;
  lvVars.Columns.Add.Caption := 'Variable';
  lvVars.Columns.Add.Caption := 'Value';

  tsSkills := TTabSheet.Create(pcInspector);
  tsSkills.PageControl := pcInspector;
  tsSkills.Caption := 'Skills';

  lvSkills := TListView.Create(Self);
  lvSkills.Parent := tsSkills;
  lvSkills.Align := alClient;
  lvSkills.ViewStyle := vsReport;
  lvSkills.RowSelect := True;
  lvSkills.GridLines := True;
  lvSkills.OnDblClick := lvSkillsDblClick;
  lvSkills.Columns.Add.Caption := 'Skill';
  lvSkills.Columns.Add.Caption := 'Value';
  lvSkills.Columns.Add.Caption := 'Tag';

  // Pre-populate skills
  for skill := Low(TSkillType) to High(TSkillType) do
  begin
    var item := lvSkills.Items.Add;
    item.Caption := SKILL_NAMES[skill];
    item.SubItems.Add('40');
    item.SubItems.Add('');
  end;

  tsInventory := TTabSheet.Create(pcInspector);
  tsInventory.PageControl := pcInspector;
  tsInventory.Caption := 'Inventory';

  var invPanel := TPanel.Create(Self);
  invPanel.Parent := tsInventory;
  invPanel.Align := alBottom;
  invPanel.Height := 36;
  invPanel.BevelOuter := bvNone;

  edtAddItem := TEdit.Create(Self);
  edtAddItem.Parent := invPanel;
  edtAddItem.Left := 4; edtAddItem.Top := 6;
  edtAddItem.Width := 130; edtAddItem.Height := 24;

  btnAddItem := TButton.Create(Self);
  btnAddItem.Parent := invPanel;
  btnAddItem.Caption := '+';
  btnAddItem.Left := 138; btnAddItem.Top := 6;
  btnAddItem.Width := 28; btnAddItem.Height := 24;
  btnAddItem.OnClick := btnAddItemClick;

  btnRemItem := TButton.Create(Self);
  btnRemItem.Parent := invPanel;
  btnRemItem.Caption := '-';
  btnRemItem.Left := 170; btnRemItem.Top := 6;
  btnRemItem.Width := 28; btnRemItem.Height := 24;
  btnRemItem.OnClick := btnRemItemClick;

  lstInventory := TListBox.Create(Self);
  lstInventory.Parent := tsInventory;
  lstInventory.Align := alClient;

  tsQuests := TTabSheet.Create(pcInspector);
  tsQuests.PageControl := pcInspector;
  tsQuests.Caption := 'Quest Flags';

  lvQuests := TListView.Create(Self);
  lvQuests.Parent := tsQuests;
  lvQuests.Align := alClient;
  lvQuests.ViewStyle := vsReport;
  lvQuests.RowSelect := True;
  lvQuests.GridLines := True;
  lvQuests.Columns.Add.Caption := 'Quest';
  lvQuests.Columns.Add.Caption := 'Flag';
  lvQuests.Columns.Add.Caption := 'State';

  // Karma/Rep labels at bottom of inspector
  var pnlStats := TPanel.Create(Self);
  pnlStats.Parent := pnlInspector;
  pnlStats.Align := alBottom;
  pnlStats.Height := 56;
  pnlStats.BevelOuter := bvNone;

  var lblKarmaHdr := TLabel.Create(Self);
  lblKarmaHdr.Parent := pnlStats;
  lblKarmaHdr.Left := 8; lblKarmaHdr.Top := 6;
  lblKarmaHdr.Caption := 'KARMA';
  lblKarmaHdr.Font.Style := [fsBold];

  btn := TButton.Create(pnlStats);
  btn.Parent := pnlStats;
  btn.Left := 8; btn.Top := 22;
  btn.Width := 80; btn.Height := 24;
  btn.Tag := 1;
  btn.Name := 'spnKarmaPreview';

var lblRepHdr: TLabel;
   lblRepHdr := TLabel.Create(Self);
   lblRepHdr.Parent := pnlStats;
  lblRepHdr.Left := 100; lblRepHdr.Top := 6;
  lblRepHdr.Caption := 'REPUTATION';
  lblRepHdr.Font.Style := [fsBold];

  btn := TButton.Create(pnlStats);
  btn.Parent := pnlStats;
  btn.Left := 100; btn.Top := 22;
  btn.Width := 80; btn.Height := 24;
  btn.Tag := 2;
  btn.Name := 'spnRepPreview';
end;

procedure TPreviewForm.StyleUI;
var
  t: TFDCTheme;
begin
  t := TThemeManager.Current;
  TControlHack(Self).Color := t.BgDark;
  Font.Color := t.TextPrimary;
  Font.Name := t.FontName;

  pnlLeft.Color := t.BgDark;
  pnlRight.Color := t.BgMedium;
  pnlGameView.Color := t.BgDark;
  pnlPortrait.Color := t.BgMedium;
  pnlDialogue.Color := t.BgDark;
  pnlOptions.Color := t.BgDark;
  pnlHistory.Color := t.BgMedium;
  pnlControls.Color := t.BgMedium;
  pnlInspector.Color := t.BgMedium;
  scrollOptions.Color := t.BgDark;

  memoDialogue.Color := t.BgDark;
  memoDialogue.Font.Color := t.AccentPrimary;
  memoDialogue.Font.Name := t.MonoFontName;
  memoDialogue.Font.Size := 12;

  lstHistory.Color := t.BgMedium;
  lstHistory.Font.Color := t.TextSecondary;
  lstHistory.Font.Size := 8;

  lblNPCName.Font.Color := t.AccentPrimary;
  lblNPCName.Color := t.BgMedium;

  lblHistoryTitle.Font.Color := t.AccentSecondary;
  lblHistoryTitle.Font.Size := 8;

  lblInspTitle.Font.Color := t.AccentSecondary;
  lblInspTitle.Font.Size := 8;
  lblInspTitle.Color := t.BgMedium;

  lvVars.Color := t.BgDark;
  lvVars.Font.Color := t.TextPrimary;
  lvSkills.Color := t.BgDark;
  lvSkills.Font.Color := t.TextPrimary;
  lstInventory.Color := t.BgDark;
  lstInventory.Font.Color := t.TextPrimary;
  lvQuests.Color := t.BgDark;
  lvQuests.Font.Color := t.TextPrimary;

  TControlHack(pcInspector).Color := t.BgMedium;

  splitter.Color := t.AccentDim;

  for var i := 0 to pnlControls.ControlCount - 1 do
    if pnlControls.Controls[i] is TButton then
      (pnlControls.Controls[i] as TButton).Font.Color := t.TextPrimary;

  lblNodeInfo.Font.Color := t.TextDim;
  lblNodeInfo.Font.Size := 8;
  chkAutoAdvance.Font.Color := t.TextSecondary;

  edtAddItem.Color := t.BgLight;
  edtAddItem.Font.Color := t.TextPrimary;
end;

procedure TPreviewForm.InitSimulation;
var
  skill: TSkillType;
begin
  FSimKarma := 0;
  FSimReputation := 0;
  FSimVars.Clear;
  FSimSkills.Clear;
  FSimInventory.Clear;
  FSimQuestFlags.Clear;
  FHistory.Clear;

  for skill := Low(TSkillType) to High(TSkillType) do
    FSimSkills.AddOrSetValue(SKILL_NAMES[skill], 40);

  for var pair in FProject.GlobalVars do
    FSimVars.AddOrSetValue(pair.Key, StrToIntDef(pair.Value, 0));

  UpdateInspector;
  lstHistory.Items.Clear;
  memoDialogue.Clear;
  ClearOptionButtons;
  DrawPortraitPlaceholder;

  lblNPCName.Caption := FProject.NPCName;
  if lblNPCName.Caption = '' then lblNPCName.Caption := 'Unknown';

  AddStatusMessage('=== SIMULATION STARTED ===', TThemeManager.Current.ColorSuccess);
  AddStatusMessage('Project: ' + FProject.Name, TThemeManager.Current.TextDim);
  AddStatusMessage('NPC: ' + FProject.NPCName, TThemeManager.Current.TextDim);
end;

procedure TPreviewForm.DrawPortraitPlaceholder;
var
  bmp: TBitmap;
  r: TRect;
  t: TFDCTheme;
begin
  t := TThemeManager.Current;
  bmp := TBitmap.Create;
  try
    bmp.Width := 140;
    bmp.Height := 140;
    bmp.Canvas.Brush.Color := t.BgMedium;
    bmp.Canvas.FillRect(Rect(0, 0, 140, 140));
    bmp.Canvas.Pen.Color := t.AccentSecondary;
    bmp.Canvas.Pen.Width := 2;
    bmp.Canvas.Pen.Style := psDot;
    bmp.Canvas.Rectangle(4, 4, 136, 136);

    bmp.Canvas.Pen.Style := psSolid;
    bmp.Canvas.Pen.Width := 1;
    bmp.Canvas.Brush.Color := t.AccentDim;
    bmp.Canvas.Ellipse(50, 20, 90, 60);
    bmp.Canvas.Rectangle(44, 60, 96, 110);
    bmp.Canvas.Rectangle(30, 62, 46, 100);
    bmp.Canvas.Rectangle(94, 62, 110, 100);
    bmp.Canvas.Rectangle(46, 110, 68, 136);
    bmp.Canvas.Rectangle(72, 110, 94, 136);

    bmp.Canvas.Font.Color := t.TextDim;
    bmp.Canvas.Font.Size := 7;
    bmp.Canvas.Font.Name := 'Courier New';
    bmp.Canvas.Brush.Style := bsClear;
    bmp.Canvas.TextOut(30, 2, '[ NO PORTRAIT ]');

    imgPortrait.Picture.Assign(bmp);
  finally
    bmp.Free;
  end;
end;

procedure TPreviewForm.LoadPortrait(const filename: string);
begin
  if filename = '' then
  begin
    DrawPortraitPlaceholder;
    Exit;
  end;
  if not FileExists(filename) then
  begin
    DrawPortraitPlaceholder;
    Exit;
  end;
  try
    imgPortrait.Picture.LoadFromFile(filename);
  except
    DrawPortraitPlaceholder;
  end;
end;

procedure TPreviewForm.NavigateToNode(const nodeID: string);
var
  node: TDialogueNode;
begin
  if not Assigned(FProject) then Exit;
  node := FProject.FindNode(nodeID);
  if not Assigned(node) then
  begin
    AddStatusMessage('ERROR: Node not found: ' + nodeID, TThemeManager.Current.ColorError);
    Exit;
  end;
  FCurrentNode := node;
  DisplayNode(node);
end;

procedure TPreviewForm.DisplayNode(node: TDialogueNode);
var
  t: TFDCTheme;
begin
  if not Assigned(node) then Exit;
  t := TThemeManager.Current;

  lblNodeInfo.Caption := 'Node: ' + Copy(node.ID, 1, 14) + '  Type: ' + NODE_TYPE_NAMES[node.NodeType];

  if node.PortraitFile <> '' then
    LoadPortrait(node.PortraitFile)
  else
    DrawPortraitPlaceholder;

  if node.Speaker <> '' then
    lblNPCName.Caption := node.Speaker
  else
    lblNPCName.Caption := FProject.NPCName;

  memoDialogue.Clear;

  case node.NodeType of
    ntNPCDialogue:
    begin
      memoDialogue.Font.Color := t.AccentPrimary;
      if Trim(node.Text) <> '' then
        memoDialogue.Text := node.Text
      else
        memoDialogue.Text := '(no dialogue text)';
    end;

    ntPlayerReply:
    begin
      memoDialogue.Font.Color := t.ColorSuccess;
      memoDialogue.Text := '[Player Response Options]';
    end;

    ntConditional:
    begin
      memoDialogue.Font.Color := t.ColorWarning;
      memoDialogue.Text := '[Conditional Branch]' + sLineBreak;
      memoDialogue.Text := memoDialogue.Text + 'Evaluating ' + IntToStr(node.Conditions.Count) + ' condition(s)...';
      if EvaluateAllConditions(node) then
      begin
        memoDialogue.Text := memoDialogue.Text + sLineBreak + '-> Condition MET';
        if node.NextNodeID <> '' then
        begin
          AddHistoryEntry(node, '[Condition passed]');
          NavigateToNode(node.NextNodeID);
          Exit;
        end;
      end else
        memoDialogue.Text := memoDialogue.Text + sLineBreak + '-> Condition NOT met';
    end;

    ntScript:
    begin
      memoDialogue.Font.Color := t.ColorInfo;
      memoDialogue.Text := '[Script Node]' + sLineBreak;
      for var sc in node.Scripts do
        if sc.IsEnabled then
          memoDialogue.Text := memoDialogue.Text + sLineBreak +
            '[' + GetEnumName(TypeInfo(TScriptEvent), Ord(sc.EventType)) + ']' + sLineBreak +
            sc.ScriptCode;
    end;

    ntCombatTrigger:
    begin
      memoDialogue.Font.Color := t.ColorError;
      memoDialogue.Text := 'COMBAT TRIGGERED' + sLineBreak;
      if node.CombatScript <> '' then
        memoDialogue.Text := memoDialogue.Text + node.CombatScript;
      memoDialogue.Text := memoDialogue.Text + sLineBreak + sLineBreak +
        '[Dialogue ends - combat begins]';
    end;

    ntQuestUpdate:
    begin
      memoDialogue.Font.Color := t.ColorInfo;
      memoDialogue.Text := 'QUEST UPDATE' + sLineBreak;
      memoDialogue.Text := memoDialogue.Text + 'Quest: ' + node.QuestID + sLineBreak;
      memoDialogue.Text := memoDialogue.Text + 'Flag: ' + node.QuestFlag;
      if node.QuestID <> '' then
      begin
        FSimQuestFlags.AddOrSetValue(node.QuestID, StrToIntDef(node.QuestFlag, 1));
        UpdateQuestsView;
      end;
    end;

    ntTrade:
    begin
      memoDialogue.Font.Color := t.AccentSecondary;
      memoDialogue.Text := 'BARTER / TRADE SCREEN' + sLineBreak;
      memoDialogue.Text := memoDialogue.Text + '[Trade interface would open here]';
    end;

    ntEndDialogue:
    begin
      memoDialogue.Font.Color := t.TextDim;
      memoDialogue.Text := '[ DIALOGUE ENDS ]';
      AddHistoryEntry(node, '[Dialogue ended]');
      AddStatusMessage('--- Dialogue ended ---', t.TextDim);
      Exit;
    end;

    ntComment:
    begin
      memoDialogue.Font.Color := t.TextDim;
      memoDialogue.Text := '// Comment node: ' + node.Comment;
      if node.NextNodeID <> '' then
      begin
        NavigateToNode(node.NextNodeID);
        Exit;
      end;
    end;

    ntRandom:
    begin
      memoDialogue.Font.Color := t.ColorInfo;
      memoDialogue.Text := '[Random Branch - Weight: ' + IntToStr(node.RandomWeight) + ']';
    end;
  end;

  AddHistoryEntry(node, '');
  BuildOptionButtons(node);

  if chkAutoAdvance.Checked and
     (node.NodeType in [ntNPCDialogue, ntComment]) and
     (node.PlayerOptions.Count = 0) and
     (node.NextNodeID <> '') then
  begin
    AddHistoryEntry(node, '[Auto-advanced]');
    NavigateToNode(node.NextNodeID);
    Exit;
  end;

  if (node.NodeType in [ntNPCDialogue, ntComment]) and
     (node.PlayerOptions.Count = 0) and
     (node.NextNodeID = '') then
    AddStatusMessage('(No further options - dialogue branch ends)', t.TextDim);
end;

procedure TPreviewForm.ClearOptionButtons;
var
  btn: TButton;
begin
  for btn in FOptionButtons do
  begin
    scrollOptions.RemoveControl(btn);
    btn.Free;
  end;
  FOptionButtons.Clear;
end;

procedure TPreviewForm.BuildOptionButtons(node: TDialogueNode);
var
  opt: TPlayerOption;
  btn: TButton;
  yPos: Integer;
  isAvailable: Boolean;
  t: TFDCTheme;
  optText: string;
begin
  ClearOptionButtons;
  t := TThemeManager.Current;
  yPos := 4;

  if (node.NextNodeID <> '') and (node.NodeType in [ntNPCDialogue, ntScript, ntRandom]) then
  begin
    btn := TButton.Create(scrollOptions);
    btn.Parent := scrollOptions;
    btn.Left := 4; btn.Top := yPos;
    btn.Width := scrollOptions.ClientWidth - 20;
    btn.Height := 36;
    btn.Caption := '->  [Continue]';
    btn.Font.Color := t.AccentPrimary;
    btn.Font.Style := [fsBold];
    btn.Tag := -1;
    btn.Hint := node.NextNodeID;
    btn.ShowHint := True;
    btn.OnClick := OptionButtonClick;
    FOptionButtons.Add(btn);
    Inc(yPos, 42);
  end;

  for var i := 0 to node.PlayerOptions.Count - 1 do
  begin
    opt := node.PlayerOptions[i];
    isAvailable := EvaluateOptionConditions(opt);

    if opt.IsHidden and not isAvailable then
      Continue;

    optText := IntToStr(i + 1) + '.  ' + opt.Text;

    if opt.HasSkillCheck then
      optText := optText + '  [' + SKILL_NAMES[opt.SkillCheck.Skill] + ' ' +
        IntToStr(opt.SkillCheck.Difficulty) + '%]';

    if opt.ItemRequired <> '' then
      optText := optText + '  (requires: ' + opt.ItemRequired + ')';

    if not isAvailable then
      optText := optText + '  -- NOT AVAILABLE';

    btn := TButton.Create(scrollOptions);
    btn.Parent := scrollOptions;
    btn.Left := 4; btn.Top := yPos;
    btn.Width := scrollOptions.ClientWidth - 20;
    btn.Height := 40;
    btn.Caption := optText;
    btn.WordWrap := True;
    btn.Enabled := isAvailable;
    btn.Tag := i;

    if not isAvailable then
      btn.Font.Color := t.TextDisabled
    else if opt.HasSkillCheck then
      btn.Font.Color := t.ColorWarning
    else
      btn.Font.Color := t.TextPrimary;

    btn.Hint := 'Target: ' + opt.TargetNodeID;
    btn.ShowHint := True;
    btn.OnClick := OptionButtonClick;
    FOptionButtons.Add(btn);
    Inc(yPos, 46);
  end;

  btn := TButton.Create(scrollOptions);
  btn.Parent := scrollOptions;
  btn.Left := 4; btn.Top := yPos;
  btn.Width := scrollOptions.ClientWidth - 20;
  btn.Height := 32;
  btn.Caption := 'Goodbye.';
  btn.Font.Color := t.TextDim;
  btn.Tag := -99;
  btn.OnClick := OptionButtonClick;
  FOptionButtons.Add(btn);
end;

procedure TPreviewForm.OptionButtonClick(Sender: TObject);
var
  btn: TButton;
  opt: TPlayerOption;
  tagVal: Integer;
  node: TDialogueNode;
  skillPassed: Boolean;
  t: TFDCTheme;
begin
  if not (Sender is TButton) then Exit;
  btn := TButton(Sender);
  tagVal := btn.Tag;
  t := TThemeManager.Current;
  node := FCurrentNode;

  if tagVal = -99 then
  begin
    AddStatusMessage('--- Player chose to end dialogue ---', t.TextDim);
    memoDialogue.Font.Color := t.TextDim;
    memoDialogue.Text := '[ YOU END THE CONVERSATION ]';
    ClearOptionButtons;
    Exit;
  end;

  if tagVal = -1 then
  begin
    AddHistoryEntry(node, '[Continue]');
    NavigateToNode(node.NextNodeID);
    Exit;
  end;

  if (tagVal >= 0) and (tagVal < node.PlayerOptions.Count) then
  begin
    opt := node.PlayerOptions[tagVal];
    AddStatusMessage('Player: ' + opt.Text, t.ColorSuccess);

    if opt.HasSkillCheck then
    begin
      skillPassed := SimulateSkillCheck(opt.SkillCheck);
      if skillPassed then
      begin
        AddStatusMessage('SKILL CHECK PASSED! (' + SKILL_NAMES[opt.SkillCheck.Skill] +
          ' ' + IntToStr(GetSkillValue(SKILL_NAMES[opt.SkillCheck.Skill])) +
          ' vs ' + IntToStr(opt.SkillCheck.Difficulty) + ')',
          t.ColorSuccess);
        if opt.SkillCheck.XPReward > 0 then
          AddStatusMessage('  +' + IntToStr(opt.SkillCheck.XPReward) + ' XP awarded', t.ColorInfo);
        AddHistoryEntry(node, opt.Text + ' [SKILL PASS]');
        if opt.SkillCheck.SuccessNodeID <> '' then
          NavigateToNode(opt.SkillCheck.SuccessNodeID)
        else if opt.TargetNodeID <> '' then
          NavigateToNode(opt.TargetNodeID);
      end else
      begin
        AddStatusMessage('SKILL CHECK FAILED! (' + SKILL_NAMES[opt.SkillCheck.Skill] +
          ' ' + IntToStr(GetSkillValue(SKILL_NAMES[opt.SkillCheck.Skill])) +
          ' vs ' + IntToStr(opt.SkillCheck.Difficulty) + ')',
          t.ColorError);
        if opt.SkillCheck.FailureMessage <> '' then
          AddStatusMessage('  "' + opt.SkillCheck.FailureMessage + '"', t.TextSecondary);
        AddHistoryEntry(node, opt.Text + ' [SKILL FAIL]');
        if opt.SkillCheck.FailureNodeID <> '' then
          NavigateToNode(opt.SkillCheck.FailureNodeID)
        else if opt.TargetNodeID <> '' then
          NavigateToNode(opt.TargetNodeID);
      end;
    end else
    begin
      AddHistoryEntry(node, opt.Text);
      if opt.TargetNodeID <> '' then
        NavigateToNode(opt.TargetNodeID)
      else
        AddStatusMessage('(Option has no target node)', t.ColorWarning);
    end;
  end;
end;

procedure TPreviewForm.AddHistoryEntry(node: TDialogueNode; const choice: string);
var
  entry: TPreviewHistory;
begin
  entry.NodeID := node.ID;
  entry.NodeType := node.NodeType;
  entry.Speaker := IfThen(node.Speaker <> '', node.Speaker, FProject.NPCName);
  entry.Text := node.Text;
  entry.ChoiceMade := choice;
  FHistory.Add(entry);

  if Trim(node.Text) <> '' then
  begin
    var display := '';
    if node.NodeType = ntNPCDialogue then
      display := '[NPC] ' + entry.Speaker + ': ' + Copy(node.Text, 1, 60)
    else if choice <> '' then
      display := '[PLY] ' + Copy(choice, 1, 60)
    else
      display := '[' + NODE_TYPE_NAMES[node.NodeType] + '] ' + Copy(node.Text, 1, 50);
    lstHistory.Items.Add(display);
    lstHistory.TopIndex := lstHistory.Items.Count - 1;
  end;
end;

procedure TPreviewForm.AddStatusMessage(const msg: string; color: TColor);
begin
  lstHistory.Items.Add('  ' + msg);
  lstHistory.TopIndex := lstHistory.Items.Count - 1;
end;

function TPreviewForm.GetSkillValue(const skillName: string): Integer;
begin
  if not FSimSkills.TryGetValue(skillName, Result) then
    Result := 40;
  for var i := 0 to lvSkills.Items.Count - 1 do
    if lvSkills.Items[i].Caption = skillName then
    begin
      Result := StrToIntDef(lvSkills.Items[i].SubItems[0], Result);
      Break;
    end;
end;

function TPreviewForm.GetSimVar(const name: string): Integer;
begin
  if not FSimVars.TryGetValue(name, Result) then
    Result := 0;
end;

function TPreviewForm.EvaluateCondition(const cond: TCondition): Boolean;
var
  lhs: Integer;
  rhs: Integer;
begin
  Result := False;
  rhs := StrToIntDef(cond.Value, 0);

  case cond.CondType of
    ctSkillCheck:
      lhs := GetSkillValue(cond.Variable);
    ctStatCheck:
      lhs := GetSimVar('STAT_' + cond.Variable);
    ctReputation:
      lhs := FSimReputation;
    ctKarma:
      lhs := FSimKarma;
    ctGlobalVar, ctLocalVar:
      lhs := GetSimVar(cond.Variable);
    ctQuestFlag:
    begin
      if not FSimQuestFlags.TryGetValue(cond.Variable, lhs) then lhs := 0;
    end;
    ctInventory:
    begin
      Result := FSimInventory.IndexOf(cond.Variable) >= 0;
      Exit;
    end;
    ctCompanion:
    begin
      Result := FSimInventory.IndexOf('COMPANION_' + cond.Variable) >= 0;
      Exit;
    end;
    ctRandom:
    begin
      Result := Random(100) < rhs;
      Exit;
    end;
  else
    lhs := 0;
  end;

  case cond.Operator of
    coEQ:  Result := lhs = rhs;
    coNEQ: Result := lhs <> rhs;
    coLT:  Result := lhs < rhs;
    coGT:  Result := lhs > rhs;
    coLTE: Result := lhs <= rhs;
    coGTE: Result := lhs >= rhs;
  end;
end;

function TPreviewForm.EvaluateAllConditions(node: TDialogueNode): Boolean;
var
  i: Integer;
  cond: TCondition;
  condResult: Boolean;
begin
  Result := True;
  if node.Conditions.Count = 0 then Exit;

  Result := EvaluateCondition(node.Conditions[0]);
  for i := 1 to node.Conditions.Count - 1 do
  begin
    cond := node.Conditions[i];
    condResult := EvaluateCondition(cond);
    case cond.BoolOp of
      boAND: Result := Result and condResult;
      boOR:  Result := Result or condResult;
      boNOT: Result := Result and not condResult;
    end;
  end;
end;

function TPreviewForm.EvaluateOptionConditions(opt: TPlayerOption): Boolean;
var
  cond: TCondition;
begin
  Result := True;

  if opt.ReputationRequired > 0 then
    if FSimReputation < opt.ReputationRequired then
    begin
      Result := False;
      Exit;
    end;

  if opt.KarmaRequired > -1000 then
    if FSimKarma < opt.KarmaRequired then
    begin
      Result := False;
      Exit;
    end;

  if opt.ItemRequired <> '' then
    if FSimInventory.IndexOf(opt.ItemRequired) < 0 then
    begin
      Result := False;
      Exit;
    end;

  for cond in opt.Conditions do
    if not EvaluateCondition(cond) then
    begin
      Result := False;
      Exit;
    end;
end;

function TPreviewForm.SimulateSkillCheck(const sk: TSkillCheck): Boolean;
var
  skillValue: Integer;
  roll: Integer;
begin
  skillValue := GetSkillValue(SKILL_NAMES[sk.Skill]);
  roll := Random(100) + 1;
  var effectiveChance := skillValue - sk.Difficulty + 50;
  effectiveChance := Max(5, Min(95, effectiveChance));
  Result := roll <= effectiveChance;
end;

procedure TPreviewForm.UpdateInspector;
begin
  UpdateVarsView;
  UpdateSkillsView;
  UpdateQuestsView;
  lstInventory.Items.Clear;
  for var item in FSimInventory do
    lstInventory.Items.Add(item);
end;

procedure TPreviewForm.UpdateVarsView;
var
  item: TListItem;
begin
  lvVars.Items.Clear;
  for var pair in FSimVars do
  begin
    item := lvVars.Items.Add;
    item.Caption := pair.Key;
    item.SubItems.Add(IntToStr(pair.Value));
  end;
  item := lvVars.Items.Add;
  item.Caption := 'KARMA';
  item.SubItems.Add(IntToStr(FSimKarma));
  item := lvVars.Items.Add;
  item.Caption := 'REPUTATION';
  item.SubItems.Add(IntToStr(FSimReputation));
end;

procedure TPreviewForm.UpdateSkillsView;
var
  skillName: string;
  val: Integer;
begin
  for var i := 0 to lvSkills.Items.Count - 1 do
  begin
    skillName := lvSkills.Items[i].Caption;
    if FSimSkills.TryGetValue(skillName, val) then
      lvSkills.Items[i].SubItems[0] := IntToStr(val);
  end;
end;

procedure TPreviewForm.UpdateQuestsView;
var
  item: TListItem;
begin
  lvQuests.Items.Clear;
  for var pair in FSimQuestFlags do
  begin
    item := lvQuests.Items.Add;
    item.Caption := pair.Key;
    item.SubItems.Add('ACTIVE');
    item.SubItems.Add(IntToStr(pair.Value));
  end;
end;

procedure TPreviewForm.lvSkillsDblClick(Sender: TObject);
var
  item: TListItem;
  newVal: string;
begin
  item := lvSkills.Selected;
  if not Assigned(item) then Exit;
  newVal := InputBox('Edit Skill Value', item.Caption + ':', item.SubItems[0]);
  if newVal <> '' then
  begin
    item.SubItems[0] := IntToStr(StrToIntDef(newVal, 40));
    FSimSkills.AddOrSetValue(item.Caption, StrToIntDef(newVal, 40));
  end;
end;

procedure TPreviewForm.lvVarsDblClick(Sender: TObject);
var
  item: TListItem;
  newVal: string;
begin
  item := lvVars.Selected;
  if not Assigned(item) then Exit;
  newVal := InputBox('Edit Variable', item.Caption + ':', item.SubItems[0]);
  if newVal <> '' then
  begin
    item.SubItems[0] := IntToStr(StrToIntDef(newVal, 0));
    if item.Caption = 'KARMA' then
      FSimKarma := StrToIntDef(newVal, 0)
    else if item.Caption = 'REPUTATION' then
      FSimReputation := StrToIntDef(newVal, 0)
    else
      FSimVars.AddOrSetValue(item.Caption, StrToIntDef(newVal, 0));
  end;
end;

procedure TPreviewForm.btnAddItemClick(Sender: TObject);
begin
  if Trim(edtAddItem.Text) <> '' then
  begin
    FSimInventory.Add(Trim(edtAddItem.Text));
    lstInventory.Items.Add(Trim(edtAddItem.Text));
    edtAddItem.Clear;
  end;
end;

procedure TPreviewForm.btnRemItemClick(Sender: TObject);
begin
  if lstInventory.ItemIndex >= 0 then
  begin
    FSimInventory.Delete(lstInventory.ItemIndex);
    lstInventory.Items.Delete(lstInventory.ItemIndex);
  end;
end;

procedure TPreviewForm.btnRestartClick(Sender: TObject);
begin
  InitSimulation;
  if FProject.StartNodeID <> '' then
    NavigateToNode(FProject.StartNodeID)
  else if FProject.Nodes.Count > 0 then
    NavigateToNode(FProject.Nodes[0].ID);
end;

procedure TPreviewForm.btnStepBackClick(Sender: TObject);
begin
  if FHistory.Count >= 2 then
  begin
    FHistory.Delete(FHistory.Count - 1);
    var prevEntry := FHistory[FHistory.Count - 1];
    FHistory.Delete(FHistory.Count - 1);
    NavigateToNode(prevEntry.NodeID);
    if lstHistory.Items.Count > 0 then
      lstHistory.Items.Delete(lstHistory.Items.Count - 1);
  end else
    AddStatusMessage('(Nothing to go back to)', TThemeManager.Current.TextDim);
end;

procedure TPreviewForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TPreviewForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  idx: Integer;
begin
  if (Key >= Ord('1')) and (Key <= Ord('9')) then
  begin
    idx := Key - Ord('1');
    if idx < FOptionButtons.Count then
    begin
      if FOptionButtons[idx].Enabled then
        FOptionButtons[idx].Click;
    end;
    Key := 0;
  end else if Key = VK_RETURN then
  begin
    if FOptionButtons.Count > 0 then
      FOptionButtons[0].Click;
    Key := 0;
  end else if Key = VK_ESCAPE then
    Close;
end;

initialization
  Randomize;

end.