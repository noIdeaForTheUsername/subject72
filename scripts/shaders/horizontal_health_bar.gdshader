shader_type canvas_item;

uniform float fill = 1.0;
uniform float white_fill = 1.0;
uniform	float slope = 0.016;
uniform vec2 texture_size = vec2(292, 30);

void fragment() {
    vec2 pixel_uv = floor(UV * texture_size) / texture_size;

	float max_x_uv = 1.0 - slope * 0.9;
	float threshold_x = fill * max_x_uv + (max_x_uv - pixel_uv.y * max_x_uv) * slope;
	float white_threshold_x = white_fill * max_x_uv + (max_x_uv - pixel_uv.y * max_x_uv) * slope;

	if (pixel_uv.x >= white_threshold_x || fill == 0.0) {
		float param = max(COLOR.r, max(COLOR.g, COLOR.b)) * 0.1;
		COLOR = vec4(param, param, param, COLOR.a);
	}
	else if (pixel_uv.x >= threshold_x || fill == 0.0) {
		float param = max(COLOR.r, max(COLOR.g, COLOR.b));
		COLOR = vec4(param, param, param, COLOR.a);
	}
}
