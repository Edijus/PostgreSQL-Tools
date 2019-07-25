unit Main;

interface

uses
  Winapi.Windows
  , Winapi.Messages
  , System.SysUtils
  , System.Variants
  , System.Classes
  , Vcl.Graphics
  , Vcl.Controls
  , Vcl.Forms
  , Vcl.Dialogs
  , Vcl.StdCtrls
  , AHK_Unicode_Implementation
  , Generics.Collections
  , DBObjectNameForm
  ;

type
  TChecker = class(TThread)
  strict private
    FDisabledWindows: TDictionary<HWND, HWND>;
    FSleepTimeMS: Int64;

    procedure CheckWindows;
  public
    constructor Create(const ACheckIntervalMS: Int64); reintroduce;
    procedure Execute; override;
  end;

type
  TfrmMain = class(TForm)
    procedure FormCreate(Sender: TObject);
  strict private const
    WM_SELECT_SQL = WM_USER + 0;
    WM_SELECT_DB_OBJECT = WM_USER + 1;
  strict private
    { Private declarations }
    FChecker: TChecker;
    FCtrlQHotkey: Integer;
    FCtrlShiftSpaceHotkey: Integer;
    FDBObjectForm: TfrmDBObjectName;

    procedure WMHotKey(var Msg: TWMHotKey); message WM_HOTKEY;
    procedure OnSelectSQLMessage(var Msg: TMessage); message WM_SELECT_SQL;
    procedure OnSelectDBObjectMessage(var Msg: TMessage); message WM_SELECT_DB_OBJECT;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  StrUtils
  ;

function ParseConnectionParams(const AWindowCaption: string; out AHost, AUsername, ADatabase: string;
  out APort: integer): Boolean;
var
  _PortStr: string;
begin
  AHost := Copy(AWindowCaption, Pos('@', AWindowCaption) + 1, Length(AWindowCaption));
  AHost := Copy(AHost, 1, Pos(':', AHost) - 1);

  AUsername := Copy(AWindowCaption, Pos(' on ', AWindowCaption) + 4, Length(AWindowCaption));
  AUsername := Copy(AUsername, 1, Pos('@', AUsername) - 1);

  ADatabase := Copy(AWindowCaption, Pos(' - ', AWindowCaption) + 3, Length(AWindowCaption));
  ADatabase := Copy(ADatabase, 1, Pos(' on ', ADatabase) - 1);

  _PortStr := Copy(AWindowCaption, Pos(':', AWindowCaption) + 1, Length(AWindowCaption));
  _PortStr := Trim(StringReplace(_PortStr, '*', '', [rfReplaceAll, rfIgnoreCase]));
  APort := StrTointDef(_PortStr, 0);

  Result := (AHost <> '') and (AUsername <> '') and (ADatabase <> '') and (APort <> 0);
end;

procedure TfrmMain.OnSelectDBObjectMessage(var Msg: TMessage);
var
  _ActiveTileDef: string;
  _WindowHandle: HWND;
  _WndLeft: integer;
  _WndTop: integer;
  _WndWidth: integer;
  _WndHeight: integer;
  _Host: string;
  _Username: string;
  _Database: string;
  _Port: integer;
  _DBObject: string;
begin
  _ActiveTileDef := WinGetActiveTitle(_WindowHandle);
  if not AnsiContainsText(_ActiveTileDef, 'Query - ') then
    Exit;

  if not AnsiContainsText(_ActiveTileDef, '@') then
    Exit;

  if not AnsiContainsText(_ActiveTileDef, ':') then
    Exit;

  if not ParseConnectionParams(_ActiveTileDef, _Host, _Username, _Database, _Port) then
    Exit;

  Sleep(250);

  WinGetPos(_WindowHandle, _WndLeft, _WndTop, _WndWidth, _WndHeight);

  if not Assigned(FDBObjectForm) then
    FDBObjectForm := TfrmDBObjectName.Create(nil);

  if FDBObjectForm.Showing then
  begin
    FDBObjectForm.BringToFront;
    Exit;
  end;

  FDBObjectForm.InitConnectionParams(_Host, _Username, _Database, '', _Port);
  FDBObjectForm.Left := _WndLeft + 6;
  FDBObjectForm.Top := _WndTop + _WndHeight - FDBObjectForm.Height - 6;
  if FDBObjectForm.ShowModal <> mrOk then
  begin
    SetForegroundWindow(_WindowHandle);
    Exit;
  end;

  _DBObject := FDBObjectForm.GetDBObject;
  if _DBObject = '' then
    Exit;

  SetForegroundWindow(_WindowHandle);
  Sleep(100);
  SendText(_DBObject);
