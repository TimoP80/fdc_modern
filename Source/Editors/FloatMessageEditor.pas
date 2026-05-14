unit FloatMessageEditor;

interface

uses
   System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
   Vcl.Dialogs, NodeTypes, uThemeManager;

type
  TFloatMessageType = (fmtCombatTaunt, fmtNPReaction, fmtQuestNotification, fmtEnvironmental);

  TfrmFloatMessageEditor = class(TForm)
    pnlMain: TPanel;
    lblText: TLabel;
    edtText: TMemo;
    lblType: TLabel;
    cmbType: TComboBox;
    lblTiming: TLabel;
    edtTiming: TEdit;
    lblColor: TLabel;
    cmbColor: TComboBox;
    btnPreview: TButton;
    btnSave: TButton;
    procedure btnPreviewClick(Sender: TObject);
  private
    FNode: TDialogueNode;
  public
    constructor Create(AOwner: TComponent; ANode: TDialogueNode); reintroduce;
  end;

implementation

{ TfrmFloatMessageEditor }

constructor TfrmFloatMessageEditor.Create(AOwner: TComponent; ANode: TDialogueNode);
begin
    inherited CreateNew(AOwner);
    FNode := ANode;
    edtText.Text := ANode.Text;
    cmbType.Items.AddStrings(['Combat Taunt', 'NPC Reaction', 'Quest Notification', 'Environmental']);
    cmbColor.Items.AddStrings(['White', 'Yellow', 'Red', 'Green']);
    TThemeManager.ApplyToForm(Self);
end;

procedure TfrmFloatMessageEditor.btnPreviewClick(Sender: TObject);
begin
  // Preview float message in a popup
  ShowMessage('Preview: ' + edtText.Text);
end;

end.