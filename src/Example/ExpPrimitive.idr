module Example.ExpPrimitive

import Shader.Source

%default total

||| This tests the *actual compiler primitive*, rather than replacing exp(x)
||| with a truncated polynomial or pow(constant, x).
%export "glsles:fragment|v_uv=in,u_gain=uniform"
exp_primitive : SVec 2 -> Double -> SVec 4
exp_primitive uv gain =
  let value = expF (x uv * gain)
   in vec4 value value value 1.0

main : IO ()
main = pure ()
