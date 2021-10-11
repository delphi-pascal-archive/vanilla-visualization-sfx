unit F_Math;

interface

uses
  Windows;

function Min(A, B: Integer): Integer;

implementation

function Min(A, B: Integer): Integer;
begin
  if (A < B) then
    Result := A
  else
    Result := B;
end;

end.