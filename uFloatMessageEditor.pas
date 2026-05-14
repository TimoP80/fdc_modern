unit uFloatMessageEditor;

// uFloatMessageEditor - Float message editor form

interface

uses
  System.SysUtils, System.Classes, System.Math, System.StrUtils, System.TypInfo,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.Buttons, Vcl.Dialogs, Vcl.Samples.Spin, Vcl.Graphics,
  uDialogueTypes, uThemeManager;

type
  TFloatMessageForm = class(TForm)
  private
    FProject: TDialogueProject;
    FLblText: TLabel;
    FLblCategory: TLabel;
    FLblPriority: TLabel;
    FLblWeight: TLabel;
    FLblDuration: TLabel;
    FLblCondition: TLabel;
    FLblLocaleKey: TLabel;

    pnlTop: TPanel;
    lblTitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    btnAddMsg: TButton;
    btnDelMsg: TButton;
    btnDuplMsg: TButton;
    splitter: TSplitter;
    pnlList: TPanel;
    pnlDetail: TPanel;
    lblListHdr: TLabel;
    lstMessages: TListBox;
    lblCategoryFilter: TLabel;
    cmbCategoryFilter: TComboBox;
    btnNewCat: TButton;

    // Detail panel controls
    memoText: TMemo;
    cmbCategory: TComboBox;
    spnPriority: TSpinEdit;
    spnWeight: TSpinEdit;
    edtDuration: TEdit;
    edtCondition: TEdit;
    edtLocaleKey: TEdit;
    grpFlags: TGroupBox;
    chkAmbient: TCheckBox;
    chkCombat: TCheckBox;
    chkContextSensitive: TCheckBox;
    lblPreview: TLabel;
    pnlPreview: TPanel;
    lblPreviewText: TLabel;

    FCurrentMsg: TFloatMessage;

    procedure BuildLayout;
    procedure StyleForm;
    procedure RefreshList;
    procedure RefreshCategoryFilter;
    procedure LoadMessage(msg: TFloatMessage);
    procedure SaveCurrentMessage;
    procedure UpdatePreview;
    procedure lstMessagesClick(Sender: TObject);
    procedure cmbCategoryFilterChange(Sender: TObject);
    procedure btnAddMsgClick(Sender: TObject);
    procedure btnDelMsgClick(Sender: TObject);
    procedure btnDuplMsgClick(Sender: TObject);
    procedure btnNewCatClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure memoTextChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  public
    class procedure Execute(AOwner: TComponent; aProject: TDialogueProject);
  end;

implementation

type
  TControlHack = class(TControl) end;

{ TFloatMessageForm }

class procedure TFloatMessageForm.Execute(AOwner: TComponent; aProject: TDialogueProject);
var
  frm: TFloatMessageForm;
begin
  frm := TFloatMessageForm.CreateNew(AOwner);
  try
    frm.FProject := aProject;
    frm.BuildLayout;
    frm.StyleForm;
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;

procedure TFloatMessageForm.FormCreate(Sender: TObject);
begin
  BuildLayout;
  StyleForm;
end;

procedure TFloatMessageForm.FormShow(Sender: TObject);
begin
  RefreshCategoryFilter;
  RefreshList;
end;

procedure TFloatMessageForm.BuildLayout;
var
  y, lw, cx, cw: Integer;
  lbl: TLabel;
  wlbl: TLabel;
