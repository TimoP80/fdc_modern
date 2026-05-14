unit uLocalization;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ExtCtrls, Vcl.Dialogs, Vcl.Graphics,
  uDialogueTypes, uThemeManager, uExportManager;

type
  TLocalizationForm = class(TForm)
  private
    FProject: TDialogueProject;
    pnlTop, pnlBottom: TPanel;
    lblTitle: TLabel;
    lstLocales: TListBox;
    btnAddLocale, btnRemLocale, btnExport, btnImport, btnClose: TButton;
    lvStrings: TListView;
    lblStats: TLabel;
    procedure BuildLayout;
    procedure StyleForm;
    procedure RefreshLocales;
    procedure RefreshStrings;
    procedure btnAddLocaleClick(Sender: TObject);
    procedure btnRemLocaleClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
    procedure lstLocalesClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  public
    class procedure Execute(AOwner: TComponent; aProject: TDialogueProject);
  end;

implementation

class procedure TLocalizationForm.Execute(AOwner: TComponent; aProject: TDialogueProject);
var frm: TLocalizationForm;
begin
  frm := TLocalizationForm.CreateNew(AOwner);
  try frm.FProject := aProject;
  frm.BuildLayout;
  frm.StyleForm;
  frm.RefreshLocales;
  frm.RefreshStrings;
  frm.ShowModal;
  finally frm.Free; end;
end;

procedure TLocalizationForm.FormCreate(Sender: TObject); begin BuildLayout; StyleForm; end;
procedure TLocalizationForm.FormShow(Sender: TObject); begin RefreshLocales; RefreshStrings; end;

procedure TLocalizationForm.BuildLayout;
var
  pnlLocales: TPanel;
  locHdr: TLabel;
  locBtnPanel: TPanel;
  sp: TSplitter;
  pnlStrings: TPanel;
