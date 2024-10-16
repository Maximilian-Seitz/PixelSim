#[compute]
#version 450

const float DELTA = 0.002;

const float CELL_NONE = 0.0;
const float CELL_SAND = 0.5;
const float CELL_WALL = 1.0;


// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;


// Uniforms
layout(set = 0, binding = 0, std430) restrict buffer ParamsBuffer {
	int run_index;
} params;

layout(set = 1, binding = 0, r8) restrict readonly uniform image2D input_img;
layout(set = 2, binding = 0, r8) restrict writeonly uniform image2D output_img;



float get_cell(ivec2 pos, ivec2 grid_size) {
	if (pos.x < grid_size.x && pos.y < grid_size.y) {
		return imageLoad(input_img, pos).r;
	} else {
		return CELL_WALL;
	}
}

void set_cell(ivec2 pos, ivec2 grid_size, float type) {
	if (pos.x < grid_size.x && pos.y < grid_size.y) {
		imageStore(output_img, pos, vec4(type, 0, 0, 1));
	}
}



void process_chunk(ivec2 top_left_pos, ivec2 grid_size) {
	float t_l = get_cell(top_left_pos + ivec2(0, 0), grid_size);
	float t_r = get_cell(top_left_pos + ivec2(1, 0), grid_size);
	float b_l = get_cell(top_left_pos + ivec2(0, 1), grid_size);
	float b_r = get_cell(top_left_pos + ivec2(1, 1), grid_size);

	float t_l_out = t_l;
	float t_r_out = t_r;
	float b_l_out = b_l;
	float b_r_out = b_r;

	if (abs(t_l - CELL_SAND) < DELTA) {
		if (b_l < CELL_SAND - DELTA) {
			t_l_out = CELL_NONE;
			b_l_out = CELL_SAND;
		} else if (t_r < CELL_SAND - DELTA && b_r < CELL_SAND - DELTA) {
			t_l_out = CELL_NONE;
			b_r_out = CELL_SAND;
		}
	}

	if (abs(t_r - CELL_SAND) < DELTA) {
		if (b_r < CELL_SAND - DELTA) {
			t_r_out = CELL_NONE;
			b_r_out = CELL_SAND;
		} else if (t_l < CELL_SAND - DELTA && b_l < CELL_SAND - DELTA) {
			t_r_out = CELL_NONE;
			b_l_out = CELL_SAND;
		}
	}

	set_cell(top_left_pos + ivec2(0, 0), grid_size, t_l_out);
	set_cell(top_left_pos + ivec2(1, 0), grid_size, t_r_out);
	set_cell(top_left_pos + ivec2(0, 1), grid_size, b_l_out);
	set_cell(top_left_pos + ivec2(1, 1), grid_size, b_r_out);
}


void main() {
	ivec2 top_left_pos = ivec2(gl_GlobalInvocationID.xy) * 2;
	top_left_pos.x += (params.run_index >> 1) & 1;
	top_left_pos.y += params.run_index & 1;

	ivec2 grid_size = imageSize(input_img);

	process_chunk(top_left_pos, grid_size);
}
