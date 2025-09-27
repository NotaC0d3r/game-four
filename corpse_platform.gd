extends StaticBody2D

@onready var colshape: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer
@onready var sprite: Node = null

@export var fade_out: bool = true
@export var fade_time: float = 0.25
@export var one_way: bool = false
@export var one_way_margin: float = 6.0

func _ready() -> void:
	if has_node("Sprite2D"):
		sprite = $Sprite2D

	if is_instance_valid(colshape):
		colshape.one_way_collision = one_way
		colshape.one_way_collision_margin = one_way_margin

	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

	z_index = 5

func begin_decay(seconds: float) -> void:
	timer.wait_time = max(0.05, seconds)
	timer.start()

func _on_timer_timeout() -> void:
	if fade_out:
		var tw := create_tween()
		if sprite and sprite is CanvasItem:
			tw.tween_property(sprite, "modulate:a", 0.0, fade_time)
		tw.tween_callback(Callable(self, "queue_free"))
	else:
		queue_free()
