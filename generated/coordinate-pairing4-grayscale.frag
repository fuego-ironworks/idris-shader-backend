#version 300 es
precision highp float;
precision highp int;

uniform float u_covector_coordinates[4];
uniform float u_vector_coordinates[4];
layout(location = 0) out vec4 _idris_fragColor;

void main() {
  float _idris_t0 = u_covector_coordinates[int(0.0)];
  float _idris_t1 = u_vector_coordinates[int(0.0)];
  float _idris_t2 = (_idris_t0 * _idris_t1);
  float _idris_t3 = (0.0 + _idris_t2);
  float _idris_t4 = u_covector_coordinates[int(1.0)];
  float _idris_t5 = u_vector_coordinates[int(1.0)];
  float _idris_t6 = (_idris_t4 * _idris_t5);
  float _idris_t7 = (_idris_t3 + _idris_t6);
  float _idris_t8 = u_covector_coordinates[int(2.0)];
  float _idris_t9 = u_vector_coordinates[int(2.0)];
  float _idris_t10 = (_idris_t8 * _idris_t9);
  float _idris_t11 = (_idris_t7 + _idris_t10);
  float _idris_t12 = u_covector_coordinates[int(3.0)];
  float _idris_t13 = u_vector_coordinates[int(3.0)];
  float _idris_t14 = (_idris_t12 * _idris_t13);
  float _idris_t15 = (_idris_t11 + _idris_t14);
  vec4 _idris_t16 = vec4(_idris_t15, _idris_t15, _idris_t15, 1.0);
  _idris_fragColor = _idris_t16;
}

