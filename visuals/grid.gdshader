shader_type canvas_item;


#define EQ(a, b) (abs((a) - (b)) < 0.002)
#define LESS_THAN(a, b) ((a) < (b) - 0.002)

struct Cell {
	float type;
	vec3 data;
};

#define CELL_TYPE_EMPTY (0.0)
#define CELL_TYPE_WATER (0.5)
#define CELL_TYPE_SAND (0.75)
#define CELL_TYPE_WALL (1.0)

#define IS_EMPTY(cell) EQ((cell).type, CELL_TYPE_EMPTY)
#define IS_WATER(cell) EQ((cell).type, CELL_TYPE_WATER)
#define IS_SAND(cell) EQ((cell).type, CELL_TYPE_SAND)
#define IS_WALL(cell) EQ((cell).type, CELL_TYPE_WALL)


uniform ivec2 highlight_pos = ivec2(-1);

uniform vec4 background_color: source_color = vec4(0, 0, 0, 1);
uniform sampler2D sand_color_range: source_color;
uniform sampler2D water_color_range: source_color;
uniform sampler2D stone_color_range: source_color;

void fragment() {
	vec2 pixel_pos = UV / TEXTURE_PIXEL_SIZE;
	vec2 pixel_offset = vec2(pixel_pos - floor(pixel_pos));

	Cell cell = Cell(COLOR.a, COLOR.rgb);

	if (IS_WALL(cell)) {
		COLOR = texture(stone_color_range, vec2(cell.data.z, 0));
	} else if (IS_SAND(cell)) {
		COLOR = texture(sand_color_range, vec2(cell.data.z, 0));
	} else if (IS_WATER(cell)) {
		COLOR = texture(water_color_range, vec2(cell.data.z, 0));
	} else {
		COLOR = background_color;
	}

	if (ivec2(floor(pixel_pos)) == highlight_pos) {
		vec3 highlight_color = vec3(0.4 - sin(pixel_offset.x*PI) * sin(pixel_offset.y*PI));
		COLOR.rgb = max(highlight_color, COLOR.rgb);
	}
}
