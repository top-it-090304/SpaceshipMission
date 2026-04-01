extends Node2D

# Сообщения когда шар пыльный (brush не выбрана)
var messages_dusty: Array[String] = [
	"Похоже, шар немного пыльный...",
]

var is_typing: bool = false
var full_text: String = ""
var current_index: int = 0
var current_messages: Array[String] = []

const TYPE_SPEED: float = 0.015

@onready var ball_button: TextureButton = $BallButton
@onready var ball_dialog: Panel = $BallDialog
@onready var dialog_label: RichTextLabel = $BallDialog/DialogLabel
@onready var next_button: TextureButton = $BallDialog/NextButton
@onready var dust_layer: TextureRect = $DustLayer
@onready var back_button: TextureButton = $BackButton
@onready var riddle_label: Label = $RiddleLabel

func _ready() -> void:
	ball_button.pressed.connect(_on_ball_pressed)
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)
	ball_dialog.visible = false
	next_button.visible = false
	riddle_label.visible = false

	# Показываем инвентарь
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game:
		var inv = main_game.get_node_or_null("UILayer/InventoryRoot")
		if inv:
			var toggle = inv.get_node_or_null("ToggleButton")
			if toggle:
				toggle.visible = true
			# Если инвентарь ещё не открыт — выдвигаем
			if not inv.is_open:
				inv._on_toggle_button_pressed()

	# Если пыль уже стёрта — сразу показываем загадку
	if GameState.ball_cleaned:
		dust_layer.visible = false
		riddle_label.visible = true

func _on_ball_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")

	if not GameState.ball_cleaned and main_game != null:
		var inventory = main_game.get_node("UILayer/InventoryRoot")
		if inventory.get_selected_item_id() == "brush":
			# Стираем пыль
			GameState.ball_cleaned = true
			inventory.remove_item("brush")
			dust_layer.visible = false
			riddle_label.visible = true
			return

	# Пыль не стёрта и brush не выбрана — показываем «пыльный»
	if not GameState.ball_cleaned:
		_open_dialog(messages_dusty)

func _on_back_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game:
		main_game.close_ball()

# --- Диалог ---
func _open_dialog(messages: Array[String]) -> void:
	current_messages = messages
	current_index = 0
	ball_dialog.visible = true
	_show_message(current_index)

func _show_message(index: int) -> void:
	full_text = current_messages[index]
	dialog_label.text = ""
	next_button.visible = false
	is_typing = true
	_type_next_char(0)

func _type_next_char(char_idx: int) -> void:
	if not is_typing:
		dialog_label.text = full_text
		next_button.visible = true
		return
	if char_idx > full_text.length():
		is_typing = false
		next_button.visible = true
		return
	dialog_label.text = full_text.substr(0, char_idx)
	await get_tree().create_timer(TYPE_SPEED).timeout
	_type_next_char(char_idx + 1)

func _on_next_pressed() -> void:
	if is_typing:
		is_typing = false
		dialog_label.text = full_text
		next_button.visible = true
		return

	current_index += 1

	if current_index >= current_messages.size():
		ball_dialog.visible = false
		return

	_show_message(current_index)
