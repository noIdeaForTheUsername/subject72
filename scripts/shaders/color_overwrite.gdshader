shader_type canvas_item;

uniform vec4 overwrite_color;
uniform float overwrite_intensity = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a > 0.0) {
		vec4 col = tex * COLOR;
		col = mix(col, overwrite_color, overwrite_intensity);
		COLOR = col;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
