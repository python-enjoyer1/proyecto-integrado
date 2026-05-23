uniform vec2 u_resolution;
uniform float u_shadow_alpha;
uniform vec2 u_offset;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = (screen_coords * u_resolution.xy) / u_resolution.y;
    float shadow_alpha = Texel(tex, uv + u_offset).a * u_shadow_alpha;
    vec4 texture = Texel(tex, uv);

    return mix(vec4(0.0, 0.0, 0.0, shadow_alpha), texture, texture.a);
}