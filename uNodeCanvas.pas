unit uNodeCanvas;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Menus, Vcl.Dialogs,
  Winapi.Windows, Winapi.Messages,
  Vcl.Graphics,
  uDialogueTypes, uThemeManager;

type
  TCanvasConnection = record
    FromNodeID: string;
    ToNodeID: string;
    Label_: string;
    OptionIndex: Integer;  // -1 = direct link, else option index
    Color: TColor;
    IsSkillSuccess: Boolean;
    IsSkillFail: Boolean;
  end;

  TNodeCanvasAction = (ncaNone, ncaDragging, ncaConnecting, ncaSelecting, ncaPanning);

  TNodeSelectEvent = procedure(Sender: TObject; const NodeID: string) of object;
  TNodeDoubleClickEvent = procedure(Sender: TObject; const NodeID: string) of object;
  TConnectionEvent = procedure(Sender: TObject; const FromID, ToID: string; optIdx: Integer) of object;

  TNodeCanvas = class(TCustomControl)
  private
    FProject: TDialogueProject;
    FOffsetX, FOffsetY: Integer;
    FZoom: Single;
    FAction: TNodeCanvasAction;
    FMouseStart: TPoint;
    FDragNode: TDialogueNode;
    FDragStartX, FDragStartY: Integer;
    FSelecting: Boolean;
    FSelectRect: TRect;
    FSelectedNodes: TList<TDialogueNode>;
    FConnectFrom: TDialogueNode;
FConnectFromOpt: Integer;
     FLastMousePos: TPoint;
     FShowGrid: Boolean;
     FSnapToGrid: Boolean;
     FGridSize: Integer;
     FShowMinimap: Boolean;
     FPopupMenu: TPopupMenu;
     FRightClickNode: TDialogueNode;
     FOnNodeSelect: TNodeSelectEvent;
     FOnNodeDblClick: TNodeDoubleClickEvent;
     FOnConnectionMade: TConnectionEvent;
     FOnModified: TNotifyEvent;
     FBuffer: TBitmap;

     procedure DrawBackground;
     procedure DrawGrid;
     procedure DrawConnections;
     procedure DrawNodes;
     procedure DrawNode(node: TDialogueNode);
     procedure DrawNodeHeader(node: TDialogueNode; const r: TRect; headerColor: TColor);
     procedure DrawNodeBody(node: TDialogueNode; const r: TRect);
     procedure DrawNodePorts(node: TDialogueNode; const r: TRect);
     procedure DrawMinimap;
     procedure DrawSelectionRect;
     procedure DrawArrow(x1, y1, x2, y2: Integer; color: TColor; curved: Boolean);
     procedure DrawGlowRect(const r: TRect; color: TColor; glowSize: Integer);
     procedure DrawScanlines;
function WorldToScreen(x, y: Integer): TPoint;
      function ScreenToWorld(x, y: Integer): TPoint;
      function NodeAtPoint(pt: TPoint): TDialogueNode;
      function SnapToGrid(val: Integer): Integer;
      procedure BuildPopupMenu;
      procedure MenuAddNPCClick(Sender: TObject);
      procedure MenuAddPlayerClick(Sender: TObject);
     procedure MenuAddConditionalClick(Sender: TObject);
     procedure MenuAddScriptClick(Sender: TObject);
     procedure MenuAddEndClick(Sender: TObject);
     procedure MenuAddCommentClick(Sender: TObject);
     procedure MenuDeleteNodeClick(Sender: TObject);
     procedure MenuSetStartClick(Sender: TObject);
     procedure MenuPropertiesClick(Sender: TObject);
     procedure MouseWheelHandler(var Message: TMessage); override;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetProject(proj: TDialogueProject);
    procedure Refresh; reintroduce;
    procedure CenterView;
    procedure FitAll;
    procedure ZoomIn;
    procedure ZoomOut;
    procedure ZoomReset;
    procedure SelectAll;
    procedure DeleteSelected;
procedure AddNode(nodeType: TNodeType; x, y: Integer);
     procedure AutoLayout;
     procedure RebuildBuffer;
     function GetNodeRect(node: TDialogueNode): TRect;
     property ShowGrid: Boolean read FShowGrid write FShowGrid;
     property SnapToGrid_: Boolean read FSnapToGrid write FSnapToGrid;
     property GridSize: Integer read FGridSize write FGridSize;
     property ShowMinimap: Boolean read FShowMinimap write FShowMinimap;
     property Zoom: Single read FZoom;
     property SelectedNodes: TList<TDialogueNode> read FSelectedNodes;
     property OnNodeSelect: TNodeSelectEvent read FOnNodeSelect write FOnNodeSelect;
     property OnNodeDblClick: TNodeDoubleClickEvent read FOnNodeDblClick write FOnNodeDblClick;
     property OnConnectionMade: TConnectionEvent read FOnConnectionMade write FOnConnectionMade;
     property OnModified: TNotifyEvent read FOnModified write FOnModified;
   end;

implementation

uses
  System.Math;

const
  PORT_RADIUS = 7;
  HEADER_HEIGHT = 28;
  NODE_CORNER = 6;
  MIN_ZOOM = 0.15;
  MAX_ZOOM = 3.0;
  MINIMAP_W = 180;
  MINIMAP_H = 120;
  MINIMAP_MARGIN = 10;

{ TNodeCanvas }

constructor TNodeCanvas.Create(AOwner: TComponent);
begin
  inherited;
  FZoom := 1.0;
  FOffsetX := 0;
  FOffsetY := 0;
  FShowGrid := True;
  FSnapToGrid := True;
  FGridSize := 20;
  FShowMinimap := True;
  FSelectedNodes := TList<TDialogueNode>.Create;
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;
  TabStop := True;
  DoubleBuffered := True;
  BuildPopupMenu;
end;

destructor TNodeCanvas.Destroy;
begin
  FSelectedNodes.Free;
  FBuffer.Free;
  FPopupMenu.Free;
  inherited;
end;

procedure TNodeCanvas.SetProject(proj: TDialogueProject);
begin
  FProject := proj;
  FSelectedNodes.Clear;
  FDragNode := nil;
  CenterView;
  RebuildBuffer;
  Invalidate;
end;

procedure TNodeCanvas.RebuildBuffer;
begin
  if Width <= 0 then Exit;
  FBuffer.Width := Width;
  FBuffer.Height := Height;
