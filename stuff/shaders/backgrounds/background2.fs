uniform vec2 resolution;
uniform float time;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / resolution;
    vec4 dim = vec4(0.5, 0.5, 0.5, 0.5);
    float special_time = clamp(1 / (time * 20), 0.01, 1);

    uv.x -= fract(acos(clamp(special_time / 0.05, -1.0, 1.0)));
    uv.y += fract(sin(special_time / 0.03));

    vec4 pixel = Texel(tex, uv);

    float random = fract(sin(dot(uv * special_time, vec2(12.9898, 78.233))) * 43758.5453);

    pixel.r -= fract(asin(clamp(special_time - random * 3.1415, -1.0, 1.0))) / 2;
    color.g /= fract(acos(clamp(special_time / 2.345, -1.0, 1.0))) / 88;
    color.b += fract(atan(random) * 9584) / 35;


    return pixel * color / random * 0.095;
}