# NVIDIA Hopper, Blackwell and Blackwell Ultra: compiler target facts

Status: **architecture catalogue with Idris-checked guards, not a PTX backend**.
Recorded 2026-10-10 against current NVIDIA published programming, PTX and SKU
documentation. Source-of-truth implementation: `src/Backend/NVIDIA/Specs.idr`.
The catalogue is independently typechecked via
`idris2 --build nvidia-target-specifications.ipkg`. It is not connected to
a CUDA/PTX emitter or the inherited NVIDIA fragment mocks.

This catalogue concerns commercially published NVIDIA hardware families, **not
which GPU served a particular OpenAI request**. Cloud partitioning, clock
limits, driver and installed compiler versions must be measured independently.

## Architecture and SKU are different questions

| Named GPU / configuration | Compute capability | Baseline PTX target | Reported HBM per GPU | Reported HBM bandwidth per GPU | NVLink bandwidth per GPU |
| --- | --- | --- | ---: | ---: | ---: |
| H100 SXM | Hopper 9.0 | `sm_90` | 80 GB HBM3 | 3.35 TB/s | 900 GB/s |
| H200 SXM | Hopper 9.0 | `sm_90` | 141 GB HBM3e | 4.8 TB/s | 900 GB/s |
| B200 SXM | Blackwell 10.0 | `sm_100` | 180 GB HBM3e | up to 8 TB/s | 1.8 TB/s |
| GB200 NVL72 GPU | Blackwell 10.0 | `sm_100` | 186 GB HBM3e | up to 8 TB/s | 1.8 TB/s |
| GB300 NVL72 GPU | Blackwell Ultra 10.3 | `sm_103` | **279 GB HBM3e** | up to 8 TB/s | 1.8 TB/s |

GB200's **two-GPU** Grace Blackwell superchip reports 372 GB of HBM,
equivalent to 186 GB per GPU. The GB300 NVL72 **rack** holds 72 Blackwell
Ultra GPUs and 36 Grace CPUs; multiply per-GPU figures only if the quantity
explicitly concerns the entire 72-GPU rack, not a single CUDA device.
GB300 marketing also describes up to 288 GB **physical HBM** on Blackwell
Ultra; NVIDIA's official GB300 NVL72 SKU datasheet says **279 GB per GPU**.
The catalogue uses the SKU-specific 279 GB, not a chip maximum. On any real
server, query memory returned by the driver rather than using the catalogue to
size allocations.

SKU SM counts: NVIDIA describes H100 SXM and H200 SXM as 132 SMs in product
material, B200 as 148 enabled SMs, and Blackwell Ultra as **up to** 160 SMs
on a full chip. An enabled-SM count on a rented slice/MIG partition must be
read at runtime. `smCountCeiling : Maybe Nat` deliberately does not guess
where product evidence or deployment variations are uncertain. GB300's 160 is
a **physical full-chip upper bound**, not proof that all instances expose 160.

Sources:
- NVIDIA CUDA device / architecture classification:
  https://developer.nvidia.com/cuda/gpus
- NVIDIA CUDA technical capability tables (2026-09-10 revision):
  https://docs.nvidia.com/cuda/cuda-programming-guide/05-appendices/compute-capabilities.html
- NVIDIA Hopper family SKUs and H200:
  https://www.nvidia.com/en-us/data-center/h100/
  https://www.nvidia.com/en-us/data-center/h200/
  https://docs.nvidia.com/enterprise-reference-architectures/hgx-ai-factory-h100-h200-b200/latest/components.html
- NVIDIA Blackwell and GB200:
  https://www.nvidia.com/en-us/data-center/gb200-nvl72/
  https://docs.nvidia.com/cuda/blackwell-tuning-guide/
- Official GB300/Blackwell Ultra datasheet (including 279 GB per NVL72 GPU):
  https://resources.nvidia.com/en-us-gpu-resources/blackwell-ultra-datasheet
  https://www.nvidia.com/en-us/data-center/gb300-nvl72/

## The shared SM execution limits (compute capabilities 9.0, 10.0, 10.3)

These are *architectural maxima*, not an occupancy promise for a kernel.

