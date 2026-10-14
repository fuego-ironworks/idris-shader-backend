module FourierUnrolled

import Shader.Source
import FourierMath

%default covering

export
polynomial_unrolled : SVec 2 -> SArray 24 (SVec 2) -> SVec 2
polynomial_unrolled point coefficients =
  let accumulated_23 : SVec 2 = array_at coefficients 23.0
      accumulated_22 : SVec 2 = horner_step point accumulated_23 coefficients 22.0
      accumulated_21 : SVec 2 = horner_step point accumulated_22 coefficients 21.0
      accumulated_20 : SVec 2 = horner_step point accumulated_21 coefficients 20.0
      accumulated_19 : SVec 2 = horner_step point accumulated_20 coefficients 19.0
      accumulated_18 : SVec 2 = horner_step point accumulated_19 coefficients 18.0
      accumulated_17 : SVec 2 = horner_step point accumulated_18 coefficients 17.0
      accumulated_16 : SVec 2 = horner_step point accumulated_17 coefficients 16.0
      accumulated_15 : SVec 2 = horner_step point accumulated_16 coefficients 15.0
      accumulated_14 : SVec 2 = horner_step point accumulated_15 coefficients 14.0
      accumulated_13 : SVec 2 = horner_step point accumulated_14 coefficients 13.0
      accumulated_12 : SVec 2 = horner_step point accumulated_13 coefficients 12.0
      accumulated_11 : SVec 2 = horner_step point accumulated_12 coefficients 11.0
      accumulated_10 : SVec 2 = horner_step point accumulated_11 coefficients 10.0
      accumulated_9 : SVec 2 = horner_step point accumulated_10 coefficients 9.0
      accumulated_8 : SVec 2 = horner_step point accumulated_9 coefficients 8.0
      accumulated_7 : SVec 2 = horner_step point accumulated_8 coefficients 7.0
      accumulated_6 : SVec 2 = horner_step point accumulated_7 coefficients 6.0
      accumulated_5 : SVec 2 = horner_step point accumulated_6 coefficients 5.0
      accumulated_4 : SVec 2 = horner_step point accumulated_5 coefficients 4.0
      accumulated_3 : SVec 2 = horner_step point accumulated_4 coefficients 3.0
      accumulated_2 : SVec 2 = horner_step point accumulated_3 coefficients 2.0
      accumulated_1 : SVec 2 = horner_step point accumulated_2 coefficients 1.0
   in complex_multiply accumulated_1 point


