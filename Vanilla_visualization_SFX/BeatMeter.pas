unit BeatMeter;

{******************************************************************************}
{                                                                              }
{ Проект             : Beat Meter Control                                      }
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
  Windows, Messages, CommCtrl, F_Windows, bass;

procedure CreateBeatCtrlStaticW(hWnd: HWND);
procedure RemoveBeatCtrlStaticW(hWnd: HWND);

const

  { extended control messages }

  STM_EX_GETBEATELAPSE  = WM_USER + 101;
  STM_EX_SETBEATELAPSE  = WM_USER + 102;

  STM_GETBEATMODE       = WM_USER + 103;
  STM_SETBEATMODE       = WM_USER + 104;

  STM_EX_GETBEATIMAGE   = WM_USER + 105;
  STM_EX_SETBEATIMAGE   = WM_USER + 106;

  STM_EX_SETBEATHSTREAM = WM_USER + 107;

  { extended control states }

  SS_NONE = 0;
  SS_BEAT = 1;

implementation

type

  TCtrlWndProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;

  P_CTRL_PRO = ^T_CTRL_PRO;
  T_CTRL_PRO = packed record
    CtrlProc  : TCtrlWndProc;
    dwClsExtra: DWORD;
    //
    hbmMem    : HBITMAP;
    //
    dwLevel   : TSmallPoint;
    //
    dwElapse  : Integer;
    dwMode    : Integer;
    //
    stream    : HSTREAM;
    //
    biWidth   : Integer;
    biHeight  : Integer;
    biHalf    : Integer;
    //
    timerId   : DWORD;
    //
    dwStyle   : DWORD;
  end;

var

  pcp: P_CTRL_PRO;

//

procedure CtrlWndProc_GetLevels(pcp: P_CTRL_PRO);
var
  dwRet: DWORD;
begin

  pcp.dwLevel.x := 0;
  pcp.dwLevel.y := 0;

  if ((pcp.stream <> 0) and (pcp.dwMode = SS_BEAT)) then
  try
    dwRet := BASS_ChannelIsActive(pcp.stream);
    if (dwRet = BASS_ACTIVE_PLAYING) then
    try
      dwRet := BASS_ChannelGetLevel(pcp.stream);
      if (dwRet <> DWORD(-1)) then
      try
      finally
        pcp.dwLevel.x := MulDiv(pcp.biHalf, LoWord(dwRet), High(Smallint));
        pcp.dwLevel.y := MulDiv(pcp.biHalf, HiWord(dwRet), High(Smallint));
      end;
    finally
    end;
  finally
  end;

end;

//

