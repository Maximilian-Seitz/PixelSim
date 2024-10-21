class_name ComputeShader extends RefCounted

var _rd: RenderingDevice

var _shader: RID
var _pipeline: RID


func _init(shader_file: RDShaderFile) -> void:
	_rd = RenderingServer.get_rendering_device()
	
	var shader_spirv := shader_file.get_spirv()
	_shader = _rd.shader_create_from_spirv(shader_spirv)
	_pipeline = _rd.compute_pipeline_create(_shader)


func run(invocations: Vector3i, uniform_sets: Array[RID]) -> void:
	var compute_list := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(compute_list, _pipeline)
	
	var set_index: int = 0
	for uniform_set in uniform_sets:
		_rd.compute_list_bind_uniform_set(compute_list, uniform_set, set_index)
		set_index += 1
	
	_rd.compute_list_dispatch(compute_list, invocations.x, invocations.y, invocations.z)
	_rd.compute_list_end()
	
	#_rd.barrier(RenderingDevice.BARRIER_MASK_COMPUTE)


func create_storage_buffer(size: int) -> RID:
	return _rd.storage_buffer_create(size)

func update_storage_buffer(storage_buffer: RID, data: PackedByteArray, offset: int = 0) -> void:
	_rd.buffer_update(storage_buffer, offset, data.size(), data)

func free_storage_buffer(storage_buffer: RID) -> void:
	_rd.free_rid(storage_buffer)


func create_texture(format: RDTextureFormat) -> RID:
	return _rd.texture_create(format, RDTextureView.new())

func free_texture(texture: RID) -> void:
	_rd.free_rid(texture)


func generate_uniform_set(uniforms: Array[RDUniform], index: int = 0) -> RID:
	return _rd.uniform_set_create(uniforms, _shader, index)

func free_uniform_set(uniform_set: RID) -> void:
	_rd.free_rid(uniform_set)
