uniform float time;
uniform vec2 window_coords;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(tex, texture_coords);
    vec2 uv = screen_coords / window_coords;

    float random = fract(sin(dot(uv + time, vec2(12.9898, 78.233))) * 43758.5453); // No built-in random function, so you have to do some simulation.

    return vec4(random, random, random, pixel.a);
}