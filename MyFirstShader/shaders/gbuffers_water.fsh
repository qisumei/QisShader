#version 330 compatibility
/* DRAWBUFFERS:01 */

uniform sampler2D gtexture;
uniform sampler2D shadowtex0;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

in vec2 texCoord;
in vec4 glColor;
in vec4 shadowSpacePos;
in vec2 lightMapCoords;
in vec3 normalView;

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

    vec3 nView = normalize(normalView);

    vec3 playerPos = (gbufferModelViewInverse * vec4(texCoord * 2.0 - 1.0, 1.0, 1.0)).xyz;
    vec3 worldPosStr = cameraPosition + playerPos;
    float time = frameTimeCounter * 2.0;
    float waveX = sin(worldPosStr.x * 2.0 + time) * 0.05 + sin(worldPosStr.x * 4.0 - time * 1.5) * 0.02;
    float waveZ = cos(worldPosStr.z * 2.0 + time) * 0.05 + cos(worldPosStr.z * 4.0 - time * 1.5) * 0.02;
    vec3 waveNormWorld = normalize(vec3(waveX, 1.0, waveZ));
    vec3 waveNormView = normalize(mat3(gbufferModelView) * waveNormWorld);

    nView = normalize(mix(nView, waveNormView, 0.8));

    vec3 l = normalize(shadowLightPosition);
    float NdotL = max(dot(nView, l), 0.0);
    float sunVisibility = 0.0;

    if (skyLight > 0.05 && NdotL > 0.0) {
        if (shadowUV.x >= 0.0 && shadowUV.x <= 1.0 && shadowUV.y >= 0.0 && shadowUV.y <= 1.0) {
            float distortionFactor = length(shadowNDC.xy) * 0.9 + 0.1;
            float currentBias = clamp(0.001 * tan(acos(NdotL)), 0.0002, 0.005) * distortionFactor;
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
    vec3 torchLight = vec3(1.0, 0.65, 0.25) * blockLight * 0.9;
    vec3 sunLight = vec3(1.0, 0.95, 0.9) * skyLight * sunVisibility * NdotL * 0.8;

    outColor = vec4(color.rgb * min(ambient + torchLight + sunLight, vec3(1.0)), color.a);
    outData = vec4(0.85, nView.x, nView.y, nView.z);
}