#[compute]
#version 450

#include "lib/grid_utils.glsl"


// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// Uniforms
layout(set = 0, binding = 0, std430) restrict buffer ParamsBuffer {
	ivec2 point;
    float type;
    vec3 data;
} params;

layout(set = 1, binding = 0, rgba8) uniform image2D _img;

// I have to redifine get_cell/set_cell, and I didn't move them into the util because of readonly/writeonly
Cell get_cell(ivec2 pos, ivec2 grid_size) {
	if (pos.x < grid_size.x && pos.y < grid_size.y && pos.x >= 0 && pos.y >= 0) {
		vec4 cell_bytes = imageLoad(_img, pos);
		return Cell(cell_bytes.a, cell_bytes.xyz);
	} else {
		return Cell(CELL_TYPE_WALL, vec3(0));
	}
}

void set_cell(ivec2 pos, ivec2 grid_size, Cell cell) {
	if (pos.x < grid_size.x && pos.y < grid_size.y && pos.x >= 0 && pos.y >= 0) {
		imageStore(_img, pos, vec4(cell.data, cell.type));
	}
}

void main() {
    ivec2 g_size = imageSize(_img);
    Cell target_cell;
    target_cell.data = params.data;
    target_cell.type = params.type;
	set_cell(params.point,g_size,target_cell);
}
