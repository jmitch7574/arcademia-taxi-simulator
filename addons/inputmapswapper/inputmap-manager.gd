class_name InputMapManager

static var file_path_base = "res://input-maps/"
static var file_path_user = "user://input-maps/"

static func ensure_base_dir(check_path : String) -> void:
	if not DirAccess.dir_exists_absolute(check_path): 
		DirAccess.make_dir_absolute(check_path)

static func save_system(name : String) -> void:
	ensure_base_dir("res://input-maps/")
	var config = ConfigFile.new()
	config.set_value("meta", "version", 1)

	var project_setting_keys = ProjectSettings.get_property_list()

	for key in project_setting_keys:
		if key.name.begins_with("input/"):
			var setting_name = key.name
			var setting_value = ProjectSettings.get_setting(setting_name)
			setting_name = setting_name.replace("input/", "")
			config.set_value("input", setting_name, setting_value)
	
	var target_file = "res://input-maps/" + name
	
	var error = config.save(target_file)
	if error != OK:
		push_error("Failed to save")

static func save_runtime(name : String) -> void:
	ensure_base_dir("user://input-maps/")
	var config = ConfigFile.new()

	for action in InputMap.get_actions():
		var entry = {
			"deadzone": InputMap.action_get_deadzone(action),
			"events": []
		}
		for event in InputMap.action_get_events(action):
			entry["events"].append(event)
		
		config.set_value("input", action, entry)
	
	var target_file = "user://input-maps/" + name
	
	var error = config.save(target_file)
	if error != OK:
		push_error("Failed to save")
	
static func load_system(target_file : String) -> void:
	var config = ConfigFile.new()
	var error = config.load(target_file)

	if error != OK:
		push_error("Error loading InputMap: ", error)
		return
	
	var project_setting_keys = ProjectSettings.get_property_list()
	for key in project_setting_keys:
		if key.name.begins_with("input/"):
			ProjectSettings.clear(key["name"]) 

	var sections = config.get_sections()
	if "input" in sections:
		var keys = config.get_section_keys("input")
		for key in keys:
			ProjectSettings.set_setting("input/" + key, config.get_value("input", key))
	else:
		print("No 'input' section found in the config file: ", target_file)

	print("InputMap imported from: ", target_file)
	
	var save_error = ProjectSettings.save() # Capture the return value
	if save_error == OK:
		print("Project settings saved successfully to project.godot!")
	else:
		push_error("FAILED to save project settings! Error code: ", save_error) # THIS IS KEY
	
static func load_runtime(target_file : String) -> void:
	var config = ConfigFile.new()
	var error = config.load(target_file)

	if error != OK:
		push_error("Error loading InputMap: ", error)
		return
	
	var action_keys = InputMap.get_actions()

	for key in action_keys:
		InputMap.action_erase_events(key)

	var sections = config.get_sections()
	if "input" in sections:
		var keys = config.get_section_keys("input")
		for key in keys:
			InputMap.add_action(key)
			var events = config.get_value("input", key)
			InputMap.action_set_deadzone(key, events["deadzone"])
			for event in events["events"]:
				InputMap.action_add_event(key, event)
				
				if event is InputEventKey:
					print("Added event %s to %s" % [OS.get_keycode_string(event.keycode), key])
	else:
		print("No 'input' section found in the config file: ", target_file)

	

	print("InputMap imported from: ", target_file)
