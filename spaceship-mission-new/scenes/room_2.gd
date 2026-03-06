extends Node2D

signal go_left
signal go_right

func _ready() -> void:
	$LeftArrow.pressed.connect(_on_left_pressed)
	$RightArrow.pressed.connect(_on_right_pressed)

func _on_left_pressed() -> void:
	emit_signal("go_left")

func _on_right_pressed() -> void:
	emit_signal("go_right")
	
func _on_box1_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return

	if main_game.chest1_opened:
		return

	main_game.open_chest1()
	
func _on_box2_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return

	if main_game.chest2_opened:
		return

	main_game.open_chest2()
	
