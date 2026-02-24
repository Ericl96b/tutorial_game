extends Area2D
@onready var game_manager: Node = %GameManager
@onready var timer: Timer = $Timer

func _ready() -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		timer.start()

func _on_timer_timeout() -> void:
	game_manager.next_level()
