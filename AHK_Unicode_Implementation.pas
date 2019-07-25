unit AHK_Unicode_Implementation;

interface

Uses
  {Delphi}
  WinAPI.Windows
  , Vcl.Forms
  , Vcl.Dialogs
  , Classes
  , SysUtils
  , Vcl.ClipBrd
  , IOUtils
  , System.Generics.Collections
  , TlHelp32
  , ShellAPI
  , Messages
  , Variants
  , Vcl.Graphics
  , Vcl.Controls
  , PsAPI
  , StrUtils
  , Data.DB
  , Diagnostics
  {Project}
  , Core.WndControl
  ;

const
  SB_GETPARTS = (WM_USER + 6);
  SB_GETTEXTLENGTH = (WM_USER + 12);
  SB_GETTEXT = (WM_USER + 13);
  KEYEVENTF_KEYDOWN = 0;
  ERROR_NOT_FOUND = 1168; // Element not found.

type
  TMouseButton = (LeftClick, RightClick);

type
  TWndProcess = record
    MainWndHandle: HWND;
    MainWndCaption: string;
    PID: integer;
    ProcessPath: string;
    ChildWindows: TArray<TPair<HWND, string>>;
  end;

function GetProcessWindow(const AWindowTitle: string;
  const AProcessID: Cardinal): HWND;
function GetProcessPID(const AProcessFileName: string): integer;
function GetProcessPath(const APID: DWord): string;
function GetProcessMainWindow(const AProcessPath: string): TWndProcess;
function ProcessExists(const AProcessName: string): boolean;
function ProcessClose(const AProcessFileName: string): boolean;
function ProcessWaitClose(const AProcessFileName: string; const AMilliSeconds: Extended): Boolean;
function RunApplication(const AExecutableFile, AParameters: string;
  const AShowOption: Integer = SW_SHOWNORMAL): Integer;

function GetCaptionByClassName(const AWinClassName: string): string;
function IfWinExist(const AWinTitle, AWinText: string): boolean;
function IsWindowResponsive(const AWinTitle: string; const ATimeOut: integer): Boolean; overload;
function IsWindowResponsive(const AWinHandle: HWND; const ATimeOut: integer): Boolean; overload;
function WinGetActiveTitle(out AWindowHandle: HWND): string; overload;
function WinGetActiveTitle: string; overload;
function WinGetHandle(const AWinTitle, AWinText: string): HWND;
function WinActivate(const AWinTitle: string): boolean; overload;
function WinActivate(const AWinTitle, AWinText: string): boolean; overload;
function WinWaitActive(const AWinTitle: string; const AMilliSeconds: extended)
  : boolean; overload;
function WinWaitNotActive(const AWinTitle, AWinText: string;
  const AMilliSeconds: extended): boolean;
function WinWaitActive(const AWinTitle, AWinText: string;
  const AMilliSeconds: extended): boolean; overload;
function WinWait(const AWinTitle: string; const AMilliSeconds: extended)
  : boolean; overload;
function WinWaitHide(const AWinTitle, AWinText: string; const AMilliSeconds: Integer): boolean;
function WinWaitVisible(const AWinTitle, AWinText: string; const AMilliSeconds: Integer): boolean;
function WinWait(const AWinTitle, AWinText: string;
  const AMilliSeconds: extended): boolean; overload;
function WinWaitClose(const AWinTitle, AWinText: string;
  const AMilliSeconds: Integer): boolean;
function WinClose(const AWinTitle, AWinText: string;
  const AMilliSeconds: Integer): boolean;
function WinGetText(const AWinTitle: string): string;
function WinGetPos(const AWinTitle: string;
  out X, Y, AWidth, AHeight: Integer): boolean; overload;
function WinGetPos(const AWinHandle: HWND;
  out X, Y, AWidth, AHeight: Integer): boolean; overload;

function ControlLocate(const AWindowHandle: HWND;
  const AControlClass, AControlText: string;
  const ALocateOptions: TLocateOptions): TArray<TWndControl>;
function ControlGetFocus(const AWinTitle, AWinText: string;
  const AGetHandle: boolean): string; overload;
function ControlGetFocus(const AWinTitle, AWinText: string; const AGetHandle: boolean;
  const ATimeOut: integer): string; overload;
function ControlGetPos(const AControl, AWinTitle, AWinText: string;
  out X, Y, AWidth, AHeight: Integer): boolean;
function GetControlHandle(const AControl, AWinTitle, AWinText: string;
  out AControlHandle: HWND): boolean;
function ControlSetText(const AControl, ANewText, AWinTitle: string): boolean;
function ControlGetText(const AControl, AWinTitle: string): string;
function ControlClick(const AControl, AWinTitle: string): boolean; overload;
function ControlClick(const AControl, AWinTitle: string; const X, Y: Integer)
  : boolean; overload;
function ControlFocus(const AControl, AWinTitle: string): boolean;
function ControlWaitFocus(const AControl, AWinTitle: string; const AMilliSeconds: Extended): boolean;
function ControlAtPoint(const APoint: TPoint;
  const AGetHandle: boolean): string;
function ControlSetEnabled(const AControl: string; const AMainWndHandle: HWND;
  AEnable: boolean): boolean;

procedure PostKeyEx32(Key: Word; const shift: TShiftState; specialkey: boolean);
function SendText(const AText: string): boolean;
function MouseScroll(const ADown: boolean; const AScrollUnits: Word): boolean;
procedure MouseClick(const AMouseAction: System.Word; const X, Y: Integer);

procedure SendEnterKeyPress;
procedure SendKeyPress(const AKeyCode: Byte);

function FileReadLine(const AFilename: string; const ALineNum: Integer): string;
function FileCountLines(const AFilename: string): Integer;
function FileInsertLine(const AText, AFilename: string;
  const ALineNum: Integer): boolean;
function FileDeleteLine(const AFilename: string;
  const ALineNum: Integer): boolean;
function FileAppend(const AText, AFilename: string): boolean;
function FileRead(const AFilename: string): string;

function FileGetTime(out AFileDateTime: TDateTime; const AFile: string;
  const AWhichTime: Char = 'M'): boolean;
function FileSetTime(const ANewDateTime: TDateTime; const AFile: string;
  const AWhichTime: Char = 'M'): boolean;

function ClipWait(const AMiliSecondsToWait: Integer): boolean;

function PixelGetColor(const X, Y: Integer): string;

function ClickX(const ACoordinates: string = 'x';
  const AClickCount: Integer = 1; const ADelay: Integer = 0): boolean;

function ImageSearch(const ASubimageFile: string): TRect;

function A_LastError: integer;

implementation

type
  PEnumInfo = ^TEnumInfo;

  TEnumInfo = record
    ControlHandles: TList<HWND>;
    ControlClasses: TList<String>;
  end;

const
  MESSAGE_TIME_OUT_MS = 10000;

var
  FLastError: integer;

function A_LastError: integer;
begin
  Result := FLastError;
end;

procedure ResetError;
begin
  FLastError := 0;
  SetLastError(0);
end;

function AllowSetForegroundWindow(dwProcessId: DWORD): BOOL; stdcall; external 'user32.dll';

function ControlGetTextByHandle(const AControlHandle: HWND): string;
var
  _ControlText: string;
  _ItemCount: integer;
  _ControlListText: string;
  _ControlTextLen: integer;
  _ActualLength: integer;
  j: integer;
  _Success: bOOLEAN;
begin
  Result := '';
  _ControlText := '';

  _ControlTextLen := 0;
  ResetError;
  _Success := SendMessageTimeOut(AControlHandle, WM_GETTEXTLENGTH, 0, 0,
    SMTO_ABORTIFHUNG, MESSAGE_TIME_OUT_MS, PDWORD_PTR(@_ControlTextLen)) <> 0;

  if not _Success then
  begin
    FLastError := GetLastError;
    Exit;
  end;

  _ControlTextLen := _ControlTextLen + 2;
  SetLength(_ControlText, _ControlTextLen);
  for j := 0 to Length(_ControlText) - 1 do
    _ControlText[j] := #0;

  _ActualLength := 0;
  ResetError;
  _Success := SendMessageTimeOut(AControlHandle, WM_GETTEXT, WPARAM(_ControlTextLen),
    LPARAM(_ControlText), SMTO_ABORTIFHUNG, MESSAGE_TIME_OUT_MS, PDWORD_PTR(@_ActualLength)) <> 0;

  if not _Success then
  begin
    FLastError := GetLastError;
    Exit;
  end;
  SetLength(_ControlText, _ActualLength);

  _ControlListText := '';
  _ItemCount := 0;
  //_ItemCount := SendMessage(AControlHandle, LB_GETCOUNT, 0, 0);
  ResetError;
  _Success := SendMessageTimeOut(AControlHandle, LB_GETCOUNT, 0, 0,
    SMTO_ABORTIFHUNG, MESSAGE_TIME_OUT_MS, PDWORD_PTR(@_ItemCount)) <> 0;

  if not _Success then
  begin
    FLastError := GetLastError;
    Exit;
  end;

  if _ItemCount <> LB_ERR then
  begin
    for j := 0 to _ItemCount - 1 do
    begin
      _ControlTextLen := 0;
      ResetError;
      _Success := SendMessageTimeOut(AControlHandle, LB_GETTEXTLEN, j, 0,
        SMTO_ABORTIFHUNG, MESSAGE_TIME_OUT_MS, PDWORD_PTR(@_ControlTextLen)) <> 0;

      if not _Success then
      begin
        FLastError := GetLastError;
        Exit;
      end;

      //_ControlTextLen := SendMessage(AControlHandle, LB_GETTEXTLEN, j, 0);
      _ControlTextLen := _ControlTextLen + 2;
      SetLength(_ControlListText, _ControlTextLen);
      SendMessage(AControlHandle, LB_GETTEXT, j, LPARAM(_ControlListText));
      if Trim(_ControlListText) <> '' then
        _ControlText := _ControlText + sLineBreak + _ControlListText;
    end;
  end;

  _ControlListText := '';
  _ItemCount := SendMessage(AControlHandle, CB_GETCOUNT, 0, 0);
  if _ItemCount <> CB_ERR then
  begin
    for j := 0 to _ItemCount -1 do
    begin
      _ControlTextLen := SendMessage(AControlHandle, CB_GETLBTEXTLEN, j, 0);
      SetLength(_ControlListText, _ControlTextLen);
      SendMessage(AControlHandle, CB_GETLBTEXT, j, LPARAM(_ControlListText));
      if Trim(_ControlListText) <> '' then
        _ControlText := _ControlText + sLineBreak + _ControlListText;
    end;
  end;

  {_ControlListText := '';
  _ItemCount := SendMessage(AControlHandle, SB_GETPARTS, 0, 0);
  if _ItemCount <> 0 then
  begin
    for j := 0 to _ItemCount - 1 do
    begin
      _ControlTextLen := SendMessage(AControlHandle, SB_GETTEXTLENGTH, j, 0);
      SetLength(_ControlListText, _ControlTextLen);
      // VirtualAllocEx is needed, because SB_GETTEXT works only on current process
      //SendMessage(AControlHandle, SB_GETTEXT, j, LPARAM(_ControlListText));
      if Trim(_ControlListText) <> '' then
        _ControlText := _ControlText + sLineBreak + _ControlListText;
    end;
  end;}

  Result := _ControlText;
