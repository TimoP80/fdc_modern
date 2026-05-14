unit FalloutUtils;

interface

uses
  System.SysUtils, System.Classes;

type
  TFalloutUtils = class
  public
    class function EscapeMSGText(const AText: string): string;
    class function GenerateNodeID(ANodeType: string): string;
  end;

implementation

{ TFalloutUtils }

class function TFalloutUtils.EscapeMSGText(const AText: string): string;
begin
  Result := AText.Replace('}', '\}', [rfReplaceAll]).Replace('{', '\{', [rfReplaceAll]);
end;

class function TFalloutUtils.GenerateNodeID(ANodeType: string): string;
begin
  Result := LowerCase(ANodeType) + '_' + FormatDateTime('hhnnsszzz', Now);
end;

end.