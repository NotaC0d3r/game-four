extends RigidBody2D

@export var corpse_platform_scene: PackedScene
@export var corpse_lifetime: float = 6.0
@onready var decay_timer: Timer = $DecayTimer
@onready var colshape: CollisionShape2D = $CollisionShape2D

var picked := false
var _saved_layer: int
var _saved_mask: int

func _ready() -> void:
	if decay_timer:
		decay_timer.wait_time = corpse_lifetime

func be_picked(player: Node) -> void:
	# mark picked, freeze physics, and disable ALL collisions to avoid pushing the player
	picked = true
	freeze = true

	_saved_layer = collision_layer
	_saved_mask  = collision_mask

	# turn off collisions this frame safely
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if is_instance_valid(colshape):
		colshape.set_deferred("disabled", true)

	# also kill velocities so it doesn't jitter in-hand
	linear_velocity = Vector2.ZERO
	angular_velocity = 0

func be_released() -> void:
	# restore collisions and unfreeze
	if is_instance_valid(colshape):
		colshape.set_deferred("disabled", false)
	set_deferred("collision_layer", _saved_layer)
	set_deferred("collision_mask", _saved_mask)
	freeze = false
	picked = false

func die_and_become_platform() -> void:
	# spawn platform at ground-aligned position
	if not corpse_platform_scene:
		queue_free()
		return
	var platform := corpse_platform_scene.instantiate()
	platform.global_position = global_position + Vector2(0, 4)
	get_tree().current_scene.add_child(platform)
	platform.call_deferred("begin_decay", corpse_lifetime)
	queue_free()
	
