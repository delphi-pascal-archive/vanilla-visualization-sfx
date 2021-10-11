unit TextScroll;

{******************************************************************************}
{                                                                              }
{ Проект             : Text Scroller Control                                   }
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
  Windows, Messages, F_Windows, F_Graphics;

procedure CreateScrollCtrlStaticW(hWnd: HWND);
procedure RemoveScrollCtrlStaticW(hWnd: HWND);

const

  { extended control messages }

  STM_EX_GETSCROLLELAPSE  = WM_USER + 101;
  STM_EX_SETSCROLLELAPSE  = WM_USER + 102;

  STM_EX_GETSCROLLMODE    = WM_USER + 103;
  STM_EX_SETSCROLLMODE    = WM_USER + 104;

  STM_EX_GETSCROLLEXSTYLE = WM_USER + 105;
  STM_EX_SETSCROLLEXSTYLE = WM_USER + 106;

  STM_EX_GETSCROLLPIXEL   = WM_USER + 107;
  STM_EX_SETSCROLLPIXEL   = WM_USER + 108;

  STM_EX_SETSTARTPOS      = WM_USER + 109;

  STM_EX_SETENABLESCROLL  = WM_USER + 110;

  { extended control styles }

  SS_EX_SHADOW = $00000001;
  SS_EX_SMOOTH = $00000010;
  SS_EX_BLEND  = $00000100;
  SS_EX_DASH   = $00001000;

  { extended control states }

  SST_CENTER = 0;
  SST_RIGHT  = 1;
  SST_LEFT   = 2;

implementation

type

  TCtrlWndProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
  P_CTRL_PRO = ^T_CTRL_PRO;
  T_CTRL_PRO = packed record
    CtrlProc  : TCtrlWndProc;
    dwClsExtra: DWORD;
    rcClient  : TRect;
    //
    hFont     : HFONT;
    //
    hdcMem    : HDC;
    hbmMem    : HBITMAP;
    hbmOld    : HBITMAP;
    //
    dwMode    : Integer;
    dwElapse  : Integer;
    //
    txtSize   : TSize;
    pszText   : WideString;
    //
    dwOffset  : Integer;
    dwPixels  : Integer;
    //
    dwExStyle : DWORD;
    bScroll   : Boolean;
    //
    timerId   : DWORD;
    //
    dwStyle   : DWORD;
  end;

var

  pcp: P_CTRL_PRO;

//

function CtrlWndProc_GetTextSize(pcp: P_CTRL_PRO; hWnd: HWND): TSize;
var
  hdcIn: HDC;
begin

  hdcIn := GetDC(hWnd);
  if (hdcIn <> 0) then
  try

    if (pcp.hFont <> 0) then
      SelectObject(hdcIn, pcp.hFont);
    GetTextExtentPoint32W(
      hdcIn,
      LPWSTR(pcp.pszText),
      lstrlenW(LPWSTR(pcp.pszText)),
      Result
    );

  finally
    ReleaseDC(hWnd, hdcIn);
  end;

end;

//

procedure CtrlWndProc_CreateObject(pcp: P_CTRL_PRO; var hdcIn, hdcMem: HDC; var hbmMem, hbmOld: HBITMAP);
begin

  hdcMem := CreateCompatibleDC(hdcIn);
  if (hdcMem <> 0) then
  try
    hbmMem := CreateCompatibleBitmap(
      hdcIn,
      pcp.rcClient.Right - pcp.rcClient.Left,
      pcp.rcClient.Bottom - pcp.rcClient.Top
    );
    if (hbmMem <> 0) then
    try
    finally
      hbmOld := SelectObject(hdcMem, hbmMem);
    end;
  finally
  end;

end;

//

procedure CtrlWndProc_DeleteObject(var hdcMem: HDC; var hbmMem: HBITMAP; var hbmOld: HBITMAP);
begin

  if (hdcMem <> 0) then
  try
    SelectObject(hdcMem, hbmOld);
  finally
    DeleteObject(hbmMem);
    DeleteDC(hdcMem);
  end;

end;

//

procedure CtrlWndProc_SetStartPos(pcp: P_CTRL_PRO);
begin

  case pcp.dwMode of
    SST_RIGHT:
    begin
      pcp.dwOffset := -pcp.txtSize.cx - 10;
    end;
    SST_LEFT:
    begin
      pcp.dwOffset := (pcp.rcClient.Right - pcp.rcClient.Left) + 10;
    end;
  end;

