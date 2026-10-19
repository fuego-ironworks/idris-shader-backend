module Test.Backend.SpoofCoordinatePairing

import Shader.Source
import Shader.Coordinates

%extern
coordinate_pairing : CovectorCoordinates 32 CartesianReal32 ->
                     VectorCoordinates 32 CartesianReal32 -> Double

%export "glsles:fragment|u_covector=uniform,u_vector=uniform"
bad_intrinsic : CovectorCoordinates 32 CartesianReal32 ->
                VectorCoordinates 32 CartesianReal32 -> ShaderFloatTuple 4
bad_intrinsic covector vector =
  let result = Test.Backend.SpoofCoordinatePairing.coordinate_pairing covector vector
   in vec4 result result result 1.0

main : IO ()
main = pure ()
