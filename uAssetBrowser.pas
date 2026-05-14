unit uAssetBrowser;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ExtCtrls, Vcl.Dialogs, Vcl.Graphics, Vcl.Imaging.PNGImage,
  uThemeManager;

type
  TAssetBrowserForm = class(TForm)
  private
    pnlTop, pnlBottom: TPanel;
    lblTitle, lblPath: TLabel;
    tvAssets: TTreeView;
    imgPreview: TImage;
    btnBrowseFolder: TButton;
    btnClose: TButton;
    btnSelect: TButton;
    cmbFilter: TComboBox;
    splitter: TSplitter;
    pnlPreview: TPanel;
    pnlList: TPanel;
    FSelectedFile: string;
    FRootPath: string;
    procedure BuildLayout;
    procedure StyleForm;
    procedure PopulateTree(const path: string);
    procedure AddSubDir(parent: TTreeNode; const dirPath: string);
    procedure tvAssetsClick(Sender: TObject);
    procedure btnBrowseFolderClick(Sender: TObject);
    procedure btnSelectClick(Sender: TObject);
    procedure cmbFilterChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  public
    class function Execute(AOwner: TComponent; const rootPath: string;
      out selectedFile: string): Boolean;
    property SelectedFile: string read FSelectedFile;
  end;

implementation

class function TAssetBrowserForm.Execute(AOwner: TComponent; const rootPath: string;
   out selectedFile: string): Boolean;
var frm: TAssetBrowserForm;
begin
   frm := TAssetBrowserForm.CreateNew(AOwner);
   try
     frm.FRootPath := rootPath;
     frm.BuildLayout;
     frm.StyleForm;
     if rootPath <> '' then frm.PopulateTree(rootPath);
     Result := frm.ShowModal = mrOk;
     selectedFile := frm.FSelectedFile;
   finally frm.Free; end;
end;

procedure TAssetBrowserForm.FormCreate(Sender: TObject); begin BuildLayout; StyleForm; end;

procedure TAssetBrowserForm.BuildLayout;
var
  filterLbl: TLabel;
begin
  Width := 640; Height := 500;
  Caption := 'Asset Browser';
  Position := poMainFormCenter;
  OnCreate := FormCreate;

  pnlTop := TPanel.Create(Self); pnlTop.Parent := Self;
  pnlTop.Align := alTop; pnlTop.Height := 72; pnlTop.BevelOuter := bvNone;

  lblTitle := TLabel.Create(Self); lblTitle.Parent := pnlTop;
  lblTitle.Left := 10; lblTitle.Top := 6;
  lblTitle.Caption := 'ASSET BROWSER';
  lblTitle.Font.Size := 12; lblTitle.Font.Style := [fsBold];

  filterLbl := TLabel.Create(Self); filterLbl.Parent := pnlTop;
  filterLbl.Left := 10; filterLbl.Top := 32; filterLbl.Caption := 'Filter:'; filterLbl.Width := 40;

  cmbFilter := TComboBox.Create(Self); cmbFilter.Parent := pnlTop;
  cmbFilter.Left := 52; cmbFilter.Top := 28; cmbFilter.Width := 180;
  cmbFilter.Style := csDropDownList;
  cmbFilter.Items.AddStrings(['All Assets', 'Images (*.png;*.jpg;*.bmp)', 'Audio (*.wav;*.ogg;*.mp3)', 'Scripts (*.ssl)']);
  cmbFilter.ItemIndex := 0; cmbFilter.OnChange := cmbFilterChange;

  btnBrowseFolder := TButton.Create(Self); btnBrowseFolder.Parent := pnlTop;
  btnBrowseFolder.Caption := '📁 Browse Folder...';
  btnBrowseFolder.Left := 244; btnBrowseFolder.Top := 28;
  btnBrowseFolder.Width := 130; btnBrowseFolder.Height := 28;
  btnBrowseFolder.OnClick := btnBrowseFolderClick;

  lblPath := TLabel.Create(Self); lblPath.Parent := pnlTop;
  lblPath.Left := 10; lblPath.Top := 52; lblPath.Caption := 'No folder selected';
  lblPath.Width := 600; lblPath.Font.Size := 7;

  pnlBottom := TPanel.Create(Self); pnlBottom.Parent := Self;
  pnlBottom.Align := alBottom; pnlBottom.Height := 42; pnlBottom.BevelOuter := bvNone;

  btnSelect := TButton.Create(Self); btnSelect.Parent := pnlBottom;
  btnSelect.Caption := 'Select'; btnSelect.Left := pnlBottom.Width - 196; btnSelect.Top := 7;
  btnSelect.Width := 88; btnSelect.Height := 28; btnSelect.Anchors := [akRight, akTop];
  btnSelect.OnClick := btnSelectClick;

  btnClose := TButton.Create(Self); btnClose.Parent := pnlBottom;
  btnClose.Caption := 'Cancel'; btnClose.ModalResult := mrCancel;
  btnClose.Left := pnlBottom.Width - 100; btnClose.Top := 7;
  btnClose.Width := 88; btnClose.Height := 28; btnClose.Anchors := [akRight, akTop];

  pnlList := TPanel.Create(Self); pnlList.Parent := Self;
  pnlList.Align := alLeft; pnlList.Width := 280; pnlList.BevelOuter := bvNone;

  tvAssets := TTreeView.Create(Self); tvAssets.Parent := pnlList;
  tvAssets.Align := alClient; tvAssets.OnClick := tvAssetsClick;

  splitter := TSplitter.Create(Self); splitter.Parent := Self;
  splitter.Align := alLeft; splitter.Width := 4;

  pnlPreview := TPanel.Create(Self); pnlPreview.Parent := Self;
  pnlPreview.Align := alClient; pnlPreview.BevelOuter := bvLowered;

  imgPreview := TImage.Create(Self); imgPreview.Parent := pnlPreview;
  imgPreview.Align := alClient; imgPreview.Stretch := True;
  imgPreview.Proportional := True; imgPreview.Center := True;
