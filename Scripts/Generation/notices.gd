extends VBoxContainer
## Notification system

func _on_generator_event(message: String) -> void:
	var label := Label.new()
	
	label.text = message
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 32
	
	add_child(label)
	pass # Replace with function body.

func _on_generator_world_generated() -> void:
	get_parent().queue_free()