end;

function EnumChildren(AWindowHandle: HWND; ALParam: lParam): bool; stdcall;
var
  _ClassName: array [0 .. MAX_PATH] of Char;
  _MainWndHandle: HWND;
  i, _NextNumber: Integer;
begin
  if (Assigned(PEnumInfo(ALParam).ControlHandles)) and
    (Assigned(PEnumInfo(ALParam).ControlClasses)) then
  begin
    _NextNumber := 1;
    if PEnumInfo(ALParam).ControlHandles.Count = 0 then
    begin
      _MainWndHandle := GetAncestor(AWindowHandle, GA_ROOT);
      PEnumInfo(ALParam).ControlHandles.Add(_MainWndHandle);
      GetClassName(_MainWndHandle, _ClassName, Length(_ClassName));
      PEnumInfo(ALParam).ControlClasses.Add(_ClassName);
    end;

    ResetError;
    PEnumInfo(ALParam).ControlHandles.Add(AWindowHandle);
    if GetClassName(AWindowHandle, _ClassName, Length(_ClassName)) = 0 then
    begin
      FLastError := GetLastError;
      OutputDebugString(PWideChar('GetClassName FAILED: ' + IntToStr(FLastError)));
    end;

    for i := 0 to PEnumInfo(ALParam).ControlClasses.Count - 1 do
    begin
      if Pos(_ClassName, PEnumInfo(ALParam).ControlClasses[i]) = 1 then
        Inc(_NextNumber);
    end;

    PEnumInfo(ALParam).ControlClasses.Add(_ClassName + IntToStr(_NextNumber));
  end;
  Result := true;
end;

// Runs application and returns PID. 0 if failed.
function RunApplication(const AExecutableFile, AParameters: string;
  const AShowOption: Integer = SW_SHOWNORMAL): Integer;
var
  _SEInfo: TShellExecuteInfo;
begin
  Result := 0;
  if not FileExists(AExecutableFile) then
    Exit;

  FillChar(_SEInfo, SizeOf(_SEInfo), 0);
  _SEInfo.cbSize := SizeOf(TShellExecuteInfo);
  _SEInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  // _SEInfo.Wnd := Application.Handle;
  _SEInfo.lpFile := PChar(AExecutableFile);
  _SEInfo.lpParameters := PChar(AParameters);
  _SEInfo.lpDirectory := PChar(ExtractFilePath(AExecutableFile));
  _SEInfo.nShow := AShowOption;
  if ShellExecuteEx(@_SEInfo) then
  begin
    WaitForInputIdle(_SEInfo.hProcess, 3000);
    Result := GetProcessID(_SEInfo.hProcess);
  end;
end;

function EnableAllPrivileges: Boolean;
var
  c1: THandle;
  c2: Cardinal;
  ptp: PTokenPrivileges;
  i1: integer;
begin
  Result := false;
  if OpenProcessToken(WinAPI.Windows.GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or
    TOKEN_QUERY, c1) then
    try
      c2 := 0;
      GetTokenInformation(c1, TokenPrivileges, nil, 0, c2);
      if c2 <> 0 then
      begin
        ptp := AllocMem(c2);
        if GetTokenInformation(c1, TokenPrivileges, ptp, c2, c2) then
        begin
          for i1 := 0 to integer(ptp^.PrivilegeCount) - 1 do
            ptp^.Privileges[i1].Attributes := ptp^.Privileges[i1].Attributes or
              SE_PRIVILEGE_ENABLED;
          Result := AdjustTokenPrivileges(c1, false, ptp^, c2, PTokenPrivileges(nil)^,
            cardinal(pointer(nil)^));
        end;
        FreeMem(ptp);
      end;
    finally
      CloseHandle(c1)
    end;
end;

function GetProcessPath(const APID: DWord): string;
var
  _ProcessHandle: THandle;
  _Len: DWord;
begin
  EnableAllPrivileges;
  Result := '';
  ResetError;
  _ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ,
    False, APID);

  if (_ProcessHandle = 0) then
  begin
    FLastError := GetLastError;
    Exit;
  end;

  try
    SetLength(Result, MAX_PATH);
    _Len := GetModuleFileNameEx(_ProcessHandle, 0, PChar(Result), Length(Result));
    FLastError := GetLastError;
    if _Len <> 0 then
      SetLength(Result, _Len);
  finally
    CloseHandle(_ProcessHandle);
  end;
end;

function EnumWindowsProcesses(AWndHandle: HWND; AWinProcesses: LParam): BOOL; stdcall;

  function EnumChildren(AWindowHandle: HWND; ALParam: lParam): bool; stdcall;
  var
    _ControlTextLen: Integer;
    _ControlText: string;
    _ChildWnd: TPair<hwnd, string>;
  begin
    _ControlTextLen := SendMessage(AWindowHandle, WM_GETTEXTLENGTH, 0, 0) + 1;
    SetLength(_ControlText, _ControlTextLen + 1);
    SendMessage(AWindowHandle, WM_GETTEXT, _ControlTextLen,
      lParam(PCHAR(_ControlText)));
    SetLength(_ControlText, Length(_ControlText) - 2);

    _ChildWnd.Key := AWindowHandle;
    _ChildWnd.Value := _ControlText;

    TList<TPair<hwnd, string>>(ALParam).Add(_ChildWnd);

    Result := True;
  end;

  function EnumThreadWndProc(AWindowHandle: HWND; ALParam: lParam): bool; stdcall;
  var
    _ControlTextLen: Integer;
    _ControlText: string;
    _ChildWnd: TPair<hwnd, string>;
    _ClassName: array [0 .. MAX_PATH] of Char;
  begin
    Result := True;
    if not IsWindowVisible(AWindowHandle) then
      Exit;

    _ControlTextLen := SendMessage(AWindowHandle, WM_GETTEXTLENGTH, 0, 0) + 1;
    SetLength(_ControlText, _ControlTextLen + 1);
    SendMessage(AWindowHandle, WM_GETTEXT, _ControlTextLen,
      lParam(PCHAR(_ControlText)));
    SetLength(_ControlText, Length(_ControlText) - 2);

    _ChildWnd.Key := AWindowHandle;
    _ChildWnd.Value := _ControlText;
    if (_ChildWnd.Value <> '') then
    begin
      GetClassName(AWindowHandle, _ClassName, Length(_ClassName));
      if _ClassName <> 'THintWindow' then
        TList<TPair<hwnd, string>>(ALParam).Add(_ChildWnd);
    end;

    Result := True;
  end;

var
  _WndCaption: Array [0 .. MAX_PATH] of Char;
  _ClassName: array [0 .. MAX_PATH] of Char;
  _WinProcess: TWndProcess;
  _ChildWindows: TList<TPair<hwnd, string>>;
  i: Integer;
  _WndThread: integer;
begin
  Result := True;
  ResetError;
  
  if IsWindowVisible(AWndHandle) and ((GetWindowLong(AWndHandle, GWL_HWNDPARENT) = 0) or
    (HWND(GetWindowLong(AWndHandle, GWL_HWNDPARENT)) = GetDesktopWindow)) and
    ((GetWindowLong(AWndHandle, GWL_EXSTYLE) and WS_EX_TOOLWINDOW) = 0) then
  begin
    ZeroMemory(@_ClassName, SizeOf(_ClassName));
    GetClassName(AWndHandle, _ClassName, Length(_ClassName));
    if _ClassName = 'THintWindow' then
      Exit;

    ZeroMemory(@_WndCaption, SizeOf(_WndCaption));
    GetWindowText(AWndHandle, _WndCaption, Length(_WndCaption));

    if not IsWindowResponsive(_WndCaption, MESSAGE_TIME_OUT_MS) then
    begin
      OutputDebugString(PWideChar('Window "' + _WndCaption + '" is not responsive (2).'));
      //FLastError := 1298; // ERROR_APP_HANG
      //Result := False;
      Exit;
    end;
    
    _WinProcess := Default(TWndProcess);

    _WndThread := GetWindowThreadProcessId(AWndHandle, @_WinProcess.PID);
    if _WinProcess.PID <> 0 then
    begin
      _WinProcess.ProcessPath := GetProcessPath(_WinProcess.PID);
      _WinProcess.MainWndHandle := AWndHandle;
      _WinProcess.MainWndCaption := _WndCaption;

      _ChildWindows := TList<TPair<hwnd, string>>.Create;
      try
        EnumThreadWindows(_WndThread, @EnumThreadWndProc, LParam(_ChildWindows));

        Setlength(_WinProcess.ChildWindows, 0);
        for i := 0 to _ChildWindows.Count - 1 do
        begin
          if _ChildWindows[i].Key = _WinProcess.MainWndHandle then
            Continue;

          if _ClassName = 'THintWindow' then
            Continue;

          Setlength(_WinProcess.ChildWindows, Length(_WinProcess.ChildWindows) + 1);
          _WinProcess.ChildWindows[Length(_WinProcess.ChildWindows) - 1] := _ChildWindows[i];
        end;
      finally
        FreeAndNil(_ChildWindows);
      end;

      TList<TWndProcess>(AWinProcesses).Add(_WinProcess);
    end;
  end;
end;

function GetWindowsProcesses: TArray<TWndProcess>;
var
  _WndProcesses: TList<TWndProcess>;
  i: Integer;
