# Public hardware and separate acceptance levels

Reviewed 2026-10-13 UTC. PASS covers the stated bounded fields/path, not every
capability. FAIL means an exercised selected-toolchain refusal. UNVERIFIED means
matching evidence is absent. The private OpenAI inventory and installed SKU
configurations are unknown. All followers remain optional to MIRO A1 ARM32.

| Hardware | Public OpenAI relationship | Published identity / capacity reference | Specs | Checked codegen | Vendor validation | ABI/readback | Physical execution | ai-ci |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MIRO A1 / PowerVR GE8322 | Primary user device | ARM32 / GLSL ES; memory queried at runtime | PASS declared profile | PASS GLSL suite | PASS GLSL validator | UNVERIFIED current device | UNVERIFIED current artifact | Bounded host checks |
| NVIDIA A100 | 2024 research benchmark; fleet unknown | Ampere sm_80; 40/80 GB variants | PASS bounded | PASS Givens/pixel | PASS CUDA 12.9.86 | UNVERIFIED | UNVERIFIED | PASS bounded numeric/Ike |
| NVIDIA H100 | Hopper family operating; SKU unknown | sm_90; SXM reference 80 GB | PASS bounded | PASS Givens/pixel | PASS CUDA 12.9.86 | UNVERIFIED | UNVERIFIED | PASS bounded numeric/Ike |
| NVIDIA H200 | Hopper family operating; SKU unknown | sm_90; SXM reference 141 GB | PASS bounded | PASS Givens/pixel | PASS CUDA 12.9.86 | UNVERIFIED | UNVERIFIED | PASS bounded numeric/Ike |
| NVIDIA B200 | Blackwell family operating; SKU unknown | sm_100; SXM reference 180 GB | PASS bounded | PASS Givens/pixel | PASS CUDA 12.9.86 | UNVERIFIED | UNVERIFIED | PASS bounded numeric/Ike |
| NVIDIA GB200 | Blackwell family operating; SKU unknown | sm_100; 372 GB per two-GPU superchip | PASS bounded | PASS Givens/pixel | PASS CUDA 12.9.86 | UNVERIFIED | UNVERIFIED | PASS bounded numeric/Ike |
| NVIDIA GB300 | Blackwell family operating; SKU unknown | sm_103; NVL72 GPU reference 279 GB; physical HBM marketing differs | PASS bounded | PASS Givens/pixel | PASS CUDA 12.9.86 | UNVERIFIED | UNVERIFIED | PASS bounded numeric/Ike |
| NVIDIA Rubin | Announced capacity | sm_107 in CUDA/Tile IR 13.4 developer preview; installed memory unknown | PASS preview identity; resources unknown | FAIL CUDA 12.9 pin | UNVERIFIED newer preview | UNVERIFIED | UNVERIFIED | UNVERIFIED target |
| AMD MI300X | Acknowledged collaboration | CDNA3 gfx942, wave64, 192 GiB, native FNUZ | PASS published fields | PASS bounded pixel | PASS ROCm 7.2.3 LLVM 22 | UNVERIFIED | UNVERIFIED | PASS bounded numeric/Ike |
| AMD MI350X | Acknowledged collaboration | CDNA4 gfx950, wave64, 288 GiB, native OCP FP8 | PASS published fields | PASS bounded pixel | PASS ROCm 7.2.3 LLVM 22 | UNVERIFIED | UNVERIFIED | PASS bounded numeric/Ike |
| AMD MI450 series | Announced agreement; activation unknown | Family commitment; exact SKU/memory unknown | PASS classification; SKU unknown | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED target |
| AMD MI455X | Representative public SKU; OpenAI assignment unknown | CDNA5 gfx1250, wave32; 432 GB HBM4 / 23.3 TB/s advertised | PASS published fields | PASS bounded pixel | PASS ROCm 7.2.3 LLVM 22 | UNVERIFIED | UNVERIFIED | PASS bounded numeric/Ike |
| Microsoft Maia 200 | Microsoft reports OpenAI-model support | SDK preview; 216 GB HBM3e / 7 TB/s / 272 MB SRAM | PASS fields; raw ISA unknown | UNVERIFIED SDK integration | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED target |
| AWS Trainium3 | Capacity commitment; assignment unknown | Neuron 2.29.1/NKI; eight NeuronCore-v4; 144 GiB / 4.9 TB/s | PASS fields | UNVERIFIED NKI integration | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED target |
| AWS Trainium4 | Announced future capacity; expected 2027 | Provisional resources/interface; no invented ISA | PASS classification; architecture unknown | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED target |
| Cerebras WSE-3 | Explicit Codex-Spark production serving | WSE-3 / public CSL SDK; deployed resources unknown | PASS serving identity; resources unknown | UNVERIFIED CSL integration | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED target |
| OpenAI/Broadcom Jalapeño | Measured first silicon; planned end-2026 deployment | Custom inference ASIC; public raw ISA/SDK/memory unknown | PASS dated classification; resources unknown | UNVERIFIED; no invented backend | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED target |
| Google TPU, generation unknown | Reported early testing; later denial of current product plans | Generic XLA/JAX/Pallas do not identify an OpenAI chip | UNVERIFIED generation | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED target |

