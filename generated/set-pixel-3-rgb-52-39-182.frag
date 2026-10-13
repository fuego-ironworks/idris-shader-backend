#version 300 es
precision highp float;
precision highp int;

in vec2 v_ndc;
layout(location = 0) out vec4 _idris_fragColor;

void main() {
  float _idris_t0 = v_ndc.x;
  bool _idris_t1 = (_idris_t0 > 0.5);
  float _idris_t3;
  if (_idris_t1) {
    float _idris_t4 = (52.0 / 255.0);
    _idris_t3 = _idris_t4;
  } else {
    _idris_t3 = 0.0;
  }
  float _idris_t5;
  if (_idris_t1) {
    float _idris_t6 = (39.0 / 255.0);
    _idris_t5 = _idris_t6;
  } else {
    _idris_t5 = 0.0;
  }
  float _idris_t7;
  if (_idris_t1) {
    float _idris_t8 = (182.0 / 255.0);
    _idris_t7 = _idris_t8;
  } else {
    _idris_t7 = 0.0;
  }
  vec4 _idris_t9 = vec4(_idris_t3, _idris_t5, _idris_t7, 1.0);
  _idris_fragColor = _idris_t9;
}

