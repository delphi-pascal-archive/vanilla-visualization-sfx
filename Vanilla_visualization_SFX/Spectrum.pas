unit Spectrum;

{******************************************************************************}
{                                                                              }
{ Проект             : Spectrum Control                                        }
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

procedure CreateSpecCtrlStaticW(hWnd: HWND);
procedure RemoveSpecCtrlStaticW(hWnd: HWND);

const

  { extended control messages }

  STM_GETSPECELAPSE     = WM_USER + 101;
  STM_SETSPECELAPSE     = WM_USER + 102;

  STM_GETSPECMODE       = WM_USER + 103;
  STM_SETSPECMODE       = WM_USER + 104;

  STM_EX_GETSPECEXSTYLE = WM_USER + 105;
  STM_EX_SETSPECEXSTYLE = WM_USER + 106;

  STM_SETSPECHSTREAM    = WM_USER + 107;

  { extended control styles }

  SS_EX_GRID = $00000001;

  { extended control states }

  SS_NONE   = 0;
  SS_THICK  = 1;
  SS_THIN   = 2;
  SS_LINES  = 3;
  SS_SOLID  = 4;
  SS_DOUBLE = 5;

implementation

const

  MAX_WIDTH   = 89;
  MAX_HEIGTH  = 29;

  BandsCount  = 20;
  BlockWidth  = 3;
  BlockHeight = 25;
  BlockGap    = 1;

type

  TFFTData  = Array [0..1024] of Single;
  TWavData  = Array [0..2048] of DWORD;
  TBandData = Array [0..BandsCount-1] of WORD;

  TCtrlWndProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;

  P_CTRL_PRO = ^T_CTRL_PRO;
  T_CTRL_PRO = packed record
    CtrlProc  : TCtrlWndProc;
    dwClsExtra: DWORD;
    //
    hdcMem    : HDC;
    hbmMem    : HBITMAP;
    hbmOld    : HBITMAP;
    hdcBar    : HDC;
    hbrMem    : HBITMAP;
    hbrOld    : HBITMAP;
    //
    dwElapse  : Integer;
    dwMode    : Integer;
    //
    stream    : HSTREAM;
    //
    color     : TColorRef;
    //
    Peak      : Array [1..BandsCount] of Single;
    Passed    : Array [1..BandsCount] of Integer;
    BandOut   : TBandData;
    //
    dwExStyle : DWORD;
    //
    timerId   : DWORD;
    //
    dwStyle   : DWORD;
  end;

var

  pcp: P_CTRL_PRO;

  gpt: Array [0..27] of TPoint = (
    (X: 0; Y: 0),
    (X: 0; Y: 12),
    (X: 0; Y: 24),
    (X: 1; Y: 0),
    (X: 1; Y: 10),
    (X: 1; Y: 12),
    (X: 1; Y: 14),
    (X: 1; Y: 24),
    (X: MAX_WIDTH - 2; Y: 0),
    (X: MAX_WIDTH - 2; Y: 10),
    (X: MAX_WIDTH - 2; Y: 12),
    (X: MAX_WIDTH - 2; Y: 14),
    (X: MAX_WIDTH - 2; Y: 24),
    (X: MAX_WIDTH - 1; Y: 0),
    (X: MAX_WIDTH - 1; Y: 12),
    (X: MAX_WIDTH - 1; Y: 24),
    (X: 10; Y: MAX_HEIGTH - 2),
    (X: 18; Y: MAX_HEIGTH - 2),
    (X: 27; Y: MAX_HEIGTH - 2),
    (X: 34; Y: MAX_HEIGTH - 2),
    (X: 44; Y: MAX_HEIGTH - 2),
    (X: 54; Y: MAX_HEIGTH - 2),
    (X: 62; Y: MAX_HEIGTH - 2),
    (X: 70; Y: MAX_HEIGTH - 2),
    (X: 78; Y: MAX_HEIGTH - 2),
    (X: 10; Y: MAX_HEIGTH - 1),
    (X: 44; Y: MAX_HEIGTH - 1),
    (X: 78; Y: MAX_HEIGTH - 1)
  );

//

procedure CtrlWndProc_DrawGrid(pcp: P_CTRL_PRO);
var
  lb  : TLogBrush;
  pNew: HPEN;
  pOld: HPEN;
  pt  : Integer;
