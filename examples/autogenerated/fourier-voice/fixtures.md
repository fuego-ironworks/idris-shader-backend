# Coefficient fixtures

These are exact dyadic test values, stored in ascending power order. Every row
has 24 complex coefficients. ignored-dc and exact-value-check deliberately put
nonzero bytes in element zero to test the rule that the constant term is
ignored.

hann-cosine-bin-8 is the ideal normalized transform of
0.5 cos(2π × 8 × sample_index ÷ 1024) after a periodic Hann window.
hann-two-tones adds 0.25 sin(2π × 16 × sample_index ÷ 1024).
These are analytic coefficient fixtures, not recorded output of the production
FFT or microphone. They isolate fragment input and do not accept audio framing.

At z=(0.25,−0.5), exact-value-check has polynomial value
(2.34375,−0.3125), with the stored c₀ ignored. This is a hand-derived oracle
point, not an executed GPU result. zero-at-quarter has roots at zero and 0.25.

No recorded-speech buffer has been obtained. The final benchmark must retain
its actual recording provenance, production coefficient bytes and digest.
Before GPU qualification, encode all fixture pairs as IEEE binary32 for
std430 vec2 storage, record the encoded digests, and feed identical buffers to
both shaders. Text hashes alone do not qualify the future GPU input.