begin
  ResetError;
  _WndProcesses := TList<TWndProcess>.Create;
  try
    EnumWindows(@EnumWindowsProcesses, LParam(_WndProcesses));
    SetLength(Result, _WndProcesses.Count);

    for i := 0 to _WndProcesses.Count - 1 do
      Result[i] := _WndProcesses[i];
  finally
    FreeAndNil(_WndProcesses);
  end;
end;

function GetProcessMainWindow(const AProcessPath: string): TWndProcess;
var
  _WndProcesses: TArray<TWndProcess>;
  i: integer;
begin
  ResetError;
  Result := Default(TWndProcess);
  _WndProcesses := GetWindowsProcesses;
  for i := 0 to Length(_WndProcesses) - 1 do
  begin
    if UpperCase(AProcessPath) = UpperCase(_WndProcesses[i].ProcessPath) then
    begin
      Result := _WndProcesses[i];
      Break;
    end;
  end;
end;

function GetProcessWindow(const AWindowTitle: string;
  const AProcessID: Cardinal): HWND;
var
  _WindowHandle: HWND;
  _ProcessID: Cardinal;
  _LoopCount: Integer;
begin
  _WindowHandle := 0;
  Result := _WindowHandle;
  if (AProcessID = 0) then
    Exit;

  _LoopCount := 100;
  while (_LoopCount > 0) do
  begin
    _WindowHandle := FindWindowEx(0, _WindowHandle, nil,
      PWideChar(AWindowTitle));

    GetWindowThreadProcessId(_WindowHandle, _ProcessID);
    if (_ProcessID = AProcessID) then
      Break;

    _LoopCount := _LoopCount - 1;
  end;
  Result := _WindowHandle;
end;

function GetCaptionByClassName(const AWinClassName: string): string;
var
  _hWnd: HWND;
  _WndTitle: array [0 .. MAX_PATH] of Char;
begin
  _hWnd := FindWindow(PWideChar(AWinClassName), nil);
  if _hWnd <> 0 then
    if GetWindowText(_hWnd, _WndTitle, Length(_WndTitle)) <> 0 then
      Result := string(_WndTitle);
end;

function IfWinExist(const AWinTitle, AWinText: string): boolean;
begin
  Result := FindWindow(nil, PWideChar(AWinTitle)) > 0;
  if Result then
  begin
    if AWinText <> '' then
      Result := WinWait(AWinTitle, AWinText, 1000);
  end;
end;

function WinGetPos(const AWinHandle: HWND;
  out X, Y, AWidth, AHeight: Integer): boolean;
var
  _WindowRect: TRect;
begin
  Result := False;

  Result := GetWindowRect(AWinHandle, &_WindowRect);
  if Result then
  begin
    X := _WindowRect.Left;
    Y := _WindowRect.Top;
    AWidth := _WindowRect.Width;
    AHeight := _WindowRect.Height;
  end;
end;

function WinGetPos(const AWinTitle: string;
  out X, Y, AWidth, AHeight: Integer): boolean;
var
  _WindowHandle: HWND;
  _WindowRect: TRect;
begin
  Result := False;

  _WindowHandle := FindWindow(nil, PWideChar(AWinTitle));
  if _WindowHandle = 0 then
    Exit;

  Result := GetWindowRect(_WindowHandle, &_WindowRect);
  if Result then
  begin
    X := _WindowRect.Left;
    Y := _WindowRect.Top;
    AWidth := _WindowRect.Width;
    AHeight := _WindowRect.Height;
  end;
end;

function WinGetActiveTitle: string;
var
  _WindowHandle: HWND;
begin
  Result := WinGetActiveTitle(_WindowHandle);
end;

function WinGetActiveTitle(out AWindowHandle: HWND): string;
var
  _hWnd: HWND;
  _WndTitle: array [0 .. MAX_PATH] of Char;
  _MousePos: TPoint;
  _ClassName: array [0 .. MAX_PATH] of Char;
  _TimeOut: integer;
begin
  Result := '';
  _hWnd := GetForegroundWindow;
  if _hWnd = 0 then
  begin
    _TimeOut := 10;
    // Pasak MSDN gali būti, kad keičiasi langų fokusas, tai palaukiam, kol pasikeis
    while _hWnd = 0 do
    begin
      _hWnd := GetForegroundWindow;
      Sleep(20);
      _TimeOut := _TimeOut - 1;
      if _TimeOut <= 0 then
        Break;
    end;
  end;

  if _hWnd <> 0 then
  begin
    // Pasitikrinam klasės vardą, jei tai hintas, tai patraukiam kursorių
    GetClassName(_hWnd, _ClassName, Length(_ClassName));
    if _ClassName = 'THintWindow' then
    begin
      GetCursorPos(_MousePos);
      SetCursorPos (-1, -1);
      _hWnd := GetForegroundWindow;
      SetCursorPos(_MousePos.X, _MousePos.Y);
    end;

    if _hWnd <> 0 then
    begin
      if GetWindowText(_hWnd, _WndTitle, Length(_WndTitle)) <> 0 then
      begin
        Result := string(_WndTitle);
        AWindowHandle := _hWnd;
      end;
    end;
  end;
end;

function WinGetHandle(const AWinTitle, AWinText: string): HWND;
var
  _WinText: string;
begin
  Result := 0;
  if AWinText <> '' then
    _WinText := WinGetText(AWinTitle);
  if (AnsiContainsText(_WinText, AWinText) or (AWinText = '')) then
    Result := FindWindow(nil, PWideChar(AWinTitle));
end;

function WinActivate(const AWinTitle: string): boolean;
const
  METHOD_NAME = 'WinActivate';
var
  _WindowHandle: HWND;
  _KeyboardState: TKeyboardState;
  _WindowThread: Cardinal;
  _ProcessID: Cardinal;
  _AppHandle: THandle;
  _Form: TForm;
  _CurrentProcessID: Cardinal;
  _CurrentWindowThread: Cardinal;
  _Attached: Boolean;
begin
  ResetError;
  _Attached := False;
  _WindowThread := 0;
  _CurrentWindowThread := 0;
  _Form := nil;

  // Jei langas jau aktyvus, tai nieko nekeičiam
  Result := WinGetActiveTitle = AWinTitle;
  if Result then
    Exit;

  try
    _WindowHandle := FindWindow(nil, PWideChar(AWinTitle));
    FLastError := GetLastError;
{$IFDEF DEBUG}
    OutputDebugString(PWideChar(METHOD_NAME + ': FLastError1: ' + IntTostr(FLastError) +
      ', _WindowHandle: ' + Format('%.8X', [_WindowHandle])));
{$ENDIF DEBUG}
    if _WindowHandle <> 0 then
    begin
      _WindowThread := GetWindowThreadProcessId(_WindowHandle, _ProcessID);
      if _WindowThread = 0 then
      begin
{$IFDEF DEBUG}
        OutputDebugString(PWideChar(METHOD_NAME + ': GetWindowThreadProcessId FAILED.'));
{$ENDIF DEBUG}
        Exit;
      end;

      _AppHandle := Application.Handle;
      if _AppHandle = 0 then
      begin
        _Form := TForm.Create(nil);
        _AppHandle := _Form.Handle;
      end;

      _CurrentWindowThread := GetWindowThreadProcessId(_AppHandle, _CurrentProcessID);
      if _CurrentWindowThread = 0 then
        Exit;

      if not AttachThreadInput(_WindowThread, _CurrentWindowThread, True) then
      begin
        FLastError := GetLastError;
{$IFDEF DEBUG}
        OutputDebugString(PWideChar(METHOD_NAME + ': AttachThreadInput FAILED: ' + IntToStr(FLastError)));
{$ENDIF DEBUG}
        Exit;
      end;

      _Attached := True;

      if IsIconic(_WindowHandle) then
      begin
        ShowWindow(_WindowHandle, SW_RESTORE);
        ResetError;
        Result := IsIconic(_WindowHandle);
        if Result then
          Result := WinWaitActive(AWinTitle, 1000);
      end
      else
        Result := SetForegroundWindow(_WindowHandle);

      if not Result then
      begin
        FLastError := GetLastError;
{$IFDEF DEBUG}
        OutputDebugString(PWideChar(METHOD_NAME + ': FLastError2: ' + IntTostr(FLastError) +
          ', _WindowHandle: ' + Format('%.8X', [_WindowHandle])));
{$ENDIF DEBUG}

        // Applications might lock focus, so, hack it around
        GetKeyBoardState(_KeyboardState);

        if _KeyboardState[VK_MENU] <> 1 then
          keybd_event(VK_MENU, 0, KEYEVENTF_EXTENDEDKEY or 0, 0);

        Result := SetForegroundWindow(_WindowHandle);
        keybd_event(VK_MENU, 0, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);
      end;

      if not Result then
      begin
        SendKeyPress(VK_MENU);
        SendKeyPress(VK_MENU);
        ResetError;
        if not BringWindowToTop(_WindowHandle) then
        begin
          FLastError := GetLastError;
{$IFDEF DEBUG}
          OutputDebugString(PWideChar(METHOD_NAME + ': BringWindowToTop FAILED: ' +
            IntTostr(FLastError) + ', _WindowHandle: ' + Format('%.8X', [_WindowHandle])));
{$ENDIF DEBUG}
        end
        else
          Result := SetForegroundWindow(_WindowHandle);
      end;

      if not Result then
      begin
        ResetError;
        if not SetWindowPos(_WindowHandle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE) then
        begin
          FLastError := GetLastError;
{$IFDEF DEBUG}
          OutputDebugString(PWideChar(METHOD_NAME + ': SetWindowPos FAILED: ' +
            IntTostr(FLastError) + ', _WindowHandle: ' + Format('%.8X', [_WindowHandle])));
{$ENDIF DEBUG}
        end
        else
          Result := SetForegroundWindow(_WindowHandle);
      end;

      // Palaukiam, kol langas susiaktyvuos
      Result := WinWaitActive(AWinTitle, 1000);
    end;

  finally
    if _Attached then
      AttachThreadInput(_WindowThread, _CurrentWindowThread, not _Attached);

    if Assigned(_Form) then
      FreeAndNil(_Form);
  end;
end;

function WinActivate(const AWinTitle, AWinText: string): boolean;
var
  _WinText: string;
begin
  Result := WinActivate(AWinTitle);
  if not Result then
    Exit;

  _WinText := WinGetText(WinGetActiveTitle);
  Result := AnsiContainsText(_WinText, AWinText);
end;

function WinWaitNotActive(const AWinTitle, AWinText: string;
  const AMilliSeconds: extended): boolean;
