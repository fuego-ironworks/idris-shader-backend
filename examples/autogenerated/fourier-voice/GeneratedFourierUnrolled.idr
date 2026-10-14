module GeneratedFourierUnrolled

import Shader.Source
import FourierMath
import FourierUnrolled

%default covering

%export "glsles:fragment|v_uv=in,u_coefficients=uniform"
fourier_voice : SVec 2 -> SArray 24 (SVec 2) -> SVec 4
fourier_voice uv coefficients =
  rgba (voice_color (polynomial_unrolled (point_from_uv uv) coefficients))

main : IO ()
main = pure ()

