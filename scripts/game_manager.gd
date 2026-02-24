extends Node
@onready var score: Control = $"../CanvasLayer/Control/VBoxContainer/Score/Label"
@onready var deaths: Control = $"../CanvasLayer/Control/VBoxContainer/Deaths/Label"

func _ready():
	score.text = str(GameState.score)
	deaths.text = str(GameState.deaths)

func add_score():
	GameState.score += 1
	score.text = str(GameState.score)
	
func add_deaths():
	GameState.deaths += 1
	deaths.text = str(GameState.deaths)
	
func next_level():
	if GameState.level == 1:
		get_tree().change_scene_to_file("res://scenes/level_2.tscn")
		GameState.level += 1
		
