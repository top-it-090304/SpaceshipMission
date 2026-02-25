extends CharacterBody2D

var speed = 300.0
var target_position = Vector2()

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	target_position = global_position
	anim.play("idle")

func _input(event):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		target_position = get_global_mouse_position()

func _physics_process(delta):
	if position.distance_to(target_position) > 5:
		velocity = position.direction_to(target_position) * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	if velocity.length() > 1:
		if anim.animation != "walk":
			anim.play("walk")
		if velocity.x != 0:
			anim.flip_h = velocity.x < 0
	else:
		if anim.animation != "idle":
			anim.play("idle")
