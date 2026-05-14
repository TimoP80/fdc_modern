unit Logger;

interface

uses
   System.SysUtils, System.Classes, System.TypInfo;

type
  TLogLevel = (llInfo, llWarning, llError);

  TLogger = class
  private
    FLogFile: TStreamWriter;
    class var FInstance: TLogger;
    constructor Create;
  public
    class function GetInstance: TLogger;
    procedure Log(const AMessage: string; ALevel: TLogLevel = llInfo);
    procedure LogError(const AMessage: string);
    procedure LogWarning(const AMessage: string);
  end;

implementation

{ TLogger }

constructor TLogger.Create;
begin
  FLogFile := TStreamWriter.Create('FalloutDialogueCreator.log', True, TEncoding.UTF8);
end;

class function TLogger.GetInstance: TLogger;
begin
  if not Assigned(FInstance) then
    FInstance := TLogger.Create;
  Result := FInstance;
end;

procedure TLogger.Log(const AMessage: string; ALevel: TLogLevel = llInfo);
begin
  FLogFile.WriteLine(Format('%s [%s] %s', [DateTimeToStr(Now), GetEnumName(TypeInfo(TLogLevel), Integer(ALevel)), AMessage]));
  FLogFile.Flush;
end;

procedure TLogger.LogError(const AMessage: string);
begin
  Log(AMessage, llError);
end;

procedure TLogger.LogWarning(const AMessage: string);
begin
  Log(AMessage, llWarning);
end;

initialization

finalization
  if Assigned(TLogger.FInstance) then
    TLogger.FInstance.Free;

end.