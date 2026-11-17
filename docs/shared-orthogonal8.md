# Callable eight-dimensional rotations

`Shader.Orthogonal8` exposes the Householder operation used by the retained alignment example, parameterized by an arbitrary nonzero normal and an arbitrary argument. `two_reflections8_chunk` composes H_second after H_first. This is a bounded numerical lowering of the `two_reflections` / `compose_orthogonal` semantics in Idric, not a new photo-specific geometry definition or proof that the complete exact module is linked.

Both reflecting planes pass through the origin. Their normals are metric-identified covectors in one explicitly declared standard Euclidean space. Affine classifier offsets do not belong to this rotation API. The caller must check representation, dimension, metric, basis and variance; dimension alone never authorizes composition.

`Example.ApplyTwoReflections8` exposes eight transformed coordinates in three RGBA Float32 readbacks. Alpha is a validity lane, not colour opacity. A zero normal invalidates every page. Nonfinite inputs/results, missing shaders and unsupported framebuffer formats must be refused without a fallback. Normals are scaled by their largest absolute component before products; division is componentwise so a reciprocal of a tiny normal is not formed. Arithmetic that still overflows Float32 is refused by the consumer. No accuracy promise is made for denormal flush-to-zero hardware.

The inverse reverses the reflection order. Equal normals produce identity; nonzero scaling or sign changes leave each reflector unchanged. Each reflection has determinant -1, hence their composition has determinant +1. Application-level composition must reverse operation order when inverted.

Build with `make -f tools/photo-math.mk generate IDRIS2=/path/to/pinned/idris2`. This compiles the current typed 32D coordinate pairing, the legacy alignment diagnostic and the new operation with the registered backend. Outputs stay under `build/photo-math`; no generated GLSL is handwritten or altered after emission. `source-revision.txt`, `source.sha256` and `generated.sha256` bind the result.

The photo consumer must independently execute the generated program, test quarter turns, inverse/identity, scale/sign invariance, full-coordinate transport, norm/pairing preservation and composed order, and reject a corrupted or missing shared program. Compiler success alone is not numerical, physical-phone or photo-quality acceptance.

Status at introduction: source implementation only; generation and runtime results must be recorded at exact commits. The old diagnostic remains unchanged and is not advertised as the new operation.
