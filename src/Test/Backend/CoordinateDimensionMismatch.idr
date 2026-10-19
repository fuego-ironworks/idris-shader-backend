module Test.Backend.CoordinateDimensionMismatch

import Shader.Source
import Shader.Coordinates

%export "glsles:fragment|u_covector=uniform,u_vector=uniform"
bad_pairing : CovectorCoordinates 4 CartesianReal4 ->
              VectorCoordinates 32 CartesianReal32 -> ShaderFloatTuple 4
bad_pairing covector vector =
  let result = coordinate_pairing covector vector
   in vec4 result result result 1.0

main : IO ()
main = pure ()
