extends VBoxContainer


func _on_generator_event(message: String) -> void:
	var label := Label.new()
	
	label.text = message
	
	add_child(label)
	pass # Replace with function body.
