unit F_MiscUtils;

interface

uses
  Windows, Messages, Bass, F_SysUtils;

function GetPlaybackPosition(stream: HSTREAM): FLOAT;
function GetPlaybackLength(stream: HSTREAM): FLOAT;
function GetFmtPlayTime(time: DWORD): WideString;

implementation

//

function GetPlaybackPosition(stream: HSTREAM): FLOAT;
var
  pos: QWORD;
begin

  pos := BASS_ChannelGetPosition(stream, BASS_POS_BYTE);
  Result := BASS_ChannelBytes2Seconds(stream, pos);

end;

//

function GetPlaybackLength(stream: HSTREAM): FLOAT;
var
  pos: QWORD;
begin

  pos := BASS_ChannelGetLength(stream, BASS_POS_BYTE);
  Result := BASS_ChannelBytes2Seconds(stream, pos);

end;

//

function GetFmtPlayTime(time: DWORD): WideString;
begin

  time := time div 1000; // millisec to mseconds.
  Result := FormatW('%.2d', [time mod 60]);
  time := time div 60; // seconds to minutes.
  Result := FormatW('%.2d:%s', [time mod 60, Result]);
  time := time div 60; // minutes to hours.
  Result := FormatW('%.2d:%s', [time mod 24, Result]);

end;

end.
