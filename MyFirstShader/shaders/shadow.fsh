#version 330 compatibility
/* DRAWBUFFERS:0 */

uniform sampler2D tex;

in vec2 texCoord;
in vec4 glColor;

layout(location = 0) out vec4 outShadowColor;

void main() {
    vec4 color = texture(tex, texCoord) * glColor;
    if (color.a < 0.1) discard;
    color.rgb = pow(color.rgb, vec3(2.2));

    outShadowColor = vec4(color.rgb, 1.0);
}