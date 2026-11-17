module Shader.Orthogonal8

import Shader.Source

%default total

||| Numerical lowering of the Householder operation used by
||| Example.RotateDifference8ToE1. Compose two reflections for an SO(8) map,
||| matching the semantic two_reflections operation in Idric. These tuples
||| are transport, not proof of a common Euclidean space: callers must check
||| representation, basis, metric and the covector role of both normals.
||| No material/photo labels or classifier fitting belong in this module.
public export
maximum_component8 : ShaderFloatTuple 4 -> ShaderFloatTuple 4 -> Double
maximum_component8 low high =
  maxF (maxF (absF (x low)) (absF (y low)))
       (maxF (maxF (absF (z low)) (absF (w low)))
             (maxF (maxF (absF (x high)) (absF (y high)))
                   (maxF (absF (z high)) (absF (w high)))))

||| Divide components individually: forming 1/scale first can overflow for a
||| small but valid Float32 normal. Nonzero normals are rescaled to max=1.
public export
divide_components4 : ShaderFloatTuple 4 -> Double -> ShaderFloatTuple 4
divide_components4 value divisor =
  vec4 (x value / divisor) (y value / divisor)
       (z value / divisor) (w value / divisor)

||| H_n(v) = v - 2*n*(n.v)/(n.n), evaluated with a safely rescaled normal.
||| Zero normals produce an internal identity only to keep arithmetic defined;
||| the exported transport marks them invalid and consumers MUST reject them.
public export
reflect8_chunk :
  ShaderFloatTuple 4 -> ShaderFloatTuple 4 ->
  ShaderFloatTuple 4 -> ShaderFloatTuple 4 -> Double -> ShaderFloatTuple 4
reflect8_chunk normal_low normal_high value_low value_high chunk =
  let normal_scale = maximum_component8 normal_low normal_high
      safe_scale = if normal_scale > 0.0 then normal_scale else 1.0
      scaled_low = divide_components4 normal_low safe_scale
      scaled_high = divide_components4 normal_high safe_scale
      squared_norm = component_product_sum scaled_low scaled_low +
                     component_product_sum scaled_high scaled_high
      safe_norm = if squared_norm > 0.0 then squared_norm else 1.0
      projection = component_product_sum scaled_low value_low +
                   component_product_sum scaled_high value_high
      factor = 2.0 * (projection / safe_norm)
      selected_value = if chunk < 0.5 then value_low else value_high
      selected_normal = if chunk < 0.5 then scaled_low else scaled_high
   in subtract_components selected_value (scale_components factor selected_normal)

||| Apply first reflection, then second. Reversing the normal order is the
||| inverse; equal nonzero normals give identity. Signs/scales of either
||| normal do not change the map. The affine offsets of classifier planes
||| are intentionally absent: this is a linear rotation, not affine reflection.
public export
two_reflections8_chunk :
  ShaderFloatTuple 4 -> ShaderFloatTuple 4 ->
  ShaderFloatTuple 4 -> ShaderFloatTuple 4 ->
  ShaderFloatTuple 4 -> ShaderFloatTuple 4 -> Double -> ShaderFloatTuple 4
two_reflections8_chunk first_low first_high second_low second_high value_low value_high chunk =
  let intermediate_low = reflect8_chunk first_low first_high value_low value_high 0.0
      intermediate_high = reflect8_chunk first_low first_high value_low value_high 1.0
   in reflect8_chunk second_low second_high intermediate_low intermediate_high chunk
