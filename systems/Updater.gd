class_name Updater extends Node

signal update_triggered()

@export var updates_per_second: float = 60


var _progress: float = 0

func _process(delta: float) -> void:
	_progress += updates_per_second * delta
	
	while _progress > 1:
		update_triggered.emit()
		_progress -= 1

func set_updates_per_second(value: float) -> void:
	updates_per_second = value

func get_updates_per_second() -> float:
	return updates_per_second