| Property | Published limit |
| --- | ---: |
| Threads / warp | 32 |
| Threads / block | 1,024 |
| Resident threads / SM | 2,048 |
| Resident warps / SM | 64 |
| Resident thread blocks / SM | 32 |
| 32-bit registers / SM | 65,536 |
| 32-bit registers / block | 65,536 |
| Registers / thread | 255 |
| Shared memory / SM | 228 KiB |
| User-accessible shared memory / block | 227 KiB |
| Combined L1 / shared cache / SM | 256 KiB |
| Shared memory banks | 32 |
| Constant memory | 64 KiB |
| Max local memory / thread | 512 KiB |
| Portable static shared / block | 48 KiB |

Allocation above 48 KiB/block requires explicitly requested **dynamic shared
memory**. The 228 KiB capacity is carved out of the unified 256 KiB cache.
Supported carveouts in KiB: 0, 8, 16, 32, 64, 100, 132, 164, 196, 228.
The CUDA occupancy API is still needed: registers/thread, memory/block,
blocks/cluster, number of warps, scheduler constraints, and installed GPU
configuration may cut occupancy sharply.

Grid/block limits to capture in any future dispatch descriptor: up to three
dimensions per grid and block; grid x up to 2^31 - 1, grid y/z up to 65,535;
block x/y up to 1,024; block z up to 64; total threads/block up to 1,024.
Do not conflate *dimensions* with total block thread count. CUDA reports up to
128 resident grids/device, independent of a particular kernel's occupancy.
The **portable** thread-block-cluster size is 8; Blackwell B200 also exposes
nonportable 16-block clusters after explicit opt-in. Query actual cluster
occupancy; don't hardcode an assumption that bigger clusters fit.

Sources: CUDA Programming Guide, technical tables 29–33 and memory carveout
table; Hopper and Blackwell Tuning Guides.

## Instruction dialect / binary compatibility

**PTX is NVIDIA's virtual ISA; SASS is GPU-native machine code.**
`sm_90`, `sm_100`, `sm_103` are baseline PTX feature targets. The
suffix changes the set of instructions a compiler may legally generate.

| Target | Meaning | Portability across these three GPUs |
| --- | --- | --- |
| `sm_90` | Hopper 9.0 baseline | Hopper, Blackwell 10.0, Blackwell Ultra 10.3, subject to PTX JIT/toolchain support |
| `sm_90a` | Hopper 9.0 architecture-specific | **Only** 9.0 |
| `sm_100` | Blackwell 10.0 baseline | 10.0 and 10.3 |
| `sm_100f` | 10.x family features | 10.0 and 10.3 (and documented compatible later family targets) |
| `sm_100a` | 10.0 architecture-specific | **Only** 10.0 |
| `sm_103` | 10.3 baseline | 10.3 and later compatible GPUs; not 10.0 |
| `sm_103f` | family features introduced by 10.3 | 10.3 and later compatible 10.x members; not 10.0 |
| `sm_103a` | 10.3 architecture-specific | **Only** 10.3 |

*Never* treat `sm_90a` as portable PTX merely because ordinary `sm_90`
is forward-compatible. *Never* dispatch `sm_100a` onto GB300 simply
because both GPUs are called Blackwell. Compiler/PTX version, driver JIT,
cubin-vs-PTX artifact kind, toolchain support and runtime device query are
**independent checks** beyond the architecture eligibility table.

In this repository:
- `ptxTarget` selects an annotated **intended** PTX target;
- `acceptsPTXTarget` checks just documented architecture compatibility;
- `supports` encodes a hardware capability;
- `instructionEligible` checks architecture **and feature-set suffix**;
- none of these functions compiles PTX.

Sources:
https://docs.nvidia.com/cuda/cuda-programming-guide/05-appendices/compute-capabilities.html
https://docs.nvidia.com/cuda/parallel-thread-execution/

## Scalar, tensor and packing semantics

| Semantic operation | Hopper `sm_90` | Blackwell `sm_100` | Blackwell Ultra `sm_103` |
| --- | --- | --- | --- |
| Scalar FP32 | Yes | Yes | Yes |
| Scalar FP64 | Yes | Yes | Yes |
| Scalar FP32:FP64 peak throughput | 2:1 | 2:1 | **64:1** |
| FP64 Tensor Core operations | Yes | Yes | **No** |
| Tensor FP16 / BF16 / TF32 | Yes | Yes | Yes |
| Tensor FP8 E4M3 / E5M2 | Yes | Yes | Yes |
| Tensor FP6 E2M3 / E3M2 | No | Yes | Yes |
| Tensor FP4 E2M1 | No | Yes | Yes |
| Tensor INT8 | Yes | Yes | Yes |
| Tensor INT4 in current CUDA Table 33 | Not listed | Not listed | Not listed |
| Signed E5M3 FP8 **tensor input** | No | No | No |
| PTX 9.4 unsigned UE5M3 **scale** | Not available | Not available | Not available |

