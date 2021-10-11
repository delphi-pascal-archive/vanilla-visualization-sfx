unit D_MainProc;

interface

uses
  Windows, Messages, CommCtrl, ShellApi, F_Windows, F_Messages, F_CommDlg,
  F_SysUtils, DigitTimer, BeatMeter, PlugDraw, Spectrum, TextScroll, bass,
  bass_sfx, F_MiscUtils, F_Resources, D_FullProc;

function MainDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;

implementation

//

function MainDlgProc_WmInitDialog(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
const
  fmtPlug: WideString = 'Plugins';
  fmtFind: WideString = '%s%s\*.svp';
  fmtPath: WideString = '%s%s\%s';
var
  dwRet  : DWORD;
  hbim   : HBITMAP;
  himl   : HIMAGELIST;
  hFind  : THandle;
  hData  : TWin32FindDataW;
  pszPath: WideString;
  pszText: WideString;
  plugin : HSFX;
  bRet   : Boolean;
  wc     : TWndClassExW;
  osvi   : TOSVersionInfoW;
begin

  //

  BASS_Init(-1, 44100, 0, hWnd, nil);
  BASS_SFX_Init(HInstance, hWnd);

  //

  CreateTimerCtrlStaticW(GetDlgItem(hWnd, IDC_TIMER));
  CreateBeatCtrlStaticW(GetDlgItem(hWnd, IDC_METER));
  CreatePlugCtrlStaticW(GetDlgItem(hWnd, IDC_VISUAL));
  CreateSpecCtrlStaticW(GetDlgItem(hWnd, IDC_SPECTR));
  CreateScrollCtrlStaticW(GetDlgItem(hWnd, IDC_SCROLL));

  //

  SendMessageW(GetDlgItem(hWnd, IDC_TIMER), STM_EX_SETTIMERMODE, SS_EX_HHMMSS, 0);
  SendMessageW(GetDlgItem(hWnd, IDC_TIMER), STM_EX_SETDIVIDERVALUE, 6, 0);

  //

  SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_SETSFXMODE, SS_VISUAL, 0);

  //

  SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), STM_EX_SETSCROLLMODE, 0,
    SST_CENTER);

  //

  dwRet := SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), STM_EX_GETSCROLLEXSTYLE,
    0, 0);
  SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), STM_EX_SETSCROLLEXSTYLE, 0,
    dwRet or SS_EX_BLEND or SS_EX_DASH);

  //

  hbim := LoadImageW(HInstance, MAKEINTRESOURCEW(IDB_BITMAP_TIMER), IMAGE_BITMAP,
    0, 0, LR_DEFAULTCOLOR);
  if (hbim <> 0) then
  begin

    himl := ImageList_Create(10, 14, ILC_COLOR8 or ILC_MASK, 0, 0);
    if (himl <> 0) then
    begin

      ImageList_AddMasked(himl, hbim, RGB(192, 192, 192));
      ImageList_SetBkColor(himl, CLR_NONE);
      SendMessageW(GetDlgItem(hWnd, IDC_TIMER), STM_EX_SETIMAGELIST, 0, himl);

    end;
    DeleteObject(hbim);

  end;

  hbim := LoadImageW(HInstance, MAKEINTRESOURCEW(IDB_BITMAP_METER), IMAGE_BITMAP,
    0, 0, LR_LOADMAP3DCOLORS);
  if (hbim <> 0) then
    SendMessageW(GetDlgItem(hWnd, IDC_METER), STM_EX_SETBEATIMAGE, 0, hbim);

  hbim := LoadImageW(HInstance, MAKEINTRESOURCEW(IDB_BITMAP_BANNER), IMAGE_BITMAP,
    0, 0, LR_LOADMAP3DCOLORS);
  if (hbim <> 0) then
    SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_SETSFXIMAGE, 0, hbim);

  //

  SendMessageW(GetDlgItem(hWnd, IDC_VOLUME), TBM_SETRANGEMIN, Integer(TRUE), 0);
  SendMessageW(GetDlgItem(hWnd, IDC_VOLUME), TBM_SETRANGEMAX, Integer(TRUE), 100);
  SendMessageW(GetDlgItem(hWnd, IDC_VOLUME), TBM_SETRANGE, Integer(TRUE),
    MakeLParam(0, 100));
  SendMessageW(GetDlgItem(hWnd, IDC_VOLUME), TBM_SETPOS, Integer(TRUE), 100);

  //

  pszPath := FormatW(
    fmtFind,
    [ExtractFilePathW(AnsiStringToWide(ParamStr(0), CP_ACP)), fmtPlug]
  );
  hFind := FindFirstFileW(LPWSTR(pszPath), hData);
  if (hFind <> INVALID_HANDLE_VALUE) then
  begin
    repeat
      if (hData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0) then
      begin

        pszText := FormatW(
          fmtPath,
          [ExtractFilePathW(AnsiStringToWide(ParamStr(0), CP_ACP)), fmtPlug, hData.cFileName]
        );

        plugin := BASS_SFX_PluginCreateW(LPWSTR(pszText), 0, 0, 0, 0);
        if (plugin <> -1) then
        begin

          BASS_SFX_PluginFree(plugin);
          SendMessageW(GetDlgItem(hWnd, IDC_PLUGINS), LB_ADDSTRING, 0,
            Integer(LPWSTR(pszText)));

        end;

      end;
    until
      not FindNextFileW(hFind, hData);
    FindClose(hFind);

  end;

  //

  ZeroMemory(@osvi, SizeOf(TOSVersionInfoW));
  osvi.dwOSVersionInfoSize := SizeOf(TOSVersionInfoW);
  F_Windows.GetVersionExW(osvi);
  if (osvi.dwMajorVersion >= 6) then
  begin

    ChangeWindowMessageFilter(WM_COPYGLOBALDATA, MSGFLT_ADD);
    ChangeWindowMessageFilter(WM_DROPFILES, MSGFLT_ADD);

  end;

  DragAcceptFiles(hWnd, TRUE);

  //

  SendMessageW(GetDlgItem(hWnd, IDC_PLUGINS), LB_SETCURSEL, 0, 0);
  SendMessageW(hWnd, WM_COMMAND, MakeWParam(IDC_STOP, BN_CLICKED), 0);
  SendMessageW(hWnd, WM_COMMAND, MakeWParam(IDC_PLUGINS, LBN_SELCHANGE),
    GetDlgItem(hWnd, IDC_PLUGINS));

  //

  bRet := GetClassInfoExW(HInstance, pszClass, wc);
  if not bRet then
  begin

    ZeroMemory(@wc, SizeOf(TWndClassExW));

    wc.cbSize        := SizeOf(TWndClassExW);
    wc.style         := {CS_HREDRAW or CS_VREDRAW}0;
    wc.lpfnWndProc   := @FullWndProc;
    wc.cbClsExtra    := 0;
    wc.cbWndExtra    := 0;
    wc.hInstance     := HInstance;
    wc.hIcon         := 0;
    wc.hCursor       := F_Windows.LoadCursorW(0, MAKEINTRESOURCEW(IDC_ARROW));
    wc.hbrBackground := HBRUSH(COLOR_3DFACE + 1);
    wc.lpszMenuName  := nil;
    wc.lpszClassName := pszClass;
    wc.hIconSm       := 0;

    RegisterClassExW(wc);

  end;

  //

  Result := 0;

