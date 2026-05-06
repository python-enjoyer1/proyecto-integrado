#define PIXEL_FILTER 745.0

uniform vec2 resolution;
uniform float time;


vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(tex, texture_coords);

    vec2 normalized_coords = screen_coords / resolution.xy;

    pixel.r = normalized_coords.x * cos(time);
    pixel.g = normalized_coords.y * sin(time);
    pixel.b = 0.0;

    return pixel * color;
}