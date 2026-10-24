shader_type canvas_item;

uniform float fill = 1.0;
uniform float white_fill = 1.0;
uniform vec2 texture_size = vec2(28, 322);

void fragment() {
    vec2 pixel_uv = (fill == 0.0 ? floor(UV * texture_size) : ceil(UV * texture_size)) / texture_size;

	if (1.0 - pixel_uv.y >= white_fill) {
		// Black
		float param = max(COLOR.r, max(COLOR.g, COLOR.b)) * 0.1;
		COLOR = vec4(param, param, param, COLOR.a);
	}
	else if (1.0 - pixel_uv.y >= fill) {
		// White
		float param = max(COLOR.r, max(COLOR.g, COLOR.b));
		COLOR = vec4(param, param, param, COLOR.a);
	}
}