end;

procedure TNodeCanvas.Refresh;
begin
  Invalidate;
end;

procedure TNodeCanvas.CenterView;
begin
  FOffsetX := Width div 2;
  FOffsetY := Height div 2;
  FZoom := 1.0;
  Invalidate;
end;

procedure TNodeCanvas.FitAll;
var
   minX, minY, maxX, maxY: Integer;
   margin: Integer;
   scaleX, scaleY: Single;
   i: Integer;
 begin
   if not Assigned(FProject) or (FProject.Nodes.Count = 0) then
   begin
     CenterView;
     Exit;
   end;
   margin := 40;
   minX := MaxInt; minY := MaxInt;
   maxX := Low(Integer); maxY := Low(Integer);
   for i := 0 to FProject.Nodes.Count - 1 do
   begin
     minX := Min(minX, FProject.Nodes[i].X);
     minY := Min(minY, FProject.Nodes[i].Y);
     maxX := Max(maxX, FProject.Nodes[i].X + FProject.Nodes[i].Width);
     maxY := Max(maxY, FProject.Nodes[i].Y + FProject.Nodes[i].Height);
   end;
   if (maxX <= minX) or (maxY <= minY) then Exit;
   scaleX := (Width - margin * 2) / (maxX - minX);
   scaleY := (Height - margin * 2) / (maxY - minY);
   FZoom := Min(scaleX, scaleY);
   FZoom := Max(MIN_ZOOM, Min(MAX_ZOOM, FZoom));
   FOffsetX := Round(margin - minX * FZoom);
   FOffsetY := Round(margin - minY * FZoom);
   Invalidate;
end;

procedure TNodeCanvas.ZoomIn;
begin
  FZoom := Min(FZoom * 1.2, MAX_ZOOM);
  Invalidate;
end;

procedure TNodeCanvas.ZoomOut;
begin
  FZoom := Max(FZoom / 1.2, MIN_ZOOM);
  Invalidate;
end;

procedure TNodeCanvas.ZoomReset;
begin
  FZoom := 1.0;
  Invalidate;
end;

function TNodeCanvas.WorldToScreen(x, y: Integer): TPoint;
begin
  Result.X := Round(x * FZoom) + FOffsetX;
  Result.Y := Round(y * FZoom) + FOffsetY;
end;

function TNodeCanvas.ScreenToWorld(x, y: Integer): TPoint;
begin
  if FZoom <> 0 then
  begin
    Result.X := Round((x - FOffsetX) / FZoom);
    Result.Y := Round((y - FOffsetY) / FZoom);
  end else
  begin
    Result.X := x;
    Result.Y := y;
  end;
end;

function TNodeCanvas.SnapToGrid(val: Integer): Integer;
begin
  if FSnapToGrid then
    Result := (val div FGridSize) * FGridSize
  else
    Result := val;
end;

function TNodeCanvas.GetNodeRect(node: TDialogueNode): TRect;
var
  sp: TPoint;
begin
  sp := WorldToScreen(node.X, node.Y);
  Result := Rect(sp.X, sp.Y,
    sp.X + Round(node.Width * FZoom),
    sp.Y + Round(node.Height * FZoom));
end;

function TNodeCanvas.NodeAtPoint(pt: TPoint): TDialogueNode;
var
  node: TDialogueNode;
  nr: TRect;
  i: Integer;
begin
  Result := nil;
  if not Assigned(FProject) then Exit;
  // Search in reverse (top nodes first visually)
  for i := FProject.Nodes.Count - 1 downto 0 do
  begin
    node := FProject.Nodes[i];
    nr := GetNodeRect(node);
    if PtInRect(nr, pt) then
    begin
      Result := node;
      Exit;
    end;
  end;
end;

procedure TNodeCanvas.Paint;
var
  nr: TRect;
  sx, sy: Integer;
begin
  if Width > FBuffer.Width then RebuildBuffer;
  if Height > FBuffer.Height then RebuildBuffer;

  FBuffer.Width := Width;
  FBuffer.Height := Height;

  DrawBackground;
  if FShowGrid then DrawGrid;
  if Assigned(FProject) then
  begin
    DrawConnections;
    DrawNodes;
  end;
  DrawScanlines;
  if FShowMinimap then DrawMinimap;
  if FSelecting then DrawSelectionRect;

  // Draw connecting line in progress
  if FAction = ncaConnecting then
  begin
    nr := GetNodeRect(FConnectFrom);
    sx := nr.Right;
    sy := (nr.Top + nr.Bottom) div 2;
    FBuffer.Canvas.Pen.Color := TThemeManager.Current.AccentPrimary;
    FBuffer.Canvas.Pen.Width := 2;
    FBuffer.Canvas.Pen.Style := psDash;
    FBuffer.Canvas.MoveTo(sx, sy);
    FBuffer.Canvas.LineTo(FLastMousePos.X, FLastMousePos.Y);
  end;

  Canvas.Draw(0, 0, FBuffer);
end;

procedure TNodeCanvas.DrawBackground;
begin
  FBuffer.Canvas.Brush.Color := TThemeManager.Current.CanvasBg;
  FBuffer.Canvas.FillRect(Rect(0, 0, Width, Height));
end;

procedure TNodeCanvas.DrawGrid;
var
  startX, startY, x, y: Integer;
  gridStep: Integer;
  c1, c2: TColor;
begin
  c1 := TThemeManager.Current.GridColor;
  c2 := TColor(Integer(c1) + $050505);
  gridStep := Round(FGridSize * FZoom);
  if gridStep < 4 then Exit;

  FBuffer.Canvas.Pen.Style := psSolid;

  startX := FOffsetX mod gridStep;
  if startX < 0 then Inc(startX, gridStep);
  startY := FOffsetY mod gridStep;
  if startY < 0 then Inc(startY, gridStep);

  x := startX;
  while x < Width do
  begin
    // Major grid every 5
    if ((x - startX) div gridStep) mod 5 = 0 then
      FBuffer.Canvas.Pen.Color := c2
    else
      FBuffer.Canvas.Pen.Color := c1;
    FBuffer.Canvas.Pen.Width := 1;
    FBuffer.Canvas.MoveTo(x, 0);
    FBuffer.Canvas.LineTo(x, Height);
    Inc(x, gridStep);
  end;
  y := startY;
  while y < Height do
  begin
    if ((y - startY) div gridStep) mod 5 = 0 then
      FBuffer.Canvas.Pen.Color := c2
    else
      FBuffer.Canvas.Pen.Color := c1;
    FBuffer.Canvas.MoveTo(0, y);
    FBuffer.Canvas.LineTo(Width, y);
    Inc(y, gridStep);
  end;
