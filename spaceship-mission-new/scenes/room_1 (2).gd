
extends Node2D

signal go_left
signal go_right

var is_typing: bool = false
var full_text: String = ""
var current_index: int = 0
var current_messages: Array[String] = []

const TYPE_SPEED: float = 0.03

# --- Сообщения для панели управления (ScreenButton) ---
var messages_no_card: Array[String] = [
	"🔒 Доступ ограничен. Для использования панели управления подтвердите личность — приложите карту доступа.",
]
var messages_with_card: Array[String] = [
	"✅ Карта принята. Личность подтверждена. Панель управления разблокирована.",
]
var messages_already_unlocked: Array[String] = [
	"✅ Панель управления разблокирована.",
]

# --- Сообщения для экрана звёздного неба (Stars) ---
var messages_no_access: Array[String] = [
	"🚫 Нет доступа. Сначала подтвердите личность на панели управления.",
]
var messages_no_starmap: Array[String] = [
	"🌌 Система навигации повреждена. Для корректировки маршрута и прокладки курса через аномальную зону необходима звёздная карта. Найдите её.",
]

var active_dialog: Panel = null
var active_label: RichTextLabel = null
var active_next: TextureButton = null

@onready var screen_button: TextureButton = $ScreenButton
@onready var screen_dialog: Panel = $ScreenDialog
@onready var screen_label: RichTextLabel = $ScreenDialog/DialogLabel
@onready var screen_next: TextureButton = $ScreenDialog/NextButton

@onready var stars_button: TextureButton = $Stars
@onready var stars_dialog: Panel = $StarsDialog
@onready var stars_label: RichTextLabel = $StarsDialog/DialogLabel
@onready var stars_next: TextureButton = $StarsDialog/NextButton

func _ready() -> void:
	$LeftArrow.pressed.connect(_on_left_pressed)
	$RightArrow.pressed.connect(_on_right_pressed)
	screen_button.pressed.connect(_on_screen_pressed)
	screen_next.pressed.connect(func(): _on_next_pressed(screen_dialog))
	screen_dialog.visible = false
	screen_next.visible = true
	stars_button.pressed.connect(_on_stars_pressed)
	stars_next.pressed.connect(func(): _on_next_pressed(stars_dialog))
	stars_dialog.visible = false
	stars_next.visible = true

func _on_left_pressed() -> void:
	emit_signal("go_left")

func _on_right_pressed() -> void:
	emit_signal("go_right")

func _on_screen_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return

	# Уже разблокировано — просто показываем статус
	if main_game.screen_unlocked:
		_open_dialog(screen_dialog, screen_label, screen_next, messages_already_unlocked)
		return

	var inventory = main_game.get_node("UILayer/InventoryRoot")
	if inventory.get_selected_item_id() == "keycard":
		inventory.remove_item("keycard")
		inventory.clear_selection()
		main_game.screen_unlocked = true
		_open_dialog(screen_dialog, screen_label, screen_next, messages_with_card)
	else:
		_open_dialog(screen_dialog, screen_label, screen_next, messages_no_card)

func _on_stars_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return
	var inventory = main_game.get_node("UILayer/InventoryRoot")

	if not main_game.screen_unlocked:
		_open_dialog(stars_dialog, stars_label, stars_next, messages_no_access)
		return

	if inventory.get_selected_item_id() == "starmap":
		inventory.remove_item("starmap")
		inventory.clear_selection()
		# main_game.open_starmap_minigame()
		return

	_open_dialog(stars_dialog, stars_label, stars_next, messages_no_starmap)

func _open_dialog(dialog: Panel, label: RichTextLabel, next_btn: TextureButton, messages: Array[String]) -> void:
	active_dialog = dialog
	active_label = label
	active_next = next_btn
	current_messages = messages
	current_index = 0
	dialog.visible = true
	_show_message(current_index)

func _show_message(index: int) -> void:
	full_text = current_messages[index]
	active_label.text = ""
	active_next.visible = true
	is_typing = true
	_type_next_char(0)

func _type_next_char(char_idx: int) -> void:
	if not is_typing:
		active_label.text = full_text
		active_next.visible = true
		return
	if char_idx > full_text.length():
		is_typing = false
		active_next.visible = true
		return
	active_label.text = full_text.substr(0, char_idx)
	await get_tree().create_timer(TYPE_SPEED).timeout
	_type_next_char(char_idx + 1)

func _on_next_pressed(dialog: Panel) -> void:
	if is_typing:
		is_typing = false
		active_label.text = full_text
		active_next.visible = true
		return
	current_index += 1
	if current_index >= current_messages.size():
		dialog.visible = false
		return
	_show_message(current_index)
