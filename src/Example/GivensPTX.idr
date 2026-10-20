module Example.GivensPTX

import Shader.Source

%default total

||| Scale before squaring, retaining finite small/large input norms.
stableNorm : Double -> Double -> Double
stableNorm first second =
  let magnitude = maxF (absF first) (absF second)
   in if magnitude > 3.4028234663852886e38 then magnitude
      else let safeMagnitude = if magnitude == 0.0 then 1.0 else magnitude
               horizontal = first / safeMagnitude
               vertical = second / safeMagnitude
            in magnitude * sqrtF (horizontal * horizontal + vertical * vertical)

||| A real plane rotation, returned with norms for independent readback.
||| This finite-input slice avoids transcendental approximations and FMA.
%export "ptx:fragment|ab=in"
givens : ShaderFloatTuple 2 -> ShaderFloatTuple 4
givens ab =
  let first = x ab
      second = y ab
      magnitude = maxF (absF first) (absF second)
      safeMagnitude = if magnitude == 0.0 then 1.0 else magnitude
      horizontal = first / safeMagnitude
      vertical = second / safeMagnitude
      scaledRadius = sqrtF (horizontal * horizontal + vertical * vertical)
      safeRadius = if scaledRadius == 0.0 then 1.0 else scaledRadius
      radius = magnitude * scaledRadius
      cosine = if magnitude == 0.0 then 1.0 else horizontal / safeRadius
      sine = if magnitude == 0.0 then 0.0 else vertical / safeRadius
      aligned = cosine * first + sine * second
      erased = (-sine) * first + cosine * second
      normAfter = stableNorm aligned erased
   in vec4 aligned erased radius normAfter

main : IO ()
main = pure ()
