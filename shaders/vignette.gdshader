shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 3.0) = 0.6;
uniform float radius : hint_range(0.0, 1.5) = 0.75;
uniform vec4 vignette_color : source_color = vec4(0.05, 0.04, 0.01, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 screen = texture(SCREEN_TEXTURE, uv);

	// Distancia desde el centro (0.0 = centro, 1.0 = esquina)
	vec2 centered = uv * 2.0 - 1.0;
	float dist = length(centered);

	// Viñeta: solo oscurece cuando dist > radius
	float vignette = smoothstep(radius, 1.4, dist * strength);

	COLOR = mix(screen, vignette_color, vignette);
	COLOR.a = 1.0;
}
