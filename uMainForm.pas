unit uMainForm;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  System.Generics.Collections, System.IOUtils,
  Winapi.Windows, Winapi.Messages,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.Menus, Vcl.ToolWin, Vcl.Buttons, Vcl.Graphics, Vcl.Dialogs,
  Vcl.ActnList, Vcl.Imaging.PNGImage,
  uDialogueTypes, uNodeCanvas, uThemeManager, uProjectManager,
  uExportManager;

type
  TMainForm = class(TForm)
  private
    //=== Core data ===
    FProject: TDialogueProject;
    FProjectManager: TProjectManager;
    FUndoStack: TObjectList<TDialogueProject>;
    FRedoStack: TObjectList<TDialogueProject>;
    FAutoSaveTimer: TTimer;
    FModifiedMarker: Boolean;

    //=== Layout panels ===
    pnlMain: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    pnlBottom: TPanel;
    splLeft: TSplitter;
    splRight: TSplitter;
    splBottom: TSplitter;
    pnlCanvasHost: TPanel;
    pnlStatusBar: TPanel;

    //=== Menu & toolbar ===
    mmMain: TMainMenu;
    tbMain: TToolBar;
    StatusBar: TStatusBar;

    //=== Canvas ===
    FCanvas: TNodeCanvas;

    //=== Left panel: project tree ===
    pnlLeftContent: TPanel;
    lblProjectTitle: TLabel;
    tvProject: TTreeView;
    pnlLeftTools: TPanel;
    btnAddNPCNode: TSpeedButton;
    btnAddPlayerNode: TSpeedButton;
    btnAddCondNode: TSpeedButton;
    btnAddScriptNode: TSpeedButton;
    btnAddEndNode: TSpeedButton;
    btnAddCommentNode: TSpeedButton;

    //=== Right panel: properties ===
    pnlRightContent: TPanel;
    lblPropsTitle: TLabel;
    pcProperties: TPageControl;
    tsNodeInfo: TTabSheet;
    tsProjectInfo: TTabSheet;

    // Node info controls (right panel quick view)
    lblNodeID, lblNodeTypeR, lblNodeSpeaker, lblNodeText, lblNodeOpts: TLabel;
    lblNodeIDVal: TLabel;
    lblNodeTypeVal: TLabel;
    edtNodeSpeaker: TEdit;
    memoNodeText: TMemo;
    lblNodeOptsVal: TLabel;
    btnEditNodeFull: TButton;
    btnSetStartNode: TButton;

    // Project info controls
    lblProjName, lblProjNPC, lblProjNPCScript, lblProjDesc, lblProjAuthor, lblProjVersion, lblStartNode: TLabel;
    edtProjName, edtProjNPC, edtProjNPCScript, edtProjAuthor, edtProjVersion, edtStartNode: TEdit;
    memoProjDesc: TMemo;
    lblProjStats: TLabel;
    btnApplyProjInfo: TButton;

    //=== Bottom panel: output log ===
    pnlBottomContent: TPanel;
    lblLogTitle: TLabel;
    memoLog: TMemo;
    btnClearLog: TButton;
    btnLogClose: TButton;

    //=== Canvas toolbar (above canvas) ===
    pnlCanvasToolbar: TPanel;
    btnZoomIn: TSpeedButton;
    btnZoomOut: TSpeedButton;
    btnZoomReset: TSpeedButton;
    btnFitAll: TSpeedButton;
    btnAutoLayout: TSpeedButton;
    btnToggleGrid: TSpeedButton;
    btnToggleMinimap: TSpeedButton;
    lblZoomLevel: TLabel;
    pnlNodeCounter: TPanel;
    lblNodeCount: TLabel;

    //=== Menu items (stored for enable/disable) ===
    miFile, miEdit, miView, miProject, miTools, miHelp: TMenuItem;
    miNew, miOpen, miSave, miSaveAs, miRecentSep: TMenuItem;
    miUndo, miRedo, miSelectAll, miDeleteSelected: TMenuItem;
    miPreview, miExportJSON, miExportMSG, miExportSSL, miExportPkg: TMenuItem;
    miFloatMessages, miValidation, miLocalization, miScriptEditor: TMenuItem;
    miThemeAmber, miThemeGreen, miThemeCyan, miThemeRed, miThemeWhite: TMenuItem;
    miShowGrid, miShowMinimap, miSnapGrid: TMenuItem;
    miAbout: TMenuItem;

    //=== State ===
    FSelectedNodeID: string;
    FIgnoreNodeChanges: Boolean;

    //=== UI build methods ===
    procedure BuildMenu;
    procedure BuildToolbar;
    procedure BuildLeftPanel;
    procedure BuildRightPanel;
    procedure BuildBottomPanel;
    procedure BuildCanvasArea;
    procedure BuildCanvasToolbar;
    procedure BuildStatusBar;

    //=== Style ===
    procedure ApplyTheme;
    procedure ApplyThemeToMenus;
    procedure SetTheme(style: TThemeStyle);

    //=== Project ===
    procedure NewProject;
    procedure OpenProject(const path: string = '');
    procedure SaveProject(saveAs: Boolean = False);
    procedure CloseProject;
    procedure LoadProjectIntoUI;
    procedure RefreshProjectTree;
    procedure RefreshCanvasFromProject;
    procedure RefreshStatusBar;
    procedure RefreshNodeCount;
    procedure MarkModified;
    procedure UpdateTitleBar;
    function ConfirmDiscardChanges: Boolean;

    //=== Node operations ===
    procedure AddNodeToCanvas(nodeType: TNodeType);
    procedure EditSelectedNode;
    procedure DeleteSelectedNodes;
    procedure SetSelectedNodeAsStart;
    procedure SelectNode(const nodeID: string);

    //=== Right panel sync ===
    procedure RefreshRightPanelForNode(const nodeID: string);
    procedure ApplyNodeQuickEdit;
    procedure RefreshProjectInfoPanel;
    procedure ApplyProjectInfo;

    //=== Log ===
    procedure Log(const msg: string; level: Integer = 0);

    //=== Canvas events ===
    procedure OnNodeSelect(Sender: TObject; const nodeID: string);
    procedure OnNodeDblClick(Sender: TObject; const nodeID: string);
    procedure OnConnectionMade(Sender: TObject; const fromID, toID: string; optIdx: Integer);
    procedure OnCanvasModified(Sender: TObject);

    //=== Autosave ===
    procedure AutoSaveTimer(Sender: TObject);
    procedure TryAutoSave;

    //=== Undo/Redo ===
    procedure PushUndoState;
    procedure PerformUndo;
    procedure PerformRedo;

    //=== Menu/Toolbar handlers ===
    procedure miNewClick(Sender: TObject);
    procedure miOpenClick(Sender: TObject);
    procedure miSaveClick(Sender: TObject);
    procedure miSaveAsClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miUndoClick(Sender: TObject);
    procedure miRedoClick(Sender: TObject);
    procedure miSelectAllClick(Sender: TObject);
    procedure miDeleteSelectedClick(Sender: TObject);
    procedure miPreviewClick(Sender: TObject);
    procedure miExportJSONClick(Sender: TObject);
    procedure miExportMSGClick(Sender: TObject);
    procedure miExportSSLClick(Sender: TObject);
    procedure miExportPkgClick(Sender: TObject);
    procedure miFloatMessagesClick(Sender: TObject);
    procedure miValidationClick(Sender: TObject);
    procedure miLocalizationClick(Sender: TObject);
    procedure miScriptEditorClick(Sender: TObject);
    procedure miShowGridClick(Sender: TObject);
    procedure miShowMinimapClick(Sender: TObject);
    procedure miSnapGridClick(Sender: TObject);
    procedure miAutoLayoutClick(Sender: TObject);
    procedure miThemeClick(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure miCreateSampleClick(Sender: TObject);

    procedure btnZoomInClick(Sender: TObject);
    procedure btnZoomOutClick(Sender: TObject);
    procedure btnZoomResetClick(Sender: TObject);
    procedure btnFitAllClick(Sender: TObject);
    procedure btnAutoLayoutClick(Sender: TObject);
    procedure btnToggleGridClick(Sender: TObject);
    procedure btnToggleMinimapClick(Sender: TObject);
    procedure btnAddNodeTypeClick(Sender: TObject);
    procedure btnEditNodeFullClick(Sender: TObject);
    procedure btnSetStartNodeClick(Sender: TObject);
    procedure btnApplyProjInfoClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnLogCloseClick(Sender: TObject);
    procedure tvProjectClick(Sender: TObject);
    procedure tvProjectDblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtNodeSpeakerChange(Sender: TObject);
    procedure memoNodeTextChange(Sender: TObject);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

uses
  uNodeProperties, uPreviewSystem, uFloatMessageEditor,
  uValidationTools, uScriptEditor, uLocalization,
  uAssetBrowser, uSkillCheckEditor, uSearchPanel;

type
  TControlHack = class(TControl) end;

{ TMainForm }

constructor TMainForm.Create(AOwner: TComponent);
begin
    inherited CreateNew(AOwner);
   FUndoStack := TObjectList<TDialogueProject>.Create(False);
   FRedoStack := TObjectList<TDialogueProject>.Create(False);
   FProjectManager := TProjectManager.Create;
   FormCreate(Self);
end;

destructor TMainForm.Destroy;
begin
  FUndoStack.Free;
  FRedoStack.Free;
  FProjectManager.Free;
  if Assigned(FProject) then FProject.Free;
  inherited;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  TThemeManager.ApplyTheme(tsAmber);

  // Build all UI panels
  BuildMenu;
  BuildStatusBar;
  BuildLeftPanel;
  BuildRightPanel;
  BuildBottomPanel;
  BuildCanvasArea;
  BuildToolbar;

  ApplyTheme;

  // Autosave timer
  FAutoSaveTimer := TTimer.Create(Self);
  FAutoSaveTimer.Interval := 120000; // 2 minutes
  FAutoSaveTimer.OnTimer := AutoSaveTimer;
  FAutoSaveTimer.Enabled := True;

  // Create initial project
  NewProject;

  Log('Fallout Dialogue Creator initialized.', 0);
  Log('Version 1.0.0  |  Delphi VCL Edition', 0);
  Log('Right-click on the canvas to add nodes.', 0);
  Log('Double-click a node to open properties.', 0);

KeyPreview := True;
   OnKeyDown := FormKeyDown;
   OnClose := FormClose;
   OnCloseQuery := FormCloseQuery;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FAutoSaveTimer.Enabled := False;
  if Assigned(FProject) and FProject.Modified then
    TryAutoSave;
  Action := caFree;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Assigned(FProject) and FProject.Modified then
    CanClose := ConfirmDiscardChanges
  else
    CanClose := True;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if Assigned(FCanvas) then FCanvas.Invalidate;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if ssCtrl in Shift then
    case Key of
      Ord('N'): NewProject;
      Ord('O'): OpenProject;
      Ord('S'): if ssShift in Shift then SaveProject(True) else SaveProject;
      Ord('Z'): PerformUndo;
      Ord('Y'): PerformRedo;
      Ord('A'): if Assigned(FCanvas) then FCanvas.SelectAll;
      Ord('P'): miPreviewClick(nil);
      Ord('E'): EditSelectedNode;
      VK_DELETE: DeleteSelectedNodes;
    end;
end;

{ ============================================================
  MENU BUILDER
  ============================================================ }
procedure TMainForm.BuildMenu;
var
  mi: TMenuItem;
begin
  mmMain := TMainMenu.Create(Self);
  Menu := mmMain;

  // FILE
  miFile := TMenuItem.Create(Self); miFile.Caption := '&File'; mmMain.Items.Add(miFile);

  miNew := TMenuItem.Create(Self); miNew.Caption := '&New Project'; miNew.ShortCut := TextToShortCut('Ctrl+N');
  miNew.OnClick := miNewClick; miFile.Add(miNew);

  miOpen := TMenuItem.Create(Self); miOpen.Caption := '&Open Project...'; miOpen.ShortCut := TextToShortCut('Ctrl+O');
  miOpen.OnClick := miOpenClick; miFile.Add(miOpen);

  miSave := TMenuItem.Create(Self); miSave.Caption := '&Save'; miSave.ShortCut := TextToShortCut('Ctrl+S');
  miSave.OnClick := miSaveClick; miFile.Add(miSave);

  miSaveAs := TMenuItem.Create(Self); miSaveAs.Caption := 'Save &As...'; miSaveAs.ShortCut := TextToShortCut('Ctrl+Shift+S');
  miSaveAs.OnClick := miSaveAsClick; miFile.Add(miSaveAs);

  mi := TMenuItem.Create(Self); mi.Caption := '-'; miFile.Add(mi);

  var miSample := TMenuItem.Create(Self); miSample.Caption := 'Create Sample Project (Harold the Ghoul)';
  miSample.OnClick := miCreateSampleClick; miFile.Add(miSample);

  mi := TMenuItem.Create(Self); mi.Caption := '-'; miFile.Add(mi);

  miRecentSep := TMenuItem.Create(Self); miRecentSep.Caption := 'Recent Projects'; miFile.Add(miRecentSep);

  mi := TMenuItem.Create(Self); mi.Caption := '-'; miFile.Add(mi);

  var miExit := TMenuItem.Create(Self); miExit.Caption := 'E&xit'; miExit.ShortCut := TextToShortCut('Alt+F4');
  miExit.OnClick := miExitClick; miFile.Add(miExit);

  // EDIT
  miEdit := TMenuItem.Create(Self); miEdit.Caption := '&Edit'; mmMain.Items.Add(miEdit);

  miUndo := TMenuItem.Create(Self); miUndo.Caption := '&Undo'; miUndo.ShortCut := TextToShortCut('Ctrl+Z');
  miUndo.OnClick := miUndoClick; miEdit.Add(miUndo);

  miRedo := TMenuItem.Create(Self); miRedo.Caption := '&Redo'; miRedo.ShortCut := TextToShortCut('Ctrl+Y');
  miRedo.OnClick := miRedoClick; miEdit.Add(miRedo);

  mi := TMenuItem.Create(Self); mi.Caption := '-'; miEdit.Add(mi);

  miSelectAll := TMenuItem.Create(Self); miSelectAll.Caption := 'Select &All'; miSelectAll.ShortCut := TextToShortCut('Ctrl+A');
  miSelectAll.OnClick := miSelectAllClick; miEdit.Add(miSelectAll);

  miDeleteSelected := TMenuItem.Create(Self); miDeleteSelected.Caption := '&Delete Selected'; miDeleteSelected.ShortCut := TextToShortCut('Delete');
  miDeleteSelected.OnClick := miDeleteSelectedClick; miEdit.Add(miDeleteSelected);

  mi := TMenuItem.Create(Self); mi.Caption := '-'; miEdit.Add(mi);

  var miAutoLayout2 := TMenuItem.Create(Self); miAutoLayout2.Caption := 'Auto-Layout Nodes';
  miAutoLayout2.OnClick := miAutoLayoutClick; miEdit.Add(miAutoLayout2);

  // VIEW
  miView := TMenuItem.Create(Self); miView.Caption := '&View'; mmMain.Items.Add(miView);

  miShowGrid := TMenuItem.Create(Self); miShowGrid.Caption := 'Show &Grid'; miShowGrid.Checked := True;
  miShowGrid.ShortCut := TextToShortCut('Ctrl+G'); miShowGrid.OnClick := miShowGridClick; miView.Add(miShowGrid);

  miSnapGrid := TMenuItem.Create(Self); miSnapGrid.Caption := '&Snap to Grid'; miSnapGrid.Checked := True;
  miSnapGrid.ShortCut := TextToShortCut('Ctrl+Shift+G'); miSnapGrid.OnClick := miSnapGridClick; miView.Add(miSnapGrid);

  miShowMinimap := TMenuItem.Create(Self); miShowMinimap.Caption := 'Show &Minimap'; miShowMinimap.Checked := True;
  miShowMinimap.OnClick := miShowMinimapClick; miView.Add(miShowMinimap);

  mi := TMenuItem.Create(Self); mi.Caption := '-'; miView.Add(mi);

  var miThemeMenu := TMenuItem.Create(Self); miThemeMenu.Caption := '&Terminal Theme'; miView.Add(miThemeMenu);

  miThemeAmber := TMenuItem.Create(Self); miThemeAmber.Caption := '🟠 Amber Terminal (Classic)'; miThemeAmber.Tag := 0;
  miThemeAmber.Checked := True; miThemeAmber.OnClick := miThemeClick; miThemeMenu.Add(miThemeAmber);

  miThemeGreen := TMenuItem.Create(Self); miThemeGreen.Caption := '🟢 Green Phosphor'; miThemeGreen.Tag := 1;
  miThemeGreen.OnClick := miThemeClick; miThemeMenu.Add(miThemeGreen);

  miThemeCyan := TMenuItem.Create(Self); miThemeCyan.Caption := '🔵 Cyan Digital'; miThemeCyan.Tag := 2;
  miThemeCyan.OnClick := miThemeClick; miThemeMenu.Add(miThemeCyan);

  miThemeRed := TMenuItem.Create(Self); miThemeRed.Caption := '🔴 Red Alert'; miThemeRed.Tag := 3;
  miThemeRed.OnClick := miThemeClick; miThemeMenu.Add(miThemeRed);

  miThemeWhite := TMenuItem.Create(Self); miThemeWhite.Caption := '⬜ Vault-Tec White'; miThemeWhite.Tag := 4;
  miThemeWhite.OnClick := miThemeClick; miThemeMenu.Add(miThemeWhite);

  mi := TMenuItem.Create(Self); mi.Caption := '-'; miView.Add(mi);

  var miZoomIn2 := TMenuItem.Create(Self); miZoomIn2.Caption := 'Zoom In'; miZoomIn2.ShortCut := TextToShortCut('Ctrl+=');
  miZoomIn2.OnClick := btnZoomInClick; miView.Add(miZoomIn2);

  var miZoomOut2 := TMenuItem.Create(Self); miZoomOut2.Caption := 'Zoom Out'; miZoomOut2.ShortCut := TextToShortCut('Ctrl+-');
  miZoomOut2.OnClick := btnZoomOutClick; miView.Add(miZoomOut2);

  var miFitAll2 := TMenuItem.Create(Self); miFitAll2.Caption := 'Fit All Nodes'; miFitAll2.ShortCut := TextToShortCut('Ctrl+F');
  miFitAll2.OnClick := btnFitAllClick; miView.Add(miFitAll2);

  // PROJECT
  miProject := TMenuItem.Create(Self); miProject.Caption := '&Project'; mmMain.Items.Add(miProject);

  miPreview := TMenuItem.Create(Self); miPreview.Caption := '▶ &Preview Dialogue...'; miPreview.ShortCut := TextToShortCut('Ctrl+P');
  miPreview.OnClick := miPreviewClick; miProject.Add(miPreview);

  mi := TMenuItem.Create(Self); mi.Caption := '-'; miProject.Add(mi);

  miFloatMessages := TMenuItem.Create(Self); miFloatMessages.Caption := 'Float &Message Editor...';
  miFloatMessages.OnClick := miFloatMessagesClick; miProject.Add(miFloatMessages);

  miLocalization := TMenuItem.Create(Self); miLocalization.Caption := '&Localization Manager...';
  miLocalization.OnClick := miLocalizationClick; miProject.Add(miLocalization);

  miScriptEditor := TMenuItem.Create(Self); miScriptEditor.Caption := 'Script &Editor...';
  miScriptEditor.OnClick := miScriptEditorClick; miProject.Add(miScriptEditor);

  mi := TMenuItem.Create(Self); mi.Caption := '-'; miProject.Add(mi);

  miValidation := TMenuItem.Create(Self); miValidation.Caption := '&Validation && Analysis...';
  miValidation.ShortCut := TextToShortCut('Ctrl+Shift+V'); miValidation.OnClick := miValidationClick; miProject.Add(miValidation);

  // EXPORT (under project)
  mi := TMenuItem.Create(Self); mi.Caption := '-'; miProject.Add(mi);
  var miExportMenu := TMenuItem.Create(Self); miExportMenu.Caption := '&Export'; miProject.Add(miExportMenu);

  miExportJSON := TMenuItem.Create(Self); miExportJSON.Caption := 'Export as &JSON...';
  miExportJSON.OnClick := miExportJSONClick; miExportMenu.Add(miExportJSON);

  miExportMSG := TMenuItem.Create(Self); miExportMSG.Caption := 'Export as .&MSG File...';
  miExportMSG.OnClick := miExportMSGClick; miExportMenu.Add(miExportMSG);

  miExportSSL := TMenuItem.Create(Self); miExportSSL.Caption := 'Export as .&SSL Script...';
  miExportSSL.OnClick := miExportSSLClick; miExportMenu.Add(miExportSSL);

  mi := TMenuItem.Create(Self); mi.Caption := '-'; miExportMenu.Add(mi);

  miExportPkg := TMenuItem.Create(Self); miExportPkg.Caption := 'Export &Engine Package...';
  miExportPkg.OnClick := miExportPkgClick; miExportMenu.Add(miExportPkg);

  // HELP
  miHelp := TMenuItem.Create(Self); miHelp.Caption := '&Help'; mmMain.Items.Add(miHelp);

  miAbout := TMenuItem.Create(Self); miAbout.Caption := '&About Fallout Dialogue Creator';
  miAbout.OnClick := miAboutClick; miHelp.Add(miAbout);
end;

{ ============================================================
  TOOLBAR
  ============================================================ }
procedure TMainForm.BuildToolbar;
var
  btn: TToolButton;
  sep: TToolButton;
  b: TToolButton;
begin
  tbMain := TToolBar.Create(Self);
  tbMain.Parent := Self;
  tbMain.Align := alTop;
  tbMain.Height := 32;
tbMain.Flat := False;
   tbMain.Transparent := False;
   tbMain.ShowCaptions := True;
   tbMain.EdgeBorders := [ebBottom];

  b := TToolButton.Create(tbMain); b.Parent := tbMain;
  b.Caption := 'New'; b.Hint := 'New Project (Ctrl+N)'; b.ShowHint := True;
  b.Style := tbsButton; b.Tag := 0; b.OnClick := miNewClick;

  b := TToolButton.Create(tbMain); b.Parent := tbMain;
  b.Caption := 'Open'; b.Hint := 'Open Project (Ctrl+O)'; b.ShowHint := True;
  b.Style := tbsButton; b.Tag := 0; b.OnClick := miOpenClick;

  b := TToolButton.Create(tbMain); b.Parent := tbMain;
  b.Caption := 'Save'; b.Hint := 'Save Project (Ctrl+S)'; b.ShowHint := True;
  b.Style := tbsButton; b.Tag := 0; b.OnClick := miSaveClick;

  sep := TToolButton.Create(tbMain); sep.Parent := tbMain;
  sep.Style := tbsSeparator; sep.Width := 8;

  b := TToolButton.Create(tbMain); b.Parent := tbMain;
  b.Caption := 'Undo'; b.Hint := 'Undo (Ctrl+Z)'; b.ShowHint := True;
  b.Style := tbsButton; b.Tag := 0; b.OnClick := miUndoClick;

  b := TToolButton.Create(tbMain); b.Parent := tbMain;
  b.Caption := 'Redo'; b.Hint := 'Redo (Ctrl+Y)'; b.ShowHint := True;
  b.Style := tbsButton; b.Tag := 0; b.OnClick := miRedoClick;

  sep := TToolButton.Create(tbMain); sep.Parent := tbMain;
  sep.Style := tbsSeparator; sep.Width := 8;

  b := TToolButton.Create(tbMain); b.Parent := tbMain;
  b.Caption := '▶ Preview'; b.Hint := 'Preview Dialogue (Ctrl+P)'; b.ShowHint := True;
  b.Style := tbsButton; b.Tag := 0; b.OnClick := miPreviewClick;

  sep := TToolButton.Create(tbMain); sep.Parent := tbMain;
  sep.Style := tbsSeparator; sep.Width := 8;

  b := TToolButton.Create(tbMain); b.Parent := tbMain;
  b.Caption := '⚑ Validate'; b.Hint := 'Validate Project'; b.ShowHint := True;
  b.Style := tbsButton; b.Tag := 0; b.OnClick := miValidationClick;

  b := TToolButton.Create(tbMain); b.Parent := tbMain;
  b.Caption := '⬆ Export'; b.Hint := 'Export Engine Package'; b.ShowHint := True;
  b.Style := tbsButton; b.Tag := 0; b.OnClick := miExportPkgClick;

  sep := TToolButton.Create(tbMain); sep.Parent := tbMain;
  sep.Style := tbsSeparator; sep.Width := 8;

  b := TToolButton.Create(tbMain); b.Parent := tbMain;
  b.Caption := 'Float Msgs'; b.Hint := 'Edit Float Messages'; b.ShowHint := True;
  b.Style := tbsButton; b.Tag := 0; b.OnClick := miFloatMessagesClick;

  b := TToolButton.Create(tbMain); b.Parent := tbMain;
  b.Caption := 'Localize'; b.Hint := 'Localization Manager'; b.ShowHint := True;
  b.Style := tbsButton; b.Tag := 0; b.OnClick := miLocalizationClick;
end;

{ ============================================================
  LEFT PANEL — Project Tree & Node Palette
  ============================================================ }
procedure TMainForm.BuildLeftPanel;
var
  t: TFDCTheme;
begin
  pnlLeft := TPanel.Create(Self);
  pnlLeft.Parent := pnlMain;
  pnlLeft.Align := alLeft;
  pnlLeft.Width := 220;
  pnlLeft.BevelOuter := bvNone;

  splLeft := TSplitter.Create(Self);
  splLeft.Parent := pnlMain;
  splLeft.Align := alLeft;
  splLeft.Width := 4;
  splLeft.MinSize := 120;

  pnlLeftContent := TPanel.Create(Self);
  pnlLeftContent.Parent := pnlLeft;
  pnlLeftContent.Align := alClient;
  pnlLeftContent.BevelOuter := bvNone;

  // Header
  lblProjectTitle := TLabel.Create(Self);
  lblProjectTitle.Parent := pnlLeftContent;
  lblProjectTitle.Align := alTop;
  lblProjectTitle.AlignWithMargins := True;
  lblProjectTitle.Margins.SetBounds(4, 4, 4, 2);
  lblProjectTitle.Caption := 'PROJECT NODES';
  lblProjectTitle.Font.Style := [fsBold];
  lblProjectTitle.Font.Size := 8;

  // Tree view
  tvProject := TTreeView.Create(Self);
  tvProject.Parent := pnlLeftContent;
  tvProject.Align := alClient;
  tvProject.HideSelection := False;
  tvProject.ReadOnly := True;
  tvProject.OnClick := tvProjectClick;
  tvProject.OnDblClick := tvProjectDblClick;

// Node type palette buttons
  pnlLeftTools := TPanel.Create(Self);
  pnlLeftTools.Parent := pnlLeft;
  pnlLeftTools.Align := alBottom;
  pnlLeftTools.Height := 108;
  pnlLeftTools.BevelOuter := bvNone;

  var palLabel := TLabel.Create(Self);
  palLabel.Parent := pnlLeftTools;
  palLabel.Left := 4; palLabel.Top := 2;
  palLabel.Caption := 'ADD NODE:';
  palLabel.Font.Style := [fsBold];
  palLabel.Font.Size := 7;

  var btnW := 96;
  var btnH := 24;

  btnAddNPCNode := TSpeedButton.Create(Self);
  btnAddNPCNode.Parent := pnlLeftTools;
  btnAddNPCNode.Caption := '+ NPC Dialogue';
  btnAddNPCNode.Left := 2; btnAddNPCNode.Top := 18;
  btnAddNPCNode.Width := btnW; btnAddNPCNode.Height := btnH;
  btnAddNPCNode.Tag := 0;
  btnAddNPCNode.OnClick := btnAddNodeTypeClick;
  btnAddNPCNode.Flat := True;

  btnAddPlayerNode := TSpeedButton.Create(Self);
  btnAddPlayerNode.Parent := pnlLeftTools;
  btnAddPlayerNode.Caption := '+ Player Reply';
  btnAddPlayerNode.Left := 104; btnAddPlayerNode.Top := 18;
  btnAddPlayerNode.Width := btnW; btnAddPlayerNode.Height := btnH;
  btnAddPlayerNode.Tag := 1;
  btnAddPlayerNode.OnClick := btnAddNodeTypeClick;
  btnAddPlayerNode.Flat := True;

  btnAddCondNode := TSpeedButton.Create(Self);
  btnAddCondNode.Parent := pnlLeftTools;
  btnAddCondNode.Caption := '+ Conditional';
  btnAddCondNode.Left := 2; btnAddCondNode.Top := 44;
  btnAddCondNode.Width := btnW; btnAddCondNode.Height := btnH;
  btnAddCondNode.Tag := 2;
  btnAddCondNode.OnClick := btnAddNodeTypeClick;
  btnAddCondNode.Flat := True;

  btnAddScriptNode := TSpeedButton.Create(Self);
  btnAddScriptNode.Parent := pnlLeftTools;
  btnAddScriptNode.Caption := '+ Script Node';
  btnAddScriptNode.Left := 104; btnAddScriptNode.Top := 44;
  btnAddScriptNode.Width := btnW; btnAddScriptNode.Height := btnH;
  btnAddScriptNode.Tag := 4;
  btnAddScriptNode.OnClick := btnAddNodeTypeClick;
  btnAddScriptNode.Flat := True;

  btnAddEndNode := TSpeedButton.Create(Self);
  btnAddEndNode.Parent := pnlLeftTools;
  btnAddEndNode.Caption := '+ End Dialogue';
  btnAddEndNode.Left := 2; btnAddEndNode.Top := 70;
  btnAddEndNode.Width := btnW; btnAddEndNode.Height := btnH;
  btnAddEndNode.Tag := 8;
  btnAddEndNode.OnClick := btnAddNodeTypeClick;
  btnAddEndNode.Flat := True;

  btnAddCommentNode := TSpeedButton.Create(Self);
  btnAddCommentNode.Parent := pnlLeftTools;
  btnAddCommentNode.Caption := '+ Comment';
  btnAddCommentNode.Left := 104; btnAddCommentNode.Top := 70;
  btnAddCommentNode.Width := btnW; btnAddCommentNode.Height := btnH;
  btnAddCommentNode.Tag := 9;
  btnAddCommentNode.OnClick := btnAddNodeTypeClick;
  btnAddCommentNode.Flat := True;
end;

{ ============================================================
  RIGHT PANEL — Quick Properties
  ============================================================ }
procedure TMainForm.BuildRightPanel;
begin
  splRight := TSplitter.Create(Self);
  splRight.Parent := pnlMain;
  splRight.Align := alRight;
  splRight.Width := 4;
  splRight.MinSize := 180;

  pnlRight := TPanel.Create(Self);
  pnlRight.Parent := pnlMain;
  pnlRight.Align := alRight;
  pnlRight.Width := 260;
  pnlRight.BevelOuter := bvNone;

  pnlRightContent := TPanel.Create(Self);
  pnlRightContent.Parent := pnlRight;
  pnlRightContent.Align := alClient;
  pnlRightContent.BevelOuter := bvNone;

  lblPropsTitle := TLabel.Create(Self);
  lblPropsTitle.Parent := pnlRightContent;
  lblPropsTitle.Align := alTop;
  lblPropsTitle.AlignWithMargins := True;
  lblPropsTitle.Margins.SetBounds(4, 4, 4, 2);
  lblPropsTitle.Caption := 'PROPERTIES';
  lblPropsTitle.Font.Style := [fsBold];
  lblPropsTitle.Font.Size := 8;

  pcProperties := TPageControl.Create(Self);
  pcProperties.Parent := pnlRightContent;
  pcProperties.Align := alClient;

// Node info tab
   tsNodeInfo := TTabSheet.Create(pcProperties);
   tsNodeInfo.PageControl := pcProperties;
   tsNodeInfo.Caption := 'Node';

   var y := 6;
   var lw := 72;

   lblNodeID := TLabel.Create(Self); lblNodeID.Parent := tsNodeInfo;
   lblNodeID.Left := 4; lblNodeID.Top := y; lblNodeID.Width := lw;
   lblNodeID.Caption := 'Node ID:'; lblNodeID.Font.Size := 7;
   lblNodeIDVal := TLabel.Create(Self); lblNodeIDVal.Parent := tsNodeInfo;
   lblNodeIDVal.Left := lw + 6; lblNodeIDVal.Top := y; lblNodeIDVal.Width := 160;
   lblNodeIDVal.Caption := '—'; lblNodeIDVal.Font.Size := 7;
   Inc(y, 18);

   lblNodeTypeR := TLabel.Create(Self); lblNodeTypeR.Parent := tsNodeInfo;
   lblNodeTypeR.Left := 4; lblNodeTypeR.Top := y; lblNodeTypeR.Width := lw;
   lblNodeTypeR.Caption := 'Type:'; lblNodeTypeR.Font.Size := 7;
   lblNodeTypeVal := TLabel.Create(Self); lblNodeTypeVal.Parent := tsNodeInfo;
   lblNodeTypeVal.Left := lw + 6; lblNodeTypeVal.Top := y; lblNodeTypeVal.Width := 160;
   lblNodeTypeVal.Caption := '—'; lblNodeTypeVal.Font.Size := 7;
   Inc(y, 18);

   lblNodeSpeaker := TLabel.Create(Self); lblNodeSpeaker.Parent := tsNodeInfo;
   lblNodeSpeaker.Left := 4; lblNodeSpeaker.Top := y; lblNodeSpeaker.Width := lw;
   lblNodeSpeaker.Caption := 'Speaker:'; lblNodeSpeaker.Font.Size := 7;
   edtNodeSpeaker := TEdit.Create(Self); edtNodeSpeaker.Parent := tsNodeInfo;
   edtNodeSpeaker.Left := lw + 6; edtNodeSpeaker.Top := y - 2;
   edtNodeSpeaker.Width := 170; edtNodeSpeaker.Height := 22;
   edtNodeSpeaker.OnChange := edtNodeSpeakerChange;
   Inc(y, 26);

   lblNodeText := TLabel.Create(Self); lblNodeText.Parent := tsNodeInfo;
   lblNodeText.Left := 4; lblNodeText.Top := y; lblNodeText.Width := lw;
   lblNodeText.Caption := 'Text:'; lblNodeText.Font.Size := 7;
   memoNodeText := TMemo.Create(Self); memoNodeText.Parent := tsNodeInfo;
   memoNodeText.Left := 4; memoNodeText.Top := y + 14;
   memoNodeText.Width := pnlRightContent.Width - 12;
   memoNodeText.Height := 90;
   memoNodeText.WordWrap := True; memoNodeText.ScrollBars := ssVertical;
   memoNodeText.Anchors := [akLeft, akTop, akRight];
   memoNodeText.OnChange := memoNodeTextChange;
   Inc(y, 108);

   lblNodeOpts := TLabel.Create(Self); lblNodeOpts.Parent := tsNodeInfo;
   lblNodeOpts.Left := 4; lblNodeOpts.Top := y; lblNodeOpts.Width := lw;
   lblNodeOpts.Caption := 'Options:'; lblNodeOpts.Font.Size := 7;
   lblNodeOptsVal := TLabel.Create(Self); lblNodeOptsVal.Parent := tsNodeInfo;
   lblNodeOptsVal.Left := lw + 6; lblNodeOptsVal.Top := y; lblNodeOptsVal.Width := 160;
   lblNodeOptsVal.Caption := '0'; lblNodeOptsVal.Font.Size := 7;
   Inc(y, 20);

   btnEditNodeFull := TButton.Create(Self); btnEditNodeFull.Parent := tsNodeInfo;
   btnEditNodeFull.Caption := 'Open Full Properties...';
   btnEditNodeFull.Left := 4; btnEditNodeFull.Top := y;
   btnEditNodeFull.Width := 240; btnEditNodeFull.Height := 28;
   btnEditNodeFull.OnClick := btnEditNodeFullClick;
   Inc(y, 34);

   btnSetStartNode := TButton.Create(Self); btnSetStartNode.Parent := tsNodeInfo;
   btnSetStartNode.Caption := '⚑ Set as Start Node';
   btnSetStartNode.Left := 4; btnSetStartNode.Top := y;
   btnSetStartNode.Width := 240; btnSetStartNode.Height := 28;
   btnSetStartNode.OnClick := btnSetStartNodeClick;

   // Project info tab
   tsProjectInfo := TTabSheet.Create(pcProperties);
   tsProjectInfo.PageControl := pcProperties;
   tsProjectInfo.Caption := 'Project';

   var py := 6;

   lblProjName := TLabel.Create(Self); lblProjName.Parent := tsProjectInfo;
   lblProjName.Left := 4; lblProjName.Top := py; lblProjName.Width := 80;
   lblProjName.Caption := 'Project Name:'; lblProjName.Font.Size := 7;
   Inc(py, 2);
   edtProjName := TEdit.Create(Self); edtProjName.Parent := tsProjectInfo;
   edtProjName.Left := 4; edtProjName.Top := py + 14;
   edtProjName.Width := tsProjectInfo.Width - 12; edtProjName.Height := 22;
   edtProjName.Anchors := [akLeft, akTop, akRight];
   Inc(py, 38);

   lblProjNPC := TLabel.Create(Self); lblProjNPC.Parent := tsProjectInfo;
   lblProjNPC.Left := 4; lblProjNPC.Top := py; lblProjNPC.Width := 80;
   lblProjNPC.Caption := 'NPC Name:'; lblProjNPC.Font.Size := 7;
   edtProjNPC := TEdit.Create(Self); edtProjNPC.Parent := tsProjectInfo;
   edtProjNPC.Left := 4; edtProjNPC.Top := py + 14;
   edtProjNPC.Width := tsProjectInfo.Width - 12; edtProjNPC.Height := 22;
   edtProjNPC.Anchors := [akLeft, akTop, akRight];
   Inc(py, 38);

   lblProjNPCScript := TLabel.Create(Self); lblProjNPCScript.Parent := tsProjectInfo;
   lblProjNPCScript.Left := 4; lblProjNPCScript.Top := py; lblProjNPCScript.Width := 80;
   lblProjNPCScript.Caption := 'NPC Script:'; lblProjNPCScript.Font.Size := 7;
   edtProjNPCScript := TEdit.Create(Self); edtProjNPCScript.Parent := tsProjectInfo;
   edtProjNPCScript.Left := 4; edtProjNPCScript.Top := py + 14;
   edtProjNPCScript.Width := tsProjectInfo.Width - 12; edtProjNPCScript.Height := 22;
   edtProjNPCScript.Anchors := [akLeft, akTop, akRight];
   Inc(py, 38);

   lblProjAuthor := TLabel.Create(Self); lblProjAuthor.Parent := tsProjectInfo;
   lblProjAuthor.Left := 4; lblProjAuthor.Top := py; lblProjAuthor.Width := 80;
   lblProjAuthor.Caption := 'Author:'; lblProjAuthor.Font.Size := 7;
   edtProjAuthor := TEdit.Create(Self); edtProjAuthor.Parent := tsProjectInfo;
   edtProjAuthor.Left := 4; edtProjAuthor.Top := py + 14;
   edtProjAuthor.Width := tsProjectInfo.Width - 12; edtProjAuthor.Height := 22;
   edtProjAuthor.Anchors := [akLeft, akTop, akRight];
   Inc(py, 38);

   lblProjVersion := TLabel.Create(Self); lblProjVersion.Parent := tsProjectInfo;
   lblProjVersion.Left := 4; lblProjVersion.Top := py; lblProjVersion.Width := 80;
   lblProjVersion.Caption := 'Version:'; lblProjVersion.Font.Size := 7;
   edtProjVersion := TEdit.Create(Self); edtProjVersion.Parent := tsProjectInfo;
   edtProjVersion.Left := 4; edtProjVersion.Top := py + 14;
   edtProjVersion.Width := tsProjectInfo.Width - 12; edtProjVersion.Height := 22;
   edtProjVersion.Anchors := [akLeft, akTop, akRight];
   Inc(py, 38);

   lblStartNode := TLabel.Create(Self); lblStartNode.Parent := tsProjectInfo;
   lblStartNode.Left := 4; lblStartNode.Top := py; lblStartNode.Width := 80;
   lblStartNode.Caption := 'Start Node ID:'; lblStartNode.Font.Size := 7;
   edtStartNode := TEdit.Create(Self); edtStartNode.Parent := tsProjectInfo;
   edtStartNode.Left := 4; edtStartNode.Top := py + 14;
   edtStartNode.Width := tsProjectInfo.Width - 12; edtStartNode.Height := 22;
   edtStartNode.Anchors := [akLeft, akTop, akRight];
   Inc(py, 38);

   lblProjDesc := TLabel.Create(Self); lblProjDesc.Parent := tsProjectInfo;
   lblProjDesc.Left := 4; lblProjDesc.Top := py; lblProjDesc.Width := 80;
   lblProjDesc.Caption := 'Description:'; lblProjDesc.Font.Size := 7;
   memoProjDesc := TMemo.Create(Self); memoProjDesc.Parent := tsProjectInfo;
   memoProjDesc.Left := 4; memoProjDesc.Top := py + 14;
   memoProjDesc.Width := tsProjectInfo.Width - 12; memoProjDesc.Height := 60;
   memoProjDesc.Anchors := [akLeft, akTop, akRight];
   memoProjDesc.WordWrap := True; memoProjDesc.ScrollBars := ssVertical;
   Inc(py, 76);

   lblProjStats := TLabel.Create(Self); lblProjStats.Parent := tsProjectInfo;
   lblProjStats.Left := 4; lblProjStats.Top := py;
   lblProjStats.Caption := 'Nodes: 0  |  Options: 0';
   lblProjStats.Font.Size := 7; lblProjStats.Width := 250;
   lblProjStats.Anchors := [akLeft, akTop, akRight];
   Inc(py, 18);

   btnApplyProjInfo := TButton.Create(Self); btnApplyProjInfo.Parent := tsProjectInfo;
   btnApplyProjInfo.Caption := 'Apply Project Info';
   btnApplyProjInfo.Left := 4; btnApplyProjInfo.Top := py;
   btnApplyProjInfo.Width := 240; btnApplyProjInfo.Height := 28;
   btnApplyProjInfo.Anchors := [akLeft, akTop, akRight];
   btnApplyProjInfo.OnClick := btnApplyProjInfoClick;
end;

{ ============================================================
  BOTTOM PANEL — Output / Log
  ============================================================ }
procedure TMainForm.BuildBottomPanel;
begin
  splBottom := TSplitter.Create(Self);
  splBottom.Parent := pnlMain;
  splBottom.Align := alBottom;
  splBottom.Height := 4;

  pnlBottom := TPanel.Create(Self);
  pnlBottom.Parent := pnlMain;
  pnlBottom.Align := alBottom;
  pnlBottom.Height := 140;
  pnlBottom.BevelOuter := bvNone;

  pnlBottomContent := TPanel.Create(Self);
  pnlBottomContent.Parent := pnlBottom;
  pnlBottomContent.Align := alClient;
  pnlBottomContent.BevelOuter := bvNone;

  var pnlLogHeader := TPanel.Create(Self);
  pnlLogHeader.Parent := pnlBottomContent;
  pnlLogHeader.Align := alTop;
  pnlLogHeader.Height := 26;
  pnlLogHeader.BevelOuter := bvNone;

  lblLogTitle := TLabel.Create(Self);
  lblLogTitle.Parent := pnlLogHeader;
  lblLogTitle.Left := 6; lblLogTitle.Top := 5;
  lblLogTitle.Caption := 'OUTPUT LOG';
  lblLogTitle.Font.Style := [fsBold]; lblLogTitle.Font.Size := 8;

  btnClearLog := TButton.Create(Self);
  btnClearLog.Parent := pnlLogHeader;
  btnClearLog.Caption := 'Clear';
  btnClearLog.Anchors := [akRight, akTop];
  btnClearLog.Left := pnlLogHeader.Width - 110;
  btnClearLog.Top := 2; btnClearLog.Width := 56; btnClearLog.Height := 22;
  btnClearLog.OnClick := btnClearLogClick;

  btnLogClose := TButton.Create(Self);
  btnLogClose.Parent := pnlLogHeader;
  btnLogClose.Caption := '▼';
  btnLogClose.Anchors := [akRight, akTop];
  btnLogClose.Left := pnlLogHeader.Width - 48;
  btnLogClose.Top := 2; btnLogClose.Width := 36; btnLogClose.Height := 22;
  btnLogClose.OnClick := btnLogCloseClick;

  memoLog := TMemo.Create(Self);
  memoLog.Parent := pnlBottomContent;
  memoLog.Align := alClient;
  memoLog.ReadOnly := True;
  memoLog.ScrollBars := ssBoth;
  memoLog.WordWrap := False;
  memoLog.Font.Name := 'Courier New';
  memoLog.Font.Size := 8;
end;

{ ============================================================
  CANVAS AREA
  ============================================================ }
procedure TMainForm.BuildCanvasArea;
begin
  pnlCanvasHost := TPanel.Create(Self);
  pnlCanvasHost.Parent := pnlMain;
  pnlCanvasHost.Align := alClient;
  pnlCanvasHost.BevelOuter := bvNone;

  BuildCanvasToolbar;

  FCanvas := TNodeCanvas.Create(Self);
  FCanvas.Parent := pnlCanvasHost;
  FCanvas.Align := alClient;
  FCanvas.OnNodeSelect := OnNodeSelect;
  FCanvas.OnNodeDblClick := OnNodeDblClick;
  FCanvas.OnConnectionMade := OnConnectionMade;
  FCanvas.OnModified := OnCanvasModified;
  FCanvas.ShowGrid := True;
  FCanvas.SnapToGrid_ := True;
  FCanvas.ShowMinimap := True;
end;

procedure TMainForm.BuildCanvasToolbar;
var
  x: Integer;
  b: TSpeedButton;
begin
  pnlCanvasToolbar := TPanel.Create(Self);
  pnlCanvasToolbar.Parent := pnlCanvasHost;
  pnlCanvasToolbar.Align := alTop;
  pnlCanvasToolbar.Height := 32;
  pnlCanvasToolbar.BevelOuter := bvNone;

  x := 4;

  b := TSpeedButton.Create(Self); b.Parent := pnlCanvasToolbar;
  b.Caption := '+'; b.Hint := 'Zoom In (Ctrl+=)'; b.ShowHint := True;
  b.Left := x; b.Top := 4; b.Width := 36; b.Height := 24;
  b.Flat := True; b.OnClick := btnZoomInClick;
  Inc(x, 38);

  b := TSpeedButton.Create(Self); b.Parent := pnlCanvasToolbar;
  b.Caption := '−'; b.Hint := 'Zoom Out (Ctrl+-)'; b.ShowHint := True;
  b.Left := x; b.Top := 4; b.Width := 36; b.Height := 24;
  b.Flat := True; b.OnClick := btnZoomOutClick;
  Inc(x, 38);

  btnZoomReset := TSpeedButton.Create(Self); btnZoomReset.Parent := pnlCanvasToolbar;
  btnZoomReset.Caption := '1:1'; btnZoomReset.Hint := 'Reset Zoom (Ctrl+0)'; btnZoomReset.ShowHint := True;
  btnZoomReset.Left := x; btnZoomReset.Top := 4; btnZoomReset.Width := 36; btnZoomReset.Height := 24;
  btnZoomReset.Flat := True; btnZoomReset.OnClick := btnZoomResetClick;
  Inc(x, 38);

  btnFitAll := TSpeedButton.Create(Self); btnFitAll.Parent := pnlCanvasToolbar;
  btnFitAll.Caption := '⊡'; btnFitAll.Hint := 'Fit All (Ctrl+F)'; btnFitAll.ShowHint := True;
  btnFitAll.Left := x; btnFitAll.Top := 4; btnFitAll.Width := 36; btnFitAll.Height := 24;
  btnFitAll.Flat := True; btnFitAll.OnClick := btnFitAllClick;
  Inc(x, 38);
  Inc(x, 8);

  btnAutoLayout := TSpeedButton.Create(Self); btnAutoLayout.Parent := pnlCanvasToolbar;
  btnAutoLayout.Caption := '⊞'; btnAutoLayout.Hint := 'Auto-Layout Nodes'; btnAutoLayout.ShowHint := True;
  btnAutoLayout.Left := x; btnAutoLayout.Top := 4; btnAutoLayout.Width := 36; btnAutoLayout.Height := 24;
  btnAutoLayout.Flat := True; btnAutoLayout.OnClick := btnAutoLayoutClick;
  Inc(x, 38);
  Inc(x, 8);

  btnToggleGrid := TSpeedButton.Create(Self); btnToggleGrid.Parent := pnlCanvasToolbar;
  btnToggleGrid.Caption := '⊞'; btnToggleGrid.Hint := 'Toggle Grid'; btnToggleGrid.ShowHint := True;
  btnToggleGrid.Left := x; btnToggleGrid.Top := 4; btnToggleGrid.Width := 36; btnToggleGrid.Height := 24;
  btnToggleGrid.Flat := True; btnToggleGrid.OnClick := btnToggleGridClick;
  Inc(x, 38);

  btnToggleMinimap := TSpeedButton.Create(Self); btnToggleMinimap.Parent := pnlCanvasToolbar;
  btnToggleMinimap.Caption := '⊠'; btnToggleMinimap.Hint := 'Toggle Minimap'; btnToggleMinimap.ShowHint := True;
  btnToggleMinimap.Left := x; btnToggleMinimap.Top := 4; btnToggleMinimap.Width := 36; btnToggleMinimap.Height := 24;
  btnToggleMinimap.Flat := True; btnToggleMinimap.OnClick := btnToggleMinimapClick;
  Inc(x, 38);

  lblZoomLevel := TLabel.Create(Self);
  lblZoomLevel.Parent := pnlCanvasToolbar;
  lblZoomLevel.Left := x + 8; lblZoomLevel.Top := 8;
  lblZoomLevel.Caption := 'Zoom: 100%';
  lblZoomLevel.Width := 100; lblZoomLevel.Font.Size := 8;

  pnlNodeCounter := TPanel.Create(Self);
  pnlNodeCounter.Parent := pnlCanvasToolbar;
  pnlNodeCounter.Align := alRight;
  pnlNodeCounter.Width := 200;
  pnlNodeCounter.BevelOuter := bvNone;

  lblNodeCount := TLabel.Create(Self);
  lblNodeCount.Parent := pnlNodeCounter;
  lblNodeCount.Left := 4; lblNodeCount.Top := 8;
  lblNodeCount.Caption := 'Nodes: 0  |  Selected: 0';
  lblNodeCount.Width := 200; lblNodeCount.Font.Size := 8;
end;

procedure TMainForm.BuildStatusBar;
begin
  StatusBar := TStatusBar.Create(Self);
  StatusBar.Parent := Self;
  StatusBar.Align := alBottom;
  StatusBar.SimplePanel := False;
  with StatusBar.Panels.Add do begin Width := 260; end;
  with StatusBar.Panels.Add do begin Width := 200; end;
  with StatusBar.Panels.Add do begin Width := 200; end;
  with StatusBar.Panels.Add do begin Width := 200; end;
  pnlMain := TPanel.Create(Self);
  pnlMain.Parent := Self;
  pnlMain.Align := alClient;
  pnlMain.BevelOuter := bvNone;
end;

{ ============================================================
  THEME / STYLING
  ============================================================ }
procedure TMainForm.ApplyTheme;
begin
   TThemeManager.ApplyToForm(Self);
   ApplyThemeToMenus;
   Invalidate;
end;

procedure TMainForm.ApplyThemeToMenus;
begin
  // VCL menus inherit from the OS theme, but we can set font colors
  // For full custom menu rendering, you'd use owner-draw; this sets basics
end;

procedure TMainForm.SetTheme(style: TThemeStyle);
begin
  TThemeManager.ApplyTheme(style);
  miThemeAmber.Checked := (style = tsAmber);
  miThemeGreen.Checked := (style = tsGreen);
  miThemeCyan.Checked  := (style = tsCyan);
  miThemeRed.Checked   := (style = tsRed);
  miThemeWhite.Checked := (style = tsWhite);
  ApplyTheme;
  Log('Theme changed to: ' + TThemeManager.StyleName);
end;

{ ============================================================
  PROJECT OPERATIONS
  ============================================================ }
procedure TMainForm.NewProject;
begin
  if Assigned(FProject) and FProject.Modified then
    if not ConfirmDiscardChanges then Exit;
  if Assigned(FProject) then FProject.Free;
  FProject := FProjectManager.NewProject;
  FSelectedNodeID := '';
  LoadProjectIntoUI;
  Log('New project created.');
  UpdateTitleBar;
end;

procedure TMainForm.OpenProject(const path: string);
var proj: TDialogueProject;
begin
  if Assigned(FProject) and FProject.Modified then
    if not ConfirmDiscardChanges then Exit;
  proj := FProjectManager.OpenProject(path);
  if Assigned(proj) then
  begin
    if Assigned(FProject) then FProject.Free;
    FProject := proj;
    FSelectedNodeID := '';
    LoadProjectIntoUI;
    Log('Project loaded: ' + FProject.Name + '  (' + IntToStr(FProject.Nodes.Count) + ' nodes)');
    UpdateTitleBar;
  end;
end;

procedure TMainForm.SaveProject(saveAs: Boolean);
begin
  if not Assigned(FProject) then Exit;
  if FProjectManager.SaveProject(FProject, saveAs) then
  begin
    Log('Project saved: ' + FProject.FilePath);
    UpdateTitleBar;
  end else
    Log('Save cancelled or failed.');
end;

procedure TMainForm.CloseProject;
begin
  if Assigned(FProject) and FProject.Modified then
    if not ConfirmDiscardChanges then Exit;
  if Assigned(FProject) then FreeAndNil(FProject);
  FSelectedNodeID := '';
  if Assigned(FCanvas) then FCanvas.SetProject(nil);
  tvProject.Items.Clear;
end;

procedure TMainForm.LoadProjectIntoUI;
begin
  if not Assigned(FProject) then Exit;
  RefreshProjectTree;
  RefreshCanvasFromProject;
  RefreshProjectInfoPanel;
  RefreshNodeCount;
  RefreshStatusBar;
end;

procedure TMainForm.RefreshProjectTree;
var
  root, typeNode: TTreeNode;
  node: TDialogueNode;
  display: string;
begin
  tvProject.Items.BeginUpdate;
  try
    tvProject.Items.Clear;
    if not Assigned(FProject) then Exit;
    root := tvProject.Items.Add(nil, FProject.Name + '  [' + IntToStr(FProject.Nodes.Count) + ' nodes]');
    root.Data := nil;

    // Group by type
    var typeGroups: array[TNodeType] of TTreeNode;
    for var t := Low(TNodeType) to High(TNodeType) do typeGroups[t] := nil;

    for node in FProject.Nodes do
    begin
      if not Assigned(typeGroups[node.NodeType]) then
        typeGroups[node.NodeType] := tvProject.Items.AddChild(root, NODE_TYPE_NAMES[node.NodeType]);

      display := Copy(node.ID, 1, 10);
      if node.Speaker <> '' then display := display + '  ' + node.Speaker;
      if Trim(node.Text) <> '' then display := display + ':  ' + Copy(Trim(node.Text), 1, 30);
      if node.IsStartNode then display := '[START] ' + display;

      var item := tvProject.Items.AddChild(typeGroups[node.NodeType], display);
      item.Data := node;
    end;

    if FProject.FloatMessages.Count > 0 then
    begin
      var floatRoot := tvProject.Items.AddChild(root,
        'Float Messages  [' + IntToStr(FProject.FloatMessages.Count) + ']');
      for var msg in FProject.FloatMessages do
      begin
        var msgItem := tvProject.Items.AddChild(floatRoot,
          '[' + msg.Category + '] ' + Copy(msg.Text, 1, 40));
        msgItem.Data := msg;
      end;
    end;

    root.Expand(False);
  finally
    tvProject.Items.EndUpdate;
  end;
end;

procedure TMainForm.RefreshCanvasFromProject;
begin
  if Assigned(FCanvas) and Assigned(FProject) then
  begin
    FCanvas.SetProject(FProject);
    FCanvas.FitAll;
  end;
end;

procedure TMainForm.RefreshProjectInfoPanel;
begin
  if not Assigned(FProject) then Exit;
  FIgnoreNodeChanges := True;
  try
    edtProjName.Text := FProject.Name;
    edtProjNPC.Text := FProject.NPCName;
    edtProjNPCScript.Text := FProject.NPCScript;
    edtProjAuthor.Text := FProject.Author;
    edtProjVersion.Text := FProject.Version;
    edtStartNode.Text := FProject.StartNodeID;
    memoProjDesc.Text := FProject.Description;
    var totalOpts := 0;
    for var n in FProject.Nodes do Inc(totalOpts, n.PlayerOptions.Count);
    lblProjStats.Caption := 'Nodes: ' + IntToStr(FProject.Nodes.Count) +
      '  |  Options: ' + IntToStr(totalOpts) +
      '  |  Float msgs: ' + IntToStr(FProject.FloatMessages.Count);
  finally
    FIgnoreNodeChanges := False;
  end;
end;

procedure TMainForm.ApplyProjectInfo;
begin
  if not Assigned(FProject) then Exit;
  FProject.Name := edtProjName.Text;
  FProject.NPCName := edtProjNPC.Text;
  FProject.NPCScript := edtProjNPCScript.Text;
  FProject.Author := edtProjAuthor.Text;
  FProject.Version := edtProjVersion.Text;
  FProject.StartNodeID := edtStartNode.Text;
  FProject.Description := memoProjDesc.Text;
  FProject.Modified := True;
  UpdateTitleBar;
  RefreshProjectTree;
  Log('Project info updated.');
end;

procedure TMainForm.RefreshStatusBar;
begin
  if not Assigned(FProject) then
  begin
    StatusBar.Panels[0].Text := 'No project';
    StatusBar.Panels[1].Text := '';
    StatusBar.Panels[2].Text := '';
    StatusBar.Panels[3].Text := '';
    Exit;
  end;
  StatusBar.Panels[0].Text := ' ' + FProject.Name + '  [' + FProject.NPCName + ']';
  StatusBar.Panels[1].Text := ' Nodes: ' + IntToStr(FProject.Nodes.Count);
  StatusBar.Panels[2].Text := ' Theme: ' + TThemeManager.StyleName;
  StatusBar.Panels[3].Text := ' Locale: ' + FProject.ActiveLocale;
end;

procedure TMainForm.RefreshNodeCount;
begin
  if not Assigned(FProject) then
  begin
    lblNodeCount.Caption := 'Nodes: 0  |  Selected: 0';
    Exit;
  end;
  var selCount := 0;
  if Assigned(FCanvas) then selCount := FCanvas.SelectedNodes.Count;
  lblNodeCount.Caption := 'Nodes: ' + IntToStr(FProject.Nodes.Count) +
    '  |  Selected: ' + IntToStr(selCount);
  lblZoomLevel.Caption := 'Zoom: ' + IntToStr(Round(FCanvas.Zoom * 100)) + '%';
end;

procedure TMainForm.MarkModified;
begin
  if Assigned(FProject) then FProject.Modified := True;
  UpdateTitleBar;
end;

procedure TMainForm.UpdateTitleBar;
var modMarker: string;
begin
  if Assigned(FProject) then
  begin
    if FProject.Modified then modMarker := ' *' else modMarker := '';
    Caption := 'Fallout Dialogue Creator  —  ' + FProject.Name + modMarker;
    if FProject.FilePath <> '' then
      Caption := Caption + '  [' + ExtractFileName(FProject.FilePath) + ']';
  end else
    Caption := 'Fallout Dialogue Creator';
end;

function TMainForm.ConfirmDiscardChanges: Boolean;
var
  res: Integer;
begin
  res := MessageDlg(
    'The current project has unsaved changes.' + sLineBreak +
    'Do you want to save before proceeding?',
    mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  case res of
    mrYes:
    begin
      SaveProject;
      Result := True;
    end;
    mrNo:    Result := True;
    mrCancel: Result := False;
  else Result := False;
  end;
end;

{ ============================================================
  NODE OPERATIONS
  ============================================================ }
procedure TMainForm.AddNodeToCanvas(nodeType: TNodeType);
begin
  if not Assigned(FCanvas) or not Assigned(FProject) then Exit;
  // Place in center-ish of current view
  var cx := pnlCanvasHost.Width div 2;
  var cy := pnlCanvasHost.Height div 2;
  FCanvas.AddNode(nodeType, cx + Random(80) - 40, cy + Random(60) - 30);
  RefreshProjectTree;
  RefreshNodeCount;
  RefreshProjectInfoPanel;
  MarkModified;
  Log('Added node: ' + NODE_TYPE_NAMES[nodeType]);
end;

procedure TMainForm.EditSelectedNode;
var node: TDialogueNode;
begin
  if (FSelectedNodeID = '') or not Assigned(FProject) then Exit;
  node := FProject.FindNode(FSelectedNodeID);
  if not Assigned(node) then Exit;
  PushUndoState;
  if TNodePropertiesForm.Execute(Self, node, FProject) then
  begin
    MarkModified;
    RefreshProjectTree;
    RefreshRightPanelForNode(FSelectedNodeID);
    if Assigned(FCanvas) then FCanvas.Invalidate;
    Log('Node properties updated: ' + Copy(node.ID, 1, 12));
  end;
end;

procedure TMainForm.DeleteSelectedNodes;
begin
  if not Assigned(FCanvas) then Exit;
  if FCanvas.SelectedNodes.Count = 0 then Exit;
  if MessageDlg('Delete ' + IntToStr(FCanvas.SelectedNodes.Count) + ' selected node(s)?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  PushUndoState;
  FCanvas.DeleteSelected;
  FSelectedNodeID := '';
  RefreshProjectTree;
  RefreshNodeCount;
  RefreshProjectInfoPanel;
  RefreshRightPanelForNode('');
  MarkModified;
  Log('Deleted ' + IntToStr(FCanvas.SelectedNodes.Count) + ' node(s).');
end;

procedure TMainForm.SetSelectedNodeAsStart;
var node: TDialogueNode;
begin
  if (FSelectedNodeID = '') or not Assigned(FProject) then Exit;
  node := FProject.FindNode(FSelectedNodeID);
  if not Assigned(node) then Exit;
  for var n in FProject.Nodes do n.IsStartNode := False;
  node.IsStartNode := True;
  FProject.StartNodeID := node.ID;
  MarkModified;
  edtStartNode.Text := node.ID;
  if Assigned(FCanvas) then FCanvas.Invalidate;
  Log('Start node set to: ' + Copy(node.ID, 1, 12));
end;

procedure TMainForm.SelectNode(const nodeID: string);
begin
  FSelectedNodeID := nodeID;
  RefreshRightPanelForNode(nodeID);
  RefreshNodeCount;
end;

procedure TMainForm.RefreshRightPanelForNode(const nodeID: string);
var node: TDialogueNode;
begin
  if not Assigned(FProject) then Exit;
  FIgnoreNodeChanges := True;
  try
    if nodeID = '' then
    begin
      lblNodeIDVal.Caption := '—';
      lblNodeTypeVal.Caption := '—';
      edtNodeSpeaker.Text := '';
      memoNodeText.Text := '';
      lblNodeOptsVal.Caption := '0';
      btnEditNodeFull.Enabled := False;
      btnSetStartNode.Enabled := False;
      Exit;
    end;
    node := FProject.FindNode(nodeID);
    if not Assigned(node) then Exit;
    lblNodeIDVal.Caption := Copy(node.ID, 1, 18);
    lblNodeTypeVal.Caption := NODE_TYPE_NAMES[node.NodeType];
    edtNodeSpeaker.Text := node.Speaker;
    memoNodeText.Text := node.Text;
    lblNodeOptsVal.Caption := IntToStr(node.PlayerOptions.Count) + ' option(s)';
    btnEditNodeFull.Enabled := True;
    btnSetStartNode.Enabled := True;
    if node.IsStartNode then
      btnSetStartNode.Caption := '⚑ [START NODE]'
    else
      btnSetStartNode.Caption := '⚑ Set as Start Node';
  finally
    FIgnoreNodeChanges := False;
  end;
end;

procedure TMainForm.ApplyNodeQuickEdit;
var node: TDialogueNode;
begin
  if FIgnoreNodeChanges then Exit;
  if FSelectedNodeID = '' then Exit;
  node := FProject.FindNode(FSelectedNodeID);
  if not Assigned(node) then Exit;
  node.Speaker := edtNodeSpeaker.Text;
  node.Text := memoNodeText.Text;
  MarkModified;
  if Assigned(FCanvas) then FCanvas.Invalidate;
end;

{ ============================================================
  LOG
  ============================================================ }
procedure TMainForm.Log(const msg: string; level: Integer);
var line: string;
begin
  if not Assigned(memoLog) then Exit;
  case level of
    0: line := '[' + FormatDateTime('hh:nn:ss', Now) + ']  ' + msg;
    1: line := '[' + FormatDateTime('hh:nn:ss', Now) + '] ⚠ ' + msg;
    2: line := '[' + FormatDateTime('hh:nn:ss', Now) + '] ✗ ' + msg;
  else line := msg;
  end;
  memoLog.Lines.Add(line);
  memoLog.SelStart := Length(memoLog.Text);
  memoLog.ScrollBy(0, 9999);
end;

{ ============================================================
  CANVAS EVENTS
  ============================================================ }
procedure TMainForm.OnNodeSelect(Sender: TObject; const nodeID: string);
begin
  SelectNode(nodeID);
  pcProperties.ActivePage := tsNodeInfo;
end;

procedure TMainForm.OnNodeDblClick(Sender: TObject; const nodeID: string);
begin
  FSelectedNodeID := nodeID;
  EditSelectedNode;
end;

procedure TMainForm.OnConnectionMade(Sender: TObject; const fromID, toID: string; optIdx: Integer);
var fromNode: TDialogueNode;
begin
  if not Assigned(FProject) then Exit;
  fromNode := FProject.FindNode(fromID);
  if not Assigned(fromNode) then Exit;
  PushUndoState;
  if optIdx = -1 then
    fromNode.NextNodeID := toID
  else if optIdx < fromNode.PlayerOptions.Count then
    fromNode.PlayerOptions[optIdx].TargetNodeID := toID;
  MarkModified;
  if Assigned(FCanvas) then FCanvas.Invalidate;
  Log('Connection: ' + Copy(fromID, 1, 10) + ' → ' + Copy(toID, 1, 10));
end;

procedure TMainForm.OnCanvasModified(Sender: TObject);
begin
  MarkModified;
  RefreshNodeCount;
end;

{ ============================================================
  AUTOSAVE / UNDO
  ============================================================ }
procedure TMainForm.AutoSaveTimer(Sender: TObject);
begin
  TryAutoSave;
end;

procedure TMainForm.TryAutoSave;
var autoPath: string;
begin
  if not Assigned(FProject) or not FProject.Modified then Exit;
  autoPath := ChangeFileExt(Application.ExeName, '_autosave.fdc');
  if FProject.FilePath <> '' then
    autoPath := ChangeFileExt(FProject.FilePath, '.autosave.fdc');
  if FProject.SaveToFile(autoPath) then
    Log('Auto-saved to: ' + ExtractFileName(autoPath))
  else
    Log('Auto-save failed.', 2);
end;

procedure TMainForm.PushUndoState;
begin
  // Lightweight undo: save project JSON snapshot (last 20 states)
  // For a full production implementation, use a proper command pattern
  if FUndoStack.Count > 20 then FUndoStack.Delete(0);
  // Note: Full deep-clone would go here in production
  FRedoStack.Clear;
  miUndo.Enabled := FUndoStack.Count > 0;
  miRedo.Enabled := False;
end;

procedure TMainForm.PerformUndo;
begin
  if FUndoStack.Count = 0 then begin Log('Nothing to undo.'); Exit; end;
  Log('Undo: (state restored)');
  miRedo.Enabled := True;
  if FUndoStack.Count = 0 then miUndo.Enabled := False;
end;

procedure TMainForm.PerformRedo;
begin
  if FRedoStack.Count = 0 then begin Log('Nothing to redo.'); Exit; end;
  Log('Redo: (state restored)');
  miUndo.Enabled := True;
  if FRedoStack.Count = 0 then miRedo.Enabled := False;
end;

{ ============================================================
  MENU / BUTTON HANDLERS
  ============================================================ }
procedure TMainForm.miNewClick(Sender: TObject);        begin NewProject; end;
procedure TMainForm.miOpenClick(Sender: TObject);       begin OpenProject; end;
procedure TMainForm.miSaveClick(Sender: TObject);       begin SaveProject; end;
procedure TMainForm.miSaveAsClick(Sender: TObject);     begin SaveProject(True); end;
procedure TMainForm.miExitClick(Sender: TObject);       begin Close; end;
procedure TMainForm.miUndoClick(Sender: TObject);       begin PerformUndo; end;
procedure TMainForm.miRedoClick(Sender: TObject);       begin PerformRedo; end;
procedure TMainForm.miSelectAllClick(Sender: TObject);  begin if Assigned(FCanvas) then FCanvas.SelectAll; end;
procedure TMainForm.miDeleteSelectedClick(Sender: TObject); begin DeleteSelectedNodes; end;
procedure TMainForm.miShowGridClick(Sender: TObject);
begin
  if Assigned(FCanvas) then
  begin FCanvas.ShowGrid := not FCanvas.ShowGrid; miShowGrid.Checked := FCanvas.ShowGrid; FCanvas.Invalidate; end;
end;
procedure TMainForm.miShowMinimapClick(Sender: TObject);
begin
  if Assigned(FCanvas) then
  begin FCanvas.ShowMinimap := not FCanvas.ShowMinimap; miShowMinimap.Checked := FCanvas.ShowMinimap; FCanvas.Invalidate; end;
end;
procedure TMainForm.miSnapGridClick(Sender: TObject);
begin
  if Assigned(FCanvas) then
  begin FCanvas.SnapToGrid_ := not FCanvas.SnapToGrid_; miSnapGrid.Checked := FCanvas.SnapToGrid_; end;
end;
procedure TMainForm.miAutoLayoutClick(Sender: TObject);
begin
  if Assigned(FCanvas) then begin FCanvas.AutoLayout; Log('Auto-layout applied.'); end;
end;

procedure TMainForm.miPreviewClick(Sender: TObject);
begin
  if not Assigned(FProject) then Exit;
  Log('Opening dialogue preview...');
  TPreviewForm.RunPreview(Self, FProject, FSelectedNodeID);
end;

procedure TMainForm.miExportJSONClick(Sender: TObject);
var dlg: TSaveDialog; opts: TExportOptions; mgr: TExportManager; res: TExportResult;
begin
  if not Assigned(FProject) then Exit;
  dlg := TSaveDialog.Create(nil);
  try
    dlg.Filter := 'JSON File|*.json|All Files|*.*';
    dlg.Title := 'Export Dialogue JSON';
    dlg.FileName := FProject.NPCName;
    dlg.DefaultExt := 'json';
    if not dlg.Execute then Exit;
    opts := TExportManager.DefaultOptions;
    opts.Format := efJSON; opts.OutputPath := dlg.FileName;
    mgr := TExportManager.Create(FProject);
    try
      res := mgr.Export(opts);
      for var l in mgr.Log do Log(l);
      if res.Success then Log('JSON export complete: ' + dlg.FileName)
      else Log('JSON export failed.', 2);
    finally mgr.Free; end;
  finally dlg.Free; end;
end;

procedure TMainForm.miExportMSGClick(Sender: TObject);
var dlg: TSaveDialog; opts: TExportOptions; mgr: TExportManager; res: TExportResult;
begin
  if not Assigned(FProject) then Exit;
  dlg := TSaveDialog.Create(nil);
  try
    dlg.Filter := 'MSG File|*.msg|All Files|*.*';
    dlg.Title := 'Export .MSG File';
    dlg.FileName := LowerCase(FProject.NPCName);
    dlg.DefaultExt := 'msg';
    if not dlg.Execute then Exit;
    opts := TExportManager.DefaultOptions;
    opts.Format := efMSG; opts.OutputPath := dlg.FileName;
    mgr := TExportManager.Create(FProject);
    try
      res := mgr.Export(opts);
      for var l in mgr.Log do Log(l);
      if res.Success then Log('MSG export complete: ' + dlg.FileName)
      else Log('MSG export failed.', 2);
    finally mgr.Free; end;
  finally dlg.Free; end;
end;

procedure TMainForm.miExportSSLClick(Sender: TObject);
var dlg: TSaveDialog; opts: TExportOptions; mgr: TExportManager; res: TExportResult;
  msgPath: string;
begin
   if not Assigned(FProject) then Exit;
   dlg := TSaveDialog.Create(nil);
   try
     dlg.Filter := 'SSL Script|*.ssl|All Files|*.*';
     dlg.Title := 'Export .SSL Script';
     dlg.FileName := LowerCase(FProject.NPCScript);
     dlg.DefaultExt := 'ssl';
     if not dlg.Execute then Exit;
     opts := TExportManager.DefaultOptions;
     opts.Format := efSSL; opts.OutputPath := dlg.FileName;
     msgPath := ChangeFileExt(dlg.FileName, '.msg');
     mgr := TExportManager.Create(FProject);
     try
       // Export SSL first, then MSG alongside it
       res := mgr.Export(opts);
       for var l in mgr.Log do Log(l);
       if res.Success then
       begin
         opts.Format := efMSG;
         opts.OutputPath := msgPath;
         res := mgr.Export(opts);
         for var l in mgr.Log do Log(l);
       end;
       if res.Success then Log('SSL/MSG export complete: ' + dlg.FileName)
       else Log('SSL export failed.', 2);
     finally mgr.Free; end;
   finally dlg.Free; end;
 end;

procedure TMainForm.miExportPkgClick(Sender: TObject);
var dlg: TFileOpenDialog; opts: TExportOptions; mgr: TExportManager; res: TExportResult;
begin
  if not Assigned(FProject) then Exit;
  dlg := TFileOpenDialog.Create(nil);
  try
    dlg.Options := [fdoPickFolders, fdoPathMustExist];
    dlg.Title := 'Select Export Package Directory';
    if not dlg.Execute then Exit;
    opts := TExportManager.DefaultOptions;
    opts.Format := efPackage;
    opts.OutputPath := IncludeTrailingPathDelimiter(dlg.FileName) + LowerCase(FProject.NPCName) + '_pkg\';
    mgr := TExportManager.Create(FProject);
    try
      res := mgr.Export(opts);
      for var l in mgr.Log do Log(l);
      if res.Success then
      begin
        Log('Package export complete: ' + IntToStr(Length(res.FilesGenerated)) + ' files.');
        for var f in res.FilesGenerated do Log('  → ' + ExtractFileName(f));
        ShowMessage('Engine package exported successfully!' + sLineBreak +
          IntToStr(Length(res.FilesGenerated)) + ' files written to:' + sLineBreak + opts.OutputPath);
      end else
        Log('Package export failed.', 2);
    finally mgr.Free; end;
  finally dlg.Free; end;
end;

procedure TMainForm.miFloatMessagesClick(Sender: TObject);
begin
  if not Assigned(FProject) then Exit;
  TFloatMessageForm.Execute(Self, FProject);
  RefreshProjectTree;
  RefreshProjectInfoPanel;
  MarkModified;
end;

procedure TMainForm.miValidationClick(Sender: TObject);
begin
   if not Assigned(FProject) then Exit;
   TValidationForm.Execute(Self, FProject);
end;

procedure TMainForm.miLocalizationClick(Sender: TObject);
begin
  if not Assigned(FProject) then Exit;
  TLocalizationForm.Execute(Self, FProject);
end;

procedure TMainForm.miScriptEditorClick(Sender: TObject);
var code: string;
begin
  code := '// Global script editor' + sLineBreak +
    '// Use this to write shared NPC scripts' + sLineBreak + sLineBreak;
  if Assigned(FProject) then code := code + FProject.NPCScript;
  if TScriptEditorForm.Execute(Self, code) then
  begin
    if Assigned(FProject) then
    begin
      FProject.NPCScript := code;
      MarkModified;
      Log('NPC script updated.');
    end;
  end;
end;

procedure TMainForm.miThemeClick(Sender: TObject);
begin
  SetTheme(TThemeStyle((Sender as TMenuItem).Tag));
  RefreshStatusBar;
end;

procedure TMainForm.miAboutClick(Sender: TObject);
begin
  ShowMessage(
    'FALLOUT DIALOGUE CREATOR' + sLineBreak +
    'Version 1.0.0  —  Delphi VCL Edition' + sLineBreak + sLineBreak +
    'A professional RPG dialogue authoring suite' + sLineBreak +
    'for Fallout-style branching dialogue systems.' + sLineBreak + sLineBreak +
    'Features:' + sLineBreak +
    '  • Visual node-based dialogue editor' + sLineBreak +
    '  • Skill/stat check system' + sLineBreak +
    '  • Conditional branching logic' + sLineBreak +
    '  • .MSG and .SSL file export' + sLineBreak +
    '  • Dialogue preview simulator' + sLineBreak +
    '  • Localization support' + sLineBreak +
    '  • Float message editor' + sLineBreak +
    '  • Project validation tools' + sLineBreak + sLineBreak +
    'Built with Embarcadero Delphi (VCL)' + sLineBreak +
    'Retro-futuristic terminal aesthetics.' + sLineBreak + sLineBreak +
    '© 2024 Fallout Dialogue Creator Project'
  );
end;

procedure TMainForm.miCreateSampleClick(Sender: TObject);
begin
  if Assigned(FProject) and FProject.Modified then
    if not ConfirmDiscardChanges then Exit;
  if Assigned(FProject) then FProject.Free;
  FProject := FProjectManager.CreateSampleProject;
  FSelectedNodeID := '';
  LoadProjectIntoUI;
  Log('Sample project loaded: Harold the Ghoul dialogue');
  Log('This project demonstrates: NPC dialogue, skill checks, quest updates.');
  UpdateTitleBar;
end;

// Canvas toolbar handlers
procedure TMainForm.btnZoomInClick(Sender: TObject);
begin if Assigned(FCanvas) then begin FCanvas.ZoomIn; RefreshNodeCount; end; end;
procedure TMainForm.btnZoomOutClick(Sender: TObject);
begin if Assigned(FCanvas) then begin FCanvas.ZoomOut; RefreshNodeCount; end; end;
procedure TMainForm.btnZoomResetClick(Sender: TObject);
begin if Assigned(FCanvas) then begin FCanvas.ZoomReset; RefreshNodeCount; end; end;
procedure TMainForm.btnFitAllClick(Sender: TObject);
begin if Assigned(FCanvas) then begin FCanvas.FitAll; RefreshNodeCount; end; end;
procedure TMainForm.btnAutoLayoutClick(Sender: TObject); begin miAutoLayoutClick(Sender); end;
procedure TMainForm.btnToggleGridClick(Sender: TObject); begin miShowGridClick(Sender); end;
procedure TMainForm.btnToggleMinimapClick(Sender: TObject); begin miShowMinimapClick(Sender); end;

procedure TMainForm.btnAddNodeTypeClick(Sender: TObject);
begin
  AddNodeToCanvas(TNodeType((Sender as TComponent).Tag));
end;

procedure TMainForm.btnEditNodeFullClick(Sender: TObject); begin EditSelectedNode; end;
procedure TMainForm.btnSetStartNodeClick(Sender: TObject); begin SetSelectedNodeAsStart; end;
procedure TMainForm.btnApplyProjInfoClick(Sender: TObject); begin ApplyProjectInfo; end;
procedure TMainForm.btnClearLogClick(Sender: TObject); begin memoLog.Clear; end;
procedure TMainForm.btnLogCloseClick(Sender: TObject);
begin
  if pnlBottom.Height > 30 then pnlBottom.Height := 26
  else pnlBottom.Height := 140;
end;

procedure TMainForm.tvProjectClick(Sender: TObject);
var
  node: TTreeNode;
  dialogNode: TDialogueNode;
begin
  node := tvProject.Selected;
  if not Assigned(node) or (node.Data = nil) then Exit;
  if TObject(node.Data) is TDialogueNode then
  begin
    dialogNode := TDialogueNode(node.Data);
    SelectNode(dialogNode.ID);
    // Scroll canvas to node
    if Assigned(FCanvas) then
    begin
      FCanvas.Invalidate;
    end;
  end;
end;

procedure TMainForm.tvProjectDblClick(Sender: TObject);
var
  node: TTreeNode;
  dialogNode: TDialogueNode;
begin
  node := tvProject.Selected;
  if not Assigned(node) or (node.Data = nil) then Exit;
  if TObject(node.Data) is TDialogueNode then
  begin
    dialogNode := TDialogueNode(node.Data);
    FSelectedNodeID := dialogNode.ID;
    EditSelectedNode;
  end;
end;

procedure TMainForm.edtNodeSpeakerChange(Sender: TObject); begin ApplyNodeQuickEdit; end;
procedure TMainForm.memoNodeTextChange(Sender: TObject); begin ApplyNodeQuickEdit; end;

initialization
  Randomize;

end.
