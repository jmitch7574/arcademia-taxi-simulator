extends Camera3D

@export var target: Node3D  # assign your taxi/player here
@export var follow_distance: float = 10.0
@export var height: float = 4.0
@export var smooth_speed: float = 5.0

func _process(delta):
	if not target:
		return

	# Get only the YAW from the target's rotation
	var target_yaw = target.global_transform.basis.get_euler().y
	var yaw_only_basis = Basis(Vector3.UP, target_yaw)

	# Calculate offset position behind the target
	var offset = yaw_only_basis.z * -follow_distance + Vector3.UP * height
	var target_position = target.global_transform.origin + offset

	# Smoothly move the camera toward that position
	global_transform.origin = global_transform.origin.lerp(target_position, delta * smooth_speed)

	# Look at the target, but use a stable up vector
	look_at(target.global_transform.origin, Vector3.UP)
