extends Area2D

@export var kills_player: bool = true
@export var convert_sacrifice_to_platform: bool = true
@export var ignore_held_sacrifice: bool = true  # avoids killing while you’re carrying it
@export var float_before_platform: bool = false # optional variant below
@export var float_time: float = 0.8            # seconds to bob before becoming platform

# internal: keep timers per body if using float mode
var _float_timers := {}

func _ready() -> void:
	monitoring = true
	monitorable = true
	# Make sure collision layer/mask are fine; default is OK for Area2D.

func _on_body_entered(body: Node) -> void:
	# 1) Sacrifice logic
	if convert_sacrifice_to_platform and body.has_method("die_and_become_platform"):
		# don’t kill it while held (prevents pushback/grief)
		if ignore_held_sacrifice and "picked" in body and body.picked:
			return

		if float_before_platform:
			_begin_float(body)
		else:
			body.die_and_become_platform()
		return

	# 2) Player logic
	if kills_player and body.is_in_group("player"):
		_respawn_player()

func _begin_float(sacrifice: Node) -> void:
	# gentle float: increase damping, zero velocity, then platformize after a delay
	if sacrifice is RigidBody2D:
		sacrifice.linear_velocity = Vector2.ZERO
		sacrifice.angular_velocity = 0
		# Add some drag so it ‘sits’ on water before dying
		sacrifice.linear_damp = 8.0
		sacrifice.angular_damp = 8.0

	# start a one-shot timer for this specific sacrifice
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = float_time
	add_child(t)
	_float_timers[sacrifice] = t
	t.timeout.connect(func ():
		if is_instance_valid(sacrifice):
			sacrifice.die_and_become_platform()
		_float_timers.erase(sacrifice)
		t.queue_free()
	)
	t.start()

func _respawn_player() -> void:
	get_tree().reload_current_scene()
