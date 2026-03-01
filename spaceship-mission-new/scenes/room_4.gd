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
	
	
func _on_main_massage_button_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game:
		main_game.open_message4()
