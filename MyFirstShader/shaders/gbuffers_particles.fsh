#version 330 compatibility
/* DRAWBUFFERS:01 */

uniform sampler2D gtexture;
uniform sampler2D shadowtex0;

in vec2 texCoord;
in vec4 glColor;
in vec2 lightMapCoords;
in vec4 shadowSpacePos;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outData;

void main() {
    vec4 color = texture(gtexture, texCoord) * glColor;
    if (color.a < 0.1) discard;
    color.rgb = pow(color.rgb, vec3(2.2));

    float blockLight = lightMapCoords.x;
    float skyLight = lightMapCoords.y;

    vec3 shadowNDC = shadowSpacePos.xyz / shadowSpacePos.w;
    vec3 shadowUV = shadowNDC * 0.5 + 0.5;
    float sunVisibility = 1.0;

    if (skyLight > 0.05) {
        if (shadowUV.x >= 0.0 && shadowUV.x <= 1.0 && shadowUV.y >= 0.0 && shadowUV.y <= 1.0) {
            float shadowDepth = texture(shadowtex0, shadowUV.xy).r;
            if (shadowUV.z - 0.002 > shadowDepth) {
                sunVisibility = 0.0;
            }
        }
    }

    float ambient = 0.05 + skyLight * 0.15;
    float torchLight = blockLight * 0.6;
    float sunLight = skyLight * sunVisibility * 0.8;
    float finalLight = min(ambient + torchLight + sunLight, 1.0);

    outColor = vec4(color.rgb * finalLight, color.a);
    outData = vec4(0.0, 0.0, 0.0, 1.0);
}