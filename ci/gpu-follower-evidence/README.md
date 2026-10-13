# Captured host qualification

The recorded producer inputs are the two preserved parents in `dependencies.tsv`
plus the feature source blobs accompanying this directory. `source-blobs.tsv`
anchors the actual material source files independently of later narrative or
receipt commits. `artifact-hashes.tsv` contains actual emitted and assembled
bytes; the raw producer/assembler logs and Ike receipts retain observed status.

Current source, compiler, API and SDK pins must be replayed before an exact-head
CI acceptance claim. These local records do not turn historical runs or a
source-identical subsequent metadata commit into a current hosted CI result.
The independent gate source is pinned in dependencies; all ordinary positives
and seven deliberately broken numerical/receipt controls were executed.

This is Ubuntu 24.04 x86-64 host evidence. No GPU device node or CUDA driver
was available. Physical PowerVR, NVIDIA, AMD and proprietary-accelerator
execution, host/device readback and full canonical Idriç integration remain
UNVERIFIED. Earlier LLVM 19 refusals are superseded for the bounded AMD pixel
slice by actual ROCm 7.2.3 assembly/link acceptance for all three selected CPUs.

ROCm archive source:
https://repo.radeon.com/rocm/apt/7.2.3/pool/main/r/rocm-llvm/rocm-llvm_22.0.0.26084.70203-90~24.04_amd64.deb
Official digest index:
https://repo.radeon.com/rocm/apt/7.2.3/dists/noble/main/binary-amd64/Packages
Only the required three vendor programs were extracted; no full ROCm
installation or runtime/physical acceptance is asserted.
