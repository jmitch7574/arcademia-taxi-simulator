extends VehicleBody3D

@export var MAX_STEER = 0.5
@export var ENGINE_POWER = 500

func _physics_process(delta: float) -> void:
	steering = move_toward(steering, Input.get_axis("move_right", "move_left") * MAX_STEER, delta * 10)
	engine_force = Input.get_axis("b_button", "a_button") * ENGINE_POWER
	
	if (Input.is_action_pressed("a_button")):
		print("drive")
		print(Input.get_axis("b_button", "a_button"))
