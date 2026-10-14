module Example.CoordinatePairing32Grayscale

import Shader.Source
import Shader.Coordinates

%default total

||| Pair two coherent 32D coordinate packets, then display the numerical scalar.
||| The scalar pairing and the RGBA display encoding are distinct operations.
%export "glsles:fragment|u_covector_coordinates=uniform,u_vector_coordinates=uniform"
coordinate_pairing32_grayscale :
  CovectorCoordinates 32 CartesianReal32 ->
  VectorCoordinates 32 CartesianReal32 -> ShaderFloatTuple 4
coordinate_pairing32_grayscale covector_coordinates vector_coordinates =
  let paired_value = coordinate_pairing covector_coordinates vector_coordinates
   in vec4 paired_value paired_value paired_value 1.0

main : IO ()
main = pure ()
