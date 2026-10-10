module Backend.NVIDIA.Specs

%default total

||| Architectural identities, NOT interchangeable product names.
||| sm_100 and sm_103 differ materially (notably FP64 tensor support).
public export
data NVIDIAArch = HopperSM90 | BlackwellSM100 | BlackwellUltraSM103

||| A PTX baseline is forward compatible subject to JIT support; -a is exact
||| architecture only; -f is restricted to a compatible Blackwell family.
public export
data PTXScope = Baseline | FamilySpecific | ArchitectureSpecific

public export
ptxTarget : NVIDIAArch -> PTXScope -> Maybe String
ptxTarget HopperSM90 Baseline = Just "sm_90"
ptxTarget HopperSM90 FamilySpecific = Nothing
ptxTarget HopperSM90 ArchitectureSpecific = Just "sm_90a"
ptxTarget BlackwellSM100 Baseline = Just "sm_100"
ptxTarget BlackwellSM100 FamilySpecific = Just "sm_100f"
ptxTarget BlackwellSM100 ArchitectureSpecific = Just "sm_100a"
ptxTarget BlackwellUltraSM103 Baseline = Just "sm_103"
ptxTarget BlackwellUltraSM103 FamilySpecific = Just "sm_103f"
ptxTarget BlackwellUltraSM103 ArchitectureSpecific = Just "sm_103a"

||| Conservative compatibility table for the three architectures in this file.
||| An sm_90a cubin is NOT forward-compatible with sm_100/sm_103.
||| This only checks architectural eligibility, not PTX ISA/toolkit/driver support.
public export
acceptsPTXTarget : NVIDIAArch -> String -> Bool
acceptsPTXTarget HopperSM90 "sm_90" = True
acceptsPTXTarget HopperSM90 "sm_90a" = True
acceptsPTXTarget BlackwellSM100 "sm_90" = True
acceptsPTXTarget BlackwellSM100 "sm_100" = True
acceptsPTXTarget BlackwellSM100 "sm_100f" = True
acceptsPTXTarget BlackwellSM100 "sm_100a" = True
acceptsPTXTarget BlackwellUltraSM103 "sm_90" = True
acceptsPTXTarget BlackwellUltraSM103 "sm_100" = True
acceptsPTXTarget BlackwellUltraSM103 "sm_100f" = True
acceptsPTXTarget BlackwellUltraSM103 "sm_103" = True
acceptsPTXTarget BlackwellUltraSM103 "sm_103f" = True
acceptsPTXTarget BlackwellUltraSM103 "sm_103a" = True
acceptsPTXTarget _ _ = False

||| Limits are maxima, not a guarantee of occupancy for a particular kernel.
||| All sizes ending in KiB are binary units, unlike product HBM GB and TB/s.
public export
record SMLimits where
  constructor MkSMLimits
  warpThreads : Nat
  threadsPerBlockMax : Nat
  residentThreadsPerSMMax : Nat
  residentWarpsPerSMMax : Nat
  residentBlocksPerSMMax : Nat
  registers32PerSM : Nat
  registers32PerBlock : Nat
  registersPerThreadMax : Nat
  sharedKiBPerSMMax : Nat
  sharedKiBPerBlockMax : Nat
  combinedL1SharedKiB : Nat
  sharedMemoryBanks : Nat
  constantMemoryKiB : Nat
  localMemoryPerThreadKiBMax : Nat
  staticSharedMemoryKiBPortable : Nat

||| NVIDIA CUDA Programming Guide CC 9.0, 10.0, 10.3 tables 30-32;
||| Hopper/Blackwell Tuning Guides. Resource limits coincide for these CCs.
public export
sm90To103Limits : SMLimits
sm90To103Limits = MkSMLimits
  32 1024 2048 64 32 65536 65536 255
  228 227 256 32 64 512 48

||| CUDA grid/block dimensions are distinct from their total thread budget.
||| Constraints of a particular launched kernel may be much stricter.
public export
record GridLimits where
  constructor MkGridLimits
  gridDimensionsMax : Nat
  gridXMax : Nat
  gridYMax : Nat
  gridZMax : Nat
  blockDimensionsMax : Nat
  blockXMax : Nat
  blockYMax : Nat
  blockZMax : Nat
  residentGridsPerDeviceMax : Nat
  portableClusterBlocksMax : Nat

public export
cudaGridLimits : GridLimits
cudaGridLimits = MkGridLimits
  3 2147483647 65535 65535
  3 1024 1024 64 128 8

||| B200's nonportable cluster limit requires opt-in; 8 is portable.
||| Never apply 16 automatically to every SM100/SM103 SKU.
public export
record SMProfile where
  constructor MkSMProfile
  architectureName : String
  computeMajor : Nat
  computeMinor : Nat
  resourceLimits : SMLimits
  sharedCarveoutsKiB : List Nat
  scalarFP32PerScalarFP64Throughput : Nat
  tensorCoreGeneration : Nat

