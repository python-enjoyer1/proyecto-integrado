uniform vec2 resolution;
uniform float time;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    float special_time = time * 0.000001;

    vec2 uv = screen_coords / resolution;
    vec4 dim = vec4(0.3, 0.3, 0.3, 1.0);

    uv.x += cos(special_time);
    uv.y += sin(special_time);

    vec4 pixel = Texel(tex, uv);

    float random = fract(sin(dot(uv * (special_time), vec2(12.9898, 78.233))) * 43758.5453);

    pixel.r += cos(random);
    pixel.b += sin(random);

    color.r += cos(uv.x - special_time);
    color.b += sin(uv.y - special_time);

    return pixel * (color * dim);
}