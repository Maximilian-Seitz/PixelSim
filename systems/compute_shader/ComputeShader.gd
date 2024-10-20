class_name ComputeShader extends Resource


@export var shader_file: RDShaderFile
@export var edit_shader_file: RDShaderFile

var renderer: RenderingDevice

var _shader: RID
var _pipeline: RID
var _edit_shader: RID
var _edit_pipeline: RID


func start() -> void:
	renderer = RenderingServer.get_rendering_device()
	
	var shader_spirv := shader_file.get_spirv()
	_shader = renderer.shader_create_from_spirv(shader_spirv)
	
	var edit_shader_spirv := edit_shader_file.get_spirv()
	_edit_shader = renderer.shader_create_from_spirv(edit_shader_spirv)
	
	_pipeline = renderer.compute_pipeline_create(_shader)
	_edit_pipeline = renderer.compute_pipeline_create(_edit_shader)
	
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

func dispatch_edit(pos:Vector2i,type:float,data:Vector3,target_texture_uniform_set:RID) -> void:
	var compute_list := renderer.compute_list_begin()
	renderer.compute_list_bind_compute_pipeline(compute_list,_edit_pipeline)
	
	var parameters = PackedByteArray()
	parameters.resize((3 + 3) * 4)
	parameters.encode_s32(0 * 4,pos.x)
	parameters.encode_s32(1 * 4,pos.y)
	parameters.encode_float(2 * 4,type)
	parameters.encode_float(3 * 4,data.x)
	parameters.encode_float(4 * 4,data.y)
	parameters.encode_float(5 * 4,data.z)
	var params_buffer := renderer.storage_buffer_create(parameters.size(),parameters)
	
	var params_uniform = RDUniform.new()
	params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	params_uniform.binding = 0
	params_uniform.add_id(params_buffer);
	
	var params_uniform_set = renderer.uniform_set_create([params_uniform],_edit_shader,0)
	renderer.compute_list_bind_uniform_set(compute_list, params_uniform_set, 0)
	
	#It's a bit silly how this works, its a bit of a hack, I think
	renderer.compute_list_bind_uniform_set(compute_list, target_texture_uniform_set, 1)
	
	renderer.compute_list_dispatch(compute_list, 1, 1, 1)
	renderer.compute_list_end()
	renderer.free_rid(params_buffer)
	

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