end;

//

function MainDlgProc_WmCommand(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
const
  fmtFilter: WideString = 'All supported types'#0'*.mp3;*.mo3;*.it;*.xm;*.sm3;*.mtm;*.mod;*.umx'#0#0;
  pszWindow: LPWSTR = 'TPluginWindowName';
var
  osvi   : TOSVersionInfoW;
  ofn    : TOpenFilenameW;
  dwStyle: DWORD;
  pszAnsi: AnsiString;
  dwRet  : DWORD;
  iItem  : Integer;
  pszText: WideString;
  plugin : HSFX;
  bRet   : Boolean;
  wc     : TWndClassExW;
  msg    : TMsg;
  rcItem : TRect;

  procedure SyncEnd(Handle: HSYNC; Channel, Data, User: DWORD); stdcall;
  begin
    SendMessageW(User, WM_COMMAND, MakeWParam(IDC_STOP, BN_CLICKED), 0);
  end;

begin

  //

  case HiWord(wParam) of

    //

    {
    STN_DBLCLK
    }
    LBN_SELCHANGE:
    begin

      //

      case LoWord(wParam) of

        //

        IDC_PLUGINS:
        begin

          plugin := SendMessageW(GetDlgItem(hWnd, IDC_VISUAL),
            STM_EX_GETSFXHMODULE, 0, 0);
          if (plugin <> -1) then
          begin

            SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_SETSFXACTIVATE,
              Integer(FALSE), 0);
            BASS_SFX_PluginFree(plugin);

          end;

          iItem := SendMessageW(GetDlgItem(hWnd, IDC_PLUGINS), LB_GETCURSEL, 0, 0);
          if (iItem <> LB_ERR) then
          begin

            dwRet := SendMessageW(GetDlgItem(hWnd, IDC_PLUGINS), LB_GETTEXTLEN,
              iItem, 0);
            SetLength(pszText, dwRet + 1);
            SendMessageW(GetDlgItem(hWnd, IDC_PLUGINS), LB_GETTEXT, iItem,
              Integer(LPWSTR(pszText)));

            if FileExistsW(pszText) then
            begin

              plugin := BASS_SFX_PluginCreateW(LPWSTR(pszText), 0, 0, 0, 0);
              if (plugin <> -1) then
              begin

                SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_SETSFXHMODULE,
                  0, plugin);
                SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_SETSFXRESIZE,
                  0, 0);
                SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_SETSFXACTIVATE,
                  Integer(TRUE), 0);

              end;

            end;

          end;

        end;


        //

        IDC_SCROLL:
        begin

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_SCROLL),
            STM_EX_GETSCROLLMODE, 0, 0);

          case dwRet of
            SST_RIGHT:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), STM_EX_SETSCROLLMODE,
                0, SST_LEFT);
            end;
            SST_LEFT:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), STM_EX_SETSCROLLMODE,
                0, SST_RIGHT);
            end;

          end;

        end;

      end;

    end;

    //

    BN_CLICKED:
    begin

      //

      case LoWord(wParam) of

        //

        IDC_METER:
        begin

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_METER), STM_GETBEATMODE,
            0, 0);

          case dwRet of
            SS_NONE:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_METER), STM_SETBEATMODE,
                SS_BEAT, 0);
            end;
            SS_BEAT:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_METER), STM_SETBEATMODE,
                SS_NONE, 0);
            end;
          end;

        end;

        //

        IDC_VISUAL:
        begin

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_GETSFXMODE,
            0, 0);

          case dwRet of
            SS_BANNER:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_SETSFXMODE,
                SS_VISUAL, 0);
            end;
            SS_VISUAL:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_SETSFXMODE,
                SS_BANNER, 0);
            end;
          end;

        end;

        //

        IDC_SPECTR:
        begin

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_SPECTR), STM_GETSPECMODE,
            0, 0);

          case dwRet of
            SS_NONE:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_SPECTR), STM_SETSPECMODE,
                SS_THICK, 0);
            end;
            SS_THICK:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_SPECTR), STM_SETSPECMODE,
                SS_THIN, 0);
            end;
            SS_THIN:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_SPECTR), STM_SETSPECMODE,
                SS_SOLID, 0);
            end;
            SS_SOLID:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_SPECTR), STM_SETSPECMODE,
                SS_LINES, 0);
            end;
            SS_LINES:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_SPECTR), STM_SETSPECMODE,
                SS_DOUBLE, 0);
            end;
            SS_DOUBLE:
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_SPECTR), STM_SETSPECMODE,
                SS_NONE, 0);
            end;
          end;

        end;

        //

        IDC_OPEN:
        begin

          ZeroMemory(@osvi, SizeOf(TOSVersionInfoW));
          osvi.dwOSVersionInfoSize := SizeOf(TOSVersionInfoW);
          F_Windows.GetVersionExW(osvi);

          ZeroMemory(@ofn, SizeOf(TOpenFilenameW));

          with ofn do
          begin

            dwStyle := OFN_OVERWRITEPROMPT or OFN_DONTADDTORECENT or
              OFN_ENABLESIZING or OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or
              OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY;

            if (osvi.dwPlatformId = VER_PLATFORM_WIN32_NT) then
              lStructSize := SizeOf(TOpenFilenameW)
            else
              lStructSize := OPENFILENAME_SIZE_VERSION_400W;

            hWndOwner   := hWnd;
            HInstance   := HInstance;
            lpstrFilter := LPWSTR(fmtFilter);
            lpstrFile   := VirtualAlloc(nil, MAX_PATH, MEM_COMMIT, PAGE_READWRITE);
            nMaxFile    := MAX_PATH;
            Flags       := dwStyle;
            FlagsEx     := OFN_EX_NOPLACESBAR;

            if GetOpenFileNameW(ofn) then
            begin

              lstrcpynW(pszFile, lpstrFile, lstrlenW(lpstrFile) + 1);
              SendMessageW(hWnd, WM_COMMAND, MakeLParam(IDC_PLAY, BN_CLICKED), 0);

            end;

            if (lpstrFile <> nil) then
              VirtualFree(lpstrFile, 0, MEM_RELEASE);

          end;

        end;

        //

        IDC_PLAY:
        begin

          SendMessageW(hWnd, WM_COMMAND, MakeWParam(IDC_STOP, BN_CLICKED), 0);

          pszAnsi := WideStringToAnsi(pszFile, CP_ACP);
          stream := BASS_StreamCreateFile(FALSE, LPTSTR(pszAnsi), 0, 0, 0);
          if (stream = 0) then
          begin

            dwRet := BASS_MUSIC_STOPBACK or BASS_MUSIC_RAMP or
              BASS_MUSIC_AUTOFREE or BASS_MUSIC_CALCLEN;
            stream := BASS_MusicLoad(FALSE, LPTSTR(pszAnsi), 0, 0, dwRet, 0);

          end;

          if (stream <> 0) then
          begin

            iItem := Round(GetPlaybackLength(stream));
            SendMessageW(GetDlgItem(hWnd, IDC_SEEK), TBM_SETRANGEMAX, 0, iItem);

            EnableWindow(GetDlgItem(hWnd, IDC_SEEK), TRUE);
            {
            EnableWindow(GetDlgItem(hWnd, IDC_SCREEN), TRUE);
            }

            SendMessageW(GetDlgItem(hWnd, IDC_METER), STM_EX_SETBEATHSTREAM, 0,
              stream);
            SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_SETSFXHSTREAM, 0,
              stream);
            SendMessageW(GetDlgItem(hWnd, IDC_SPECTR), STM_SETSPECHSTREAM, 0,
              stream);

            sync := BASS_ChannelSetSync(stream, BASS_SYNC_END, 0, @SyncEnd,
              Pointer(hWnd));

            SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), STM_EX_SETSCROLLMODE, 0,
              SST_LEFT);
            SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), STM_EX_SETSTARTPOS, 0, 0);

            BASS_ChannelPlay(stream, TRUE);

            SetTimer(hWnd, IDT_TIMER_SEEK, 150, nil);

            pszText := ExtractFileNameW(pszFile);
            SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), WM_SETTEXT, 0,
              Integer(LPWSTR(pszText)));

          end;

        end;

        //

        IDC_STOP:
        begin

          KillTimer(hWnd, IDT_TIMER_SEEK);
          KillTimer(hWnd, IDT_TIMER_CUE);

          dwRet := SendMessageW(hWnd, WM_GETTEXTLENGTH, 0, 0);
          if (dwRet > 0) then
          begin
            SetLength(pszText, dwRet + 1);
            SendMessageW(hWnd, WM_GETTEXT, dwRet + 1, Integer(LPWSTR(pszText)));
          end;

          SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), WM_SETTEXT, 0,
            Integer(LPWSTR(pszText)));

          SendMessageW(GetDlgItem(hWnd, IDC_TIMER), STM_EX_SETTIMEVALUE, 0, 0);
          SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), STM_EX_SETSCROLLMODE, 0,
            SST_CENTER);
          SendMessageW(GetDlgItem(hWnd, IDC_SEEK), TBM_SETPOS, Integer(TRUE), 0);

          EnableWindow(GetDlgItem(hWnd, IDC_SEEK), FALSE);
          {
          EnableWindow(GetDlgItem(hWnd, IDC_SCREEN), FALSE);
          }

          BASS_ChannelRemoveSync(stream, sync);
          BASS_StreamFree(stream);
          BASS_MusicFree(stream);
          stream := 0;
          sync := 0;

        end;

        //

        IDC_SCREEN:
        begin

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_GETSFXMODE,
            0, 0);
          bRet := GetClassInfoExW(HInstance, pszClass, wc);
          if ((dwRet = SS_VISUAL) and bRet) then
          begin

            {
            MessageBox(hWnd, 'CreateWindowExW', nil, 0);
            }

            hVisWnd := CreateWindowExW(
              WS_EX_TOPMOST,
              pszClass,
              pszWindow,
              WS_POPUP or WS_CHILD,
              0,
              0,
              GetSystemMetrics(SM_CXSCREEN),
              GetSystemMetrics(SM_CYSCREEN),
              hWnd,
              0,
              HInstance,
              nil
            );
            if (hVisWnd <> 0) then
            begin

              ShowWindow(hVisWnd, SW_SHOW);
              UpdateWindow(hVisWnd);
              while GetMessageW(msg, 0, 0, 0) do
              begin

                if (not IsDialogMessage(hVisWnd, msg)) then
                begin

                  TranslateMessage(msg);
                  DispatchMessageW(msg);

                end;

              end;

              SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_SETSFXRESIZE, 0, 0);

              SendMessageW(GetDesktopWindow, WM_SETREDRAW, Integer(TRUE), 0);
              GetWindowRect(GetDesktopWindow, rcItem);
              dwRet := RDW_INVALIDATE or RDW_UPDATENOW or RDW_ALLCHILDREN;
              RedrawWindow(GetDesktopWindow, @rcItem, 0, dwRet);

              {
              MessageBox(hWnd, 'PostQuitMessage', nil, 0);
              }

            end;

          end;

        end;

      end;

    end;

  end;

  //

  Result := 0;

