# Explicit Float32 source contract probe

This tests the source type needed before claiming that a numerical width is
preserved from source typing into lowering. A directive or precision qualifier
cannot replace that source contract. No Float32-to-Double alias is introduced.

Input/output: Float32 → Float32 identity, no effects, rounding or conversion.
The actual Idriç frontend/API at 2734ac5a86610eddfab73b1644d72b4ac85a65ee is
the producer tested here; current e8b9173ab2d840ef0cf212698ea2fee97bd9e807 has
no compiler/prelude changes against that head.

Status: the actual source check exited 1 with `Undefined name Float32`.
The required FP width-probe stage is FAIL, with its exact diagnostic retained
in the control receipt. Explicit source-width preservation remains a compiler
dependency. Never rename Double or a GLSL precision class to Float32
as a substitute. The next language work is a real format-bearing scalar type
and primitive semantics preserved through the compiler handoff, with rounding
and incompatible-lowering refusal tests.
