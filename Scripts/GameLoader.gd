class_name GameRoot
extends Node3D

static var time : float = 240
static var score : float = 0
static var dist : float = 0

var current_building : NamedBuilding = null
var current_fare : float = 0

signal fare_started(building_name, fare_amount)
signal fare_complete

const TAXI_PREFAB = preload("res://Prefabs/taxi_prefab.tscn")
var taxi : Node3D

@onready var world_origin: StoredWorldInfo = $Generator/WorldOrigin
@onready var generator: Generator = $Generator


func _ready() -> void:
	time = 240
	score = 0


func _process(delta: float) -> void:
	time -= delta

func _on_generator_file_loaded() -> void:
	taxi = TAXI_PREFAB.instantiate()
	add_child(taxi)
	taxi.global_position = world_origin.spawn_point.global_position

func select_new_fare():
	current_building = generator.selectable_buildings.pick_random()
	current_fare = randi_range(5, 20)
	fare_started.emit(current_building.building_name, current_fare)
