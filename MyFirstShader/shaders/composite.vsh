#version 150

in vec3 vaPosition;
in vec2 vaUV0;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

out vec2 texCoord;

void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(vaPosition, 1.0);
    texCoord = vaUV0;
}