begin
  Width := 780; Height := 520;
  Caption := 'Localization Manager';
  Position := poMainFormCenter;
  OnCreate := FormCreate; OnShow := FormShow;

  pnlTop := TPanel.Create(Self); pnlTop.Parent := Self;
  pnlTop.Align := alTop; pnlTop.Height := 40; pnlTop.BevelOuter := bvNone;
  lblTitle := TLabel.Create(Self); lblTitle.Parent := pnlTop;
  lblTitle.Left := 10; lblTitle.Top := 8;
  lblTitle.Caption := 'LOCALIZATION MANAGER';
  lblTitle.Font.Size := 12; lblTitle.Font.Style := [fsBold];

  pnlBottom := TPanel.Create(Self); pnlBottom.Parent := Self;
  pnlBottom.Align := alBottom; pnlBottom.Height := 42; pnlBottom.BevelOuter := bvNone;

  lblStats := TLabel.Create(Self); lblStats.Parent := pnlBottom;
  lblStats.Left := 6; lblStats.Top := 12; lblStats.Caption := 'Strings: 0'; lblStats.Width := 200;

  btnExport := TButton.Create(Self); btnExport.Parent := pnlBottom;
  btnExport.Caption := '⬆ Export Pack'; btnExport.Left := 220; btnExport.Top := 7;
  btnExport.Width := 110; btnExport.Height := 28; btnExport.OnClick := btnExportClick;

  btnImport := TButton.Create(Self); btnImport.Parent := pnlBottom;
  btnImport.Caption := '⬇ Import Pack'; btnImport.Left := 338; btnImport.Top := 7;
  btnImport.Width := 110; btnImport.Height := 28; btnImport.OnClick := btnImportClick;

  btnClose := TButton.Create(Self); btnClose.Parent := pnlBottom;
  btnClose.Caption := 'Done'; btnClose.ModalResult := mrOk;
  btnClose.Anchors := [akRight, akTop];
  btnClose.Left := pnlBottom.Width - 96; btnClose.Top := 7;
  btnClose.Width := 90; btnClose.Height := 28;

  pnlLocales := TPanel.Create(Self); pnlLocales.Parent := Self;
  pnlLocales.Align := alLeft; pnlLocales.Width := 180; pnlLocales.BevelOuter := bvNone;

  locHdr := TLabel.Create(Self); locHdr.Parent := pnlLocales;
  locHdr.Left := 4; locHdr.Top := 4; locHdr.Caption := 'LOCALES'; locHdr.Font.Style := [fsBold];

  lstLocales := TListBox.Create(Self); lstLocales.Parent := pnlLocales;
  lstLocales.Left := 0; lstLocales.Top := 24; lstLocales.Width := 180;
  lstLocales.Height := pnlLocales.Height - 70;
  lstLocales.Anchors := [akLeft, akTop, akRight, akBottom];
  lstLocales.OnClick := lstLocalesClick;

  locBtnPanel := TPanel.Create(Self); locBtnPanel.Parent := pnlLocales;
  locBtnPanel.Align := alBottom; locBtnPanel.Height := 36; locBtnPanel.BevelOuter := bvNone;

  btnAddLocale := TButton.Create(Self); btnAddLocale.Parent := locBtnPanel;
  btnAddLocale.Caption := '+'; btnAddLocale.Left := 4; btnAddLocale.Top := 4;
  btnAddLocale.Width := 40; btnAddLocale.Height := 26; btnAddLocale.OnClick := btnAddLocaleClick;

  btnRemLocale := TButton.Create(Self); btnRemLocale.Parent := locBtnPanel;
  btnRemLocale.Caption := '−'; btnRemLocale.Left := 48; btnRemLocale.Top := 4;
  btnRemLocale.Width := 40; btnRemLocale.Height := 26; btnRemLocale.OnClick := btnRemLocaleClick;

  sp := TSplitter.Create(Self); sp.Parent := Self;
  sp.Align := alLeft; sp.Width := 4;

  pnlStrings := TPanel.Create(Self); pnlStrings.Parent := Self;
  pnlStrings.Align := alClient; pnlStrings.BevelOuter := bvNone;

  lvStrings := TListView.Create(Self); lvStrings.Parent := pnlStrings;
  lvStrings.Align := alClient; lvStrings.ViewStyle := vsReport;
  lvStrings.RowSelect := True; lvStrings.GridLines := True;
  with lvStrings.Columns.Add do begin Caption := 'Key'; Width := 180; end;
  with lvStrings.Columns.Add do begin Caption := 'Source (en-US)'; Width := 260; end;
  with lvStrings.Columns.Add do begin Caption := 'Translation'; Width := 260; end;
  with lvStrings.Columns.Add do begin Caption := 'Status'; Width := 80; end;
end;

procedure TLocalizationForm.StyleForm;
var t: TFDCTheme;
begin
  t := TThemeManager.Current;
  Color := t.BgDark; Font.Color := t.TextPrimary;
  pnlTop.Color := t.BgMedium; pnlBottom.Color := t.BgMedium;
  lblTitle.Font.Color := t.AccentPrimary;
  lstLocales.Color := t.BgDark; lstLocales.Font.Color := t.TextPrimary;
  lvStrings.Color := t.BgDark; lvStrings.Font.Color := t.TextPrimary;
  lblStats.Font.Color := t.TextSecondary;
   TThemeManager.ApplyToForm(Self);
end;

procedure TLocalizationForm.RefreshLocales;
var
  locale: string;
begin
  lstLocales.Items.Clear;
  if not Assigned(FProject) then Exit;
  for locale in FProject.Locales do lstLocales.Items.Add(locale);
  if lstLocales.Items.Count > 0 then lstLocales.ItemIndex := 0;
end;

procedure TLocalizationForm.RefreshStrings;
var
  node: TDialogueNode;
  item: TListItem;
  count: Integer;
  i: Integer;
