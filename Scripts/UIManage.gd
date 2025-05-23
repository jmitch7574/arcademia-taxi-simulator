class_name UIManager
extends Control

@onready var time_and_score: Control = $"Time and Score"
@onready var current_destination: Control = $"Current Destination"

@onready var time: Label = $"Time and Score/Time"
@onready var money: Label = $"Time and Score/Money"
@onready var current_fare: Label = $"Current Destination/CurrentFare"
@onready var distance: Label = $"Current Destination/Distance"
@onready var build_name: Label = $"Current Destination/BuildName"
@onready var arrow_container: Node2D = $"Current Destination/ArrowContainer"
@onready var brake: Label = $"Current Destination/BRAKE"

var current_building : NamedBuilding = null
var taxi : Node3D
var game_start : float

var score_target_y : float = -215
var dest_target_y : float = -215

func _process(delta: float):
	time.text =  "%02d:%02d" % [floori(GameRoot.time / 60.0), floori(GameRoot.time) % 60]
	distance.text = "DIST: " + str(floor(GameRoot.dist)) + "m"
	money.text = "$" + str(GameRoot.score)
	
	time_and_score.position.y = lerp(time_and_score.position.y, score_target_y, 2 * delta)
	current_destination.position.y = lerp(current_destination.position.y, dest_target_y, 2 * delta)
	
	if GameRoot.current_building != null:
		var direction_to_building = (taxi.global_position - GameRoot.current_building.center).normalized()
		var direction_to_building_2d = Vector2(direction_to_building.x, direction_to_building.z).normalized()
		var character_forward_2d = Vector2(taxi.global_basis.z.normalized().x, taxi.global_basis.z.normalized().z).normalized()
		arrow_container.rotation = character_forward_2d.angle_to(direction_to_building_2d)
	
	if GameRoot.dist < 25:
		brake.visible = true
	else:
		brake.visible = false
	
	if GameRoot.time < 10:
		time.set("theme_override_colors/font_color", Color(1.0,0.0,0.0,1.0))
	else:
		time.set("theme_override_colors/font_color", Color(0.0,0.0,0.0,1.0))
	

func _on_game_root_fare_complete() -> void:
	money.text = "$" + str(GameRoot.score)

func _on_game_root_fare_started(building: Variant, fare_amount: Variant) -> void:
	current_fare.text = "$" + str(fare_amount)
	build_name.text = building.building_name
	current_destination.position.y = -215


func _on_generator_world_generated() -> void:
	game_start = Time.get_ticks_msec()
	score_target_y = 0
	dest_target_y = 0
