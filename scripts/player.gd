extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const LADDER_SPEED = 100.0
const BREAK_DELAY = 0.5
const RESPAWN_DELAY = 3.0
const COYOTE_TIME = 0.08

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer = $jump_sound
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var tile_map_layer___main: TileMapLayer = $"../TileMapLayer - Main"
@onready var tile_map_layer___breakables: TileMapLayer = $"../TileMapLayer - Breakables"


var is_dead: bool = false
var is_big: bool = false
var on_ladder: bool = false
var broken_tiles: Array = []
var breaking_tiles: Dictionary = {}  # Vector2i -> float (timer)
var respawn_queue: Array = []
var coyote_timer: float = 0.0

func _ready() -> void:
	for cell in tile_map_layer___breakables.get_used_cells():
		var tile_data = tile_map_layer___breakables.get_cell_tile_data(cell)
		if tile_data and tile_data.get_custom_data("is_breakable"):
			broken_tiles.append({
				"pos": cell,
				"source_id": tile_map_layer___breakables.get_cell_source_id(cell),
				"atlas_coords": tile_map_layer___breakables.get_cell_atlas_coords(cell),
				"alternative": tile_map_layer___breakables.get_cell_alternative_tile(cell)
			})

func respawn() -> void:
	velocity = Vector2.ZERO
	global_position = Vector2(1, 0)
	is_dead = false
	is_big = false
	on_ladder = false
	scale = Vector2(1, 1)
	breaking_tiles.clear()
	respawn_queue.clear()
	for tile in broken_tiles:
		tile_map_layer___breakables.set_cell(tile["pos"], tile["source_id"], tile["atlas_coords"], tile["alternative"])

func become_big() -> void:
	is_big = true
	scale = Vector2(1.5, 1.5)

func become_small() -> void:
	is_big = false
	scale = Vector2(1, 1)

func is_on_ice() -> bool:
	var player_pos = global_position + Vector2(0, 16)
	var tile_pos = tile_map_layer___main.local_to_map(tile_map_layer___main.to_local(player_pos))
	var tile_data = tile_map_layer___main.get_cell_tile_data(tile_pos)
	if tile_data:
		return tile_data.get_custom_data("is_ice") == true
	return false

func check_ladder_tile(pos: Vector2i) -> bool:
	var tile_data = tile_map_layer___main.get_cell_tile_data(pos)
	return tile_data != null and tile_data.get_custom_data("is_ladder") == true

func is_on_ladder_tile() -> bool:
	var feet_pos = global_position
	var feet_map = tile_map_layer___main.local_to_map(tile_map_layer___main.to_local(feet_pos))
	if check_ladder_tile(feet_map):
		return true
	# Also check one cell above the feet (player origin is at the feet)
	if check_ladder_tile(feet_map + Vector2i(0, -1)):
		return true
	return false

func get_breakable_tile() -> Vector2i:
	var player_pos = global_position + Vector2(0, 16)
	var tile_pos = tile_map_layer___breakables.local_to_map(tile_map_layer___breakables.to_local(player_pos))
	var tile_data = tile_map_layer___breakables.get_cell_tile_data(tile_pos)
	if tile_data and tile_data.get_custom_data("is_breakable"):
		return tile_pos
	return Vector2i(-1, -1)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity += get_gravity() * delta
		global_position += velocity * delta
		return

	# --- Ladder State Management ---
	var ladder_overlap = is_on_ladder_tile()

	# Enter ladder mode only when overlapping a ladder tile AND pressing up or down
	if not on_ladder and ladder_overlap:
		if Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
			on_ladder = true
			velocity = Vector2.ZERO

	# Exit ladder if the player drifts off all ladder tiles
	if on_ladder and not ladder_overlap:
		on_ladder = false

	# --- Ladder Physics ---
	if on_ladder:
		# Jump off ladder: only when jump is pressed WITHOUT move_up on the same frame
		# (prevents Up Arrow triggering both climb and jump simultaneously)
		if Input.is_action_just_pressed("jump") and not Input.is_action_just_pressed("move_up"):
			on_ladder = false
			velocity.y = JUMP_VELOCITY
			jump_sound.play()
			coyote_timer = 0.0
		else:
			# Climb: up/down input drives vertical movement, no gravity
			var climb_dir = Input.get_axis("move_up", "move_down")
			velocity.y = climb_dir * LADDER_SPEED
			velocity.x = 0

			# Top dismount: pressing up but no ladder tile above
			if climb_dir < 0:
				var feet_map = tile_map_layer___main.local_to_map(tile_map_layer___main.to_local(global_position))
				var above_map = feet_map + Vector2i(0, -1)
				if not check_ladder_tile(above_map):
					on_ladder = false
					velocity.y = -LADDER_SPEED

			# Bottom dismount: grounded while pressing down or idle
			if on_ladder and is_on_floor() and climb_dir >= 0:
				on_ladder = false

	# --- Normal Physics (when not on ladder) ---
	if not on_ladder:
		if is_on_floor():
			coyote_timer = COYOTE_TIME
		else:
			coyote_timer -= delta
			velocity += get_gravity() * delta

		if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			jump_sound.play()
			coyote_timer = 0.0

	# --- Direction, Animation & Horizontal Movement ---
	var direction := Input.get_axis("move_left", "move_right")
	var crouching := Input.is_action_pressed("move_down") and is_on_floor() and not on_ladder

	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true

	if on_ladder:
		play_animation("idle")
	elif is_on_floor():
		if crouching:
			play_animation("crouch")
		elif direction == 0:
			play_animation("idle")
		else:
			play_animation("run")
	else:
		play_animation("jump")

	if not on_ladder:
		if is_on_floor() and is_on_ice():
			velocity.x = lerp(velocity.x, direction * SPEED, 0.025)
		elif direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# Register any breakable tile the player touches - each gets its own timer
	if is_on_floor():
		var tile = get_breakable_tile()
		if tile != Vector2i(-1, -1) and not breaking_tiles.has(tile):
			breaking_tiles[tile] = 0.0

	# Tick all active breaking timers and break tiles that have hit the delay
	var to_break: Array = []
	for tile_pos in breaking_tiles:
		breaking_tiles[tile_pos] += delta
		if breaking_tiles[tile_pos] >= BREAK_DELAY:
			to_break.append(tile_pos)

	for tile_pos in to_break:
		breaking_tiles.erase(tile_pos)
		for tile in broken_tiles:
			if tile["pos"] == tile_pos:
				respawn_queue.append({
					"pos": tile["pos"],
					"source_id": tile["source_id"],
					"atlas_coords": tile["atlas_coords"],
					"alternative": tile["alternative"],
					"timer": 0.0
				})
				break
		tile_map_layer___breakables.erase_cell(tile_pos)

	# Tick respawn queue and restore tiles when ready
	for tile in respawn_queue:
		tile["timer"] += delta

	respawn_queue = respawn_queue.filter(func(tile):
		if tile["timer"] >= RESPAWN_DELAY:
			tile_map_layer___breakables.set_cell(tile["pos"], tile["source_id"], tile["atlas_coords"], tile["alternative"])
			return false
		return true
	)

func play_animation(anim: String) -> void:
	if animated_sprite_2d.animation != anim:
		animated_sprite_2d.play(anim)
