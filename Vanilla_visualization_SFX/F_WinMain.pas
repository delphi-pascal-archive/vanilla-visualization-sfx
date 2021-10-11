unit F_WinMain;

interface

uses
  Windows, Messages, CommCtrl, F_CommCtrl, F_Resources, D_MainProc;

function WinMain(HInstance: HINST; hPrevInstance: HINST; lpCmdLine: LPTSTR; nCmdShow: Integer): Integer; stdcall;

implementation

//

function WinMain(HInstance: HINST; hPrevInstance: HINST; lpCmdLine: LPTSTR; nCmdShow: Integer): Integer; stdcall;
var
  iccex: TInitCommonControlsEx;
begin

  //

  iccex.dwSize := SizeOf(TInitCommonControlsEx);
  iccex.dwICC  := ICC_STANDARD_CLASSES or ICC_WIN95_CLASSES or ICC_BAR_CLASSES;
  InitCommonControlsEx(iccex);

  //

  DialogBoxParamW(HInstance, MAKEINTRESOURCEW(IDD_DIALOG_MAIN), 0, @MainDlgProc,
    0);

  //

  Result := 0;

end;

end.