In particular, GB300's **much faster low-precision tensor matrix paths**
must not cause the compiler to assume strong FP64 acceleration. Scalar FP64
works, but throughput is reduced relative to FP32 and native FP64 Tensor
Cores are absent. The distinction matters for complex analysis, accurate
log/arg near poles, iterated polynomial roots, and diagnostic oracles.

These packed Tensor Core operand formats are not ordinary scalar numeric types
whose arithmetic automatically maps to one Tensor Core instruction. Record
type widths, layout, rounding, accumulation format, signedness, scale
metadata, packing, and allowed matrix shapes in a **separate operation
contract**. The intended standard signed FP8 formats are **E4M3 and E5M2**.
Do not silently demote a numeric request to tensor FP8 or map signed formats
to an unsigned scale format.

**PTX ISA 9.4 nuance:** NVIDIA also documents an 8-bit unsigned `ue5m3`
format used as a *scale* for `tcgen05` and in `cvt` conversions. These
operations require `sm_107f` or later within the same Blackwell family,
not `sm_90`, `sm_100`, or `sm_103`. Therefore the catalogue denies
UE5M3 scale availability **only for its three modeled architectures**;
it does not claim that NVIDIA has no UE5M3 format anywhere. It is also
not a signed 8-bit E5M3 matrix input.

FP64/FP32 special-function semantics and `--use_fast_math` are not
interchangeable. In particular: explicit FMA/contraction controls, rounding
mode, subnormal treatment/flush-to-zero, signed zero, NaN propagation,
transcendental approximation bounds, and `atan2`/complex branch conventions
must be part of the typed shader semantics before backend selection.
PTX approximate `sin`, `cos`, `lg2`, `ex2`, `rcp`, `rsqrt` should not
be substituted for an accurately specified oracle without precision evidence.
Precision and layout proofs belong to the shader IR, not SKU marketing data.

Source for allowed matrix operands and throughput ratios: CUDA technical
capability tables 30 and 33; PTX instruction reference. The CUDA table lists
no INT4 for SM90, SM100 or SM103. An older CUDA 13.2 PDF search
extraction lists INT4 on 10.0/10.3, and PTX documents legacy warp-level
`.s4`/`.u4` MMA operations; the current online September 10, 2026
table is the conservative source for this list. Do not mistake either
a legacy warp MMA form or a packed INT4 representation for available
fifth-generation `tcgen05` INT4 acceleration.

## Async memory, warp collaboration and Tensor Cores

### Hopper SM90 / H100 / H200

- 4th generation Tensor Cores; Warpgroup MMA (WGMMA) works in 128-thread
  groups and requires the architecture-specific `sm_90a` target.
- Thread Block Clusters and **Distributed Shared Memory** add a cluster-level
  locality/synchronization scope above an ordinary block.
- **Tensor Memory Accelerator (TMA)** supports asynchronous multidimensional
  global/shared transfers, including bulk copies, coordinated with barriers.
- Asynchronous barriers and shared-memory synchronization are semantic
  requirements; do not reorder producer/consumer activity across them.
- CUDA Table 29 explicitly describes **native DPX on Hopper** and
  a **multiple-instruction implementation on Blackwell**. Blackwell GPU
  DPX algorithms may still benefit from newer CUDA 13.2/PTX optimizations,
  but a library using DPX is not proof of a single native DPX instruction.

### Blackwell SM100 / B200 / GB200

- 5th generation Tensor Cores use the `tcgen05` PTX family and a dedicated
  Tensor Memory (TMEM) space; this is **not** Hopper's WGMMA dialect.
- Enable appropriate instructions through `sm_100f` or `sm_100a`,
  depending on their ISA target notes; baseline `sm_100` does not grant all
  specialist instructions.
- TMA, DSM, block clusters, warp operations, and shared memory remain useful
  even for non-Tensor Core kernels.
- GB200 specifically reports a 126 MB L2 cache (SKU, not automatically true
  for all SM100 GPUs).

### Blackwell Ultra SM103 / GB300

