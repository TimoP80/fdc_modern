unit VariableSystem;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TVariableType = (vtGlobal, vtLocal, vtQuestFlag, vtKarma, vtReputation, vtInventory, vtPartyMember);

  TVariable = class
  private
    FName: string;
    FVarType: TVariableType;
    FValue: Integer;
    FDefaultValue: Integer;
  public
    constructor Create(const AName: string; AType: TVariableType);

    property Name: string read FName;
    property VarType: TVariableType read FVarType write FVarType;
    property Value: Integer read FValue write FValue;
    property DefaultValue: Integer read FDefaultValue write FDefaultValue;
  end;

  TVariableSystem = class
  private
    FVariables: TObjectList<TVariable>;
  public
    constructor Create;
    destructor Destroy; override;

    function AddVariable(const AName: string; AType: TVariableType): TVariable;
    function FindVariable(const AName: string): TVariable;
    procedure ResetToDefaults;

    property Variables: TObjectList<TVariable> read FVariables;
  end;

implementation

{ TVariable }

constructor TVariable.Create(const AName: string; AType: TVariableType);
begin
  inherited Create;
  FName := AName;
  FVarType := AType;
  FValue := 0;
  FDefaultValue := 0;
end;

{ TVariableSystem }

constructor TVariableSystem.Create;
begin
  inherited;
  FVariables := TObjectList<TVariable>.Create(True);
end;

destructor TVariableSystem.Destroy;
begin
  FVariables.Free;
  inherited;
end;

function TVariableSystem.AddVariable(const AName: string; AType: TVariableType): TVariable;
begin
  Result := TVariable.Create(AName, AType);
  FVariables.Add(Result);
end;

function TVariableSystem.FindVariable(const AName: string): TVariable;
var
  VarItem: TVariable;
begin
  for VarItem in FVariables do
    if VarItem.Name = AName then
      Exit(VarItem);
  Result := nil;
end;

procedure TVariableSystem.ResetToDefaults;
var
  VarItem: TVariable;
begin
  for VarItem in FVariables do
    VarItem.Value := VarItem.DefaultValue;
end;

end.