unit NodePalette;

interface

uses
    System.SysUtils, System.Classes, System.TypInfo,
    Vcl.Controls, Vcl.ExtCtrls, Vcl.Graphics, Vcl.StdCtrls,
    NodeTypes, uThemeManager;

type
  TNodePalette = class(TPanel)
  private
    FListBox: TListBox;
    FOnNodeSelect: TProc<TDialogueNodeType>;
    procedure ListBoxClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent);
    procedure PopulateNodes;
    property OnNodeSelect: TProc<TDialogueNodeType> read FOnNodeSelect write FOnNodeSelect;
  end;

implementation

{ TNodePalette }

constructor TNodePalette.Create(AOwner: TComponent);
begin
   inherited;
   Align := alLeft;
   Width := 200;
   Color := TThemeManager.Current.BgMedium;
   FListBox := TListBox.Create(Self);
   FListBox.Parent := Self;
   FListBox.Align := alClient;
   FListBox.Color := TThemeManager.Current.BgDark;
   FListBox.Font.Color := TThemeManager.Current.TextPrimary;
   FListBox.Font.Name := TThemeManager.Current.FontName;
   FListBox.OnClick := ListBoxClick;
   PopulateNodes;
end;

procedure TNodePalette.PopulateNodes;
var
  NodeType: TDialogueNodeType;
begin
  FListBox.Items.BeginUpdate;
  try
    for NodeType := Low(TDialogueNodeType) to High(TDialogueNodeType) do
      FListBox.Items.Add(GetEnumName(TypeInfo(TDialogueNodeType), Integer(NodeType)));
  finally
    FListBox.Items.EndUpdate;
  end;
end;

procedure TNodePalette.ListBoxClick(Sender: TObject);
begin
  if Assigned(FOnNodeSelect) and (FListBox.ItemIndex >= 0) then
    FOnNodeSelect(TDialogueNodeType(FListBox.ItemIndex));
end;

end.