end;

procedure TfrmMain.OnSelectSQLMessage(var Msg: TMessage);
var
  _ActiveTileDef: string;
  _WindowHandle: HWND;
  _Text: string;
begin
  _ActiveTileDef := WinGetActiveTitle(_WindowHandle);
  if not AnsiContainsText(_ActiveTileDef, 'Query - ') then
    Exit;

  if not AnsiContainsText(_ActiveTileDef, '@') then
    Exit;

  if not AnsiContainsText(_ActiveTileDef, ':') then
    Exit;

  Sleep(250);

  _Text := 'SELECT' + #13 + '  *' + #13 + 'FROM' + #13 + '  ';
  SendText(_Text);
end;

procedure TfrmMain.WMHotKey(var Msg: TWMHotKey);
begin
  if Msg.HotKey = FCtrlQHotkey then
    PostMessage(Self.Handle, WM_SELECT_SQL, 0, 0)
  else if Msg.HotKey = FCtrlShiftSpaceHotkey then
    PostMessage(Self.Handle, WM_SELECT_DB_OBJECT, 0, 0);
end;

constructor TChecker.Create(const ACheckIntervalMS: Int64);
begin
  inherited Create(True);
  FSleepTimeMS := ACheckIntervalMS;
  FDisabledWindows := TDictionary<HWND, HWND>.Create;
end;

procedure TChecker.Execute;
begin
  inherited;
  while not Self.Terminated do
  begin
    Sleep(FSleepTimeMS);
    CheckWindows;
  end;
end;

procedure TChecker.CheckWindows;
var
  _ActiveTile: string;
  _WinText: string;
  _WindowHandle: HWND;
begin;
  try
    _ActiveTile := WinGetActiveTitle(_WindowHandle);
    if not AnsiContainsText(_ActiveTile, 'Query - ') then
      Exit;

    if FDisabledWindows.ContainsKey(_WindowHandle) then
      Exit;

    _WinText := WinGetText(_ActiveTile);
    if not AnsiContainsText(_WinText, 'Previous queries') then
      Exit;

    if not ControlSetEnabled('ComboBox1', _WindowHandle, False) then
      Exit;

    FDisabledWindows.AddOrSetValue(_WindowHandle, _WindowHandle);
  except

  end;
end;

procedure ProcessHelpCommandLineParam;
var
  i: Integer;
begin
  for i := 0 to ParamCount do
  begin
    if (LowerCase(ParamStr(i)) = '-help') or (LowerCase(ParamStr(i)) = '/help') then
    begin
      ShowMessage('Ctrl+Q to type' + sLineBreak + 'SELECT' + sLineBreak + '  *' + sLineBreak + 'FROM' + sLineBreak +
      sLineBreak + 'Ctrl+Shift+Space for autocompletion');
    end;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
const
  VK_Q = $51;
var
  i: integer;
  _CheckIntervalMS: Int64;
begin
  // Register Hotkey Ctrl + Q
  FCtrlQHotkey := GlobalAddAtom('CtrlQHotkey');
  RegisterHotKey(Handle, FCtrlQHotkey, MOD_CONTROL, VK_Q);

  // Register Hotkey Ctrl + Shift + Space
  FCtrlShiftSpaceHotkey := GlobalAddAtom('CtrlShiftSpaceHotkey');
  RegisterHotKey(Handle, FCtrlShiftSpaceHotkey, MOD_CONTROL + MOD_SHIFT, VK_SPACE);

  Self.Hide;
  _CheckIntervalMS := -1;
  for i := 0 to ParamCount do
  begin
    if _CheckIntervalMS = 0 then
      _CheckIntervalMS := StrToIntDef(ParamStr(i), 1001);

    if ParamStr(i) = '-t' then
      _CheckIntervalMS := 0;
  end;
  ProcessHelpCommandLineParam;

  if _CheckIntervalMS <= 0 then
    _CheckIntervalMS := 1002;

  FChecker := TChecker.Create(_CheckIntervalMS);
  FChecker.Start;
end;

end.
