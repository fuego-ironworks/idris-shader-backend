module FourierMath

import Shader.Source

%default covering

complex_multiply : SVec 2 -> SVec 2 -> SVec 2
complex_multiply left right =
  vec2 (x left * x right - y left * y right)
       (x left * y right + y left * x right)

polynomial_from :
  SVec 2 -> SArray 24 (SVec 2) -> Double -> Double -> SVec 2 -> SVec 2
polynomial_from point coefficients active index state =
  if index < minF active 24.0
     then
       let coefficient_index = 23.0 - index
           coefficient = if coefficient_index == 0.0
                            then vec2 0.0 0.0
                            else array_at coefficients coefficient_index
           next = vadd (complex_multiply state point) coefficient
        in polynomial_from point coefficients active (index + 1.0) next
     else state

public export
polynomial_loop : SVec 2 -> SArray 24 (SVec 2) -> SVec 2
polynomial_loop point coefficients =
  polynomial_from point coefficients 24.0 0.0 (vec2 0.0 0.0)

public export
polynomial_unrolled : SVec 2 -> SArray 24 (SVec 2) -> SVec 2
polynomial_unrolled point coefficients =
  let accumulated_23 = array_at coefficients 23.0
      accumulated_22 = vadd (complex_multiply accumulated_23 point) (array_at coefficients 22.0)
      accumulated_21 = vadd (complex_multiply accumulated_22 point) (array_at coefficients 21.0)
      accumulated_20 = vadd (complex_multiply accumulated_21 point) (array_at coefficients 20.0)
      accumulated_19 = vadd (complex_multiply accumulated_20 point) (array_at coefficients 19.0)
      accumulated_18 = vadd (complex_multiply accumulated_19 point) (array_at coefficients 18.0)
      accumulated_17 = vadd (complex_multiply accumulated_18 point) (array_at coefficients 17.0)
      accumulated_16 = vadd (complex_multiply accumulated_17 point) (array_at coefficients 16.0)
      accumulated_15 = vadd (complex_multiply accumulated_16 point) (array_at coefficients 15.0)
      accumulated_14 = vadd (complex_multiply accumulated_15 point) (array_at coefficients 14.0)
      accumulated_13 = vadd (complex_multiply accumulated_14 point) (array_at coefficients 13.0)
      accumulated_12 = vadd (complex_multiply accumulated_13 point) (array_at coefficients 12.0)
      accumulated_11 = vadd (complex_multiply accumulated_12 point) (array_at coefficients 11.0)
      accumulated_10 = vadd (complex_multiply accumulated_11 point) (array_at coefficients 10.0)
      accumulated_9 = vadd (complex_multiply accumulated_10 point) (array_at coefficients 9.0)
      accumulated_8 = vadd (complex_multiply accumulated_9 point) (array_at coefficients 8.0)
      accumulated_7 = vadd (complex_multiply accumulated_8 point) (array_at coefficients 7.0)
      accumulated_6 = vadd (complex_multiply accumulated_7 point) (array_at coefficients 6.0)
      accumulated_5 = vadd (complex_multiply accumulated_6 point) (array_at coefficients 5.0)
      accumulated_4 = vadd (complex_multiply accumulated_5 point) (array_at coefficients 4.0)
      accumulated_3 = vadd (complex_multiply accumulated_4 point) (array_at coefficients 3.0)
      accumulated_2 = vadd (complex_multiply accumulated_3 point) (array_at coefficients 2.0)
      accumulated_1 = vadd (complex_multiply accumulated_2 point) (array_at coefficients 1.0)
   in complex_multiply accumulated_1 point

srgb_component : Double -> Double
srgb_component linear_value =
  let value = maxF linear_value 0.0
   in if value <= 0.0031308
         then 12.92 * value
         else 1.055 * powF value (1.0 / 2.4) - 0.055

hcl_to_srgb : Double -> Double -> Double -> SVec 3
hcl_to_srgb hue_degrees chroma lightness =
  let hue = hue_degrees * 0.017453292519943295769236907684886
      u_star = chroma * cosF hue
      v_star = chroma * sinF hue
      white_u_prime = 0.19783982482140777
      white_v_prime = 0.46833630293240974
      cie_y = if lightness > 8.0
                 then powF ((lightness + 16.0) / 116.0) 3.0
                 else lightness / 903.2962962962963
      u_prime = u_star / (13.0 * lightness) + white_u_prime
      v_prime = v_star / (13.0 * lightness) + white_v_prime
      cie_x = (9.0 * cie_y * u_prime) / (4.0 * v_prime)
      cie_z = cie_y * (12.0 - 3.0 * u_prime - 20.0 * v_prime) / (4.0 * v_prime)
      linear_red = 3.2404542 * cie_x - 1.5371385 * cie_y - 0.4985314 * cie_z
      linear_green = -0.9692660 * cie_x + 1.8760108 * cie_y + 0.0415560 * cie_z
      linear_blue = 0.0556434 * cie_x - 0.2040259 * cie_y + 1.0572252 * cie_z
   in vec3 (clampF (srgb_component linear_red) 0.0 1.0)
           (clampF (srgb_component linear_green) 0.0 1.0)
           (clampF (srgb_component linear_blue) 0.0 1.0)

public export
voice_color : SVec 2 -> SVec 3
voice_color value =
  let phase = if x value == 0.0
                 then if y value == 0.0 then 0.0 else atan2F (y value) (x value)
                 else atan2F (y value) (x value)
      magnitude = maxF (length value) 0.000000000001
      hue_degrees = 360.0 * fractF (phase / 6.28318530717958647692)
      modulus_band = fractF (logF magnitude / 2.30258509299404568402)
      lightness = 66.0 + 4.0 * modulus_band + 3.0 * fractF (hue_degrees / 100.0)
   in hcl_to_srgb hue_degrees 45.0 lightness

public export
point_from_uv : SVec 2 -> SVec 2
point_from_uv uv =
  vec2 (mixF (-0.44) 0.44 (x uv)) (mixF (-0.88) 0.88 (y uv))

public export
rgba : SVec 3 -> SVec 4
rgba color = vec4 (x color) (y color) (z color) 1.0

