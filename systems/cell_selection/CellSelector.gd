class_name CellSelector extends OptionButton

@export var simulation: PixelSimulation

func _ready() -> void:
	for cell_type_name in PixelSimulation.CellType.keys():
		var cell_type_text := (cell_type_name as String).to_lower().capitalize()
		add_item(cell_type_text)
	
	select(simulation.selected_cell_type)
	
	item_selected.connect(_cell_type_selected)

func _cell_type_selected(cell_type: PixelSimulation.CellType) -> void:
	simulation.selected_cell_type = cell_type
