class_name PixelSimulation extends Node2D


@export var field_size: Vector2i = Vector2i(2000, 2000)

@export_group("Zoom")
@export var min_zoom: float = 0.5
@export var max_zoom: float = 40.0
@export var zoom_step: float = 0.1

@export_group("Simulation")
@export var simulator: PixelSimulationComputer

@export_group("Visuals")
@export var field_material: Material


enum CellType {
	WATER,
	SAND,
	WALL
}


var sprite: Sprite2D
var camera: Camera2D

var is_busy: bool = false

var selected_cell_type: CellType = CellType.SAND



enum _PlaceMode {
	NONE,
	CLEAR,
	CELL
}

var _place_mode: _PlaceMode


func _ready() -> void:
	simulator.field_size = field_size
	simulator.setup()
	
	camera = Camera2D.new()
	camera.zoom = 20 * Vector2.ONE
	camera.position = field_size / 2
	add_child(camera)
	
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.texture = simulator.render_texture
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		-4*field_size,
		9*field_size
	)
	sprite.position = -4*field_size
	sprite.material = field_material
	add_child(sprite)


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			camera.position -= event.relative / camera.zoom
			_center_camera()
	elif event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_in(get_local_mouse_position())
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out(get_local_mouse_position())
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_place_mode = _PlaceMode.CLEAR
			elif event.button_index == MOUSE_BUTTON_LEFT:
				_place_mode = _PlaceMode.CELL
		else:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if _place_mode == _PlaceMode.CLEAR:
					_place_mode = _PlaceMode.NONE
			elif event.button_index == MOUSE_BUTTON_LEFT:
				if _place_mode == _PlaceMode.CELL:
					_place_mode = _PlaceMode.NONE

func _process(_delta: float) -> void:
	match _place_mode:
		_PlaceMode.CLEAR:
			clear_cell(get_hovered_cell())
		_PlaceMode.CELL:
			set_cell(get_hovered_cell(), selected_cell_type)

func zoom_in(pos: Vector2) -> void:
	var zoom_factor = camera.zoom.x * (1.0 + zoom_step)
	
	if zoom_factor < max_zoom:
		camera.position += (pos - camera.position) * zoom_step
		camera.zoom = zoom_factor * Vector2.ONE
	else:
		camera.zoom = max_zoom * Vector2.ONE
	
	_center_camera()

func zoom_out(pos: Vector2) -> void:
	var zoom_factor = camera.zoom.x * (1.0 - zoom_step)
	
	if zoom_factor > min_zoom:
		camera.position -= (pos - camera.position) * zoom_step
		camera.zoom = zoom_factor * Vector2.ONE
	else:
		camera.zoom = min_zoom * Vector2.ONE
	
	_center_camera()

func get_hovered_cell() -> Vector2i:
	var mouse_pos = sprite.get_local_mouse_position()
	return Vector2i(
		int(mouse_pos.x) % sprite.texture.get_width(),
		int(mouse_pos.y) % sprite.texture.get_width()
	)


func clear_cell(pos: Vector2i) -> void:
	simulator.set_cell_empty(pos)

func set_cell(pos: Vector2i, type: CellType) -> void:
	match type:
		CellType.WATER:
			simulator.set_cell_water(pos)
		CellType.SAND:
			simulator.set_cell_sand(pos)
		CellType.WALL:
			simulator.set_cell_wall(pos)


func run_step() -> void:
	if not is_busy:
		is_busy = true
		simulator.step()
		is_busy = false

func _center_camera() -> void:
	while camera.position.x < -0.5*field_size.x:
		camera.position.x += field_size.x
	
	while camera.position.y < -0.5*field_size.y:
		camera.position.y += field_size.y
	
	while camera.position.x > 1.5*field_size.x:
		camera.position.x -= field_size.x
	
	while camera.position.y > 1.5*field_size.y:
		camera.position.y -= field_size.y