var
  _StopWatch: TStopWatch;
  _ActiveWinTitle: string;
begin
  _StopWatch := TStopWatch.Create;
  _StopWatch.Start;

  while True do
  begin
    if _StopWatch.ElapsedMilliseconds > AMilliSeconds then
      Break;

    _ActiveWinTitle := WinGetActiveTitle;
    if _ActiveWinTitle <> AWinTitle then
      Break;
  end;

  Result := _StopWatch.ElapsedMilliseconds < AMilliSeconds;
  if not Result then
    FLastError := WAIT_TIMEOUT;
end;

function WinWaitActive(const AWinTitle, AWinText: string;
  const AMilliSeconds: extended): boolean;
var
  _WinText: string;
  _StopWatch: TStopWatch;
begin
  _StopWatch := TStopWatch.Create;
  _StopWatch.Start;

  Result := WinWaitActive(AWinTitle, AMilliSeconds);
  if Result then
  begin
    while (true) do
    begin
      _WinText := WinGetText(AWinTitle);
      Result := AWinText = '';
      if not Result then
        Result := AnsiContainsText(_WinText, AWinText);

      if Result then
        Break
      else
      begin
        if _StopWatch.ElapsedMilliseconds >= AMilliSeconds then
          Break;
      end;
    end;
  end;

  if not Result then
    FLastError := WAIT_TIMEOUT;

  _StopWatch.Stop;
end;

function WinWaitActive(const AWinTitle: string;
  const AMilliSeconds: extended): boolean;
var
  _Handle: THandle;
  _WndTitle: array [0 .. MAX_PATH] of Char;
  _StopWatch: TStopWatch;
begin
  _WndTitle := '';

  _StopWatch := TStopWatch.Create;
  _StopWatch.Start;
  while True do
  begin
    _Handle := GetForegroundWindow;
    if _Handle <> 0 then
    begin
      GetWindowText(_Handle, _WndTitle, Length(_WndTitle));
      if ((LowerCase(_WndTitle) = LowerCase(AWinTitle))) then
      begin
        if IsWindowVisible(_Handle) then
        begin
          _StopWatch.Stop;
          Break;
        end;
      end;

      // FIXME: Patikrinti ar reikia padaryti tikrinimą ar langas turi fokusą
      if _StopWatch.ElapsedMilliseconds > AMilliSeconds then
      begin
        _StopWatch.Stop;
        Break;
      end;
    end;
  end;
  Result := _StopWatch.ElapsedMilliseconds <= AMilliSeconds;
end;

function WinClose(const AWinTitle, AWinText: string;
  const AMilliSeconds: Integer): boolean;
var
  _WindowHandle: HWND;
begin
  _WindowHandle := FindWindow(nil, PWideChar(AWinTitle));
  PostMessage(_WindowHandle, WM_CLOSE, 0, 0);
  Result := WinWaitClose(AWinTitle, AWinText, AMilliSeconds);
end;

function WinWaitClose(const AWinTitle, AWinText: string;
  const AMilliSeconds: Integer): boolean;
var
  _StopWatch: TStopWatch;
begin
  Result := IfWinExist(AWinTitle, AWinText);
  if not Result then
  begin
    Result := true;
    Exit;
  end;

  _StopWatch := TStopWatch.Create;
  _StopWatch.Start;
  while (FindWindow(nil, PWideChar(AWinTitle)) <> 0) do
  begin
    if _StopWatch.ElapsedMilliseconds > AMilliSeconds then
      Break;
  end;
  _StopWatch.Stop;
  Result := not IfWinExist(AWinTitle, AWinText);
end;

function WinWaitVisible(const AWinTitle, AWinText: string; const AMilliSeconds: Integer): boolean;
var
  _StopWatch: TStopWatch;
  _WindowHandle: HWND;
begin
  Result := IfWinExist(AWinTitle, AWinText);
  if not Result then
    Exit;

  _StopWatch := TStopWatch.Create;
  _StopWatch.Start;
  _WindowHandle := FindWindow(nil, PWideChar(AWinTitle));
  while (_WindowHandle <> 0) do
  begin
    _WindowHandle := FindWindow(nil, PWideChar(AWinTitle));

    if IsWindowVisible(_WindowHandle) then
      Break;

    if _StopWatch.ElapsedMilliseconds > AMilliSeconds then
      Break;
  end;
  _StopWatch.Stop;

  if _WindowHandle = 0 then
    Result := False
  else
    Result := IsWindowVisible(_WindowHandle);
end;

function WinWaitHide(const AWinTitle, AWinText: string; const AMilliSeconds: Integer): boolean;
var
  _StopWatch: TStopWatch;
  _WindowHandle: HWND;
begin
  Result := IfWinExist(AWinTitle, AWinText);
  if not Result then
  begin
    Result := True;
    Exit;
  end;

  _StopWatch := TStopWatch.Create;
  _StopWatch.Start;
  _WindowHandle := FindWindow(nil, PWideChar(AWinTitle));
  while (_WindowHandle <> 0) do
  begin
    _WindowHandle := FindWindow(nil, PWideChar(AWinTitle));

    if not IsWindowVisible(_WindowHandle) then
      Break;

    if _StopWatch.ElapsedMilliseconds > AMilliSeconds then
      Break;
  end;
  _StopWatch.Stop;

  Result := (not IsWindowVisible(_WindowHandle)) or (_WindowHandle = 0);
end;

function WinWait(const AWinTitle, AWinText: string;
  const AMilliSeconds: extended): boolean; overload;
var
  _WinText: string;
  _MilliSeconds: extended;
begin
  Result := WinWait(AWinTitle, AMilliSeconds);
  if not Result then
    Exit;

  _MilliSeconds := AMilliSeconds;
  _WinText := WinGetText(AWinTitle);
  while (not AnsiContainsText(_WinText, AWinText)) and (_MilliSeconds > 0) do
  begin
    Sleep(1);
    _WinText := WinGetText(AWinTitle);
    _MilliSeconds := _MilliSeconds - 1;
  end;

  Result := AnsiContainsText(_WinText, AWinText);
end;

function WinWait(const AWinTitle: string; const AMilliSeconds: extended)
  : boolean; overload;
var
  _MilliSeconds: extended;
begin
  Result := False;
  _MilliSeconds := AMilliSeconds;
  while (FindWindow(nil, PWideChar(AWinTitle)) = 0) and (_MilliSeconds > 0) do
  begin
    Sleep(1);
    _MilliSeconds := _MilliSeconds - 1;
  end;
  if (FindWindow(nil, PWideChar(AWinTitle)) > 0) then
    Result := true;
end;

function IsWindowResponsive(const AWinTitle: string; const ATimeOut: integer): Boolean;
var
  _WindowHandle: HWND;
begin
  Result := True;

  _WindowHandle := FindWindow(nil, PWideChar(AWinTitle));
  if _WindowHandle <> 0 then
    Result := IsWindowResponsive(_WindowHandle, ATimeOut);
end;

function IsWindowResponsive(const AWinHandle: HWND; const ATimeOut: integer): Boolean;
var
  _TextLen: integer;
begin
  _TextLen := 0;
  Result := SendMessageTimeOut(AWinHandle, WM_GETTEXTLENGTH, 0, 0,
    SMTO_ABORTIFHUNG, ATimeOut, PDWORD_PTR(@_TextLen)) <> 0;
end;

function WinGetText(const AWinTitle: string): string;
  function EnumChildren(AWindowHandle: HWND; ALParam: lParam): bool; stdcall;
  var
    _ControlText: string;
  begin
    _ControlText := ControlGetTextByHandle(AWindowHandle);
    if _ControlText <> '' then
      TStrings(ALParam).Add(_ControlText);
    Result := true;
  end;

var
  _MainWindowHandle: HWND;
  _WindowTextList: TStringlist;
begin
  Result := '';
  ResetError;

  _MainWindowHandle := FindWindow(nil, PWideChar(AWinTitle));
  if _MainWindowHandle <> 0 then
  begin
    if not IsWindowResponsive(AWinTitle, MESSAGE_TIME_OUT_MS) then
    begin
      OutputDebugString(PWideChar('Window "' + AWinTitle + '" is not responsive (1).'));
      FLastError := 1298; // ERROR_APP_HANG
      Exit;
    end;

    _WindowTextList := TStringlist.Create;
    try
      try
        EnumChildWindows(_MainWindowHandle, @EnumChildren,
          UINT_PTR(_WindowTextList));
        Result := _WindowTextList.Text;
      except
        //on E: Exception do
         // MessageDlg(E.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0)
      end;
    finally
      FreeAndNil(_WindowTextList);
    end;
  end;
end;

procedure SendKeyPress(const AKeyCode: Byte);
begin
  keybd_event(AKeyCode, 0, KEYEVENTF_KEYDOWN, 0);
  keybd_event(AKeyCode, 0, KEYEVENTF_KEYUP, 0);
end;

procedure SendEnterKeyPress;
begin
  keybd_event(VK_RETURN, 0, KEYEVENTF_KEYDOWN, 0);
  keybd_event(VK_RETURN, 0, KEYEVENTF_KEYUP, 0);
end;

{ *
  * AControl: Control handle determined by Spy++ (e.g. 0037064A)
  * or classname+number (e.g. Edit5)
  * ANewText: Text to assign to control
  * AWinTitle: Window Title/Caption
  * }
function ControlSetText(const AControl, ANewText, AWinTitle: string): boolean;
var
  _MainWindowHandle, _ControlHandle: HWND;
  _EnumInfo: TEnumInfo;
  i: Integer;
begin
  Result := False;
  if AControl = '' then
    Exit;

  _MainWindowHandle := FindWindow(nil, PWideChar(AWinTitle));
  if _MainWindowHandle <> 0 then
  begin
    _EnumInfo.ControlHandles := TList<HWND>.Create;
    _EnumInfo.ControlClasses := TList<String>.Create;
    try
      EnumChildWindows(_MainWindowHandle, @EnumChildren, lParam(@_EnumInfo));
{$IFDEF WIN64}
      TryStrToInt64('$' + Trim(AControl), Int64(_ControlHandle));
{$ELSE}
      TryStrToInt('$' + Trim(AControl), Integer(_ControlHandle));
{$ENDIF WIN64}
      for i := 0 to _EnumInfo.ControlHandles.Count - 1 do
      begin
        if (_ControlHandle = _EnumInfo.ControlHandles.Items[i]) then
        begin
          Result := SendMessage(_EnumInfo.ControlHandles.Items[i], WM_SETTEXT,
            0, Integer(PChar(ANewText))) = 1;
          Break;
        end
        else if AControl = _EnumInfo.ControlClasses[i] then
        begin
          Result := SendMessage(_EnumInfo.ControlHandles.Items[i], WM_SETTEXT,
            0, Integer(PChar(ANewText))) = 1;
          Break;
        end
      end;

      if Result then
        Result := ControlGetText(AControl, AWinTitle) = ANewText;
    finally
      FreeAndNil(_EnumInfo.ControlHandles);
      FreeAndNil(_EnumInfo.ControlClasses);
    end;
  end;
