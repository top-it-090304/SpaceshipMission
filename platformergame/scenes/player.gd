extends CharacterBody2D

const GRAVITY : int = 5000
const JUMP_SPEED : int = -1800

func _physics_process(delta):
	velocity.y += GRAVITY * delta
	if is_on_floor():
		if not get_parent().game_running:
			$AnimatedSprite2D.play("idle")
		if Input.is_action_pressed("ui_accept"):
			velocity.y = JUMP_SPEED
		else:
			$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("jump")
	move_and_slide()
