shader_type canvas_item;

uniform bool use_room_side = true;
uniform bool invert_side = false;
uniform vec3 outside_tint : source_color = vec3(0.6, 0.65, 0.75);
uniform float outside_darkness : hint_range(0.0, 0.5) = 0.15;

uniform vec2 shadow_point = vec2(9999.0, 9999.0);
uniform vec2 shadow_radius = vec2(9.0, 22.0);
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.0;

uniform bool enable_ao = true;
uniform int ao_step_count : hint_range(1, 16) = 6;
uniform float ao_step_size : hint_range(0.5, 8.0) = 2.0;
uniform float ao_influence : hint_range(0.0, 1.0) = 0.5;

uniform float height_falloff : hint_range(0.0, 0.05) = 0.015;

uniform bool enable_specular = false;
uniform float specular_strength : hint_range(0.0, 2.0) = 0.5;
uniform float specular_shininess : hint_range(1.0, 128.0) = 32.0;

varying vec2 local_pos;
varying vec2 screen_pixel_size;

void vertex() {
	local_pos = VERTEX;
}

float compute_ao(vec2 frag_coord, vec2 screen_uv) {
	vec2 march_pos = frag_coord;
	vec2 norm = texture_sdf_normal(screen_uv_to_sdf(screen_uv));
	float res = 0.0;

	for (int i = 1; i < ao_step_count; i++) {
		vec2 rp = march_pos + ao_step_size * float(i) * norm * screen_pixel_size;
		res += (1.0 / pow(2.0, float(i))) * (ao_step_size * float(i) - texture_sdf(screen_uv_to_sdf(rp * screen_pixel_size)));
	}

	if (res >= 0.0) {
		return 1.0 - ao_influence * clamp(1.0 - ao_step_size / res, 0.0, 1.0);
	}
	return 1.0;
}

void fragment() {
	screen_pixel_size = SCREEN_PIXEL_SIZE;

	vec4 tex_color = texture(TEXTURE, UV);

	// Parche de sombra ajena
	vec2 delta = (local_pos - shadow_point) / max(shadow_radius, vec2(0.01));
	float patch_dist = length(delta);
	float patch = 1.0 - smoothstep(0.0, 1.0, patch_dist);
	float darken = patch * shadow_strength;

	// Oclusión ambiental
	float ao = enable_ao ? compute_ao(FRAGCOORD.xy, SCREEN_UV) : 1.0;

	COLOR = vec4(tex_color.rgb * (1.0 - darken) * ao, tex_color.a);
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

	// Caída de luz por altura (local_pos.y mas negativo = mas arriba)
	float height_atten = clamp(1.0 - height_falloff * max(0.0, -local_pos.y), 0.0, 1.0);
	final_color *= height_atten;

	// Brillo especular simple (Blinn-Phong, sin mapa dedicado)
	if (enable_specular) {
		vec3 view_dir = vec3(0.0, 0.0, 1.0);
		vec3 half_vec = normalize(LIGHT_DIRECTION + view_dir);
		float spec = pow(max(dot(NORMAL, half_vec), 0.0), specular_shininess);
		final_color += LIGHT_COLOR.rgb * LIGHT_ENERGY * spec * specular_strength;
	}

	LIGHT = vec4(final_color, COLOR.a * LIGHT_COLOR.a);
}