extends Button
func shake_button() -> void:
	var start_pos := position
	var tween := create_tween()
	tween.tween_property($Button, "position", start_pos + Vector2(-5, 0), 0.05)
	tween.tween_property($Button, "position", start_pos + Vector2(5, 0), 0.05)
	tween.tween_property($Button, "position", start_pos, 0.05)
	
func _ready() -> void:
	shake_button()
	
