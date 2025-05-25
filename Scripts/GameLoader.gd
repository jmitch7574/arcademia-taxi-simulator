extends Node3D

const TAXI_PREFAB = preload("res://Prefabs/taxi_prefab.tscn")
@onready var world_origin: StoredWorldInfo = $Generator/WorldOrigin


func _ready() -> void:
	pass


func _on_generator_file_loaded() -> void:
	var taxi = TAXI_PREFAB.instantiate()
	add_child(taxi)
	taxi.global_position = world_origin.spawn_point.global_position
