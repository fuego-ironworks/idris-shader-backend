module Example.PixelPTX

import Shader.Source

%default total

||| Independently testable numerical/pixel kernel. Input is a per-sample
||| coordinate; output contains an actual polynomial plus RGB-like channels.
%export "ptx:fragment|coordinate=in,gain=uniform"
pixel : SVec 2 -> Double -> SVec 4
pixel coordinate gain =
  let horizontal = x coordinate
      vertical = y coordinate
      realPart = horizontal * horizontal - vertical * vertical
      imaginaryPart = 2.0 * horizontal * vertical
   in vec4 (gain * realPart) (gain * imaginaryPart)
           (horizontal * horizontal + vertical * vertical) 1.0

main : IO ()
main = pure ()
