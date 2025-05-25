extends Control

@onready var time: Label = $"Time and Score/Time"
@onready var money: Label = $"Time and Score/Money"
@onready var current_fare: Label = $"Current Destination/CurrentFare"
@onready var distance: Label = $"Current Destination/Distance"
@onready var build_name: Label = $"Current Destination/BuildName"

func _process(delta: float):
	time.text = str(floor(GameRoot.time / 60.0)) + ":" + str(floor(time) % 60)
	distance.text = "DIST: " + str(floor(GameRoot.dist))

func _on_game_root_fare_complete() -> void:
	money.text = "$" + str(GameRoot.score)

func _on_game_root_fare_started(building_name: Variant, fare_amount: Variant) -> void:
	current_fare.text = "$" + str(fare_amount)
	build_name.text = building_name
