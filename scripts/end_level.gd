extends Area2D

@onready var big_smoke_puff: AnimatedSprite2D = $big_smoke_puff
@onready var flower_petal_smoke_puff: AnimatedSprite2D = $flower_petal_smoke_puff
@onready var small_smoke_puff: AnimatedSprite2D = $small_smoke_puff
@onready var star_smoke_puff: AnimatedSprite2D = $star_smoke_puff
@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	big_smoke_puff.visible = false
	flower_petal_smoke_puff.visible = false
	small_smoke_puff.visible = false
	star_smoke_puff.visible = false
	label.text = "Level " + str(GameState.level) + " Complete!"
	label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		label.visible = true
		animation_player.play("text_flash")
		big_smoke_puff.visible = true
		big_smoke_puff.play("big_smoke_puff")
		flower_petal_smoke_puff.visible = true
		flower_petal_smoke_puff.play("flower_petal_smoke_puff")
		small_smoke_puff.visible = true
		small_smoke_puff.play("small_smoke_puff")
		star_smoke_puff.visible = true
		star_smoke_puff.play("star_smoke_puff")
