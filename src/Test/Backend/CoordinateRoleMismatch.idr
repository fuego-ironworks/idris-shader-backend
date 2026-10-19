module Test.Backend.CoordinateRoleMismatch

import Shader.Source
import Shader.Coordinates

%export "glsles:fragment|u_left=uniform,u_right=uniform"
bad_pairing : VectorCoordinates 32 CartesianReal32 ->
              VectorCoordinates 32 CartesianReal32 -> ShaderFloatTuple 4
bad_pairing left right =
  let result = coordinate_pairing left right
   in vec4 result result result 1.0

main : IO ()
main = pure ()