end;

//

function MainDlgProc_WmDropFiles(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  //

  try

    ZeroMemory(@pszFile, SizeOf(pszFile));
    DragQueryFileW(HDROP(wParam), 0, pszFile, SizeOf(pszFile));

    SendMessageW(hWnd, WM_COMMAND, MakeLParam(IDC_PLAY, BN_CLICKED), 0);

  finally

    DragFinish(HDROP(wParam));

  end;

  //

  Result := 0;

end;

//

function MainDlgProc_WmTimer(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  intPos : Integer;
  dwRet  : DWORD;
  pszText: WideString;
begin

  //

  if (wParam = IDT_TIMER_SEEK) then
  begin

    dwRet := BASS_ChannelIsActive(stream);
    if (dwRet = BASS_ACTIVE_PLAYING) then
    begin

      intPos := Round(GetPlaybackPosition(stream));

      SendMessageW(GetDlgItem(hWnd, IDC_TIMER), STM_EX_SETTIMEVALUE, intPos, 0);
      SendMessageW(GetDlgItem(hWnd, IDC_SEEK), TBM_SETPOS, Integer(TRUE), intPos);

    end;

  end
  else
  if (wParam = IDT_TIMER_CUE) then
  begin

    if ((GetCapture = GetDlgItem(hWnd, IDC_SEEK)) or
      (GetCapture = GetDlgItem(hWnd, IDC_VOLUME))) then
        dwThick := 3;

    if (dwThick <> 0) then
      Dec(dwThick);

    if (dwThick = 0) then
    begin

      KillTimer(hWnd, IDT_TIMER_CUE);

      dwRet := BASS_ChannelIsActive(stream);
      if (dwRet = BASS_ACTIVE_PLAYING) then
        SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), STM_EX_SETSCROLLMODE, 0,
          SST_LEFT);

      dwRet := BASS_ChannelIsActive(stream);
      if (dwRet = BASS_ACTIVE_PLAYING) then
      begin

        pszText := ExtractFileNameW(pszFile);
        SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), WM_SETTEXT, 0,
          Integer(LPWSTR(pszText)));

      end
      else
      begin

        dwRet := SendMessageW(hWnd, WM_GETTEXTLENGTH, 0, 0);
        if (dwRet > 0) then
        begin
          SetLength(pszText, dwRet + 1);
          SendMessageW(hWnd, WM_GETTEXT, dwRet + 1, Integer(LPWSTR(pszText)));
        end;

        SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), WM_SETTEXT, 0,
          Integer(LPWSTR(pszText)));

      end;

    end;

  end;

  //

  Result := 0;