end;

{ *
  * AControl: Control handle determined by Spy++ (e.g. 0037064A)
  * or classname+number (e.g. Edit5)
  * AWinTitle: Window Title/Caption
  * }
function ControlGetText(const AControl, AWinTitle: string): string;
var
  _MainWindowHandle, _ControlHandle: HWND;
  _EnumInfo: TEnumInfo;
  i: Integer;
  _ControlFound: Boolean;
begin
  Result := '';
  ResetError;
  _ControlFound := False;
  _MainWindowHandle := FindWindow(nil, PWideChar(AWinTitle));
  if _MainWindowHandle = 0 then
  begin
    FLastError := GetLastError;
    Exit;
  end;

  _EnumInfo.ControlHandles := TList<HWND>.Create;
  _EnumInfo.ControlClasses := TList<String>.Create;
  try
    EnumChildWindows(_MainWindowHandle, @EnumChildren, lParam(@_EnumInfo));
{$IFDEF WIN64}
    TryStrToInt64('$' + Trim(AControl), Int64(_ControlHandle));
{$ELSE}
    TryStrToInt('$' + Trim(AControl), Integer(_ControlHandle));
{$ENDIF WIN64}
    for i := 0 to _EnumInfo.ControlHandles.Count - 1 do
    begin
      if (_ControlHandle = _EnumInfo.ControlHandles.Items[i]) or
        (AControl = _EnumInfo.ControlClasses[i]) then
      begin
        Result := ControlGetTextByHandle(_EnumInfo.ControlHandles.Items[i]);
        _ControlFound := True;

        Break;
      end;
    end;

    if not _ControlFound then
      FLastError := ERROR_NOT_FOUND;
  finally
    FreeAndNil(_EnumInfo.ControlHandles);
    FreeAndNil(_EnumInfo.ControlClasses);
  end;
end;

// Eina per visus AWindowHandle control'sus ir ieško AControlClass klasės control'o, kurio tekstas
// pilnai arba dalinai (priklauso nuo ALocateOptions) atitinka AControlText
// ir pagal AGetHandle grąžina arba control'o HWND (kaip Sky++) arba klasės identifikatorių
// Klasės identifikatorius skaičiuojamas pagal AWindowHandle konteinerį, todėl jei ieškoma GroupBox'e,
// tai sunumeruos vienaip, o jei ieškoma visame TForm - sunumeruos kitaip
function ControlLocate(const AWindowHandle: HWND;
  const AControlClass, AControlText: string;
  const ALocateOptions: TLocateOptions): TArray<TWndControl>;
var
  _ControlText: string;
  _EnumInfo: TEnumInfo;
  i: Integer;
  _WndControl: TWndControl;
  _ControlClass: string;
begin
  Result := nil;

  FLastError := 0;
  if AWindowHandle = 0 then
  begin
    FLastError := ERROR_INVALID_WINDOW_HANDLE;
    Exit;
  end;

  _EnumInfo.ControlHandles := TList<HWND>.Create;
  _EnumInfo.ControlClasses := TList<String>.Create;
  try
    EnumChildWindows(AWindowHandle, @EnumChildren, lParam(@_EnumInfo));

    for i := 0 to _EnumInfo.ControlHandles.Count - 1 do
    begin
      _ControlClass := Copy(_EnumInfo.ControlClasses[i], 1, Length(AControlClass));
      if (AControlClass = _ControlClass) then
      begin
        _ControlText := ControlGetTextByHandle(_EnumInfo.ControlHandles[i]);

        if AControlText <> '' then
        begin
          if not AnsiContainsText(_ControlText, AControlText) then
            Continue;
        end;

        SetLength(Result, Length(Result) + 1);

        _WndControl.ID := _EnumInfo.ControlClasses.Items[i];
        _WndControl.Wnd.Caption := _ControlText;
        _WndControl.Wnd.Handle := Format('%.8X', [_EnumInfo.ControlHandles.Items[i]]);

        Result[Length(Result) - 1] := _WndControl;
      end;
    end;
  finally
    FreeAndNil(_EnumInfo.ControlClasses);
    FreeAndNil(_EnumInfo.ControlHandles);
  end;
end;

function ControlGetFocus2(const AWinTitle, AWinText: string; const AGetHandle: boolean): string;
var
  _WindowHandle: HWND;
  _ActiveWindowThread: Cardinal;
  _ProcessID: Cardinal;
  _CurrentProcessID: Cardinal;
  _CurrentWindowThread: Cardinal;
  _FocusedControlHandle: HWND;
  _EnumInfo: TEnumInfo;
  i: Integer;
  _AppHandle: THandle;
  _Form: Tform;
begin
  Result := '';
  _Form := nil;

  try
    _WindowHandle := WinGetHandle(AWinTitle, AWinText);
    if _WindowHandle = 0 then
      Exit;

    _ActiveWindowThread := GetWindowThreadProcessId(_WindowHandle, _ProcessID);
    if _ActiveWindowThread = 0 then
      Exit;

    _AppHandle := Application.Handle;
    if _AppHandle = 0 then
    begin
      _Form := TForm.Create(nil);
      _AppHandle := _Form.Handle;
    end;

    _CurrentWindowThread := GetWindowThreadProcessId(_AppHandle, _CurrentProcessID);
    if _CurrentWindowThread = 0 then
      Exit;

    if not AttachThreadInput(_ActiveWindowThread, _CurrentWindowThread, true) then
      Exit;

    _FocusedControlHandle := GetFocus();
    AttachThreadInput(_ActiveWindowThread, _CurrentWindowThread, False);
    if AGetHandle then
      Result := Format('%.8X', [_FocusedControlHandle])
    else
    begin
      if (_WindowHandle <> 0) and (_FocusedControlHandle <> 0) then
      begin
        _EnumInfo.ControlHandles := TList<HWND>.Create;
        _EnumInfo.ControlClasses := TList<String>.Create;
        try
          EnumChildWindows(_WindowHandle, @EnumChildren, lParam(@_EnumInfo));

          for i := 0 to _EnumInfo.ControlHandles.Count - 1 do
          begin
            if (_FocusedControlHandle = _EnumInfo.ControlHandles.Items[i]) then
            begin
              Result := _EnumInfo.ControlClasses[i];
              Break;
            end;
          end;
        finally
          FreeAndNil(_EnumInfo.ControlHandles);
          FreeAndNil(_EnumInfo.ControlClasses);
        end;
      end;
    end;
  finally
    FreeAndNil(_Form);
  end;
end;

{
  Specified window may not exist yet
}
function ControlGetFocus(const AWinTitle, AWinText: string; const AGetHandle: boolean;
  const ATimeOut: integer): string;
var
  _StopWatch: TStopWatch;
begin
  Result := '';
  ResetError;

  _StopWatch := TStopWatch.Create;
  _StopWatch.Start;
  while (True) do
  begin
    Result := ControlGetFocus2(AWinTitle, AWinText, AGetHandle);
    if (Result <> '') then
      Break;

    if _StopWatch.ElapsedMilliseconds > ATimeOut then
      Break;
  end;
  _StopWatch.Stop;

  if Result <> '' then
    Exit;

  if (FLastError = ERROR_SUCCESS) then
   FLastError := WAIT_TIMEOUT;
end;

{
  Specified window must exist
}
function ControlGetFocus(const AWinTitle, AWinText: string;
  const AGetHandle: boolean): string;
begin
  Result := '';
  ResetError;
  if WinGetHandle(AWinTitle, AWinText) = 0 then
    Exit;

  Result := ControlGetFocus(AWinTitle, AWinText, AGetHandle, 5000);
end;

{ *
  * AControl: Control handle determined by Spy++ (e.g. 0037064A)
  * or classname+number (e.g. Edit5)
  * AWinTitle: Window Title/Caption
  * }
function ControlGetPos(const AControl, AWinTitle, AWinText: string;
  out X, Y, AWidth, AHeight: Integer): boolean;
var
  _ControlHandle: HWND;
  _WindowRect: TRect;
begin
  ResetError;
  _ControlHandle := 0;
{$IFDEF WIN64}
    TryStrToInt64('$' + Trim(AControl), Int64(_ControlHandle));
{$ELSE}
    TryStrToInt('$' + Trim(AControl), Integer(_ControlHandle));
{$ENDIF WIN64}
  if _ControlHandle = 0 then
  begin
    Result := GetControlHandle(AControl, AWinTitle, AWinText, _ControlHandle);
    if not Result then
      Exit;
  end;

  Result := GetWindowRect(_ControlHandle, &_WindowRect);
  if not Result then
  begin
    FLastError := GetLastError;
    Exit;
  end;

  X := _WindowRect.Left;
  Y := _WindowRect.Top;
  AWidth := _WindowRect.Width;
  AHeight := _WindowRect.Height;
end;

function GetControlHandle(const AControl, AWinTitle, AWinText: string;
  out AControlHandle: HWND): boolean;
var
  _MainWindowHandle, _ControlHandle: HWND;
  _EnumInfo: TEnumInfo;
  i: Integer;
begin
  ResetError;
  Result := False;
  _MainWindowHandle := FindWindow(nil, PWideChar(AWinTitle));
  if _MainWindowHandle = 0 then
  begin
    FLastError := GetLastError;
    Exit;
  end;

  _EnumInfo.ControlHandles := TList<HWND>.Create;
  _EnumInfo.ControlClasses := TList<String>.Create;
  try
    EnumChildWindows(_MainWindowHandle, @EnumChildren, lParam(@_EnumInfo));
{$IFDEF WIN64}
    TryStrToInt64('$' + Trim(AControl), Int64(_ControlHandle));
{$ELSE}
    TryStrToInt('$' + Trim(AControl), Integer(_ControlHandle));
{$ENDIF WIN64}
    for i := 0 to _EnumInfo.ControlHandles.Count - 1 do
    begin
      if (_ControlHandle = _EnumInfo.ControlHandles.Items[i]) or
        (AControl = _EnumInfo.ControlClasses[i]) then
      begin
        AControlHandle := _EnumInfo.ControlHandles.Items[i];
        Result := True;
        Break;
      end;
    end;
  finally
    FreeAndNil(_EnumInfo.ControlHandles);
    FreeAndNil(_EnumInfo.ControlClasses);
  end;
