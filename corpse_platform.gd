extends StaticBody2D

@onready var colshape: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer
@onready var sprite: CanvasItem = null

@export var one_way: bool = false
@export var one_way_margin: float = 6.0

func _ready() -> void:
	# Assign sprite safely (no "?" operator)
	if has_node("Sprite2D"):
		sprite = $Sprite2D

	z_index = 5

	if is_instance_valid(colshape):
		colshape.one_way_collision = one_way
		colshape.one_way_collision_margin = one_way_margin

	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

	if sprite:
		sprite.modulate.a = 1.0  # fully visible

func begin_decay(seconds: float) -> void:
	seconds = max(0.1, seconds)  # avoid instant despawn
	timer.wait_time = seconds
	timer.start()

func _on_timer_timeout() -> void:
	queue_free()
