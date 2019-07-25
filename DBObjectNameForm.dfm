object frmDBObjectName: TfrmDBObjectName
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  ClientHeight = 176
  ClientWidth = 335
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnActivate = FormActivate
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlDBObject: TPanel
    Left = 0
    Top = 0
    Width = 335
    Height = 176
    Align = alClient
    Caption = 'pnlDBObject'
    TabOrder = 0
    object eDBObject: TEdit
      Left = 1
      Top = 1
      Width = 333
      Height = 21
      Align = alTop
      TabOrder = 0
      Text = 'eDBObject'
      OnChange = eDBObjectChange
      OnKeyDown = eDBObjectKeyDown
      OnKeyPress = eDBObjectKeyPress
    end
    object lbDBObjectName: TListBox
      Left = 1
      Top = 22
      Width = 333
      Height = 153
      Align = alClient
      ItemHeight = 13
      TabOrder = 1
      OnDblClick = lbDBObjectNameDblClick
      OnKeyDown = lbDBObjectNameKeyDown
      OnKeyPress = lbDBObjectNameKeyPress
    end
  end
  object conDBObject: TZConnection
    ControlsCodePage = cCP_UTF16
    Catalog = ''
    Properties.Strings = (
      'application_name=pgAdminDaemon'
      'AutoEncodeStrings=ON'
      'controls_cp=CP_UTF16')
    HostName = ''
    Port = 0
    Database = ''
    User = ''
    Password = ''
    Protocol = 'postgresql-9'
    Left = 128
    Top = 88
  end
  object qObjects: TZQuery
    Connection = conDBObject
    SQL.Strings = (
      'SELECT'
      
        '  CAST(table_schema || '#39'.'#39' || table_name AS varchar(255)) AS db_' +
        'object'
      'FROM'
      '  information_schema.tables'
      'WHERE'
      '  TRUE'
      '  AND table_schema NOT IN ('#39'pg_catalog'#39', '#39'information_schema'#39')'
      'ORDER BY'
      '  db_object')
    Params = <>
    Left = 224
    Top = 48
    object qObjectsdb_object: TWideStringField
      FieldName = 'db_object'
      Size = 255
    end
  end
end
