uniform vec2 screen_size;

vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
    vec4 pixel = Texel(image, uvs);

    vec2 normalized_screen = vec2(screen_coords.x / screen_size.x, screen_coords.y / screen_size.y);

    return vec4(normalized_screen.xy, 1.0, 1.0) * pixel;
}