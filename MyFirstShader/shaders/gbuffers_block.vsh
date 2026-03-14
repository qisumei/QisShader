#version 330

in vec3 vaPosition;
in vec2 vaUV0;
in vec4 vaColor;
in ivec2 vaUV2;
in vec3 vaNormal;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat3 normalMatrix;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

out vec2 texCoord;
out vec4 glColor;
out vec4 shadowSpacePos;
out vec2 lightMapCoords;
out vec3 normal;

vec2 distort(vec2 pos) {
    float centerDistance = length(pos);
    float distortionFactor = centerDistance * 0.9 + 0.1;
    return pos / distortionFactor;
}

void main() {
    vec4 viewPos = modelViewMatrix * vec4(vaPosition, 1.0);
    gl_Position = projectionMatrix * viewPos;

    vec4 playerPos = gbufferModelViewInverse * viewPos;
    shadowSpacePos = shadowProjection * shadowModelView * playerPos;
    shadowSpacePos.xy = distort(shadowSpacePos.xy);
    shadowSpacePos.z *= 0.2;

    texCoord = vaUV0;
    glColor = vaColor;
    lightMapCoords = vaUV2 / 240.0;
    normal = normalMatrix * vaNormal;
}