function CtrlWndProc_WmDestroy(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RemoveBeatCtrlStaticW(hWnd);

  Result := 0;

end;

//

function CtrlWndProc_WmEnable(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_WmPaint(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  ps       : TPaintStruct;
  hdcIn    : HDC;
  hdcBmpMem: HDC;
  hbmBmpOld: HBITMAP;
  hdcBltMem: HDC;
  hbmBltMem: HBITMAP;
  hbmBltOld: HBITMAP;
  hdcOutMem: HDC;
  hbmOutMem: HBITMAP;
  hbmOutOld: HBITMAP;
  rcClient : TRect;
  dwRet    : DWORD;
begin

  if (wParam = 0) then
    hdcIn := BeginPaint(hWnd, ps)
  else
    hdcIn := wParam;

  if (hdcIn <> 0) then
  try

    dwRet := GetObjectType(pcp.hbmMem);
    if (dwRet = OBJ_BITMAP) then
    try

      hdcBltMem := CreateCompatibleDC(hdcIn);
      hbmBltMem := CreateCompatibleBitmap(hdcIn, pcp.biWidth, pcp.biHeight);
      hbmBltOld := SelectObject(hdcBltMem, hbmBltMem);

      hdcBmpMem := CreateCompatibleDC(hdcIn);
      hbmBmpOld := SelectObject(hdcBmpMem, pcp.hbmMem);

      hdcOutMem := CreateCompatibleDC(hdcIn);
      hbmOutMem := CreateCompatibleBitmap(hdcIn, pcp.biWidth, pcp.biHeight);
      hbmOutOld := SelectObject(hdcOutMem, hbmOutMem);

      BitBlt(hdcBltMem, 0, 0, pcp.biHalf, pcp.biWidth, hdcBmpMem, 0, 0, SRCCOPY);
      StretchBlt(hdcBltMem, pcp.biWidth - 1, 0, -pcp.biHalf, pcp.biHeight,
        hdcBmpMem, 0, 0, pcp.biHalf, pcp.biHeight, SRCCOPY);

      if ((pcp.stream <> 0) and (pcp.dwMode = SS_BEAT)) then
      try
        dwRet := BASS_ChannelIsActive(pcp.stream);
        if (dwRet = BASS_ACTIVE_PLAYING) then
        try

          StretchBlt(hdcBltMem, pcp.biHalf, 0, -pcp.dwLevel.x, pcp.biHeight,
            hdcBmpMem, pcp.biHalf, 0, pcp.dwLevel.x, pcp.biHeight, SRCCOPY);
          BitBlt(hdcBltMem, pcp.biHalf - 1, 0, pcp.dwLevel.y, pcp.biHeight,
            hdcBmpMem, pcp.biHalf, 0, SRCCOPY);

        finally
        end;
      finally
      end;

      SetRect(rcClient, 0, 0, pcp.biWidth, pcp.biHeight);
      CallWindowProcW(@pcp.CtrlProc, hWnd, WM_PRINTCLIENT, hdcOutMem, PRF_CLIENT);

      TransparentBlt(
        hdcOutMem,
        0,
        0,
        pcp.biWidth,
        pcp.biHeight,
        hdcBltMem,
        0,
        0,
        pcp.biWidth,
        pcp.biHeight,
        GetPixel(hdcBltMem, pcp.biHalf + 1, 0)
      );

      BitBlt(
        hdcIn,
        0,
        0,
        pcp.biWidth,
        pcp.biHeight,
        hdcOutMem,
        0,
        0,
        SRCCOPY
      );

      SelectObject(hdcBmpMem, hbmBmpOld);
      DeleteDC(hdcBmpMem);

      SelectObject(hdcBltMem, hbmBltOld);
      DeleteObject(hbmBltMem);
      DeleteDC(hdcBltMem);

      SelectObject(hdcOutMem, hbmOutOld);
      DeleteObject(hbmOutMem);
      DeleteDC(hdcOutMem);

    finally
    end;

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

function CtrlWndProc_WmTimer(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  CtrlWndProc_GetLevels(pcp);
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetBeatElapse(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwElapse);

end;

//

function CtrlWndProc_StmExSetBeatElapse(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwElapse := wParam;
  if (pcp.timerId <> 0) then
  begin
    KillTimer(hWnd, pcp.timerId);
    pcp.timerId := 0;
  end;
  pcp.timerId := SetTimer(hWnd, 0, pcp.dwElapse, nil);
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_StmGetBeatMode(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwMode);

end;

//

function CtrlWndProc_StmSetBeatMode(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwMode := wParam;

  Result := 0;

end;

//

function CtrlWndProc_StmExGetBeatImage(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.hbmMem);

end;

//

function CtrlWndProc_StmExSetBeatImage(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  hbim : HBITMAP;
  bmi  : TBitmapInfo;
  dwRet: DWORD;
begin

  hbim := HBITMAP(lParam);
  if (hbim <> 0) then
  try

    dwRet := GetObjectType(hbim);
    if (dwRet = OBJ_BITMAP) then
    try

      pcp.hbmMem := hbim;

      dwRet := GetObjectW(pcp.hbmMem, SizeOf(TBitmapInfo), @bmi);
      if (dwRet <> 0) then
      try

        pcp.biWidth  := bmi.bmiHeader.biWidth;
        pcp.biHeight := bmi.bmiHeader.biHeight;
        pcp.biHalf   := pcp.biWidth div 2;

        SetWindowPos(
          hWnd,
          HWND_TOP,
          0,
          0,
          pcp.biWidth,
          pcp.biHeight,
          SWP_NOMOVE or SWP_NOZORDER
        );

      finally
      end;

    finally
    end;

  finally
  end;

  Result := 0;

end;

//

function CtrlWndProc_StmExSetBeatHStream(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.stream := HSTREAM(lParam);

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

    WM_TIMER:
    begin
      Result := CtrlWndProc_WmTimer(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETBEATELAPSE:
    begin
      Result := CtrlWndProc_StmExGetBeatElapse(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETBEATELAPSE:
    begin
      Result := CtrlWndProc_StmExSetBeatElapse(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_GETBEATMODE:
    begin
      Result := CtrlWndProc_StmGetBeatMode(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_SETBEATMODE:
    begin
      Result := CtrlWndProc_StmSetBeatMode(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETBEATIMAGE:
    begin
      Result := CtrlWndProc_StmExGetBeatImage(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETBEATIMAGE:
    begin
      Result := CtrlWndProc_StmExSetBeatImage(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETBEATHSTREAM:
    begin
      Result := CtrlWndProc_StmExSetBeatHStream(pcp, hWnd, uMsg, wParam, lParam);
    end;

  else
    Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);
  end;

end;

//

procedure CreateBeatCtrlStaticW(hWnd: HWND);
begin

  RemoveBeatCtrlStaticW(hWnd);

  pcp := P_CTRL_PRO(HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, SizeOf(T_CTRL_PRO)));
  if (pcp <> nil) then
  try

    ZeroMemory(pcp, SizeOf(T_CTRL_PRO));

    pcp.CtrlProc   := TCtrlWndProc(Pointer(GetWindowLongPtrW(hWnd, GWL_WNDPROC)));
    pcp.dwClsExtra := GetWindowLongPtrW(hWnd, GWL_USERDATA);
    pcp.hbmMem     := 0;
    ZeroMemory(@pcp.dwLevel, SizeOf(TSmallPoint));
    pcp.dwElapse   := 25;
    pcp.dwMode     := SS_BEAT;
    pcp.stream     := 0;
    pcp.biWidth    := 0;
    pcp.biHeight   := 0;
    pcp.biHalf     := pcp.biWidth div 2;
    pcp.timerId    := SetTimer(hWnd, 0, pcp.dwElapse, nil);
    pcp.dwStyle    := GetWindowLongPtrW(hWnd, GWL_STYLE);

    if ((pcp.dwStyle and SS_NOTIFY) = 0) then
      SetWindowLongPtrW(hWnd, GWL_STYLE, pcp.dwStyle or SS_NOTIFY);

    SetWindowLongPtrW(hWnd, GWL_USERDATA, Longint(pcp));

    SetWindowLongPtrW(hWnd, GWL_WNDPROC, Longint(@CtrlWndProc));

    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  finally
  end;

end;

//

procedure RemoveBeatCtrlStaticW(hWnd: HWND);
begin

  pcp := P_CTRL_PRO(GetWindowLongPtrW(hWnd, GWL_USERDATA));
  if (pcp <> nil) then
  try

    if (pcp.timerId <> 0) then
      KillTimer(hWnd, pcp.timerId);

    SetWindowLongPtrW(hWnd, GWL_STYLE, pcp.dwStyle);

    SetWindowLongPtrW(hWnd, GWL_WNDPROC, Longint(@pcp.CtrlProc));

    SetWindowLongPtrW(hWnd, GWL_USERDATA, pcp.dwClsExtra);

    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  finally
    HeapFree(GetProcessHeap, 0, pcp);
  end;

end;

end.