end;

{ *
  * AControl: Control handle determined by Spy++ (e.g. 0037064A)
  * or classname+number (e.g. Edit5)
  * AWinTitle: Window Title/Caption
  * X, Y are coordinates relative to control
  *
}
function ControlClick(const AControl, AWinTitle: string;
  const X, Y: Integer): boolean;
const
  TIMEOUT = 100;
var
  _X: Integer;
  _Y: Integer;
  _Width: Integer;
  _Height: Integer;
begin
  ResetError;
  Result := ControlGetPos(AControl, AWinTitle, '', _X, _Y, _Width, _Height);
  if not Result then
    Exit;

  Result := SetCursorPos(_X + X, _Y + Y);
  if not Result then
  begin
    FLastError := GetLastError;
    Exit;
  end;

  mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
  mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);

  // Netikrinti čia ar paspaustas controlsas turi fokusą, nes jį paspaudus
  // jis tyčia gali fokusą uždėti kitur, pvz paspaudus mygtuką
  Result := True;
end;

{ *
  * AControl: Control handle determined by Spy++ (e.g. 0037064A)
  * or classname+number (e.g. Edit5)
  * AWinTitle: Window Title/Caption
  * }
function ControlClick(const AControl, AWinTitle: string): boolean;
begin
  ResetError;
  Result := ControlClick(AControl, AWinTitle, 1, 1);
end;

{ *
  * AControl: Control handle determined by Spy++ (e.g. 0037064A)
  * or classname+number (e.g. Edit5)
  * AWinTitle: Window Title/Caption
  * }
function ControlFocus(const AControl, AWinTitle: string): boolean;
var
  _ControlHandle: HWND;
begin
  Result := GetControlHandle(AControl, AWinTitle, '', _ControlHandle);
  if not Result then
    Exit;

  ResetError;
  Result := SendMessageTimeout(_ControlHandle, WM_SETFOCUS, 0, 0, SMTO_ABORTIFHUNG,
    MESSAGE_TIME_OUT_MS, nil) <> 0;

  if not Result then
    FLastError := GetLastError;
end;

{ *
  * AControl: Control handle determined by Spy++ (e.g. 0037064A)
  * or classname+number (e.g. Edit5)
  * AWinTitle: Window Title/Caption
  * }
function ControlWaitFocus(const AControl, AWinTitle: string; const AMilliSeconds: Extended): boolean;
var
  _StopWatch: TStopWatch;
  _FocusedControl: string;
  _HandleUsed: Boolean;
begin
  Result := False;

  if WinGetActiveTitle <> AWinTitle then
    Exit;

  _HandleUsed := StrToIntDef(AControl, -1) > 0;
  _StopWatch := TStopWatch.Create;
  _StopWatch.Start;
  while (_FocusedControl <> AControl) do
  begin
    _FocusedControl := ControlGetFocus(AWinTitle, '', _HandleUsed);

    if _StopWatch.ElapsedMilliseconds > AMilliSeconds then
      Break;
  end;
  _StopWatch.Stop;

  Result := _FocusedControl = AControl;
end;

{ *
  * Gets Control Handle or ClassName+ID at point
  * Usage: Memo1.Lines.Add(ControlAtPoint(Mouse.CursorPos, False));
  * }
function ControlAtPoint(const APoint: TPoint;
  const AGetHandle: boolean): string;
var
  _MainWindowHandle, _ControlHandle: HWND;
  _EnumInfo: TEnumInfo;
  i: Integer;
  _ptScreen: TPoint;
begin
  _ptScreen := APoint;
  _ControlHandle := WindowFromPoint(_ptScreen);
  WinAPI.Windows.ScreenToClient(_ControlHandle, _ptScreen);
  if ChildWindowFromPoint(_ControlHandle, _ptScreen) <> 0 then
    _ControlHandle := ChildWindowFromPoint(_ControlHandle, _ptScreen);

  if AGetHandle then
  begin
    Result := Format('%.8X', [_ControlHandle]);
    Exit;
  end;

  _MainWindowHandle := GetAncestor(_ControlHandle, GA_ROOT);
  if _MainWindowHandle <> 0 then
  begin
    _EnumInfo.ControlHandles := TList<HWND>.Create;
    _EnumInfo.ControlClasses := TList<String>.Create;
    try
      EnumChildWindows(_MainWindowHandle, @EnumChildren, lParam(@_EnumInfo));
      for i := 0 to _EnumInfo.ControlHandles.Count - 1 do
      begin
        if _EnumInfo.ControlHandles.Items[i] = _ControlHandle then
        begin
          Result := _EnumInfo.ControlClasses.Items[i];
          Break;
        end;
      end;
    finally
      FreeAndNil(_EnumInfo.ControlClasses);
      FreeAndNil(_EnumInfo.ControlHandles);
    end;
  end;
end;

// Function returns control and class name under the cursor
// Works only for self application
function GetDelphiControlNameAtCursor: string;
var
  _WinControl: TWinControl;
begin
  _WinControl := FindVCLWindow(Mouse.CursorPos);

  if _WinControl <> nil then
    Result := _WinControl.Name + ' (' + _WinControl.ClassName + ')';
end;

{ *
  * AControl: Control handle determined by Spy++ (e.g. 0037064A)
  * or classname+number (e.g. Edit5)
  * AWinTitle: Window Title/Caption
  * AEnable: enable or disable control
  * }
function ControlSetEnabled(const AControl: string; const AMainWndHandle: HWND;
  AEnable: boolean): boolean;
var
  _MainWindowHandle, _ControlHandle: HWND;
  _EnumInfo: TEnumInfo;
  i: Integer;
begin
  Result := False;
  _MainWindowHandle := AMainWndHandle;
  if _MainWindowHandle <> 0 then
  begin
    _EnumInfo.ControlHandles := TList<HWND>.Create;
    _EnumInfo.ControlClasses := TList<String>.Create;
    try
      EnumChildWindows(_MainWindowHandle, @EnumChildren, lParam(@_EnumInfo));
{$IFDEF WIN64}
      TryStrToInt64('$' + Trim(AControl), Int64(_ControlHandle));
{$ELSE}
      TryStrToInt('$' + Trim(AControl), Integer(_ControlHandle));
{$ENDIF WIN64}
      for i := 0 to _EnumInfo.ControlHandles.Count - 1 do
      begin
        if (_ControlHandle = _EnumInfo.ControlHandles.Items[i]) or
          (AControl = _EnumInfo.ControlClasses[i]) then
        begin
          EnableWindow(_EnumInfo.ControlHandles.Items[i], AEnable);
          // Force controls to look like as they are supposed to be
          ShowWindow(_EnumInfo.ControlHandles.Items[i], SW_HIDE);
          ShowWindow(_EnumInfo.ControlHandles.Items[i], SW_SHOW);
          Result := IsWindowEnabled(_EnumInfo.ControlHandles.Items[i])
            = AEnable;
          Break;
        end;
      end;
    finally
      FreeAndNil(_EnumInfo.ControlClasses);
      FreeAndNil(_EnumInfo.ControlHandles);
    end;
  end;
end;

// http://delphidabbler.com/tips/170
procedure PostKeyEx32(Key: Word; const shift: TShiftState; specialkey: boolean);
type
  TShiftKeyInfo = record
    shift: Byte;
    vkey: Byte;
  end;

  ByteSet = set of 0 .. 7;
const
  shiftkeys: array [1 .. 3] of TShiftKeyInfo = ((shift: Ord(ssCtrl);
    vkey: VK_CONTROL), (shift: Ord(ssShift); vkey: VK_SHIFT),
    (shift: Ord(ssAlt); vkey: VK_MENU));
var
  flag: DWord;
  bShift: ByteSet absolute shift;
  j: integer;
begin
  for j := 1 to 3 do
  begin
    if shiftkeys[j].shift in bShift then
      keybd_event(shiftkeys[j].vkey, MapVirtualKey(shiftkeys[j].vkey, 0), 0, 0);
  end;
  if specialkey then
    flag := KEYEVENTF_EXTENDEDKEY
  else
    flag := 0;

  keybd_event(Key, MapVirtualKey(Key, 0), flag, 0);
  flag := flag or KEYEVENTF_KEYUP;
  keybd_event(Key, MapVirtualKey(Key, 0), flag, 0);

  for j := 3 downto 1 do
  begin
    if shiftkeys[j].shift in bShift then
      keybd_event(shiftkeys[j].vkey, MapVirtualKey(shiftkeys[j].vkey, 0),
        KEYEVENTF_KEYUP, 0);
  end;
end;

{ *
  * Simulates typing
  * Usage: SendText('UPPERlower eeee1234567890/*-+!"£$%^&*()_+= ąčęėĄČĘįšųūž');
  * }
function SendText(const AText: string): boolean;
var
  i: Integer;
  _Input: TInput;
  _KeybdInput: TKeybdInput;

  _ActiveWindow: HWND;
  _PID: DWord;
  _ProcessHandle: THandle;
const
  KEYEVENTF_UNICODE = $0004;
