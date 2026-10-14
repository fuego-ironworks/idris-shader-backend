module OutOfBoundsProbe

import Shader.Source

%default covering

sum_from : Double -> SArray 24 (SVec 2) -> Double -> SVec 2 -> SVec 2
sum_from active coefficients index state =
  if index < minF active 24.0
     then
       let coefficient = array_at coefficients (24.0 - index)
           next = vadd state coefficient
        in sum_from active coefficients (index + 1.0) next
     else state

%export "glsles:fragment|u_active=uniform,u_coefficients=uniform"
index_probe : Double -> SArray 24 (SVec 2) -> SVec 4
index_probe active coefficients =
  let result = sum_from active coefficients 0.0 (vec2 0.0 0.0)
   in vec4 (x result) (y result) 0.0 1.0

main : IO ()
main = pure ()

