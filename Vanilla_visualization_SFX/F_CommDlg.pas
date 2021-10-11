unit F_CommDlg;

interface

uses
  Windows, Messages;

type
  POpenFilenameA = ^TOpenFilenameA;
  POpenFilenameW = ^TOpenFilenameW;
  POpenFilename = POpenFilenameA;
  tagOFNA = packed record
    lStructSize      : DWORD;
    hWndOwner        : HWND;
    HInstance        : HINST;
    lpstrFilter      : PAnsiChar;
    lpstrCustomFilter: PAnsiChar;
    nMaxCustFilter   : DWORD;
    nFilterIndex     : DWORD;
    lpstrFile        : PAnsiChar;
    nMaxFile         : DWORD;
    lpstrFileTitle   : PAnsiChar;
    nMaxFileTitle    : DWORD;
    lpstrInitialDir  : PAnsiChar;
    lpstrTitle       : PAnsiChar;
    Flags            : DWORD;
    nFileOffset      : Word;
    nFileExtension   : Word;
    lpstrDefExt      : PAnsiChar;
    lCustData        : LPARAM;
    lpfnHook         : function(Wnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): UINT; stdcall;
    lpTemplateName   : PAnsiChar;
    pvReserved       : Pointer;
    dwReserved       : DWORD;
    FlagsEx          : DWORD;
  end;
  tagOFNW = packed record
    lStructSize      : DWORD;
    hWndOwner        : HWND;
    HInstance        : HINST;
    lpstrFilter      : PWideChar;
    lpstrCustomFilter: PWideChar;
    nMaxCustFilter   : DWORD;
    nFilterIndex     : DWORD;
    lpstrFile        : PWideChar;
    nMaxFile         : DWORD;
    lpstrFileTitle   : PWideChar;
    nMaxFileTitle    : DWORD;
    lpstrInitialDir  : PWideChar;
    lpstrTitle       : PWideChar;
    Flags            : DWORD;
    nFileOffset      : Word;
    nFileExtension   : Word;
    lpstrDefExt      : PWideChar;
    lCustData        : LPARAM;
    lpfnHook         : function(Wnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): UINT; stdcall;
    lpTemplateName   : PWideChar;
    pvReserved       : Pointer;
    dwReserved       : DWORD;
    FlagsEx          : DWORD;
  end;
  tagOFN = tagOFNA;
  TOpenFilenameA = tagOFNA;
  TOpenFilenameW = tagOFNW;
  TOpenFilename = TOpenFilenameA;
  OPENFILENAMEA = tagOFNA;
  OPENFILENAMEW = tagOFNW;
  OPENFILENAME = OPENFILENAMEA;

function GetOpenFileName(var OpenFile: TOpenFilename): BOOL; stdcall;
function GetOpenFileNameA(var OpenFile: TOpenFilenameA): BOOL; stdcall;
function GetOpenFileNameW(var OpenFile: TOpenFilenameW): BOOL; stdcall;
function GetSaveFileName(var OpenFile: TOpenFilename): BOOL; stdcall;
function GetSaveFileNameA(var OpenFile: TOpenFilenameA): BOOL; stdcall;
function GetSaveFileNameW(var OpenFile: TOpenFilenameW): BOOL; stdcall;

const
  OFN_READONLY                   = $00000001;
  OFN_OVERWRITEPROMPT            = $00000002;
  OFN_HIDEREADONLY               = $00000004;
  OFN_NOCHANGEDIR                = $00000008;
  OFN_SHOWHELP                   = $00000010;
  OFN_ENABLEHOOK                 = $00000020;
  OFN_ENABLETEMPLATE             = $00000040;
  OFN_ENABLETEMPLATEHANDLE       = $00000080;
  OFN_NOVALIDATE                 = $00000100;
  OFN_ALLOWMULTISELECT           = $00000200;
  OFN_EXTENSIONDIFFERENT         = $00000400;
  OFN_PATHMUSTEXIST              = $00000800;
  OFN_FILEMUSTEXIST              = $00001000;
  OFN_CREATEPROMPT               = $00002000;
  OFN_SHAREAWARE                 = $00004000;
  OFN_NOREADONLYRETURN           = $00008000;
  OFN_NOTESTFILECREATE           = $00010000;
  OFN_NONETWORKBUTTON            = $00020000;
  OFN_NOLONGNAMES                = $00040000;
  OFN_EXPLORER                   = $00080000;
  OFN_NODEREFERENCELINKS         = $00100000;
  OFN_LONGNAMES                  = $00200000;
  OFN_ENABLEINCLUDENOTIFY        = $00400000;
  OFN_ENABLESIZING               = $00800000;
  OFN_DONTADDTORECENT            = $02000000;
  OFN_FORCESHOWHIDDEN            = $10000000;
  OFN_EX_NOPLACESBAR             = $00000001;
  OFN_SHAREFALLTHROUGH           = 2;
  OFN_SHARENOWARN                = 1;
  OFN_SHAREWARN                  = 0;
  OPENFILENAME_SIZE_VERSION_400A = SizeOf(TOpenFileNameA) - SizeOf(Pointer) - (2 * SizeOf(DWORD));
  OPENFILENAME_SIZE_VERSION_400W = SizeOf(TOpenFileNameW) - SizeOf(Pointer) - (2 * SizeOf(DWORD));
  OPENFILENAME_SIZE_VERSION_400  = OPENFILENAME_SIZE_VERSION_400A;
  CDN_FIRST                      = -601;
  CDN_INITDONE                   = CDN_FIRST - 0;

implementation

const
  comdlg32 = 'comdlg32.dll';

function GetOpenFileName;  external comdlg32 name 'GetOpenFileNameA';
function GetOpenFileNameA; external comdlg32 name 'GetOpenFileNameA';
function GetOpenFileNameW; external comdlg32 name 'GetOpenFileNameW';
function GetSaveFileName;  external comdlg32 name 'GetSaveFileNameA';
function GetSaveFileNameA; external comdlg32 name 'GetSaveFileNameA';
function GetSaveFileNameW; external comdlg32 name 'GetSaveFileNameW';

end.