||| Scalar FP64 throughput ratio is *not* a Tensor Core capability.
||| CC 10.3 loses native FP64 Tensor Core acceleration found on CC 10.0.
public export
profile : NVIDIAArch -> SMProfile
profile HopperSM90 = MkSMProfile
  "Hopper" 9 0 sm90To103Limits
  [0, 8, 16, 32, 64, 100, 132, 164, 196, 228] 2 4
profile BlackwellSM100 = MkSMProfile
  "Blackwell" 10 0 sm90To103Limits
  [0, 8, 16, 32, 64, 100, 132, 164, 196, 228] 2 5
profile BlackwellUltraSM103 = MkSMProfile
  "Blackwell Ultra" 10 3 sm90To103Limits
  [0, 8, 16, 32, 64, 100, 132, 164, 196, 228] 64 5

||| These are Tensor Core operand types, not scalar ALU instruction types.
||| Signed FP8 Tensor Core operands are E4M3/E5M2, not E5M3.
||| PTX 9.4 also defines unsigned UE5M3 *scales* for sm_107f+, which are
||| distinct from these three architectures and from signed FP8 operands.
public export
data TensorOperand =
    TensorFP64 | TensorTF32 | TensorBF16 | TensorFP16
  | TensorE4M3 | TensorE5M2 | TensorE2M3 | TensorE3M2
  | TensorE2M1 | TensorINT8 | TensorINT4

public export
tensorOperandName : TensorOperand -> String
tensorOperandName TensorFP64 = "fp64"
tensorOperandName TensorTF32 = "tf32"
tensorOperandName TensorBF16 = "bf16"
tensorOperandName TensorFP16 = "fp16"
tensorOperandName TensorE4M3 = "fp8.e4m3"
tensorOperandName TensorE5M2 = "fp8.e5m2"
tensorOperandName TensorE2M3 = "fp6.e2m3"
tensorOperandName TensorE3M2 = "fp6.e3m2"
tensorOperandName TensorE2M1 = "fp4.e2m1"
tensorOperandName TensorINT8 = "int8"
tensorOperandName TensorINT4 = "int4"

||| CUDA Programming Guide online table 33 (2026-09-10): supported tensor
||| inputs at CC 9.0, 10.0 and 10.3. The current online table omits INT4 for
||| these three CCs, despite a divergent older 13.2 PDF extraction and legacy
||| warp-level PTX .s4/.u4 MMA instructions. Do not infer tcgen05 INT4 support.
public export
tensorOperands : NVIDIAArch -> List TensorOperand
tensorOperands HopperSM90 =
  [TensorFP64, TensorTF32, TensorBF16, TensorFP16, TensorE4M3, TensorE5M2, TensorINT8]
tensorOperands BlackwellSM100 =
  [TensorFP64, TensorTF32, TensorBF16, TensorFP16, TensorE4M3, TensorE5M2,
   TensorE2M3, TensorE3M2, TensorE2M1, TensorINT8]
tensorOperands BlackwellUltraSM103 =
  [TensorTF32, TensorBF16, TensorFP16, TensorE4M3, TensorE5M2,
   TensorE2M3, TensorE2M1, TensorINT8]

||| Feature guards for eventual instruction selection; this module emits no PTX.
public export
data NVIDIAFeature =
    ScalarFP64 | TensorFP64Capability | TensorFP8Capability
  | TensorFP6Capability | TensorFP4Capability
  | NativeSignedE5M3TensorInput | NativeUE5M3Scale
  | WarpShuffle | WarpVote | WarpReduce | AsyncBarrier
  | Atomic128 | ThreadBlockClusters | DistributedSharedMemory
  | TensorMemoryAccelerator | HopperWGMMA | NativeDPX
  | BlackwellTCGen05 | BlackwellTensorMemory | TCGen05LoadReduction

public export
supports : NVIDIAArch -> NVIDIAFeature -> Bool
supports _ ScalarFP64 = True
supports HopperSM90 TensorFP64Capability = True
supports BlackwellSM100 TensorFP64Capability = True
supports BlackwellUltraSM103 TensorFP64Capability = False
supports _ TensorFP8Capability = True
supports HopperSM90 TensorFP6Capability = False
supports _ TensorFP6Capability = True
supports HopperSM90 TensorFP4Capability = False
supports _ TensorFP4Capability = True
supports _ NativeSignedE5M3TensorInput = False
supports _ NativeUE5M3Scale = False
supports _ WarpShuffle = True
supports _ WarpVote = True
supports _ WarpReduce = True
supports _ AsyncBarrier = True
supports _ Atomic128 = True
supports _ ThreadBlockClusters = True
supports _ DistributedSharedMemory = True
supports _ TensorMemoryAccelerator = True
supports HopperSM90 HopperWGMMA = True
supports _ HopperWGMMA = False
||| CUDA Table 29 (2026-09-10) records native DPX on SM90, but multi-
||| instruction implementations for the SM100/SM103 family. Available
||| DPX-like operations are not synonymous with one native DPX instruction.
supports HopperSM90 NativeDPX = True
supports _ NativeDPX = False
supports HopperSM90 BlackwellTCGen05 = False
supports _ BlackwellTCGen05 = True
supports HopperSM90 BlackwellTensorMemory = False
supports _ BlackwellTensorMemory = True
supports BlackwellUltraSM103 TCGen05LoadReduction = True
supports _ TCGen05LoadReduction = False