begin
  ResetError;
  if Length(AText) = 0 then
  begin
    Result := False;
    Exit;
  end;

  _Input.Itype := INPUT_KEYBOARD;
  for i := 1 to Length(AText) do
  begin
    _KeybdInput.wVk := 0;
    _KeybdInput.dwFlags := KEYEVENTF_UNICODE;
    _KeybdInput.wScan := Ord(AText[i]);
    _Input.KI := _KeybdInput;
    if SendInput(1, _Input, SizeOf(_Input)) <> 1 then
    begin
      Result := False;
      Exit;
    end;
    _KeybdInput.dwFlags := KEYEVENTF_UNICODE + KEYEVENTF_KEYUP;
    _Input.KI := _KeybdInput;
    if SendInput(1, _Input, SizeOf(_Input)) <> 1 then
    begin
      Result := False;
      Exit;
    end;
  end;

  Result := False;
  // Gaunam aktyvų langą
  _ActiveWindow := GetForegroundWindow;
  if _ActiveWindow = 0 then
    Exit;

  // Gaunam procesą, kuriam priklauso tas aktyvus langas
  ResetError;
  GetWindowThreadProcessId(_ActiveWindow, @_PID);
  _ProcessHandle := OpenProcess(PROCESS_ALL_ACCESS, False, _PID);
  if _ProcessHandle = 0 then
    Exit;

  ResetError;
  if WaitForInputIdle(_ProcessHandle, MESSAGE_TIME_OUT_MS) <> ERROR_SUCCESS then
    FLastError := GetLastError;

  CloseHandle(_ProcessHandle);

  Result := FLastError = ERROR_SUCCESS;
end;

procedure MouseClick(const AMouseAction: System.Word; const X, Y: Integer);
begin
  SetCursorPos(X, Y);
  mouse_event(AMouseAction, 0, 0, 0, 0);
end;

{ *
  * Scrolls are app dependant e.g. using 50 instead of WHEEL_DELTA will not
  * work for some applications until it reaches value of WHEEL_DELTA(120).
  * Need something else? Use VK_DOWN/VK_UP
  * }
function MouseScroll(const ADown: boolean; const AScrollUnits: Word): boolean;
var
  _Input: TInput;
  i: Integer;
begin
  Result := False;
  _Input.Itype := INPUT_MOUSE;
  _Input.mi.dx := 0;
  _Input.mi.dy := 0;
  _Input.mi.dwFlags := MOUSEEVENTF_WHEEL;
  _Input.mi.time := 0;
  _Input.mi.dwExtraInfo := 0;
  if ADown then
    _Input.mi.mouseData := DWORD(-WHEEL_DELTA)
  else
    _Input.mi.mouseData := DWORD(WHEEL_DELTA);
  for i := 1 to AScrollUnits do
    if SendInput(1, _Input, SizeOf(_Input)) <> 1 then
      Exit
    else
      Result := true;
end;

{ *
  * File operations are optimized to work in all systems (Win, MAC...) and Unicode
  * }
function FileReadLine(const AFilename: string; const ALineNum: Integer): string;
var
  _FileContent: TStringlist;
begin
  Result := '';
  if (FileExists(AFilename)) and (ALineNum > 0) then
  begin
    _FileContent := TStringlist.Create();
    try
      try
        _FileContent.LoadFromFile(AFilename);
        if _FileContent.Count >= ALineNum then
          Result := _FileContent.Strings[ALineNum - 1];
      except
        on E: Exception do
          MessageDlg(E.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0)
      end;
    finally
      FreeAndNil(_FileContent);
    end;
  end;
end;

function FileCountLines(const AFilename: string): Integer;
var
  _FileContent: TStringlist;
begin
  Result := 0;
  if FileExists(AFilename) then
  begin
    _FileContent := TStringlist.Create();
    try
      try
        _FileContent.LoadFromFile(AFilename);
        Result := _FileContent.Count;
      except
        on E: Exception do
          MessageDlg(E.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0)
      end;
    finally
      FreeAndNil(_FileContent);
    end;
  end;
end;

function FileInsertLine(const AText, AFilename: string;
  const ALineNum: Integer): boolean;
var
  _FileContent: TStringlist;
begin
  Result := False;
  if (FileExists(AFilename)) and (ALineNum > 0) then
  begin
    _FileContent := TStringlist.Create();
    try
      try
        _FileContent.LoadFromFile(AFilename);
        if _FileContent.Count >= ALineNum - 1 then
        begin
          _FileContent.Insert(ALineNum - 1, AText);
          _FileContent.SaveToFile(AFilename);
          Result := true;
        end;
      except
        on E: Exception do
          MessageDlg(E.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
      end;
    finally
      FreeAndNil(_FileContent);
    end;
  end;
end;

function FileDeleteLine(const AFilename: string;
  const ALineNum: Integer): boolean;
var
  _FileContent: TStringlist;
begin
  Result := False;
  if (FileExists(AFilename)) and (ALineNum > 0) then
  begin
    _FileContent := TStringlist.Create();
    try
      try
        _FileContent.LoadFromFile(AFilename);
        if _FileContent.Count >= ALineNum then
        begin
          _FileContent.Delete(ALineNum - 1);
          _FileContent.SaveToFile(AFilename);
          Result := true;
        end;
      except
        on E: Exception do
          MessageDlg(E.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
      end;
    finally
      FreeAndNil(_FileContent);
    end;
  end;
end;

function FileAppend(const AText, AFilename: string): boolean;
var
  _FileContent: TStringlist;
begin
  Result := False;
  _FileContent := TStringlist.Create();
  try
    try
      if FileExists(AFilename) then
        _FileContent.LoadFromFile(AFilename)
      else
        ForceDirectories(ExtractFilePath(AFilename));
      _FileContent.Add(AText);
      _FileContent.SaveToFile(AFilename, TEncoding.UTF8);
      Result := true;
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  finally
    FreeAndNil(_FileContent);
  end;
end;

function FileRead(const AFilename: string): string;
var
  _FileContent: TStringlist;
begin
  Result := '';
  if FileExists(AFilename) then
  begin
    _FileContent := TStringlist.Create();
    try
      try
        _FileContent.LoadFromFile(AFilename);
        Result := _FileContent.Text;
      except
        on E: Exception do
          MessageDlg(E.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
      end;
    finally
      FreeAndNil(_FileContent);
    end;
  end;
end;

function GetProcessPID(const AProcessFileName: string): integer;
var
  _ContinueLoop: bool;
  _SnapshotHandle: THandle;
  _ProcessEntry32: TProcessEntry32;
  _PIDPath: string;
begin
  Result := 0;
  if not FileExists(AProcessFileName) then
    Exit;

  _SnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  try
    _ProcessEntry32.dwSize := SizeOf(_ProcessEntry32);
    _ContinueLoop := Process32First(_SnapshotHandle, _ProcessEntry32);
    while Integer(_ContinueLoop) <> 0 do
    begin
      _PIDPath := GetProcessPath(_ProcessEntry32.th32ProcessID);
      if (_PIDPath = AProcessFileName) then
      begin
        Result := _ProcessEntry32.th32ProcessID;
        Break;
      end;

      _ContinueLoop := Process32Next(_SnapshotHandle, _ProcessEntry32);
    end;
  finally
    CloseHandle(_SnapshotHandle);
  end;
end;

function ProcessWaitClose(const AProcessFileName: string; const AMilliSeconds: Extended): Boolean;
var
  _StopWatch: TStopWatch;
begin
  _StopWatch := TStopWatch.Create;
  _StopWatch.Start;
  while _StopWatch.ElapsedMilliseconds < AMilliSeconds do
  begin
    if not ProcessExists(ExtractFileName(AProcessFileName)) then
      Break;
  end;
  _StopWatch.Stop;
  Result := _StopWatch.ElapsedMilliseconds <= AMilliSeconds;
  if Result then
    OutputDebugString(Pwidechar('Uzsidare'))
  else
    OutputDebugString(Pwidechar('NEUzsidare'));
end;

function ProcessClose(const AProcessFileName: string): boolean;
var
  _PID: integer;
  _ProcessHandle: THandle;
begin
  ResetError;
  Result := True;
  if not FileExists(AProcessFileName) then
    Exit;

  _PID := GetProcessPID(AProcessFileName);
  if _PID = 0 then
    Exit;

  while _PID <> 0 do
  begin
    _ProcessHandle := OpenProcess(PROCESS_TERMINATE, False, _PID);
    if _ProcessHandle = 0 then
    begin
      FLastError := GetLastError;
      _PID := GetProcessPID(AProcessFileName);
      Continue;
    end;

    try
      OutputDebugString(PWideChar('Buvau čia: ' + IntToStr(_PID)));
      Result := TerminateProcess(_ProcessHandle, 0);
      FLastError := GetLastError;
      if not Result then
      begin
        OutputDebugString(PWideChar('Nepaejo: ' + IntToStr(_PID)));
        Break;
      end
      else
      begin
        // Duodam laiko procesui užsidaryti
        if not ProcessWaitClose(AProcessFileName, 3000) then
          Break;
      end;

      _PID := GetProcessPID(AProcessFileName);
      OutputDebugString(PWideChar('Gavom: ' + IntToStr(_PID)));
    finally
      CloseHandle(_ProcessHandle);
    end;
  end;
end;

function ProcessExists(const AProcessName: string): boolean;
var
  ContinueLoop: bool;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := False;
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile))
      = UpperCase(AProcessName)) or (UpperCase(FProcessEntry32.szExeFile)
      = UpperCase(AProcessName))) then
    begin
      Result := true;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function ClickX(const ACoordinates: string = 'x';
  const AClickCount: Integer = 1; const ADelay: Integer = 0): boolean;
var
  _CoordX, _CoordY: Integer;
  i: Integer;
begin
  Result := False;
  if ((ACoordinates <> '') and (Pos('x', ACoordinates) <> 0) and
    (AClickCount >= 1)) then
  begin
    if ACoordinates <> 'x' then
    begin
      if TryStrToInt(Copy(ACoordinates, 1, Pos('x', ACoordinates) - 1), _CoordX)
        = true then
        if TryStrToInt(Copy(ACoordinates, Pos('x', ACoordinates) + 1,
          Pos('x', Copy(ACoordinates, 1, (Length(ACoordinates))))), _CoordY) = true
        then
        begin
          SetCursorPos(_CoordX, _CoordY);
          Sleep(50);
          for i := 1 to AClickCount do
          begin
            if ADelay <> 0 then
              Sleep(ADelay);
            mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
            mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
            Result := true;
          end;
        end;
    end;
  end;
end;

function FileGetTime(out AFileDateTime: TDateTime; const AFile: string;
  const AWhichTime: Char = 'M'): boolean;
begin
  Result := False;
  if FileExists(AFile) then
  begin
    case AWhichTime of
      'C', 'c':
        AFileDateTime := IOUtils.TFile.GetCreationTime(AFile);
      'A', 'a':
        AFileDateTime := IOUtils.TFile.GetLastAccessTime(AFile);
    else
      AFileDateTime := IOUtils.TFile.GetLastWriteTime(AFile);
    end;
    Result := true;
  end;
end;

