program pgAdminDaemon;

uses
  Vcl.Forms,
  Windows,
  Main in 'Main.pas' {frmMain},
  AHK_Unicode_Implementation in 'AHK_Unicode_Implementation.pas',
  Core.WndControl in 'Core.WndControl.pas',
  DBObjectNameForm in 'DBObjectNameForm.pas' {frmDBObjectName};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  Application.ShowMainForm := False;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