end;

procedure TNodeCanvas.DrawConnections;
var
  node: TDialogueNode;
  opt: TPlayerOption;
  targetNode: TDialogueNode;
  nr, tr: TRect;
  sx, sy, tx, ty: Integer;
  i, j: Integer;
begin
  if not Assigned(FProject) then Exit;

  for i := 0 to FProject.Nodes.Count - 1 do
  begin
    node := FProject.Nodes[i];
    nr := GetNodeRect(node);
    sx := nr.Right;
    sy := (nr.Top + nr.Bottom) div 2;

    // Direct next node link
    if node.NextNodeID <> '' then
    begin
      targetNode := FProject.FindNode(node.NextNodeID);
      if Assigned(targetNode) then
      begin
        tr := GetNodeRect(targetNode);
        tx := tr.Left;
        ty := (tr.Top + tr.Bottom) div 2;
        DrawArrow(sx, sy, tx, ty, TThemeManager.Current.AccentSecondary, True);
      end;
    end;

    // Option links
    for j := 0 to node.PlayerOptions.Count - 1 do
    begin
      opt := node.PlayerOptions[j];
      sy := nr.Top + Round(HEADER_HEIGHT * FZoom) + i * Round(22 * FZoom) + Round(11 * FZoom);

      if opt.TargetNodeID <> '' then
      begin
        targetNode := FProject.FindNode(opt.TargetNodeID);
        if Assigned(targetNode) then
        begin
          tr := GetNodeRect(targetNode);
          tx := tr.Left;
          ty := (tr.Top + tr.Bottom) div 2;
          DrawArrow(sx, sy, tx, ty, TThemeManager.Current.AccentPrimary, True);
        end;
      end;

      if opt.HasSkillCheck then
      begin
        if opt.SkillCheck.SuccessNodeID <> '' then
        begin
          targetNode := FProject.FindNode(opt.SkillCheck.SuccessNodeID);
          if Assigned(targetNode) then
          begin
            tr := GetNodeRect(targetNode);
            DrawArrow(sx, sy, tr.Left, (tr.Top + tr.Bottom) div 2,
              TThemeManager.Current.ColorSuccess, True);
          end;
        end;
        if opt.SkillCheck.FailureNodeID <> '' then
        begin
          targetNode := FProject.FindNode(opt.SkillCheck.FailureNodeID);
          if Assigned(targetNode) then
          begin
            tr := GetNodeRect(targetNode);
            DrawArrow(sx, sy, tr.Left, (tr.Top + tr.Bottom) div 2,
              TThemeManager.Current.ColorError, True);
          end;
        end;
      end;
    end;
  end;
end;

procedure TNodeCanvas.DrawArrow(x1, y1, x2, y2: Integer; color: TColor; curved: Boolean);
var
  dx, dy: Integer;
  cx1, cy1, cx2, cy2: Integer;
  len: Single;
  angle, arrowLen: Single;
  ax1, ay1, ax2, ay2: Integer;
  endX, endY: Integer;
  prevX, prevY, nx, ny: Integer;
  t: Integer;
  f: Single;
  pts: array[0..2] of TPoint;
begin
  FBuffer.Canvas.Pen.Color := color;
  FBuffer.Canvas.Pen.Width := Max(1, Round(FZoom * 1.5));
  FBuffer.Canvas.Pen.Style := psSolid;

  if curved then
  begin
    dx := (x2 - x1) div 2;
    cx1 := x1 + Abs(dx);
    cy1 := y1;
    cx2 := x2 - Abs(dx);
    cy2 := y2;

    // Draw bezier approximation with line segments
    prevX := x1;
    prevY := y1;
    for t := 1 to 20 do
    begin
      f := t / 20.0;
      nx := Round((1-f)*(1-f)*(1-f)*x1 + 3*(1-f)*(1-f)*f*cx1 + 3*(1-f)*f*f*cx2 + f*f*f*x2);
      ny := Round((1-f)*(1-f)*(1-f)*y1 + 3*(1-f)*(1-f)*f*cy1 + 3*(1-f)*f*f*cy2 + f*f*f*y2);
      FBuffer.Canvas.MoveTo(prevX, prevY);
      FBuffer.Canvas.LineTo(nx, ny);
      prevX := nx;
      prevY := ny;
    end;
    endX := x2; endY := y2;
  end else
  begin
    FBuffer.Canvas.MoveTo(x1, y1);
    FBuffer.Canvas.LineTo(x2, y2);
    endX := x2; endY := y2;
  end;

  // Arrowhead
  dx := x2 - x1;
  dy := y2 - y1;
  len := Sqrt(dx * dx + dy * dy);
  if len > 0 then
  begin
    arrowLen := Max(6.0, 12.0 * FZoom);
    angle := ArcTan2(dy, dx);
    ax1 := Round(endX - arrowLen * Cos(angle - 0.5));
    ay1 := Round(endY - arrowLen * Sin(angle - 0.5));
    ax2 := Round(endX - arrowLen * Cos(angle + 0.5));
    ay2 := Round(endY - arrowLen * Sin(angle + 0.5));
    FBuffer.Canvas.Brush.Color := color;
    FBuffer.Canvas.Pen.Color := color;
    pts[0] := Point(endX, endY);
    pts[1] := Point(ax1, ay1);
    pts[2] := Point(ax2, ay2);
    FBuffer.Canvas.Polygon(pts);
  end;
end;

procedure TNodeCanvas.DrawGlowRect(const r: TRect; color: TColor; glowSize: Integer);
var
  i: Integer;
  alpha: Integer;
  c: TColor;