begin

  // brush.

  lb.lbStyle := BS_SOLID;
  lb.lbColor := pcp.color;
  lb.lbHatch := 0;

  pNew := ExtCreatePen(PS_COSMETIC or PS_ALTERNATE, 1, lb, 0, nil);
  if (pNew <> 0) then
  try

    pOld := SelectObject(pcp.hdcMem, pNew);
    if (pOld <> 0) then
    try

      // left.

      MoveToEx(pcp.hdcMem, 2, 0, nil);
      LineTo(pcp.hdcMem, 2, MAX_HEIGTH - 4);

      // right.

      MoveToEx(pcp.hdcMem, MAX_WIDTH - 3, 0, nil);
      LineTo(pcp.hdcMem, MAX_WIDTH - 3, MAX_HEIGTH - 4);

      // bottom.

      MoveToEx(pcp.hdcMem, 2, MAX_HEIGTH - 3, nil);
      LineTo(pcp.hdcMem, MAX_WIDTH - 2, MAX_HEIGTH - 3);

      // array of points.

      for pt := Low(gpt) to High(gpt) do
        SetPixel(pcp.hdcMem, gpt[pt].X, gpt[pt].Y, pcp.color);

    finally
      SelectObject(pcp.hdcMem, pOld);
    end;

  finally
    DeleteObject(pNew);
  end;

end;

//

procedure CtrlWndProc_DrawBands(pcp: P_CTRL_PRO);
var
  tmprc : TRect;
  barrc : TRect;
  band  : Integer;
  penNew: HPEN;
  penOld: HPEN;
begin

  if (pcp.dwMode = SS_THICK) then
  begin

    for band := 1 to BandsCount do
    begin

      if (pcp.BandOut[band-1] > BlockHeight) then
        pcp.BandOut[band-1] := BlockHeight;

      if (pcp.BandOut[band-1] > 0) then
      begin

        SetRect(
          barrc,
          0,
          BlockHeight - pcp.BandOut[band-1],
          BlockWidth,
          BlockHeight
        );

        if (barrc.Top < 0) then
          barrc.Top := 0;

        SetRect(
          tmprc,
          (BlockWidth + BlockGap) * (band - 1) + 5,
          barrc.Top,
          tmprc.Left + BlockWidth,
          barrc.Bottom - 1
        );

        BitBlt(
          pcp.hdcMem,
          tmprc.Left,
          tmprc.Top,
          BlockWidth,
          tmprc.Bottom - tmprc.Top + 1,
          pcp.hdcBar,
          barrc.Left,
          barrc.Top,
          SRCCOPY
        );

      end;

      if (pcp.BandOut[band-1] >= Trunc(pcp.Peak[band])) then
      begin

        pcp.Peak[band] := pcp.BandOut[band-1] + 0.01;
        pcp.Passed[band] := 0;

      end
      else
      begin
        if (pcp.BandOut[band-1] < Trunc(pcp.Peak[band])) then
        begin
          if (Trunc(pcp.Peak[band]) > 0) then
          begin

            penNew := CreatePen(PS_SOLID, 1, pcp.color);
            penOld := SelectObject(pcp.hdcMem, penNew);

            MoveToEx(
              pcp.hdcMem,
              (BlockWidth + BlockGap) * band + 3,
              BlockHeight - Trunc(pcp.Peak[band]),
              nil
            );
            LineTo(
              pcp.hdcMem,
              (BlockWidth + BlockGap) * (band - 1) + 1 + BlockWidth,
              BlockHeight - Trunc(pcp.Peak[band])
            );

            SelectObject(pcp.hdcMem, penOld);
            DeleteObject(penNew);

            if (pcp.Passed[band] >= 8) then
              pcp.Peak[band] := pcp.Peak[band] - 0.3 * (pcp.Passed[band] - 8);
            if (pcp.Peak[band] <= 3) then
              pcp.Peak[band] := 1
            else
              Inc(pcp.Passed[band]);

          end;
        end;
      end;

    end;

  end;

end;

//

procedure CtrlWndProc_DrawEffects(pcp: P_CTRL_PRO);
const
  bandFreq: Array [0..BandsCount-1] of WORD = (1, 2, 3, 6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96, 102);
  Boost   = 0.15;
  Scale   = 80;
  MaxVal  = 65535;
  DrawRes = 4;
  ScopOff = MAX_HEIGTH - 5 * 2;
  xCenter = (MAX_HEIGTH - 5) div 2;
