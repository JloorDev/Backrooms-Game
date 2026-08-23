shader_type canvas_item;

uniform bool invert_side = false;
uniform vec3 outside_tint : source_color = vec3(0.6, 0.65, 0.75);
uniform float outside_darkness : hint_range(0.0, 0.5) = 0.15;
uniform bool use_room_side = true;

uniform vec2 shadow_point = vec2(9999.0, 9999.0);
uniform vec2 shadow_radius = vec2(9.0, 22.0);
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	vec2 delta = (local_pos - shadow_point) / max(shadow_radius, vec2(0.01));
	float dist = length(delta);
	float patch = 1.0 - smoothstep(0.0, 1.0, dist);
	float darken = patch * shadow_strength;

	COLOR = vec4(tex_color.rgb * (1.0 - darken), tex_color.a);
}

void light() {
	float ndotl = max(dot(NORMAL, LIGHT_DIRECTION), 0.0);
	vec3 lit_color = COLOR.rgb * LIGHT_COLOR.rgb * LIGHT_ENERGY * ndotl;
	vec3 final_color;

	if (use_room_side) {
		float side = smoothstep(-0.15, 0.15, LIGHT_DIRECTION.y);
		if (invert_side) {
			side = 1.0 - side;
		}
		vec3 dark_color = COLOR.rgb * outside_tint * outside_darkness;
		final_color = mix(dark_color, lit_color, side);
	} else {
		final_color = lit_color;
	}

	LIGHT = vec4(final_color, COLOR.a * LIGHT_COLOR.a);
}