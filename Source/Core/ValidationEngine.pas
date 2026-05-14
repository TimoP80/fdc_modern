unit ValidationEngine;

interface

uses
    System.SysUtils, System.Classes, System.Generics.Collections,
    NodeTypes, VariableSystem, SkillCheckSystem;

type
  TValidationError = record
    NodeID: string;
    Message: string;
    Severity: Integer; // 0=info, 1=warning, 2=error
  end;

  TValidationEngine = class
  public
    class function ValidateProject(AProject: TDialogueProject; AVariableSystem: TVariableSystem; ASkillManager: TSkillCheckManager): TArray<TValidationError>;
    class function ValidateNode(ANode: TDialogueNode; AProject: TDialogueProject): TArray<TValidationError>;
  end;

implementation

{ TValidationEngine }

class function TValidationEngine.ValidateProject(AProject: TDialogueProject; AVariableSystem: TVariableSystem; ASkillManager: TSkillCheckManager): TArray<TValidationError>;
var
  Errors: TList<TValidationError>;
  Node: TDialogueNode;
  Check: TSkillCheck;
  Err: TValidationError;
begin
  Errors := TList<TValidationError>.Create;
  try
    for Node in AProject.Nodes do
      Errors.AddRange(ValidateNode(Node, AProject));

    for Check in ASkillManager.Checks do
    begin
      if (Check.SuccessNodeID <> '') and (AProject.FindNode(Check.SuccessNodeID) = nil) then
      begin
        Err.NodeID := Check.SuccessNodeID; Err.Message := 'Skill check success node not found'; Err.Severity := 2;
        Errors.Add(Err);
      end;
      if (Check.FailureNodeID <> '') and (AProject.FindNode(Check.FailureNodeID) = nil) then
      begin
        Err.NodeID := Check.FailureNodeID; Err.Message := 'Skill check failure node not found'; Err.Severity := 2;
        Errors.Add(Err);
      end;
    end;

    Result := Errors.ToArray;
  finally
    Errors.Free;
  end;
end;

class function TValidationEngine.ValidateNode(ANode: TDialogueNode; AProject: TDialogueProject): TArray<TValidationError>;
var
  Errors: TList<TValidationError>;
  LinkID: string;
  Err: TValidationError;
begin
  Errors := TList<TValidationError>.Create;
  try
    if ANode.Text = '' then
    begin
      Err.NodeID := ANode.ID; Err.Message := 'Node has no text'; Err.Severity := 1;
      Errors.Add(Err);
    end;

    for LinkID in ANode.Links do
      if AProject.FindNode(LinkID) = nil then
      begin
        Err.NodeID := ANode.ID; Err.Message := 'Linked node ' + LinkID + ' not found'; Err.Severity := 2;
        Errors.Add(Err);
      end;

    if ANode.NodeType = dntEnd then
    begin
      if ANode.Links.Count > 0 then
      begin
        Err.NodeID := ANode.ID; Err.Message := 'End node has outgoing links'; Err.Severity := 2;
        Errors.Add(Err);
      end;
    end;

    Result := Errors.ToArray;
  finally
    Errors.Free;
  end;
end;

end.