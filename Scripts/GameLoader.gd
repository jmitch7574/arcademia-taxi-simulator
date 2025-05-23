class_name GameRoot
extends Node3D
## Class that manages the gameloop
##
## TODO: Give better name

static var time : float
static var time_elapsed : float = 0
static var score : int = 0
static var dist : float = 0
static var fare_count : int = 0

static var current_building : NamedBuilding = null
var current_fare : int = 0

signal fare_started(building, fare_amount)
signal fare_complete

const TAXI_PREFAB = preload("res://Prefabs/taxi_prefab.tscn")
var taxi : Node3D

const BUILDING_HIGHLIGHT = preload("res://Material/building-highlight.tres")
const BUILDING = preload("res://Material/building.tres")

@onready var debug_camera: Camera3D = $DebugCamera
@onready var world_origin: StoredWorldInfo = $Generator/WorldOrigin
@onready var generator: Generator = $Generator
@onready var game_ui: UIManager = $GameUI

func _ready() -> void:
	score = 0
	time = 45
	time_elapsed = 0
	fare_count = 0

func _process(delta: float) -> void:
	time -= delta
	time_elapsed += delta
	if taxi != null and current_building != null:
		dist = taxi.global_position.distance_to(current_building.center)
		
		if dist < 25 and taxi.linear_velocity.length() < 3:
			complete_fare()
	
	if time < 0 or Input.is_action_just_pressed("end_game"):
		get_tree().change_scene_to_file("res://Scenes/results.tscn")
	if Input.is_action_just_pressed("more_time"):
		time += 10

func _on_generator_world_generated() -> void:
	taxi = TAXI_PREFAB.instantiate()
	add_child(taxi)
	taxi.get_child(0).current = true
	taxi.global_position = world_origin.spawn_point.global_position
	taxi = taxi.get_child(1)
	debug_camera.global_position = world_origin.spawn_point.global_position + Vector3(0, 450, 0)
	game_ui.taxi = taxi
	select_new_fare()
		
func complete_fare():
	score += current_fare
	for building in generator.selectable_buildings:
		building.material = BUILDING
	
	fare_count += 1
	select_new_fare()

func select_new_fare():
	var valid_building_picked = false
	var distance : float = 0
	
	
	while not valid_building_picked:
		current_building = generator.selectable_buildings.pick_random()
		
		var taxi_pos = taxi.global_position
		var building_pos = current_building.center
		distance = taxi_pos.distance_to(building_pos)
		
		if distance > 300:
			continue
		if current_building.building_name.length() > 30:
			continue
		current_fare = randi_range(5, 20) * floor(pow(distance, 0.1))
		valid_building_picked = true
		await get_tree().process_frame
	fare_started.emit(current_building, current_fare)
	var additional_time =  distance / max(pow(time_elapsed / 5, 0.7), 5)
	current_building.material = BUILDING_HIGHLIGHT
	time += additional_time
