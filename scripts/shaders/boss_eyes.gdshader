shader_type canvas_item;
//
//uniform vec2 texture_size;
//uniform vec2 sprite_position;
//uniform vec4 rects[3];  // x: topleft x;   y: topleft y;   z: bottomright x;   w: bottomright y;
//
//
//void fragment() {
	//vec2 moved_UV;
	//moved_UV.x = UV.x + sprite_position.y / texture_size.y;
	//moved_UV.y = UV.y - sprite_position.x / texture_size.x;
	//bool in_rect = false;
	//for (int i = 0; i < rects.length(); i++) {
		//if (moved_UV.x > rects[i].x && moved_UV.y > rects[i].y
		//&& moved_UV.x < rects[i].z && moved_UV.y < rects[i].w) {
			//in_rect = true;
			//break;
		//}
	//}
//
	//if (!in_rect) {
		//COLOR.a = 0.0;
	//}
//}
