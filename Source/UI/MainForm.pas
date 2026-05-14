unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids,
  NodeTypes, ProjectManager, NodeEditor, ThemeManager;

type
  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    pnlCenter: TPanel;
    pnlRight: TPanel;
    pnlBottom: TPanel;
    splitLeft: TSplitter;
    splitRight: TSplitter;
    splitBottom: TSplitter;
    lstNodePalette: TListBox;
    propInspector: TStringGrid;
    memConsole: TMemo;
    mainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mnuNew: TMenuItem;
    mnuOpen: TMenuItem;
    mnuSave: TMenuItem;
    mnuExit: TMenuItem;
    mnuExport: TMenuItem;
    mnuExportSSL: TMenuItem;
    mnuExportMSG: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure mnuNewClick(Sender: TObject);
    procedure mnuOpenClick(Sender: TObject);
    procedure mnuSaveClick(Sender: TObject);
    procedure mnuExportSSLClick(Sender: TObject);
    procedure mnuExportMSGClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
  private
    FProjectManager: TProjectManager;
    FNodeEditor: TNodeEditor;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  DialogueCompiler, JSONSerializer;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FProjectManager := TProjectManager.Create;
  FNodeEditor := TNodeEditor.Create(Self);
  FNodeEditor.Parent := pnlCenter;
  FNodeEditor.Align := alClient;
  TThemeManager.ApplyFalloutTheme(Self);
  lstNodePalette.Items.AddStrings(['NPC Dialogue', 'Player Reply', 'Skill Check', 'End Node']);
end;

procedure TfrmMain.mnuNewClick(Sender: TObject);
begin
  FProjectManager.NewProject('New Project');
  FNodeEditor.Nodes.Clear;
  memConsole.Lines.Add('New project created');
end;

procedure TfrmMain.mnuOpenClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Filter := 'JSON Files (*.json)|*.json';
    if OpenDlg.Execute then
    begin
      FProjectManager.LoadProject(OpenDlg.FileName);
      FNodeEditor.Nodes.Clear;
      for var Node in FProjectManager.CurrentProject.Nodes do
        FNodeEditor.Nodes.Add(Node);
      memConsole.Lines.Add('Project loaded: ' + OpenDlg.FileName);
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TfrmMain.mnuSaveClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.Filter := 'JSON Files (*.json)|*.json';
    if SaveDlg.Execute then
    begin
      FProjectManager.SaveProjectAs(SaveDlg.FileName);
      memConsole.Lines.Add('Project saved: ' + SaveDlg.FileName);
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmMain.mnuExportSSLClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.Filter := 'SSL Files (*.ssl)|*.ssl';
    if SaveDlg.Execute then
    begin
      TDialogueCompiler.CompileToSSL(FProjectManager.CurrentProject, SaveDlg.FileName, ChangeFileExt(SaveDlg.FileName, '.msg'));
      memConsole.Lines.Add('Exported SSL: ' + SaveDlg.FileName);
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmMain.mnuExportMSGClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.Filter := 'MSG Files (*.msg)|*.msg';
    if SaveDlg.Execute then
    begin
      TDialogueCompiler.CompileToSSL(FProjectManager.CurrentProject, ChangeFileExt(SaveDlg.FileName, '.ssl'), SaveDlg.FileName);
      memConsole.Lines.Add('Exported MSG: ' + SaveDlg.FileName);
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmMain.mnuExitClick(Sender: TObject);
begin
  Close;
end;

end.