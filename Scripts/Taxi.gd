class_name Taxi
extends VehicleBody3D

@export var MAX_STEER = 0.5
@export var ENGINE_POWER = 500
@export var MAX_SPEED = 30
var time_upside = 0

func _physics_process(delta: float) -> void:
	steering = Input.get_axis("move_right", "move_left") * MAX_STEER
	engine_force = Input.get_axis("c_button", "a_button") * ENGINE_POWER
	
	if (Input.is_action_pressed("b_button") and not are_all_wheels_off()):
		var decay_factor = pow(0.5, delta / 2)
		
		# Apply the decay to the current speed
		linear_velocity *= decay_factor
	
	if linear_velocity.length() > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED
	
	if Input.is_action_just_pressed("reset_pos"):
		position = Vector3(0, 0, 0)
		rotation_degrees = Vector3(0, 0, 0)
	
	if are_all_wheels_off():
		time_upside += delta
		if time_upside > 4:
			position = Vector3(0, 0, 0)
			rotation_degrees = Vector3(0, 0, 0)
	else:
		time_upside = 0
		
	if global_position.y < -8:
		position = Vector3(0, 0, 0)
		rotation_degrees = Vector3(0, 0, 0)

func are_all_wheels_off():
	for child in get_children():
		if child is VehicleWheel3D:
			if child.is_in_contact() and child.use_as_traction:
				return false
	
	return true
