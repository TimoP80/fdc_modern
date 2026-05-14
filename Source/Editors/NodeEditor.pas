unit NodeEditor;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Generics.Collections,
  Winapi.Windows, Winapi.Messages, Vcl.Controls, Vcl.Graphics, Vcl.Forms, NodeTypes;

type
  TNodeEditor = class(TCustomControl)
  private
    FNodes: TList<TDialogueNode>;
    FZoom: Single;
    FOffset: TPoint;
    FDragging: Boolean;
    FDragNode: TDialogueNode;
    FDragStart: TPoint;
    FSelectedNodes: TList<TDialogueNode>;
    procedure SetZoom(const Value: Single);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddNode(ANode: TDialogueNode);
    procedure ClearSelection;
    function ScreenToCanvas(const APoint: TPoint): TPoint;
    function CanvasToScreen(const APoint: TPoint): TPoint;

    property Zoom: Single read FZoom write SetZoom;
    property Nodes: TList<TDialogueNode> read FNodes;
    property SelectedNodes: TList<TDialogueNode> read FSelectedNodes;
  end;

implementation

uses
  Vcl.StdCtrls;

{ TNodeEditor }

constructor TNodeEditor.Create(AOwner: TComponent);
begin
  inherited;
  FNodes := TList<TDialogueNode>.Create;
  FSelectedNodes := TList<TDialogueNode>.Create;
  FZoom := 1.0;
  FOffset := Point(0, 0);
  DoubleBuffered := True;
end;

destructor TNodeEditor.Destroy;
begin
  FNodes.Free;
  FSelectedNodes.Free;
  inherited;
end;

procedure TNodeEditor.AddNode(ANode: TDialogueNode);
begin
  FNodes.Add(ANode);
  Invalidate;
end;

procedure TNodeEditor.ClearSelection;
begin
  FSelectedNodes.Clear;
  Invalidate;
end;

function TNodeEditor.ScreenToCanvas(const APoint: TPoint): TPoint;
begin
  Result.X := Round((APoint.X - FOffset.X) / FZoom);
  Result.Y := Round((APoint.Y - FOffset.Y) / FZoom);
end;

function TNodeEditor.CanvasToScreen(const APoint: TPoint): TPoint;
begin
  Result.X := Round(APoint.X * FZoom) + FOffset.X;
  Result.Y := Round(APoint.Y * FZoom) + FOffset.Y;
end;

procedure TNodeEditor.SetZoom(const Value: Single);
begin
  FZoom := Value;
  if FZoom < 0.25 then FZoom := 0.25;
  if FZoom > 4.0 then FZoom := 4.0;
  Invalidate;
end;

procedure TNodeEditor.Paint;
var
  Node: TDialogueNode;
  NodeRect: TRect;
  I: Integer;
begin
  Canvas.Brush.Color := clBlack;
  Canvas.FillRect(ClientRect);

  // Draw grid
  Canvas.Pen.Color := clGreen;
  Canvas.Pen.Style := psDot;
  for I := 0 to ClientWidth div 20 do
  begin
    Canvas.MoveTo(I * 20, 0);
    Canvas.LineTo(I * 20, ClientHeight);
  end;
  for I := 0 to ClientHeight div 20 do
  begin
    Canvas.MoveTo(0, I * 20);
    Canvas.LineTo(ClientWidth, I * 20);
  end;
  Canvas.Pen.Style := psSolid;

  // Draw nodes
  for Node in FNodes do
  begin
    NodeRect := Rect(
      CanvasToScreen(Node.Position).X,
      CanvasToScreen(Node.Position).Y,
      CanvasToScreen(Node.Position).X + Round(150 * FZoom),
      CanvasToScreen(Node.Position).Y + Round(80 * FZoom)
    );

    // Node background
    if FSelectedNodes.Contains(Node) then
      Canvas.Brush.Color := clLime
    else
      Canvas.Brush.Color := clGreen;
    Canvas.FillRect(NodeRect);

// Node text
      Canvas.Font.Color := clBlack;
      Canvas.TextRect(NodeRect, NodeRect.Left + 4, NodeRect.Top + 4, Node.Text);

     // Draw connections (simplified)
     Canvas.Pen.Color := clYellow;
     for var LinkID in Node.Links do
     begin
       // Connection drawing not implemented yet
     end;
  end;
end;

procedure TNodeEditor.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CanvasPt: TPoint;
  Node: TDialogueNode;
begin
  CanvasPt := ScreenToCanvas(Point(X, Y));
  for Node in FNodes do
  begin
    if PtInRect(Rect(Node.Position.X, Node.Position.Y, Node.Position.X + 150, Node.Position.Y + 80), CanvasPt) then
    begin
      FDragNode := Node;
      FDragging := True;
      FDragStart := CanvasPt;
      if not (ssCtrl in Shift) then
        ClearSelection;
      FSelectedNodes.Add(Node);
      Exit;
    end;
  end;
  ClearSelection;
end;

procedure TNodeEditor.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if FDragging and Assigned(FDragNode) then
  begin
    var CanvasPt := ScreenToCanvas(Point(X, Y));
    FDragNode.Position := Point(
      FDragNode.Position.X + (CanvasPt.X - FDragStart.X),
      FDragNode.Position.Y + (CanvasPt.Y - FDragStart.Y)
    );
    FDragStart := CanvasPt;
    Invalidate;
  end;
end;

procedure TNodeEditor.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FDragging := False;
  FDragNode := nil;
end;

end.