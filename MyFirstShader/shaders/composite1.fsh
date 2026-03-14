#version 330
/* DRAWBUFFERS:01 */

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;
in vec2 texCoord;
layout(location = 0) out vec4 outColor;

float getDitherNoise(vec2 pos) { return fract(52.9829189 * fract(dot(pos, vec2(0.06711056, 0.00583715)))); }
vec3 ACESFilm(vec3 x) { return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0); }

void main() {
    vec2 offsetDist = texCoord - 0.5;
    vec3 color;
    color.r = texture(colortex0, texCoord - offsetDist * 0.005).r;
    color.g = texture(colortex0, texCoord).g;
    color.b = texture(colortex0, texCoord + offsetDist * 0.005).b;
    
    vec3 bloom = vec3(0.0); float weightSum = 0.0;
    float dither = getDitherNoise(gl_FragCoord.xy) * 6.2831853;
    vec2 aspect = vec2(viewHeight / viewWidth, 1.0);
    for(int i = 1; i <= 48; i++) {
        float r = float(i) / 48.0; float w = exp(-r * 8.0); weightSum += w;
        vec2 off = vec2(cos(float(i)*2.39996+dither), sin(float(i)*2.39996+dither)) * pow(r, 1.5) * 0.25 * aspect;
        vec3 sCol = texture(colortex0, texCoord + off).rgb;
        if (dot(sCol, vec3(0.21, 0.72, 0.07)) > 0.85) bloom += sCol * w;
    }
    color += (bloom / max(weightSum, 0.001)) * 1.2;
    color = ACESFilm(color * 1.2);
    color = pow(color, vec3(1.05)) * mix(vec3(1.0), vec3(smoothstep(0.85, 0.2, length(texCoord-0.5))), 0.5);

    color = pow(color, vec3(1.0 / 2.2));

    float noise = getDitherNoise(gl_FragCoord.xy);
    color += (noise - 0.5) / 255.0;

    outColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}