public export
data NVIDIASku = H100SXM | H200SXM | B200SXM | GB200NVL72 | GB300NVL72

||| GB here means manufacturer-reported decimal gigabytes, TB/s decimal.
||| smCountCeiling is a published SKU count or full-chip upper bound, never
||| an assumed number of enabled SMs on an arbitrary cloud instance.
||| B200's larger cluster size needs an explicit nonportable opt-in.
public export
nonportableClusterBlocks : NVIDIASku -> Maybe Nat
nonportableClusterBlocks B200SXM = Just 16
nonportableClusterBlocks _ = Nothing

public export
record SKUSpec where
  constructor MkSKUSpec
  productName : String
  productArch : NVIDIAArch
  hbmGB : Nat
  peakHBMBandwidthGBs : Nat
  peakNVLinkBidirectionalGBs : Nat
  smCountCeiling : Maybe Nat
  smCountQualification : String

public export
sku : NVIDIASku -> SKUSpec
sku H100SXM = MkSKUSpec
  "H100 SXM" HopperSM90 80 3350 900 (Just 132)
  "H100 SXM implementation, not every H100 variant"
sku H200SXM = MkSKUSpec
  "H200 SXM" HopperSM90 141 4800 900 (Just 132)
  "published H200 SXM configuration; a cloud slice may expose fewer"
sku B200SXM = MkSKUSpec
  "B200 SXM" BlackwellSM100 180 8000 1800 (Just 148)
  "published B200 configuration; installed SKU must be queried"
sku GB200NVL72 = MkSKUSpec
  "GB200 NVL72 GPU" BlackwellSM100 186 8000 1800 Nothing
  "186 GB is 372 GB per two-GPU Grace Blackwell superchip"
sku GB300NVL72 = MkSKUSpec
  "GB300 NVL72 GPU" BlackwellUltraSM103 279 8000 1800 (Just 160)
  "160 SM is the full Blackwell Ultra chip ceiling, not a runtime probe"

public export
specificationReferences : List String
specificationReferences =
  [ "https://developer.nvidia.com/cuda/gpus"
  , "https://docs.nvidia.com/cuda/cuda-programming-guide/05-appendices/compute-capabilities.html"
  , "https://docs.nvidia.com/cuda/parallel-thread-execution/"
  , "https://docs.nvidia.com/cuda/hopper-tuning-guide/"
  , "https://docs.nvidia.com/cuda/blackwell-tuning-guide/"
  , "https://www.nvidia.com/en-us/data-center/gb200-nvl72/"
  , "https://www.nvidia.com/en-us/data-center/gb300-nvl72/"
  , "https://resources.nvidia.com/en-us-gpu-resources/blackwell-ultra-datasheet"
  ]

||| A hardware feature does not imply the baseline PTX target exposes its
||| architecture-specific instruction. Require the right PTX feature set.
||| The eventual PTX emitter must also check its actual toolchain version.
public export
instructionEligible : NVIDIAArch -> PTXScope -> NVIDIAFeature -> Bool
instructionEligible arch scope feature =
  case ptxTarget arch scope of
    Nothing => False
    Just _ =>
      if not (supports arch feature) then False
      else case feature of
        HopperWGMMA => case scope of
          ArchitectureSpecific => True
          _ => False
        BlackwellTCGen05 => case scope of
          Baseline => False
          _ => True
        BlackwellTensorMemory => case scope of
          Baseline => False
          _ => True
        TCGen05LoadReduction => case scope of
          Baseline => False
          _ => True
        _ => True

||| Compiler/ISA minimum is separate from the GPU architecture.
||| Only mark a floor when NVIDIA's ISA explicitly states one.
public export
minimumPTXISA : NVIDIAFeature -> Maybe (Nat, Nat)
minimumPTXISA BlackwellTCGen05 = Just (8, 6)
minimumPTXISA TCGen05LoadReduction = Just (8, 8)
minimumPTXISA NativeUE5M3Scale = Just (9, 4)
minimumPTXISA _ = Nothing
