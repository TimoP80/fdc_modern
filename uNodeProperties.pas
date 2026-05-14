unit uNodeProperties;

// uNodeProperties - Node property editor form

interface

uses
  System.SysUtils, System.Classes, System.Math, System.TypInfo,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.Dialogs, Vcl.Samples.Spin,
  Vcl.Graphics, Winapi.Windows,
  uDialogueTypes, uThemeManager;

type
  TNodePropertiesForm = class(TForm)
  private
    FNode: TDialogueNode;
    FProject: TDialogueProject;
    FLabelW: Integer;
    FLabelH: Integer;

    // Layout controls
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pcMain: TPageControl;
    tsGeneral: TTabSheet;
    tsOptions: TTabSheet;
    tsConditions: TTabSheet;
    tsScripts: TTabSheet;
    pnlButtons: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    btnApply: TButton;

    // General tab
    pnlGeneralLeft: TPanel;
    lblNodeType: TLabel;
    cmbNodeType: TComboBox;
    lblSpeaker: TLabel;
    edtSpeaker: TEdit;
    lblText: TLabel;
    memoText: TMemo;
    lblNotes: TLabel;
    memoNotes: TMemo;
    chkIsStart: TCheckBox;
    lblPortrait: TLabel;
    edtPortrait: TEdit;
    btnPortraitBrowse: TButton;
    lblVoice: TLabel;
    edtVoice: TEdit;
    btnVoiceBrowse: TButton;
    lblQuestID: TLabel;
    edtQuestID: TEdit;
    lblQuestFlag: TLabel;
    edtQuestFlag: TEdit;
    lblReputation: TLabel;
    spnReputation: TSpinEdit;
    lblKarma: TLabel;
    spnKarma: TSpinEdit;
    lblTag: TLabel;
    edtTag: TEdit;
    lblNextNode: TLabel;
    cmbNextNode: TComboBox;
    lblWeight: TLabel;
    spnWeight: TSpinEdit;
    lblCombat: TLabel;
    edtCombatScript: TEdit;
    lblComment: TLabel;
    memoComment: TMemo;

    // Options tab
    lstOptions: TListBox;
    pnlOptionDetail: TPanel;
    lblOptText: TLabel;
    edtOptText: TEdit;
    lblOptTarget: TLabel;
    cmbOptTarget: TComboBox;
    chkOptHidden: TCheckBox;
    chkOptSkill: TCheckBox;
    pnlSkillCheck: TPanel;
    lblSkillType: TLabel;
    cmbSkillType: TComboBox;
    lblDifficulty: TLabel;
    trkDifficulty: TTrackBar;
    lblDiffValue: TLabel;
    lblXPReward: TLabel;
    spnXPReward: TSpinEdit;
    lblSuccessMsg: TLabel;
    edtSuccessMsg: TEdit;
    lblFailMsg: TLabel;
    edtFailMsg: TEdit;
    lblSuccessNode: TLabel;
    cmbSuccessNode: TComboBox;
    lblFailNode: TLabel;
    cmbFailNode: TComboBox;
    lblItemRequired: TLabel;
    edtItemRequired: TEdit;
    lblOptRep: TLabel;
    spnOptRep: TSpinEdit;
    lblOptKarma: TLabel;
    spnOptKarma: TSpinEdit;
    btnAddOption: TButton;
    btnDelOption: TButton;
    btnMoveUp: TButton;
    btnMoveDown: TButton;

    // Conditions tab
    lstConditions: TListBox;
    pnlCondDetail: TPanel;
    lblCondType: TLabel;
    cmbCondType: TComboBox;
    lblCondVar: TLabel;
    edtCondVar: TEdit;
    lblCondOp: TLabel;
    cmbCondOp: TComboBox;
    lblCondVal: TLabel;
    edtCondVal: TEdit;
    lblCondBool: TLabel;
    cmbCondBool: TComboBox;
    btnAddCond: TButton;
    btnDelCond: TButton;
    lblProbPreview: TLabel;

    // Scripts tab
    lstScripts: TListBox;
    pnlScriptDetail: TPanel;
    lblEventType: TLabel;
    cmbEventType: TComboBox;
    chkScriptEnabled: TCheckBox;
    memoScript: TMemo;
    btnAddScript: TButton;
    btnDelScript: TButton;
    lblScriptRef: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BuildLayout;
    procedure StyleForm;
    procedure PopulateFromNode;
    procedure SaveToNode;
    procedure PopulateNodeCombos;
    procedure RefreshOptionList;
    procedure RefreshConditionList;
    procedure RefreshScriptList;
    procedure AddLabelTo(ctrl: TWinControl; const cap: string; y: Integer; out lbl: TLabel);
    procedure lstOptionsClick(Sender: TObject);
    procedure lstConditionsClick(Sender: TObject);
    procedure lstScriptsClick(Sender: TObject);
    procedure btnAddOptionClick(Sender: TObject);
    procedure btnDelOptionClick(Sender: TObject);
    procedure btnMoveUpClick(Sender: TObject);
    procedure btnMoveDownClick(Sender: TObject);
    procedure btnAddCondClick(Sender: TObject);
    procedure btnDelCondClick(Sender: TObject);
    procedure btnAddScriptClick(Sender: TObject);
    procedure btnDelScriptClick(Sender: TObject);
    procedure chkOptSkillClick(Sender: TObject);
    procedure trkDifficultyChange(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnPortraitBrowseClick(Sender: TObject);
    procedure btnVoiceBrowseClick(Sender: TObject);
    procedure SaveCurrentOption;
    procedure SaveCurrentCondition;
    procedure SaveCurrentScript;
  public
    class function Execute(AOwner: TComponent; aNode: TDialogueNode; aProject: TDialogueProject): Boolean;
  end;

implementation

type
  TControlHack = class(TControl) end;

{ TNodePropertiesForm }

class function TNodePropertiesForm.Execute(AOwner: TComponent; aNode: TDialogueNode;
  aProject: TDialogueProject): Boolean;
var
  frm: TNodePropertiesForm;
begin
   frm := TNodePropertiesForm.CreateNew(AOwner);
   try
     frm.FNode := aNode;
     frm.FProject := aProject;
     frm.FormCreate(nil);
     frm.FormShow(nil);
     Result := frm.ShowModal = mrOk;
   finally
     frm.Free;
   end;
end;

procedure TNodePropertiesForm.FormCreate(Sender: TObject);
begin
  BuildLayout;
  StyleForm;
end;

procedure TNodePropertiesForm.FormShow(Sender: TObject);
begin
  PopulateNodeCombos;
  PopulateFromNode;
end;

procedure TNodePropertiesForm.AddLabelTo(ctrl: TWinControl; const cap: string; y: Integer; out lbl: TLabel);
begin
  lbl := TLabel.Create(Self);
  lbl.Parent := ctrl;
  lbl.Left := 8;
  lbl.Top := y + 3;
  lbl.Width := FLabelW;
  lbl.Caption := cap;
  lbl.Alignment := taRightJustify;
end;

procedure TNodePropertiesForm.BuildLayout;
var
  i: TNodeType;
  sk: TSkillType;
  ct: TConditionType;
  co: TConditionOperator;
  se: TScriptEvent;
  yPos, ctrlX, ctrlW: Integer;
  lbl: TLabel;
begin
  FLabelW := 110;
  ctrlX := 128;
  ctrlW := 300;

  Width := 820;
  Height := 680;
  Caption := 'Node Properties';
  Position := poMainFormCenter;
  BorderStyle := bsSizeable;

  // Header panel
  pnlHeader := TPanel.Create(Self);
  pnlHeader.Parent := Self;
  pnlHeader.Align := alTop;
  pnlHeader.Height := 44;
  pnlHeader.BevelOuter := bvNone;

  lblTitle := TLabel.Create(Self);
  lblTitle.Parent := pnlHeader;
  lblTitle.Left := 12;
  lblTitle.Top := 10;
  lblTitle.Font.Size := 14;
  lblTitle.Font.Style := [fsBold];
  lblTitle.Caption := 'Node Properties';

  // Buttons panel
  pnlButtons := TPanel.Create(Self);
  pnlButtons.Parent := Self;
  pnlButtons.Align := alBottom;
  pnlButtons.Height := 42;
  pnlButtons.BevelOuter := bvNone;

  btnOK := TButton.Create(Self);
  btnOK.Parent := pnlButtons;
  btnOK.Caption := 'OK';
  btnOK.ModalResult := mrNone;
  btnOK.Width := 88;
  btnOK.Height := 28;
  btnOK.Left := pnlButtons.Width - 280;
  btnOK.Top := 7;
  btnOK.Anchors := [akRight, akTop];
  btnOK.OnClick := btnOKClick;

  btnApply := TButton.Create(Self);
  btnApply.Parent := pnlButtons;
  btnApply.Caption := 'Apply';
  btnApply.Width := 88;
  btnApply.Height := 28;
  btnApply.Left := pnlButtons.Width - 184;
  btnApply.Top := 7;
  btnApply.Anchors := [akRight, akTop];
  btnApply.OnClick := btnApplyClick;

  btnCancel := TButton.Create(Self);
  btnCancel.Parent := pnlButtons;
  btnCancel.Caption := 'Cancel';
  btnCancel.ModalResult := mrCancel;
  btnCancel.Width := 88;
  btnCancel.Height := 28;
  btnCancel.Left := pnlButtons.Width - 96;
  btnCancel.Top := 7;
  btnCancel.Anchors := [akRight, akTop];
  btnCancel.OnClick := btnCancelClick;

  // PageControl
  pcMain := TPageControl.Create(Self);
  pcMain.Parent := Self;
  pcMain.Align := alClient;

  // --- GENERAL TAB ---
  tsGeneral := TTabSheet.Create(pcMain);
  tsGeneral.PageControl := pcMain;
  tsGeneral.Caption := 'General';

  yPos := 8;

  AddLabelTo(tsGeneral, 'Node Type:', yPos, lblNodeType);
  cmbNodeType := TComboBox.Create(Self);
  cmbNodeType.Parent := tsGeneral;
  cmbNodeType.Left := ctrlX; cmbNodeType.Top := yPos;
  cmbNodeType.Width := ctrlW; cmbNodeType.Style := csDropDownList;
  for i := Low(TNodeType) to High(TNodeType) do
    cmbNodeType.Items.Add(NODE_TYPE_NAMES[i]);
  Inc(yPos, 28);

  AddLabelTo(tsGeneral, 'Speaker:', yPos, lblSpeaker);
  edtSpeaker := TEdit.Create(Self);
  edtSpeaker.Parent := tsGeneral;
  edtSpeaker.Left := ctrlX; edtSpeaker.Top := yPos; edtSpeaker.Width := ctrlW;
  Inc(yPos, 28);

  AddLabelTo(tsGeneral, 'Dialogue Text:', yPos, lblText);
  memoText := TMemo.Create(Self);
  memoText.Parent := tsGeneral;
  memoText.Left := ctrlX; memoText.Top := yPos; memoText.Width := ctrlW; memoText.Height := 80;
  memoText.WordWrap := True; memoText.ScrollBars := ssVertical;
  Inc(yPos, 88);

  AddLabelTo(tsGeneral, 'Notes:', yPos, lblNotes);
  memoNotes := TMemo.Create(Self);
  memoNotes.Parent := tsGeneral;
  memoNotes.Left := ctrlX; memoNotes.Top := yPos; memoNotes.Width := ctrlW; memoNotes.Height := 54;
  memoNotes.WordWrap := True; memoNotes.ScrollBars := ssVertical;
  Inc(yPos, 62);

  AddLabelTo(tsGeneral, 'Portrait File:', yPos, lblPortrait);
  edtPortrait := TEdit.Create(Self);
  edtPortrait.Parent := tsGeneral; edtPortrait.Left := ctrlX; edtPortrait.Top := yPos;
  edtPortrait.Width := ctrlW - 32;
  btnPortraitBrowse := TButton.Create(Self);
  btnPortraitBrowse.Parent := tsGeneral; btnPortraitBrowse.Caption := '...';
  btnPortraitBrowse.Left := ctrlX + ctrlW - 28; btnPortraitBrowse.Top := yPos;
  btnPortraitBrowse.Width := 28; btnPortraitBrowse.Height := edtPortrait.Height;
  btnPortraitBrowse.OnClick := btnPortraitBrowseClick;
  Inc(yPos, 28);

  AddLabelTo(tsGeneral, 'Voice File:', yPos, lblVoice);
  edtVoice := TEdit.Create(Self);
  edtVoice.Parent := tsGeneral; edtVoice.Left := ctrlX; edtVoice.Top := yPos;
  edtVoice.Width := ctrlW - 32;
  btnVoiceBrowse := TButton.Create(Self);
  btnVoiceBrowse.Parent := tsGeneral; btnVoiceBrowse.Caption := '...';
  btnVoiceBrowse.Left := ctrlX + ctrlW - 28; btnVoiceBrowse.Top := yPos;
  btnVoiceBrowse.Width := 28; btnVoiceBrowse.Height := edtVoice.Height;
  btnVoiceBrowse.OnClick := btnVoiceBrowseClick;
  Inc(yPos, 28);

  AddLabelTo(tsGeneral, 'Next Node:', yPos, lblNextNode);
  cmbNextNode := TComboBox.Create(Self);
  cmbNextNode.Parent := tsGeneral; cmbNextNode.Left := ctrlX; cmbNextNode.Top := yPos;
  cmbNextNode.Width := ctrlW; cmbNextNode.Style := csDropDown;
  Inc(yPos, 28);

  AddLabelTo(tsGeneral, 'Quest ID:', yPos, lblQuestID);
  edtQuestID := TEdit.Create(Self);
  edtQuestID.Parent := tsGeneral; edtQuestID.Left := ctrlX; edtQuestID.Top := yPos;
  edtQuestID.Width := ctrlW div 2 - 4;
  AddLabelTo(tsGeneral, 'Quest Flag:', yPos, lblQuestFlag);
  lblQuestFlag.Left := ctrlX + ctrlW div 2 + 4;
  edtQuestFlag := TEdit.Create(Self);
  edtQuestFlag.Parent := tsGeneral; edtQuestFlag.Left := ctrlX + ctrlW div 2 + lblQuestFlag.Width + 8;
  edtQuestFlag.Top := yPos; edtQuestFlag.Width := ctrlW div 2 - lblQuestFlag.Width - 12;
  Inc(yPos, 28);

  AddLabelTo(tsGeneral, 'Reputation:', yPos, lblReputation);
  spnReputation := TSpinEdit.Create(Self);
  spnReputation.Parent := tsGeneral; spnReputation.Left := ctrlX; spnReputation.Top := yPos;
  spnReputation.Width := 80; spnReputation.MinValue := -1000; spnReputation.MaxValue := 1000;
  AddLabelTo(tsGeneral, 'Karma:', yPos, lblKarma);
  lblKarma.Left := ctrlX + 90;
  spnKarma := TSpinEdit.Create(Self);
  spnKarma.Parent := tsGeneral; spnKarma.Left := ctrlX + 90 + 80; spnKarma.Top := yPos;
  spnKarma.Width := 80; spnKarma.MinValue := -1000; spnKarma.MaxValue := 1000;
  Inc(yPos, 28);

  AddLabelTo(tsGeneral, 'Tag:', yPos, lblTag);
  edtTag := TEdit.Create(Self);
  edtTag.Parent := tsGeneral; edtTag.Left := ctrlX; edtTag.Top := yPos; edtTag.Width := ctrlW div 2;
  AddLabelTo(tsGeneral, 'Weight:', yPos, lblWeight);
  lblWeight.Left := ctrlX + ctrlW div 2 + 4;
  spnWeight := TSpinEdit.Create(Self);
  spnWeight.Parent := tsGeneral; spnWeight.Left := ctrlX + ctrlW div 2 + 52;
  spnWeight.Top := yPos; spnWeight.Width := 64; spnWeight.MinValue := 1; spnWeight.MaxValue := 100;
  Inc(yPos, 28);

  chkIsStart := TCheckBox.Create(Self);
  chkIsStart.Parent := tsGeneral;
  chkIsStart.Left := ctrlX; chkIsStart.Top := yPos;
  chkIsStart.Caption := 'Mark as Start Node (first node in dialogue)';
  chkIsStart.Width := 320;
  Inc(yPos, 28);

  AddLabelTo(tsGeneral, 'Comment:', yPos, lblComment);
  memoComment := TMemo.Create(Self);
  memoComment.Parent := tsGeneral;
  memoComment.Left := ctrlX; memoComment.Top := yPos; memoComment.Width := ctrlW; memoComment.Height := 60;
  memoComment.WordWrap := True;

  // --- OPTIONS TAB ---
  tsOptions := TTabSheet.Create(pcMain);
  tsOptions.PageControl := pcMain;
  tsOptions.Caption := 'Player Options';

  var optToolPanel := TPanel.Create(Self);
  optToolPanel.Parent := tsOptions;
  optToolPanel.Align := alTop;
  optToolPanel.Height := 36;
  optToolPanel.BevelOuter := bvNone;

  btnAddOption := TButton.Create(Self);
  btnAddOption.Parent := optToolPanel; btnAddOption.Caption := '+ Add Option';
  btnAddOption.Left := 4; btnAddOption.Top := 4; btnAddOption.Width := 100; btnAddOption.Height := 26;
  btnAddOption.OnClick := btnAddOptionClick;

  btnDelOption := TButton.Create(Self);
  btnDelOption.Parent := optToolPanel; btnDelOption.Caption := 'Delete';
  btnDelOption.Left := 108; btnDelOption.Top := 4; btnDelOption.Width := 80; btnDelOption.Height := 26;
  btnDelOption.OnClick := btnDelOptionClick;

  btnMoveUp := TButton.Create(Self);
  btnMoveUp.Parent := optToolPanel; btnMoveUp.Caption := 'Up';
  btnMoveUp.Left := 192; btnMoveUp.Top := 4; btnMoveUp.Width := 60; btnMoveUp.Height := 26;
  btnMoveUp.OnClick := btnMoveUpClick;

  btnMoveDown := TButton.Create(Self);
  btnMoveDown.Parent := optToolPanel; btnMoveDown.Caption := 'Down';
  btnMoveDown.Left := 256; btnMoveDown.Top := 4; btnMoveDown.Width := 68; btnMoveDown.Height := 26;
  btnMoveDown.OnClick := btnMoveDownClick;

  var optSplit := TSplitter.Create(Self);

  lstOptions := TListBox.Create(Self);
  lstOptions.Parent := tsOptions;
  lstOptions.Align := alLeft;
  lstOptions.Width := 200;
  lstOptions.OnClick := lstOptionsClick;

  optSplit.Parent := tsOptions;
  optSplit.Align := alLeft;
  optSplit.Width := 4;

  pnlOptionDetail := TPanel.Create(Self);
  pnlOptionDetail.Parent := tsOptions;
  pnlOptionDetail.Align := alClient;
  pnlOptionDetail.BevelOuter := bvNone;

  var oy := 8;

  AddLabelTo(pnlOptionDetail, 'Option Text:', oy, lblOptText);
  edtOptText := TEdit.Create(Self);
  edtOptText.Parent := pnlOptionDetail; edtOptText.Left := 116; edtOptText.Top := oy;
  edtOptText.Width := pnlOptionDetail.Width - 124; edtOptText.Anchors := [akLeft, akTop, akRight];
  Inc(oy, 28);

  AddLabelTo(pnlOptionDetail, 'Target Node:', oy, lblOptTarget);
  cmbOptTarget := TComboBox.Create(Self);
  cmbOptTarget.Parent := pnlOptionDetail; cmbOptTarget.Left := 116; cmbOptTarget.Top := oy;
  cmbOptTarget.Width := 240; cmbOptTarget.Style := csDropDown;
  Inc(oy, 28);

  chkOptHidden := TCheckBox.Create(Self);
  chkOptHidden.Parent := pnlOptionDetail; chkOptHidden.Left := 116; chkOptHidden.Top := oy;
  chkOptHidden.Caption := 'Hidden (conditionally shown)'; chkOptHidden.Width := 220;
  Inc(oy, 26);

  AddLabelTo(pnlOptionDetail, 'Item Req:', oy, lblItemRequired);
  edtItemRequired := TEdit.Create(Self);
  edtItemRequired.Parent := pnlOptionDetail; edtItemRequired.Left := 116; edtItemRequired.Top := oy;
  edtItemRequired.Width := 200;
  Inc(oy, 28);

  AddLabelTo(pnlOptionDetail, 'Reputation Req:', oy, lblOptRep);
  spnOptRep := TSpinEdit.Create(Self);
  spnOptRep.Parent := pnlOptionDetail; spnOptRep.Left := 116; spnOptRep.Top := oy;
  spnOptRep.Width := 80; spnOptRep.MinValue := -1000; spnOptRep.MaxValue := 1000;
  Inc(oy, 28);

  AddLabelTo(pnlOptionDetail, 'Karma Req:', oy, lblOptKarma);
  lblOptKarma.Left := 210;
  spnOptKarma := TSpinEdit.Create(Self);
  spnOptKarma.Parent := pnlOptionDetail; spnOptKarma.Left := 286; spnOptKarma.Top := oy;
  spnOptKarma.Width := 80; spnOptKarma.MinValue := -1000; spnOptKarma.MaxValue := 1000;
  Inc(oy, 28);

  chkOptSkill := TCheckBox.Create(Self);
  chkOptSkill.Parent := pnlOptionDetail; chkOptSkill.Left := 116; chkOptSkill.Top := oy;
  chkOptSkill.Caption := 'Requires Skill Check';
  chkOptSkill.OnClick := chkOptSkillClick;
  Inc(oy, 26);

  // Skill check panel
  pnlSkillCheck := TPanel.Create(Self);
  pnlSkillCheck.Parent := pnlOptionDetail;
  pnlSkillCheck.Left := 8; pnlSkillCheck.Top := oy;
  pnlSkillCheck.Width := pnlOptionDetail.Width - 16;
  pnlSkillCheck.Height := 160;
  pnlSkillCheck.Anchors := [akLeft, akTop, akRight];
  pnlSkillCheck.BevelOuter := bvLowered;
  pnlSkillCheck.Visible := False;
  pnlSkillCheck.Caption := '';

  var sky := 8;
  AddLabelTo(pnlSkillCheck, 'Skill:', sky, lblSkillType);
  cmbSkillType := TComboBox.Create(Self);
  cmbSkillType.Parent := pnlSkillCheck; cmbSkillType.Left := 116; cmbSkillType.Top := sky;
  cmbSkillType.Width := 160; cmbSkillType.Style := csDropDownList;
  for sk := Low(TSkillType) to High(TSkillType) do
    cmbSkillType.Items.Add(SKILL_NAMES[sk]);
  Inc(sky, 28);

  var skLabel := TLabel.Create(Self);
  skLabel.Parent := pnlSkillCheck; skLabel.Left := 8; skLabel.Top := sky + 3;
  skLabel.Caption := 'Difficulty:'; skLabel.Width := 100; skLabel.Alignment := taRightJustify;
  trkDifficulty := TTrackBar.Create(Self);
  trkDifficulty.Parent := pnlSkillCheck; trkDifficulty.Left := 116; trkDifficulty.Top := sky;
  trkDifficulty.Width := 160; trkDifficulty.Min := 1; trkDifficulty.Max := 100;
  trkDifficulty.Frequency := 10; trkDifficulty.OnChange := trkDifficultyChange;
  lblDiffValue := TLabel.Create(Self);
  lblDiffValue.Parent := pnlSkillCheck; lblDiffValue.Left := 280; lblDiffValue.Top := sky + 3;
  lblDiffValue.Caption := '50';
  Inc(sky, 28);

  var skXP := TLabel.Create(Self);
  skXP.Parent := pnlSkillCheck; skXP.Left := 8; skXP.Top := sky + 3;
  skXP.Caption := 'XP Reward:'; skXP.Width := 100; skXP.Alignment := taRightJustify;
  spnXPReward := TSpinEdit.Create(Self);
  spnXPReward.Parent := pnlSkillCheck; spnXPReward.Left := 116; spnXPReward.Top := sky;
  spnXPReward.Width := 80; spnXPReward.MinValue := 0; spnXPReward.MaxValue := 9999;
  Inc(sky, 28);

  var skSucc := TLabel.Create(Self);
  skSucc.Parent := pnlSkillCheck; skSucc.Left := 8; skSucc.Top := sky + 3;
  skSucc.Caption := 'Success ->'; skSucc.Width := 100; skSucc.Alignment := taRightJustify;
  cmbSuccessNode := TComboBox.Create(Self);
  cmbSuccessNode.Parent := pnlSkillCheck; cmbSuccessNode.Left := 116; cmbSuccessNode.Top := sky;
  cmbSuccessNode.Width := 200; cmbSuccessNode.Style := csDropDown;
  Inc(sky, 28);

  var skFail := TLabel.Create(Self);
  skFail.Parent := pnlSkillCheck; skFail.Left := 8; skFail.Top := sky + 3;
  skFail.Caption := 'Failure ->'; skFail.Width := 100; skFail.Alignment := taRightJustify;
  cmbFailNode := TComboBox.Create(Self);
  cmbFailNode.Parent := pnlSkillCheck; cmbFailNode.Left := 116; cmbFailNode.Top := sky;
  cmbFailNode.Width := 200; cmbFailNode.Style := csDropDown;

  // --- CONDITIONS TAB ---
  tsConditions := TTabSheet.Create(pcMain);
  tsConditions.PageControl := pcMain;
  tsConditions.Caption := 'Conditions';

  var condTool := TPanel.Create(Self);
  condTool.Parent := tsConditions; condTool.Align := alTop; condTool.Height := 36; condTool.BevelOuter := bvNone;
  btnAddCond := TButton.Create(Self);
  btnAddCond.Parent := condTool; btnAddCond.Caption := '+ Add Condition';
  btnAddCond.Left := 4; btnAddCond.Top := 4; btnAddCond.Width := 120; btnAddCond.Height := 26;
  btnAddCond.OnClick := btnAddCondClick;
  btnDelCond := TButton.Create(Self);
  btnDelCond.Parent := condTool; btnDelCond.Caption := 'Delete';
  btnDelCond.Left := 128; btnDelCond.Top := 4; btnDelCond.Width := 80; btnDelCond.Height := 26;
  btnDelCond.OnClick := btnDelCondClick;

  lstConditions := TListBox.Create(Self);
  lstConditions.Parent := tsConditions; lstConditions.Align := alLeft; lstConditions.Width := 200;
  lstConditions.OnClick := lstConditionsClick;

  var condSplit := TSplitter.Create(Self);
  condSplit.Parent := tsConditions; condSplit.Align := alLeft; condSplit.Width := 4;

  pnlCondDetail := TPanel.Create(Self);
  pnlCondDetail.Parent := tsConditions; pnlCondDetail.Align := alClient; pnlCondDetail.BevelOuter := bvNone;

  var cy := 12;
  FLabelW := 110;

  AddLabelTo(pnlCondDetail, 'Condition Type:', cy, lblCondType);
  cmbCondType := TComboBox.Create(Self);
  cmbCondType.Parent := pnlCondDetail; cmbCondType.Left := 130; cmbCondType.Top := cy;
  cmbCondType.Width := 200; cmbCondType.Style := csDropDownList;
  for ct := Low(TConditionType) to High(TConditionType) do
    cmbCondType.Items.Add(GetEnumName(TypeInfo(TConditionType), Ord(ct)));
  Inc(cy, 28);

  AddLabelTo(pnlCondDetail, 'Variable/Key:', cy, lblCondVar);
  edtCondVar := TEdit.Create(Self);
  edtCondVar.Parent := pnlCondDetail; edtCondVar.Left := 130; edtCondVar.Top := cy; edtCondVar.Width := 200;
  Inc(cy, 28);

  AddLabelTo(pnlCondDetail, 'Operator:', cy, lblCondOp);
  cmbCondOp := TComboBox.Create(Self);
  cmbCondOp.Parent := pnlCondDetail; cmbCondOp.Left := 130; cmbCondOp.Top := cy;
  cmbCondOp.Width := 100; cmbCondOp.Style := csDropDownList;
  for co := Low(TConditionOperator) to High(TConditionOperator) do
    cmbCondOp.Items.Add(OPERATOR_NAMES[co]);
  Inc(cy, 28);

  AddLabelTo(pnlCondDetail, 'Value:', cy, lblCondVal);
  edtCondVal := TEdit.Create(Self);
  edtCondVal.Parent := pnlCondDetail; edtCondVal.Left := 130; edtCondVal.Top := cy; edtCondVal.Width := 200;
  Inc(cy, 28);

  AddLabelTo(pnlCondDetail, 'Boolean Op:', cy, lblCondBool);
  cmbCondBool := TComboBox.Create(Self);
  cmbCondBool.Parent := pnlCondDetail; cmbCondBool.Left := 130; cmbCondBool.Top := cy;
  cmbCondBool.Width := 100; cmbCondBool.Style := csDropDownList;
  cmbCondBool.Items.AddStrings(['AND', 'OR', 'NOT']);
  Inc(cy, 36);

  lblProbPreview := TLabel.Create(Self);
  lblProbPreview.Parent := pnlCondDetail;
  lblProbPreview.Left := 130; lblProbPreview.Top := cy;
  lblProbPreview.Caption := 'Total conditions: 0';
  lblProbPreview.Font.Style := [fsBold];

  // --- SCRIPTS TAB ---
  tsScripts := TTabSheet.Create(pcMain);
  tsScripts.PageControl := pcMain;
  tsScripts.Caption := 'Scripts';

  var scriptTool := TPanel.Create(Self);
  scriptTool.Parent := tsScripts; scriptTool.Align := alTop; scriptTool.Height := 36; scriptTool.BevelOuter := bvNone;
  btnAddScript := TButton.Create(Self);
  btnAddScript.Parent := scriptTool; btnAddScript.Caption := '+ Add Script';
  btnAddScript.Left := 4; btnAddScript.Top := 4; btnAddScript.Width := 100; btnAddScript.Height := 26;
  btnAddScript.OnClick := btnAddScriptClick;
  btnDelScript := TButton.Create(Self);
  btnDelScript.Parent := scriptTool; btnDelScript.Caption := 'Delete';
  btnDelScript.Left := 108; btnDelScript.Top := 4; btnDelScript.Width := 80; btnDelScript.Height := 26;
  btnDelScript.OnClick := btnDelScriptClick;

  lstScripts := TListBox.Create(Self);
  lstScripts.Parent := tsScripts; lstScripts.Align := alLeft; lstScripts.Width := 180;
  lstScripts.OnClick := lstScriptsClick;

  var scSplit := TSplitter.Create(Self);
  scSplit.Parent := tsScripts; scSplit.Align := alLeft; scSplit.Width := 4;

  pnlScriptDetail := TPanel.Create(Self);
  pnlScriptDetail.Parent := tsScripts; pnlScriptDetail.Align := alClient; pnlScriptDetail.BevelOuter := bvNone;

  var sy2 := 8;
  var scLabel := TLabel.Create(Self);
  scLabel.Parent := pnlScriptDetail; scLabel.Left := 8; scLabel.Top := sy2 + 3;
  scLabel.Caption := 'Event Type:'; scLabel.Width := 90;
  cmbEventType := TComboBox.Create(Self);
  cmbEventType.Parent := pnlScriptDetail; cmbEventType.Left := 104; cmbEventType.Top := sy2;
  cmbEventType.Width := 200; cmbEventType.Style := csDropDownList;
  for se := Low(TScriptEvent) to High(TScriptEvent) do
    cmbEventType.Items.Add(GetEnumName(TypeInfo(TScriptEvent), Ord(se)));
  Inc(sy2, 28);

  chkScriptEnabled := TCheckBox.Create(Self);
  chkScriptEnabled.Parent := pnlScriptDetail; chkScriptEnabled.Left := 104; chkScriptEnabled.Top := sy2;
  chkScriptEnabled.Caption := 'Script Enabled';
  Inc(sy2, 28);

  var scCodeLabel := TLabel.Create(Self);
  scCodeLabel.Parent := pnlScriptDetail; scCodeLabel.Left := 8; scCodeLabel.Top := sy2;
  scCodeLabel.Caption := 'Script Code:'; scCodeLabel.Font.Style := [fsBold];
  Inc(sy2, 20);

  memoScript := TMemo.Create(Self);
  memoScript.Parent := pnlScriptDetail;
  memoScript.Left := 4; memoScript.Top := sy2;
  memoScript.Width := pnlScriptDetail.Width - 8;
  memoScript.Height := pnlScriptDetail.Height - sy2 - 40;
  memoScript.Anchors := [akLeft, akTop, akRight, akBottom];
  memoScript.ScrollBars := ssBoth; memoScript.WordWrap := False;
  memoScript.Font.Name := 'Courier New'; memoScript.Font.Size := 10;

  lblScriptRef := TLabel.Create(Self);
  lblScriptRef.Parent := pnlScriptDetail;
  lblScriptRef.Left := 4; lblScriptRef.Anchors := [akLeft, akBottom];
  lblScriptRef.Top := pnlScriptDetail.Height - 28;
  lblScriptRef.Caption := 'Tip: Use player.skill[SPEECH], global_var["VAR_NAME"], npc.reputation, etc.';
  lblScriptRef.Font.Size := 8;
end;

procedure TNodePropertiesForm.StyleForm;
var
  t: TFDCTheme;
begin
  t := TThemeManager.Current;
  TControlHack(Self).Color := t.BgDark;
  Font.Color := t.TextPrimary;
  Font.Name := t.FontName;

  pnlHeader.Color := t.BgMedium;
  lblTitle.Font.Color := t.AccentPrimary;
  lblTitle.Font.Size := 14;

  pnlButtons.Color := t.BgMedium;

  for var i := 0 to ComponentCount - 1 do
  begin
    if Components[i] is TMemo then
    begin
      (Components[i] as TMemo).Color := t.BgLight;
      (Components[i] as TMemo).Font.Color := t.TextPrimary;
    end else if Components[i] is TEdit then
    begin
      (Components[i] as TEdit).Color := t.BgLight;
      (Components[i] as TEdit).Font.Color := t.TextPrimary;
    end else if Components[i] is TComboBox then
    begin
      (Components[i] as TComboBox).Color := t.BgLight;
      (Components[i] as TComboBox).Font.Color := t.TextPrimary;
    end else if Components[i] is TLabel then
    begin
      (Components[i] as TLabel).Font.Color := t.TextSecondary;
    end else if Components[i] is TPanel then
    begin
      (Components[i] as TPanel).Color := t.BgDark;
      (Components[i] as TPanel).Font.Color := t.TextPrimary;
    end else if Components[i] is TListBox then
    begin
      (Components[i] as TListBox).Color := t.BgMedium;
      (Components[i] as TListBox).Font.Color := t.TextPrimary;
    end else if Components[i] is TCheckBox then
    begin
      (Components[i] as TCheckBox).Color := t.BgDark;
      (Components[i] as TCheckBox).Font.Color := t.TextPrimary;
    end;
  end;

  memoScript.Font.Name := t.MonoFontName;
  memoScript.Font.Color := t.AccentPrimary;

  TControlHack(pcMain).Color := t.BgDark;
   TThemeManager.ApplyToForm(Self);
end;

procedure TNodePropertiesForm.PopulateNodeCombos;
var
  node: TDialogueNode;
  display: string;
begin
  if not Assigned(FProject) then Exit;
  cmbNextNode.Items.Clear;
  cmbNextNode.Items.Add('(none)');
  cmbOptTarget.Items.Clear;
  cmbOptTarget.Items.Add('(none)');
  cmbSuccessNode.Items.Clear;
  cmbSuccessNode.Items.Add('(none)');
  cmbFailNode.Items.Clear;
  cmbFailNode.Items.Add('(none)');
  for node in FProject.Nodes do
  begin
    if node = FNode then Continue;
    display := '[' + Copy(node.ID, 1, 8) + '] ' +
      NODE_TYPE_NAMES[node.NodeType];
    if node.Speaker <> '' then display := display + ' - ' + node.Speaker;
    if Trim(node.Text) <> '' then
      display := display + ': ' + Copy(Trim(node.Text), 1, 30);
    cmbNextNode.Items.AddObject(display, TObject(node));
    cmbOptTarget.Items.AddObject(display, TObject(node));
    cmbSuccessNode.Items.AddObject(display, TObject(node));
    cmbFailNode.Items.AddObject(display, TObject(node));
  end;
end;

procedure TNodePropertiesForm.PopulateFromNode;
var
  i: Integer;
begin
  if not Assigned(FNode) then Exit;

  cmbNodeType.ItemIndex := Ord(FNode.NodeType);
  edtSpeaker.Text := FNode.Speaker;
  memoText.Text := FNode.Text;
  memoNotes.Text := FNode.Notes;
  edtPortrait.Text := FNode.PortraitFile;
  edtVoice.Text := FNode.VoiceFile;
  edtQuestID.Text := FNode.QuestID;
  edtQuestFlag.Text := FNode.QuestFlag;
  spnReputation.Value := FNode.Reputation;
  spnKarma.Value := FNode.Karma;
  edtTag.Text := FNode.Tag;
  spnWeight.Value := FNode.RandomWeight;
  chkIsStart.Checked := FNode.IsStartNode;
  memoComment.Text := FNode.Comment;
  edtCombatScript.Text := FNode.CombatScript;

  cmbNextNode.Text := FNode.NextNodeID;
  for i := 1 to cmbNextNode.Items.Count - 1 do
    if TDialogueNode(cmbNextNode.Items.Objects[i]).ID = FNode.NextNodeID then
    begin
      cmbNextNode.ItemIndex := i;
      Break;
    end;

  RefreshOptionList;
  RefreshConditionList;
  RefreshScriptList;

  lblTitle.Caption := 'Node Properties  [' + Copy(FNode.ID, 1, 16) + ']  - ' + NODE_TYPE_NAMES[FNode.NodeType];
end;

procedure TNodePropertiesForm.RefreshOptionList;
var
  opt: TPlayerOption;
  display: string;
begin
  lstOptions.Items.Clear;
  for opt in FNode.PlayerOptions do
  begin
    display := opt.Text;
    if display = '' then display := '(empty)';
    if opt.HasSkillCheck then
      display := '[SKILL] ' + display;
    if opt.IsHidden then
      display := '[H] ' + display;
    lstOptions.Items.AddObject(display, opt);
  end;
end;

procedure TNodePropertiesForm.RefreshConditionList;
var
  cond: TCondition;
  display: string;
begin
  lstConditions.Items.Clear;
  for cond in FNode.Conditions do
  begin
    display := GetEnumName(TypeInfo(TConditionType), Ord(cond.CondType)) +
      ' ' + cond.Variable + ' ' + OPERATOR_NAMES[cond.Operator] + ' ' + cond.Value;
    lstConditions.Items.Add(display);
  end;
  lblProbPreview.Caption := 'Total conditions: ' + IntToStr(FNode.Conditions.Count);
end;

procedure TNodePropertiesForm.RefreshScriptList;
var
  sc: TNodeScript;
  display: string;
begin
  lstScripts.Items.Clear;
  for sc in FNode.Scripts do
  begin
    display := GetEnumName(TypeInfo(TScriptEvent), Ord(sc.EventType));
    if not sc.IsEnabled then display := '[OFF] ' + display;
    lstScripts.Items.AddObject(display, sc);
  end;
end;

procedure TNodePropertiesForm.lstOptionsClick(Sender: TObject);
var
  opt: TPlayerOption;
  i: Integer;
begin
  if lstOptions.ItemIndex < 0 then Exit;
  opt := TPlayerOption(lstOptions.Items.Objects[lstOptions.ItemIndex]);
  if not Assigned(opt) then Exit;

  edtOptText.Text := opt.Text;
  cmbOptTarget.Text := opt.TargetNodeID;
  for i := 1 to cmbOptTarget.Items.Count - 1 do
    if TDialogueNode(cmbOptTarget.Items.Objects[i]).ID = opt.TargetNodeID then
    begin cmbOptTarget.ItemIndex := i; Break; end;

  chkOptHidden.Checked := opt.IsHidden;
  chkOptSkill.Checked := opt.HasSkillCheck;
  edtItemRequired.Text := opt.ItemRequired;
  spnOptRep.Value := opt.ReputationRequired;
  spnOptKarma.Value := opt.KarmaRequired;
  pnlSkillCheck.Visible := opt.HasSkillCheck;

  if opt.HasSkillCheck then
  begin
    cmbSkillType.ItemIndex := Ord(opt.SkillCheck.Skill);
    trkDifficulty.Position := opt.SkillCheck.Difficulty;
    spnXPReward.Value := opt.SkillCheck.XPReward;
    edtSuccessMsg.Text := opt.SkillCheck.SuccessMessage;
    edtFailMsg.Text := opt.SkillCheck.FailureMessage;

    for i := 1 to cmbSuccessNode.Items.Count - 1 do
      if TDialogueNode(cmbSuccessNode.Items.Objects[i]).ID = opt.SkillCheck.SuccessNodeID then
      begin cmbSuccessNode.ItemIndex := i; Break; end;
    for i := 1 to cmbFailNode.Items.Count - 1 do
      if TDialogueNode(cmbFailNode.Items.Objects[i]).ID = opt.SkillCheck.FailureNodeID then
      begin cmbFailNode.ItemIndex := i; Break; end;
  end;
end;

procedure TNodePropertiesForm.lstConditionsClick(Sender: TObject);
var
  idx: Integer;
  cond: TCondition;
begin
  idx := lstConditions.ItemIndex;
  if (idx < 0) or (idx >= FNode.Conditions.Count) then Exit;
  cond := FNode.Conditions[idx];
  cmbCondType.ItemIndex := Ord(cond.CondType);
  edtCondVar.Text := cond.Variable;
  cmbCondOp.ItemIndex := Ord(cond.Operator);
  edtCondVal.Text := cond.Value;
  cmbCondBool.ItemIndex := Ord(cond.BoolOp);
end;

procedure TNodePropertiesForm.lstScriptsClick(Sender: TObject);
var
  sc: TNodeScript;
begin
  if lstScripts.ItemIndex < 0 then Exit;
  sc := TNodeScript(lstScripts.Items.Objects[lstScripts.ItemIndex]);
  if not Assigned(sc) then Exit;
  cmbEventType.ItemIndex := Ord(sc.EventType);
  chkScriptEnabled.Checked := sc.IsEnabled;
  memoScript.Text := sc.ScriptCode;
end;

procedure TNodePropertiesForm.SaveCurrentOption;
var
  opt: TPlayerOption;
  i: Integer;
begin
  if lstOptions.ItemIndex < 0 then Exit;
  opt := TPlayerOption(lstOptions.Items.Objects[lstOptions.ItemIndex]);
  if not Assigned(opt) then Exit;
  opt.Text := edtOptText.Text;
  opt.IsHidden := chkOptHidden.Checked;
  opt.HasSkillCheck := chkOptSkill.Checked;
  opt.ItemRequired := edtItemRequired.Text;
  opt.ReputationRequired := spnOptRep.Value;
  opt.KarmaRequired := spnOptKarma.Value;

  if cmbOptTarget.ItemIndex > 0 then
    opt.TargetNodeID := TDialogueNode(cmbOptTarget.Items.Objects[cmbOptTarget.ItemIndex]).ID
  else
    opt.TargetNodeID := '';

  if opt.HasSkillCheck then
  begin
    opt.SkillCheck.Skill := TSkillType(cmbSkillType.ItemIndex);
    opt.SkillCheck.Difficulty := trkDifficulty.Position;
    opt.SkillCheck.XPReward := spnXPReward.Value;
    opt.SkillCheck.SuccessMessage := edtSuccessMsg.Text;
    opt.SkillCheck.FailureMessage := edtFailMsg.Text;
    if cmbSuccessNode.ItemIndex > 0 then
      opt.SkillCheck.SuccessNodeID := TDialogueNode(cmbSuccessNode.Items.Objects[cmbSuccessNode.ItemIndex]).ID
    else
      opt.SkillCheck.SuccessNodeID := '';
    if cmbFailNode.ItemIndex > 0 then
      opt.SkillCheck.FailureNodeID := TDialogueNode(cmbFailNode.Items.Objects[cmbFailNode.ItemIndex]).ID
    else
      opt.SkillCheck.FailureNodeID := '';
  end;
end;

procedure TNodePropertiesForm.SaveCurrentCondition;
var
  idx: Integer;
  cond: TCondition;
begin
  idx := lstConditions.ItemIndex;
  if (idx < 0) or (idx >= FNode.Conditions.Count) then Exit;
  cond := FNode.Conditions[idx];
  cond.CondType := TConditionType(cmbCondType.ItemIndex);
  cond.Variable := edtCondVar.Text;
  cond.Operator := TConditionOperator(cmbCondOp.ItemIndex);
  cond.Value := edtCondVal.Text;
  cond.BoolOp := TBoolOp(cmbCondBool.ItemIndex);
  FNode.Conditions[idx] := cond;
end;

procedure TNodePropertiesForm.SaveCurrentScript;
var
  sc: TNodeScript;
begin
  if lstScripts.ItemIndex < 0 then Exit;
  sc := TNodeScript(lstScripts.Items.Objects[lstScripts.ItemIndex]);
  if not Assigned(sc) then Exit;
  sc.EventType := TScriptEvent(cmbEventType.ItemIndex);
  sc.IsEnabled := chkScriptEnabled.Checked;
  sc.ScriptCode := memoScript.Text;
end;

procedure TNodePropertiesForm.SaveToNode;
begin
  SaveCurrentOption;
  SaveCurrentCondition;
  SaveCurrentScript;

  FNode.NodeType := TNodeType(cmbNodeType.ItemIndex);
  FNode.Speaker := edtSpeaker.Text;
  FNode.Text := memoText.Text;
  FNode.Notes := memoNotes.Text;
  FNode.PortraitFile := edtPortrait.Text;
  FNode.VoiceFile := edtVoice.Text;
  FNode.QuestID := edtQuestID.Text;
  FNode.QuestFlag := edtQuestFlag.Text;
  FNode.Reputation := spnReputation.Value;
  FNode.Karma := spnKarma.Value;
  FNode.Tag := edtTag.Text;
  FNode.RandomWeight := spnWeight.Value;
  FNode.Comment := memoComment.Text;
  FNode.CombatScript := edtCombatScript.Text;

  if FNode.IsStartNode <> chkIsStart.Checked then
  begin
    if chkIsStart.Checked then
    begin
      for var node in FProject.Nodes do node.IsStartNode := False;
      FProject.StartNodeID := FNode.ID;
    end;
    FNode.IsStartNode := chkIsStart.Checked;
  end;

  if cmbNextNode.ItemIndex > 0 then
    FNode.NextNodeID := TDialogueNode(cmbNextNode.Items.Objects[cmbNextNode.ItemIndex]).ID
  else if cmbNextNode.ItemIndex = 0 then
    FNode.NextNodeID := ''
  else
    FNode.NextNodeID := cmbNextNode.Text;
end;

procedure TNodePropertiesForm.btnAddOptionClick(Sender: TObject);
var
  opt: TPlayerOption;
begin
  opt := TPlayerOption.Create;
  opt.Text := 'New response option';
  FNode.PlayerOptions.Add(opt);
  RefreshOptionList;
  lstOptions.ItemIndex := lstOptions.Items.Count - 1;
  lstOptionsClick(nil);
end;

procedure TNodePropertiesForm.btnDelOptionClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := lstOptions.ItemIndex;
  if idx < 0 then Exit;
  FNode.PlayerOptions.Delete(idx);
  RefreshOptionList;
  if lstOptions.Items.Count > 0 then
    lstOptions.ItemIndex := Min(idx, lstOptions.Items.Count - 1);
end;

procedure TNodePropertiesForm.btnMoveUpClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := lstOptions.ItemIndex;
  if idx <= 0 then Exit;
  FNode.PlayerOptions.Exchange(idx, idx - 1);
  RefreshOptionList;
  lstOptions.ItemIndex := idx - 1;
end;

procedure TNodePropertiesForm.btnMoveDownClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := lstOptions.ItemIndex;
  if (idx < 0) or (idx >= FNode.PlayerOptions.Count - 1) then Exit;
  FNode.PlayerOptions.Exchange(idx, idx + 1);
  RefreshOptionList;
  lstOptions.ItemIndex := idx + 1;
end;

procedure TNodePropertiesForm.btnAddCondClick(Sender: TObject);
var
  cond: TCondition;
begin
  cond.CondType := ctSkillCheck;
  cond.Variable := 'SPEECH';
  cond.Operator := coGTE;
  cond.Value := '50';
  cond.BoolOp := boAND;
  FNode.Conditions.Add(cond);
  RefreshConditionList;
  lstConditions.ItemIndex := lstConditions.Items.Count - 1;
  lstConditionsClick(nil);
end;

procedure TNodePropertiesForm.btnDelCondClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := lstConditions.ItemIndex;
  if idx < 0 then Exit;
  FNode.Conditions.Delete(idx);
  RefreshConditionList;
end;

procedure TNodePropertiesForm.btnAddScriptClick(Sender: TObject);
var
  sc: TNodeScript;
begin
  sc := TNodeScript.Create;
  sc.EventType := seOnNodeEnter;
  sc.ScriptCode := '// Script code here' + sLineBreak +
    'procedure OnNodeEnter(npc, player: TEntity; nodeID: string);' + sLineBreak +
    'begin' + sLineBreak +
    '  // Your code' + sLineBreak +
    'end;';
  FNode.Scripts.Add(sc);
  RefreshScriptList;
  lstScripts.ItemIndex := lstScripts.Items.Count - 1;
  lstScriptsClick(nil);
end;

procedure TNodePropertiesForm.btnDelScriptClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := lstScripts.ItemIndex;
  if idx < 0 then Exit;
  FNode.Scripts.Delete(idx);
  RefreshScriptList;
end;

procedure TNodePropertiesForm.chkOptSkillClick(Sender: TObject);
begin
  pnlSkillCheck.Visible := chkOptSkill.Checked;
end;

procedure TNodePropertiesForm.trkDifficultyChange(Sender: TObject);
begin
  lblDiffValue.Caption := IntToStr(trkDifficulty.Position) + '%';
end;

procedure TNodePropertiesForm.btnOKClick(Sender: TObject);
begin
  SaveToNode;
  ModalResult := mrOk;
end;

procedure TNodePropertiesForm.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TNodePropertiesForm.btnApplyClick(Sender: TObject);
begin
  SaveToNode;
end;

procedure TNodePropertiesForm.btnPortraitBrowseClick(Sender: TObject);
var
  dlg: TOpenDialog;
begin
  dlg := TOpenDialog.Create(nil);
  try
    dlg.Filter := 'Image Files|*.png;*.jpg;*.bmp;*.gif|All Files|*.*';
    dlg.Title := 'Select Portrait Image';
    if dlg.Execute then
      edtPortrait.Text := dlg.FileName;
  finally
    dlg.Free;
  end;
end;

procedure TNodePropertiesForm.btnVoiceBrowseClick(Sender: TObject);
var
  dlg: TOpenDialog;
begin
  dlg := TOpenDialog.Create(nil);
  try
    dlg.Filter := 'Audio Files|*.wav;*.ogg;*.mp3|All Files|*.*';
    dlg.Title := 'Select Voice Audio';
    if dlg.Execute then
      edtVoice.Text := dlg.FileName;
  finally
    dlg.Free;
  end;
end;

initialization
  System.Classes.RegisterClass(TNodePropertiesForm);

end.