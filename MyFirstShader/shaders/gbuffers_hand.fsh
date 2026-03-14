#version 330
/* DRAWBUFFERS:01 */

uniform sampler2D gtexture;
uniform vec3 shadowLightPosition;

in vec2 texCoord;
in vec4 glColor;
in vec2 lightMapCoords;
in vec3 normal;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outData;

void main() {
    vec4 color = texture(gtexture, texCoord) * glColor;
    if (color.a < 0.1) discard;
    color.rgb = pow(color.rgb, vec3(2.2));

    float blockLight = lightMapCoords.x;
    float skyLight = lightMapCoords.y;

    vec3 finalNormal = length(normal) > 0.01 ? normalize(normal) : vec3(0.0, 1.0, 0.0);
    vec3 l = normalize(shadowLightPosition);
    float NdotL = max(dot(finalNormal, l), 0.0);
    float sunVisibility = 1.0;

    float ambient = 0.05 + skyLight * 0.15;
    float torchLight = blockLight * 0.6;
    float sunLight = skyLight * sunVisibility * NdotL * 0.8;
    float finalLight = min(ambient + torchLight + sunLight, 1.0);

    outColor = vec4(color.rgb * finalLight, color.a);
    outData = vec4(0.0, 0.0, 0.0, 1.0);
}