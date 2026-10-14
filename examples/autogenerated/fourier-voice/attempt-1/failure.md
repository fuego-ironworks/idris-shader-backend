# Attempt 1: large source-check expansion

Both source checks were killed with exit 137 while importing the combined
FourierMath module. No generated GLSL existed. They were launched concurrently,
so that run alone cannot determine the per-process requirement. The host's
memory.events subsequently reported two OOM kills under an 8 GiB limit.

Version 2 separates the loop and unrolled modules and exports operation
signatures without public-exporting their bodies for dependent elaboration.
The complex operation remains a function with the same SVec 2 interface and
arithmetic. This is a source representation change, not a weaker type or a
different polynomial. The original sources remain under attempt-1.

Serial retries must establish whether this resolves the source-check failure.
Backend compilation, emitted output, and hardware behavior remain separate.

