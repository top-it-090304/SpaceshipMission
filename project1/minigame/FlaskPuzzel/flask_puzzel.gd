extends Control

signal puzzle_solved

const CAPACITY := {
	1: 10,
	2: 6,
	3: 5,
}

var volume := {
	1: 5,
	2: 6,
	3: 0,
}

const TARGET_VOLUME := 8

@onready var masks := {
	1: $Board/Flask1/Mask,
	2: $Board/Flask2/Mask,
	3: $Board/Flask3/Mask,
}

@onready var waters := {
	1: $Board/Flask1/Mask/Water,
	2: $Board/Flask2/Mask/Water,
	3: $Board/Flask3/Mask/Water,
}

@onready var outlines := {
	1: $Board/Flask1/Outline,
	2: $Board/Flask2/Outline,
	3: $Board/Flask3/Outline,
}

@onready var click_areas := {
	1: $Board/Flask1/ClickArea,
	2: $Board/Flask2/ClickArea,
	3: $Board/Flask3/ClickArea,
}

var selected_flask := 0

func _ready() -> void:
	click_areas[1].pressed.connect(func(): _on_flask_clicked(1))
	click_areas[2].pressed.connect(func(): _on_flask_clicked(2))
	click_areas[3].pressed.connect(func(): _on_flask_clicked(3))
	for i in click_areas.keys():
		var btn := click_areas[i] as Button
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_update_all_flasks()

func _on_flask_clicked(index: int) -> void:
	if selected_flask == 0:
		if volume[index] > 0:
			selected_flask = index
			_highlight_flask(index, true)
	else:
		if index == selected_flask:
			_highlight_flask(selected_flask, false)
			selected_flask = 0
			return
		_pour(selected_flask, index)
		_highlight_flask(selected_flask, false)
		selected_flask = 0
		_check_win()

func _pour(from_idx: int, to_idx: int) -> void:
	if from_idx == to_idx:
		return
	var from_vol: int = volume[from_idx]
	var to_vol: int = volume[to_idx]
	var cap_to: int = CAPACITY[to_idx]
	if from_vol == 0:
		return
	if to_vol >= cap_to:
		return
	var space := cap_to - to_vol
	var amount := mini(space, from_vol)
	volume[from_idx] -= amount
	volume[to_idx] += amount
	_update_flask_animated(from_idx)
	_update_flask_animated(to_idx)

func _update_all_flasks() -> void:
	for i in waters.keys():
		_update_flask_instant(i)

func _update_flask_instant(index: int) -> void:
	var water := waters[index] as ColorRect
	var mask := masks[index] as Control
	var mask_h := mask.size.y
	var cap := float(CAPACITY[index])
	var v := float(volume[index])
	var water_h := mask_h * (v / cap)
	water.anchor_left = 0.0
	water.anchor_right = 1.0
	water.anchor_top = 0.0
	water.anchor_bottom = 0.0
	water.offset_left = 0.0
	water.offset_right = 0.0
	water.offset_top = mask_h - water_h
	water.offset_bottom = mask_h

func _update_flask_animated(index: int) -> void:
	var water := waters[index] as ColorRect
	var mask := masks[index] as Control
	var mask_h := mask.size.y
	var cap := float(CAPACITY[index])
	var v := float(volume[index])
	var water_h := mask_h * (v / cap)
	var target_top := mask_h - water_h
	var target_bottom := mask_h
	water.anchor_left = 0.0
	water.anchor_right = 1.0
	water.anchor_top = 0.0
	water.anchor_bottom = 0.0
	water.offset_right = 0.0
	water.offset_left = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(water, "offset_top", target_top, 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(water, "offset_bottom", target_bottom, 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _highlight_flask(index: int, enable: bool) -> void:
	var outline = outlines[index]
	if enable:
		outline.modulate = Color(1.0, 0.9, 0.2)
	else:
		outline.modulate = Color(1, 1, 1)

func _check_win() -> void:
	if volume[1] == TARGET_VOLUME:
		await get_tree().create_timer(0.5).timeout
		puzzle_solved.emit()
		queue_free()

func _on_exit_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game:
		main_game.close_flask()
	else:
		queue_free()


func _on_button_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game:
		main_game.on_flask_solved()
	
