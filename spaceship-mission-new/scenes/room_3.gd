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


func _on_puzzels_pressed() -> void:
	get_tree().change_scene_to_file("res://minigame/15puzzle/Board.tscn")
