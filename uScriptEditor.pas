unit uScriptEditor;

interface

uses
  System.SysUtils, System.Classes, System.TypInfo,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ExtCtrls, Vcl.Graphics, Vcl.Dialogs,
  uDialogueTypes, uThemeManager;

type
  TScriptEditorForm = class(TForm)
  private
    FScriptCode: string;
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    btnValidate: TButton;
    pcScript: TPageControl;
    tsEditor: TTabSheet;
    tsReference: TTabSheet;
    memoEditor: TMemo;
    memoReference: TMemo;
    pnlToolbar: TPanel;
    cmbEventType: TComboBox;
    lblEvent: TLabel;
    btnInsertTemplate: TButton;
    lblLineInfo: TLabel;
    procedure BuildLayout;
    procedure StyleForm;
    procedure LoadReference;
    procedure ValidateScript;
    procedure InsertTemplate;
    procedure memoEditorKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnOKClick(Sender: TObject);
    procedure btnValidateClick(Sender: TObject);
    procedure btnInsertTemplateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  public
    class function Execute(AOwner: TComponent; var code: string): Boolean;
  end;

implementation

class function TScriptEditorForm.Execute(AOwner: TComponent; var code: string): Boolean;
var frm: TScriptEditorForm;
begin
   frm := TScriptEditorForm.CreateNew(AOwner);
   try
     frm.BuildLayout;
     frm.StyleForm;
     frm.LoadReference;
     frm.FScriptCode := code;
     frm.memoEditor.Text := code;
     Result := frm.ShowModal = mrOk;
     if Result then code := frm.memoEditor.Text;
   finally frm.Free; end;
end;

procedure TScriptEditorForm.FormCreate(Sender: TObject);
begin BuildLayout; StyleForm; LoadReference; end;