begin
  Width := 860;
  Height := 580;
  Caption := 'Float Message Editor';
  Position := poMainFormCenter;
  OnCreate := FormCreate;
  OnShow := FormShow;

  // Top header
  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := 40;
  pnlTop.BevelOuter := bvNone;

  lblTitle := TLabel.Create(Self);
  lblTitle.Parent := pnlTop;
  lblTitle.Left := 10; lblTitle.Top := 8;
  lblTitle.Caption := 'FLOAT MESSAGE EDITOR';
  lblTitle.Font.Size := 13;
  lblTitle.Font.Style := [fsBold];

  // Bottom controls
  pnlBottom := TPanel.Create(Self);
  pnlBottom.Parent := Self;
  pnlBottom.Align := alBottom;
  pnlBottom.Height := 42;
  pnlBottom.BevelOuter := bvNone;

  btnAddMsg := TButton.Create(Self);
  btnAddMsg.Parent := pnlBottom;
  btnAddMsg.Caption := '+ Add Message';
  btnAddMsg.Left := 6; btnAddMsg.Top := 7;
  btnAddMsg.Width := 110; btnAddMsg.Height := 28;
  btnAddMsg.OnClick := btnAddMsgClick;

  btnDelMsg := TButton.Create(Self);
  btnDelMsg.Parent := pnlBottom;
  btnDelMsg.Caption := 'Delete';
  btnDelMsg.Left := 122; btnDelMsg.Top := 7;
  btnDelMsg.Width := 80; btnDelMsg.Height := 28;
  btnDelMsg.OnClick := btnDelMsgClick;

  btnDuplMsg := TButton.Create(Self);
  btnDuplMsg.Parent := pnlBottom;
  btnDuplMsg.Caption := 'Duplicate';
  btnDuplMsg.Left := 208; btnDuplMsg.Top := 7;
  btnDuplMsg.Width := 80; btnDuplMsg.Height := 28;
  btnDuplMsg.OnClick := btnDuplMsgClick;

  btnClose := TButton.Create(Self);
  btnClose.Parent := pnlBottom;
  btnClose.Caption := 'Done';
  btnClose.ModalResult := mrOk;
  btnClose.Anchors := [akRight, akTop];
  btnClose.Left := pnlBottom.Width - 96;
  btnClose.Top := 7; btnClose.Width := 90; btnClose.Height := 28;
  btnClose.OnClick := btnCloseClick;

  // List panel (left)
  pnlList := TPanel.Create(Self);
  pnlList.Parent := Self;
  pnlList.Align := alLeft;
  pnlList.Width := 280;
  pnlList.BevelOuter := bvNone;

  lblListHdr := TLabel.Create(Self);
  lblListHdr.Parent := pnlList;
  lblListHdr.Left := 6; lblListHdr.Top := 4;
  lblListHdr.Caption := 'MESSAGES';
  lblListHdr.Font.Style := [fsBold];
  lblListHdr.Font.Size := 8;

  var filterPanel := TPanel.Create(Self);
  filterPanel.Parent := pnlList;
  filterPanel.Left := 0; filterPanel.Top := 22;
  filterPanel.Width := pnlList.Width;
  filterPanel.Height := 30;
  filterPanel.BevelOuter := bvNone;
  filterPanel.Anchors := [akLeft, akTop, akRight];

  lblCategoryFilter := TLabel.Create(Self);
  lblCategoryFilter.Parent := filterPanel;
  lblCategoryFilter.Left := 4; lblCategoryFilter.Top := 7;
  lblCategoryFilter.Caption := 'Filter:';

  cmbCategoryFilter := TComboBox.Create(Self);
  cmbCategoryFilter.Parent := filterPanel;
  cmbCategoryFilter.Left := 44; cmbCategoryFilter.Top := 4;
  cmbCategoryFilter.Width := 180; cmbCategoryFilter.Height := 22;
  cmbCategoryFilter.Style := csDropDownList;
  cmbCategoryFilter.OnChange := cmbCategoryFilterChange;

  btnNewCat := TButton.Create(Self);
  btnNewCat.Parent := filterPanel;
  btnNewCat.Caption := '+Cat';
  btnNewCat.Left := 228; btnNewCat.Top := 3;
  btnNewCat.Width := 44; btnNewCat.Height := 24;
  btnNewCat.OnClick := btnNewCatClick;

  lstMessages := TListBox.Create(Self);
  lstMessages.Parent := pnlList;
  lstMessages.Left := 0; lstMessages.Top := 52;
  lstMessages.Width := pnlList.Width;
  lstMessages.Height := pnlList.Height - 52;
  lstMessages.Anchors := [akLeft, akTop, akRight, akBottom];
  lstMessages.OnClick := lstMessagesClick;

  splitter := TSplitter.Create(Self);
  splitter.Parent := Self;
  splitter.Align := alLeft;
  splitter.Width := 4;

  // Detail panel (right)
  pnlDetail := TPanel.Create(Self);
  pnlDetail.Parent := Self;
  pnlDetail.Align := alClient;
  pnlDetail.BevelOuter := bvNone;

  y := 10;
  lw := 100;
  cx := 116;
  cw := 300;

  // AddLbl helper
  lbl := TLabel.Create(Self); lbl.Parent := pnlDetail;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw;
  lbl.Caption := 'Text:'; lbl.Alignment := taRightJustify;
  FLblText := lbl;

  memoText := TMemo.Create(Self);
  memoText.Parent := pnlDetail;
  memoText.Left := cx; memoText.Top := y;
  memoText.Width := cw; memoText.Height := 70;
  memoText.WordWrap := True; memoText.ScrollBars := ssVertical;
  memoText.OnChange := memoTextChange;
  Inc(y, 78);

  lbl := TLabel.Create(Self); lbl.Parent := pnlDetail;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw;
  lbl.Caption := 'Category:'; lbl.Alignment := taRightJustify;
  FLblCategory := lbl;

  cmbCategory := TComboBox.Create(Self);
  cmbCategory.Parent := pnlDetail;
  cmbCategory.Left := cx; cmbCategory.Top := y; cmbCategory.Width := 180;
  cmbCategory.Items.AddStrings(['Ambient', 'Combat Taunt', 'Greeting', 'Random', 'Context', 'Trade']);
  Inc(y, 28);

  lbl := TLabel.Create(Self); lbl.Parent := pnlDetail;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw;
  lbl.Caption := 'Priority:'; lbl.Alignment := taRightJustify;
  FLblPriority := lbl;

  spnPriority := TSpinEdit.Create(Self);
  spnPriority.Parent := pnlDetail;
  spnPriority.Left := cx; spnPriority.Top := y;
  spnPriority.Width := 80; spnPriority.MinValue := 1; spnPriority.MaxValue := 10;
  spnPriority.Value := 5;

  lbl := TLabel.Create(Self); lbl.Parent := pnlDetail;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw;
  lbl.Caption := 'Weight:'; lbl.Alignment := taRightJustify;
  FLblWeight := lbl;

  wlbl := TLabel.Create(Self); wlbl.Parent := pnlDetail;
  wlbl.Left := cx + 90; wlbl.Top := y + 3; wlbl.Width := 80;
  wlbl.Caption := 'Weight'; wlbl.Alignment := taRightJustify;

  spnWeight := TSpinEdit.Create(Self);
  spnWeight.Parent := pnlDetail;
  spnWeight.Left := cx + 90 + wlbl.Width + 4; spnWeight.Top := y;
  spnWeight.Width := 80; spnWeight.MinValue := 1; spnWeight.MaxValue := 100;
  spnWeight.Value := 1;
  Inc(y, 28);

  lbl := TLabel.Create(Self); lbl.Parent := pnlDetail;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw;
  lbl.Caption := 'Duration:'; lbl.Alignment := taRightJustify;
  FLblDuration := lbl;

  edtDuration := TEdit.Create(Self);
  edtDuration.Parent := pnlDetail;
  edtDuration.Left := cx; edtDuration.Top := y; edtDuration.Width := 80;
  edtDuration.Text := '3.0';
  Inc(y, 28);

  lbl := TLabel.Create(Self); lbl.Parent := pnlDetail;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw;
  lbl.Caption := 'Condition:'; lbl.Alignment := taRightJustify;
  FLblCondition := lbl;

  edtCondition := TEdit.Create(Self);
  edtCondition.Parent := pnlDetail;
  edtCondition.Left := cx; edtCondition.Top := y; edtCondition.Width := cw;
  edtCondition.Text := '';
  Inc(y, 28);

  lbl := TLabel.Create(Self); lbl.Parent := pnlDetail;
  lbl.Left := 6; lbl.Top := y + 3; lbl.Width := lw;
  lbl.Caption := 'Locale Key:'; lbl.Alignment := taRightJustify;
  FLblLocaleKey := lbl;

  edtLocaleKey := TEdit.Create(Self);
  edtLocaleKey.Parent := pnlDetail;
  edtLocaleKey.Left := cx; edtLocaleKey.Top := y; edtLocaleKey.Width := cw;
  edtLocaleKey.Text := '';
  Inc(y, 36);

  // Flags group
  grpFlags := TGroupBox.Create(Self);
  grpFlags.Parent := pnlDetail;
  grpFlags.Left := cx; grpFlags.Top := y;
  grpFlags.Width := cw; grpFlags.Height := 80;
  grpFlags.Caption := 'Message Type Flags';

  chkAmbient := TCheckBox.Create(Self);
  chkAmbient.Parent := grpFlags;
  chkAmbient.Left := 8; chkAmbient.Top := 18;
  chkAmbient.Caption := 'Ambient / Idle bark';
  chkAmbient.Width := 160; chkAmbient.Checked := True;

  chkCombat := TCheckBox.Create(Self);
  chkCombat.Parent := grpFlags;
  chkCombat.Left := 8; chkCombat.Top := 38;
  chkCombat.Caption := 'Combat taunt';
  chkCombat.Width := 160;

  chkContextSensitive := TCheckBox.Create(Self);
  chkContextSensitive.Parent := grpFlags;
  chkContextSensitive.Left := 8; chkContextSensitive.Top := 58;
  chkContextSensitive.Caption := 'Context-sensitive (condition driven)';
  chkContextSensitive.Width := 240;

  Inc(y, 92);

  // Preview
  lblPreview := TLabel.Create(Self);
  lblPreview.Parent := pnlDetail;
  lblPreview.Left := 6; lblPreview.Top := y;
  lblPreview.Caption := 'PREVIEW:';
  lblPreview.Font.Style := [fsBold]; lblPreview.Font.Size := 8;
  Inc(y, 18);

  pnlPreview := TPanel.Create(Self);
  pnlPreview.Parent := pnlDetail;
  pnlPreview.Left := cx; pnlPreview.Top := y;
  pnlPreview.Width := cw; pnlPreview.Height := 42;
  pnlPreview.BevelOuter := bvLowered;
  pnlPreview.BevelInner := bvNone;

  lblPreviewText := TLabel.Create(Self);
  lblPreviewText.Parent := pnlPreview;
  lblPreviewText.Align := alClient;
  lblPreviewText.Alignment := taCenter;
  lblPreviewText.Layout := tlCenter;
  lblPreviewText.WordWrap := True;
  lblPreviewText.Caption := '(no text)';
  lblPreviewText.Font.Size := 11;
