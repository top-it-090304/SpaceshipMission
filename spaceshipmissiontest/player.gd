extends CharacterBody2D

@export var speed: float = 300.0

var target: Vector2

func _ready() -> void:
	target = global_position

func _input(event: InputEvent) -> void:
	# одно нажатие мыши
	if event.is_action_pressed("click"):
		target = get_global_mouse_position()  # мировая позиция клика [web:36]

func _physics_process(delta: float) -> void:
	# двигаемся к цели только по X
	var desired := Vector2(target.x, global_position.y)

	# если ещё далеко – идём
	if global_position.distance_to(desired) > 2.0:
		var dir: Vector2 = global_position.direction_to(desired) # нормализованное направление [web:30]
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO  # остановка ровно в точке

	move_and_slide()
