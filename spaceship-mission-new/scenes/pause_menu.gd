extends Control

func _ready() -> void:
	if not $Background/ResumeButton.pressed.is_connected(_on_resume_pressed):
		$Background/ResumeButton.pressed.connect(_on_resume_pressed)
	if not $Background/ResetButton.pressed.is_connected(_on_reset_pressed):
		$Background/ResetButton.pressed.connect(_on_reset_pressed)
	if not $Background/QuitButton.pressed.is_connected(_on_quit_pressed):
		$Background/QuitButton.pressed.connect(_on_quit_pressed)

	$Background/MusicSlider.value = AudioManager.music_volume
	$Background/SFXSlider.value = AudioManager.sfx_volume
	if not $Background/MusicSlider.value_changed.is_connected(AudioManager.set_music_volume):
		$Background/MusicSlider.value_changed.connect(AudioManager.set_music_volume)
	if not $Background/SFXSlider.value_changed.is_connected(AudioManager.set_sfx_volume):
		$Background/SFXSlider.value_changed.connect(AudioManager.set_sfx_volume)

func _on_resume_pressed() -> void:
	AudioManager.play_click()
	queue_free()

func _on_reset_pressed() -> void:
	PycoLog.log_event_by_type("quest_reset", {})
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")

func _on_quit_pressed() -> void:
	GameState.save()
	await PycoLog.log_stop_playing()
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
