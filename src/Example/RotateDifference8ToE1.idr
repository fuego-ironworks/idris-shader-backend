module Example.RotateDifference8ToE1

import Shader.Source

%default total

||| Subtract two 8D vectors (stored as two vec4 chunks), then map the
||| difference to ||a-b|| e1 with an orientation-preserving orthogonal map.
|||
||| Cross-repository mathematical/type/lowering index:
||| https://github.com/isomorphisms/Idric/blob/Idri%C3%A7/_/examples/unified-higher-mathematics/ROTATION-COMPLEX-PROJECTIVE-CROSS-REFERENCES.md
|||
||| For a non-degenerate difference, the first Householder reflection sends
||| d to ||d||e1.  A fixed reflection that flips e2 leaves ||d||e1 unchanged;
||| composing the two reflections has determinant +1, so the composition is a
||| proper high-dimensional rotation.  If d is already on +e1, use identity.
%export "glsles:fragment|u_a0=uniform,u_a1=uniform,u_b0=uniform,u_b1=uniform"
rotate_difference8_to_e1 :
  ShaderFloatTuple 4 -> ShaderFloatTuple 4 -> ShaderFloatTuple 4 -> ShaderFloatTuple 4 -> ShaderFloatTuple 4
rotate_difference8_to_e1 a0 a1 b0 b1 =
  let d0 = subtract_components a0 b0
      d1 = subtract_components a1 b1
      original_norm = sqrtF (component_product_sum d0 d0 + component_product_sum d1 d1)
      target0 = vec4 original_norm 0.0 0.0 0.0
      u0_raw = subtract_components d0 target0
      u1_raw = d1
      u_norm = sqrtF (component_product_sum u0_raw u0_raw + component_product_sum u1_raw u1_raw)
      inverse_u_norm = 1.0 / maxF 0.000001 u_norm
      u0 = scale_components inverse_u_norm u0_raw
      u1 = scale_components inverse_u_norm u1_raw
      projection = component_product_sum d0 u0 + component_product_sum d1 u1
      twice_projection = 2.0 * projection
      reflected0 = subtract_components d0 (scale_components twice_projection u0)
      reflected1 = subtract_components d1 (scale_components twice_projection u1)
      rotated0 =
        if u_norm > 0.000001
           then vec4 (x reflected0) (0.0 - y reflected0) (z reflected0) (w reflected0)
           else reflected0
      tail0 = vec3 (y rotated0) (z rotated0) (w rotated0)
      residual = sqrtF (component_product_sum tail0 tail0 + component_product_sum reflected1 reflected1)
      axis_ratio = x rotated0 / maxF 0.000001 original_norm
   in vec4 axis_ratio residual residual 1.0

main : IO ()
main = pure ()
