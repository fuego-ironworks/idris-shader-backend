# Compiler implementation comparison reference

The ICK `inspiration` branch collects source and discussion comparisons among
GCC, Clang/LLVM, TinyCC, chibicc, cproc/QBE, lacc, 8cc, cparser/libFirm,
CompCert, PCC, slimcc, and c4:

https://github.com/dilapidated-shed/ick/tree/inspiration/inspiration

This shader backend should treat that work as comparative research, not as a
reason to adopt a CPU C compiler architecture.

## Relevant parts

The useful documents are:

- `gcc-contrast-notes.md` — public discussion of compiler tradeoffs;
- `kernel-construct-corpus.md` — real production C constructs used to expose
  compiler seams;
- `first-six-traces.md` — corrected paired-source archaeology across the
  reference compilers.

Several observations may matter as the shader backend evolves:

- **Clang/LLVM:** source-semantic structure and backend IR stay deliberately
  separate. Compare that boundary with checked Idris/ANF -> shader subset ->
  typed shader representation -> GLSL.
- **cproc/QBE:** a small frontend/backend contract can remain useful without
  importing a large optimizer into the frontend.
- **cparser/libFirm:** explicit graph operations survive until target-aware
  lowering. The comparison's `CopyB` example is CPU-oriented, but the broader
  question applies here: which shader operations should remain explicit until
  a GLSL/SPIR-V-specific stage can lower them intelligently?
- **CompCert:** important semantic operations remain named across several
  intermediate representations. This is useful precedent for preserving
  shader-subset meaning instead of lowering early merely because a target form
  is available.
- **TinyCC/chibicc/8cc/c4:** smaller compilers make the cost of each extra
  representation and optimization stage visible. They also make refusal
  boundaries obvious, which fits this backend's deliberate rejection of
  recursion, closures, heap data, and unsupported effects.

The Linux-kernel paired cases are not shader workloads. Their value here is
methodological: start from real source constructs, preserve the semantic
question, then reduce only for executable comparison.

## Questions to revisit

When the shader IR or target set changes, compare:

- whether typed linear/structured shader operations are being lowered too
  early;
- whether a new target really needs a shared GPU IR or can use the current
  target-specific boundary;
- whether optimization belongs before or after target selection;
- whether target facts such as vector width, precision, storage class, and
  structured-control restrictions remain explicit long enough;
- whether adding SPIR-V/Vulkan would benefit from a clearer backend seam rather
  than widening the GLSL emitter into a multi-target backend.

## Update rule

Refresh this note when the ICK comparison gains executable cross-compiler
results, when a new shader target is implemented, or when the shader
representation changes materially. Do not turn a comparison note into an
acceptance claim: emitted GLSL, validated GLSL, live rendering, and physical-GPU
execution remain separate evidence levels.