end;

//

procedure CtrlWndProc_DrawText(pcp: P_CTRL_PRO; hWnd: HWND; hdcIn: HDC);
const
  dwExStyle: Array [Boolean] of Byte = (NONANTIALIASED_QUALITY, CLEARTYPE_QUALITY);
var
  dwRet  : DWORD;
  hfnt   : HFONT;
  lf     : TLogFontW;
  dwPosX : DWORD;
  dwPosY : DWORD;
  clrText: TColorRef;
begin

  dwRet := lstrlenW(LPWSTR(pcp.pszText));
  if (dwRet <> 0) then
  begin

    hfnt := 0;

    ZeroMemory(@lf, SizeOf(TLogFontW));
    if (pcp.hFont <> 0) then
    begin

      dwRet := GetObjectW(pcp.hFont, SizeOf(TLogFontW), @lf);
      if (dwRet <> 0) then
      begin

        with lf do
        begin

          lfQuality         := dwExStyle[(pcp.dwExStyle and SS_EX_SMOOTH) <> 0];
          lfClipPrecision   := CLIP_CHARACTER_PRECIS;
          lfOutPrecision    := OUT_CHARACTER_PRECIS;
          lfPitchAndFamily  := DEFAULT_PITCH;
          hfnt := CreateFontIndirectW(lf);

        end;

      end;

    end;

    if (hfnt <> 0) then
      SelectObject(hdcIn, hfnt)
    else
      SelectObject(hdcIn, pcp.hFont);

    SetBkMode(hdcIn, TRANSPARENT);
    SetBkColor(hdcIn, TRANSPARENT);

    if (pcp.dwMode = SST_CENTER) then
      dwPosX := ((pcp.rcClient.Right - pcp.rcClient.Left) - pcp.txtSize.cx) div 2
    else
      dwPosX := pcp.dwOffset;
    dwPosY := (((pcp.rcClient.Bottom - pcp.rcClient.Top) - pcp.txtSize.cy) div 2);

    if ((pcp.dwExStyle and SS_EX_SHADOW) <> 0) then
    begin

      clrText := SetTextColor(hdcIn, GetSysColor(COLOR_GRAYTEXT));

      Inc(dwPosX);
      Inc(dwPosY);

      TextOutW(
        hdcIn,
        dwPosX,
        dwPosY,
        LPWSTR(pcp.pszText),
        lstrlenW(LPWSTR(pcp.pszText))
      );

      Dec(dwPosX, 2);
      Dec(dwPosY, 2);

      SetTextColor(hdcIn, clrText);

    end;

    TextOutW(
      hdcIn,
      dwPosX,
      dwPosY,
      LPWSTR(pcp.pszText),
      lstrlenW(LPWSTR(pcp.pszText))
    );

    if (hfnt <> 0) then
      DeleteObject(hfnt);

  end;

end;

//

