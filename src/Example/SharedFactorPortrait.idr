module Example.SharedFactorPortrait

import Shader.PhasePortrait
import Shader.Source

%default total

-- The backend proves the finite 64-slot bound of the covering accumulator.
covering
%export "glsles:fragment|v_ndc=in,u_center=uniform,u_half_height=uniform,u_aspect=uniform,u_zero_count=uniform,u_pole_count=uniform,u_zeros=uniform,u_poles=uniform"
shared_factor_portrait : ShaderFloatTuple 2 -> ShaderFloatTuple 2 -> Double -> Double -> Int -> Int -> SArray 64 (ShaderFloatTuple 2) -> SArray 64 (ShaderFloatTuple 2) -> ShaderFloatTuple 4
shared_factor_portrait ndc center half_height aspect zero_count pole_count zeros poles =
  let point = add_components center (vec2 (x ndc * half_height * aspect)
                                (y ndc * half_height))
      -- This external module deliberately exercises the exported split API.
      -- Holomorphic adds its entire-function measure before this same colour
      -- conversion; the rational-only path must keep exactly the same palette.
      measure = rational_measure point
                                 (int_to_double zero_count) zeros
                                 (int_to_double pole_count) poles
      color = wegert_rgb_from_measure measure
   in vec4 (x color) (y color) (z color) 1.0

main : IO ()
main = pure ()