begin
  lvStrings.Items.Clear;
  if not Assigned(FProject) then Exit;
  count := 0;
  for node in FProject.Nodes do
  begin
    if (node.NodeType = ntComment) or (Trim(node.Text) = '') then Continue;
    item := lvStrings.Items.Add;
    item.Caption := 'node_' + Copy(node.ID, 1, 10) + '_text';
    item.SubItems.Add(Copy(node.Text, 1, 80));
    item.SubItems.Add(Copy(node.Text, 1, 80));  // Placeholder translation
    item.SubItems.Add('Untranslated');
    Inc(count);
    for i := 0 to node.PlayerOptions.Count - 1 do
    begin
      if Trim(node.PlayerOptions[i].Text) = '' then Continue;
      item := lvStrings.Items.Add;
      item.Caption := 'node_' + Copy(node.ID, 1, 10) + '_opt' + IntToStr(i);
      item.SubItems.Add(Copy(node.PlayerOptions[i].Text, 1, 80));
      item.SubItems.Add(Copy(node.PlayerOptions[i].Text, 1, 80));
      item.SubItems.Add('Untranslated');
      Inc(count);
    end;
  end;
  lblStats.Caption := 'Total strings: ' + IntToStr(count);
end;

procedure TLocalizationForm.lstLocalesClick(Sender: TObject);
begin
  if lstLocales.ItemIndex >= 0 then
    FProject.ActiveLocale := lstLocales.Items[lstLocales.ItemIndex];
  RefreshStrings;
end;

procedure TLocalizationForm.btnAddLocaleClick(Sender: TObject);
var locale: string;
begin
  locale := InputBox('Add Locale', 'Locale code (e.g. de-DE, fr-FR, ru-RU):', '');
  if Trim(locale) = '' then Exit;
  if FProject.Locales.IndexOf(locale) < 0 then
  begin
    FProject.Locales.Add(locale);
    FProject.Modified := True;
    RefreshLocales;
  end;
end;

procedure TLocalizationForm.btnRemLocaleClick(Sender: TObject);
begin
  if lstLocales.ItemIndex <= 0 then begin ShowMessage('Cannot remove default locale.'); Exit; end;
  FProject.Locales.Delete(lstLocales.ItemIndex);
  FProject.Modified := True;
  RefreshLocales;
end;

procedure TLocalizationForm.btnExportClick(Sender: TObject);
var
  dlg: TSaveDialog;
  opts: TExportOptions;
  mgr: TExportManager;
  res: TExportResult;
begin
  dlg := TSaveDialog.Create(nil);
  try
    dlg.Filter := 'Localization JSON|*.json|All Files|*.*';
    dlg.Title := 'Export Localization Pack';
    dlg.FileName := FProject.NPCName + '_' + FProject.ActiveLocale;
    if not dlg.Execute then Exit;
    opts := TExportManager.DefaultOptions;
    opts.Format := efLocalization;
    opts.OutputPath := dlg.FileName;
    opts.LocaleFilter := FProject.ActiveLocale;
    mgr := TExportManager.Create(FProject);
    try
      res := mgr.Export(opts);
      if res.Success then
        ShowMessage('Exported ' + IntToStr(Length(res.FilesGenerated)) + ' file(s) successfully.')
      else
        ShowMessage('Export failed: ' + string.Join(sLineBreak, res.Errors));
    finally mgr.Free; end;
  finally dlg.Free; end;
end;

procedure TLocalizationForm.btnImportClick(Sender: TObject);
var
  dlg: TOpenDialog;
  sl: TStringList;
  jsonObj: TJSONObject;
begin
  dlg := TOpenDialog.Create(nil);
  try
    dlg.Filter := 'Localization JSON|*.json|All Files|*.*';
    dlg.Title := 'Import Localization Pack';
    if not dlg.Execute then Exit;
    sl := TStringList.Create;
    try
      sl.LoadFromFile(dlg.FileName, TEncoding.UTF8);
      jsonObj := TJSONObject.ParseJSONValue(sl.Text) as TJSONObject;
      if Assigned(jsonObj) then
      try
        ShowMessage('Localization file loaded successfully.' + sLineBreak +
          'Found ' + IntToStr((jsonObj.GetValue('count') as TJSONNumber).AsInt) + ' strings.');
      finally jsonObj.Free; end;
    finally sl.Free; end;
  finally dlg.Free; end;
end;

initialization
  RegisterClass(TLocalizationForm);
end.