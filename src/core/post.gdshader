shader_type canvas_item;
// Gritty gothic grade: desaturation, crushed blacks, split-toning, soft bloom, edge aberration, vignette, film grain.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float time = 0.0;
uniform float grit = 1.0;
uniform vec3 shadow_tint = vec3(0.05, 0.07, 0.14);
uniform vec3 high_tint = vec3(1.04, 0.97, 0.88);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);
	vec2 ab = c * r2 * 0.012;
	vec3 col;
	col.r = texture(screen_tex, uv + ab).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - ab).b;

	vec3 bloom = vec3(0.0);
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		bloom += textureLod(screen_tex, uv + vec2(cos(a), sin(a)) * 0.006, 2.0).rgb;
	}
	bloom = max(bloom / 8.0 - vec3(0.42), vec3(0.0));
	col += bloom * 0.9;

	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, 0.78);
	col = (col - 0.5) * (1.0 + 0.22 * grit) + 0.5;
	col = max(col - 0.03 * grit, vec3(0.0));
	col = pow(col, vec3(1.12));
	col = mix(col * high_tint, col + shadow_tint * (1.0 - smoothstep(0.0, 0.5, l)), 1.0 - smoothstep(0.0, 0.6, l));

	float vig = smoothstep(0.18, 0.62, r2 * 1.9);
	col *= 1.0 - vig * 0.62;
	float g = hash(uv * vec2(1920.0, 1080.0) + fract(time) * 100.0) - 0.5;
	col += g * 0.045 * grit * (1.0 - l * 0.6);
	COLOR = vec4(col, 1.0);
}
