# Runner division producer

The four arithmetic divisions in the handwritten C framebuffer/timing runner
use `÷`, with ICK c61e448251744a2f40ad743ebef1a027bdcd2f9d preserving `/`
semantics. Strings, generated GLSL assets and ordinary `.idr` sources retain
their existing bytes. This C runner is not an Idriç or GLSL lowering result.

The host Makefile requires an explicit ICK compiler. CI uses the immutable
`ai-ci/ick-host@903b2cb27ea572c9c6cb2ffa9f39e0fbf06ec9f8` producer and requires
the shared C-stage contract before the existing Mesa framebuffer probes.
The pre-existing Python backend-analysis tools are unchanged language debt.

Android jobs use the corresponding pinned `ick-android` action for ARMv7 and
AArch64. `tools/ick-android.mk` consumes its shared ABI and header metadata;
ICK emits assembly and the unchanged NDK r27c assembles and links API21 PIE
executables against EGL/GLES. Compiler builtin headers precede Bionic, and
both Android API macros agree. No alternative C frontend is selected.
The pre-existing phone host procedure also requires `ICK_STAGE` and
`AICI_ROOT` and calls this same producer. An unqualified ABI fails explicitly.

Local validation: the complete AArch64/API21 runner compiles, assembles and
links with actual NDK 27.2.12479018 as an ELF64 PIE. The native ICK runner
executes all six shader compile/link and framebuffer checks successfully
under Mesa llvmpipe (OpenGL ES 3.2). The six C-stage contract assertions and
the phone/tablet renderer-gate regression also pass. The ordinary Idris
backend emission suite remains an independent hosted check.

Package source/blob checks, integrity manifests and phone/tablet renderer
identity gates remain separate. Existing checked ordinary Idris source must
still produce the selected shaders through the backend. Local compilation,
host Mesa execution and cross-linked Android packages do not establish
physical PowerVR/Imagination or TAB_P10 Mali-G57 execution.
