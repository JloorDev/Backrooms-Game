shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 10.0) = 3.0;
uniform vec4 tint_color : source_color = vec4(0.1, 0.1, 0.09, 0.45);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 color = vec4(0.0);
	float total = 0.0;

	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			vec2 offset = vec2(float(x), float(y)) * blur_amount * SCREEN_PIXEL_SIZE;
			color += texture(SCREEN_TEXTURE, uv + offset);
			total += 1.0;
		}
	}

	color /= total;
	COLOR = mix(color, vec4(tint_color.rgb, 1.0), tint_color.a);
	COLOR.a = 1.0;
}
