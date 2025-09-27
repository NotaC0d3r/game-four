extends Area2D

@export var kills_player: bool = true
@export var convert_sacrifice_to_platform: bool = true
@export var ignore_held_sacrifice: bool = true
@export var float_before_platform: bool = false
@export var float_time: float = 0.6

var _float_timers := {}

func _ready() -> void:
	# Make sure this script is really running
	print("[Water] _ready on node:", name, " in scene:", get_tree().current_scene)

	# Ensure Area2D is active
	monitoring = true
	monitorable = true

	# TEMP: brute-force mask so we listen to everything (we’ll tighten later)
	# 20 bits on (Godot 4 uses 20 physics layers)
	collision_mask = 0xFFFFF

	# Self-connect the signal so we don’t rely on editor wiring
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	print("[Water] layer=", collision_layer, " mask=", collision_mask)

func _on_body_entered(body: Node) -> void:
	print("[Water] body_entered:", body.name, " type=", body.get_class())

	# Sacrifice → platform
	if convert_sacrifice_to_platform and body.has_method("die_and_become_platform"):
		if ignore_held_sacrifice and "picked" in body and body.picked:
			print("[Water] Sacrifice is currently held; ignoring.")
			return

		if float_before_platform:
			_begin_float(body)
		else:
			print("[Water] Converting to platform now.")
			body.die_and_become_platform()
		return

	# Player falls in
	if kills_player and body.is_in_group("player"):
		print("[Water] Player entered; reloading scene.")
		get_tree().reload_current_scene()

func _begin_float(sacrifice: Node) -> void:
	print("[Water] Begin float then platform.")
	if sacrifice is RigidBody2D:
		sacrifice.linear_velocity = Vector2.ZERO
		sacrifice.angular_velocity = 0
		sacrifice.linear_damp = 8.0
		sacrifice.angular_damp = 8.0

	var t := Timer.new()
	t.one_shot = true
	t.wait_time = float_time
	add_child(t)
	t.timeout.connect(func ():
		if is_instance_valid(sacrifice):
			print("[Water] Float done → platform.")
			sacrifice.die_and_become_platform()
		t.queue_free()
	)
	t.start()
