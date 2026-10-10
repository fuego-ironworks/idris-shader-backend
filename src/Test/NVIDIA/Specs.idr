module Test.NVIDIA.Specs

import Backend.NVIDIA.Specs

%default total

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
noNativeE5M3 : supports BlackwellUltraSM103 NativeE5M3 = False
noNativeE5M3 = Refl

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