begin
  for i := glowSize downto 1 do
  begin
    alpha := Round(80 * (i / glowSize));
    // Mix with background
    c := TColor(
      ((GetBValue(color) * alpha + GetBValue(TThemeManager.Current.CanvasBg) * (255 - alpha)) div 255) shl 16 or
      ((GetGValue(color) * alpha + GetGValue(TThemeManager.Current.CanvasBg) * (255 - alpha)) div 255) shl 8 or
      ((GetRValue(color) * alpha + GetRValue(TThemeManager.Current.CanvasBg) * (255 - alpha)) div 255)
    );
    FBuffer.Canvas.Pen.Color := c;
    FBuffer.Canvas.Pen.Width := 1;
    FBuffer.Canvas.Brush.Style := bsClear;
    FBuffer.Canvas.RoundRect(r.Left - i, r.Top - i, r.Right + i, r.Bottom + i,
      NODE_CORNER + i, NODE_CORNER + i);
  end;
end;

procedure TNodeCanvas.DrawNodes;
var
  node: TDialogueNode;
  i: Integer;
begin
  // Draw deselected first, then selected on top
  for i := 0 to FProject.Nodes.Count - 1 do
  begin
    node := FProject.Nodes[i];
    if not node.Selected then
      DrawNode(node);
  end;
  for i := 0 to FProject.Nodes.Count - 1 do
  begin
    node := FProject.Nodes[i];
    if node.Selected then
      DrawNode(node);
  end;
end;

procedure TNodeCanvas.DrawNode(node: TDialogueNode);
var
   r: TRect;
   bodyColor, headerColor: TColor;
   badgeR: TRect;
begin
   r := GetNodeRect(node);
   if (r.Right < -20) or (r.Left > Width + 20) or
      (r.Bottom < -20) or (r.Top > Height + 20) then
     Exit;  // Off screen culling

   // Use theme-aware colors for node body and header
  bodyColor := TThemeManager.Current.BgMedium;
  headerColor := TThemeManager.Current.BgLight;

  // Glow for selected or start node
  if node.Selected then
    DrawGlowRect(r, TThemeManager.Current.AccentPrimary, 4)
  else if node.IsStartNode then
    DrawGlowRect(r, TThemeManager.Current.ColorSuccess, 3);

  // Node shadow
  FBuffer.Canvas.Brush.Color := $00000000;
  FBuffer.Canvas.Pen.Style := psClear;
  FBuffer.Canvas.RoundRect(r.Left + 3, r.Top + 4, r.Right + 3, r.Bottom + 4, NODE_CORNER, NODE_CORNER);

  // Node body background — use theme BgMedium
  FBuffer.Canvas.Brush.Color := bodyColor;
  FBuffer.Canvas.Pen.Color := if node.Selected then TThemeManager.Current.AccentPrimary else TThemeManager.Current.BorderDark;
  FBuffer.Canvas.Pen.Width := if node.Selected then 2 else 1;
  FBuffer.Canvas.Pen.Style := psSolid;
  FBuffer.Canvas.RoundRect(r.Left, r.Top, r.Right, r.Bottom, NODE_CORNER, NODE_CORNER);

  DrawNodeHeader(node, r, headerColor);
  DrawNodeBody(node, r);
  DrawNodePorts(node, r);

  // Start node badge
  if node.IsStartNode then
  begin
    FBuffer.Canvas.Brush.Color := TThemeManager.Current.ColorSuccess;
    FBuffer.Canvas.Pen.Style := psClear;
    FBuffer.Canvas.Font.Size := Max(6, Round(7 * FZoom));
    FBuffer.Canvas.Font.Name := 'Segoe UI';
    FBuffer.Canvas.Font.Color := TThemeManager.Current.BgDark;
    FBuffer.Canvas.Font.Style := [fsBold];
    badgeR := Rect(r.Left + 2, r.Top + 2, r.Left + Round(40 * FZoom), r.Top + Round(14 * FZoom));
    FBuffer.Canvas.RoundRect(badgeR.Left, badgeR.Top, badgeR.Right, badgeR.Bottom, 3, 3);
    FBuffer.Canvas.TextRect(badgeR, (badgeR.Left + badgeR.Right) div 2, (badgeR.Top + badgeR.Bottom) div 2, 'START');
    FBuffer.Canvas.Font.Style := [];
  end;
end;

procedure TNodeCanvas.DrawNodeHeader(node: TDialogueNode; const r: TRect; headerColor: TColor);
var
   headerR: TRect;
   accent: TColor;
   title: string;
   markerSize: Integer;
 begin
   accent := NODE_ACCENT_COLORS[node.NodeType];
   headerR := Rect(r.Left + 1, r.Top + 1, r.Right - 1, r.Top + Round(HEADER_HEIGHT * FZoom));

   // Header background using theme color
   FBuffer.Canvas.Brush.Color := headerColor;
   FBuffer.Canvas.Pen.Style := psClear;
   FBuffer.Canvas.FillRect(headerR);

   // Accent border on top of header
   FBuffer.Canvas.Brush.Color := accent;
   FBuffer.Canvas.FillRect(Rect(r.Left + 1, r.Top + 1, r.Right - 1, r.Top + Max(2, Round(3 * FZoom))));

  // Node type icon marker
  markerSize := Round(8 * FZoom);
  FBuffer.Canvas.Brush.Color := accent;
  FBuffer.Canvas.Pen.Style := psClear;
  FBuffer.Canvas.Ellipse(
    r.Left + 6,
    headerR.Top + (headerR.Height - markerSize) div 2,
    r.Left + 6 + markerSize,
    headerR.Top + (headerR.Height + markerSize) div 2
  );

  // Header title
  FBuffer.Canvas.Font.Color := accent;
  FBuffer.Canvas.Font.Size := Max(7, Round(8 * FZoom));
  FBuffer.Canvas.Font.Name := TThemeManager.Current.FontName;
  FBuffer.Canvas.Font.Style := [fsBold];
  FBuffer.Canvas.Brush.Style := bsClear;

  title := NODE_TYPE_NAMES[node.NodeType];
  if node.Speaker <> '' then
    title := title + '  [' + node.Speaker + ']';

FBuffer.Canvas.TextRect(
     Rect(r.Left + 6 + markerSize + 4, headerR.Top, r.Right - 4, headerR.Bottom),
     r.Left + 6 + markerSize + 4, headerR.Top,
     title
   );
  FBuffer.Canvas.Font.Style := [];

  // Separator line
  FBuffer.Canvas.Pen.Color := TThemeManager.Current.BorderDark;
  FBuffer.Canvas.Pen.Width := 1;
  FBuffer.Canvas.Pen.Style := psSolid;
  FBuffer.Canvas.MoveTo(r.Left + 1, headerR.Bottom);
  FBuffer.Canvas.LineTo(r.Right - 1, headerR.Bottom);