end;

//

function MainDlgProc_WmHScroll(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
const
  fmtVolume: WideString = 'Volume %d%%';
  fmtTimer : WideString = 'Search %s / %s (%d%%)';
var
  intPos : Integer;
  pszText: WideString;
  dwRet  : DWORD;
begin

  //

  case LoWord(wParam) of
    TB_TOP,
    TB_BOTTOM,
    TB_LINEUP,
    TB_LINEDOWN,
    TB_PAGEUP,
    TB_PAGEDOWN,
    TB_ENDTRACK,
    TB_THUMBPOSITION,
    TB_THUMBTRACK:
    begin

      dwThick := 3;
      KillTimer(hWnd, IDT_TIMER_CUE);
      SetTimer(hWnd, IDT_TIMER_CUE, 250, nil);

      SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), STM_EX_SETSCROLLMODE, 0,
        SST_CENTER);

      if (lParam = Integer(GetDlgItem(hWnd, IDC_SEEK))) then
      begin

        dwRet := BASS_ChannelIsActive(stream);
        if (dwRet = BASS_ACTIVE_PLAYING) then
        begin

          intPos := SendMessageW(GetDlgItem(hWnd, IDC_SEEK), TBM_GETPOS, 0, 0);
          BASS_ChannelSetPosition(stream, BASS_ChannelSeconds2Bytes(stream,
            intPos), BASS_POS_BYTE);

          dwRet := Round(GetPlaybackPosition(stream) / GetPlaybackLength(stream) *
            100);

          pszText := FormatW(
            fmtTimer,
            [GetFmtPlayTime(Round(GetPlaybackPosition(stream)) * 1000),
            GetFmtPlayTime(Round(GetPlaybackLength(stream) * 1000)), dwRet]
          );
          SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), WM_SETTEXT, 0,
            Integer(LPWSTR(pszText)));

          SendMessageW(GetDlgItem(hWnd, IDC_TIMER), STM_EX_SETTIMEVALUE,
            Round(GetPlaybackPosition(stream)), 0);

        end;

      end;

      if (lParam = Integer(GetDlgItem(hWnd, IDC_VOLUME))) then
      begin

        intPos := SendMessageW(GetDlgItem(hWnd, IDC_VOLUME), TBM_GETPOS, 0, 0);
        BASS_SetConfig(BASS_CONFIG_GVOL_STREAM, intPos * 100);
        BASS_SetConfig(BASS_CONFIG_GVOL_MUSIC, intPos * 100);
        pszText := FormatW(fmtVolume, [intPos]);
        SendMessageW(GetDlgItem(hWnd, IDC_SCROLL), WM_SETTEXT, 0,
          Integer(LPWSTR(pszText)));

      end;

    end;
  end;

  //

  Result := 0;
  
