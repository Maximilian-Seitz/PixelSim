#define CELL_TYPE_EMPTY (0.0)
#define CELL_TYPE_WATER (0.5)
#define CELL_TYPE_SAND (0.75)
#define CELL_TYPE_WALL (1.0)

struct Cell {
	float type;
	vec3 data;
};