end;

procedure TNodeCanvas.DrawNodeBody(node: TDialogueNode; const r: TRect);
var
   bodyR: TRect;
   textPreview: string;
   lineY: Integer;
opt: TPlayerOption;
    optText: string;
    j: Integer;
begin
bodyR := Rect(r.Left + 1, r.Top + Round(HEADER_HEIGHT * FZoom) + 1, r.Right - 1, r.Bottom - 1);
   FBuffer.Canvas.Brush.Color := TThemeManager.Current.BgMedium;
  FBuffer.Canvas.Pen.Style := psClear;
  FBuffer.Canvas.FillRect(bodyR);

  FBuffer.Canvas.Brush.Style := bsClear;

  if node.NodeType = ntComment then
  begin
    FBuffer.Canvas.Font.Color := TThemeManager.Current.TextSecondary;
    FBuffer.Canvas.Font.Size := Max(7, Round(8 * FZoom));
    FBuffer.Canvas.Font.Style := [fsItalic];
    textPreview := node.Comment;
FBuffer.Canvas.TextRect(
         Rect(bodyR.Left + 4, bodyR.Top + 4, bodyR.Right - 4, bodyR.Bottom - 4),
         bodyR.Left + 4, bodyR.Top + 4,
         textPreview
       );
    FBuffer.Canvas.Font.Style := [];
    Exit;
  end;

  // Main text preview
  FBuffer.Canvas.Font.Color := TThemeManager.Current.TextPrimary;
  FBuffer.Canvas.Font.Size := Max(7, Round(8 * FZoom));
  FBuffer.Canvas.Font.Name := TThemeManager.Current.FontName;
  FBuffer.Canvas.Font.Style := [];

  if Trim(node.Text) <> '' then
  begin
    textPreview := node.Text;
    if Length(textPreview) > 80 then
      textPreview := Copy(textPreview, 1, 77) + '...';
FBuffer.Canvas.TextRect(
       Rect(bodyR.Left + 8, bodyR.Top + 4, bodyR.Right - 14, bodyR.Top + Round(22 * FZoom)),
       bodyR.Left + 8, bodyR.Top + 4,
       textPreview
     );
  end else
  begin
    FBuffer.Canvas.Font.Color := TThemeManager.Current.TextDim;
    FBuffer.Canvas.Font.Style := [fsItalic];
    FBuffer.Canvas.TextOut(bodyR.Left + 8, bodyR.Top + 4, '(no text)');
    FBuffer.Canvas.Font.Style := [];
  end;

// Player options listing
   lineY := bodyR.Top + Round(24 * FZoom);
   for j := 0 to node.PlayerOptions.Count - 1 do
   begin
     opt := node.PlayerOptions[j];
     if lineY >= bodyR.Bottom - 4 then Break;
    FBuffer.Canvas.Font.Color := TThemeManager.Current.AccentPrimary;
    FBuffer.Canvas.Font.Size := Max(6, Round(7 * FZoom));
    optText := '→ ';
    if opt.Text <> '' then
      optText := optText + opt.Text
    else
      optText := optText + '(option)';
    if opt.HasSkillCheck then
      optText := optText + ' [' + SKILL_NAMES[opt.SkillCheck.Skill] + ']';
FBuffer.Canvas.TextRect(
       Rect(bodyR.Left + 8, lineY, bodyR.Right - 14, lineY + Round(18 * FZoom)),
       bodyR.Left + 8, lineY,
       optText
     );
    Inc(lineY, Round(20 * FZoom));
    FBuffer.Canvas.Pen.Color := TThemeManager.Current.BorderDark;
    FBuffer.Canvas.Pen.Width := 1;
    FBuffer.Canvas.Pen.Style := psSolid;
    FBuffer.Canvas.MoveTo(bodyR.Left + 6, lineY - 1);
    FBuffer.Canvas.LineTo(bodyR.Right - 6, lineY - 1);
  end;

  // Condition indicator
  if node.Conditions.Count > 0 then
  begin
    FBuffer.Canvas.Font.Color := TThemeManager.Current.ColorWarning;
    FBuffer.Canvas.Font.Size := Max(6, Round(7 * FZoom));
    FBuffer.Canvas.TextOut(bodyR.Left + 8, bodyR.Bottom - Round(16 * FZoom),
      '⚙ ' + IntToStr(node.Conditions.Count) + ' condition(s)');
  end;

  // Script indicator
  if node.Scripts.Count > 0 then
  begin
    FBuffer.Canvas.Font.Color := TThemeManager.Current.ColorInfo;
    FBuffer.Canvas.Font.Size := Max(6, Round(7 * FZoom));
    FBuffer.Canvas.TextOut(bodyR.Right - Round(50 * FZoom), bodyR.Bottom - Round(16 * FZoom), '⟨script⟩');
  end;
end;

procedure TNodeCanvas.DrawNodePorts(node: TDialogueNode; const r: TRect);
var
  portR: TRect;
  i: Integer;
  portCount: Integer;
  portY: Integer;
begin
  // Input port (left side) - single
  portR := Rect(r.Left - Round(PORT_RADIUS * FZoom), (r.Top + r.Bottom) div 2 - Round(PORT_RADIUS * FZoom),
    r.Left + Round(PORT_RADIUS * FZoom), (r.Top + r.Bottom) div 2 + Round(PORT_RADIUS * FZoom));

  if node.NodeType <> ntEndDialogue then
  begin
    FBuffer.Canvas.Brush.Color := TThemeManager.Current.BgMedium;
    FBuffer.Canvas.Pen.Color := TThemeManager.Current.AccentSecondary;
    FBuffer.Canvas.Pen.Width := Max(1, Round(FZoom));
    FBuffer.Canvas.Pen.Style := psSolid;
    FBuffer.Canvas.Ellipse(portR.Left, portR.Top, portR.Right, portR.Bottom);
  end;

  // Output ports (right side)
  portCount := Max(1, node.PlayerOptions.Count);
  if node.NodeType in [ntEndDialogue, ntComment] then Exit;

  for i := 0 to portCount - 1 do
  begin
    portY := r.Top + Round(HEADER_HEIGHT * FZoom) + i * Round(22 * FZoom) + Round(11 * FZoom);
    portR := Rect(r.Right - Round(PORT_RADIUS * FZoom), portY - Round(PORT_RADIUS * FZoom),
      r.Right + Round(PORT_RADIUS * FZoom), portY + Round(PORT_RADIUS * FZoom));
    FBuffer.Canvas.Brush.Color := TThemeManager.Current.AccentDim;
    FBuffer.Canvas.Pen.Color := TThemeManager.Current.AccentPrimary;
    FBuffer.Canvas.Pen.Width := Max(1, Round(FZoom));
    FBuffer.Canvas.Pen.Style := psSolid;
    FBuffer.Canvas.Ellipse(portR.Left, portR.Top, portR.Right, portR.Bottom);
  end;
