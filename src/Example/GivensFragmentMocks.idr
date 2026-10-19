module Example.GivensFragmentMocks

import Shader.Source

%default total

||| Genuine two-dimensional Givens rotation.
|||
||| Cross-repository mathematical/type/lowering index:
||| https://github.com/isomorphisms/Idric/blob/Idri%C3%A7/_/examples/unified-higher-mathematics/ROTATION-COMPLEX-PROJECTIVE-CROSS-REFERENCES.md
|||
||| For input (a,b), choose c=a/r and s=b/r and apply
|||
|||   [ c  s]
|||   [-s  c]
|||
||| so the result is (r,0).  The tiny-radius case uses the identity rotation.
||| The returned vec4 is (rotated_x, rotated_y, norm_before, norm_after), which
||| lets the mock runner check both alignment and norm preservation.
givensReceipt : ShaderFloatTuple 2 -> ShaderFloatTuple 4
givensReceipt ab =
  let a = x ab
      b = y ab
      radius = sqrtF (a * a + b * b)
      safeRadius = maxF radius 0.000000000001
      rawC = a / safeRadius
      rawS = b / safeRadius
      tiny = radius <= 0.000000000001
      c = if tiny then 1.0 else rawC
      s = if tiny then 0.0 else rawS
      rotatedX = c * a + s * b
      rotatedY = (-s) * a + c * b
      normAfter = sqrtF (rotatedX * rotatedX + rotatedY * rotatedY)
   in vec4 rotatedX rotatedY radius normAfter

%export "powervr-ge8322-mock:fragment|ab=in"
powervrGivens : ShaderFloatTuple 2 -> ShaderFloatTuple 4
powervrGivens = givensReceipt

%export "mali-g57-valhall-mock:fragment|ab=in"
maliGivens : ShaderFloatTuple 2 -> ShaderFloatTuple 4
maliGivens = givensReceipt

%export "switch-maxwell-sm53-mock:fragment|ab=in"
switchGivens : ShaderFloatTuple 2 -> ShaderFloatTuple 4
switchGivens = givensReceipt

%export "steam-rdna2-vulkan-mock:fragment|ab=in"
steamGivens : ShaderFloatTuple 2 -> ShaderFloatTuple 4
steamGivens = givensReceipt

%export "webgpu-wgsl-mock:fragment|ab=in"
webgpuGivens : ShaderFloatTuple 2 -> ShaderFloatTuple 4
webgpuGivens = givensReceipt

%export "apple-metal-mock:fragment|ab=in"
appleGivens : ShaderFloatTuple 2 -> ShaderFloatTuple 4
appleGivens = givensReceipt

%export "nvidia-hopper-sm90-mock:fragment|ab=in"
hopperGivens : ShaderFloatTuple 2 -> ShaderFloatTuple 4
hopperGivens = givensReceipt

%export "nvidia-blackwell-sm100-mock:fragment|ab=in"
blackwellGivens : ShaderFloatTuple 2 -> ShaderFloatTuple 4
blackwellGivens = givensReceipt

%export "adreno-tile-mock:fragment|ab=in"
adrenoGivens : ShaderFloatTuple 2 -> ShaderFloatTuple 4
adrenoGivens = givensReceipt

main : IO ()
main = pure ()
