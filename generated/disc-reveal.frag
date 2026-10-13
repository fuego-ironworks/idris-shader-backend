#version 300 es
precision highp float;
precision highp int;

in vec2 v_ndc;
uniform vec2 u_center;
uniform float u_half_height;
uniform float u_aspect;
uniform vec2 u_disc_center;
uniform float u_disc_radius;
uniform vec2 u_resolution;
layout(location = 0) out vec4 _idris_fragColor;

void main() {
  float _idris_t0 = u_center.x;
  float _idris_t1 = v_ndc.x;
  float _idris_t2 = (_idris_t1 * u_half_height);
  float _idris_t3 = (_idris_t2 * u_aspect);
  float _idris_t4 = (_idris_t0 + _idris_t3);
  float _idris_t5 = u_center.y;
  float _idris_t6 = v_ndc.y;
  float _idris_t7 = (_idris_t6 * u_half_height);
  float _idris_t8 = (_idris_t5 + _idris_t7);
  float _idris_t9 = u_disc_center.x;
  float _idris_t10 = (_idris_t4 - _idris_t9);
  float _idris_t11 = u_disc_center.y;
  float _idris_t12 = (_idris_t8 - _idris_t11);
  float _idris_t13 = (_idris_t10 * _idris_t10);
  float _idris_t14 = (_idris_t12 * _idris_t12);
  float _idris_t15 = (_idris_t13 + _idris_t14);
  float _idris_t16 = sqrt(_idris_t15);
  float _idris_t17 = (2.0 * u_half_height);
  float _idris_t18 = u_resolution.y;
  float _idris_t19 = max(1.0, _idris_t18);
  float _idris_t20 = (_idris_t17 / _idris_t19);
  float _idris_t21 = (2.0 * _idris_t20);
  float _idris_t22 = max(1e-5, _idris_t21);
  bool _idris_t23 = (u_disc_radius < 0.0);
  float _idris_t25;
  if (_idris_t23) {
    _idris_t25 = 0.0;
  } else {
    bool _idris_t26 = (1e-5 > u_disc_radius);
    float _idris_t28 = (_idris_t26 ? 1e-5 : u_disc_radius);
    bool _idris_t29 = (1e-5 > _idris_t22);
    float _idris_t31 = (_idris_t29 ? 1e-5 : _idris_t22);
    bool _idris_t32 = (_idris_t28 < _idris_t31);
    float _idris_t34 = (_idris_t32 ? _idris_t28 : _idris_t31);
    float _idris_t35 = (u_disc_radius - _idris_t34);
    float _idris_t36 = (_idris_t16 - _idris_t35);
    float _idris_t37 = (_idris_t36 / _idris_t34);
    bool _idris_t38 = (_idris_t37 < 0.0);
    float _idris_t40;
    if (_idris_t38) {
      _idris_t40 = 0.0;
    } else {
      bool _idris_t41 = (_idris_t37 > 1.0);
      float _idris_t43 = (_idris_t41 ? 1.0 : _idris_t37);
      _idris_t40 = _idris_t43;
    }
    _idris_t25 = _idris_t40;
  }
  float _idris_t45 = (_idris_t1 + 1.0);
  float _idris_t46 = (0.5 * _idris_t45);
  float _idris_t47 = u_resolution.x;
  float _idris_t48 = (_idris_t46 * _idris_t47);
  float _idris_t50 = (_idris_t6 + 1.0);
  float _idris_t51 = (0.5 * _idris_t50);
  float _idris_t53 = (_idris_t51 * _idris_t18);
  float _idris_t54 = (0.173 * _idris_t48);
  float _idris_t55 = sin(_idris_t54);
  float _idris_t56 = (0.137 * _idris_t53);
  float _idris_t57 = sin(_idris_t56);
  float _idris_t58 = (_idris_t55 * _idris_t57);
  float _idris_t59 = (0.5 * _idris_t58);
  float _idris_t60 = (0.5 + _idris_t59);
  float _idris_t61 = (1.0 - _idris_t60);
  float _idris_t62 = (0.035 * _idris_t61);
  float _idris_t63 = (0.055 * _idris_t60);
  float _idris_t64 = (_idris_t62 + _idris_t63);
  vec4 _idris_t65 = vec4(_idris_t64, _idris_t64, _idris_t64, _idris_t25);
  _idris_fragColor = _idris_t65;
}

