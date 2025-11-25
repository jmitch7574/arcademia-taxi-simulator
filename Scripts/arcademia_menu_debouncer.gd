extends Node

var input_bounce : float = 0.175 
var last_hit_time : float

# Keyboard Navigation
var key_nav := {
	KEY_UP: Vector2.UP,
	KEY_DOWN: Vector2.DOWN,
	KEY_LEFT: Vector2.LEFT,
	KEY_RIGHT: Vector2.RIGHT
}

# Controller Navigation
var button_nav := {
	JOY_BUTTON_DPAD_UP: Vector2.UP,
	JOY_BUTTON_DPAD_DOWN: Vector2.DOWN,
	JOY_BUTTON_DPAD_LEFT: Vector2.LEFT,
	JOY_BUTTON_DPAD_RIGHT: Vector2.RIGHT
}

func _input(event):
	if (event is InputEventKey and event.pressed and event.keycode  in key_nav) \
		or (event is InputEventJoypadMotion and abs(event.axis_value) > 0) \
		or (event is InputEventJoypadButton and event.pressed and event.button_index in key_nav):
			
			var now := Time.get_ticks_msec() / 1000.0

			# Block if it's too soon since last UI step
			if now - last_hit_time < input_bounce:
				get_viewport().set_input_as_handled()
				return
				
			# Allow this input and update timer
			last_hit_time = now