- 5th-generation Tensor Cores, low-precision tensor modes and large TMEM;
  high-level sources describe **256 KiB Tensor Memory per SM**.
  TMEM is not the same as the 228 KiB shared memory.
- PTX `tcgen05.ld.red` (TMEM load/reduction) requires **`sm_103f` or
  `sm_103a`** in this family, not just `sm_100f`.
- FP64 Tensor Core availability is **false**, despite the common name
  Blackwell and despite the continued presence of scalar FP64.

PTX target feature guards are a starting point. Instruction forms also
constrain CTA group, warp participation, address spaces, alignment, layout,
barrier arrival/wait discipline and matrix tile shapes.

Sources:
https://docs.nvidia.com/cuda/hopper-tuning-guide/
https://docs.nvidia.com/cuda/blackwell-tuning-guide/
https://docs.nvidia.com/cuda/parallel-thread-execution/
https://developer.nvidia.com/blog/accelerating-end-to-end-co-folding-performance-with-nvidia-bionemo-agent-toolkit/

## Memory tiers and shader construction

Different address spaces: register, per-thread local (which may spill),
shared/cluster-shared, global HBM, constant, and read-only/cache paths.
Register allocation and spills, shared-memory bank conflicts, global-memory
coalescing and L2 reuse determine performance. "GPU has 279 GB" is not a
usable per-kernel tile capacity. On NVLink systems, remote-GPU data also
requires real peer access/transport arrangements, independent of PTX source.

The target `FragmentProgram` currently describes a **fragment** stage with
varyings/uniforms and `vec4` color. That is already a good semantic source
for the Holomorphic/Wegert CPU or PowerVR renderer, but NVIDIA compute GPUs
cannot be treated as if they had a standard OpenGL ES framebuffer. A future
PTX compute backend requires:
- A typed pixel-domain/dispatch descriptor (`width`, `height`, row pitch,
  buffer/texture ABI, thread-to-pixel indexing and bounds checks).
- A clear account of `v_uv` or `v_ndc`, pixel centers, aspect ratio,
  and what converts a fragment input into a compute thread's coordinates.
- Explicit `uniform` argument and arrays copied to device storage (not
  silently lifted into legacy GL uniforms).
- An output buffer and typed color/rounding/range contract; no fabricated
  `store.frag_color` native instruction.
- One-sample-per-thread initially, occupancy-conscious fusion/batching only
  after proving that pixel independence and numerical contracts are retained.
- Separate scalar, warp, CTA and tensor-tiled optimization lanes; tensor
  matrix instructions are usually *not* the efficient way to evaluate one
  arbitrary complex number per pixel.

The first real compiler evidence would be ordinary checked Idris source ->
actual NVIDIA-specific typed lowering -> complete PTX -> `ptxas` accepted
assembly at a **declared toolkit version**. Host/device ABI and CUDA driver
launch with exact buffer readback would be separate later gates. A physical
H100/B200/GB300 run requires **named GPU identity and a receipt**. Emitting
mock pseudo assembly or comparing a CPU oracle does not establish those gates.

## Guardrails and acceptance

1. `idris2 --build nvidia-target-specifications.ipkg` typechecks
   `Backend.NVIDIA.Specs` and 34 definitional properties in
   `Test.NVIDIA.Specs`. The properties constrain a *static catalogue*;
   they are not hardware tests or PTX output checks.
2. This PR **does not alter or claim acceptance of** the existing
   `FragmentMock` targets. Their inherited emitter refers to the obsolete
   `bindings` representation rather than the current `statements` IR;
   an SM103 mock and its missing fixture exports are deliberately not
   introduced as a supposedly working GPU target.
3. Do not extrapolate actual enabled SMs, device memory, MIG settings,
   compiler support or clock policy from the architecture class.
4. The registered GLSL ES 3.00 compiler remains separate from the new
   NVIDIA catalogue. This is not CUDA/PTX lowering, GPU execution,
   a completed shader target, or Idriç compiler integration.
5. Full PTX generation, `ptxas` validation, host/device ABI, buffer readback,
   and physical named-GPU measurements remain independent **PENDING** stages.
6. The unrelated legacy GLSL intermediate-representation golden check already
   fails on the current default branch; its mismatch must be fixed in its
   own scope, not hidden or weakened to make this catalogue look green.

Related: `docs/float-semantics.md`, `docs/holomorphic-explorer-follower.md`,
`src/Backend/GLSLES/IR.idr`, and `AGENTS.md`.
