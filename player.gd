extends CharacterBody2D

@export var move_speed: float = 200.0
@export var jump_speed: float = 360.0
@export var gravity: float = 900.0
@export var throw_force: Vector2 = Vector2(280, -100)

var held: RigidBody2D = null
@onready var grab_area: Area2D = $GrabArea
@onready var sprite: Node2D = $Sprite2D

func _physics_process(delta: float) -> void:
	# horizontal
	var dir := Input.get_axis("left", "right")  # keep your existing input names
	velocity.x = dir * move_speed

	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_speed

	move_and_slide()

	# face direction (optional)
	if dir != 0:
		sprite.scale.x = sign(dir)

	# pickup / drop
	if Input.is_action_just_pressed("pickup"):
		_try_pick_or_drop()

	# throw
	if Input.is_action_just_pressed("throw") and held:
		_throw()

func _try_pick_or_drop() -> void:
	if held:
		_drop()
		return

	# find a Sacrifice in the grab area
	for body in grab_area.get_overlapping_bodies():
		if body is RigidBody2D and body.has_method("be_picked"):
			held = body

			# IMPORTANT: disable collisions BEFORE reparenting to avoid pushback
			held.be_picked(self)

			# parent to player (we'll set a local offset)
			held.reparent(self)

			# place clearly OUTSIDE the player's collider
			var dir := sprite.scale.x
			if dir == 0:
				dir = 1  # default facing right if standing still
			held.position = Vector2(16 * dir, -12)  # tweak to your sprite size
			return

func _drop() -> void:
	if held:
		var h := held
		# move back to world and place a bit in front
		h.reparent(get_tree().current_scene)
		var dir := sprite.scale.x
		if dir == 0:
			dir = 1
		h.global_position = global_position + Vector2(16 * dir, 0)

		# restore collisions & unfreeze
		if h.has_method("be_released"):
			h.be_released()
		held = null

func _throw() -> void:
	if held:
		var dir := sprite.scale.x
		if dir == 0:
			dir = 1

		var h := held
		h.reparent(get_tree().current_scene)
		h.global_position = global_position + Vector2(18 * dir, -4)

		# restore collisions & unfreeze, then give it an arc
		if h.has_method("be_released"):
			h.be_released()
		h.linear_velocity = Vector2(throw_force.x * dir, throw_force.y)

		held = null
