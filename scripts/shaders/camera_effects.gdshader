shader_type canvas_item;


uniform float intensity;
uniform float max_distance;

uniform float max_ghost_alpha: hint_range(0.0, 1.0) = 0.4;
uniform float shake_coeff;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;


void fragment() {
	vec2 offset = vec2(max_distance, 0.0) * intensity;

	vec2 shake = vec2(
		sin(TIME * 4.0) * max_distance * shake_coeff,
		0
	) * intensity;

	vec4 ghost_left = texture(SCREEN_TEXTURE, SCREEN_UV + offset + shake);
	vec4 ghost_right =  texture(SCREEN_TEXTURE, SCREEN_UV - offset - shake);

	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	color = mix(color, ghost_left, max_ghost_alpha * intensity);
	color = mix(color, ghost_right, max_ghost_alpha * intensity);
	COLOR = color;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
