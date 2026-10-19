# Checked coordinate pairing

Control: https://github.com/isomorphisms/flexible-pipes/issues/116.

The mathematical owner is Idriç's MathematicalSpaces/EuclideanGeometry API.
Its vector and covector roles, named space, real ambient field and dimension
are distinct from the numerical shader interface implemented here.

The shader receives one vector-coordinate packet and one covector-coordinate
packet in the same named standard Cartesian frame. The coordinate scalar
encoding is the existing shader floating contract, not an exact real field or
binary64 guarantee. Pairing returns a numerical scalar; an example separately
maps it to RGBA. Packing is a fixed scalar array in this first checked path.

The source signatures enforce role, dimension and frame. Canonical qualified
intrinsic identity is required before numerical IR erases those roles into
fixed array operands. The compiler records the checked source interface beside
the emitted artifact. Ordinary GLSL tuples remain a separate carrier.

Required acceptance: positive 4D/32D generated kernels; wrong-role, dimension,
equal-dimension different-space and spoofed-declaration refusal; all basis
pairings and signed/general cases through actual shader readback; independent
source and numerical controls. GPU/device execution is a separate stage.

The first compile exposed stale upstream ANF constructor references; consumers
were migrated to the real Idriç API names. Canonical-spelling spoof fixtures
also exposed backend errors exiting successfully; errors now fail the process.

Status: source checking, both emitted dimensions, all five refusals and retained
backend checks passed through the recorded FP → Ike/Grease execution. Actual
Mesa llvmpipe shader readback covers every 32D basis pairing and two signed
coordinate-change samples. The independent ai-ci Idriç checker passes that
readback and rejects an executed one-operand coordinate-swap shader and a
missing final-coordinate result. No fallback was needed. llvmpipe is software
execution; neither physical-device acceptance nor general floating correctness
is claimed. Complete scalar-width/packing qualification remains a later gate.
