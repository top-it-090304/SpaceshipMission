extends CharacterBody2D

const GRAVITY: float = 2000.0
const JUMP_VELOCITY: float = -720.0

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	if is_on_floor():
		if get_parent().game_running:
			$AnimatedSprite2D.play("walk")
		else:
			$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.play("jump")

	move_and_slide()

func jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func reset() -> void:
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("idle")
