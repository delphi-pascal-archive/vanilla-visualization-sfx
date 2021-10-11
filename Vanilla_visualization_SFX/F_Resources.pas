unit F_Resources;

interface

uses
  Windows, bass;

const

  { id dialog resources }

  IDD_DIALOG_MAIN = 1;

  { id bitmap resources }

  IDB_BITMAP_TIMER  = 1;
  IDB_BITMAP_METER  = 2;
  IDB_BITMAP_BANNER = 3;

  { id dialog controls #101 }

  IDC_TIMER   = 11;
  IDC_METER   = 12;
  IDC_VISUAL  = 13;
  IDC_SPECTR  = 14;
  IDC_SCROLL  = 15;
  IDC_SEEK    = 16;
  IDC_VOLUME  = 17;
  IDC_OPEN    = 18;
  IDC_PLAY    = 19;
  IDC_STOP    = 20;
  IDC_SCREEN  = 21;
  IDC_PLUGINS = 22;
  IDC_FULLSCR = 23;

  { id dialog timers }

  IDT_TIMER_SEEK = 51;
  IDT_TIMER_CUE  = 52;

var

  stream  : HSTREAM = 0;
  sync    : HSYNC = 0;

  dwThick : Byte = 0;

  pszFile : Array [0..MAX_PATH-1] of WideChar;

  pszClass: LPWSTR = 'TPluginMainForm';
  hVisWnd : HWND = 0;

implementation

end.