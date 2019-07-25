unit DBObjectNameForm;

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
  , Vcl.ExtCtrls
  , ZAbstractConnection
  , ZConnection
  , IOUtils
  , Data.DB
  , ZAbstractRODataset
  , ZAbstractDataset
  , ZDataset
  , StrUtils
  ;

type
  TfrmDBObjectName = class(TForm)
    pnlDBObject: TPanel;
    eDBObject: TEdit;
    lbDBObjectName: TListBox;
    conDBObject: TZConnection;
    qObjects: TZQuery;
    qObjectsdb_object: TWideStringField;
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure eDBObjectChange(Sender: TObject);
    procedure eDBObjectKeyPress(Sender: TObject; var Key: Char);
    procedure lbDBObjectNameDblClick(Sender: TObject);
    procedure eDBObjectKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lbDBObjectNameKeyPress(Sender: TObject; var Key: Char);
    procedure lbDBObjectNameKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    FDatabaseObjList: TArray<string>;

    function GetDBPassword(out APassword: string): Boolean;
    procedure FilterList(const ASearchStr: string);
  public
    { Public declarations }
    procedure InitConnectionParams(const AHost, AUsername, ADatabase, APassword: string; const APort: integer);
    function GetDBObject: string;
  end;

implementation

{$R *.dfm}

procedure TfrmDBObjectName.FormActivate(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TfrmDBObjectName.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ShowWindow(Application.Handle, SW_SHOW);
end;

procedure TfrmDBObjectName.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = chr(27) {ESC} then
  begin
    Key := #0;
    Self.Close;
  end;
end;

procedure TfrmDBObjectName.FormShow(Sender: TObject);
begin
  eDBObject.Clear;
  SetForegroundWindow(Self.Handle);
  ActiveControl := eDBObject;
end;

function TfrmDBObjectName.GetDBObject: string;
begin
  Result := '';
  if (lbDBObjectName.Items.Count <= 0) then
    Exit;

  if lbDBObjectName.ItemIndex = -1 then
    Result := lbDBObjectName.Items[0]
  else
    Result := lbDBObjectName.Items[lbDBObjectName.ItemIndex];
end;

function TfrmDBObjectName.GetDBPassword(out APassword: string): Boolean;
var
  _PGPass: TStringList;
  _PasswFile: string;
  _Line: string;
  _ConnectionParams: string;
  i: Integer;
begin
  _PGPass := TStringList.Create;
  try
    _PasswFile := System.SysUtils.GetEnvironmentVariable('APPDATA');
    _PasswFile := TPath.Combine(_PasswFile, 'postgresql\pgpass.conf');

    if not FileExists(_PasswFile) then
      Exit(False);

    _ConnectionParams := conDBObject.HostName + ':' + IntToStr(conDBObject.Port) + ':*:' + conDBObject.User + ':';
    _PGPass.LoadFromFile(_PasswFile);
    for i := 0 to _PGPass.Count - 1 do
    begin
      _Line := _PGPass[i];
      _Line := Copy(_Line, 1, Length(_ConnectionParams));
      if _Line = _ConnectionParams then
      begin
        APassword := Copy(_PGPass[i], Length(_Line) + 1, Length(_PGPass[i]));
        Break;
      end;
    end;

    Result := (APassword <> '');
  finally
    FreeAndNil(_PGPass);
  end;
end;

procedure TfrmDBObjectName.eDBObjectChange(Sender: TObject);
begin
  FilterList(eDBObject.Text);
end;

procedure TfrmDBObjectName.eDBObjectKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Ord(Key) = VK_DOWN then
  begin
    lbDBObjectName.SetFocus;
    if lbDBObjectName.Items.Count > 0 then
      lbDBObjectName.ItemIndex := 0;
  end;
end;

procedure TfrmDBObjectName.eDBObjectKeyPress(Sender: TObject; var Key: Char);
begin
  if Ord(Key) = VK_RETURN then
  begin
    Key := #0;
    if lbDBObjectName.Items.Count <= 0 then
      Exit;

    Self.ModalResult := mrOK;
  end;
end;

procedure TfrmDBObjectName.FilterList(const ASearchStr: string);
var
  i: Integer;
begin
  lbDBObjectName.Items.BeginUpdate;
  try
    lbDBObjectName.Clear;

    for i := 0 to Length(FDatabaseObjList) - 1 do
    begin
      if AnsiContainsText(FDatabaseObjList[i], ASearchStr) or (ASearchStr = '') then
        lbDBObjectName.Items.Add(FDatabaseObjList[i]);
    end;
  finally
    lbDBObjectName.Items.EndUpdate;
  end;
end;

procedure TfrmDBObjectName.InitConnectionParams(const AHost, AUsername, ADatabase, APassword: string;
  const APort: integer);
var
  _Connect: Boolean;
  _Password: string;
begin
  _Connect := False;

  if (AHost <> conDBObject.HostName) or (AUsername <> conDBObject.User) or (ADatabase <> conDBObject.Database) or
    ((APassword <> '') and (APassword <> conDBObject.Password)) or (APort <> conDBObject.Port) then
  begin
    conDBObject.Disconnect;
    conDBObject.HostName := AHost;
    conDBObject.Database := ADatabase;
    conDBObject.User := AUsername;
    conDBObject.Password := APassword;
    conDBObject.Port := APort;

    _Connect := True;
  end;

  if _Connect and not conDBObject.Connected then
  begin
    if conDBObject.Password = '' then
    begin
      GetDBPassword(_Password);
      conDBObject.Password := _Password;
    end;

    conDBObject.Connect;

    SetLength(FDatabaseObjList, 0);
    lbDBObjectName.Clear;
    qObjects.Close;
    qObjects.Open;
    qObjects.First;
    while not qObjects.Eof do
    begin
      SetLength(FDatabaseObjList, Length(FDatabaseObjList) + 1);
      FDatabaseObjList[Length(FDatabaseObjList) - 1] := qObjectsdb_object.AsString;

      qObjects.Next;
    end;
    conDBObject.Disconnect;

    FilterList('');
  end;
end;

procedure TfrmDBObjectName.lbDBObjectNameDblClick(Sender: TObject);
begin
  Self.ModalResult := mrOK;
end;

procedure TfrmDBObjectName.lbDBObjectNameKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Ord(Key) = VK_UP then
  begin
    if lbDBObjectName.ItemIndex <= 0 then
      eDBObject.SetFocus;
  end;
end;

procedure TfrmDBObjectName.lbDBObjectNameKeyPress(Sender: TObject; var Key: Char);
begin
  if Ord(Key) = VK_RETURN then
  begin
    Key := #0;
    Self.ModalResult := mrOK;
  end;
end;

end.
