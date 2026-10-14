# Fourier Voice fragment comparison

Request: SUN FRAGMENT-FOURIER-01; user continuation “Go”.
Base backend: 4a29362e580df393e4d64a9929e4c1e592ac4c53.
GPU reference: isomorphismes/Fourier-sound@3c2ecaafd9384b2096dd55b11cca5a74ec0c6c83, render/android/gpu_voice_pipeline.c.
CPU reference: isomorphismes/Fourier-sound@a71c9d37f47154ba7b66d7c0d5c912477c71f23c.

## Values and types, before implementation

A point is a complex number represented by two real Cartesian components.
A coefficient is likewise a complex number. A 24-element SArray is coefficient
storage, not a definition of a mathematical vector. Complex addition and scalar
multiplication have their usual vector-space meanings. Complex multiplication
has its usual ring meaning; it is not a dot product.

SVec 2 is the opaque shader carrier for those Cartesian pairs; SVec 3 and
SVec 4 carry display RGB and RGBA values. No lists stand in for these carriers.

- complex_multiply : SVec 2 → SVec 2 → SVec 2
- polynomial_loop : SVec 2 → SArray 24 (SVec 2) → SVec 2
- polynomial_unrolled : SVec 2 → SArray 24 (SVec 2) → SVec 2
- voice_color : SVec 2 → SVec 3
- fragment : SVec 2 → SArray 24 (SVec 2) → SVec 4

The polynomial is Σ from k=1 through 23 of coefficient[k] × point^k. Storage
element zero is ignored regardless of its contents. The domain is
[−0.44,0.44] × [−0.88,0.88]. Inputs admitted for numerical comparison are finite.
The loop has exactly 24 iterations; the explicit form starts at coefficient 23
and performs 23 complex multiply-add steps.

Coloring follows the existing Fourier Voice HCL, CIE L*u*v*, and sRGB constants.
An explicit zero-value phase of zero is shared by candidate and future control:
GLSL atan(0,0) must not define silence acceptance. This qualifies a defined
comparison semantics rather than claiming the original shader already did so.

The source has no host IO, allocation, or general recursion. Its covering tail
iteration is intended to match the existing backend's admitted bounded shape.
The actual requested integration target is GLES 3.10, std430 readonly SSBO
binding zero, with the final FFT buffer consumed directly by the fragment.

## Language and backend choice

The job explicitly requests the existing ordinary Idris 2 → GLSL backend. Use
that compiler route, not an invented Idriç integration or handwritten output.
This is the presently documented generator; Idriç integration remains separate.

The current interface parser offers only FragmentInput and Uniform, and the
emitter writes GLSL ES 3.00. Supported uniform examples are generation probes,
not acceptance of the resident FFT → SSBO → fragment application.

## Invocation and results

PASS: current ordinary-source checks; registered unrolled emission (highp and
mediump); Khronos syntax/link validation; existing bounded-loop regression.
REFUSED: readonly storage-buffer interface and safe reverse array indexing.
NOT_RUN: independent numerical/image checking. See README.md and the retained
raw receipts for each evidence boundary and failed attempt.
Physical A1 correctness and performance: NOT_RUN.
No installed APK identity has been observed in this environment.

## Fallback and next language work

No generated GLSL will be substituted for absent backend output. Any uniform
variant remains an explicitly separate generation probe. The first necessary
production capabilities are typed readonly SSBO input with pinned GLES 3.10
emission and sound range checking for the safe 23 − index access. Keep
rejection of illegal storage/type/binding and out-of-range combinations. A passing
test must compile checked source and draw from the final FFT buffer directly.

