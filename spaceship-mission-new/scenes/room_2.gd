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

	# если нужно запретить повторный вход, когда сундук уже открыт:
	if main_game.chest_opened:
		return

	main_game.open_chest()
	
func _on_screwdriver_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game:
		main_game.inventory.add_item("key")
	$Screwdriver.hide()
