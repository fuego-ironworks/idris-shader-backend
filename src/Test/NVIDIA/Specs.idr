module Test.NVIDIA.Specs

import Backend.NVIDIA.Specs

%default total
%unbound_implicits off

||| These are compile-time checks of exact architecture, instruction and SKU
||| distinctions. They are not compiler-output or physical-GPU acceptance.
public export
hopperComputeMajor : computeMajor (profile HopperSM90) = 9
hopperComputeMajor = Refl

public export
h200UsesHopper : productArch (sku H200SXM) = HopperSM90
h200UsesHopper = Refl

public export
b200UsesSM100 : computeMinor (profile (productArch (sku B200SXM))) = 0
b200UsesSM100 = Refl

public export
gb300UsesSM103 : computeMinor (profile (productArch (sku GB300NVL72))) = 3
gb300UsesSM103 = Refl

public export
gb300NoTensorFP64 : supports BlackwellUltraSM103 TensorFP64Capability = False
gb300NoTensorFP64 = Refl

public export
gb200HasTensorFP64 : supports BlackwellSM100 TensorFP64Capability = True
gb200HasTensorFP64 = Refl

public export
hopperHasNoFP4Tensor : supports HopperSM90 TensorFP4Capability = False
hopperHasNoFP4Tensor = Refl

public export
gb300HasFP4Tensor : supports BlackwellUltraSM103 TensorFP4Capability = True
gb300HasFP4Tensor = Refl

public export
noSignedE5M3TensorInput : supports BlackwellUltraSM103 NativeSignedE5M3TensorInput = False
noSignedE5M3TensorInput = Refl

public export
noUE5M3ScaleOnGB300 : supports BlackwellUltraSM103 NativeUE5M3Scale = False
noUE5M3ScaleOnGB300 = Refl

public export
ue5m3ScaleMinPTX : minimumPTXISA NativeUE5M3Scale = Just (9, 4)
ue5m3ScaleMinPTX = Refl

public export
h100WgmmaNeedsExact : instructionEligible HopperSM90 Baseline HopperWGMMA = False
h100WgmmaNeedsExact = Refl

public export
h100WgmmaExact : instructionEligible HopperSM90 ArchitectureSpecific HopperWGMMA = True
h100WgmmaExact = Refl

public export
b200Tcgen05NeedsFamily : instructionEligible BlackwellSM100 Baseline BlackwellTCGen05 = False
b200Tcgen05NeedsFamily = Refl

public export
b200Tcgen05Family : instructionEligible BlackwellSM100 FamilySpecific BlackwellTCGen05 = True
b200Tcgen05Family = Refl

public export
gb300LdRed : instructionEligible BlackwellUltraSM103 FamilySpecific TCGen05LoadReduction = True
gb300LdRed = Refl

public export
b200NoLdRed : instructionEligible BlackwellSM100 ArchitectureSpecific TCGen05LoadReduction = False
b200NoLdRed = Refl

public export
gb300Accepts100f : acceptsPTXTarget BlackwellUltraSM103 "sm_100f" = True
gb300Accepts100f = Refl

public export
gb300Rejects100a : acceptsPTXTarget BlackwellUltraSM103 "sm_100a" = False
gb300Rejects100a = Refl

public export
b200Rejects90a : acceptsPTXTarget BlackwellSM100 "sm_90a" = False
b200Rejects90a = Refl

public export
smSharedMemoryMax : sharedKiBPerSMMax (resourceLimits (profile BlackwellUltraSM103)) = 228
smSharedMemoryMax = Refl

public export
smWarpSize : warpThreads (resourceLimits (profile HopperSM90)) = 32
smWarpSize = Refl

public export
h200Has132SM : smCountCeiling (sku H200SXM) = Just 132
h200Has132SM = Refl

public export
b200NonportableCluster : nonportableClusterBlocks B200SXM = Just 16
b200NonportableCluster = Refl

public export
gb300NoB200ClusterAssumption : nonportableClusterBlocks GB300NVL72 = Nothing
gb300NoB200ClusterAssumption = Refl

public export
portableClusterIsEight : portableClusterBlocksMax Backend.NVIDIA.Specs.cudaGridLimits = 8
portableClusterIsEight = Refl

public export
gridXIsWide : gridXMax Backend.NVIDIA.Specs.cudaGridLimits = 2147483647
gridXIsWide = Refl

public export
gridXIsPositive : (gridXMax Backend.NVIDIA.Specs.cudaGridLimits > 0) = True
gridXIsPositive = Refl

public export
tcgen05MinISA : minimumPTXISA BlackwellTCGen05 = Just (8, 6)
tcgen05MinISA = Refl

public export
gb300LoadReduceMinISA : minimumPTXISA TCGen05LoadReduction = Just (8, 8)
gb300LoadReduceMinISA = Refl

public export
hopperFamilyTargetUnavailable : ptxTarget HopperSM90 FamilySpecific = Nothing
hopperFamilyTargetUnavailable = Refl

public export
hopperFamilyCannotCompile : instructionEligible HopperSM90 FamilySpecific ScalarFP64 = False
hopperFamilyCannotCompile = Refl

public export
b200DPXNotSingleNative : supports BlackwellSM100 NativeDPX = False
b200DPXNotSingleNative = Refl

public export
gb300DPXNotSingleNative : supports BlackwellUltraSM103 NativeDPX = False
gb300DPXNotSingleNative = Refl

public export
b200Table33TensorInputList : tensorOperands BlackwellSM100 =
  [TensorFP64, TensorTF32, TensorBF16, TensorFP16, TensorE4M3, TensorE5M2,
   TensorE2M3, TensorE3M2, TensorE2M1, TensorINT8]
b200Table33TensorInputList = Refl

public export
gb300Table33FP6InputList : tensorOperands BlackwellUltraSM103 =
  [TensorTF32, TensorBF16, TensorFP16, TensorE4M3, TensorE5M2,
   TensorE2M3, TensorE3M2, TensorE2M1, TensorINT8]
gb300Table33FP6InputList = Refl