end;

procedure TNodeCanvas.DrawMinimap;
var
  mapR: TRect;
  node: TDialogueNode;
  minX, minY, maxX, maxY: Integer;
  scaleX, scaleY, scale: Single;
  nr: TRect;
  nx, ny, nw, nh: Integer;
  viewR: TRect;
  margin: Integer;
  vwX, vwY, vwW, vwH: Integer;
  i: Integer;
begin
  if not Assigned(FProject) or (FProject.Nodes.Count = 0) then Exit;

  mapR := Rect(Width - MINIMAP_W - MINIMAP_MARGIN, Height - MINIMAP_H - MINIMAP_MARGIN,
    Width - MINIMAP_MARGIN, Height - MINIMAP_MARGIN);

  // Minimap background
  FBuffer.Canvas.Brush.Color := TColor($A0000000 and Integer(TThemeManager.Current.BgDark));
  FBuffer.Canvas.Pen.Color := TThemeManager.Current.BorderLight;
  FBuffer.Canvas.Pen.Width := 1;
  FBuffer.Canvas.Pen.Style := psSolid;
  FBuffer.Canvas.Rectangle(mapR);

  // Get world bounds
  minX := MaxInt; minY := MaxInt; maxX := Low(Integer); maxY := Low(Integer);
  for i := 0 to FProject.Nodes.Count - 1 do
  begin
    node := FProject.Nodes[i];
    minX := Min(minX, node.X); minY := Min(minY, node.Y);
    maxX := Max(maxX, node.X + node.Width);
    maxY := Max(maxY, node.Y + node.Height);
  end;
  if maxX <= minX then Exit;

  margin := 8;
  scaleX := (MINIMAP_W - margin * 2) / Max(1, maxX - minX);
  scaleY := (MINIMAP_H - margin * 2) / Max(1, maxY - minY);
  scale := Min(scaleX, scaleY);

// Draw nodes in minimap
   FBuffer.Canvas.Pen.Style := psClear;
   for i := 0 to FProject.Nodes.Count - 1 do
   begin
     node := FProject.Nodes[i];
     nx := mapR.Left + margin + Round((node.X - minX) * scale);
     ny := mapR.Top + margin + Round((node.Y - minY) * scale);
     nw := Max(4, Round(node.Width * scale));
     nh := Max(3, Round(node.Height * scale));
     FBuffer.Canvas.Brush.Color := NODE_ACCENT_COLORS[node.NodeType];
     FBuffer.Canvas.FillRect(Rect(nx, ny, nx + nw, ny + nh));
   end;

  // Draw viewport rect
  vwX := Round((-FOffsetX / FZoom - minX) * scale) + mapR.Left + margin;
  vwY := Round((-FOffsetY / FZoom - minY) * scale) + mapR.Top + margin;
  vwW := Round((Width / FZoom) * scale);
  vwH := Round((Height / FZoom) * scale);
  FBuffer.Canvas.Brush.Style := bsClear;
  FBuffer.Canvas.Pen.Color := TThemeManager.Current.AccentPrimary;
  FBuffer.Canvas.Pen.Width := 1;
  FBuffer.Canvas.Pen.Style := psSolid;
  FBuffer.Canvas.Rectangle(vwX, vwY, vwX + vwW, vwY + vwH);
end;

procedure TNodeCanvas.DrawScanlines;
begin
  // Scanline effect removed — hindered text readability
end;

procedure TNodeCanvas.DrawSelectionRect;
begin
  FBuffer.Canvas.Pen.Color := TThemeManager.Current.AccentPrimary;
  FBuffer.Canvas.Pen.Width := 1;
  FBuffer.Canvas.Pen.Style := psDash;
  FBuffer.Canvas.Brush.Style := bsClear;
  FBuffer.Canvas.Rectangle(FSelectRect);
end;

procedure TNodeCanvas.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
   node: TDialogueNode;
   wp: TPoint;
   n: TDialogueNode;
   i: Integer;
begin
  SetFocus;
  FMouseStart := Point(X, Y);
  FLastMousePos := Point(X, Y);
  wp := ScreenToWorld(X, Y);

  if Button = mbRight then
  begin
    FRightClickNode := NodeAtPoint(Point(X, Y));
    FPopupMenu.Popup(ClientToScreen(Point(X, Y)).X, ClientToScreen(Point(X, Y)).Y);
    Exit;
  end;

  node := NodeAtPoint(Point(X, Y));

  if Button = mbLeft then
  begin
    if Assigned(node) then
    begin
      if ssCtrl in Shift then
      begin
        // Toggle selection
        node.Selected := not node.Selected;
        if node.Selected then
          FSelectedNodes.Add(node)
        else
          FSelectedNodes.Remove(node);
      end else if not node.Selected then
      begin
// Single select
         for i := 0 to FProject.Nodes.Count - 1 do
         begin
           n := FProject.Nodes[i];
           n.Selected := False;
         end;
         FSelectedNodes.Clear;
        node.Selected := True;
        FSelectedNodes.Add(node);
        if Assigned(FOnNodeSelect) then
          FOnNodeSelect(Self, node.ID);
      end;
      FAction := ncaDragging;
      FDragNode := node;
      FDragStartX := node.X;
      FDragStartY := node.Y;
    end else
    begin
// Deselect all + start selection rect
       if not (ssCtrl in Shift) then
       begin
         for i := 0 to FProject.Nodes.Count - 1 do
         begin
           n := FProject.Nodes[i];
           n.Selected := False;
         end;
         FSelectedNodes.Clear;
      end;
      FAction := ncaSelecting;
      FSelecting := True;
      FSelectRect := Rect(X, Y, X, Y);
    end;
  end else if Button = mbMiddle then
  begin
    FAction := ncaPanning;
  end;

  Invalidate;