function CtrlWndProc_WmDestroy(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RemoveScrollCtrlStaticW(hWnd);

  Result := 0;

end;

//

function CtrlWndProc_WmSetFont(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.hFont := HFONT(wParam);

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

end;

//

function CtrlWndProc_WmEnable(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RedrawWindow(hWnd, nil, 0, RDW_NOERASE or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_WmSetText(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  SetLength(pcp.pszText, lstrlenW(LPWSTR(lParam)));
  pcp.pszText := LPWSTR(lParam);
  pcp.txtSize := CtrlWndProc_GetTextSize(pcp, hWnd);

  Result := {CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam)}0;

  RedrawWindow(hWnd, nil, 0, RDW_NOERASE or RDW_INVALIDATE or RDW_UPDATENOW);

end;

//

function CtrlWndProc_WmSize(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  hdcIn: HDC;
begin

  GetClientRect(hWnd, pcp.rcClient);

  CtrlWndProc_DeleteObject(pcp.hdcMem, pcp.hbmMem, pcp.hbmOld);

  hdcIn := GetDC(hWnd);
  if (hdcIn <> 0) then
  try
    CtrlWndProc_CreateObject(pcp, hdcIn, pcp.hdcMem, pcp.hbmMem, pcp.hbmOld);
  finally
    ReleaseDC(hWnd, hdcIn);
  end;

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

  RedrawWindow(hWnd, nil, 0, RDW_NOERASE or RDW_INVALIDATE or RDW_UPDATENOW);

end;

//

function CtrlWndProc_WmPaint(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  ps        : TPaintStruct;
  hdcIn     : HDC;
  hbr       : HBRUSH;
  hdcAndMem : HDC;
  hbmAndMem : HBITMAP;
  hbmAndOld : HBITMAP;
  hdcXorMem : HDC;
  hbmXorMem : HBITMAP;
  hbmXorOld : HBITMAP;
  hdcXor1Mem: HDC;
  hbmXor1Mem: HBITMAP;
  hbmXor1Old: HBITMAP;
  rcItem    : TRect;

  function CtrlWndProc_BitBlt(hdcDst, hdcSrc: HDC; dwRop: DWORD): Boolean;
  begin
    Result := BitBlt(
      hdcDst,
      0,
      0,
      pcp.rcClient.Right - pcp.rcClient.Left,
      pcp.rcClient.Bottom - pcp.rcClient.Top,
      hdcSrc,
      0,
      0,
      dwRop
    );
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

    //

    if ((pcp.dwExStyle and SS_EX_BLEND) <> 0) then
    begin

      CtrlWndProc_CreateObject(pcp, hdcIn, hdcAndMem, hbmAndMem, hbmAndOld);

      // создаем и рисуем градиент и копию его.

      CtrlWndProc_CreateObject(pcp, hdcIn, hdcXorMem, hbmXorMem, hbmXorOld);

      CtrlWndProc_CreateObject(pcp, hdcIn, hdcXor1Mem, hbmXor1Mem, hbmXor1Old);

      FillRect(hdcAndMem, pcp.rcClient, GetStockObject(WHITE_BRUSH));

      //

      SetRect(
        rcItem,
        pcp.rcClient.Left,
        pcp.rcClient.Top,
        100,
        pcp.rcClient.Bottom
      );
      DrawGradRect(
        hdcXorMem,
        rcItem,
        GetSysColor(COLOR_3DFACE),
        RGB(0, 0, 0),
        255
      );

      SetRect(
        rcItem,
        pcp.rcClient.Right - 100,
        pcp.rcClient.Top,
        pcp.rcClient.Right,
        pcp.rcClient.Bottom
      );
      DrawGradRect(
        hdcXorMem,
        rcItem,
        RGB(0, 0, 0),
        GetSysColor(COLOR_3DFACE),
        255
      );

      //

      CtrlWndProc_DrawText(pcp, hWnd, hdcAndMem);

      // копируем градиент для копии.

      CtrlWndProc_BitBlt(hdcXor1Mem, hdcXorMem, SRCCOPY);

      // рисуем инвертированный текст на градиенте.

      CtrlWndProc_BitBlt(hdcXorMem, hdcAndMem, SRCINVERT);

      // убираем градиент - при этом инвертируется текст.

      CtrlWndProc_BitBlt(hdcXorMem, hdcXor1Mem, SRCAND);

      // убираем чёрный фон.

      CtrlWndProc_BitBlt(hdcXorMem, hdcAndMem, SRCINVERT);

      // рисуем на экране результат.

      TransparentBlt(
        pcp.hdcMem,
        0,
        0,
        pcp.rcClient.Right - pcp.rcClient.Left,
        pcp.rcClient.Bottom - pcp.rcClient.Top,
        hdcXorMem,
        0,
        0,
        pcp.rcClient.Right - pcp.rcClient.Left,
        pcp.rcClient.Bottom - pcp.rcClient.Top,
        RGB(255, 255, 255)
      );

      CtrlWndProc_DeleteObject(hdcXorMem, hbmXorMem, hbmXorOld);

      CtrlWndProc_DeleteObject(hdcXor1Mem, hbmXor1Mem, hbmXor1Old);

      CtrlWndProc_DeleteObject(hdcAndMem, hbmAndMem, hbmAndOld);

    end
    else
      CtrlWndProc_DrawText(pcp, hWnd, pcp.hdcMem);

    if ((pcp.dwExStyle and SS_EX_DASH) <> 0) then
    begin

      SetRect(
        rcItem,
        pcp.rcClient.Left,
        pcp.rcClient.Top,
        pcp.rcClient.Right div 2,
        1
      );
      DrawGradRect(
        pcp.hdcMem,
        rcItem,
        GetSysColor(COLOR_3DFACE),
        GetSysColor(COLOR_BTNSHADOW),
        100
      );

      SetRect(
        rcItem,
        pcp.rcClient.Left,
        pcp.rcClient.Bottom -1,
        pcp.rcClient.Right div 2,
        pcp.rcClient.Bottom
      );
      DrawGradRect(
        pcp.hdcMem,
        rcItem,
        GetSysColor(COLOR_3DFACE),
        GetSysColor(COLOR_BTNSHADOW),
        100
      );

      SetRect(
        rcItem,
        pcp.rcClient.Right div 2,
        pcp.rcClient.Top,
        pcp.rcClient.Right,
        1
      );
      DrawGradRect(
        pcp.hdcMem,
        rcItem,
        GetSysColor(COLOR_BTNSHADOW),
        GetSysColor(COLOR_3DFACE),
        100
      );

      SetRect(
        rcItem,
        pcp.rcClient.Right div 2,
        pcp.rcClient.Bottom -1,
        pcp.rcClient.Right,
        pcp.rcClient.Bottom
      );
      DrawGradRect(
        pcp.hdcMem,
        rcItem,
        GetSysColor(COLOR_BTNSHADOW),
        GetSysColor(COLOR_3DFACE),
        100
      );

    end;

    CtrlWndProc_BitBlt(hdcIn, pcp.hdcMem, SRCCOPY);

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

  RedrawWindow(hWnd, nil, 0, RDW_NOERASE or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_WmTimer(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (pcp.dwMode <> SST_CENTER) then
  begin

    case pcp.dwMode of
      SST_RIGHT:
      begin
        if pcp.bScroll then
          Inc(pcp.dwOffset, pcp.dwPixels);
        if (pcp.dwOffset >= (pcp.rcClient.Right - pcp.rcClient.Left) + 10) then
          CtrlWndProc_SetStartPos(pcp);
      end;
      SST_LEFT:
      begin
        if pcp.bScroll then
          Dec(pcp.dwOffset, pcp.dwPixels);
        if (pcp.dwOffset <= (-pcp.txtSize.cx - 10)) then
          CtrlWndProc_SetStartPos(pcp);
      end;
    end;

  end;

  RedrawWindow(hWnd, nil, 0, RDW_NOERASE or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetScrollElapse(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwElapse);

end;

//

function CtrlWndProc_StmExSetScrollElapse(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwElapse := wParam;
  if (pcp.timerId <> 0) then
  begin
    KillTimer(hWnd, pcp.timerId);
    pcp.timerId := 0;
  end;
  pcp.timerId := SetTimer(hWnd, 0, pcp.dwElapse, nil);
  RedrawWindow(hWnd, nil, 0, RDW_NOERASE or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetScrollMode(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwMode);

end;

//

function CtrlWndProc_StmExSetScrollMode(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if not DWORD(lParam) in [SST_CENTER, SST_RIGHT, SST_LEFT] then
    pcp.dwMode := SST_LEFT
  else
    pcp.dwMode := DWORD(lParam);

  RedrawWindow(hWnd, nil, 0, RDW_NOERASE or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetScrollExStyle(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := pcp.dwExStyle;

end;

//

function CtrlWndProc_StmExSetScrollExStyle(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwExStyle := lParam;
  RedrawWindow(hWnd, nil, 0, RDW_NOERASE or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;
//

function CtrlWndProc_StmExGetScrollPixel(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := pcp.dwPixels;

end;

//

function CtrlWndProc_StmExSetScrollPixel(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwPixels := wParam;
  RedrawWindow(hWnd, nil, 0, RDW_NOERASE or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_StmExSetStartPos(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  CtrlWndProc_SetStartPos(pcp);

  Result := 0;

end;

//

function CtrlWndProc_StmExSetEnableScroll(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.bScroll := Boolean(wParam);

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

    WM_SETFONT:
    begin
      Result := CtrlWndProc_WmSetFont(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_ENABLE:
    begin
      Result := CtrlWndProc_WmEnable(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_SETTEXT:
    begin
      Result := CtrlWndProc_WmSetText(pcp, hWnd, uMsg, wParam, lParam);
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

    WM_TIMER:
    begin
      Result := CtrlWndProc_WmTimer(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETSCROLLMODE:
    begin
      Result := CtrlWndProc_StmExGetScrollMode(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSCROLLMODE:
    begin
      Result := CtrlWndProc_StmExSetScrollMode(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETSCROLLELAPSE:
    begin
      Result := CtrlWndProc_StmExGetScrollElapse(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSCROLLELAPSE:
    begin
      Result := CtrlWndProc_StmExSetScrollElapse(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETSCROLLEXSTYLE:
    begin
      Result := CtrlWndProc_StmExGetScrollExStyle(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSCROLLEXSTYLE:
    begin
      Result := CtrlWndProc_StmExSetScrollExStyle(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETSCROLLPIXEL:
    begin
      Result := CtrlWndProc_StmExGetScrollPixel(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSCROLLPIXEL:
    begin
      Result := CtrlWndProc_StmExSetScrollPixel(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSTARTPOS:
    begin
      Result := CtrlWndProc_StmExSetStartPos(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETENABLESCROLL:
    begin
      Result := CtrlWndProc_StmExSetEnableScroll(pcp, hWnd, uMsg, wParam, lParam);
    end;

  else
    Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);
  end;

end;

//

procedure CreateScrollCtrlStaticW(hWnd: HWND);
var
  dwRet: DWORD;
begin

  RemoveScrollCtrlStaticW(hWnd);

  pcp := P_CTRL_PRO(HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, SizeOf(T_CTRL_PRO)));
  if (pcp <> nil) then
  try

    ZeroMemory(pcp, SizeOf(T_CTRL_PRO));

    pcp.CtrlProc   := TCtrlWndProc(Pointer(GetWindowLongPtrW(hWnd, GWL_WNDPROC)));
    pcp.dwClsExtra := GetWindowLongPtrW(hWnd, GWL_USERDATA);
    SetRectEmpty(pcp.rcClient);
    pcp.hFont      := SendMessageW(hWnd, WM_GETFONT, 0, 0);
    pcp.dwMode     := SST_LEFT;
    pcp.dwElapse   := 35;
    pcp.dwOffset   := 0;
    pcp.dwPixels   := 1;
    pcp.dwExStyle  := $00000000;
    pcp.bScroll    := TRUE;
    pcp.timerId    := SetTimer(hWnd, 0, pcp.dwElapse, nil);
    pcp.dwStyle    := GetWindowLongPtrW(hWnd, GWL_STYLE);

    if ((pcp.dwStyle and SS_NOTIFY) = 0) then
      SetWindowLongPtrW(hWnd, GWL_STYLE, pcp.dwStyle or SS_NOTIFY);

    dwRet := SendMessageW(hWnd, WM_GETTEXTLENGTH, 0, 0);
    if (dwRet > 0) then
    begin

      SetLength(pcp.pszText, dwRet + 1);
      SendMessageW(hWnd, WM_GETTEXT, dwRet + 1, LPARAM(LPWSTR(pcp.pszText)));
      pcp.txtSize := CtrlWndProc_GetTextSize(pcp, hWnd);

    end;

    SetWindowLongPtrW(hWnd, GWL_USERDATA, Longint(pcp));

    SetWindowLongPtrW(hWnd, GWL_WNDPROC, Longint(@CtrlWndProc));

    SendMessageW(hWnd, WM_SIZE, 0, 0);

    CallWindowProcW(@pcp.CtrlProc, hWnd, WM_PRINTCLIENT, pcp.hdcMem, PRF_CLIENT);
    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  finally
  end;

end;

//

procedure RemoveScrollCtrlStaticW(hWnd: HWND);
begin

  pcp := P_CTRL_PRO(GetWindowLongPtrW(hWnd, GWL_USERDATA));
  if (pcp <> nil) then
  try

    if (pcp.timerId <> 0) then
      KillTimer(hWnd, pcp.timerId);

    CtrlWndProc_DeleteObject(pcp.hdcMem, pcp.hbmMem, pcp.hbmOld);

    SetWindowLongPtrW(hWnd, GWL_STYLE, pcp.dwStyle);

    SetWindowLongPtrW(hWnd, GWL_WNDPROC, Longint(@pcp.CtrlProc));

    SetWindowLongPtrW(hWnd, GWL_USERDATA, pcp.dwClsExtra);

    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  finally
    HeapFree(GetProcessHeap, 0, pcp);
  end;

end;

end.