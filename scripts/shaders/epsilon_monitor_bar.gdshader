shader_type canvas_item;
render_mode unshaded;

uniform float cycle_time;

void fragment() {
	float offsetX = TIME / cycle_time;
	vec2 newUV = UV + vec2(offsetX, 0);
	newUV.x = fract(newUV.x);
	vec4 pixelColor = texture(TEXTURE, newUV);
	COLOR = pixelColor;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
