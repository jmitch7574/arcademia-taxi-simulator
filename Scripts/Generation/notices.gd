extends VBoxContainer
## Notification system

func _on_generator_event(message: String) -> void:
	var label := Label.new()
	
	label.text = message
	
	add_child(label)
	pass # Replace with function body.

func _on_generator_world_generated() -> void:
	get_parent().queue_free()