end;

procedure TNodeCanvas.MouseMove(Shift: TShiftState; X, Y: Integer);
var
   dx, dy: Integer;
   wp: TPoint;
   node: TDialogueNode;
   newX, newY: Integer;
   offX, offY: Integer;
   nr: TRect;
   i: Integer;
begin
   FLastMousePos := Point(X, Y);
  dx := X - FMouseStart.X;
  dy := Y - FMouseStart.Y;

  case FAction of
    ncaDragging:
    begin
      if Assigned(FDragNode) then
      begin
        wp := ScreenToWorld(X, Y);
        newX := SnapToGrid(FDragStartX + Round(dx / FZoom));
        newY := SnapToGrid(FDragStartY + Round(dy / FZoom));
        // Move all selected nodes
        offX := newX - FDragNode.X;
        offY := newY - FDragNode.Y;
        for node in FSelectedNodes do
        begin
          node.X := node.X + offX;
          node.Y := node.Y + offY;
        end;
        FDragNode.X := newX;
        FDragNode.Y := newY;
        Invalidate;
      end;
    end;
    ncaPanning:
    begin
      FOffsetX := FOffsetX + dx;
      FOffsetY := FOffsetY + dy;
      FMouseStart := Point(X, Y);
      Invalidate;
    end;
    ncaSelecting:
    begin
      FSelectRect := Rect(
        Min(FMouseStart.X, X), Min(FMouseStart.Y, Y),
        Max(FMouseStart.X, X), Max(FMouseStart.Y, Y)
      );
// Update selection
       for i := 0 to FProject.Nodes.Count - 1 do
       begin
         node := FProject.Nodes[i];
         nr := GetNodeRect(node);
         node.Selected := not ((nr.Right < FSelectRect.Left) or (nr.Left > FSelectRect.Right) or
                                (nr.Bottom < FSelectRect.Top) or (nr.Top > FSelectRect.Bottom));
       end;
       FSelectedNodes.Clear;
       for i := 0 to FProject.Nodes.Count - 1 do
       begin
         node := FProject.Nodes[i];
         if node.Selected then FSelectedNodes.Add(node);
       end;
      Invalidate;
    end;
    ncaConnecting:
      Invalidate;
  end;

  // Cursor
  if Assigned(NodeAtPoint(Point(X, Y))) then
    Cursor := crSizeAll
  else if FAction = ncaPanning then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
end;

procedure TNodeCanvas.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  targetNode: TDialogueNode;
begin
  if FAction = ncaDragging then
  begin
    if Assigned(FProject) then FProject.Modified := True;
    if Assigned(FOnModified) then FOnModified(Self);
  end;

  if FAction = ncaConnecting then
  begin
    targetNode := NodeAtPoint(Point(X, Y));
    if Assigned(targetNode) and Assigned(FConnectFrom) and (targetNode <> FConnectFrom) then
    begin
      if Assigned(FOnConnectionMade) then
        FOnConnectionMade(Self, FConnectFrom.ID, targetNode.ID, FConnectFromOpt);
    end;
  end;

  FAction := ncaNone;
  FDragNode := nil;
  FSelecting := False;
  Cursor := crDefault;
  Invalidate;
end;

procedure TNodeCanvas.DblClick;
var
  node: TDialogueNode;
begin
  node := NodeAtPoint(FLastMousePos);
  if Assigned(node) and Assigned(FOnNodeDblClick) then
    FOnNodeDblClick(Self, node.ID);
end;

