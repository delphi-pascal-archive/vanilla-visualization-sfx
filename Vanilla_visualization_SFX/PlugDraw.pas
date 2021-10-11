unit PlugDraw;

{******************************************************************************}
{                                                                              }
{ Проект             : Render Plugin Control                                   }
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
  Windows, Messages, F_Windows, bass, bass_sfx;

procedure CreatePlugCtrlStaticW(hWnd: HWND);
procedure RemovePlugCtrlStaticW(hWnd: HWND);

const

  { extended control messages }

  STM_EX_GETSFXIMAGE    = WM_USER + 101;
  STM_EX_SETSFXIMAGE    = WM_USER + 102;

  STM_EX_GETSFXELAPSE   = WM_USER + 103;
  STM_EX_SETSFXELAPSE   = WM_USER + 104;

  STM_EX_GETSFXMODE     = WM_USER + 105;
  STM_EX_SETSFXMODE     = WM_USER + 106;

  STM_EX_GETSFXHMODULE  = WM_USER + 107;
  STM_EX_SETSFXHMODULE  = WM_USER + 108;

  STM_EX_SETSFXACTIVATE = WM_USER + 109;

  STM_EX_SETSFXRESIZE   = WM_USER + 110;

  STM_EX_SETSFXHSTREAM  = WM_USER + 111;

  { extended control states }

  SS_BANNER = 0;
  SS_VISUAL = 1;

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
    bmBits    : PRGBQuad;
    hbmImg    : HBITMAP;
    //
    dwElapse  : Integer;
    dwMode    : Integer;
    //
    stream    : HSTREAM;
    plugin    : HMODULE;
    //
    timerId   : DWORD;
    //
    dwStyle   : DWORD;
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

procedure CtrlWndProc_BannerRender(pcp: P_CTRL_PRO; hWnd: HWND);
var
  hdcIn : HDC;
  dwRet : DWORD;
  bmi   : TBitmapInfo;
  hdcMem: HDC;
  hbmOld: HBITMAP;
  pixel : TColorRef;
  xLeft : Integer;
  xTop  : Integer;
begin

  hdcIn := GetDC(hWnd);
  if (hdcIn <> 0) then
  try

    dwRet := GetObjectType(pcp.hbmImg);
    if (dwRet = OBJ_BITMAP) then
    try

      dwRet := GetObjectW(pcp.hbmImg, SizeOf(TBitmapInfo), @bmi);
      if (dwRet <> 0) then
      try

        hdcMem := CreateCompatibleDC(hdcIn);
        hbmOld := SelectObject(hdcMem, pcp.hbmImg);

        pixel := GetPixel(hdcMem, 0, 0);

        xLeft := ((pcp.rcClient.Right - pcp.rcClient.Left) -
          bmi.bmiHeader.biWidth) div 2;
        xTop  := ((pcp.rcClient.Bottom - pcp.rcClient.Top) -
          bmi.bmiHeader.biHeight) div 2;

        TransparentBlt(
          pcp.hdcMem,
          xLeft,
          xTop,
          bmi.bmiHeader.biWidth,
          bmi.bmiHeader.biHeight,
          hdcMem,
          0,
          0,
          bmi.bmiHeader.biWidth,
          bmi.bmiHeader.biHeight,
          pixel
        );

        SelectObject(hdcMem, hbmOld);
        DeleteDC(hdcMem);

      finally
      end;

    finally
    end;

  finally

    ReleaseDC(hWnd, hdcIn);

  end;

end;

//

