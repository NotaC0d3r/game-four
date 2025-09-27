extends RigidBody2D

@export var corpse_platform_scene: PackedScene
@export var corpse_lifetime: float = 6.0

@onready var decay_timer: Timer = $DecayTimer if has_node("DecayTimer") else null
@onready var colshape: CollisionShape2D = $CollisionShape2D

var picked: bool = false
var _saved_layer: int = 0
var _saved_mask: int = 0

func _ready() -> void:
	if decay_timer:
		decay_timer.wait_time = corpse_lifetime

func be_picked(_holder: Node) -> void:
	# Freeze and disable ALL collisions so it doesn't push the player
	picked = true
	freeze = true

	_saved_layer = collision_layer
	_saved_mask  = collision_mask

	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if is_instance_valid(colshape):
		colshape.set_deferred("disabled", true)

	# Kill any residual motion
	linear_velocity = Vector2.ZERO
	angular_velocity = 0

func be_released() -> void:
	# Restore normal physics/collisions
	if is_instance_valid(colshape):
		colshape.set_deferred("disabled", false)
	set_deferred("collision_layer", _saved_layer)
	set_deferred("collision_mask", _saved_mask)
	freeze = false
	picked = false

func die_and_become_platform() -> void:
	# Build a simple platform dynamically (no external .tscn needed)
	var platform := StaticBody2D.new()

	# Collider
	var colshape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 10)  # width x height
	colshape.shape = rect
	platform.add_child(colshape)

	# Sprite (make sure you replace the texture path with your own)
	var sprite := Sprite2D.new()
	sprite.texture = preload("res://CorpsePlatform.png") # <-- change to your image
	sprite.centered = true
	sprite.position = Vector2.ZERO
	platform.add_child(sprite)

	# Make sure it's visible
	platform.z_index = 100

	# Layers/masks
	platform.collision_layer = 1
	platform.collision_mask = 0

	# Timer to despawn after corpse_lifetime
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = max(0.2, corpse_lifetime)
	platform.add_child(t)
	t.timeout.connect(func(): platform.queue_free())
	t.start()

	# Place it in the world
	platform.global_position = global_position + Vector2(0, 6)
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(platform)

	queue_free()
