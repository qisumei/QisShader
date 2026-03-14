#version 330

in vec3 vaPosition;
in vec2 vaUV0;
in vec4 vaColor;
in ivec2 vaUV2;
in vec3 vaNormal;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat3 normalMatrix;

out vec2 texCoord;
out vec4 glColor;
out vec2 lightMapCoords;
out vec3 normal;

void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(vaPosition, 1.0);

    texCoord = vaUV0;
    glColor = vaColor;
    lightMapCoords = vaUV2 / 240.0;
    normal = normalMatrix * vaNormal;
}