module Example.CoordinatePairing4Grayscale

import Shader.Source
import Shader.Coordinates

%default total

%export "glsles:fragment|u_covector_coordinates=uniform,u_vector_coordinates=uniform"
coordinate_pairing4_grayscale :
  CovectorCoordinates 4 CartesianReal4 ->
  VectorCoordinates 4 CartesianReal4 -> ShaderFloatTuple 4
coordinate_pairing4_grayscale covector_coordinates vector_coordinates =
  let paired_value = coordinate_pairing covector_coordinates vector_coordinates
   in vec4 paired_value paired_value paired_value 1.0

main : IO ()
main = pure ()
