unit NodeTypes;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Generics.Collections;

type
  TDialogueNodeType = (
    dntNPC,
    dntPlayer,
    dntSkillCheck,
    dntConditionalBranch,
    dntReputationCheck,
    dntQuestCheck,
    dntItemCheck,
    dntScriptAction,
    dntFloatMessage,
    dntEnd
  );

  TSkillType = (
    stSpeech,
    stScience,
    stRepair,
    stLockpick,
    stBarter,
    stGambling,
    stSneak,
    stOutdoorsman,
    stDoctor,
    stFirstAid
  );

  TDialogueNode = class
  private
    FID: string;
    FNodeType: TDialogueNodeType;
    FSpeaker: string;
    FText: string;
    FLinks: TList<string>;
    FPosition: TPoint;
    FSkillCheck: TSkillType;
    FDifficulty: Integer;
    FSuccessNode: string;
    FFailureNode: string;
  public
    constructor Create(const AID: string; ANodeType: TDialogueNodeType);
    destructor Destroy; override;

    property ID: string read FID;
    property NodeType: TDialogueNodeType read FNodeType write FNodeType;
    property Speaker: string read FSpeaker write FSpeaker;
    property Text: string read FText write FText;
    property Links: TList<string> read FLinks;
    property Position: TPoint read FPosition write FPosition;
    property SkillCheck: TSkillType read FSkillCheck write FSkillCheck;
    property Difficulty: Integer read FDifficulty write FDifficulty;
    property SuccessNode: string read FSuccessNode write FSuccessNode;
    property FailureNode: string read FFailureNode write FFailureNode;
  end;

  TDialogueProject = class
  private
    FName: string;
    FNodes: TList<TDialogueNode>;
    FVersion: string;
    FStartNodeID: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddNode(ANode: TDialogueNode);
    function FindNode(const AID: string): TDialogueNode;

    property Name: string read FName write FName;
    property Nodes: TList<TDialogueNode> read FNodes;
    property Version: string read FVersion write FVersion;
    property StartNodeID: string read FStartNodeID write FStartNodeID;
  end;

implementation

{ TDialogueNode }

constructor TDialogueNode.Create(const AID: string; ANodeType: TDialogueNodeType);
begin
  inherited Create;
  FID := AID;
  FNodeType := ANodeType;
  FLinks := TList<string>.Create;
  FPosition := Point(0, 0);
  FDifficulty := 0;
end;

destructor TDialogueNode.Destroy;
begin
  FLinks.Free;
  inherited;
end;

{ TDialogueProject }

constructor TDialogueProject.Create;
begin
  inherited;
  FNodes := TList<TDialogueNode>.Create;
  FVersion := '1.0';
end;

destructor TDialogueProject.Destroy;
var
  Node: TDialogueNode;
begin
  for Node in FNodes do
    Node.Free;
  FNodes.Free;
  inherited;
end;

procedure TDialogueProject.AddNode(ANode: TDialogueNode);
begin
  FNodes.Add(ANode);
end;

function TDialogueProject.FindNode(const AID: string): TDialogueNode;
var
  Node: TDialogueNode;
begin
  for Node in FNodes do
    if Node.ID = AID then
      Exit(Node);
  Result := nil;
end;

end.