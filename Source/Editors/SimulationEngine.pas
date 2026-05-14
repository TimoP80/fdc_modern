unit SimulationEngine;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, NodeTypes, VariableSystem, SkillCheckSystem;

type
  TSimulationLogEntry = record
    NodeID: string;
    Text: string;
    Timestamp: TDateTime;
  end;

  TSimulationEngine = class
  private
    FProject: TDialogueProject;
    FVariableSystem: TVariableSystem;
    FSkillManager: TSkillCheckManager;
    FCurrentNode: TDialogueNode;
    FLog: TList<TSimulationLogEntry>;
    FIsRunning: Boolean;
  public
    constructor Create(AProject: TDialogueProject; AVariableSystem: TVariableSystem; ASkillManager: TSkillCheckManager);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;
    function Step: Boolean;
    function SelectOption(ANodeID: string): Boolean;

    property CurrentNode: TDialogueNode read FCurrentNode;
    property Log: TList<TSimulationLogEntry> read FLog;
    property IsRunning: Boolean read FIsRunning;
  end;

implementation

{ TSimulationEngine }

constructor TSimulationEngine.Create(AProject: TDialogueProject; AVariableSystem: TVariableSystem; ASkillManager: TSkillCheckManager);
begin
  inherited Create;
  FProject := AProject;
  FVariableSystem := AVariableSystem;
  FSkillManager := ASkillManager;
  FLog := TList<TSimulationLogEntry>.Create;
  FIsRunning := False;
end;

destructor TSimulationEngine.Destroy;
begin
  FLog.Free;
  inherited;
end;

procedure TSimulationEngine.Start;
var
  entry: TSimulationLogEntry;
begin
  FCurrentNode := FProject.FindNode(FProject.StartNodeID);
  FIsRunning := True;
  entry.NodeID := FCurrentNode.ID;
  entry.Text := FCurrentNode.Text;
  entry.Timestamp := Now;
  FLog.Add(entry);
end;

procedure TSimulationEngine.Stop;
begin
  FIsRunning := False;
  FCurrentNode := nil;
end;

function TSimulationEngine.Step: Boolean;
var
  entry: TSimulationLogEntry;
begin
  Result := False;
  if not FIsRunning or not Assigned(FCurrentNode) then Exit;

  if FCurrentNode.Links.Count > 0 then
  begin
    FCurrentNode := FProject.FindNode(FCurrentNode.Links[0]);
    entry.NodeID := FCurrentNode.ID;
    entry.Text := FCurrentNode.Text;
    entry.Timestamp := Now;
    FLog.Add(entry);
    Result := True;
  end
  else
    Stop;
end;

function TSimulationEngine.SelectOption(ANodeID: string): Boolean;
var
  entry: TSimulationLogEntry;
begin
  Result := False;
  if not FIsRunning or not Assigned(FCurrentNode) then Exit;

  FCurrentNode := FProject.FindNode(ANodeID);
  if Assigned(FCurrentNode) then
  begin
    entry.NodeID := FCurrentNode.ID;
    entry.Text := FCurrentNode.Text;
    entry.Timestamp := Now;
    FLog.Add(entry);
    Result := True;
  end;
end;

end.