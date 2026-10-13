module Test.AMD.UnsupportedLiteral

import Shader.Source

%default total

%export "amdgcn:fragment|coordinate=in"
unsupportedLiteral : SVec 2 -> SVec 4
unsupportedLiteral coordinate = vec4 (0.1 * x coordinate) 0.0 0.0 1.0

main : IO ()
main = pure ()
