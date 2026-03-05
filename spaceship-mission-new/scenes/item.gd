extends Area2D

@export var item_id: String = "key"
@export var texture: Texture2D

func _ready() -> void:
	$Sprite2D.texture = texture
	input_event.connect(_on_input_event)

func _on_input_event(viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var main_game := get_tree().get_first_node_in_group("MainGame")
		if main_game:
			main_game.inventory.add_item(item_id)
		queue_free()
