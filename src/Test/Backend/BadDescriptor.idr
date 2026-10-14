module Test.Backend.BadDescriptor

import Shader.Source

%default total

%export "glsles:fragment|v_uv=in"
badDescriptor : ShaderFloatTuple 2 -> Double -> ShaderFloatTuple 4
badDescriptor uv time = vec4 (x uv) (y uv) time 1.0

main : IO ()
main = pure ()