procedure TNodeCanvas.KeyDown(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_DELETE: DeleteSelected;
    Ord('A'): if ssCtrl in Shift then SelectAll;
    Ord('='): if ssCtrl in Shift then ZoomIn;
    Ord('-'): if ssCtrl in Shift then ZoomOut;
    Ord('0'): if ssCtrl in Shift then ZoomReset;
    Ord('F'): if ssCtrl in Shift then FitAll;
    Ord('G'): begin FShowGrid := not FShowGrid; Invalidate; end;
  end;
end;

procedure TNodeCanvas.MouseWheelHandler(var Message: TMessage);
var
  delta: Integer;
  mousePos: TPoint;
  oldZoom: Single;
begin
  delta := SmallInt(HIWORD(Message.wParam));
  mousePos := ScreenToClient(Point(LOWORD(Message.lParam), HIWORD(Message.lParam)));

  // Zoom around mouse position
  oldZoom := FZoom;
  if delta > 0 then
    FZoom := Min(FZoom * 1.15, MAX_ZOOM)
  else
    FZoom := Max(FZoom / 1.15, MIN_ZOOM);

  if FZoom <> oldZoom then
  begin
    // Adjust offset to zoom around mouse
    FOffsetX := mousePos.X - Round((mousePos.X - FOffsetX) * FZoom / oldZoom);
    FOffsetY := mousePos.Y - Round((mousePos.Y - FOffsetY) * FZoom / oldZoom);
    Invalidate;
  end;
  Message.Result := 1;
end;

procedure TNodeCanvas.SelectAll;
var
  node: TDialogueNode;
  i: Integer;
begin
  if not Assigned(FProject) then Exit;
  FSelectedNodes.Clear;
  for i := 0 to FProject.Nodes.Count - 1 do
  begin
    node := FProject.Nodes[i];
    node.Selected := True;
    FSelectedNodes.Add(node);
  end;
  Invalidate;
end;

procedure TNodeCanvas.DeleteSelected;
var
  node: TDialogueNode;
  id: string;
  toDelete: TList<string>;
  i: Integer;
begin
  if not Assigned(FProject) then Exit;
  toDelete := TList<string>.Create;
  try
    for i := 0 to FSelectedNodes.Count - 1 do
    begin
      node := FSelectedNodes[i];
      toDelete.Add(node.ID);
    end;
    for i := 0 to toDelete.Count - 1 do
    begin
      id := toDelete[i];
      FProject.RemoveNode(id);
    end;
    FSelectedNodes.Clear;
    if Assigned(FOnModified) then FOnModified(Self);
    Invalidate;
  finally
    toDelete.Free;
  end;
end;

procedure TNodeCanvas.AddNode(nodeType: TNodeType; x, y: Integer);
var
  node: TDialogueNode;
  n: TDialogueNode;
  wp: TPoint;
  i: Integer;
begin
  if not Assigned(FProject) then Exit;
  wp := ScreenToWorld(x, y);
  node := FProject.AddNode(nodeType);
  node.X := SnapToGrid(wp.X - node.Width div 2);
  node.Y := SnapToGrid(wp.Y - node.Height div 2);
  // Clear selection and select new node
  for i := 0 to FProject.Nodes.Count - 1 do
  begin
    n := FProject.Nodes[i];
    n.Selected := False;
  end;
  FSelectedNodes.Clear;
  node.Selected := True;
  FSelectedNodes.Add(node);
  if Assigned(FOnNodeSelect) then FOnNodeSelect(Self, node.ID);
  if Assigned(FOnModified) then FOnModified(Self);
  Invalidate;
end;

procedure TNodeCanvas.AutoLayout;
var
  node: TDialogueNode;
  col, row: Integer;
  colW, rowH, marginX, marginY: Integer;
  startNode: TDialogueNode;
  i: Integer;
begin
  if not Assigned(FProject) or (FProject.Nodes.Count = 0) then Exit;

  // Simple grid auto-layout
  colW := 280;
  rowH := 160;
  marginX := 40;
  marginY := 40;
  col := 0; row := 0;

  // Put start node first
  startNode := FProject.FindNode(FProject.StartNodeID);
  if Assigned(startNode) then
  begin
    startNode.X := marginX;
    startNode.Y := marginY;
  end;

  for i := 0 to FProject.Nodes.Count - 1 do
  begin
    node := FProject.Nodes[i];
    if node = startNode then Continue;
    node.X := marginX + col * (colW + marginX);
    node.Y := marginY + row * (rowH + marginY) + rowH;
    Inc(col);
    if col >= 4 then
    begin
      col := 0;
      Inc(row);
    end;
  end;

  FProject.Modified := True;
  FitAll;
end;

procedure TNodeCanvas.BuildPopupMenu;
var
  mi: TMenuItem;
begin
  FPopupMenu := TPopupMenu.Create(Self);

  mi := TMenuItem.Create(FPopupMenu);
  mi.Caption := '+ NPC Dialogue';
  mi.OnClick := MenuAddNPCClick;
  FPopupMenu.Items.Add(mi);

  mi := TMenuItem.Create(FPopupMenu);
  mi.Caption := '+ Player Reply';
  mi.OnClick := MenuAddPlayerClick;
  FPopupMenu.Items.Add(mi);

  mi := TMenuItem.Create(FPopupMenu);
  mi.Caption := '+ Conditional';
  mi.OnClick := MenuAddConditionalClick;
  FPopupMenu.Items.Add(mi);

  mi := TMenuItem.Create(FPopupMenu);
  mi.Caption := '+ Script Node';
  mi.OnClick := MenuAddScriptClick;
  FPopupMenu.Items.Add(mi);

  mi := TMenuItem.Create(FPopupMenu);
  mi.Caption := '+ End Dialogue';
  mi.OnClick := MenuAddEndClick;
  FPopupMenu.Items.Add(mi);

  mi := TMenuItem.Create(FPopupMenu);
  mi.Caption := '+ Comment';
  mi.OnClick := MenuAddCommentClick;
  FPopupMenu.Items.Add(mi);

  mi := TMenuItem.Create(FPopupMenu);
  mi.Caption := '-';
  FPopupMenu.Items.Add(mi);

  mi := TMenuItem.Create(FPopupMenu);
  mi.Caption := 'Delete Node';
  mi.OnClick := MenuDeleteNodeClick;
  FPopupMenu.Items.Add(mi);

  mi := TMenuItem.Create(FPopupMenu);
  mi.Caption := 'Set as Start Node';
  mi.OnClick := MenuSetStartClick;
  FPopupMenu.Items.Add(mi);

  mi := TMenuItem.Create(FPopupMenu);
  mi.Caption := '-';
  FPopupMenu.Items.Add(mi);

  mi := TMenuItem.Create(FPopupMenu);
  mi.Caption := 'Properties...';
  mi.OnClick := MenuPropertiesClick;
  FPopupMenu.Items.Add(mi);
end;

procedure TNodeCanvas.MenuAddNPCClick(Sender: TObject);
begin
  AddNode(ntNPCDialogue, FMouseStart.X, FMouseStart.Y);
end;

procedure TNodeCanvas.MenuAddPlayerClick(Sender: TObject);
begin
  AddNode(ntPlayerReply, FMouseStart.X, FMouseStart.Y);
end;

procedure TNodeCanvas.MenuAddConditionalClick(Sender: TObject);
begin
  AddNode(ntConditional, FMouseStart.X, FMouseStart.Y);
end;

procedure TNodeCanvas.MenuAddScriptClick(Sender: TObject);
begin
  AddNode(ntScript, FMouseStart.X, FMouseStart.Y);
end;

procedure TNodeCanvas.MenuAddEndClick(Sender: TObject);
begin
  AddNode(ntEndDialogue, FMouseStart.X, FMouseStart.Y);
end;

procedure TNodeCanvas.MenuAddCommentClick(Sender: TObject);
begin
  AddNode(ntComment, FMouseStart.X, FMouseStart.Y);
end;

procedure TNodeCanvas.MenuDeleteNodeClick(Sender: TObject);
begin
  if Assigned(FRightClickNode) then
  begin
    FRightClickNode.Selected := True;
    if not FSelectedNodes.Contains(FRightClickNode) then
      FSelectedNodes.Add(FRightClickNode);
    DeleteSelected;
  end;
end;

procedure TNodeCanvas.MenuSetStartClick(Sender: TObject);
var
  n: TDialogueNode;
begin
  if Assigned(FRightClickNode) and Assigned(FProject) then
  begin
    for n in FProject.Nodes do n.IsStartNode := False;
    FRightClickNode.IsStartNode := True;
    FProject.StartNodeID := FRightClickNode.ID;
    FProject.Modified := True;
    if Assigned(FOnModified) then FOnModified(Self);
    Invalidate;
  end;
end;

procedure TNodeCanvas.MenuPropertiesClick(Sender: TObject);
begin
  if Assigned(FRightClickNode) and Assigned(FOnNodeDblClick) then
    FOnNodeDblClick(Self, FRightClickNode.ID);
end;

end.