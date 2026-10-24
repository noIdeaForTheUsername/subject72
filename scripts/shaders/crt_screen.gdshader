shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D noise_texture;


uniform float min_noise_intensity = 0.5;
uniform float high_lightness_noise_intensity_coefficient = 2.0;

uniform float bar_speed = 0.2;
uniform float bar_amount = 5.0;
uniform float bar_lightness = 1.0;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);

	// Noise
	vec4 noise_color = texture(noise_texture, vec2(rand(vec2(SCREEN_UV.y, TIME)), rand(vec2(SCREEN_UV.x, TIME))));
	float pixel_intensity = max(max(color.r, color.g), color.b) * high_lightness_noise_intensity_coefficient + min_noise_intensity;
	color.r = clamp(color.r + (noise_color.r - 0.5) * pixel_intensity, 0.0, 1.0);
	color.g = clamp(color.g + (noise_color.g - 0.5) * pixel_intensity, 0.0, 1.0);
	color.b = clamp(color.b + (noise_color.b - 0.5) * pixel_intensity, 0.0, 1.0);

	// Bars
	float coeff = 1.0 + abs(fract((SCREEN_UV.y + TIME * bar_speed) * bar_amount) - 0.5) * bar_lightness;
	color.r *= coeff;
	color.g *= coeff;
	color.b *= coeff;

	COLOR = color;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
