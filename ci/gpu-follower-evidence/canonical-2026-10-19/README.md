# Owned compiler/API host replay

This record is a fresh local source and host qualification, not a hosted CI or
physical-GPU result. The original compatibility records remain unchanged.

Compiler/API: isomorphisms/Idric
`2734ac5a86610eddfab73b1644d72b4ac85a65ee`. Its existing Chez executable
installed its actual compiler API into a private prefix and built the numeric,
PTX, AMDGPU, and GLSL ES packages. The known RefC-prerequisite support-only
bootstrap correction is separately integrated; this is not a new pristine
compiler bootstrap or a RefC fallback. The initially absent API package was
installed before judging backend compatibility. An initial parallel Chez
executable build was killed with status 137; the sequential PTX retry passed.

The current merge preserves main's coordinate roles and float-tuple IR. The
optional emitters and their four source fixtures now use those actual types.
Fresh PTX and LLVM emission starts from the ordinary checked source fixtures,
not handwritten assembler or a CPU imitation. CUDA 12.9.86 ptxas assembled
Givens and pixel kernels for sm_80/sm_90/sm_100/sm_103. ROCm 7.2.3 LLVM 22
lowered, assembled, and linked pixel kernels for gfx942/gfx950/gfx1250. Actual
unsupported-target, unsupported-width, unsupported-literal and damaged vendor
assembly controls failed at their expected boundaries. Program digests match
the retained vendor-tool manifest exactly. These are host compilation results.

The fresh scalar stream has SHA-256
`45a691455ef9e1b4a7aad995c6ba69a97afa4bfafa08d15844bcc5f79a95177d`.
Actual Ike `71178c348dd4621bd999ebdb6b0b60bac03fc85d`, built with the
declared ICK C frontend, executed the numeric target using the real Grease
runner. `numeric.ike.tsv` binds its current Ikefile digest and both recipes.
The independent ai-ci gate at
`fada3841bc119c9b64e4076a56b2dffedf0a9d8b` ran through checked Ithon
`9d530f4ad51f5b0a09c3e74dbe45cac5bb6d52d3`, with foreign ml_dtypes 0.5.3.
All 1,168 encodings, 1,716 midpoint cases and 904 arithmetic cases passed;
seven damaged numerical streams and three damaged Ike receipts were rejected.

The complete primary Ike `check` graph passed with the actual owned compiler,
declared ICK, accepted Ithon frontend, and installed GLSL validator. The retained
Make/Python leaf checks are explicit inherited migration debt, not native Ithon
claims. The independent gate accepted the exact `make check` plan and every
recipe status in `primary.ike.tsv`. All tracked generated outputs remained
unchanged. The five role/space/dimension/spoof fixtures were also refused by
the actual source checker/backend. A freshly ICK-built GLES runner executed
the current generated coordinate shaders under Mesa/llvmpipe; the independent
Idriç checker accepted 1,026 readbacks and rejected an executed one-operand
coordinate-swap mutant and an omitted-case record. Mesa is software-GPU host
evidence, not PowerVR, Mali, NVIDIA or AMD hardware evidence.

The inherited source Double/session-F32 bridge remains explicit. This does
not accept a canonical Float32 source handoff, native FP8 execution, device
launch, host/device ABI readback, GPU timing, any named physical GPU, or a
private accelerator deployment. Optional SDKs are host-only followers.
