# GPU follower source and type boundary

The earlier module-case failure is preserved in `module-case-attempt.txt`.
The meaningful `Givens.idric` probe reached `Undefined name Float32`. Its
original local compiler was removed before a binary/source attestation was
saved, so this is retained as an unqualified observation. Canonical Idriç source
2734ac5a86610eddfab73b1644d72b4ac85a65ee requires a new pinned replay; no
language-wide failure or successful modern shader handoff is claimed.

The semantic values are points in a plane, plane rotations, an explicit F32
sample buffer and four F32 outputs per sample. Rotation preserves length and
erases the second coordinate. Source checking must precede the shared indexed
shader IR, target checks, native vendor assembly and independent readback.

Desired signature: `rotate : SVec 2 → SVec 4`, with explicit Float32 arithmetic.
Effects belong only to host dispatch, allocation and receipts. Source numerical
functions remain pure. F16, OCP FP8, FNUZ and vendor scales cannot share an
unannotated bit layout. Generated output cannot satisfy a physical device gate.

`Givens.idric` probes the modern language's explicit Float32 shader surface.
Its result is recorded during qualification. The existing `.idr` compatibility
compiler implementation is preserved separately; it uses the inherited Double
source representation with an explicit F32 shader session. This compatibility
path does not qualify canonical Idriç Float32 checking or runtime integration.

First migration requirement: expose source-owned Float32 primitives and retain
their width in the checked core handoff consumed by this shader backend. The
acceptance case must reject implicit F16/Double substitution and compile the
same rotation through the Idriç frontend to the shared IR and actual vendor
output. A renamed `.idr` source or a CPU oracle does not satisfy that boundary.
