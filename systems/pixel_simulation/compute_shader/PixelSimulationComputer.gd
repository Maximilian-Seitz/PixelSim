class_name PixelSimulationComputer extends ComputeShader

const CELL_NONE := 0.0
const CELL_WATER := 0.5
const CELL_SAND := 0.75
const CELL_WALL := 1.0


var field_size: Vector2i

var render_texture := Texture2DRD.new()


func set_cell_empty(pos: Vector2i) -> void:
	_set_cell(pos, CELL_NONE, Vector3.ZERO)

func set_cell_water(pos: Vector2i) -> void:
	_set_cell(pos, CELL_WATER, Vector3(0, 0, randf()))

func set_cell_sand(pos: Vector2i) -> void:
	_set_cell(pos, CELL_SAND, Vector3(0, 0, randf()))

func set_cell_wall(pos: Vector2i) -> void:
	_set_cell(pos, CELL_WALL, Vector3(0, 0, randf()))


var _temp_img: Image


var _textures: Array[RID]

var _target_texture: RID:
	get: return _textures[(_run_index + 1) % 2]


var _texture_uniform_sets: Array[RID]

var _source_uniform_set: RID:
	get: return _texture_uniform_sets[_run_index % 2]

var _target_uniform_set: RID:
	get: return _texture_uniform_sets[(_run_index + 1) % 2]


var _params_buffer: RID
var _params_uniform_set: RID


var _run_index: int = 0


func _init_uniform_sets() -> void:
	var param_bytes := _generate_params_buffer()
	_params_buffer = renderer.storage_buffer_create(param_bytes.size(), param_bytes)
	
	var params_uniform = RDUniform.new()
	params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	params_uniform.binding = 0
	params_uniform.add_id(_params_buffer)
	_params_uniform_set = generate_uniform_set([ params_uniform ], 0)
	
	
	# Texture uniforms
	
	_temp_img = Image.create(
		field_size.x,
		field_size.y,
		false,
		Image.FORMAT_RGBA8
	)
	
	var img_format := RDTextureFormat.new()
	img_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	img_format.width = field_size.x
	img_format.height = field_size.y
	img_format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	for i in 2:
		_textures.append(renderer.texture_create(img_format, RDTextureView.new(), [ _temp_img.get_data() ]))
		
		var texture_uniform := RDUniform.new()
		texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		texture_uniform.binding = 0
		texture_uniform.add_id(_textures[i])
		
		_texture_uniform_sets.append(generate_uniform_set([ texture_uniform ], 1))
	
	render_texture.texture_rd_rid = _textures[1]


func _prepare_run() -> Vector3i:
	_run_index += 1
	
	var param_bytes := _generate_params_buffer()
	renderer.buffer_update(_params_buffer, 0, param_bytes.size(), param_bytes)
	
	return Vector3i(
		ceil(float(render_texture.get_width())/2.0/8.0) + 1,
		ceil(float(render_texture.get_height())/2.0/8.0) + 1,
		1
	)


func _get_uniform_sets() -> Array[RID]:
	return [
		_params_uniform_set,
		_source_uniform_set,
		_target_uniform_set
	]


func _finish_run() -> void:
	render_texture.texture_rd_rid = _target_texture


func _generate_params_buffer() -> PackedByteArray:
	var params_buffer = PackedInt32Array()
	params_buffer.append(_run_index)
	return params_buffer.to_byte_array()


func _set_cell(pos: Vector2i, type: float, data: Vector3) -> void:
	_temp_img.set_data(
		_temp_img.get_width(),
		_temp_img.get_height(),
		_temp_img.has_mipmaps(),
		_temp_img.get_format(),
		renderer.texture_get_data(_target_texture, 0)
	)
	
	_temp_img.set_pixelv(pos, Color(data.x, data.y, data.z, type))
	
	renderer.texture_update(_target_texture, 0, _temp_img.get_data())
