#version 330 compatibility

attribute vec2 mc_Entity;

uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

out vec2 texCoord;
out vec4 glColor;
out vec2 lightMapCoords;
out vec3 normalView;
out vec4 shadowSpacePos;
flat out int matId;

vec2 distort(vec2 pos) {
    float centerDistance = length(pos);
    return pos / (centerDistance * 0.9 + 0.1);
}

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = gl_ProjectionMatrix * viewPos;

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor = gl_Color;
    lightMapCoords = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    normalView = normalize(gl_NormalMatrix * gl_Normal);

    vec4 playerPos = gbufferModelViewInverse * viewPos;
    shadowSpacePos = shadowProjection * shadowModelView * playerPos;
    shadowSpacePos.xy = distort(shadowSpacePos.xy);
    shadowSpacePos.z *= 0.2;

    matId = int(mc_Entity.x);
}