end;

procedure TFloatMessageForm.StyleForm;
var
  t: TFDCTheme;
  i: Integer;
begin
  t := TThemeManager.Current;
  TControlHack(Self).Color := t.BgDark;
  Font.Color := t.TextPrimary;
  Font.Name := t.FontName;

  pnlTop.Color := t.BgMedium;
  lblTitle.Font.Color := t.AccentPrimary;
  pnlBottom.Color := t.BgMedium;
  pnlList.Color := t.BgMedium;
  pnlDetail.Color := t.BgDark;

  lstMessages.Color := t.BgDark;
  lstMessages.Font.Color := t.TextPrimary;

  memoText.Color := t.BgLight;
  memoText.Font.Color := t.TextPrimary;

  cmbCategory.Color := t.BgLight;
  cmbCategoryFilter.Color := t.BgLight;

  edtCondition.Color := t.BgLight;
  edtCondition.Font.Color := t.TextPrimary;
  edtDuration.Color := t.BgLight;
  edtLocaleKey.Color := t.BgLight;

  grpFlags.Color := t.BgDark;
  grpFlags.Font.Color := t.AccentSecondary;
  chkAmbient.Color := t.BgDark; chkAmbient.Font.Color := t.TextPrimary;
  chkCombat.Color := t.BgDark; chkCombat.Font.Color := t.TextPrimary;
  chkContextSensitive.Color := t.BgDark; chkContextSensitive.Font.Color := t.TextPrimary;

  pnlPreview.Color := t.BgLight;
  lblPreviewText.Color := t.BgLight;
  lblPreviewText.Font.Color := t.AccentPrimary;
  lblPreviewText.Font.Name := t.MonoFontName;

  lblPreview.Font.Color := t.AccentSecondary;
  lblListHdr.Font.Color := t.AccentSecondary;

