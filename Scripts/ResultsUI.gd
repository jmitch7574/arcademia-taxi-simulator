extends Control

@export var s_style : LabelSettings
@export var a_style : LabelSettings
@export var b_style : LabelSettings
@export var c_style : LabelSettings
@export var d_style : LabelSettings

@onready var money_amount: Label = $MoneyAmount
@onready var fare_amount: Label = $FareAmount
@onready var final_rank: Label = $FinalRank
@onready var exit_hint: Label = $ExitHint

func _ready() -> void:
	money_amount.text = "$" + str(GameRoot.score)
	fare_amount.text = str(GameRoot.fare_count)
	
	if OS.has_feature("arcade_release"):
		exit_hint.text = "Press F for Main Menu"
	
	if GameRoot.score >= 200:
		final_rank.text = "S"
		final_rank.label_settings = s_style
	elif GameRoot.score >= 125:
		final_rank.text = "A"
		final_rank.label_settings = a_style
	elif GameRoot.score >= 80:
		final_rank.text = "B"
		final_rank.label_settings = b_style
	elif GameRoot.score >= 50:
		final_rank.text = "C"
		final_rank.label_settings = c_style
	else:
		final_rank.text = "D"
		final_rank.label_settings = d_style
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
