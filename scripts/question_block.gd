extends Node2D

enum State { UNBUMPED, BUMPED }

var state = State.UNBUMPED
var original_position: Vector2

func _ready() -> void:
	original_position = global_position

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and state == State.UNBUMPED:
		bump_block()
	
func bump_block() -> void:
	state = State.BUMPED
	$Sprite2D.frame = 1
	GameState.spawn_beer_bottle(original_position + Vector2(0, -20))
	animate_bump()

func animate_bump() -> void:
	global_position.y -= 10
	await get_tree().create_timer(0.2).timeout
	global_position = original_position
