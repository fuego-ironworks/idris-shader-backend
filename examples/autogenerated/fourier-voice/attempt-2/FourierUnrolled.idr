module FourierUnrolled

import Shader.Source
import FourierMath

%default covering

export
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


