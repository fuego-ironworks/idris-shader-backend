# Handwritten controls

The original SSBO shader is decoded verbatim from the C string at
isomorphismes/Fourier-sound@3c2ecaafd9384b2096dd55b11cca5a74ec0c6c83,
render/android/gpu_voice_pipeline.c, fragment_source.

The uniform controls are explicitly adapted generation controls: GLSL ES 3.00,
a 24-element uniform coefficient array, fixed term count 24, fixed radii
(0.44,0.88), and v_uv naming. They define phase zero for exact complex zero,
matching the generated candidates' defined silence semantics. The unrolled
control begins at coefficient 23 and performs 23 multiply-add steps, with the
constant term forced to zero. The loop control mirrors the original
24-iteration form.

These controls are NOT the resident FFT application's deployment path and
cannot establish its performance. No substitution of uniform transport for
SSBO consumption is proposed. fullscreen.vert keeps the same oversized
fullscreen triangle and interpolated sample centers.