for i := 0 to pnlDetail.ControlCount - 1 do
     if pnlDetail.Controls[i] is TLabel then
       (pnlDetail.Controls[i] as TLabel).Font.Color := t.TextSecondary;
   TThemeManager.ApplyToForm(Self);
end;

procedure TFloatMessageForm.RefreshCategoryFilter;
var
  msg: TFloatMessage;
  cats: TStringList;
begin
  cats := TStringList.Create;
  try
    cats.Duplicates := dupIgnore;
    cats.Sorted := True;
    cats.Add('(All)');
    if Assigned(FProject) then
      for msg in FProject.FloatMessages do
        if msg.Category <> '' then cats.Add(msg.Category);
    cmbCategoryFilter.Items.Assign(cats);
    if cmbCategoryFilter.Items.Count > 0 then
      cmbCategoryFilter.ItemIndex := 0;

    cmbCategory.Items.Clear;
    for var i := 1 to cats.Count - 1 do
      cmbCategory.Items.Add(cats[i]);
    if not cmbCategory.Items.Contains('Ambient') then cmbCategory.Items.Add('Ambient');
    if not cmbCategory.Items.Contains('Combat Taunt') then cmbCategory.Items.Add('Combat Taunt');
    if not cmbCategory.Items.Contains('Greeting') then cmbCategory.Items.Add('Greeting');
    if not cmbCategory.Items.Contains('Random') then cmbCategory.Items.Add('Random');
  finally
    cats.Free;
  end;
