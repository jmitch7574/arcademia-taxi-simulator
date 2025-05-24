extends Button


func _on_pressed() -> void:
	if ResourceLoader.exists("res://SavedGens/Lincoln.tscn"):
		get_tree().change_scene_to_file("res://Scenes/gameroot.tscn")
		pass
	pass # Replace with function body.
