extends CharacterBody2D

const SPEED = 40.0

var direction = 1

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	velocity.x = direction * SPEED
	move_and_slide()

	if is_on_wall():
		direction *= -1

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.become_big()
		queue_free()
