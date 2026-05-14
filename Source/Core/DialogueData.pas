unit DialogueData;

interface

uses
  System.SysUtils, System.Classes, NodeTypes;

type
  TDialogueData = class
  private
    FProject: TDialogueProject;
  public
    constructor Create;
    destructor Destroy; override;
    property Project: TDialogueProject read FProject;
  end;

implementation

{ TDialogueData }

constructor TDialogueData.Create;
begin
  inherited;
  FProject := TDialogueProject.Create;
end;

destructor TDialogueData.Destroy;
begin
  FProject.Free;
  inherited;
end;

end.