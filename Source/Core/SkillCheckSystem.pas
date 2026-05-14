unit SkillCheckSystem;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, NodeTypes;

type
  TSkillCheck = class
  private
    FSkill: TSkillType;
    FDifficulty: Integer;
    FSuccessNodeID: string;
    FFailureNodeID: string;
    FCriticalSuccessNodeID: string;
    FCriticalFailureNodeID: string;
    FHasTraitModifier: Boolean;
    FHasPerkModifier: Boolean;
    FHasReputationModifier: Boolean;
  public
    constructor Create;

    property Skill: TSkillType read FSkill write FSkill;
    property Difficulty: Integer read FDifficulty write FDifficulty;
    property SuccessNodeID: string read FSuccessNodeID write FSuccessNodeID;
    property FailureNodeID: string read FFailureNodeID write FFailureNodeID;
    property CriticalSuccessNodeID: string read FCriticalSuccessNodeID write FCriticalSuccessNodeID;
    property CriticalFailureNodeID: string read FCriticalFailureNodeID write FCriticalFailureNodeID;
    property HasTraitModifier: Boolean read FHasTraitModifier write FHasTraitModifier;
    property HasPerkModifier: Boolean read FHasPerkModifier write FHasPerkModifier;
    property HasReputationModifier: Boolean read FHasReputationModifier write FHasReputationModifier;
  end;

  TSkillCheckManager = class
  private
    FChecks: TList<TSkillCheck>;
  public
    constructor Create;
    destructor Destroy; override;

    function AddCheck: TSkillCheck;
    procedure RemoveCheck(ACheck: TSkillCheck);
    function FindCheckByNode(const ANodeID: string): TSkillCheck;

    property Checks: TList<TSkillCheck> read FChecks;
  end;

implementation

{ TSkillCheck }

constructor TSkillCheck.Create;
begin
  inherited;
  FDifficulty := 0;
  FHasTraitModifier := False;
  FHasPerkModifier := False;
  FHasReputationModifier := False;
end;

{ TSkillCheckManager }

constructor TSkillCheckManager.Create;
begin
  inherited;
  FChecks := TList<TSkillCheck>.Create;
end;

destructor TSkillCheckManager.Destroy;
var
  Check: TSkillCheck;
begin
  for Check in FChecks do
    Check.Free;
  FChecks.Free;
  inherited;
end;

function TSkillCheckManager.AddCheck: TSkillCheck;
begin
  Result := TSkillCheck.Create;
  FChecks.Add(Result);
end;

procedure TSkillCheckManager.RemoveCheck(ACheck: TSkillCheck);
begin
  FChecks.Remove(ACheck);
  ACheck.Free;
end;

function TSkillCheckManager.FindCheckByNode(const ANodeID: string): TSkillCheck;
var
  Check: TSkillCheck;
begin
  for Check in FChecks do
    if (Check.SuccessNodeID = ANodeID) or (Check.FailureNodeID = ANodeID) then
      Exit(Check);
  Result := nil;
end;

end.