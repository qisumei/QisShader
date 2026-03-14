#version 330
/* DRAWBUFFERS:01 */

uniform sampler2D gtexture;
uniform sampler2D shadowtex0;
uniform vec3 shadowLightPosition;
uniform vec4 entityColor;

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
    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
    color.rgb = pow(color.rgb, vec3(2.2));

    float blockLight = lightMapCoords.x;
    float skyLight = lightMapCoords.y;
    vec3 shadowNDC = shadowSpacePos.xyz / shadowSpacePos.w;
    vec3 shadowUV = shadowNDC * 0.5 + 0.5;
    float sunVisibility = 0.0;

    vec3 l = normalize(shadowLightPosition);
    float NdotL = max(dot(normalize(normal), l), 0.0);

    if (skyLight > 0.05 && NdotL > 0.0) {
        if (shadowUV.x >= 0.0 && shadowUV.x <= 1.0 && shadowUV.y >= 0.0 && shadowUV.y <= 1.0) {
            float currentBias = clamp(0.002 * tan(acos(NdotL)), 0.0005, 0.01);
            vec2 texelSize = 3.0 / vec2(textureSize(shadowtex0, 0));
            float angle = getNoise(gl_FragCoord.xy) * 6.2831853;
            float totalShadow = 0.0;
            for(int i = 0; i < 8; i++) {
                float theta = float(i) * 2.39996323 + angle;
                float r = sqrt(float(i) + 0.5) / sqrt(8.0);
                vec2 offset = vec2(cos(theta), sin(theta)) * r * texelSize;
                if (shadowUV.z - currentBias > texture(shadowtex0, shadowUV.xy + offset).r) totalShadow += 1.0;
            }
            sunVisibility = 1.0 - totalShadow / 8.0;
        }
    }

    vec3 ambient = vec3(0.05 + skyLight * 0.15);
    vec3 torchColor = vec3(1.0, 0.65, 0.25);
    vec3 torchLight = torchColor * blockLight * 0.9;
    vec3 sunLight = vec3(1.0, 0.95, 0.9) * skyLight * sunVisibility * NdotL * 0.8;
    vec3 finalLight = min(ambient + torchLight + sunLight, vec3(1.0));

    outColor = vec4(color.rgb * finalLight, color.a);
    outData = vec4(0.0, 0.0, 0.0, 1.0);
}