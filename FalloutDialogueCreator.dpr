program FalloutDialogueCreator;

uses
   Vcl.Forms,
   uMainForm in 'uMainForm.pas' {MainForm},
   uDialogueTypes in 'uDialogueTypes.pas',
   uNodeCanvas in 'uNodeCanvas.pas',
   uDialogueNode in 'uDialogueNode.pas',
   uSkillCheckEditor in 'uSkillCheckEditor.pas' {SkillCheckEditorForm},
   uNodeProperties in 'uNodeProperties.pas' {NodePropertiesForm},
   uPreviewSystem in 'uPreviewSystem.pas' {PreviewForm},
   uExportManager in 'uExportManager.pas',
   uProjectManager in 'uProjectManager.pas',
   uFloatMessageEditor in 'uFloatMessageEditor.pas' {FloatMessageForm},
   uValidationTools in 'uValidationTools.pas' {ValidationForm},
   uScriptEditor in 'uScriptEditor.pas' {ScriptEditorForm},
   uLocalization in 'uLocalization.pas' {LocalizationForm},
   uAssetBrowser in 'uAssetBrowser.pas' {AssetBrowserForm},
   uThemeManager in 'uThemeManager.pas',
   uSearchPanel in 'uSearchPanel.pas',
   DialogueData in 'Source\Core\DialogueData.pas',
   NodeTypes in 'Source\Core\NodeTypes.pas',
   SkillCheckSystem in 'Source\Core\SkillCheckSystem.pas',
   VariableSystem in 'Source\Core\VariableSystem.pas',
   NodeEditor in 'Source\Editors\NodeEditor.pas',
   SimulationEngine in 'Source\Editors\SimulationEngine.pas',
   FloatMessageEditor in 'Source\Editors\FloatMessageEditor.pas',
   JSONSerializer in 'Source\Exporters\JSONSerializer.pas',
   SSLExporter in 'Source\Exporters\SSLExporter.pas',
   MSGExporter in 'Source\Exporters\MSGExporter.pas',
   DialogueCompiler in 'Source\Exporters\DialogueCompiler.pas',
   ValidationEngine in 'Source\Core\ValidationEngine.pas',
   ProjectManager in 'Source\Core\ProjectManager.pas',
   NodePalette in 'Source\UI\NodePalette.pas',
   FalloutUtils in 'Source\Utilities\FalloutUtils.pas',
   Logger in 'Source\Utilities\Logger.pas',
SSLImporter in 'Source\Importers\SSLImporter.pas',
    MSGImporter in 'Source\Importers\MSGImporter.pas',
    FMFImporter in 'Source\Importers\FMFImporter.pas';

{$R *.res}

begin
   Application.Initialize;
   Application.MainFormOnTaskbar := True;
   Application.Title := 'Fallout Dialogue Creator';
   Application.CreateForm(TMainForm, MainForm);
   Application.Run;
end.