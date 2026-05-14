unit uSkillCheckEditor;

interface

uses
  System.SysUtils, System.Classes, System.Math,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ExtCtrls, Vcl.Graphics, Vcl.Samples.Spin,
  uDialogueTypes, uThemeManager;

type
  TSkillCheckEditorForm = class(TForm)
  private
    FSkillCheck: TSkillCheck;
    FReadOnly: Boolean;
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pnlBody: TPanel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    cmbSkill: TComboBox;
    trkDifficulty: TTrackBar;
    lblDiffVal: TLabel;
    lblProbability: TLabel;
    pnlProbBar: TPanel;
    pnlProbFill: TPanel;
    spnXP: TSpinEdit;
    spnCritBonus: TSpinEdit;
    edtSuccessMsg: TEdit;
    edtFailMsg: TEdit;
    edtSuccessNode: TEdit;
    edtFailNode: TEdit;
    pnlSimulate: TPanel;
    lblSimTitle: TLabel;
    lblSimSkillVal: TLabel;
    spnSimSkill: TSpinEdit;
    btnSimulate: TButton;
    memoSimResult: TMemo;
    procedure BuildLayout;
    procedure StyleForm;
    procedure PopulateFromSkillCheck;
    procedure SaveToSkillCheck;
    procedure UpdateProbabilityBar;
    procedure trkDifficultyChange(Sender: TObject);
    procedure spnSimSkillChange(Sender: TObject);
    procedure btnSimulateClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  public
    class function Execute(AOwner: TComponent; var sk: TSkillCheck; readOnly: Boolean = False): Boolean;
    property SkillCheck: TSkillCheck read FSkillCheck write FSkillCheck;
  end;

implementation

class function TSkillCheckEditorForm.Execute(AOwner: TComponent; var sk: TSkillCheck;
  readOnly: Boolean): Boolean;
var frm: TSkillCheckEditorForm;
begin
   frm := TSkillCheckEditorForm.CreateNew(AOwner);
   try
     frm.FSkillCheck := sk;
     frm.FReadOnly := readOnly;
     frm.BuildLayout;
     frm.StyleForm;
     frm.PopulateFromSkillCheck;
     Result := frm.ShowModal = mrOk;
     if Result then sk := frm.FSkillCheck;
   finally frm.Free; end;
end;

procedure TSkillCheckEditorForm.FormCreate(Sender: TObject);
begin BuildLayout; StyleForm; end;

procedure TSkillCheckEditorForm.BuildLayout;
var
  y, lw, cx, cw: Integer;
  sk: TSkillType;
  lbl: TLabel;
