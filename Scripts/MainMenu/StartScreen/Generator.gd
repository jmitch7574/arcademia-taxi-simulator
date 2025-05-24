extends Button

const GENERATOR = "res://Scenes/Generator.tscn"

func _ready() -> void:
	if not OS.has_feature("editor"):
		queue_free()

func _on_pressed() -> void:
	get_tree().change_scene_to_file(GENERATOR)
