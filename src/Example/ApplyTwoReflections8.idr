module Example.ApplyTwoReflections8

import Shader.Source
import Shader.Orthogonal8

%default total

||| Three signed Float32 RGBA pages carry eight output coordinates, plus a
||| validity lane on EVERY page. page=0: xyz, page=1: w/xy, page=2: zw/zero.
||| inverse=0 applies H_second o H_first; inverse=1 applies the inverse.
||| All inputs must be finite and caller-validated; nonfinite output is a
||| backend refusal, never a replacement with an application-local kernel.
%export "glsles:fragment|u_first0=uniform,u_first1=uniform,u_second0=uniform,u_second1=uniform,u_x0=uniform,u_x1=uniform,u_page=uniform,u_inverse=uniform"
apply_two_reflections8 :
  ShaderFloatTuple 4 -> ShaderFloatTuple 4 ->
  ShaderFloatTuple 4 -> ShaderFloatTuple 4 ->
  ShaderFloatTuple 4 -> ShaderFloatTuple 4 -> Double -> Double -> ShaderFloatTuple 4
apply_two_reflections8 first_low first_high second_low second_high value_low value_high page inverse =
  let applied_first_low = if inverse > 0.5 then second_low else first_low
      applied_first_high = if inverse > 0.5 then second_high else first_high
      applied_second_low = if inverse > 0.5 then first_low else second_low
      applied_second_high = if inverse > 0.5 then first_high else second_high
      result_low = two_reflections8_chunk applied_first_low applied_first_high
                     applied_second_low applied_second_high value_low value_high 0.0
      result_high = two_reflections8_chunk applied_first_low applied_first_high
                     applied_second_low applied_second_high value_low value_high 1.0
      valid_first = if maximum_component8 first_low first_high > 0.0 then 1.0 else 0.0
      valid_second = if maximum_component8 second_low second_high > 0.0 then 1.0 else 0.0
      valid = valid_first * valid_second
   in if page < 0.5
         then vec4 (x result_low) (y result_low) (z result_low) valid
         else if page < 1.5
                 then vec4 (w result_low) (x result_high) (y result_high) valid
                 else vec4 (z result_high) (w result_high) 0.0 valid

main : IO ()
main = pure ()
