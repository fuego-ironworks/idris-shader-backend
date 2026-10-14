module FourierLoop

import Shader.Source
import FourierMath

%default covering

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

export
polynomial_loop : SVec 2 -> SArray 24 (SVec 2) -> SVec 2
polynomial_loop point coefficients =
  polynomial_from point coefficients 24.0 0.0 (vec2 0.0 0.0)