procedure TScriptEditorForm.BuildLayout;
var se: TScriptEvent;
begin
  Width := 720; Height := 580;
  Caption := 'Script Editor';
  Position := poMainFormCenter;
  OnCreate := FormCreate;

  pnlHeader := TPanel.Create(Self); pnlHeader.Parent := Self;
  pnlHeader.Align := alTop; pnlHeader.Height := 38; pnlHeader.BevelOuter := bvNone;
  lblTitle := TLabel.Create(Self); lblTitle.Parent := pnlHeader;
  lblTitle.Left := 10; lblTitle.Top := 8;
  lblTitle.Caption := 'SCRIPT EDITOR';
  lblTitle.Font.Size := 12; lblTitle.Font.Style := [fsBold];

  pnlToolbar := TPanel.Create(Self); pnlToolbar.Parent := Self;
  pnlToolbar.Align := alTop; pnlToolbar.Height := 34; pnlToolbar.BevelOuter := bvNone;

  lblEvent := TLabel.Create(Self); lblEvent.Parent := pnlToolbar;
  lblEvent.Left := 6; lblEvent.Top := 8; lblEvent.Caption := 'Event:';

  cmbEventType := TComboBox.Create(Self); cmbEventType.Parent := pnlToolbar;
  cmbEventType.Left := 52; cmbEventType.Top := 5;
  cmbEventType.Width := 200; cmbEventType.Style := csDropDownList;
  for se := Low(TScriptEvent) to High(TScriptEvent) do
    cmbEventType.Items.Add(GetEnumName(TypeInfo(TScriptEvent), Ord(se)));
  cmbEventType.ItemIndex := 0;

  btnInsertTemplate := TButton.Create(Self); btnInsertTemplate.Parent := pnlToolbar;
  btnInsertTemplate.Caption := 'Insert Template';
  btnInsertTemplate.Left := 260; btnInsertTemplate.Top := 4;
  btnInsertTemplate.Width := 120; btnInsertTemplate.Height := 26;
  btnInsertTemplate.OnClick := btnInsertTemplateClick;

  lblLineInfo := TLabel.Create(Self); lblLineInfo.Parent := pnlToolbar;
  lblLineInfo.Left := 400; lblLineInfo.Top := 8;
  lblLineInfo.Caption := 'Ln 1  Col 1'; lblLineInfo.Width := 200;

  pnlBottom := TPanel.Create(Self); pnlBottom.Parent := Self;
  pnlBottom.Align := alBottom; pnlBottom.Height := 42; pnlBottom.BevelOuter := bvNone;

  btnOK := TButton.Create(Self); btnOK.Parent := pnlBottom;
  btnOK.Caption := 'OK'; btnOK.Left := pnlBottom.Width - 196; btnOK.Top := 7;
  btnOK.Width := 88; btnOK.Height := 28; btnOK.OnClick := btnOKClick;
  btnOK.Anchors := [akRight, akTop];

  btnCancel := TButton.Create(Self); btnCancel.Parent := pnlBottom;
  btnCancel.Caption := 'Cancel'; btnCancel.ModalResult := mrCancel;
  btnCancel.Left := pnlBottom.Width - 100; btnCancel.Top := 7;
  btnCancel.Width := 88; btnCancel.Height := 28; btnCancel.Anchors := [akRight, akTop];

  btnValidate := TButton.Create(Self); btnValidate.Parent := pnlBottom;
  btnValidate.Caption := '✓ Validate Script';
  btnValidate.Left := 6; btnValidate.Top := 7;
  btnValidate.Width := 130; btnValidate.Height := 28;
  btnValidate.OnClick := btnValidateClick;

  pcScript := TPageControl.Create(Self); pcScript.Parent := Self;
  pcScript.Align := alClient;

  tsEditor := TTabSheet.Create(pcScript);
  tsEditor.PageControl := pcScript; tsEditor.Caption := 'Script Code';

  memoEditor := TMemo.Create(Self); memoEditor.Parent := tsEditor;
  memoEditor.Align := alClient; memoEditor.ScrollBars := ssBoth;
  memoEditor.WordWrap := False; memoEditor.Font.Name := 'Courier New';
  memoEditor.Font.Size := 10; memoEditor.OnKeyUp := memoEditorKeyUp;

  tsReference := TTabSheet.Create(pcScript);
  tsReference.PageControl := pcScript; tsReference.Caption := 'Function Reference';

  memoReference := TMemo.Create(Self); memoReference.Parent := tsReference;
  memoReference.Align := alClient; memoReference.ReadOnly := True;
  memoReference.ScrollBars := ssBoth; memoReference.WordWrap := False;
  memoReference.Font.Name := 'Courier New'; memoReference.Font.Size := 9;
end;

procedure TScriptEditorForm.StyleForm;
var t: TFDCTheme;
begin
  t := TThemeManager.Current;
  Color := t.BgDark; Font.Color := t.TextPrimary;
  pnlHeader.Color := t.BgMedium; pnlBottom.Color := t.BgMedium; pnlToolbar.Color := t.BgMedium;
  lblTitle.Font.Color := t.AccentPrimary;
  lblEvent.Font.Color := t.TextSecondary;
  lblLineInfo.Font.Color := t.TextDim; lblLineInfo.Font.Size := 8;
  memoEditor.Color := t.BgDark; memoEditor.Font.Color := t.AccentPrimary;
  memoReference.Color := t.BgDark; memoReference.Font.Color := t.TextSecondary;
  cmbEventType.Color := t.BgLight; cmbEventType.Font.Color := t.TextPrimary;
  TThemeManager.ApplyToForm(Self);
end;

