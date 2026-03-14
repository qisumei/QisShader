#version 330
/* DRAWBUFFERS:01 */

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texCoord;
layout(location = 0) out vec4 outColor;

float getDitherNoise(vec2 pos) { return fract(52.9829189 * fract(dot(pos, vec2(0.06711056, 0.00583715)))); }

vec3 getViewPos(vec2 uv) {
    vec4 ndc = vec4(uv * 2.0 - 1.0, texture(depthtex0, uv).r * 2.0 - 1.0, 1.0);
    vec4 view = gbufferProjectionInverse * ndc;
    return view.xyz / view.w;
}

vec3 renderSky(vec3 viewDir, vec3 sunDir) {
    float viewElev = max(viewDir.y, 0.0);
    vec3 zenithColor = mix(vec3(0.01, 0.02, 0.05), mix(vec3(0.20, 0.25, 0.60), vec3(0.05, 0.15, 0.45), clamp(sunDir.y * 2.5 + 0.2, 0.0, 1.0)), clamp(sunDir.y * 2.5 + 0.2, 0.0, 1.0) + clamp(1.0 - abs(sunDir.y) * 2.5, 0.0, 1.0));
    vec3 horizonColor = mix(vec3(0.05, 0.08, 0.15), mix(vec3(1.00, 0.35, 0.10), vec3(0.40, 0.55, 0.70), clamp(sunDir.y * 2.5 + 0.2, 0.0, 1.0)), clamp(sunDir.y * 2.5 + 0.2, 0.0, 1.0) + clamp(1.0 - abs(sunDir.y) * 2.5, 0.0, 1.0));
    return mix(horizonColor, zenithColor, pow(viewElev, 0.4));
}

void main() {
    vec3 baseColor = texture(colortex0, texCoord).rgb;
    float depth = texture(depthtex0, texCoord).r;
    vec3 viewDir = normalize((gbufferProjectionInverse * vec4(texCoord * 2.0 - 1.0, 1.0, 1.0)).xyz);
    vec3 worldDir = normalize((gbufferModelViewInverse * vec4(viewDir, 0.0)).xyz);
    vec3 trueSunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    float dither = getDitherNoise(gl_FragCoord.xy);

    if (depth == 1.0) {
        baseColor = renderSky(worldDir, trueSunDir);
    } else {
        vec3 viewPos = getViewPos(texCoord);

        vec4 gData = texture(colortex1, texCoord);
        float metallic = gData.r;
        vec3 normalView = length(gData.yzw) > 0.1 ? normalize(gData.yzw) : vec3(0.0, 1.0, 0.0);

        if (metallic > 0.05 || (normalize(mat3(gbufferModelViewInverse) * normalView).y > 0.5 && rainStrength > 0.0)) {

            vec3 reflectDir = normalize(reflect(normalize(viewPos), normalView));
            vec3 marchPos = viewPos + normalView * 0.1;
            vec3 step = reflectDir * 0.15;
            marchPos += step * dither;

            bool hit = false;
            for(int i = 0; i < 64; i++) {
                marchPos += step;
                vec4 p = gbufferProjection * vec4(marchPos, 1.0);
                if (p.w <= 0.0) break;
                vec2 sUV = p.xy / p.w * 0.5 + 0.5;
                if(sUV.x < 0.0 || sUV.x > 1.0 || sUV.y < 0.0 || sUV.y > 1.0) break;

                float dDiff = marchPos.z - getViewPos(sUV).z;
                float thickness = max(0.2, length(step) * 1.5);
                if(dDiff < 0.0 && dDiff > -thickness) { hit = true; break; }
                step *= 1.02;
            }

            vec3 refCol = vec3(0.0);
            float mask = 0.0;

            if(hit) {
                for(int i = 0; i < 8; i++) {
                    step *= 0.5;
                    vec4 p = gbufferProjection * vec4(marchPos, 1.0);
                    if(marchPos.z - getViewPos(p.xy / p.w * 0.5 + 0.5).z < 0.0) marchPos -= step; else marchPos += step;
                }
                vec2 fUV = (gbufferProjection * vec4(marchPos, 1.0)).xy / (gbufferProjection * vec4(marchPos, 1.0)).w * 0.5 + 0.5;
                refCol = texture(colortex0, fUV).rgb;
                vec2 edge = smoothstep(0.0, 0.08, fUV) * smoothstep(1.0, 0.92, fUV);
                mask = edge.x * edge.y;
            }

            vec3 wRefDir = normalize(mat3(gbufferModelViewInverse) * reflectDir);
            vec3 skyRefCol = renderSky(wRefDir, trueSunDir);

            if (metallic > 0.8 && length(skyRefCol) > 0.1) {
                skyRefCol *= clamp(wRefDir.y * 5.0, 0.0, 1.0);
            }
            refCol = mix(skyRefCol, refCol, mask);

            float VdotN = max(dot(-normalize(viewPos), normalView), 0.0);
            float f0 = metallic > 0.1 ? 0.8 : 0.02;
            float fresnel = f0 + (1.0 - f0) * pow(1.0 - VdotN, 5.0);
            float reflectPower = metallic < 0.05 ? 0.3 * rainStrength : metallic;

            baseColor = mix(baseColor, refCol, fresnel * reflectPower);
        }
    }
    outColor = vec4(baseColor, 1.0);
}