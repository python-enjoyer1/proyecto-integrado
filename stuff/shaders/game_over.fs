uniform vec2 resolution;
uniform float time;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = (screen_coords - 0.5 * resolution.xy) / resolution.y;

    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    float spiral1 = sin(angle * 5.0 - time * 0.5 + dist + 15.0);
    float spiral2 = sin(angle * 7.0 - time * 0.3 + dist + 12.0);
    float spiral3 = sin(angle * 3.0 - time * 0.2 + dist + 10.0);

    float pattern = spiral1 * 0.4 + spiral2 * 0.3 + spiral3 * 0.3;

    float liquid_flow1 = sin(dist * 8.0 - time * 1.5) * cos(angle * 4.0);
    float liquid_flow2 = sin(angle * 6.0 + time * 0.8) * 0.3;
    float liquid_flow = liquid_flow1 + liquid_flow2;

    float edge = smoothstep(0.0, 0.1, abs(pattern + liquid_flow * 0.5));

    float radial_intensity = exp(-dist * 2.5) * 0.8;

    float intensity = edge * (1.0 - smoothstep(0.0, 0.8, dist)) + radial_intensity;

    float morphing = sin(uv.y * 40.0 + time * 1.6) * 0.15;
    intensity += morphing * smoothstep(0.5, 0.0, dist);

    vec3 white_core = vec3(1.0);
    vec3 gray_shade = mix(vec3(0.7), vec3(1.0), smoothstep(0.3, 0.0, dist));

    intensity = clamp(intensity, 0.0, 1.0);

    vec3 spiral_color = mix(vec3(0.0), gray_shade, intensity);

    float glow_edge = smoothstep(0.15, 1.05, abs(pattern + liquid_flow * 0.4));
    spiral_color = mix(spiral_color, vec3(1.0), glow_edge * 0.3);

    return vec4(spiral_color, 1.0);
}