module Test.Backend.BadDimensions

import Shader.Source

%default total

badDot : Double
badDot = component_product_sum (vec2 1.0 2.0) (vec3 1.0 2.0 3.0)

main : IO ()
main = pure ()

