unit F_SysUtils;

interface

uses
  Windows;

function FormatW(pszText: WideString; const Params: Array of const): WideString;
function ExtractFilePathW(pszText: WideString): WideString;
function ExtractFileNameW(pszText: WideString): WideString;
function WideStringToAnsi(pszText: WideString; CodePage: WORD): AnsiString;
function AnsiStringToWide(pszText: AnsiString; CodePage: WORD): WideString;
function FileExistsW(pszText: WideString): Boolean;
function FormatTimeW(dwTime: DWORD): WideString;

implementation

//

function FormatW(pszText: WideString; const Params: Array of const): WideString;
var
  lpChar: Array [0..1023] of WideChar;
  lpWord: Array [0..15] of LongWord;
  nIndex: Integer;
begin
  for nIndex := High(Params) downto 0 do
    lpWord[nIndex] := Params[nIndex].VInteger;
  wvsprintfW(@lpChar, LPWSTR(pszText), @lpWord);
  Result := lpChar;
end;

//

function ExtractFilePathW(pszText: WideString): WideString;
var
  L: Integer;
begin
  Result := '';
  L := Length(pszText);
  while (L > 0) do
  begin
    if (pszText[L] = ':') or (pszText[L] = '\') then
    begin
      Result := Copy(pszText, 1, L);
      Break;
    end;
    Dec(L);
  end;
end;

//

function ExtractFileNameW(pszText: WideString): WideString;
var
  L: Integer;
begin
  L := Length(pszText);
  while(L > 0) do
  begin
    if (pszText[L] = '\') then
      Break;
    Dec(L);
  end;
  Result := Copy(pszText, L + 1, Length(pszText));
end;

//

function WideStringToAnsi(pszText: WideString; CodePage: WORD): AnsiString;
var
  dwBytes: Integer;
  dwFlags: DWORD;
begin
  if (pszText <> '') then
  begin
    dwFlags := WC_COMPOSITECHECK or WC_DISCARDNS or WC_SEPCHARS or WC_DEFAULTCHAR;
    dwBytes := WideCharToMultiByte(CodePage, dwFlags, LPWSTR(pszText), -1, nil,
      0, nil, nil);
    SetLength(Result, dwBytes - 1);
    if (dwBytes > 1) then
      WideCharToMultiByte(CodePage, dwFlags, LPWSTR(pszText), -1, LPTSTR(Result),
        dwBytes - 1, nil, nil);
  end
  else
    Result := '';
end;

//

function AnsiStringToWide(pszText: AnsiString; CodePage: WORD): WideString;
var
  dwBytes: Integer;
begin
  if (pszText <> '') then
  begin
    dwBytes := MultiByteToWideChar(CodePage, MB_PRECOMPOSED, LPTSTR(pszText), -1,
      nil, 0);
    SetLength(Result, dwBytes - 1);
    if (dwBytes > 1) then
      MultiByteToWideChar(CodePage, MB_PRECOMPOSED, LPTSTR(pszText), -1,
        LPWSTR(Result), dwBytes - 1);
  end
  else
    Result := '';
end;

//

function FileExistsW(pszText: WideString): Boolean;
var
  att: DWORD;
begin
  att := GetFileAttributesW(LPWSTR(pszText));
  Result := (att <> $FFFFFFFF) and (att and FILE_ATTRIBUTE_DIRECTORY = 0);
end;

//

function FormatTimeW(dwTime: DWORD): WideString;
begin
  dwTime := dwTime div 1000; // millisec to mseconds.
  Result := FormatW('%.2d', [dwTime mod 60]);
  dwTime := dwTime div 60; // seconds to minutes.
  Result := FormatW('%.2d:%s', [dwTime mod 60, Result]);
  dwTime := dwTime div 60; // minutes to hours.
  Result := FormatW('%.2d:%s', [dwTime mod 24, Result]);
end;

end.
