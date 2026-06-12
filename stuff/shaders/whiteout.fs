vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(tex, texture_coords);
    pixel.r = 1;
    pixel.g = 1;
    pixel.b = 1;
    return pixel * color;
}