begin
  Width := 520; Height := 560;
  Caption := 'Skill Check Editor';
  Position := poMainFormCenter;
  OnCreate := FormCreate;

  pnlHeader := TPanel.Create(Self); pnlHeader.Parent := Self;
  pnlHeader.Align := alTop; pnlHeader.Height := 38; pnlHeader.BevelOuter := bvNone;
  lblTitle := TLabel.Create(Self); lblTitle.Parent := pnlHeader;
  lblTitle.Left := 10; lblTitle.Top := 8;
  lblTitle.Caption := 'SKILL CHECK CONFIGURATION';
  lblTitle.Font.Size := 12; lblTitle.Font.Style := [fsBold];

  pnlBottom := TPanel.Create(Self); pnlBottom.Parent := Self;
  pnlBottom.Align := alBottom; pnlBottom.Height := 42; pnlBottom.BevelOuter := bvNone;
  btnOK := TButton.Create(Self); btnOK.Parent := pnlBottom;
  btnOK.Caption := 'OK'; btnOK.Left := pnlBottom.Width - 196; btnOK.Top := 7;
  btnOK.Width := 88; btnOK.Height := 28; btnOK.OnClick := btnOKClick;
  btnCancel := TButton.Create(Self); btnCancel.Parent := pnlBottom;
  btnCancel.Caption := 'Cancel'; btnCancel.ModalResult := mrCancel;
  btnCancel.Left := pnlBottom.Width - 100; btnCancel.Top := 7;
  btnCancel.Width := 88; btnCancel.Height := 28;
  btnOK.Anchors := [akRight, akTop]; btnCancel.Anchors := [akRight, akTop];

  pnlBody := TPanel.Create(Self); pnlBody.Parent := Self;
  pnlBody.Align := alClient; pnlBody.BevelOuter := bvNone;

  y := 10;
  lw := 120; cx := 138; cw := 280;

  lbl := TLabel.Create(Self); lbl.Parent := pnlBody;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw; lbl.Caption := 'Skill:';
  lbl.Alignment := taRightJustify;
  cmbSkill := TComboBox.Create(Self); cmbSkill.Parent := pnlBody;
  cmbSkill.Left := cx; cmbSkill.Top := y; cmbSkill.Width := 200;
  cmbSkill.Style := csDropDownList;
  for sk := Low(TSkillType) to High(TSkillType) do cmbSkill.Items.Add(SKILL_NAMES[sk]);
  cmbSkill.ItemIndex := 0;
  Inc(y, 30);

  lbl := TLabel.Create(Self); lbl.Parent := pnlBody;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw; lbl.Caption := 'Difficulty (1-100):';
  lbl.Alignment := taRightJustify;
  trkDifficulty := TTrackBar.Create(Self); trkDifficulty.Parent := pnlBody;
  trkDifficulty.Left := cx; trkDifficulty.Top := y; trkDifficulty.Width := 200;
  trkDifficulty.Min := 1; trkDifficulty.Max := 100; trkDifficulty.Position := 50;
  trkDifficulty.Frequency := 10; trkDifficulty.OnChange := trkDifficultyChange;
  lblDiffVal := TLabel.Create(Self); lblDiffVal.Parent := pnlBody;
  lblDiffVal.Left := cx + 208; lblDiffVal.Top := y + 6;
  lblDiffVal.Caption := '50%'; lblDiffVal.Width := 50; lblDiffVal.Font.Style := [fsBold];
  Inc(y, 36);

  lbl := TLabel.Create(Self); lbl.Parent := pnlBody;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw; lbl.Caption := 'Success Probability:';
  lbl.Alignment := taRightJustify;
  pnlProbBar := TPanel.Create(Self); pnlProbBar.Parent := pnlBody;
  pnlProbBar.Left := cx; pnlProbBar.Top := y + 3;
  pnlProbBar.Width := 200; pnlProbBar.Height := 18;
  pnlProbBar.BevelOuter := bvLowered; pnlProbBar.BevelInner := bvNone;
  pnlProbFill := TPanel.Create(Self); pnlProbFill.Parent := pnlProbBar;
  pnlProbFill.Left := 0; pnlProbFill.Top := 0;
  pnlProbFill.Width := 100; pnlProbFill.Height := 18;
  pnlProbFill.BevelOuter := bvNone; pnlProbFill.Caption := '';
  lblProbability := TLabel.Create(Self); lblProbability.Parent := pnlBody;
  lblProbability.Left := cx + 208; lblProbability.Top := y + 3;
  lblProbability.Caption := '50%'; lblProbability.Width := 60;
  Inc(y, 30);

  lbl := TLabel.Create(Self); lbl.Parent := pnlBody;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw; lbl.Caption := 'XP Reward:';
  lbl.Alignment := taRightJustify;
  spnXP := TSpinEdit.Create(Self); spnXP.Parent := pnlBody;
  spnXP.Left := cx; spnXP.Top := y; spnXP.Width := 100;
  spnXP.MinValue := 0; spnXP.MaxValue := 9999; spnXP.Value := 50;
  Inc(y, 30);

  lbl := TLabel.Create(Self); lbl.Parent := pnlBody;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw; lbl.Caption := 'Crit. Success Bonus:';
  lbl.Alignment := taRightJustify;
  spnCritBonus := TSpinEdit.Create(Self); spnCritBonus.Parent := pnlBody;
  spnCritBonus.Left := cx; spnCritBonus.Top := y; spnCritBonus.Width := 100;
  spnCritBonus.MinValue := 0; spnCritBonus.MaxValue := 200; spnCritBonus.Value := 0;
  Inc(y, 30);

  lbl := TLabel.Create(Self); lbl.Parent := pnlBody;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw; lbl.Caption := 'Success Message:';
  lbl.Alignment := taRightJustify;
  edtSuccessMsg := TEdit.Create(Self); edtSuccessMsg.Parent := pnlBody;
  edtSuccessMsg.Left := cx; edtSuccessMsg.Top := y; edtSuccessMsg.Width := cw;
  edtSuccessMsg.Text := '';
  Inc(y, 28);

  lbl := TLabel.Create(Self); lbl.Parent := pnlBody;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw; lbl.Caption := 'Failure Message:';
  lbl.Alignment := taRightJustify;
  edtFailMsg := TEdit.Create(Self); edtFailMsg.Parent := pnlBody;
  edtFailMsg.Left := cx; edtFailMsg.Top := y; edtFailMsg.Width := cw;
  edtFailMsg.Text := '';
  Inc(y, 28);

  lbl := TLabel.Create(Self); lbl.Parent := pnlBody;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw; lbl.Caption := 'Success Node ID:';
  lbl.Alignment := taRightJustify;
  edtSuccessNode := TEdit.Create(Self); edtSuccessNode.Parent := pnlBody;
  edtSuccessNode.Left := cx; edtSuccessNode.Top := y; edtSuccessNode.Width := cw;
  edtSuccessNode.Text := '';
  Inc(y, 28);

  lbl := TLabel.Create(Self); lbl.Parent := pnlBody;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw; lbl.Caption := 'Failure Node ID:';
  lbl.Alignment := taRightJustify;
  edtFailNode := TEdit.Create(Self); edtFailNode.Parent := pnlBody;
  edtFailNode.Left := cx; edtFailNode.Top := y; edtFailNode.Width := cw;
  edtFailNode.Text := '';
  Inc(y, 38);

  pnlSimulate := TPanel.Create(Self); pnlSimulate.Parent := pnlBody;
  pnlSimulate.Left := 6; pnlSimulate.Top := y;
  pnlSimulate.Width := pnlBody.Width - 12; pnlSimulate.Height := 110;
  pnlSimulate.BevelOuter := bvLowered; pnlSimulate.Caption := '';
  pnlSimulate.Anchors := [akLeft, akTop, akRight];

  lblSimTitle := TLabel.Create(Self); lblSimTitle.Parent := pnlSimulate;
  lblSimTitle.Left := 6; lblSimTitle.Top := 4;
  lblSimTitle.Caption := 'SIMULATION — Test skill check outcome';
  lblSimTitle.Font.Style := [fsBold]; lblSimTitle.Font.Size := 8;

  lblSimSkillVal := TLabel.Create(Self); lblSimSkillVal.Parent := pnlSimulate;
  lblSimSkillVal.Left := 6; lblSimSkillVal.Top := 26;
  lblSimSkillVal.Caption := 'Player skill value:'; lblSimSkillVal.Width := 110;

  spnSimSkill := TSpinEdit.Create(Self); spnSimSkill.Parent := pnlSimulate;
  spnSimSkill.Left := 120; spnSimSkill.Top := 22; spnSimSkill.Width := 80;
  spnSimSkill.MinValue := 1; spnSimSkill.MaxValue := 200; spnSimSkill.Value := 40;
  spnSimSkill.OnChange := spnSimSkillChange;

  btnSimulate := TButton.Create(Self); btnSimulate.Parent := pnlSimulate;
  btnSimulate.Caption := 'Roll 10x';
  btnSimulate.Left := 210; btnSimulate.Top := 22;
  btnSimulate.Width := 90; btnSimulate.Height := 26;
  btnSimulate.OnClick := btnSimulateClick;

  memoSimResult := TMemo.Create(Self); memoSimResult.Parent := pnlSimulate;
  memoSimResult.Left := 6; memoSimResult.Top := 54;
  memoSimResult.Width := pnlSimulate.Width - 12; memoSimResult.Height := 48;
  memoSimResult.ReadOnly := True; memoSimResult.ScrollBars := ssHorizontal;
  memoSimResult.Anchors := [akLeft, akTop, akRight];
  memoSimResult.Font.Name := 'Courier New'; memoSimResult.Font.Size := 8;