var
  dwRet : DWORD;
  xLeft : Integer;
  pixel : Integer;
  data  : TWavData;
  fft   : TFFTData;
  penNew: HPEN;
  penOld: HPEN;
  right : SmallInt;
  left  : SmallInt;
  posit : Integer;
  bdata : TBandData;
  start : Integer;
  band  : Integer;
  inten : Double;

  procedure DrawCenterLine;
  const
    xLeft   = 5;
    xCenter = (MAX_HEIGTH - xLeft) div 2;
    xPosit  = MAX_WIDTH - xLeft;
  begin
    penNew := CreatePen(PS_SOLID, 1, pcp.color);
    penOld := SelectObject(pcp.hdcMem, penNew);
    MoveToEx(pcp.hdcMem, xLeft, xCenter, nil);
    LineTo(pcp.hdcMem, xPosit, xCenter);
    SelectObject(pcp.hdcMem, penOld);
    DeleteObject(penNew);
  end;

  procedure FillArrayBands;
  var
    band: Integer;
  begin
    for band := 0 to (BandsCount - 1) do
      pcp.BandOut[band] := 1;
  end;

begin

  if (pcp.dwMode <> SS_NONE) then
  begin

    if (pcp.stream <> 0) then
    begin

      dwRet := BASS_ChannelIsActive(pcp.stream);
      if (dwRet = BASS_ACTIVE_PLAYING) then
      begin

        case pcp.dwMode of

          SS_THICK:
          begin

            ZeroMemory(@fft, SizeOf(TFFTData));
            dwRet := BASS_ChannelGetData(pcp.stream, @fft, BASS_DATA_FFT1024);
            if (dwRet = $FFFFFFFF) then
            begin
              for band := 0 to (BandsCount - 1) do
                pcp.BandOut[band] := 0;
            end;

            for band := 0 to (BandsCount - 1) do
            begin
              if (band = 0) then
                start := 1
              else
                start := bandFreq[band-1] + 1;
              inten := 0;
              for posit := start to bandFreq[band] do
              begin
                if (fft[posit] > inten) then
                  inten := fft[posit];
              end;
              bdata[band] := Round(inten * (1 + band * Boost) * Scale);
              if bdata[band] > pcp.BandOut[band] then
                pcp.BandOut[band] := bdata[band]
              else
              begin
                if (pcp.BandOut[band] >= 2) then
                  Dec(pcp.BandOut[band], 2)
                else
                  pcp.BandOut[band] := 0;
              end;
              if (bdata[band] > pcp.BandOut[band]) then
                pcp.BandOut[band] := bdata[band];
            end;

          end;

          SS_THIN:
          begin

            xLeft := 5;

            ZeroMemory(@fft, SizeOf(TFFTData));
            BASS_ChannelGetData(pcp.stream, @fft, BASS_DATA_FFT1024);

            penNew := CreatePen(PS_SOLID, 1, pcp.color);
            penOld := SelectObject(pcp.hdcMem, penNew);

            for pixel := xLeft to (MAX_WIDTH - 6) do
            begin
              MoveToEx(pcp.hdcMem, pixel, MAX_HEIGTH - xLeft, nil);
              LineTo(
                pcp.hdcMem,
                pixel,
                (MAX_HEIGTH - xLeft) - Round(fft[pixel] * (MAX_HEIGTH - xLeft) * (MAX_HEIGTH - 15))
              );
            end;

            SelectObject(pcp.hdcMem, penOld);
            DeleteObject(penNew);

          end;

          SS_LINES,
          SS_SOLID:
          begin

            ZeroMemory(@data, SizeOf(TWavData));
            BASS_ChannelGetData(pcp.stream, @data, 1225);

            penNew := CreatePen(PS_SOLID, 1, pcp.color);
            penOld := SelectObject(pcp.hdcMem, penNew);

            if (pcp.dwMode = SS_LINES) then
              xLeft := 4
            else
              xLeft := 5;

            MoveToEx(pcp.hdcMem, xLeft, xCenter, nil);
            posit := MAX_WIDTH - (xLeft * 2);

            for pixel := xLeft to posit do
            begin
              right := SmallInt(LoWord(data[pixel * DrawRes]));
              left := SmallInt(HiWord(data[pixel * DrawRes]));
              posit := Trunc(((right + left) / (MaxVal + (MaxVal / 2))) * ScopOff);

              if (pcp.dwMode = SS_LINES) then
                MoveToEx(pcp.hdcMem, xLeft + pixel, xCenter, nil);

              LineTo(pcp.hdcMem, xLeft + pixel, xCenter + posit);
            end;

            SelectObject(pcp.hdcMem, penOld);
            DeleteObject(penNew);

            if (pcp.dwMode = SS_LINES) then
              DrawCenterLine;

          end;

          SS_DOUBLE:
          begin

            xLeft := 5;

            ZeroMemory(@fft, SizeOf(TFFTData));
            BASS_ChannelGetData(pcp.stream, @fft, BASS_DATA_FFT512);

            penNew := CreatePen(PS_SOLID, 1, pcp.color);
            penOld := SelectObject(pcp.hdcMem, penNew);

            for pixel := xLeft to (MAX_WIDTH - xLeft) do
              fft[pixel] := fft[pixel] * Ln(pixel + 1) * 3 * (MAX_HEIGTH - 10);
            MoveToEx(pcp.hdcMem, xLeft, (MAX_HEIGTH - xLeft) div 2, nil);
            for pixel := xLeft to (MAX_WIDTH - xLeft) do
              LineTo(pcp.hdcMem, pixel, (MAX_HEIGTH - xLeft) div 2 - Round(fft[pixel] / 3));
            MoveToEx(pcp.hdcMem, xLeft, (MAX_HEIGTH - xLeft) div 2, nil);
            for pixel := xLeft to (MAX_WIDTH - xLeft) do
              LineTo(pcp.hdcMem, pixel, (MAX_HEIGTH - xLeft) div 2 + Round(fft[pixel] / 3));

            SelectObject(pcp.hdcMem, penOld);
            DeleteObject(penNew);

          end;

        end;

      end
      else
      begin

        case pcp.dwMode of

          SS_THICK:
          begin
            FillArrayBands;
          end;

          {
          SS_THIN:
          begin
          end;
          }

          SS_LINES,
          SS_SOLID,
          SS_DOUBLE:
          begin
            DrawCenterLine;
          end;

        end;

      end;

    end
    else
    begin

      case pcp.dwMode of

        SS_THICK:
        begin
          FillArrayBands;
        end;

        SS_THIN:
        begin
        end;

        SS_LINES,
        SS_SOLID,
        SS_DOUBLE:
        begin
          DrawCenterLine;
        end;

      end;

    end;

  end;

