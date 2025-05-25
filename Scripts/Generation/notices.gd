extends VBoxContainer


func _on_generator_event(message: String) -> void:
	var label := Label.new()
	
	label.text = message
	
	add_child(label)
	pass # Replace with function body.


func _on_generator_file_loaded() -> void:
	get_parent().queue_free()
