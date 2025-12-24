class_name PixelSimulationComputer extends Resource

const CELL_NONE := 0.0
const CELL_WATER := 0.5
const CELL_SAND := 0.75
const CELL_WALL := 1.0


@export var step_shader_file: RDShaderFile
@export var edit_shader_file: RDShaderFile


var field_size: Vector2i

var render_texture := Texture2DRD.new()


var _step_compute_shader: ComputeShader
var _edit_compute_shader: ComputeShader


var _textures: Array[ComputeShader.RDTexture]

var _target_texture: ComputeShader.RDTexture:
	get: return _textures[(_run_index + 1) % 2]


var _source_texture_uniform_sets: Array[ComputeShader.UniformSet]
var _target_texture_uniform_sets: Array[ComputeShader.UniformSet]

var _source_uniform_set: ComputeShader.UniformSet:
	get: return _source_texture_uniform_sets[_run_index % _source_texture_uniform_sets.size()]

var _target_uniform_set: ComputeShader.UniformSet:
	get: return _target_texture_uniform_sets[(_run_index + 1) % _target_texture_uniform_sets.size()]


var _step_params_buffer: ComputeShader.RDBuffer
var _step_params_uniform_set: ComputeShader.UniformSet


var _edit_params_buffer: ComputeShader.RDBuffer
var _edit_params_uniform_set: ComputeShader.UniformSet


var _run_index: int = 0


func setup() -> void:
	_step_compute_shader = ComputeShader.new(step_shader_file)
	_edit_compute_shader = ComputeShader.new(edit_shader_file)
	
	
	# Step params uniform
	
	var step_param_bytes := _generate_step_param_bytes(0)
	_step_params_buffer = _step_compute_shader.create_buffer(step_param_bytes.size())
	
	var step_params_uniform = RDUniform.new()
	step_params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	step_params_uniform.binding = 0
	step_params_uniform.add_id(_step_params_buffer.rid)
	_step_params_uniform_set = _step_compute_shader.create_uniform_set([ step_params_uniform ], 0)
	
	
	# Edit params uniform
	
	var edit_param_bytes := _generate_edit_param_bytes(Vector2i.ZERO, 0, Vector3.ZERO)
	_edit_params_buffer = _step_compute_shader.create_buffer(edit_param_bytes.size())
	
	var edit_params_uniform = RDUniform.new()
	edit_params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	edit_params_uniform.binding = 0
	edit_params_uniform.add_id(_edit_params_buffer.rid)
	_edit_params_uniform_set = _edit_compute_shader.create_uniform_set([ edit_params_uniform ], 0)
	
	
	# Texture uniforms
	
	var img_format := RDTextureFormat.new()
	img_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	img_format.width = field_size.x
	img_format.height = field_size.y
	img_format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	for i in 2:
		_textures.append(_step_compute_shader.create_texture(img_format))
	
	render_texture.texture_rd_rid = _textures[1].rid
	
	var uniform_set_groups = [_target_texture_uniform_sets, _source_texture_uniform_sets]
	for uniform_set_num in uniform_set_groups.size():
		# Go through the textures, and create a uniform-set for each texture for both input and output
		for i in _textures.size():
			var texture_uniform := RDUniform.new()
			texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
			texture_uniform.binding = 0
			texture_uniform.add_id(_textures[i].rid)
			
			# The 'uniform_set_num' is 0 for the target texture, and 1 for the source texture.
			# The uniform-set for the target-texture needs to be 1, and source-texture 2 (as defined in the shaders).
			uniform_set_groups[uniform_set_num].append(_step_compute_shader.create_uniform_set([ texture_uniform ], 1 + uniform_set_num))


func step() -> void:
	_run_index += 1
	
	_step_params_buffer.data = _generate_step_param_bytes(_run_index)
	
	var size = Vector3i(
		ceil(float(render_texture.get_width())/2.0/8.0) + 1,
		ceil(float(render_texture.get_height())/2.0/8.0) + 1,
		1
	)
	
	var uniform_sets: Array[ComputeShader.UniformSet] = [
		_step_params_uniform_set,
		_target_uniform_set,
		_source_uniform_set
	]
	
	_step_compute_shader.run(size, uniform_sets)
	
	render_texture.texture_rd_rid = _target_texture.rid


func set_cell_empty(pos: Vector2i) -> void:
	_set_cell(pos, CELL_NONE, Vector3.ZERO)

func set_cell_water(pos: Vector2i) -> void:
	_set_cell(pos, CELL_WATER, Vector3(0, 0, randf()))

func set_cell_sand(pos: Vector2i) -> void:
	_set_cell(pos, CELL_SAND, Vector3(0, 0, randf()))

func set_cell_wall(pos: Vector2i) -> void:
	_set_cell(pos, CELL_WALL, Vector3(0, 0, randf()))


func _set_cell(pos: Vector2i, type: float, data: Vector3) -> void:
	_edit_params_buffer.data = _generate_edit_param_bytes(pos, type, data)
	
	_edit_compute_shader.run(
		Vector3i.ONE,
		[
			_edit_params_uniform_set,
			_target_uniform_set
		]
	)


func _generate_step_param_bytes(run_index: int) -> PackedByteArray:
	var parameters = PackedByteArray()
	parameters.resize(1 * 4)
	
	parameters.encode_s32(0 * 4, run_index)
	
	return parameters

func _generate_edit_param_bytes(pos: Vector2i, type: float, data: Vector3) -> PackedByteArray:
	var parameters = PackedByteArray()
	parameters.resize((3 + 3) * 4)
	
	parameters.encode_s32(0 * 4, pos.x)
	parameters.encode_s32(1 * 4, pos.y)
	parameters.encode_float(2 * 4, type)
	parameters.encode_float(3 * 4, data.x)
	parameters.encode_float(4 * 4, data.y)
	parameters.encode_float(5 * 4, data.z)
	
	return parameters
