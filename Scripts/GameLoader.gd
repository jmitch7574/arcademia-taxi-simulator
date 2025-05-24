extends Node3D

const LINCOLN = preload("res://SavedGens/Lincoln.tscn")
const TAXI_PREFAB = preload("res://Prefabs/taxi_prefab.tscn")

func _ready() -> void:
	var lincoln : StoredWorldInfo = LINCOLN.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	add_child(lincoln)
	var taxi = TAXI_PREFAB.instantiate()
	add_child(taxi)
	taxi.global_position = lincoln.spawn_point.global_position
