#version 300 es
precision highp float;
precision highp int;
uniform vec2 u_coefficients[24];
in vec2 v_uv;
layout(location = 0) out vec4 fragmentColor;
const float TAU = 6.28318530717958647692;
const float LOG10 = 2.30258509299404568402;
vec2 complexMultiply(vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y,
                a.x * b.y + a.y * b.x);
}
vec2 polynomial(vec2 z) {
    vec2 value = u_coefficients[23];
    value = complexMultiply(value, z) + u_coefficients[22];
    value = complexMultiply(value, z) + u_coefficients[21];
    value = complexMultiply(value, z) + u_coefficients[20];
    value = complexMultiply(value, z) + u_coefficients[19];
    value = complexMultiply(value, z) + u_coefficients[18];
    value = complexMultiply(value, z) + u_coefficients[17];
    value = complexMultiply(value, z) + u_coefficients[16];
    value = complexMultiply(value, z) + u_coefficients[15];
    value = complexMultiply(value, z) + u_coefficients[14];
    value = complexMultiply(value, z) + u_coefficients[13];
    value = complexMultiply(value, z) + u_coefficients[12];
    value = complexMultiply(value, z) + u_coefficients[11];
    value = complexMultiply(value, z) + u_coefficients[10];
    value = complexMultiply(value, z) + u_coefficients[9];
    value = complexMultiply(value, z) + u_coefficients[8];
    value = complexMultiply(value, z) + u_coefficients[7];
    value = complexMultiply(value, z) + u_coefficients[6];
    value = complexMultiply(value, z) + u_coefficients[5];
    value = complexMultiply(value, z) + u_coefficients[4];
    value = complexMultiply(value, z) + u_coefficients[3];
    value = complexMultiply(value, z) + u_coefficients[2];
    value = complexMultiply(value, z) + u_coefficients[1];
    value = complexMultiply(value, z);
    return value;
}
float srgbComponent(float linearValue) {
    float value = max(linearValue, 0.0);
    if (value <= 0.0031308) return 12.92 * value;
    return 1.055 * pow(value, 1.0 / 2.4) - 0.055;
}
vec3 hclToSrgb(float hueDegrees, float chroma, float lightness) {
    const float whiteUPrime = 0.19783982482140777;
    const float whiteVPrime = 0.46833630293240974;
    float hue = radians(hueDegrees);
    float uStar = chroma * cos(hue);
    float vStar = chroma * sin(hue);
    float y = lightness > 8.0
        ? pow((lightness + 16.0) / 116.0, 3.0)
        : lightness / 903.2962962962963;
    float uPrime = uStar / (13.0 * lightness) + whiteUPrime;
    float vPrime = vStar / (13.0 * lightness) + whiteVPrime;
    float x = (9.0 * y * uPrime) / (4.0 * vPrime);
    float z = y * (12.0 - 3.0 * uPrime - 20.0 * vPrime) /
              (4.0 * vPrime);
    vec3 linearRgb = vec3(
         3.2404542 * x - 1.5371385 * y - 0.4985314 * z,
        -0.9692660 * x + 1.8760108 * y + 0.0415560 * z,
         0.0556434 * x - 0.2040259 * y + 1.0572252 * z);
    return clamp(vec3(srgbComponent(linearRgb.r),
                      srgbComponent(linearRgb.g),
                      srgbComponent(linearRgb.b)), 0.0, 1.0);
}
vec3 wegertColor(vec2 value) {
    float phase = all(equal(value, vec2(0.0))) ? 0.0 : atan(value.y, value.x);
    float magnitude = max(length(value), 1.0e-12);
    float hueDegrees = 360.0 * fract(phase / TAU);
    float modulusBand = fract(log(magnitude) / LOG10);
    float lightness = 66.0 + 4.0 * modulusBand
        + 3.0 * fract(hueDegrees / 100.0);
    return hclToSrgb(hueDegrees, 45.0, lightness);
}
void main() {
    vec2 z = vec2(mix(-0.44, 0.44, v_uv.x),
                  mix(-0.88, 0.88, v_uv.y));
    fragmentColor = vec4(wegertColor(polynomial(z)), 1.0);
}