end;

//

function MainDlgProc_WmClose(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  hbim  : HBITMAP;
  himl  : HIMAGELIST;
  plugin: HSFX;
  bRet  : Boolean;
  wc    : TWndClassExW;
begin

  //

  plugin := SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_GETSFXHMODULE, 0, 0);
  if BOOL(plugin) then
  begin

    SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_SETSFXACTIVATE,
      Integer(FALSE), 0);
    BASS_SFX_PluginFree(plugin);

  end;

  SendMessageW(hWnd, WM_COMMAND, MakeLParam(IDC_STOP, BN_CLICKED), 0);

  //

  himl := SendMessageW(GetDlgItem(hWnd, IDC_TIMER), STM_EX_GETIMAGELIST, 0, 0);
  if (himl <> 0) then
    ImageList_Destroy(himl);

  //

  hbim := SendMessageW(GetDlgItem(hWnd, IDC_METER), STM_EX_GETBEATIMAGE, 0, 0);
  if (hbim <> 0) then
    DeleteObject(hbim);

  hbim := SendMessageW(GetDlgItem(hWnd, IDC_VISUAL), STM_EX_GETSFXIMAGE, 0, 0);
  if (hbim <> 0) then
    DeleteObject(hbim);

  //

  RemoveTimerCtrlStaticW(GetDlgItem(hWnd, IDC_TIMER));
  RemoveBeatCtrlStaticW(GetDlgItem(hWnd, IDC_METER));
  RemovePlugCtrlStaticW(GetDlgItem(hWnd, IDC_VISUAL));
  RemoveSpecCtrlStaticW(GetDlgItem(hWnd, IDC_SPECTR));
  RemoveScrollCtrlStaticW(GetDlgItem(hWnd, IDC_SCROLL));

  //

  bRet := GetClassInfoExW(HInstance, pszClass, wc);
  if bRet then
    UnregisterClassW(pszClass, HInstance);

  //

  BASS_SFX_Free;
  BASS_Free;

  //

  EndDialog(hWnd, ID_OK);

  //

  PostQuitMessage(0);

  //

  Result := 0;

end;

//

function MainDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin

  //

  case uMsg of

    //

    WM_INITDIALOG:
    begin
      Result := BOOL(MainDlgProc_WmInitDialog(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_COMMAND:
    begin
      Result := BOOL(MainDlgProc_WmCommand(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_DROPFILES:
    begin
      Result := BOOL(MainDlgProc_WmDropFiles(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_TIMER:
    begin
      Result := BOOL(MainDlgProc_WmTimer(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_HSCROLL:
    begin
      Result := BOOL(MainDlgProc_WmHScroll(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_CLOSE:
    begin
      Result := BOOL(MainDlgProc_WmClose(hWnd, uMsg, wParam, lParam));
    end;

  else
    Result := FALSE;
  end;

end;

end.