unit DialogueCompiler;

interface

uses
  System.SysUtils, System.Classes, uDialogueTypes, uExportManager;

type
  TDialogueCompiler = class
  public
    class function CompileToSSL(AProject: TDialogueProject; const ASSLPath, AMSGPath: string): Boolean;
  end;

implementation

{ TDialogueCompiler }

class function TDialogueCompiler.CompileToSSL(AProject: TDialogueProject;
  const ASSLPath, AMSGPath: string): Boolean;
var
  mgr: TExportManager;
  opts: TExportOptions;
  res: TExportResult;
begin
  mgr := TExportManager.Create(AProject);
  try
    opts := TExportManager.DefaultOptions;
    opts.Format := efSSL;
    opts.OutputPath := ASSLPath;
    res := mgr.Export(opts);
    if not res.Success then
    begin
      Result := False;
      Exit;
    end;

    opts.Format := efMSG;
    opts.OutputPath := AMSGPath;
    res := mgr.Export(opts);
    Result := res.Success;
  finally
    mgr.Free;
  end;
end;

end.