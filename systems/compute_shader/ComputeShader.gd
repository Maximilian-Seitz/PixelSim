class_name ComputeShader extends Resource


@export var shader_file: RDShaderFile


var renderer: RenderingDevice

var _shader: RID
var _pipeline: RID


func start() -> void:
	renderer = RenderingServer.get_rendering_device()
	
	var shader_spirv := shader_file.get_spirv()
	_shader = renderer.shader_create_from_spirv(shader_spirv)
	_pipeline = renderer.compute_pipeline_create(_shader)
	
	_init_uniform_sets()


func run() -> void:
	# await RenderingServer.frame_post_draw
	
	var size := _prepare_run()
	
	var compute_list := renderer.compute_list_begin()
	renderer.compute_list_bind_compute_pipeline(compute_list, _pipeline)
	var set_index: int = 0
	for uniform_set in _get_uniform_sets():
		renderer.compute_list_bind_uniform_set(compute_list, uniform_set, set_index)
		set_index += 1
	renderer.compute_list_dispatch(compute_list, size.x, size.y, size.z)
	renderer.compute_list_end()
	
	#renderer.barrier(RenderingDevice.BARRIER_MASK_COMPUTE)
	
	_finish_run()


func generate_uniform_set(uniforms: Array[RDUniform], index: int = 0) -> RID:
	return renderer.uniform_set_create(uniforms, _shader, index)

func generate_image_uniform() -> RDUniform:
	return null


func _prepare_run() -> Vector3i:
	return Vector3i.ZERO

func _finish_run() -> void:
	pass


func _init_uniform_sets() -> void:
	pass

func _get_uniform_sets() -> Array[RID]:
	return []
