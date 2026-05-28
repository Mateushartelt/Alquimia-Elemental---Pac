shader_type canvas_item;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float is_white = step(0.90, col.r) * step(0.90, col.g) * step(0.90, col.b);
	COLOR = vec4(col.rgb, col.a * (1.0 - is_white));
}
