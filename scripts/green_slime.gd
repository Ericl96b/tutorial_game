extends Node2D

const SPEED = 60

var direction = 1

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_floor_right: RayCast2D = $RayCastFloorRight
@onready var ray_cast_floor_left: RayCast2D = $RayCastFloorLeft
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $killzone/CollisionShape2D
@onready var death_sound: AudioStreamPlayer2D = $hit_box/death_sound
@onready var collision_shape_2d___hit_box: CollisionShape2D = $"hit_box/CollisionShape2D - hit_box"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ray_cast_right.is_colliding() or not ray_cast_floor_right.is_colliding():
		direction = -1
		animated_sprite_2d.flip_h = true
	if ray_cast_left.is_colliding() or not ray_cast_floor_left.is_colliding():
		direction = 1
		animated_sprite_2d.flip_h = false
	position.x += direction * SPEED * delta


func _on_hit_box_body_entered(_body: Node2D) -> void:
		if _body.is_dead:
			return
		print("hit box entered")
		_body.velocity.y = -300.0
		direction = 0
		collision_shape_2d___hit_box.queue_free()
		collision_shape_2d.queue_free()
		death_sound.play()
		animated_sprite_2d.play("death")
		animated_sprite_2d.animation_finished.connect(queue_free)
