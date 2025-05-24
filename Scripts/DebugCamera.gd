extends Camera3D


@export var base_move_speed: float
var move_speed: float:
	get:
		if (Input.is_action_pressed("speed_up")):
			return base_move_speed * 10
		else:
			return base_move_speed

func _ready():
	rotation_degrees = Vector3(-60, 0, 0)

func _process(_delta: float):
	if (Input.is_action_pressed("move_left")):
		position -= Vector3(basis.x.x, 0, basis.x.z) * move_speed
	if (Input.is_action_pressed("move_right")):
		position += Vector3(basis.x.x, 0, basis.x.z) * move_speed
	if (Input.is_action_pressed("move_up")):
		position -= Vector3(basis.z.x, 0, basis.z.z) * move_speed
	if (Input.is_action_pressed("move_down")):
		position += Vector3(basis.z.x, 0, basis.z.z) * move_speed
	if (Input.is_action_pressed("move_forward")):
		position += Vector3(0, 1, 0) * move_speed
	if (Input.is_action_pressed("move_backward")):
		position -= Vector3(0, 1, 0) * move_speed
	if (Input.is_action_pressed("rotate_left")):
		rotation_degrees += Vector3(0, 3, 0)
	if (Input.is_action_pressed("rotate_right")):
		rotation_degrees -= Vector3(0, 3, 0)
	pass
