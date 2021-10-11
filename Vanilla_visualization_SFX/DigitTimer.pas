unit DigitTimer;

{******************************************************************************}
{                                                                              }
{ Проект             : Digital Timer Control                                   }
{ Последнее изменение: 04.11.2010                                              }
{ Авторские права    : © Мельников Максим Викторович, 2010                     }
{ Электронная почта  : maks1509@inbox.ru                                       }
{                                                                              }
{******************************************************************************}
{                                                                              }
{ Эта программа является свободным программным обеспечением. Вы можете         }
{ распространять и/или модифицировать её согласно условиям Стандартной         }
{ Общественной Лицензии GNU, опубликованной Фондом Свободного Программного     }
{ Обеспечения, версии 3 или, по Вашему желанию, любой более поздней версии.    }
{                                                                              }
{ Эта программа распространяется в надежде, что она будет полезной, но БЕЗ     }
{ ВСЯКИХ ГАРАНТИЙ, в том числе подразумеваемых гарантий ТОВАРНОГО СОСТОЯНИЯ    }
{ ПРИ ПРОДАЖЕ и ГОДНОСТИ ДЛЯ ОПРЕДЕЛЁННОГО ПРИМЕНЕНИЯ. Смотрите Стандартную    }
{ Общественную Лицензию GNU для получения дополнительной информации.           }
{                                                                              }
{ Вы должны были получить копию Стандартной Общественной Лицензии GNU          }
{ вместе с программой. В случае её отсутствия, посмотрите                      }
{ http://www.gnu.org/copyleft/gpl.html                                         }
{                                                                              }
{******************************************************************************}

interface

uses
  Windows, Messages, CommCtrl, F_Windows;

procedure CreateTimerCtrlStaticW(hWnd: HWND);
procedure RemoveTimerCtrlStaticW(hWnd: HWND);

const

  { extended control messages }

  STM_EX_GETIMAGELIST    = WM_USER + 101;
  STM_EX_SETIMAGELIST    = WM_USER + 102;

  STM_EX_GETTIMEVALUE    = WM_USER + 103;
  STM_EX_SETTIMEVALUE    = WM_USER + 104;

  STM_EX_GETTIMERMODE    = WM_USER + 105;
  STM_EX_SETTIMERMODE    = WM_USER + 106;

  STM_EX_GETDIVIDERVALUE = WM_USER + 107;
  STM_EX_SETDIVIDERVALUE = WM_USER + 108;

  STM_EX_GETIDEALSIZE    = WM_USER + 109;

  { extended control styles }

  SS_EX_HHMMSS = 0;
  SS_EX_HHMM   = 1;
  SS_EX_MMSS   = 2;
  SS_EX_SS     = 3;

  { digital divider value }

  DIV_DEFAULT = -1;

implementation

type
  TCtrlWndProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
  P_CTRL_PRO = ^T_CTRL_PRO;
  T_CTRL_PRO = packed record
    CtrlProc  : TCtrlWndProc;
    dwClsExtra: DWORD;
    rcClient  : TRect;
    //
    hdcMem    : HDC;
    hbmMem    : HBITMAP;
    hbmOld    : HBITMAP;
    //
    himl      : HIMAGELIST;
    //
    dwTime    : DWORD;
    dwDivider : Integer;
    //
    dwExStyle : DWORD;
  end;

var
  pcp: P_CTRL_PRO;

//

procedure CtrlWndProc_DeleteObject(pcp: P_CTRL_PRO);
begin

  if (pcp.hdcMem <> 0) then
  try
    SelectObject(pcp.hdcMem, pcp.hbmOld);
  finally
    DeleteObject(pcp.hbmMem);
    DeleteDC(pcp.hdcMem);
  end;

end;

//

function CtrlWndProc_GetIdealWidth(pcp: P_CTRL_PRO; cxIcon, cyIcon: Integer): Integer;
var
  dwDiv: Integer;
begin

  if (pcp.dwDivider = DIV_DEFAULT) then
    dwDiv := cxIcon
  else
    dwDiv := pcp.dwDivider;

  case pcp.dwExStyle of
    SS_EX_HHMMSS:
      Result := (pcp.rcClient.Right - pcp.rcClient.Left) - (cxIcon * 6) - (dwDiv * 2);
    SS_EX_HHMM,
    SS_EX_MMSS:
      Result := (pcp.rcClient.Right - pcp.rcClient.Left) - (cxIcon * 4) - dwDiv;
    SS_EX_SS:
      Result := (pcp.rcClient.Right - pcp.rcClient.Left) - (cxIcon * 2);
  else
    Result := 0;
  end;

end;

//

function CtrlWndProc_WmDestroy(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RemoveTimerCtrlStaticW(hWnd);

  Result := 0;

end;

//

function CtrlWndProc_WmEnable(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_WmSize(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  hdcIn: HDC;
begin

  GetClientRect(hWnd, pcp.rcClient);

  CtrlWndProc_DeleteObject(pcp);

  hdcIn := GetDC(hWnd);
  pcp.hdcMem := CreateCompatibleDC(hdcIn);
  pcp.hbmMem := CreateCompatibleBitmap(
    hdcIn,
    pcp.rcClient.Right - pcp.rcClient.Left,
    pcp.rcClient.Bottom - pcp.rcClient.Top
  );
  pcp.hbmOld := SelectObject(pcp.hdcMem, pcp.hbmMem);
  ReleaseDC(hWnd, hdcIn);

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

end;

//

function CtrlWndProc_WmPaint(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  ps    : TPaintStruct;
  hdcIn : HDC;
  hbr   : HBRUSH;
  cxIcon: Integer;
  cyIcon: Integer;
  xLeft : Integer;
  xTop  : Integer;
  dwTime: DWORD;
  dwSec : Integer;
  dwMin : Integer;
  dwHour: Integer;

  procedure DrawImage(dwIndex: Integer);
  begin
    ImageList_DrawEx(
      pcp.himl,
      dwIndex,
      pcp.hdcMem,
      xLeft,
      xTop,
      cxIcon,
      cyIcon,
      CLR_DEFAULT,
      CLR_DEFAULT,
      ILD_NORMAL or ILD_TRANSPARENT
    );
  end;

  procedure DrawHours;
  begin
    DrawImage(dwHour div 10);
    Inc(xLeft, cxIcon);
    DrawImage(dwHour mod 10);
  end;

  procedure DrawMinutes;
  begin
    DrawImage(dwMin div 10);
    Inc(xLeft, cxIcon);
    DrawImage(dwMin mod 10);
  end;

  procedure DrawSeconds;
  begin
    DrawImage(dwSec div 10);
    Inc(xLeft, cxIcon);
    DrawImage(dwSec mod 10);
  end;

  procedure DrawSeparator;
  begin
    Inc(xLeft, cxIcon);
    DrawImage(10);
    if (pcp.dwDivider = DIV_DEFAULT) then
      Inc(xLeft, cxIcon)
    else
      Inc(xLeft, pcp.dwDivider);
  end;

begin

  if (wParam = 0) then
    hdcIn := BeginPaint(hWnd, ps)
  else
    hdcIn := wParam;

  if (hdcIn <> 0) then

  try

    hbr := SendMessageW(GetParent(hWnd), WM_CTLCOLORSTATIC, pcp.hdcMem, hWnd);
    if (hbr <> 0) then
      FillRect(pcp.hdcMem, pcp.rcClient, hbr);

    if (pcp.himl <> 0) then
    try

      ImageList_GetIconSize(pcp.himl, cxIcon, cyIcon);

      xLeft := CtrlWndProc_GetIdealWidth(pcp, cxIcon, cyIcon) div 2;
      xTop  := ((pcp.rcClient.Bottom - pcp.rcClient.Top) - cyIcon) div 2;

      //

      dwTime := pcp.dwTime;

      // millisec to mseconds.
      dwTime := dwTime div 1000;
      dwSec := dwTime mod 60;
      // seconds to minutes.
      dwTime := dwTime div 60;
      dwMin := dwTime mod 60;
      // minutes to hours.
      dwTime := dwTime div 60;
      dwHour := dwTime mod 24;

      case pcp.dwExStyle of

        //

        SS_EX_HHMMSS:
        begin

          DrawHours;
          DrawSeparator;
          DrawMinutes;
          DrawSeparator;
          DrawSeconds;

        end;

        //

        SS_EX_HHMM:
        begin

          DrawHours;
          DrawSeparator;
          DrawMinutes;

        end;

        //

        SS_EX_MMSS:
        begin

          DrawMinutes;
          DrawSeparator;
          DrawSeconds;

        end;

        //

        SS_EX_SS:
        begin

          DrawSeconds;

        end;

      end;

    finally
    end;

    BitBlt(
      hdcIn,
      0,
      0,
      pcp.rcClient.Right - pcp.rcClient.Left,
      pcp.rcClient.Bottom - pcp.rcClient.Top,
      pcp.hdcMem,
      0,
      0,
      SRCCOPY
    );

  finally

    if (wParam = 0) then
      EndPaint(hWnd, ps);

  end;

  Result := 0;

end;

//

function CtrlWndProc_WmEraseBkgnd(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := 1;

end;

//

function CtrlWndProc_WmSysColorChange(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetImageList(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.himl);

end;

//

function CtrlWndProc_StmExSetImageList(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.himl := HIMAGELIST(lParam);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetTimeValue(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwTime div 1000);

end;

//

function CtrlWndProc_StmExSetTimeValue(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwTime := DWORD(wParam) * 1000;

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetTimerMode(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwExStyle);

end;

//

function CtrlWndProc_StmExSetTimerMode(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if not lParam in [SS_EX_HHMMSS, SS_EX_HHMM, SS_EX_MMSS, SS_EX_SS] then
    pcp.dwExStyle := SS_EX_SS
  else
    pcp.dwExStyle := wParam;

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetDividerValue(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwDivider);

end;

//

function CtrlWndProc_StmExSetDividerValue(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwDivider := wParam;

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetIdealSize(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  cxIcon: Integer;
  cyIcon: Integer;
begin

  if (pcp.himl <> 0) then
  begin

    ImageList_GetIconSize(pcp.himl, cxIcon, cyIcon);

    Result := MakeLParam(CtrlWndProc_GetIdealWidth(pcp, cxIcon, cyIcon), cyIcon);

  end
  else
    Result := 0;

end;

//

function CtrlWndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin

  pcp := P_CTRL_PRO(GetWindowLongPtrW(hWnd, GWL_USERDATA));

  if (pcp = nil) then
  begin
    Result := DefWindowProcW(hWnd, uMsg, wParam, lParam);
    Exit;
  end;

  case uMsg of

    //

    WM_DESTROY:
    begin
      Result := CtrlWndProc_WmDestroy(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_ENABLE:
    begin
      Result := CtrlWndProc_WmEnable(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_SIZE:
    begin
      Result := CtrlWndProc_WmSize(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_PRINTCLIENT,
    WM_PAINT,
    WM_UPDATEUISTATE:
    begin
      Result := CtrlWndProc_WmPaint(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_ERASEBKGND:
    begin
      Result := CtrlWndProc_WmEraseBkgnd(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_SYSCOLORCHANGE:
    begin
      Result := CtrlWndProc_WmSysColorChange(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETIMAGELIST:
    begin
      Result := CtrlWndProc_StmExGetImageList(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETIMAGELIST:
    begin
      Result := CtrlWndProc_StmExSetImageList(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETTIMEVALUE:
    begin
      Result := CtrlWndProc_StmExGetTimeValue(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETTIMEVALUE:
    begin
      Result := CtrlWndProc_StmExSetTimeValue(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETTIMERMODE:
    begin
      Result := CtrlWndProc_StmExGetTimerMode(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETTIMERMODE:
    begin
      Result := CtrlWndProc_StmExSetTimerMode(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETDIVIDERVALUE:
    begin
      Result := CtrlWndProc_StmExGetDividerValue(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETDIVIDERVALUE:
    begin
      Result := CtrlWndProc_StmExSetDividerValue(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETIDEALSIZE:
    begin
      Result := CtrlWndProc_StmExGetIdealSize(pcp, hWnd, uMsg, wParam, lParam);
    end;

  else
    Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);
  end;

end;

//

procedure CreateTimerCtrlStaticW(hWnd: HWND);
var
  iccex: TInitCommonControlsEx;
begin

  RemoveTimerCtrlStaticW(hWnd);

  pcp := P_CTRL_PRO(HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, SizeOf(T_CTRL_PRO)));
  if (pcp <> nil) then
  try

    InitCommonControls;
    iccex.dwSize := SizeOf(TInitCommonControlsEx);
    iccex.dwICC  := ICC_BAR_CLASSES;
    InitCommonControlsEx(iccex);

    ZeroMemory(pcp, SizeOf(T_CTRL_PRO));

    pcp.CtrlProc   := TCtrlWndProc(Pointer(GetWindowLongPtrW(hWnd, GWL_WNDPROC)));
    pcp.dwClsExtra := GetWindowLongPtrW(hWnd, GWL_USERDATA);
    SetRectEmpty(pcp.rcClient);
    pcp.himl       := 0;
    pcp.dwTime     := 0;
    pcp.dwDivider  := DIV_DEFAULT;
    pcp.dwExStyle  := SS_EX_SS;

    SetWindowLongPtrW(hWnd, GWL_USERDATA, Longint(pcp));

    SetWindowLongPtrW(hWnd, GWL_WNDPROC, Longint(@CtrlWndProc));

    SendMessageW(hWnd, WM_SIZE, 0, 0);

  finally
  end;

end;

//

procedure RemoveTimerCtrlStaticW(hWnd: HWND);
begin

  pcp := P_CTRL_PRO(GetWindowLongPtrW(hWnd, GWL_USERDATA));
  if (pcp <> nil) then
  try

    CtrlWndProc_DeleteObject(pcp);

    SetWindowLongPtrW(hWnd, GWL_WNDPROC, Longint(@pcp.CtrlProc));

    SetWindowLongPtrW(hWnd, GWL_USERDATA, pcp.dwClsExtra);

    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  finally
    HeapFree(GetProcessHeap, 0, pcp);
  end;

end;

end.