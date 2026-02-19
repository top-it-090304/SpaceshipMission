extends CharacterBody2D


@export var speed: float = 200.0

var target: Vector2

func _ready() -> void:
	target = global_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		# тач на мобильном
		target = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# клик мышью в редакторе / на ПК
		target = event.position


func _physics_process(delta: float) -> void:
	# направление к цели
	var dir := (target - global_position)
	if dir.length() > 4.0:
		velocity = dir.normalized() * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
