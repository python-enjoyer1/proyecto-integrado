uniform vec2 offset;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    float r = Texel(tex, texture_coords + offset).r;
    float g = Texel(tex, texture_coords).g;
    float b = Texel(tex, texture_coords - offset).b;

    return vec4(r, g, b, 1.0) * color;
}