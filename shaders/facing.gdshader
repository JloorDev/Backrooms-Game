shader_type canvas_item;

uniform bool invert_side = false;
uniform vec3 outside_tint : source_color = vec3(0.6, 0.65, 0.75);
uniform float outside_darkness : hint_range(0.0, 0.5) = 0.15;

void light() {
	float ndotl = max(dot(NORMAL, LIGHT_DIRECTION), 0.0);

	float side = smoothstep(-0.15, 0.15, LIGHT_DIRECTION.y);
	if (invert_side) {
		side = 1.0 - side;
	}

	vec3 lit_color = COLOR.rgb * LIGHT_COLOR.rgb * LIGHT_ENERGY * ndotl;
	vec3 dark_color = COLOR.rgb * outside_tint * outside_darkness;
	vec3 final_color = mix(dark_color, lit_color, side);

	LIGHT = vec4(final_color, COLOR.a * LIGHT_COLOR.a);
}