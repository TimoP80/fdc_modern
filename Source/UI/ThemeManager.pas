unit ThemeManager;

interface

uses
   Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls, System.Classes, System.SysUtils;

type
   TThemeManager = class
   public
     class procedure ApplyFalloutTheme(AForm: TForm = nil);
     class procedure ApplyFalloutThemeToControl(AControl: TControl);
   end;

implementation

{ TThemeManager }

class procedure TThemeManager.ApplyFalloutTheme(AForm: TForm = nil);
var
  I: Integer;
  Form: TForm;
  Control: TControl;
begin
  if not Assigned(AForm) then
    Form := Application.MainForm
  else
    Form := AForm;

  if not Assigned(Form) then Exit;

  Form.Color := clBlack;
  Form.Font.Name := 'Courier New';
  Form.Font.Color := clLime;

  for I := 0 to Form.ControlCount - 1 do
  begin
    Control := Form.Controls[I];
    ApplyFalloutThemeToControl(Control);
  end;
end;

class procedure TThemeManager.ApplyFalloutThemeToControl(AControl: TControl);
var
  I: Integer;
  Parent: TWinControl;
begin
  if AControl is TPanel then
  begin
    TPanel(AControl).Color := clGreen;
    TPanel(AControl).Font.Color := clBlack;
  end
  else if AControl is TListBox then
  begin
    TListBox(AControl).Color := clBlack;
    TListBox(AControl).Font.Color := clLime;
  end
  else if AControl is TMemo then
  begin
    TMemo(AControl).Color := clBlack;
    TMemo(AControl).Font.Color := clLime;
  end
  else if AControl is TEdit then
  begin
    TEdit(AControl).Color := clBlack;
    TEdit(AControl).Font.Color := clLime;
  end
  else if AControl is TComboBox then
  begin
    TComboBox(AControl).Color := clBlack;
    TComboBox(AControl).Font.Color := clLime;
  end;

  if AControl is TWinControl then
  begin
    Parent := TWinControl(AControl);
    for I := 0 to Parent.ControlCount - 1 do
      ApplyFalloutThemeToControl(Parent.Controls[I]);
  end;
end;

end.