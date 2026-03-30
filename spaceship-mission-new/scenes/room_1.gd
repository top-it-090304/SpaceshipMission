extends Node2D

signal go_left
signal go_right

var is_typing: bool = false
var full_text: String = ""
var current_index: int = 0
var current_messages: Array[String] = []

const TYPE_SPEED: float = 0.03

# Сообщение до карты
var messages_no_card: Array[String] = [
	"🔒 Доступ ограничен. Для использования панели управления подтвердите личность — приложите карту доступа.",
]

# Сообщение после карты
var messages_with_card: Array[String] = [
	"✅ Карта принята. Личность подтверждена. Панель управления разблокирована.",
]

@onready var screen_button: TextureButton = $ScreenButton
@onready var screen_dialog: Panel = $ScreenDialog
@onready var dialog_label: RichTextLabel = $ScreenDialog/DialogLabel
@onready var next_button: TextureButton = $ScreenDialog/NextButton

func _ready() -> void:
	$LeftArrow.pressed.connect(_on_left_pressed)
	$RightArrow.pressed.connect(_on_right_pressed)
	screen_button.pressed.connect(_on_screen_pressed)
	next_button.pressed.connect(_on_next_pressed)
	screen_dialog.visible = false
	next_button.visible = true

func _on_left_pressed() -> void:
	emit_signal("go_left")

func _on_right_pressed() -> void:
	emit_signal("go_right")

# --- Клик по экрану ---
func _on_screen_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return

	var inventory = main_game.get_node("UILayer/InventoryRoot")

	# Если выбрана карта — показываем сообщение с картой и убираем её
	if inventory.get_selected_item_id() == "keycard":
		inventory.remove_item("keycard")
		inventory.clear_selection()
		_open_dialog(messages_with_card)
	else:
		_open_dialog(messages_no_card)

# --- Показ диалога ---
func _open_dialog(messages: Array[String]) -> void:
	current_messages = messages
	current_index = 0
	screen_dialog.visible = true
	_show_message(current_index)

func _show_message(index: int) -> void:
	full_text = current_messages[index]
	dialog_label.text = ""
	next_button.visible = true
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
		screen_dialog.visible = false
		return

	_show_message(current_index)
