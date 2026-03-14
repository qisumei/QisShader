#version 330
/* DRAWBUFFERS:01 */

uniform sampler2D gtexture;
uniform sampler2D shadowtex0;
uniform vec3 shadowLightPosition;

in vec2 texCoord;
in vec4 glColor;
in vec4 shadowSpacePos;
in vec2 lightMapCoords;
in vec3 normal;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outData;

float getNoise(vec2 pos) { return fract(52.9829189 * fract(dot(pos, vec2(0.06711056, 0.00583715)))); }

void main() {
    vec4 color = texture(gtexture, texCoord) * glColor;
    if (color.a < 0.1) discard;
    color.rgb = pow(color.rgb, vec3(2.2));

    float blockLight = lightMapCoords.x;
    float skyLight = lightMapCoords.y;
    vec3 shadowNDC = shadowSpacePos.xyz / shadowSpacePos.w;
    vec3 shadowUV = shadowNDC * 0.5 + 0.5;
    float sunVisibility = 0.0;

    vec3 finalNormal = length(normal) > 0.01 ? normalize(normal) : vec3(0.0, 1.0, 0.0);
    vec3 l = normalize(shadowLightPosition);
    float NdotL = max(dot(finalNormal, l), 0.0);

    if (skyLight > 0.05 && NdotL > 0.0) {
        if (shadowUV.x >= 0.0 && shadowUV.x <= 1.0 && shadowUV.y >= 0.0 && shadowUV.y <= 1.0) {
            float distortionFactor = length(shadowNDC.xy) * 0.9 + 0.1;
            float currentBias = 0.002 * tan(acos(NdotL));
            currentBias = clamp(currentBias, 0.0005, 0.01) * distortionFactor;
            float spread = 3.0;
            vec2 texelSize = spread / vec2(textureSize(shadowtex0, 0));
            float noise_val = getNoise(gl_FragCoord.xy);
            float angle = noise_val * 6.2831853;
            float totalShadow = 0.0;
            int samples = 8;
            for(int i = 0; i < samples; i++) {
                float theta = float(i) * 2.39996323 + angle;
                float r = sqrt(float(i) + 0.5) / sqrt(float(samples));
                vec2 offset = vec2(cos(theta), sin(theta)) * r * texelSize;
                float shadowDepth = texture(shadowtex0, shadowUV.xy + offset).r;
                if (shadowUV.z - currentBias > shadowDepth) totalShadow += 1.0;
            }
            totalShadow /= float(samples);
            sunVisibility = 1.0 - totalShadow;
        }
    }

    float ambient = 0.05 + skyLight * 0.15;
    float torchLight = blockLight * 0.6;
    float sunLight = skyLight * sunVisibility * NdotL * 0.8;
    float finalLight = min(ambient + torchLight + sunLight, 1.0);

    outColor = vec4(color.rgb * finalLight, color.a);
    outData = vec4(0.0, 0.0, 0.0, 1.0);
}