end;

procedure TFloatMessageForm.RefreshList;
var
  msg: TFloatMessage;
  filter: string;
  display: string;
begin
  lstMessages.Items.Clear;
  if not Assigned(FProject) then Exit;

  filter := '';
  if cmbCategoryFilter.ItemIndex > 0 then
    filter := cmbCategoryFilter.Items[cmbCategoryFilter.ItemIndex];

  for msg in FProject.FloatMessages do
  begin
    if (filter <> '') and (msg.Category <> filter) then Continue;

    display := '[' + IfThen(msg.Category <> '', msg.Category, 'No Cat') + ']';
    display := display + ' P:' + IntToStr(msg.Priority);
    display := display + ' W:' + IntToStr(msg.Weight);
    display := display + '  ';
    if Trim(msg.Text) <> '' then
      display := display + Copy(msg.Text, 1, 50)
    else
      display := display + '(empty)';

    lstMessages.Items.AddObject(display, msg);
  end;

  if lstMessages.Items.Count > 0 then
  begin
    lstMessages.ItemIndex := 0;
    lstMessagesClick(nil);
  end else
    FCurrentMsg := nil;
end;

procedure TFloatMessageForm.LoadMessage(msg: TFloatMessage);
var
  catIdx: Integer;
begin
  FCurrentMsg := msg;
  memoText.Text := msg.Text;
  catIdx := cmbCategory.Items.IndexOf(msg.Category);
  if catIdx >= 0 then cmbCategory.ItemIndex := catIdx
  else cmbCategory.Text := msg.Category;
  spnPriority.Value := msg.Priority;
  spnWeight.Value := msg.Weight;
  edtDuration.Text := Format('%.1f', [msg.TimedDuration]);
  edtCondition.Text := msg.Condition;
  edtLocaleKey.Text := msg.LocaleKey;
  chkAmbient.Checked := msg.IsAmbient;
  chkCombat.Checked := msg.IsCombatTaunt;
  chkContextSensitive.Checked := msg.IsContextSensitive;
  UpdatePreview;
end;

procedure TFloatMessageForm.SaveCurrentMessage;
begin
  if not Assigned(FCurrentMsg) then Exit;
  FCurrentMsg.Text := memoText.Text;
  FCurrentMsg.Category := cmbCategory.Text;
  FCurrentMsg.Priority := spnPriority.Value;
  FCurrentMsg.Weight := spnWeight.Value;
  FCurrentMsg.TimedDuration := StrToFloatDef(edtDuration.Text, 3.0);
  FCurrentMsg.Condition := edtCondition.Text;
  FCurrentMsg.LocaleKey := edtLocaleKey.Text;
  FCurrentMsg.IsAmbient := chkAmbient.Checked;
  FCurrentMsg.IsCombatTaunt := chkCombat.Checked;
  FCurrentMsg.IsContextSensitive := chkContextSensitive.Checked;
  if Assigned(FProject) then FProject.Modified := True;
end;

