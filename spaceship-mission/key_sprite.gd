extends Area2D

@onready var main = get_tree().get_current_scene()  
@onready var tex_key_1 = preload("res://items/key_1.png")




func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item = {
			"id": "key_1",
			"icon": tex_key_1,
		}
		main.add_item(item)
		queue_free()