procedure TScriptEditorForm.LoadReference;
begin
  memoReference.Lines.Clear;
  memoReference.Lines.Add('=== FALLOUT DIALOGUE SCRIPT REFERENCE ===');
  memoReference.Lines.Add('');
  memoReference.Lines.Add('--- PLAYER / NPC ACCESS ---');
  memoReference.Lines.Add('  player                    // Player object');
  memoReference.Lines.Add('  npc                       // Current NPC object');
  memoReference.Lines.Add('  player.skill[SPEECH]      // Get player skill value (0-300)');
  memoReference.Lines.Add('  player.stat[ST]           // Get SPECIAL stat');
  memoReference.Lines.Add('  player.karma              // Get karma points');
  memoReference.Lines.Add('  player.reputation         // Get reputation with faction');
  memoReference.Lines.Add('');
  memoReference.Lines.Add('--- VARIABLES ---');
  memoReference.Lines.Add('  global_var("VAR_NAME")    // Read global variable');
  memoReference.Lines.Add('  set_global_var("VAR", v)  // Set global variable');
  memoReference.Lines.Add('  local_var("VAR_NAME")     // Read local (NPC) variable');
  memoReference.Lines.Add('  set_local_var("VAR", v)   // Set local variable');
  memoReference.Lines.Add('');
  memoReference.Lines.Add('--- QUEST SYSTEM ---');
  memoReference.Lines.Add('  quest_state("QUEST_ID")   // Get quest state (0=none,1=active,2=done)');
  memoReference.Lines.Add('  set_quest("QUEST_ID", s)  // Set quest state');
  memoReference.Lines.Add('  add_journal("QUEST_ID", e)// Add journal entry');
  memoReference.Lines.Add('');
  memoReference.Lines.Add('--- INVENTORY ---');
  memoReference.Lines.Add('  has_item(player, "ITEM")  // Check if player has item');
  memoReference.Lines.Add('  give_item(player, "ITEM") // Give item to player');
  memoReference.Lines.Add('  take_item(player, "ITEM") // Remove item from player');
  memoReference.Lines.Add('  give_caps(player, amount) // Give bottle caps');
  memoReference.Lines.Add('  take_caps(player, amount) // Remove caps');
  memoReference.Lines.Add('');
  memoReference.Lines.Add('--- REPUTATION / KARMA ---');
  memoReference.Lines.Add('  modify_karma(amount)      // Change karma (+/-)');
  memoReference.Lines.Add('  modify_rep("FACTION", v)  // Change faction reputation');
  memoReference.Lines.Add('  give_xp(amount)           // Award experience points');
  memoReference.Lines.Add('');
  memoReference.Lines.Add('--- DIALOGUE CONTROL ---');
  memoReference.Lines.Add('  end_dialogue()            // End conversation');
  memoReference.Lines.Add('  goto_node("NODE_ID")      // Jump to dialogue node');
  memoReference.Lines.Add('  set_npc_attitude(v)       // 0=hostile,50=neutral,100=friendly');
  memoReference.Lines.Add('');
  memoReference.Lines.Add('--- COMBAT ---');
  memoReference.Lines.Add('  start_combat()            // Trigger combat');
  memoReference.Lines.Add('  flee_combat()             // NPC flees');
  memoReference.Lines.Add('');
  memoReference.Lines.Add('--- EVENTS ---');
  memoReference.Lines.Add('  OnDialogueStart  // Fired when dialogue begins');
  memoReference.Lines.Add('  OnNodeEnter      // Fired when entering any node');
  memoReference.Lines.Add('  OnOptionSelected // Fired when player picks option');
  memoReference.Lines.Add('  OnSkillCheck     // Fired during skill check');
  memoReference.Lines.Add('  OnQuestUpdate    // Fired when quest state changes');
  memoReference.Lines.Add('  OnCombatStart    // Fired when combat begins');
  memoReference.Lines.Add('  OnDialogueEnd    // Fired at conversation end');
end;

procedure TScriptEditorForm.ValidateScript;
var
  issues: TStringList;
  code: string;
begin
  code := memoEditor.Text;
  issues := TStringList.Create;
  try
    if Trim(code) = '' then begin issues.Add('WARNING: Empty script'); end;
    if Pos('procedure', LowerCase(code)) > 0 then issues.Add('OK: Found procedure definition(s)');
    if Pos('end;', LowerCase(code)) > 0 then issues.Add('OK: Found end statement(s)');
    if Pos('begin', LowerCase(code)) > 0 then issues.Add('OK: Found begin block(s)');
    if issues.Count = 0 then issues.Add('Script appears valid (basic check).');
    ShowMessage('Script Validation:' + sLineBreak + issues.Text);
  finally issues.Free; end;
