unit JSONSerializer;

// JSONSerializer - Supports FDC (.fdc/.json) project format
// using the uDialogueTypes type system

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.TypInfo,
  System.DateUtils, System.IOUtils,
  uDialogueTypes;

type
  TJSONSerializer = class
  public
    class function SaveProject(AProject: TDialogueProject; const AFilePath: string): Boolean;
    class function LoadProject(AProject: TDialogueProject; const AFilePath: string): Boolean;
  end;

implementation

{ TJSONSerializer }

class function TJSONSerializer.SaveProject(AProject: TDialogueProject; const AFilePath: string): Boolean;
var
  JSONObj: TJSONObject;
  SL: TStringList;
begin
  Result := False;
  JSONObj := AProject.ToJSON;
  if not Assigned(JSONObj) then Exit;
  try
    SL := TStringList.Create;
    try
      SL.Text := JSONObj.Format(2);
      SL.SaveToFile(AFilePath, TEncoding.UTF8);
      AProject.FilePath := AFilePath;
      AProject.Modified := False;
      Result := True;
    finally
      SL.Free;
    end;
  finally
    JSONObj.Free;
  end;
end;

class function TJSONSerializer.LoadProject(AProject: TDialogueProject; const AFilePath: string): Boolean;
var
  SL: TStringList;
  JSONObj: TJSONObject;
begin
  Result := False;
  if not FileExists(AFilePath) then Exit;
  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFilePath, TEncoding.UTF8);
    JSONObj := TJSONObject.ParseJSONValue(SL.Text) as TJSONObject;
    if Assigned(JSONObj) then
    try
      AProject.FromJSON(JSONObj);
      AProject.FilePath := AFilePath;
      AProject.Modified := False;
      Result := True;
    finally
      JSONObj.Free;
    end;
  finally
    SL.Free;
  end;
end;

end.