class_name ComputeShader extends RefCounted

var _rd: RenderingDevice

var _shader: RID
var _pipeline: RID


func _init(shader_file: RDShaderFile) -> void:
	_rd = RenderingServer.get_rendering_device()
	
	var shader_spirv := shader_file.get_spirv()
	_shader = _rd.shader_create_from_spirv(shader_spirv)
	_pipeline = _rd.compute_pipeline_create(_shader)


func run(invocations: Vector3i, uniform_sets: Array[UniformSet]) -> void:
	var compute_list := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(compute_list, _pipeline)
	
	var set_index: int = 0
	for uniform_set in uniform_sets:
		_rd.compute_list_bind_uniform_set(compute_list, uniform_set.rid, set_index)
		set_index += 1
	
	_rd.compute_list_dispatch(compute_list, invocations.x, invocations.y, invocations.z)
	_rd.compute_list_end()
	
	#_rd.barrier(RenderingDevice.BARRIER_MASK_COMPUTE)


func create_buffer(size: int) -> RDBuffer:
	return RDBuffer.new(_rd, size)

func create_texture(format: RDTextureFormat) -> RDTexture:
	return RDTexture.new(_rd, format)

func create_uniform_set(uniforms: Array[RDUniform], index: int = 0) -> UniformSet:
	return UniformSet.new(_rd, _shader, uniforms, index)


class RDResource extends RefCounted:
	
	var rd: RenderingDevice
	var rid: RID
	
	func _init(_rd: RenderingDevice, _rid: RID) -> void:
		rd = _rd
		rid = _rid
	
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			rd.free_rid(rid)


class UniformSet extends RDResource:
	
	func _init(_rd: RenderingDevice, shader: RID, uniforms: Array[RDUniform], index: int) -> void:
		super(_rd, _rd.uniform_set_create(uniforms, shader, index))


class RDBuffer extends RDResource:
	
	var _size: int
	
	var data: PackedByteArray:
		get(): return rd.buffer_get_data(rid, 0, _size)
		set(value):
			assert(value.size() == _size)
			rd.buffer_update(rid, 0, _size, value)
	
	func _init(_rd: RenderingDevice, size: int) -> void:
		super(_rd, _rd.storage_buffer_create(size))
		_size = size


class RDTexture extends RDResource:
	
	func _init(_rd: RenderingDevice, format: RDTextureFormat) -> void:
		super(_rd, _rd.texture_create(format, RDTextureView.new()))
