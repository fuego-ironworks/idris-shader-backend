# Fourier Voice generated versus handwritten fragments

SUN FRAGMENT-FOURIER-01, executed 2026-10-14 UTC.

**Result: the exact 24-coefficient polynomial and coloring can be emitted as an
unrolled uniform-array fragment. The resident GPU comparison remains blocked
by missing storage-buffer input and safe reverse-index admission. No phone
speed, pixel accuracy, or latency result is claimed.**

## Source identities

- Backend/compiler logic: fuego-ironworks/idris-shader-backend
  4a29362e580df393e4d64a9929e4c1e592ac4c53, unchanged.
- Handwritten GPU: isomorphismes/Fourier-sound
  3c2ecaafd9384b2096dd55b11cca5a74ec0c6c83.
- CPU application: isomorphismes/Fourier-sound
  a71c9d37f47154ba7b66d7c0d5c912477c71f23c.
- Ordinary Idris 2 and compiler API: 0.8.0,
  idris-lang/Idris2@15a3e4e70843f7a34100f6470c04b791330788df.
- Khronos glslang: 15.1.0; Chez Scheme: 9.5.8.
- Observed host: Ubuntu 24.04.3, Linux x86_64.
- Flexible Pipes controller: 7dc68ca3d4ee49511e73b39f618a6f32da206bf7.
- Checked Ithon interface resolved for handoffs: d6e83969f82512e920fb17b44326cb54f31d015c.
  No deployed visible-sink or dispatch acceptance is asserted.

## Implemented slice

The polynomial uses coefficient[23] down through coefficient[1], with the
constant forced to zero. The domain and full HCL → CIE L*u*v* → sRGB constants
are taken from Fourier Voice. Exact zero has phase zero in the comparison
candidates; the original GLSL uses atan(0,0), which is not a defined silence
oracle. The benchmark controls document this explicit correction.

The successful path is ordinary source → registered backend → typed shader
representation → emitted GLSL → Khronos syntax and link validation. Sources,
emitted fragments, intermediate output, raw logs, and hashes are retained.
Source and output digests are listed in identities.sha256.
Vector pairs remain SVec 2 carriers for complex Cartesian components, not lists.

Generated highp GLSL is 18,103 bytes. The handwritten unrolled uniform control
is 3,568 bytes; the handwritten loop control is 2,435 bytes. Source length
includes SSA temporary names and declarations. It does not measure driver
instructions, register allocation, execution cost, or phone speed.

The highp and mediump variants have byte-identical typed IR. Only a GLSL
precision policy changes; numerical behavior and hardware width were not tested.

## Executed results

| Case | Ordinary source | Backend output | GLSL check |
| --- | --- | --- | --- |
| 24-term unrolled highp | PASS | PASS | PASS, syntax and vertex linking |
| 24-term unrolled mediump | PASS | PASS | PASS, syntax and vertex linking |
| Current compact Horner source | PASS | REFUSED: reverse index | NOT_RUN |
| Minimal forward-index twin | PASS | PASS | PASS |
| Minimal safe reverse-index twin | PASS | REFUSED: array bounds | NOT_RUN |
| Deliberately out-of-range twin | PASS | REFUSED: array bounds | NOT_RUN |
| Storage-buffer interface probe | PASS | REFUSED: unknown storage | NOT_RUN |
| Existing bounded-loop regression | PASS | PASS | PASS, highp/lowp controls |
| Handwritten controls | n/a | n/a | PASS, original syntax and adapted linking |

For the safe reverse case, index runs from 0 through 23 and the access is
23 − index, so the accessed range is 0 through 23. The current
statementArraysSafe machinery admits the forward form but rejects this
arithmetic/alias form. The bad twin uses 24 − index and must remain rejected.

The storage parser admits only in/uniform and the emitter targets ES 3.00.
The resident application's final FFT buffer requires ES 3.10 readonly std430
storage-buffer input, binding zero. Changing the application to uniform
transport would confound the requested comparison and is not proposed.

## Failed attempts retained

Attempt 1 combined the functions and publicly exported their bodies. Both
source checks were killed with exit 137. Attempt 2 separated modules; the
compact source then reached the bounds rejection, but a serial unrolled check
was killed and the OOM-kill counter increased. Attempt 3 supplies an exported
Horner-step signature and explicit SVec 2 accumulator types; source checking
and actual emission complete successfully. See attempt-1 and attempt-2.
This is evidence for this source formulation, not a compiler-wide memory diagnosis.

Backend rejection prints Error while returning zero in this compiler path.
The initial SSBO runner receipt consequently has process status PASS. That is
not shader-emission acceptance: the diagnostic and absent artifact establish
REFUSED. The range probes explicitly require an output artifact and fail
closed. Do not treat the raw process status as the evidence verdict.

## Execution boundaries

The job request was captured by Flexible Pipes before the source attempts.
Bootstrap and generation commands ran through its command-stage controller.
The upstream Idris bootstrap used its maintained Make path; the generator was
invoked directly under FP. A registered Kitchen/Ike build task and independent
AICI acceptance for this comparison are NOT_RUN. These receipts do not authorize
deployment, publication of an application artifact, or integration.

Physical MIRO A1 identity, installed APK, GL implementation, pixel readback,
driver compilation time, GPU timing, frame timing and microphone/display
latency are NOT_RUN/UNKNOWN. No APK was produced. Recorded-speech buffers and
encoded binary32 fixture digests remain pending. Text fixtures are analytic
fragment inputs, not production audio or FFT acceptance.

## Decision and allocation

Sun diagnosis is established: add the narrow readonly SSBO interface and
sound reverse-index checking, then run the controlled comparison on A1.
The emitted uniform candidates and controls supply reproducible numerical
sources, not an accepted resident renderer.

Earth: implement those coupled capabilities, wire fresh-output checks and the
registered build/acceptance path, and deliver the controlled benchmark.
Moon: NONE until that Earth result and its actual A1 acceptance exist.

The reviewed packet is published on
https://github.com/fuego-ironworks/idris-shader-backend/tree/sun/fragment-fourier-01.
The original local commits remain provenance pins; the published commits have
the same final Git tree rather than the same commit IDs.

