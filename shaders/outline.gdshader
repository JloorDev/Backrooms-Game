shader_type canvas_item;

uniform float outline_width : hint_range(0.5, 4.0) = 1.0;
uniform vec4 outline_color : source_color = vec4(6.0, 6.0, 6.0, 1.0);

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * outline_width;
	float alpha = texture(TEXTURE, UV).a;

	if (alpha < 0.5) {
		float neighbors =
			texture(TEXTURE, UV + vec2(px.x, 0.0)).a +
			texture(TEXTURE, UV - vec2(px.x, 0.0)).a +
			texture(TEXTURE, UV + vec2(0.0, px.y)).a +
			texture(TEXTURE, UV - vec2(0.0, px.y)).a;

		COLOR = neighbors > 0.0 ? outline_color : vec4(0.0);
	} else {
		COLOR = vec4(0.0);
	}
}
