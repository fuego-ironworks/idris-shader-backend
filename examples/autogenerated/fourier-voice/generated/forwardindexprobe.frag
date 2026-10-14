#version 300 es
precision highp float;
precision highp int;

uniform float u_active;
uniform vec2 u_coefficients[24];
layout(location = 0) out vec4 _idris_fragColor;

void main() {
  vec2 _idris_t0 = vec2(0.0, 0.0);
  vec2 _idris_t1 = _idris_t0;
  for (int _idris_t1_index = 0; _idris_t1_index < 24 && float(_idris_t1_index) < u_active; ++_idris_t1_index) {
    vec2 _idris_t2 = u_coefficients[int(float(_idris_t1_index))];
    vec2 _idris_t3 = (_idris_t1 + _idris_t2);
    float _idris_t4 = (float(_idris_t1_index) + 1.0);
    _idris_t1 = _idris_t3;
  }
  float _idris_t5 = _idris_t1.x;
  float _idris_t6 = _idris_t1.y;
  vec4 _idris_t7 = vec4(_idris_t5, _idris_t6, 0.0, 1.0);
  _idris_fragColor = _idris_t7;
}

