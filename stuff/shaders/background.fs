// I hate shaders.
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    return vec4(1, 1, 1, 1);
}

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    return vec4(1, 1, 1, 1);
}