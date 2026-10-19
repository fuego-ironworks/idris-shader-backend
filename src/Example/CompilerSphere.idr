module Example.CompilerSphere

import Shader.Source

%default total

%noinline
square : Double -> Double
square value = value * value

%noinline
safeNormalize : ShaderFloatTuple n -> ShaderFloatTuple n
safeNormalize value = scale_components (1.0 / maxF 0.00001 (euclidean_component_norm value)) value

%noinline
positive : Double -> Double
positive value = if value > 0.0 then value else 0.0

%export "glsles:fragment|v_uv=in,u_time=uniform"
sphere : ShaderFloatTuple 2 -> Double -> ShaderFloatTuple 4
sphere uv time =
  let px = 1.35 * x uv
      py = 1.35 * y uv
      pz = 0.35 * sinF time
      field = square px + square py + square pz - 1.0
      gradient = vec3 (2.0 * px) (2.0 * py) (2.0 * pz)
      normal = safeNormalize gradient
      light = normalize_components_unchecked (vec3 0.35 0.55 1.0)
      diffuse = positive (component_product_sum normal light)
      band = clampF ((0.075 - absF field) / 0.075) 0.0 1.0
      pulse = 0.88 + 0.12 * sinF time
      shade = pulse * (0.25 + 0.75 * diffuse)
   in vec4 (mixF 0.015 (0.95 * shade) band)
           (mixF 0.025 (0.72 * shade) band)
           (mixF 0.060 (0.18 * shade) band)
           1.0

main : IO ()
main = pure ()
