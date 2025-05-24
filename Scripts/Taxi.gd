extends VehicleBody3D

@export var MAX_STEER = 0.5
@export var ENGINE_POWER = 500
@export var MAX_SPEED = 30
var time_upside = 0

func _physics_process(delta: float) -> void:
	steering = move_toward(steering, Input.get_axis("move_right", "move_left") * MAX_STEER, delta * 10)
	engine_force = Input.get_axis("b_button", "a_button") * ENGINE_POWER
	
	if (Input.is_action_pressed("a_button")):
		print("drive")
		print(Input.get_axis("b_button", "a_button"))
	
	if linear_velocity.length() > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED
		
	
func are_all_wheels_off():
	for child in get_children():
		if child is VehicleWheel3D:
			if child.is_in_contact() and child.use_as_traction:
				return false
	
	return true
