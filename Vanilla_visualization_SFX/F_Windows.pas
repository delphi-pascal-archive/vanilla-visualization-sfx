unit F_Windows;

interface

uses
  Windows;
  
const

  HEAP_ZERO_MEMORY = $00000008;

  CLEARTYPE_QUALITY = 5;

  MSGFLT_ADD    = 1;
  MSGFLT_REMOVE = 2;

function GetVersionExW(var lpVersionInformation: TOSVersionInfoW): BOOL; stdcall;
function LoadCursorW(HInstance: HINST; lpCursorName: LPWSTR): HCURSOR; stdcall;
function GetWindowLongPtrW(hWnd: HWND; nIndex: Integer): Longint; stdcall;
function SetWindowLongPtrW(hWnd: HWND; nIndex: Integer; dwNewLong: Longint): Longint; stdcall;

var

  User32Lib: HMODULE = 0;
  ChangeWindowMessageFilter: function(message: UINT; dwFlag: DWORD): BOOL; stdcall;

implementation

function GetVersionExW; external kernel32 name 'GetVersionExW';
function LoadCursorW; external user32 name 'LoadCursorW';
function GetWindowLongPtrW; external user32 name 'GetWindowLongW';
function SetWindowLongPtrW; external user32 name 'SetWindowLongW';

initialization

  if (User32Lib = 0) then
  begin
    User32Lib := GetModuleHandleW(LPWSTR(WideString(user32)));
    if (User32Lib = 0) then
      User32Lib := LoadLibraryW(LPWSTR(WideString(user32)));
    if (User32Lib <> 0) then
      ChangeWindowMessageFilter := GetProcAddress(User32Lib, LPTSTR('ChangeWindowMessageFilter'));
  end;

finalization

  if (User32Lib <> 0) then
  begin
    FreeLibrary(User32Lib);
    User32Lib := 0;
    ChangeWindowMessageFilter := nil;
  end;

end.