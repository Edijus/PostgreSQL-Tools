unit Core.WndControl;

interface

uses
  {Delphi}
  WinAPI.Windows
  ;

type
  TWnd = record
    Caption: string;
    Handle: string;
  end;

type
  TWndControl = record
    ID: string;
    Wnd: TWnd;
  end;

implementation

end.
