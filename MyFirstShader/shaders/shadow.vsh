#version 330 compatibility

out vec2 texCoord;
out vec4 glColor;

vec2 distort(vec2 pos) {
    float centerDistance = length(pos);
    float distortionFactor = centerDistance * 0.9 + 0.1;
    return pos / distortionFactor;
}

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 projPos = gl_ProjectionMatrix * viewPos;

    projPos.xy = distort(projPos.xy);
    projPos.z *= 0.2;

    gl_Position = projPos;

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor = gl_Color;
}