shader_type canvas_item;

uniform ivec2 highlight_pos = ivec2(-1);

void fragment() {
	vec2 pixel_pos = UV / TEXTURE_PIXEL_SIZE;
	vec2 pixel_offset = vec2(pixel_pos - floor(pixel_pos));

	if (COLOR.r > 0.0) {
		COLOR.rgb = vec3(sin(pixel_offset.x*PI) * sin(pixel_offset.y*PI));
	}

	if (ivec2(floor(pixel_pos)) == highlight_pos) {
		vec3 highlight_color = vec3(0.4 - sin(pixel_offset.x*PI) * sin(pixel_offset.y*PI));
		COLOR.rgb = max(highlight_color, COLOR.rgb);
	}
}
