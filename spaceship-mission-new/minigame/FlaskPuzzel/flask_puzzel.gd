extends Control
signal puzzle_solved

# ёмкость колб (в делениях)
const CAPACITY := {
	1: 10,
	2: 6,
	3: 5,
}

# стартовые объёмы (как в Rusty Lake: 0 / 6 / 5)
var volume := {
	1: 0,
	2: 6,
	3: 5,
}

# высота Mask при ПОЛНОЙ колбе.
# Берём из инспектора size.y у Mask, когда вода ровно на верхней красной линии.
const MASK_MAX_HEIGHT := {
	1: 382.0, # Flask1
	2: 301.0, # Flask2
	3: 316.0, # Flask3
}

# ссылки на Mask внутри каждой колбы
@onready var masks := {
	1: $Board/Flask1/Mask,
	2: $Board/Flask2/Mask,
	3: $Board/Flask3/Mask,
}

# ссылки на сами колбы (для подсветки/кликов)
@onready var flask_nodes := {
	1: $Board/Flask1,
	2: $Board/Flask2,
	3: $Board/Flask3,
}

var selected_flask := 0
const TARGET_VOLUME := 8 # победа, когда в большой колбе 8

func _ready() -> void:
	_connect_flasks()
	_update_all_flasks()
	#$ExitButton.pressed.connect(_on_exit_pressed)

# ---------- клики по колбам ----------

func _connect_flasks() -> void:
	for i in flask_nodes.keys():
		var node = flask_nodes[i]
		node.mouse_filter = Control.MOUSE_FILTER_STOP
		node.gui_input.connect(func(event): _on_flask_gui_input(i, event))

func _on_flask_gui_input(index: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_flask_clicked(index)

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

# ---------- переливание ----------

func _pour(from_idx: int, to_idx: int) -> void:
	if from_idx == to_idx:
		return

	var from_vol = volume[from_idx]
	var to_vol = volume[to_idx]
	var cap_to = CAPACITY[to_idx]

	if from_vol == 0:
		return
	if to_vol >= cap_to:
		return

	var space = cap_to - to_vol
	var amount = min(space, from_vol)

	volume[from_idx] -= amount
	volume[to_idx] += amount

	_update_flask(from_idx)
	_update_flask(to_idx)

# ---------- обновление масок (уровень воды) ----------

func _update_all_flasks() -> void:
	for i in masks.keys():
		_update_flask(i)

func _update_flask(index: int) -> void:
	var mask := masks[index] as Control

	var cap := float(CAPACITY[index])
	var v := float(volume[index])
	var max_h = MASK_MAX_HEIGHT[index]

	var height = max_h * (v / cap)

	var parent_h = mask.get_parent().size.y
	mask.size.y = height
	mask.position.y = parent_h - height

func _highlight_flask(index: int, enable: bool) -> void:
	var outline = flask_nodes[index].get_node("Outline")
	if enable:
		outline.modulate = Color(1, 1, 0.7)
	else:
		outline.modulate = Color(1, 1, 1)
# ---------- победа и выход ----------

func _check_win() -> void:
	if volume[1] == TARGET_VOLUME:
		puzzle_solved.emit()
		queue_free()

func _on_exit_pressed() -> void:
	queue_free()
