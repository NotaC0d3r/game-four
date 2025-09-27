extends CharacterBody2D

@export var move_speed: float = 100.0
@export var jump_speed: float = 210.0
@export var gravity: float = 900.0
@export var throw_force: Vector2 = Vector2(280, -100)  # reduce for shorter throws

var held: RigidBody2D = null

@onready var grab_area: Area2D = $GrabArea        # small Area2D in front of player
@onready var sprite: Node2D = $Sprite2D           # for flipping / facing

func _physics_process(delta: float) -> void:
	# Horizontal movement
	var dir := Input.get_axis("left", "right")
	velocity.x = dir * move_speed

	# Gravity + jump
	if not is_on_floor():
		velocity.y += gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_speed

	move_and_slide()

	if dir != 0:
		sprite.scale.x = sign(dir)

	# Interactions
	if Input.is_action_just_pressed("pickup"):
		_try_pick_or_drop()

	if Input.is_action_just_pressed("throw") and held:
		_throw()

func _try_pick_or_drop() -> void:
	if held:
		_drop()
		return

	# Pick the first RigidBody2D in grab area that supports be_picked()
	for body in grab_area.get_overlapping_bodies():
		if body is RigidBody2D and body.has_method("be_picked"):
			held = body

			# Disable collisions BEFORE parenting to avoid pushback
			held.be_picked(self)

			# Parent to player and place just outside our collider
			held.reparent(self)
			var facing := sprite.scale.x
			if facing == 0: facing = 1
			held.position = Vector2(16 * facing, -12)  # tweak based on your sprite size
			return

func _drop() -> void:
	if held:
		var h := held
		# Back to world
		h.reparent(get_tree().current_scene)
		var facing := sprite.scale.x
		if facing == 0: facing = 1
		h.global_position = global_position + Vector2(16 * facing, 0)

		# Restore physics/collisions
		if h.has_method("be_released"):
			h.be_released()

		held = null

func _throw() -> void:
	if held:
		var facing := sprite.scale.x
		if facing == 0: facing = 1

		var h := held
		# Back to world
		h.reparent(get_tree().current_scene)
		h.global_position = global_position + Vector2(18 * facing, -4)

		# Restore physics/collisions (CRITICAL so water can detect it)
		if h.has_method("be_released"):
			h.be_released()

		# Give it an arc
		h.linear_velocity = Vector2(throw_force.x * facing, throw_force.y)

		held = null