end;

//

function CtrlWndProc_WmDestroy(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RemoveSpecCtrlStaticW(hWnd);

  Result := 0;

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

    BitBlt(hdcIn, 0, 0, MAX_WIDTH, MAX_HEIGTH, pcp.hdcMem, 0, 0, SRCCOPY);

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

  CallWindowProcW(@pcp.CtrlProc, hWnd, WM_PRINTCLIENT, pcp.hdcMem, PRF_CLIENT);
  if ((pcp.dwExStyle and SS_EX_GRID) <> 0) then
    CtrlWndProc_DrawGrid(pcp);
  CtrlWndProc_DrawEffects(pcp);
  CtrlWndProc_DrawBands(pcp);
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_StmGetSpecElapse(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwElapse);

end;

//

function CtrlWndProc_StmSetSpecElapse(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwElapse := wParam;
  if (pcp.timerId <> 0) then
  begin
    KillTimer(hWnd, pcp.timerId);
    pcp.timerId := 0;
  end;
  pcp.timerId := SetTimer(hWnd, 0, pcp.dwElapse, nil);

  Result := 0;

end;

//

function CtrlWndProc_StmGetSpecMode(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwMode);

end;

//

function CtrlWndProc_StmSetSpecMode(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwMode := wParam;

  Result := 0;

end;

//

function CtrlWndProc_StmExGetSpecExStyle(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := pcp.dwExStyle;

end;

//

function CtrlWndProc_StmExSetSpecExStyle(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwExStyle := lParam;
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_StmSetSpecHStream(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
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

    STM_GETSPECELAPSE:
    begin
      Result := CtrlWndProc_StmGetSpecElapse(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_SETSPECELAPSE:
    begin
      Result := CtrlWndProc_StmSetSpecElapse(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_GETSPECMODE:
    begin
      Result := CtrlWndProc_StmGetSpecMode(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_SETSPECMODE:
    begin
      Result := CtrlWndProc_StmSetSpecMode(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETSPECEXSTYLE:
    begin
      Result := CtrlWndProc_StmExGetSpecExStyle(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETSPECEXSTYLE:
    begin
      Result := CtrlWndProc_StmExSetSpecExStyle(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_SETSPECHSTREAM:
    begin
      Result := CtrlWndProc_StmSetSpecHStream(pcp, hWnd, uMsg, wParam, lParam);
    end;

  else
    Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);
  end;

end;

//

procedure CreateSpecCtrlStaticW(hWnd: HWND);
var
  hdcIn: HDC;
  brush: HBRUSH;
  rect : TRect;
begin

  RemoveSpecCtrlStaticW(hWnd);

  pcp := P_CTRL_PRO(HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, SizeOf(T_CTRL_PRO)));
  if (pcp <> nil) then
  try

    SetWindowPos(
      hWnd,
      HWND_TOP,
      0,
      0,
      MAX_WIDTH,
      MAX_HEIGTH,
      SWP_NOMOVE or SWP_NOZORDER
    );

    ZeroMemory(pcp, SizeOf(T_CTRL_PRO));

    pcp.CtrlProc   := TCtrlWndProc(Pointer(GetWindowLongPtrW(hWnd, GWL_WNDPROC)));
    pcp.dwClsExtra := GetWindowLongPtrW(hWnd, GWL_USERDATA);
    pcp.dwElapse   := 30;
    pcp.dwMode     := SS_THICK;
    pcp.stream     := 0;
    pcp.color      := RGB(0, 0, 0);
    pcp.dwExStyle  := SS_EX_GRID;
    pcp.timerId    := SetTimer(hWnd, 0, pcp.dwElapse, nil);
    pcp.dwStyle    := GetWindowLongPtrW(hWnd, GWL_STYLE);

    hdcIn := GetDC(hWnd);
    if (hdcIn <> 0) then
    try

      pcp.hdcMem := CreateCompatibleDC(hdcIn);
      if (pcp.hdcMem <> 0) then
      try
        pcp.hbmMem := CreateCompatibleBitmap(hdcIn, MAX_WIDTH, MAX_HEIGTH);
      finally
        pcp.hbmOld := SelectObject(pcp.hdcMem, pcp.hbmMem);
      end;

      pcp.hdcBar := CreateCompatibleDC(hdcIn);
      if (pcp.hdcMem <> 0) then
      try
        pcp.hbrMem := CreateCompatibleBitmap(hdcIn, MAX_WIDTH, MAX_HEIGTH);
      finally
        pcp.hbrOld := SelectObject(pcp.hdcBar, pcp.hbrMem);
      end;
    finally
      ReleaseDC(hWnd, hdcIn);
    end;

    brush := CreateSolidBrush(pcp.color);
    if (brush <> 0) then
    try
      SetRect(rect, 0, 0, MAX_WIDTH, MAX_HEIGTH);
      FillRect(pcp.hdcBar, rect, brush);
    finally
      DeleteObject(brush);
    end;

    if ((pcp.dwStyle and SS_NOTIFY) = 0) then
      SetWindowLongPtrW(hWnd, GWL_STYLE, pcp.dwStyle or SS_NOTIFY);

    SetWindowLongPtrW(hWnd, GWL_USERDATA, Longint(pcp));

    SetWindowLongPtrW(hWnd, GWL_WNDPROC, Longint(@CtrlWndProc));

    CallWindowProcW(@pcp.CtrlProc, hWnd, WM_PRINTCLIENT, pcp.hdcMem, PRF_CLIENT);
    if ((pcp.dwExStyle and SS_EX_GRID) <> 0) then
      CtrlWndProc_DrawGrid(pcp);
    CtrlWndProc_DrawEffects(pcp);
    CtrlWndProc_DrawBands(pcp);
    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  finally
  end;

end;

//

procedure RemoveSpecCtrlStaticW(hWnd: HWND);
begin

  pcp := P_CTRL_PRO(GetWindowLongPtrW(hWnd, GWL_USERDATA));
  if (pcp <> nil) then
  try

    if (pcp.timerId <> 0) then
      KillTimer(hWnd, pcp.timerId);

    if (pcp.hdcMem <> 0) then
    try
      SelectObject(pcp.hdcMem, pcp.hbmOld);
    finally
      DeleteObject(pcp.hbmMem);
      DeleteDC(pcp.hdcMem);
    end;

    if (pcp.hdcBar <> 0) then
    try
      SelectObject(pcp.hdcBar, pcp.hbrOld);
    finally
      DeleteObject(pcp.hbrMem);
      DeleteDC(pcp.hdcBar);
    end;

    SetWindowLongPtrW(hWnd, GWL_STYLE, pcp.dwStyle);

    SetWindowLongPtrW(hWnd, GWL_WNDPROC, Longint(@pcp.CtrlProc));

    SetWindowLongPtrW(hWnd, GWL_USERDATA, pcp.dwClsExtra);

    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  finally
    HeapFree(GetProcessHeap, 0, pcp);
  end;

end;

end.