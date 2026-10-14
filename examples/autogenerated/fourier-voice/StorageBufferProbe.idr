module StorageBufferProbe

import Shader.Source

%default total

%export "glsles:fragment|u_coefficients=ssbo"
storage_buffer_probe : SArray 24 (SVec 2) -> SVec 4
storage_buffer_probe coefficients =
  let first_coefficient = array_at coefficients 1.0
   in vec4 (x first_coefficient) (y first_coefficient) 0.0 1.0

main : IO ()
main = pure ()

