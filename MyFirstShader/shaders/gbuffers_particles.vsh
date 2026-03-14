#version 330 compatibility
/* DRAWBUFFERS:01 */

uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

out vec2 texCoord;
out vec4 glColor;
out vec2 lightMapCoords;
out vec4 shadowSpacePos;

vec2 distort(vec2 pos) {
    float centerDistance = length(pos);
    float distortionFactor = centerDistance * 0.9 + 0.1;
    return pos / distortionFactor;
}

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = gl_ProjectionMatrix * viewPos;

    vec4 playerPos = gbufferModelViewInverse * viewPos;
    shadowSpacePos = shadowProjection * shadowModelView * playerPos;
    shadowSpacePos.xy = distort(shadowSpacePos.xy);
    shadowSpacePos.z *= 0.2;

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor = gl_Color;

    lightMapCoords = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}