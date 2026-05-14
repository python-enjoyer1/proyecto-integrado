uniform vec2 resolution;
uniform float time;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / resolution;

    float special_time = cos(time) + 0.1;

    float random = fract(sin(dot(uv * special_time, vec2(12.9898, 78.233))) * 43758.5453);
    random += (uv.x - uv.y) * 1.5;

    uv.x -= cos(special_time + random);
    uv.y += sin(special_time - random);

    vec4 pixel = Texel(tex, uv);

    pixel.r -= sin(special_time + random) / 2;
    color.g -= cos(special_time / random) / 88;
    color.b += sin(special_time - random) / 35;

    color.r -= 3.1415 - cos(special_time * random);
    color.g -= 0.6 / sin(random - special_time) / 3 * 67;
    color.b -= 5 / cos(special_time / random - special_time);

    return pixel * color;
}