extends Button

func _ready():
	grab_focus()
	if OS.has_feature("arcade_release"):
		InputMapManager.load_runtime("res://input-maps/arcademia.cfg")
	
func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/gameroot.tscn")
