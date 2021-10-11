unit F_Graphics;

interface

uses
  Windows;
  
procedure DrawGradRect(hdcIn: HDC; rcItem: TRect; cLeft, cRight: TColorRef; GradFreq: Integer);

implementation

procedure DrawGradRect(hdcIn: HDC; rcItem: TRect; cLeft, cRight: TColorRef; GradFreq: Integer);
var
  stepR: TRect;     // rectangle for color's band.
  color: TColorRef; // color for the bands.
  fStep: Double;    // width of color's band.
  iBand: Integer;
  Brush: HBRUSH;
begin

  // width of color's band.

  fStep := (rcItem.right - rcItem.left) / GradFreq;

  for iBand := 0 to GradFreq do
  begin

    // set current band.

    SetRect(
      stepR,
      rcItem.Left + Round(iBand * fStep),
      rcItem.Top,
      rcItem.Left + Round((iBand + 1 ) * fStep),
      rcItem.Bottom
    );

    // set current color.

    color := RGB(
      Round((GetRValue(cRight) - GetRValue(cLeft)) * (iBand) / (GradFreq) + GetRValue(cLeft)),
      Round((GetGValue(cRight) - GetGValue(cLeft)) * (iBand) / (GradFreq) + GetGValue(cLeft)),
      Round((GetBValue(cRight) - GetBValue(cLeft)) * (iBand) / (GradFreq) + GetBValue(cLeft))
    );

    // fill current band.

    Brush := CreateSolidBrush(color);
    FillRect(hdcIn, stepR, Brush);
    DeleteObject(Brush);

  end;

end;

end.
