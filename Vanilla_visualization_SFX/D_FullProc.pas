unit D_FullProc;

interface

uses
  Windows, Messages, PlugDraw, bass_sfx, F_Resources;

function FullWndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;

implementation

//

function FullWndProc_WmCreate(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
const
  pszClass: LPWSTR = 'STATIC';
var
  hDlg  : THandle;
  plugin: HSFX;
begin

  CreateWindowExW(
    0,
    pszClass,
    nil,
    WS_CHILD or WS_VISIBLE,
    0,
    0,
    GetSystemMetrics(SM_CXSCREEN),
    GetSystemMetrics(SM_CYSCREEN),
    hWnd,
    IDC_FULLSCR,
    HInstance,
    nil
  );

  hDlg := GetParent(hWnd);
  if (hDlg <> 0) then
  begin

    plugin := SendMessageW(GetDlgItem(hDlg, IDC_VISUAL), STM_EX_GETSFXHMODULE,
      0, 0);
    if (plugin <> -1) then
    begin

      CreatePlugCtrlStaticW(GetDlgItem(hWnd, IDC_FULLSCR));
      SendMessageW(GetDlgItem(hWnd, IDC_FULLSCR), STM_EX_SETSFXMODE, SS_VISUAL, 0);
      SendMessageW(GetDlgItem(hWnd, IDC_FULLSCR), STM_EX_SETSFXHMODULE, 0, plugin);
      SendMessageW(GetDlgItem(hWnd, IDC_FULLSCR), STM_EX_SETSFXRESIZE, 0, 0);

    end;

  end;

  Result := 0;

end;

//

function FullWndProc_WmCommand(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  case HiWord(wParam) of

    BN_CLICKED:
      case LoWord(wParam) of

        IDC_FULLSCR,
        ID_CANCEL:
        begin

          PostMessageW(hWnd, WM_KEYDOWN, 0, 0);

        end;

      end;

  end;

  Result := 0;

end;

//

function FullWndProc_WmKeyDown(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  PostMessageW(hWnd, WM_DESTROY, 0, 0);

  Result := 0;

end;

//

function FullWndProc_WmSetCursor(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  SetCursor(0);

  Result := 1;

end;

//

function FullWndProc_WmDestroy(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RemovePlugCtrlStaticW(GetDlgItem(hWnd, IDC_FULLSCR));

  DestroyWindow(hWnd);
  hVisWnd := 0;
  PostQuitMessage(0);

  Result := 0;

end;

//

function FullWndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin

  case uMsg of

    //

    WM_CREATE:
    begin
      Result := FullWndProc_WmCreate(hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_COMMAND:
    begin
      Result := FullWndProc_WmCommand(hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_LBUTTONDOWN,
    WM_MBUTTONDOWN,
    WM_RBUTTONDOWN,
    WM_KEYDOWN:
    begin
      Result := FullWndProc_WmKeyDown(hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_SETCURSOR:
    begin
      Result := FullWndProc_WmSetCursor(hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_DESTROY:
    begin
      Result := FullWndProc_WmDestroy(hWnd, uMsg, wParam, lParam);
    end;

  else
    Result := DefWindowProcW(hWnd, uMsg, wParam, lParam);
  end;

end;

end.