class_name Taxi
extends VehicleBody3D

@export var BASE_STEER = 0.5
@export var BASE_POWER = 500
@export var BASE_TOP_SPEED = 30

var steering_strength:
	get:
		if (Input.is_action_pressed("c_button") and not are_all_wheels_off()):
			return BASE_STEER * 2.25
		else:
			return BASE_STEER / max((linear_velocity.length() * 4) / BASE_TOP_SPEED, 1)


var time_upside = 0

var base_friction : float
var brake_force : float = 0

@onready var front_left: VehicleWheel3D = $FrontLeft
@onready var back_left: VehicleWheel3D = $BackLeft
@onready var front_right: VehicleWheel3D = $FrontRight
@onready var back_right: VehicleWheel3D = $BackRight

@onready var skid_left_b: GPUParticles3D = $SkidLeftB
@onready var skid_right_b: GPUParticles3D = $SkidRightB
@onready var skid_left_f: GPUParticles3D = $SkidLeftF
@onready var skid_right_f: GPUParticles3D = $SkidRightF



func _ready() -> void:
	base_friction = front_left.wheel_friction_slip

func _physics_process(delta: float) -> void:
	steering = Input.get_axis("move_right", "move_left") * steering_strength
	engine_force = Input.get_axis("b_button", "a_button") * BASE_POWER
	
	
	if (Input.is_action_pressed("c_button") and not are_all_wheels_off()):
		skid_left_b.amount_ratio = 1
		skid_right_b.amount_ratio = 1
		skid_left_f.amount_ratio = 1
		skid_right_f.amount_ratio = 1
		brake = 600
		back_left.wheel_friction_slip = base_friction / 5
		back_right.wheel_friction_slip = base_friction / 5
		front_left.wheel_friction_slip = base_friction / 5
		front_right.wheel_friction_slip = base_friction / 5
	else:
		skid_left_b.amount_ratio = 0
		skid_right_b.amount_ratio = 0
		skid_left_f.amount_ratio = 0
		skid_right_f.amount_ratio = 0
		brake = 0
		back_left.brake = 0
		back_right.brake = 0
		back_left.wheel_friction_slip = base_friction
		back_right.wheel_friction_slip = base_friction
		front_left.wheel_friction_slip = base_friction
		front_right.wheel_friction_slip = base_friction
			
	
	if linear_velocity.length() > BASE_TOP_SPEED:
		linear_velocity = linear_velocity.normalized() * BASE_TOP_SPEED
	
	if Input.is_action_just_pressed("reset_pos"):
		position = Vector3(0, 5, 0)
		rotation_degrees = Vector3(0, 0, 0)
	
	if are_all_wheels_off():
		time_upside += delta
		if time_upside > 4:
			position = Vector3(0, 5, 0)
			rotation_degrees = Vector3(0, 0, 0)
			time_upside = 0
	else:
		time_upside = 0
		
	if global_position.y < -8:
		position = Vector3(0, 5, 0)
		rotation_degrees = Vector3(0, 0, 0)
	
	if Input.is_action_pressed(&"a_button") and Input.is_action_pressed(&"b_button"):
		rotation_degrees.y += Input.get_axis("move_right", "move_left") * steering_strength * 2
		

func are_all_wheels_off():
	for child in get_children():
		if child is VehicleWheel3D:
			if child.is_in_contact() and child.use_as_traction:
				return false
	
	return true