Capacity fields retain published manufacturer unit labels. They are not
qualified allocation sizes: do not convert marketing GB to bytes, or replace an
observed device's usable capacity with chip/rack maxima. Resource limits, waves,
address spaces, barriers and tensor layouts belong to a specific architecture
and SDK, never a global vendor-wide 32/64-lane default.

## Dated evidence

- OpenAI, 2026-02-27: [operating Hopper/Blackwell families and Rubin capacity](https://openai.com/index/scaling-ai-for-everyone/).
- OpenAI, 2024-10-23: [A100 research benchmark](https://openai.com/index/simplifying-stabilizing-and-scaling-continuous-time-consistency-models/).
- NVIDIA: [CUDA identities](https://developer.nvidia.com/cuda/gpus), [PTX ISA](https://docs.nvidia.com/cuda/parallel-thread-execution/), [13.4 Rubin preview](https://docs.nvidia.com/cuda/tile-ir/13.4/sections/stability.html), [HGX references](https://docs.nvidia.com/enterprise-reference-architectures/hgx-ai-factory-h100-h200-b200/latest/components.html), [GB200](https://www.nvidia.com/en-us/data-center/gb200-nvl72/), [GB300](https://www.nvidia.com/en-us/data-center/gb300-nvl72/), [SKU datasheet](https://resources.nvidia.com/en-us-gpu-resources/blackwell-ultra-datasheet).
- OpenAI, 2025-10-06: [MI300X/MI350X collaboration and MI450 agreement](https://openai.com/index/openai-amd-strategic-partnership/).
- AMD: [ROCm 7.2.3 hardware table, 2026-02-20](https://rocm.docs.amd.com/en/docs-7.2.3/reference/gpu-arch-specs.html), [HIP OCP/FNUZ](https://rocm.docs.amd.com/projects/HIP/en/docs-7.2.0/reference/low_fp_types.html), [MI455X hardware](https://www.amd.com/en/products/accelerators/instinct/mi400/mi455x.html), [gfx1250 SKU](https://rocm.docs.amd.com/projects/primus/en/main/04-technical-guides/LoRA_Native_Trainer_MI455_README.html), [CDNA5 wave32](https://rocm.docs.amd.com/projects/FlyDSL/en/latest/architecture_guide.html).
- Microsoft: [Maia, 2026-01-26](https://blogs.microsoft.com/blog/2026/01/26/maia-200-the-ai-accelerator-built-for-inference/), [FY2026 Q4 statement](https://www.microsoft.com/en-us/investor/events/fy-2026/earnings-fy-2026-q4).
- OpenAI, 2026-02-27: [Trainium3/4 agreement](https://openai.com/index/amazon-partnership/); AWS: [Neuron 2.29.1 Trainium3](https://awsdocs-neuron.readthedocs-hosted.com/en/v2.29.1/about-neuron/arch/neuron-hardware/trainium3.html).
- OpenAI, 2026-02-12: [explicit WSE-3 serving](https://openai.com/index/introducing-gpt-5-3-codex-spark/); [published CSL SDK](https://docs.cerebras.ai/).
- OpenAI, 2026-08-25: [Jalapeño results and planned deployment](https://openai.com/index/jalapeno-first-results/).
- TPU provenance is secondary reporting of OpenAI's statement, not technical inventory: Reuters [2025-06-27 report](https://www.reuters.com/business/openai-turns-googles-ai-chips-power-its-products-information-reports-2025-06-27/) and [2025-06-30 correction](https://www.reuters.com/business/openai-says-it-has-no-plan-use-googles-in-house-chip-2025-06-30/). No recovered firsthand technical statement qualifies a generation here.

## Open obligations

Host/device launch, numerical readback and named physical execution remain
required. Canonical Idriç width-preserving handoff remains unqualified. The AMD
pixel slice is not a complete HIP compiler. Maia/NKI/CSL SDK adapters remain
unimplemented; Jalapeño lacks a recovered public ISA and Trainium4 is
provisional. None of these followers becomes a primary phone dependency.
