extends Area2D

@onready var timer: Timer = $Timer
@onready var hit_sound: AudioStreamPlayer2D = %hit_sound
@onready var game_manager: Node = get_tree().current_scene.get_node("%GameManager")

var stored_body: Node2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_dead:
		return
	body.is_dead = true
	print("You Died!")
	stored_body = body
	hit_sound.play()
	Engine.time_scale = 0.30
	game_manager.add_deaths()
	timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	stored_body.respawn()
	
	# get_tree().reload_current_scene() - old scene reload for resetting after player death