function CtrlWndProc_WmDestroy(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RemovePlugCtrlStaticW(hWnd);

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
  bmi  : TBitmapInfo;
begin

  GetClientRect(hWnd, pcp.rcClient);

  CtrlWndProc_DeleteObject(pcp);

  hdcIn := GetDC(hWnd);
  if (hdcIn <> 0) then
  try

    pcp.hdcMem := CreateCompatibleDC(hdcIn);
    bmi.bmiHeader.biSize        := SizeOf(bmi.bmiHeader);
    bmi.bmiHeader.biWidth       := pcp.rcClient.Right - pcp.rcClient.Left;
    bmi.bmiHeader.biHeight      := -(pcp.rcClient.Bottom - pcp.rcClient.Top);
    bmi.bmiHeader.biPlanes      := 1;
    bmi.bmiHeader.biBitCount    := 32;
    bmi.bmiHeader.biCompression := BI_RGB;
    pcp.hbmMem := CreateDIBSection(hdcIn, bmi, DIB_RGB_COLORS, Pointer(pcp.bmBits), 0, 0);
    pcp.hbmOld := SelectObject(pcp.hdcMem, pcp.hbmMem);

    if (pcp.dwMode = SS_BANNER) then
    begin

      FillRect(pcp.hdcMem, pcp.rcClient, HBRUSH(COLOR_3DFACE + 1));
      CtrlWndProc_BannerRender(pcp, hWnd);

    end;

  finally

    ReleaseDC(hWnd, hdcIn);

  end;

  if BOOL(pcp.plugin) then
  try

    SendMessageW(hWnd, STM_EX_SETSFXRESIZE, 0, 0);

  except
  end;

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

end;

//

function CtrlWndProc_WmPaint(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  ps   : TPaintStruct;
  hdcIn: HDC;
begin

  if (wParam = 0) then
    hdcIn := BeginPaint(hWnd, ps)
  else
    hdcIn := wParam;

  if (hdcIn <> 0) then
  try

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

function CtrlWndProc_WmTimer(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (pcp.dwMode = SS_VISUAL) then
  begin

    // здесь не заливаем фон через FillRect. если не удается отрисовать
    // визуализацию, на прежнем месте будет баннер.
    // FillRect(pcp.hdcMem, pcp.rcClient, HBRUSH(COLOR_3DFACE + 1));

    if BOOL(pcp.plugin) then
      BASS_SFX_PluginRender(pcp.plugin, pcp.stream, pcp.hdcMem);
    {
    else
      FrameRect(pcp.hdcMem, pcp.rcClient, GetStockObject(LTGRAY_BRUSH));
    }

  end
  else
    CtrlWndProc_BannerRender(pcp, hWnd);
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetSfxImage(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.hbmImg);

end;

//

function CtrlWndProc_StmExSetSfxImage(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  hbim : HBITMAP;
  dwRet: DWORD;
begin

  hbim := HBITMAP(lParam);
  if (hbim <> 0) then
  try

    dwRet := GetObjectType(hbim);
    if (dwRet = OBJ_BITMAP) then
    try

      pcp.hbmImg := hbim;

    finally

      if (pcp.dwMode = SS_BANNER) then
        CtrlWndProc_BannerRender(pcp, hWnd);

    end;

  finally
  end;

  Result := 0;

end;

//

function CtrlWndProc_StmExGetSfxElapse(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwElapse);

end;

//

function CtrlWndProc_StmExSetSfxElapse(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwElapse := wParam;
  if (pcp.dwMode = SS_VISUAL) then
  begin

    if (pcp.timerId <> 0) then
    begin

      KillTimer(hWnd, pcp.timerId);
      pcp.timerId := 0;

    end;
    pcp.timerId := SetTimer(hWnd, 0, pcp.dwElapse, nil);
    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  end;

  Result := 0;

end;

//

function CtrlWndProc_StmGetSfxMode(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwMode);

end;

//

function CtrlWndProc_StmSetSfxMode(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  hdcIn: HDC;
begin

  pcp.dwMode := wParam;

  if (pcp.dwMode = SS_VISUAL) then
  begin

    if (pcp.timerId <> 0) then
    begin

      KillTimer(hWnd, pcp.timerId);
      pcp.timerId := 0;

    end;
    pcp.timerId := SetTimer(hWnd, 0, pcp.dwElapse, nil);

  end
  else
  begin

    if (pcp.timerId <> 0) then
    begin

      KillTimer(hWnd, pcp.timerId);
      pcp.timerId := 0;

    end;
    FillRect(pcp.hdcMem, pcp.rcClient, HBRUSH(COLOR_3DFACE + 1));
    hdcIn := GetDC(hWnd);
    if (hdcIn <> 0) then
    try

      CtrlWndProc_BannerRender(pcp, hWnd);

    finally

      ReleaseDC(hWnd, hdcIn);

    end;
    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  end;

  Result := 0;

end;

//

function CtrlWndProc_StmGetSfxHModule(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := HSFX(pcp.plugin);

end;

//

function CtrlWndProc_StmSetSfxHModule(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.plugin := HSFX(lParam);
  if BOOL(pcp.plugin) then
    BASS_SFX_PluginSetStream(pcp.plugin, pcp.stream);

  Result := 0;

end;

//

function CtrlWndProc_StmExSetSfxActivate(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if BOOL(pcp.plugin) then
  begin

    if BOOL(wParam) then
      BASS_SFX_PluginStart(pcp.plugin)
    else
      BASS_SFX_PluginStop(pcp.plugin);

  end;

  Result := 0;

end;

//

function CtrlWndProc_StmExSetSfxResize(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if BOOL(pcp.plugin) then
  try

    BASS_SFX_PluginResize(
      pcp.plugin,
      pcp.rcClient.Right - pcp.rcClient.Left,
      pcp.rcClient.Bottom - pcp.rcClient.Top
    );

  except
  end;

  Result := 0;

end;

//

function CtrlWndProc_StmExSetSfxHStream(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
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

    {WM_SETCURSOR:
    begin
      Result := CtrlWndProc_WmSetCursor(pcp, hWnd, uMsg, wParam, lParam);
    end;}

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

    WM_TIMER:
    begin
      Result := CtrlWndProc_WmTimer(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETSFXIMAGE:
    begin
      Result := CtrlWndProc_StmExGetSfxImage(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSFXIMAGE:
    begin
      Result := CtrlWndProc_StmExSetSfxImage(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETSFXELAPSE:
    begin
      Result := CtrlWndProc_StmExGetSfxElapse(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSFXELAPSE:
    begin
      Result := CtrlWndProc_StmExSetSfxElapse(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETSFXMODE:
    begin
      Result := CtrlWndProc_StmGetSfxMode(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSFXMODE:
    begin
      Result := CtrlWndProc_StmSetSfxMode(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETSFXHMODULE:
    begin
      Result := CtrlWndProc_StmGetSfxHModule(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSFXHMODULE:
    begin
      Result := CtrlWndProc_StmSetSfxHModule(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSFXACTIVATE:
    begin
      Result := CtrlWndProc_StmExSetSfxActivate(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSFXRESIZE:
    begin
      Result := CtrlWndProc_StmExSetSfxResize(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSFXHSTREAM:
    begin
      Result := CtrlWndProc_StmExSetSfxHStream(pcp, hWnd, uMsg, wParam, lParam);
    end;

  else
    Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);
  end;

end;

//

procedure CreatePlugCtrlStaticW(hWnd: HWND);
begin

  RemovePlugCtrlStaticW(hWnd);

  pcp := P_CTRL_PRO(HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, SizeOf(T_CTRL_PRO)));
  if (pcp <> nil) then
  try

    ZeroMemory(pcp, SizeOf(T_CTRL_PRO));

    pcp.CtrlProc   := TCtrlWndProc(Pointer(GetWindowLongPtrW(hWnd, GWL_WNDPROC)));
    pcp.dwClsExtra := GetWindowLongPtrW(hWnd, GWL_USERDATA);
    SetRectEmpty(pcp.rcClient);
    pcp.hbmImg     := 0;
    pcp.dwElapse   := 25;
    pcp.dwMode     := SS_BANNER;
    pcp.stream     := 0;
    pcp.plugin     := 0;
    pcp.timerId    := SetTimer(hWnd, 0, pcp.dwElapse, nil);
    pcp.dwStyle    := GetWindowLongPtrW(hWnd, GWL_STYLE);

    if ((pcp.dwStyle and SS_NOTIFY) = 0) then
      SetWindowLongPtrW(hWnd, GWL_STYLE, pcp.dwStyle or SS_NOTIFY);

    SetWindowLongPtrW(hWnd, GWL_USERDATA, Longint(pcp));

    SetWindowLongPtrW(hWnd, GWL_WNDPROC, Longint(@CtrlWndProc));

    SendMessageW(hWnd, WM_SIZE, 0, 0);
    SendMessageW(hWnd, WM_TIMER, 0, 0);

  finally
  end;

end;

//

procedure RemovePlugCtrlStaticW(hWnd: HWND);
begin

  pcp := P_CTRL_PRO(GetWindowLongPtrW(hWnd, GWL_USERDATA));
  if (pcp <> nil) then
  try

    CtrlWndProc_DeleteObject(pcp);

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