function FileSetTime(const ANewDateTime: TDateTime; const AFile: string;
  const AWhichTime: Char = 'M'): boolean;
begin
  Result := False;
  if FileExists(AFile) then
  begin
    case AWhichTime of
      'C', 'c':
        IOUtils.TFile.SetCreationTime(AFile, ANewDateTime);
      'A', 'a':
        IOUtils.TFile.SetLastAccessTime(AFile, ANewDateTime);
    else
      IOUtils.TFile.SetLastWriteTime(AFile, ANewDateTime);
    end;
    Result := true;
  end;
end;

function ClipWait(const AMiliSecondsToWait: Integer): boolean;
var
  i: Integer;
begin
  i := AMiliSecondsToWait;
  while i > 0 do
  begin
    Sleep(1);
    i := i - 1;
    if Clipboard.FormatCount <> 0 then
    begin
      if not((Clipboard.HasFormat(CF_TEXT)) and (Clipboard.AsText = '')) then
        Break;
    end;
  end;
  if i > 0 then
    Result := true
  else
    Result := False;
end;

function PixelGetColor(const X, Y: Integer): string;
var
  _dc: HDC;
  _Color: TColor;
begin
  if (X >= 0) and (X <= Screen.Width) and (Y >= 0) and (Y <= Screen.Height) then
  begin
    _dc := GetDC(0);
    try
      if _dc <> NULL then
      begin
        _Color := GetPixel(_dc, X, Y);
        Result := IntToHex(GetRValue(_Color), 2) + IntToHex(GetGValue(_Color),
          2) + IntToHex(GetBValue(_Color), 2);
      end;
    finally
      ReleaseDC(0, _dc);
    end;
  end;
end;

type
  TSubImageInfo = record
    X: Integer;
    Y: Integer;
    Color: Integer;
  end;

function ImageSearch(const ASubimageFile: string): TRect;
var
  X, Y, K, _Color: Integer;
  _SubImageInfo: TSubImageInfo;
  _SubImageInfoList: TList<TSubImageInfo>;
  _SmallWidth, _SmallHeight, _BigWidth, _BigHeight: Integer;
  _MatchingPixels: Integer;
  _LTColor, _RTColor, _LBColor, _RBColor: Integer;
  _FirstPixels: TList<TSubImageInfo>;
  _Offset: TPoint;
  _Desktop: HDC;
  _ScreenBitmap: TBitmap;
  _SubImagePic: TPicture;
  _SubImageBitmap: TBitmap;
  _Pos: TPoint;
begin
  Result.Left := -1;
  Result.Top := Result.Left;
  Result.Height := Result.Left;
  Result.Width := Result.Left;

  if not FileExists(ASubimageFile) then
    Exit;

  _SubImageInfoList := TList<TSubImageInfo>.Create;
  _SubImageBitmap := TBitmap.Create;
  _ScreenBitmap := TBitmap.Create;
  _FirstPixels := TList<TSubImageInfo>.Create;
  try
    _SubImagePic := TPicture.Create;
    try
      _SubImagePic.LoadFromFile(ASubimageFile);
      _SubImageBitmap.Assign(_SubImagePic.Graphic);
    finally
      FreeAndNil(_SubImagePic);
    end;

    if (_SubImageBitmap.Height < 3) or (_SubImageBitmap.Width < 3) then
      Exit; // Image is too small

    X := 0;
    Y := _SubImageBitmap.Height div 2;
    while X < _SubImageBitmap.Width - 1 do
    begin
      _SubImageInfo.X := X;
      _SubImageInfo.Y := Y;
      _Color := _SubImageBitmap.Canvas.Pixels[X, Y];
      _SubImageInfo.Color := _Color;
      _SubImageInfoList.Add(_SubImageInfo);
      X := X + 3;
    end;

    Y := 0;
    X := _SubImageBitmap.Width div 2;
    while Y < _SubImageBitmap.Height - 1 do
    begin
      _SubImageInfo.X := X;
      _SubImageInfo.Y := Y;
      _Color := _SubImageBitmap.Canvas.Pixels[X, Y];
      _SubImageInfo.Color := _Color;
      _SubImageInfoList.Add(_SubImageInfo);
      Y := Y + 3;
    end;

    X := 0;
    Y := _SubImageBitmap.Height div 4;
    while X < _SubImageBitmap.Width - 1 do
    begin
      _SubImageInfo.X := X;
      _SubImageInfo.Y := Y;
      _Color := _SubImageBitmap.Canvas.Pixels[X, Y];
      _SubImageInfo.Color := _Color;
      _SubImageInfoList.Add(_SubImageInfo);
      X := X + 3;
    end;

    Y := 0;
    X := _SubImageBitmap.Width div 4;
    while Y < _SubImageBitmap.Height - 1 do
    begin
      _SubImageInfo.X := X;
      _SubImageInfo.Y := Y;
      _Color := _SubImageBitmap.Canvas.Pixels[X, Y];
      _SubImageInfo.Color := _Color;
      _SubImageInfoList.Add(_SubImageInfo);
      Y := Y + 3;
    end;

    X := 0;
    Y := (_SubImageBitmap.Height div 4) + (_SubImageBitmap.Height div 2);
    while X < _SubImageBitmap.Width - 1 do
    begin
      _SubImageInfo.X := X;
      _SubImageInfo.Y := Y;
      _Color := _SubImageBitmap.Canvas.Pixels[X, Y];
      _SubImageInfo.Color := _Color;
      _SubImageInfoList.Add(_SubImageInfo);
      X := X + 3;
    end;

    Y := 0;
    X := (_SubImageBitmap.Width div 4) + (_SubImageBitmap.Width div 2);
    while Y < _SubImageBitmap.Height - 1 do
    begin
      _SubImageInfo.X := X;
      _SubImageInfo.Y := Y;
      _Color := _SubImageBitmap.Canvas.Pixels[X, Y];
      _SubImageInfo.Color := _Color;
      _SubImageInfoList.Add(_SubImageInfo);
      Y := Y + 3;
    end;

    _Desktop := GetDC(0);
    _ScreenBitmap.PixelFormat := pf32bit;
    _ScreenBitmap.Width := Screen.Width;
    _ScreenBitmap.Height := Screen.Height;
    BitBlt(_ScreenBitmap.Canvas.Handle, 0, 0, _ScreenBitmap.Width,
      _ScreenBitmap.Height, _Desktop, 0, 0, SRCCOPY);
    _MatchingPixels := 0;
    _SmallWidth := _SubImageBitmap.Width - 1;
    _SmallHeight := _SubImageBitmap.Height - 1;
    _BigWidth := _ScreenBitmap.Width;
    _BigHeight := _ScreenBitmap.Height;

    _LTColor := _SubImageBitmap.Canvas.Pixels[0, 0];
    _RTColor := _SubImageBitmap.Canvas.Pixels[_SmallWidth, 0];
    _LBColor := _SubImageBitmap.Canvas.Pixels[0, _SmallHeight];
    _RBColor := _SubImageBitmap.Canvas.Pixels[_SmallWidth, _SmallHeight];

    for X := 1 to 3 do
    begin
      for Y := 1 to 3 do
      begin
        _SubImageInfo.X := X;
        _SubImageInfo.Y := Y;
        _SubImageInfo.Color := _SubImageBitmap.Canvas.Pixels[X, Y];
        _FirstPixels.Add(_SubImageInfo);
      end;
    end;

    X := 0;
    while X < _BigWidth - _SmallWidth do
    begin
      Y := 0;
      while Y < _BigHeight - _SmallHeight do
      begin
        _Color := _ScreenBitmap.Canvas.Pixels[X, Y];
        _Offset.X := 0;
        _Offset.Y := 0;
        for K := 0 to _FirstPixels.Count - 1 do
        begin
          if (_Color = _FirstPixels[K].Color) then
          begin
            _Offset.X := _FirstPixels[K].X;
            _Offset.Y := _FirstPixels[K].Y;
            Break;
          end;
        end;

        // Check if all corners matches of smaller image
        if ((_Offset.X <> 0) or (_Color = _LTColor)) and
          (_ScreenBitmap.Canvas.Pixels[X + _SmallWidth, Y] = _RTColor) and
          (_ScreenBitmap.Canvas.Pixels[X, Y + _SmallHeight] = _LBColor) and
          (_ScreenBitmap.Canvas.Pixels[X + _SmallWidth, Y + _SmallHeight]
          = _RBColor) then
        begin
          // Checking if content matches
          for K := 0 to _SubImageInfoList.Count - 1 do
          begin
            _Pos.X := X - _Offset.X + _SubImageInfoList[K].X;
            _Pos.Y := Y - _Offset.Y + _SubImageInfoList[K].Y;
            if (_ScreenBitmap.Canvas.Pixels[_Pos.X, _Pos.Y] = _SubImageInfoList
              [K].Color) then
              _MatchingPixels := _MatchingPixels + 1
            else
            begin
              _Pos.X := X - _Offset.X - 1 + _SubImageInfoList[K].X;
              _Pos.Y := Y - _Offset.Y + 1 + _SubImageInfoList[K].Y;
              if (_ScreenBitmap.Canvas.Pixels[_Pos.X, _Pos.Y]
                = _SubImageInfoList[K].Color) then
                _MatchingPixels := _MatchingPixels + 1
              else
              begin
                _Pos.X := X - _Offset.X + _SubImageInfoList[K].X;
                _Pos.Y := Y - _Offset.Y + 1 + _SubImageInfoList[K].Y;
                if (_ScreenBitmap.Canvas.Pixels[_Pos.X, _Pos.Y]
                  = _SubImageInfoList[K].Color) then
                  _MatchingPixels := _MatchingPixels + 1
                else
                begin
                  _MatchingPixels := 0;
                  Break;
                end;
              end;
            end;
          end;
          if (_MatchingPixels - 1 = _SubImageInfoList.Count - 1) then
          begin
            Result.Left := X - _Offset.X;
            Result.Top := Y - _Offset.Y;

            Result.Width := _SubImageBitmap.Width;
            Result.Height := _SubImageBitmap.Height;
            Exit;
          end;
        end;
        Y := Y + 3;
      end;
      X := X + 3;
    end;

  finally
    FreeAndNil(_FirstPixels);
    FreeAndNil(_ScreenBitmap);
    FreeAndNil(_SubImageBitmap);
    FreeAndNil(_SubImageInfoList);
  end;
end;

end.
