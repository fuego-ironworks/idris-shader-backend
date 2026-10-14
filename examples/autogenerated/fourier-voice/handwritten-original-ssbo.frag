#version 310 es
precision highp float;
precision highp int;
layout(std430, binding = 0) readonly buffer Spectrum {
    vec2 coefficients[];
};
uniform uint uTermCount;
uniform vec2 uRadius;
in vec2 vUv;
layout(location = 0) out vec4 fragmentColor;
const float TAU = 6.28318530717958647692;
const float LOG10 = 2.30258509299404568402;
vec2 complexMultiply(vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y,
                a.x * b.y + a.y * b.x);
}
vec2 polynomial(vec2 z) {
    vec2 value = vec2(0.0);
    for (uint remaining = uTermCount; remaining > 0u; --remaining) {
        uint k = remaining - 1u;
        vec2 coefficient = k == 0u ? vec2(0.0) : coefficients[k];
        value = complexMultiply(value, z) + coefficient;
    }
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
    float phase = atan(value.y, value.x);
    float magnitude = max(length(value), 1.0e-12);
    float hueDegrees = 360.0 * fract(phase / TAU);
    float modulusBand = fract(log(magnitude) / LOG10);
    float lightness = 66.0 + 4.0 * modulusBand
        + 3.0 * fract(hueDegrees / 100.0);
    return hclToSrgb(hueDegrees, 45.0, lightness);
}
void main() {
    vec2 z = vec2(mix(-uRadius.x, uRadius.x, vUv.x),
                  mix(-uRadius.y, uRadius.y, vUv.y));
    fragmentColor = vec4(wegertColor(polynomial(z)), 1.0);
}