procedure TFloatMessageForm.UpdatePreview;
begin
  if Assigned(FCurrentMsg) then
    lblPreviewText.Caption := '"' + memoText.Text + '"'
  else
    lblPreviewText.Caption := '(no message selected)';
end;

procedure TFloatMessageForm.lstMessagesClick(Sender: TObject);
var
  msg: TFloatMessage;
begin
  if lstMessages.ItemIndex < 0 then Exit;
  SaveCurrentMessage;
  msg := TFloatMessage(lstMessages.Items.Objects[lstMessages.ItemIndex]);
  if Assigned(msg) then
    LoadMessage(msg);
end;

procedure TFloatMessageForm.cmbCategoryFilterChange(Sender: TObject);
begin
  SaveCurrentMessage;
  RefreshList;
end;

procedure TFloatMessageForm.btnAddMsgClick(Sender: TObject);
var
  msg: TFloatMessage;
  hadCurrent: Boolean;
  newText: string;
begin
  if not Assigned(FProject) then Exit;
  hadCurrent := Assigned(FCurrentMsg);
  newText := '';
  if not hadCurrent then
    newText := Trim(memoText.Text);
  SaveCurrentMessage;
  msg := TFloatMessage.Create;
  msg.Text := newText;
  msg.Category := IfThen(cmbCategoryFilter.ItemIndex > 0,
    cmbCategoryFilter.Items[cmbCategoryFilter.ItemIndex], 'Ambient');
  msg.Priority := 5;
  msg.Weight := 1;
  msg.IsAmbient := True;
  FProject.FloatMessages.Add(msg);
  FProject.Modified := True;
  RefreshList;
  for var i := 0 to lstMessages.Items.Count - 1 do
    if lstMessages.Items.Objects[i] = msg then
    begin
      lstMessages.ItemIndex := i;
      LoadMessage(msg);
      Break;
    end;
end;
end;

procedure TFloatMessageForm.btnDelMsgClick(Sender: TObject);
var
  msg: TFloatMessage;
  idx: Integer;
begin
  if not Assigned(FProject) or (lstMessages.ItemIndex < 0) then Exit;
  idx := lstMessages.ItemIndex;
  msg := TFloatMessage(lstMessages.Items.Objects[idx]);
  if Assigned(msg) then
  begin
    FProject.FloatMessages.Remove(msg);
    FProject.Modified := True;
    FCurrentMsg := nil;
    RefreshList;
    memoText.Clear;
  end;
end;

procedure TFloatMessageForm.btnDuplMsgClick(Sender: TObject);
var
  src, newMsg: TFloatMessage;
begin
  if not Assigned(FProject) or (lstMessages.ItemIndex < 0) then Exit;
  src := TFloatMessage(lstMessages.Items.Objects[lstMessages.ItemIndex]);
  if not Assigned(src) then Exit;
  SaveCurrentMessage;
  newMsg := TFloatMessage.Create;
  newMsg.Text := src.Text + ' (copy)';
  newMsg.Category := src.Category;
  newMsg.Priority := src.Priority;
  newMsg.Weight := src.Weight;
  newMsg.TimedDuration := src.TimedDuration;
  newMsg.Condition := src.Condition;
  newMsg.IsAmbient := src.IsAmbient;
  newMsg.IsCombatTaunt := src.IsCombatTaunt;
  newMsg.IsContextSensitive := src.IsContextSensitive;
  FProject.FloatMessages.Add(newMsg);
  FProject.Modified := True;
  RefreshList;
end;

procedure TFloatMessageForm.btnNewCatClick(Sender: TObject);
var
  catName: string;
begin
  catName := InputBox('New Category', 'Category name:', '');
  if Trim(catName) = '' then Exit;
  if cmbCategory.Items.IndexOf(catName) < 0 then
  begin
    cmbCategory.Items.Add(catName);
    cmbCategoryFilter.Items.Add(catName);
  end;
  cmbCategory.Text := catName;
end;

procedure TFloatMessageForm.btnCloseClick(Sender: TObject);
begin
  SaveCurrentMessage;
  Close;
end;

procedure TFloatMessageForm.memoTextChange(Sender: TObject);
begin
  UpdatePreview;
end;

initialization
  System.Classes.RegisterClass(TFloatMessageForm);

end.