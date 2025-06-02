@tool
extends EditorPlugin

var panel: Control
const UI = preload("res://addons/inputmapswapper/ui.tscn")
var file_path = "res://input-maps/"
var found_profiles: VBoxContainer

func _enter_tree() -> void:
	# Ensure the directory exists
	var dir = DirAccess.open("res://")
	if !dir.dir_exists(file_path):
		dir.make_dir(file_path)
		print("Created directory: ", file_path)

	panel = UI.instantiate()
	panel.name = "InputMapSwapperPanel" # Give it a unique name
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL, panel)
	found_profiles = panel.get_node("FoundProfiles")

	_load_configs()

	# Connect signals from your UI panel (assuming your UI.tscn has buttons for save/load)
	# Example: If your UI has a "save_button" and "load_button"
	if panel.has_node("SaveButton"):
		panel.get_node("SaveButton").pressed.connect(func(): _save_config())

	# Initial load (optional, you might want to call this via a button)
	# _load_config("test") # Don't call on _enter_tree directly unless you want it to load every time the plugin is enabled/reloaded.

	print("InputMapSwapper plugin loaded.")

func _load_configs() -> void:
	for child in found_profiles.get_children():
		child.queue_free()
		
	for file in DirAccess.get_files_at("res://input-maps"):
		var new_button = Button.new()
		new_button.text = file.get_file()
		new_button.pressed.connect(func(): _load_config("res://input-maps/" + file.get_file()))
		found_profiles.add_child(new_button)

func _exit_tree() -> void:
	remove_control_from_docks(panel)
	if is_instance_valid(panel):
		panel.queue_free()
	print("InputMapSwapper plugin exited.")

func _save_config() -> void:
	var name = panel.get_node("TextEdit").text + ".cfg"
	InputMapManager.save_system(name)
	_load_configs()

func _load_config(name: String) -> void:
	InputMapManager.load_system(name)
