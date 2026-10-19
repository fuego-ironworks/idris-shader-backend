module Example.SubtractVector8Norm

import Shader.Source

%default total

||| Subtract two 8D vectors represented as two vec4 chunks and reduce the
||| eight-component difference to its Euclidean norm.
%export "glsles:fragment|u_a0=uniform,u_a1=uniform,u_b0=uniform,u_b1=uniform"
subtract_vector8_norm :
  ShaderFloatTuple 4 -> ShaderFloatTuple 4 -> ShaderFloatTuple 4 -> ShaderFloatTuple 4 -> ShaderFloatTuple 4
subtract_vector8_norm a0 a1 b0 b1 =
  let d0 = subtract_components a0 b0
      d1 = subtract_components a1 b1
      norm_squared = component_product_sum d0 d0 + component_product_sum d1 d1
      result = sqrtF norm_squared
   in vec4 result result result 1.0

main : IO ()
main = pure ()
