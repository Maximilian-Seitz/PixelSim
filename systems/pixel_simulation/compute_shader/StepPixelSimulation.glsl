#[compute]
#version 450


#include "lib/random.glsl"
#include "lib/grid_utils.glsl"

const float DELTA = 0.002;

#define EQ(a, b) (abs((a) - (b)) < 0.002)
#define LESS_THAN(a, b) ((a) < (b) - 0.002)

#define SWAP(cell_a, cell_b) { Cell SWAP_CELL_TEMP_SLOT = cell_a; cell_a = cell_b; cell_b = SWAP_CELL_TEMP_SLOT; }



#define IS_EMPTY(cell) EQ((cell).type, CELL_TYPE_EMPTY)
#define IS_WATER(cell) EQ((cell).type, CELL_TYPE_WATER)
#define IS_SAND(cell) EQ((cell).type, CELL_TYPE_SAND)
#define IS_WALL(cell) EQ((cell).type, CELL_TYPE_WALL)


#define CAN_SAND_DISPLACE(cell) LESS_THAN((cell).type, CELL_TYPE_SAND)


#define CAN_WATER_DISPLACE(cell) LESS_THAN((cell).type, CELL_TYPE_WATER)
#define IS_WATER_MOVING(cell) LESS_THAN(0, (cell).data.x)
#define IS_WATER_MOVING_LEFT(cell) ((cell).data.x > 0.5)
#define IS_WATER_MOVING_RIGHT(cell) ((cell).data.x < 0.5)
#define SET_WATER_MOVING_LEFT(cell) ((cell).data.x = 0.75)
#define SET_WATER_MOVING_RIGHT(cell) ((cell).data.x = 0.25)
#define STOP_WATER_MOVING(cell) ((cell).data.x = 0.0)


#define SAND_COLLAPSE_CHANCE (0.75)
#define SHOULD_SAND_COLLAPSE(seed) ((seed) < SAND_COLLAPSE_CHANCE)



// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;


// Uniforms
layout(set = 0, binding = 0, std430) restrict buffer ParamsBuffer {
	int run_index;
} params;

layout(set = 1, binding = 0, rgba8) restrict readonly uniform image2D input_img;
layout(set = 2, binding = 0, rgba8) restrict writeonly uniform image2D output_img;

Cell get_cell(ivec2 pos, ivec2 grid_size) {
	if (pos.x < grid_size.x && pos.y < grid_size.y && pos.x >= 0 && pos.y >= 0) {
		vec4 cell_bytes = imageLoad(input_img, pos);
		return Cell(cell_bytes.a, cell_bytes.xyz);
	} else {
		return Cell(CELL_TYPE_WALL, vec3(0));
	}
}

void set_cell(ivec2 pos, ivec2 grid_size, Cell cell) {
	if (pos.x < grid_size.x && pos.y < grid_size.y && pos.x >= 0 && pos.y >= 0) {
		imageStore(output_img, pos, vec4(cell.data, cell.type));
	}
}




void process_chunk(ivec2 top_left_pos, float seed, ivec2 grid_size) {
	// INPUTS

	Cell t_l = get_cell(top_left_pos + ivec2(0, 0), grid_size);
	Cell t_r = get_cell(top_left_pos + ivec2(1, 0), grid_size);
	Cell b_l = get_cell(top_left_pos + ivec2(0, 1), grid_size);
	Cell b_r = get_cell(top_left_pos + ivec2(1, 1), grid_size);


	// SAND

	if (IS_SAND(t_l)) {
		if (CAN_SAND_DISPLACE(b_l)) {
			SWAP(t_l, b_l);
		} else if (CAN_SAND_DISPLACE(t_r) && CAN_SAND_DISPLACE(b_r)) {
			if (SHOULD_SAND_COLLAPSE(seed)) {
				SWAP(t_l, b_r);
			}
		}
	}

	if (IS_SAND(t_r)) {
		if (CAN_SAND_DISPLACE(b_r)) {
			SWAP(t_r, b_r);
		} else if (CAN_SAND_DISPLACE(t_l) && CAN_SAND_DISPLACE(b_l)) {
			if (SHOULD_SAND_COLLAPSE(seed)) {
				SWAP(t_r, b_l);
			}
		}
	}


	// WATER

	if (IS_WATER(t_l)) {
		if (CAN_WATER_DISPLACE(b_l)) {
			SWAP(t_l, b_l);
		} else if (CAN_WATER_DISPLACE(b_r)) {
			if (CAN_WATER_DISPLACE(t_r)) {
				SWAP(t_l, b_r);
			}
		} else if (IS_WATER_MOVING(t_l)) {
			if (IS_WATER_MOVING_RIGHT(t_l)) {
				if (CAN_WATER_DISPLACE(t_r)) {
					SWAP(t_l, t_r);
				} else {
					STOP_WATER_MOVING(t_l);
				}
			}
		} else if (!CAN_WATER_DISPLACE(t_r)) {
			SET_WATER_MOVING_LEFT(t_l);
		}
	}

	if (IS_WATER(t_r)) {
		if (CAN_WATER_DISPLACE(b_r)) {
			SWAP(t_r, b_r);
		} else if (CAN_WATER_DISPLACE(b_l)) {
			if (CAN_WATER_DISPLACE(t_l)) {
				SWAP(t_r, b_l);
			}
		} else if (IS_WATER_MOVING(t_r)) {
			if (IS_WATER_MOVING_LEFT(t_r)) {
				if (CAN_WATER_DISPLACE(t_l)) {
					SWAP(t_r, t_l);
				} else {
					STOP_WATER_MOVING(t_r);
				}
			}
		} else if (!CAN_WATER_DISPLACE(t_l)) {
			SET_WATER_MOVING_RIGHT(t_r);
		}
	}


	// OUTPUTS

	set_cell(top_left_pos + ivec2(0, 0), grid_size, t_l);
	set_cell(top_left_pos + ivec2(1, 0), grid_size, t_r);
	set_cell(top_left_pos + ivec2(0, 1), grid_size, b_l);
	set_cell(top_left_pos + ivec2(1, 1), grid_size, b_r);
}


void main() {
	ivec2 top_left_pos = ivec2(gl_GlobalInvocationID.xy) * 2 - ivec2(1);
	top_left_pos.x += (params.run_index >> 1) & 1;
	top_left_pos.y += params.run_index & 1;

	ivec2 grid_size = imageSize(input_img);

	float seed = random(uvec3(
		uint(gl_GlobalInvocationID.x),
		uint(gl_GlobalInvocationID.y),
		uint(params.run_index))
	);

	process_chunk(top_left_pos, seed, grid_size);
}
