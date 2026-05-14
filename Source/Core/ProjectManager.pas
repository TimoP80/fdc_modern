unit ProjectManager;

interface

uses
   System.SysUtils, System.Classes, System.DateUtils, Winapi.Windows,
   uDialogueTypes, VariableSystem, SkillCheckSystem, JSONSerializer;

type
   TProjectManager = class
   private
     FCurrentProject: TDialogueProject;
     FVariableSystem: TVariableSystem;
     FSkillCheckManager: TSkillCheckManager;
     FFilePath: string;
     FModified: Boolean;
     FAutosaveInterval: Integer;
     FLastAutosave: TDateTime;
   public
     constructor Create;
     destructor Destroy; override;

     function NewProject(const AName: string): Boolean;
     function LoadProject(const AFilePath: string): Boolean;
     function SaveProject: Boolean;
     function SaveProjectAs(const AFilePath: string): Boolean;
     procedure Autosave;
     function BackupProject: Boolean;

     property CurrentProject: TDialogueProject read FCurrentProject;
     property VariableSystem: TVariableSystem read FVariableSystem;
     property SkillCheckManager: TSkillCheckManager read FSkillCheckManager;
     property FilePath: string read FFilePath;
     property Modified: Boolean read FModified write FModified;
   end;

implementation

{ TProjectManager }

constructor TProjectManager.Create;
begin
  inherited;
  FCurrentProject := TDialogueProject.Create;
  FVariableSystem := TVariableSystem.Create;
  FSkillCheckManager := TSkillCheckManager.Create;
  FModified := False;
  FAutosaveInterval := 5 * 60 * 1000; // 5 minutes
  FLastAutosave := Now;
end;

destructor TProjectManager.Destroy;
begin
  FCurrentProject.Free;
  FVariableSystem.Free;
  FSkillCheckManager.Free;
  inherited;
end;

function TProjectManager.NewProject(const AName: string): Boolean;
begin
  FCurrentProject.Free;
  FCurrentProject := TDialogueProject.Create;
  FCurrentProject.Name := AName;
  FVariableSystem.Variables.Clear;
  FSkillCheckManager.Checks.Clear;
  FFilePath := '';
  FModified := False;
  Result := True;
end;

function TProjectManager.LoadProject(const AFilePath: string): Boolean;
begin
  Result := TJSONSerializer.LoadProject(FCurrentProject, AFilePath);
  if Result then
  begin
    FFilePath := AFilePath;
    FModified := False;
  end;
end;

function TProjectManager.SaveProject: Boolean;
begin
  if FFilePath = '' then
    Result := False
  else
    Result := TJSONSerializer.SaveProject(FCurrentProject, FFilePath);
  if Result then
    FModified := False;
end;

function TProjectManager.SaveProjectAs(const AFilePath: string): Boolean;
begin
  Result := TJSONSerializer.SaveProject(FCurrentProject, AFilePath);
  if Result then
  begin
    FFilePath := AFilePath;
    FModified := False;
  end;
end;

procedure TProjectManager.Autosave;
begin
  if FModified and (MilliSecondsBetween(Now, FLastAutosave) >= FAutosaveInterval) then
  begin
    SaveProject;
    FLastAutosave := Now;
  end;
end;

function TProjectManager.BackupProject: Boolean;
var
  BackupPath: string;
begin
  if FFilePath = '' then
    Exit(False);
  BackupPath := ChangeFileExt(FFilePath, '.bak');
  Result := CopyFile(PChar(FFilePath), PChar(BackupPath), False);
end;

end.