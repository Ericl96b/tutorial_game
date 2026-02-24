extends Node

var score: int = 0
var level: int = 1
var player_health: = 3
var deaths = 0

func reset():
	score = 0
	level = 1
	player_health = 3
	deaths = 0
	
func spawn_beer_bottle(pos: Vector2) -> void:
	var beer_bottle = preload("res://scenes/beer_bottle.tscn").instantiate()
	beer_bottle.global_position = pos
	get_tree().current_scene.add_child(beer_bottle)
