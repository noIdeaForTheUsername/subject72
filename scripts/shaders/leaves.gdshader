shader_type canvas_item;

uniform vec2 relative_player_position;
uniform vec2 sprite_size;

const float invisilibyDistance = 265.0;
const float transitionLength = 70.0;
uniform float minOpacity = 0.15;

void fragment() {
    vec4 pixelColor = texture(TEXTURE, UV);
	if (pixelColor.a > 0.0) {
		float distanceFromPlayer = length(relative_player_position - (UV * sprite_size));
		// If condition not met, fully opaque
		if (distanceFromPlayer <= invisilibyDistance) {
			if (distanceFromPlayer >= invisilibyDistance - transitionLength) {
				// Transition (partially transparent)
				float multiplier = (distanceFromPlayer - (invisilibyDistance - transitionLength)) / (transitionLength);
				pixelColor.a *= minOpacity + (multiplier * (1.0 - minOpacity));
			}
			else {
				// Maximum transparency
				pixelColor.a *= minOpacity;
			}
		}

		//if (length(FRAGCOORD.xy - vec2(1280, 720)) < 100.0) {
			//COLOR = vec4(1.0, 0.0, 0.0, 1.0);
		//}
		//else {
			//COLOR = pixelColor;
		//}

		COLOR = pixelColor;
		}
}
