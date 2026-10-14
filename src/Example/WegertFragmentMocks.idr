module Example.WegertFragmentMocks

import Shader.Source

%default total

wegertTau : Double
wegertTau = 6.28318530717958647692

wegertLog10 : Double
wegertLog10 = 2.30258509299404568402

wegertPositiveFract : Double -> Double
wegertPositiveFract value = value - floorF value

wegertSrgbComponent : Double -> Double
wegertSrgbComponent linearValue =
  let value = maxF linearValue 0.0
   in if value <= 0.0031308
         then 12.92 * value
         else 1.055 * powF value (1.0 / 2.4) - 0.055

wegertHclToSrgb : Double -> Double -> Double -> ShaderFloatTuple 3
wegertHclToSrgb hueDegrees chroma lightness =
  let hue = hueDegrees * (3.14159265358979323846 / 180.0)
      uStar = chroma * cosF hue
      vStar = chroma * sinF hue
      whiteUPrime = 0.19783982482140777
      whiteVPrime = 0.46833630293240974
      yy = if lightness > 8.0
              then powF ((lightness + 16.0) / 116.0) 3.0
              else lightness / 903.2962962962963
      uPrime = uStar / (13.0 * lightness) + whiteUPrime
      vPrime = vStar / (13.0 * lightness) + whiteVPrime
      xx = (9.0 * yy * uPrime) / (4.0 * vPrime)
      zz = yy * (12.0 - 3.0 * uPrime - 20.0 * vPrime) / (4.0 * vPrime)
      linearR = 3.2404542 * xx - 1.5371385 * yy - 0.4985314 * zz
      linearG = -0.9692660 * xx + 1.8760108 * yy + 0.0415560 * zz
      linearB = 0.0556434 * xx - 0.2040259 * yy + 1.0572252 * zz
      red = clampF (wegertSrgbComponent linearR) 0.0 1.0
      green = clampF (wegertSrgbComponent linearG) 0.0 1.0
      blue = clampF (wegertSrgbComponent linearB) 0.0 1.0
   in vec3 red green blue

wegertColorFromPhaseLogModulus : Double -> Double -> ShaderFloatTuple 3
wegertColorFromPhaseLogModulus phase logModulus =
  let hueDegrees = 360.0 * wegertPositiveFract (phase / wegertTau)
      logModulusBand = wegertPositiveFract (logModulus / wegertLog10)
      lightness = 66.0
                + 4.0 * logModulusBand
                + 3.0 * wegertPositiveFract (hueDegrees / 100.0)
   in wegertHclToSrgb hueDegrees 45.0 lightness

wegertColorComplex : ShaderFloatTuple 2 -> ShaderFloatTuple 4
wegertColorComplex value =
  let phase = atan2F (y value) (x value)
      logModulus = logF (maxF (euclidean_component_norm value) 0.000000000001)
      rgb = wegertColorFromPhaseLogModulus phase logModulus
   in vec4 (x rgb) (y rgb) (z rgb) 1.0

%export "powervr-ge8322-mock:fragment|value=in"
powervrWegert : ShaderFloatTuple 2 -> ShaderFloatTuple 4
powervrWegert = wegertColorComplex

%export "mali-g57-valhall-mock:fragment|value=in"
maliWegert : ShaderFloatTuple 2 -> ShaderFloatTuple 4
maliWegert = wegertColorComplex

%export "switch-maxwell-sm53-mock:fragment|value=in"
switchWegert : ShaderFloatTuple 2 -> ShaderFloatTuple 4
switchWegert = wegertColorComplex

%export "steam-rdna2-vulkan-mock:fragment|value=in"
steamWegert : ShaderFloatTuple 2 -> ShaderFloatTuple 4
steamWegert = wegertColorComplex

%export "webgpu-wgsl-mock:fragment|value=in"
webgpuWegert : ShaderFloatTuple 2 -> ShaderFloatTuple 4
webgpuWegert = wegertColorComplex

%export "apple-metal-mock:fragment|value=in"
appleWegert : ShaderFloatTuple 2 -> ShaderFloatTuple 4
appleWegert = wegertColorComplex

%export "nvidia-hopper-sm90-mock:fragment|value=in"
hopperWegert : ShaderFloatTuple 2 -> ShaderFloatTuple 4
hopperWegert = wegertColorComplex

%export "nvidia-blackwell-sm100-mock:fragment|value=in"
blackwellWegert : ShaderFloatTuple 2 -> ShaderFloatTuple 4
blackwellWegert = wegertColorComplex

%export "adreno-tile-mock:fragment|value=in"
adrenoWegert : ShaderFloatTuple 2 -> ShaderFloatTuple 4
adrenoWegert = wegertColorComplex

main : IO ()
main = pure ()
