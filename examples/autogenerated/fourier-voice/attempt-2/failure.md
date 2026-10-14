# Attempt 2: unrolled elaboration still exhausted memory

The split-module loop source checked successfully and then reached the actual
backend. Its safe reverse index 23 − loop_index was rejected by the bounded
array-access check. The backend retained its ANF but emitted no fragment.

The unrolled source was retried alone. Its source check was killed (exit 137);
memory.events oom_kill increased from 2 to 3. No GLSL was emitted. Splitting
modules and replacing public export alone did not solve this case.

Version 3 uses one signature-only exported Horner step across the module
boundary and explicitly types each let-bound accumulator as SVec 2. It retains
the same arithmetic and coefficient order. This tests source elaboration cost,
not GPU performance or general compiler complexity.

