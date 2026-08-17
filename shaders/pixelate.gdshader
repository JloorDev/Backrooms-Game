shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;

void fragment() {
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 pixel_uv = floor(SCREEN_UV * screen_size / pixel_size) * pixel_size + pixel_size * 0.5;
	COLOR = texture(SCREEN_TEXTURE, pixel_uv / screen_size);
}