end;

procedure TAssetBrowserForm.StyleForm;
var t: TFDCTheme;
begin
  t := TThemeManager.Current;
  Color := t.BgDark; Font.Color := t.TextPrimary;
  pnlTop.Color := t.BgMedium; pnlBottom.Color := t.BgMedium;
  pnlList.Color := t.BgDark; pnlPreview.Color := t.BgLight;
  lblTitle.Font.Color := t.AccentPrimary;
  lblPath.Font.Color := t.TextDim;
tvAssets.Color := t.BgDark; tvAssets.Font.Color := t.TextPrimary;
   cmbFilter.Color := t.BgLight;
   TThemeManager.ApplyToForm(Self);
end;

procedure TAssetBrowserForm.PopulateTree(const path: string);
var
  dirs, files: TArray<string>;
  d, f: string;
  node: TTreeNode;
begin
  tvAssets.Items.Clear;
  if not TDirectory.Exists(path) then Exit;
  lblPath.Caption := path;
  node := tvAssets.Items.Add(nil, ExtractFileName(path));
  node.Data := PChar(path);

  dirs := TDirectory.GetDirectories(path);
  for d in dirs do
  begin
    node := tvAssets.Items.AddChild(node, ExtractFileName(d));
    node.Data := PChar(d);
    AddSubDir(node, d);
  end;

  files := TDirectory.GetFiles(path);
  for f in files do
  begin
    if LowerCase(ExtractFileExt(f)) = '' then Continue;
    node := tvAssets.Items.AddChild(node, ExtractFileName(f));
    node.Data := PChar(f);
  end;

  if tvAssets.Items.Count > 0 then tvAssets.Items[0].Expand(False);
end;

procedure TAssetBrowserForm.AddSubDir(parent: TTreeNode; const dirPath: string);
var
  dirs, files: TArray<string>;
  d, f: string;
  node: TTreeNode;
begin
  dirs := TDirectory.GetDirectories(dirPath);
  for d in dirs do
  begin
    node := tvAssets.Items.AddChild(parent, ExtractFileName(d));
    node.Data := PChar(d);
    AddSubDir(node, d);
  end;
  files := TDirectory.GetFiles(dirPath);
  for f in files do
  begin
    if LowerCase(ExtractFileExt(f)) = '' then Continue;
    node := tvAssets.Items.AddChild(parent, ExtractFileName(f));
    node.Data := PChar(f);
  end;
end;

procedure TAssetBrowserForm.tvAssetsClick(Sender: TObject);
var
  node: TTreeNode;
  filePath: string;
  ext: string;
begin
  node := tvAssets.Selected;
  if not Assigned(node) or (node.Data = nil) then Exit;
  filePath := string(PChar(node.Data));
  if TFile.Exists(filePath) then
  begin
    FSelectedFile := filePath;
    lblPath.Caption := filePath;
    ext := LowerCase(ExtractFileExt(filePath));
    if (ext = '.png') or (ext = '.jpg') or (ext = '.jpeg') or (ext = '.bmp') then
    try
      imgPreview.Picture.LoadFromFile(filePath);
    except
      imgPreview.Picture.Assign(nil);
    end else
      imgPreview.Picture.Assign(nil);
  end;
end;

procedure TAssetBrowserForm.btnBrowseFolderClick(Sender: TObject);
var
  dlg: TFileOpenDialog;
begin
  dlg := TFileOpenDialog.Create(nil);
  try
    dlg.Options := [fdoPickFolders, fdoPathMustExist];
    dlg.Title := 'Select Asset Folder';
    if dlg.Execute then
    begin
      FRootPath := dlg.FileName;
      PopulateTree(FRootPath);
    end;
  finally dlg.Free; end;
end;

procedure TAssetBrowserForm.btnSelectClick(Sender: TObject);
begin
  if FSelectedFile <> '' then ModalResult := mrOk;
end;

procedure TAssetBrowserForm.cmbFilterChange(Sender: TObject);
begin
  if FRootPath <> '' then PopulateTree(FRootPath);
end;

initialization
  RegisterClass(TAssetBrowserForm);
end.