end;

procedure TSkillCheckEditorForm.StyleForm;
var
  t: TFDCTheme;
  i: Integer;
begin
  t := TThemeManager.Current;
  Color := t.BgDark; Font.Color := t.TextPrimary; Font.Name := t.FontName;
  pnlHeader.Color := t.BgMedium; pnlBottom.Color := t.BgMedium;
  pnlBody.Color := t.BgDark;
  lblTitle.Font.Color := t.AccentPrimary;
  cmbSkill.Color := t.BgLight; cmbSkill.Font.Color := t.TextPrimary;
  edtSuccessMsg.Color := t.BgLight; edtSuccessMsg.Font.Color := t.TextPrimary;
  edtFailMsg.Color := t.BgLight; edtFailMsg.Font.Color := t.TextPrimary;
  edtSuccessNode.Color := t.BgLight; edtSuccessNode.Font.Color := t.TextPrimary;
  edtFailNode.Color := t.BgLight; edtFailNode.Font.Color := t.TextPrimary;
  pnlProbBar.Color := t.BgMedium;
  pnlProbFill.Color := t.ColorSuccess;
  lblDiffVal.Font.Color := t.AccentPrimary;
  lblProbability.Font.Color := t.AccentPrimary;
  pnlSimulate.Color := t.BgMedium;
  lblSimTitle.Font.Color := t.AccentSecondary;
  memoSimResult.Color := t.BgDark; memoSimResult.Font.Color := t.TextPrimary;
