extends Node


@export var simulation: PixelSimulation
@export var grid_material: ShaderMaterial


func _process(_delta):
	grid_material.set_shader_parameter("highlight_pos", simulation.get_hovered_cell())
