extends Control

func _ready() -> void:
	$Background/ResumeButton.pressed.connect(_on_resume_pressed)
	$Background/ResetButton.pressed.connect(_on_reset_pressed)
	$Background/QuitButton.pressed.connect(_on_quit_pressed)

func _on_resume_pressed() -> void:
	# Возвращаемся в игру — удаляем меню
	queue_free()

func _on_reset_pressed() -> void:
	# Сбрасываем GameState и переходим на стартовую сцену
	GameState.current_room = 1
	GameState.intro_finished = false
	get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
