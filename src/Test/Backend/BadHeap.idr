module Test.Backend.BadHeap

import Shader.Source

%default total

%noinline
headOrZero : List Double -> Double
headOrZero [] = 0.0
headOrZero (value :: _) = value

%export "glsles:fragment|v_uv=in"
badHeap : ShaderFloatTuple 2 -> ShaderFloatTuple 4
badHeap uv =
  let value = headOrZero [x uv]
   in vec4 value value value 1.0

main : IO ()
main = pure ()