for i := 0 to pnlBody.ControlCount - 1 do
     if pnlBody.Controls[i] is TLabel then
       (pnlBody.Controls[i] as TLabel).Font.Color := t.TextSecondary;
   TThemeManager.ApplyToForm(Self);
end;

procedure TSkillCheckEditorForm.PopulateFromSkillCheck;
begin
  cmbSkill.ItemIndex := Ord(FSkillCheck.Skill);
  trkDifficulty.Position := Max(1, Min(100, FSkillCheck.Difficulty));
  spnXP.Value := FSkillCheck.XPReward;
  spnCritBonus.Value := FSkillCheck.CritSuccessBonus;
  edtSuccessMsg.Text := FSkillCheck.SuccessMessage;
  edtFailMsg.Text := FSkillCheck.FailureMessage;
  edtSuccessNode.Text := FSkillCheck.SuccessNodeID;
  edtFailNode.Text := FSkillCheck.FailureNodeID;
  UpdateProbabilityBar;
end;

procedure TSkillCheckEditorForm.SaveToSkillCheck;
begin
  FSkillCheck.Skill := TSkillType(cmbSkill.ItemIndex);
  FSkillCheck.Difficulty := trkDifficulty.Position;
  FSkillCheck.XPReward := spnXP.Value;
  FSkillCheck.CritSuccessBonus := spnCritBonus.Value;
  FSkillCheck.SuccessMessage := edtSuccessMsg.Text;
  FSkillCheck.FailureMessage := edtFailMsg.Text;
  FSkillCheck.SuccessNodeID := edtSuccessNode.Text;
  FSkillCheck.FailureNodeID := edtFailNode.Text;
end;

procedure TSkillCheckEditorForm.UpdateProbabilityBar;
var
  skill, diff, chance: Integer;
begin
  skill := spnSimSkill.Value;
  diff := trkDifficulty.Position;
  chance := Max(5, Min(95, skill - diff + 50));
  lblDiffVal.Caption := IntToStr(diff) + '%';
  lblProbability.Caption := IntToStr(chance) + '%';
  pnlProbFill.Width := Round(pnlProbBar.Width * chance / 100);
  if chance >= 70 then pnlProbFill.Color := TThemeManager.Current.ColorSuccess
  else if chance >= 40 then pnlProbFill.Color := TThemeManager.Current.ColorWarning
  else pnlProbFill.Color := TThemeManager.Current.ColorError;
end;

procedure TSkillCheckEditorForm.trkDifficultyChange(Sender: TObject);
begin UpdateProbabilityBar; end;

procedure TSkillCheckEditorForm.spnSimSkillChange(Sender: TObject);
begin UpdateProbabilityBar; end;

procedure TSkillCheckEditorForm.btnSimulateClick(Sender: TObject);
var
  skill, diff, chance, roll, pass, fail, i: Integer;
  results: string;
begin
  skill := spnSimSkill.Value;
  diff := trkDifficulty.Position;
  chance := Max(5, Min(95, skill - diff + 50));
  pass := 0; fail := 0;
  results := '';
  for i := 1 to 10 do
  begin
    roll := Random(100) + 1;
    if roll <= chance then begin Inc(pass); results := results + 'Y'; end
    else begin Inc(fail); results := results + 'N'; end;
  end;
  memoSimResult.Text := results + '  ->  Pass: ' + IntToStr(pass) + '/10  Fail: ' + IntToStr(fail) + '/10' +
    sLineBreak + 'Chance: ' + IntToStr(chance) + '%  Skill: ' + IntToStr(skill) +
    '  Difficulty: ' + IntToStr(diff);
end;

procedure TSkillCheckEditorForm.btnOKClick(Sender: TObject);
begin SaveToSkillCheck; ModalResult := mrOk; end;

initialization
  RegisterClass(TSkillCheckEditorForm);
  Randomize;
end.