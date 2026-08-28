shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 0.9);
uniform float outline_width : hint_range(0.5, 4.0) = 1.2;
uniform bool outline_enabled = false;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = tex_color;

	if (outline_enabled && tex_color.a <= 0.5) {
		vec2 px = TEXTURE_PIXEL_SIZE * outline_width;
		float neighbors =
			texture(TEXTURE, UV + vec2(px.x, 0.0)).a +
			texture(TEXTURE, UV - vec2(px.x, 0.0)).a +
			texture(TEXTURE, UV + vec2(0.0, px.y)).a +
			texture(TEXTURE, UV - vec2(0.0, px.y)).a;

		if (neighbors > 0.0) {
			COLOR = outline_color;
		}
	}
}