end;

procedure TScriptEditorForm.InsertTemplate;
var
  tmpl: string;
  se: TScriptEvent;
begin
  se := TScriptEvent(cmbEventType.ItemIndex);
  case se of
    seOnDialogueStart:
      tmpl := 'procedure OnDialogueStart(npc, player: TEntity);' + sLineBreak +
              'begin' + sLineBreak +
              '  // Called when dialogue begins' + sLineBreak +
              '  set_npc_attitude(50);  // Neutral' + sLineBreak +
              'end;';
    seOnNodeEnter:
      tmpl := 'procedure OnNodeEnter(npc, player: TEntity; nodeID: string);' + sLineBreak +
              'begin' + sLineBreak +
              '  // Called when entering this node' + sLineBreak +
              'end;';
    seOnOptionSelected:
      tmpl := 'procedure OnOptionSelected(player: TEntity; optionIndex: Integer);' + sLineBreak +
              'begin' + sLineBreak +
              '  // Called when player selects an option' + sLineBreak +
              '  case optionIndex of' + sLineBreak +
              '    0: give_xp(25);' + sLineBreak +
              '    1: modify_karma(10);' + sLineBreak +
              '  end;' + sLineBreak +
              'end;';
    seOnSkillCheck:
      tmpl := 'procedure OnSkillCheck(skill: string; playerVal, difficulty: Integer; passed: Boolean);' + sLineBreak +
              'begin' + sLineBreak +
              '  if passed then' + sLineBreak +
              '    give_xp(50)' + sLineBreak +
              '  else' + sLineBreak +
              '    set_local_var("LVAR_FAILED_CHECK", 1);' + sLineBreak +
              'end;';
    seOnQuestUpdate:
      tmpl := 'procedure OnQuestUpdate(questID: string; newState: Integer);' + sLineBreak +
              'begin' + sLineBreak +
              '  // Quest state changed' + sLineBreak +
              '  add_journal(questID, newState);' + sLineBreak +
              'end;';
    seOnCombatStart:
      tmpl := 'procedure OnCombatStart(npc, player: TEntity);' + sLineBreak +
              'begin' + sLineBreak +
              '  // Triggered when combat begins from dialogue' + sLineBreak +
              '  start_combat();' + sLineBreak +
              'end;';
    seOnDialogueEnd:
      tmpl := 'procedure OnDialogueEnd(npc, player: TEntity);' + sLineBreak +
              'begin' + sLineBreak +
              '  // Cleanup after dialogue ends' + sLineBreak +
              '  set_global_var("GVAR_MET_NPC", 1);' + sLineBreak +
              'end;';
  else
    tmpl := '// Script template' + sLineBreak + 'begin' + sLineBreak + 'end;';
  end;
  memoEditor.Lines.Add('');
  memoEditor.Lines.Add(tmpl);
end;

procedure TScriptEditorForm.memoEditorKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
var row, col: Integer;
begin
  row := memoEditor.CaretPos.Y + 1;
  col := memoEditor.CaretPos.X + 1;
  lblLineInfo.Caption := 'Ln ' + IntToStr(row) + '  Col ' + IntToStr(col) +
    '  Lines: ' + IntToStr(memoEditor.Lines.Count);
end;

procedure TScriptEditorForm.btnOKClick(Sender: TObject); begin ModalResult := mrOk; end;
procedure TScriptEditorForm.btnValidateClick(Sender: TObject); begin ValidateScript; end;
procedure TScriptEditorForm.btnInsertTemplateClick(Sender: TObject); begin InsertTemplate; end;

initialization
  RegisterClass(TScriptEditorForm);
end.