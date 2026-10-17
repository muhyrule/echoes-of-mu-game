shader_type canvas_item;
// Crisp material colours and restrained gothic grading; no blur or colour fringing.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float time = 0.0;
uniform float grit = 1.2;
uniform float scratches = 0.0;
uniform vec3 shadow_tint = vec3(0.05, 0.07, 0.14);
uniform vec3 high_tint = vec3(1.04, 0.97, 0.88);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);
	vec3 col = texture(screen_tex, uv).rgb;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, 0.96);
	col *= mix(vec3(1.0), high_tint, 0.25);
	col += shadow_tint * 0.035 * (1.0 - smoothstep(0.0, 0.4, l));
	float vig = smoothstep(0.18, 0.62, r2 * 1.9);
	col *= 1.0 - vig * min(0.24, grit * 0.12);
	// Film wear is confined to scenes which explicitly request it.
	float sc = hash(vec2(floor(uv.x * 960.0), floor(time * 8.0)));
	col -= step(0.9995, sc) * 0.025 * scratches;
	COLOR = vec4(col, 1.0);
}
