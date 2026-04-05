extends Node2D
 
signal go_left
signal go_right
 
var is_typing: bool = false
var full_text: String = ""
var current_index: int = 0
var current_messages: Array[String] = []
 
const TYPE_SPEED: float = 0.03
 
# --- Текстуры фона ---
const BG_DEFAULT   := preload("res://ImagesBackground/result_Room1.png")
const BG_ALTERNATE := preload("res://ImagesBackground/result_newfirstroomopenwad.png")
 
# --- Текстуры реактора ---
const REACTOR_COLORED := preload("res://ImagesBackground/reacterwithcolor (1).png")
 
var bg_toggled: bool = false
var hidden_item_taken: bool = false
var reactor_colored: bool = false   # инструмент применён
var reactor_picked_up: bool = false # реактор уже забрали в инвентарь
 
# --- Сообщения для ScreenButton ---
var messages_no_card: Array[String] = [
	"🔒 Доступ ограничен. Для использования панели управления подтвердите личность — приложите карту доступа.",
]
var messages_with_card: Array[String] = [
	"✅ Карта принята. Личность подтверждена. Панель управления разблокирована.",
]
var messages_already_unlocked: Array[String] = [
	"✅ Панель управления разблокирована.",
]
 
# --- Сообщения для Stars ---
var messages_no_access: Array[String] = [
	"🚫 Нет доступа. Сначала подтвердите личность на панели управления.",
]
 
# --- Сообщения для реактора ---
var messages_reactor_no_tool: Array[String] = [
	"Реактор повреждён. Нужен подходящий инструмент.",
]
var messages_reactor_done: Array[String] = [
	"✅ Готово! Реактор восстановлен. Можно забрать его.",
]
 
var active_dialog: Panel = null
var active_label: RichTextLabel = null
var active_next: TextureButton = null
 
@onready var room_background: TextureRect    = $RoomBackground
@onready var screen_button: TextureButton    = $ScreenButton
@onready var screen_dialog: Panel            = $ScreenDialog
@onready var screen_label: RichTextLabel     = $ScreenDialog/DialogLabel
@onready var screen_next: TextureButton      = $ScreenDialog/NextButton
@onready var stars_button: TextureButton     = $Stars
@onready var stars_dialog: Panel             = $StarsDialog
@onready var stars_label: RichTextLabel      = $StarsDialog/DialogLabel
@onready var stars_next: TextureButton       = $StarsDialog/NextButton
@onready var bg_toggle_button: TextureButton = $BgToggleButton
@onready var hidden_button: TextureButton    = $HiddenButton
@onready var reactor: Sprite2D               = $Reactor
@onready var reactor_button: TextureButton   = $ReactorButton  # прозрачная кнопка поверх реактора
 
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
 
	bg_toggle_button.pressed.connect(_on_bg_toggle_pressed)
 
	hidden_button.visible = false
	hidden_button.pressed.connect(_on_hidden_button_pressed)
 
	reactor_button.pressed.connect(_on_reactor_pressed)
 
# -------------------------------------------------------
 
func _on_left_pressed() -> void:
	emit_signal("go_left")
 
func _on_right_pressed() -> void:
	emit_signal("go_right")
 
# --- Переключение фона ---
func _on_bg_toggle_pressed() -> void:
	bg_toggled = not bg_toggled
	if bg_toggled:
		room_background.texture = BG_ALTERNATE
		if not hidden_item_taken:
			hidden_button.visible = true
	else:
		room_background.texture = BG_DEFAULT
		hidden_button.visible = false
 
# --- Скрытая кнопка: инвентарь + предмет tool (один раз) ---
func _on_hidden_button_pressed() -> void:
	if hidden_item_taken:
		return
	hidden_item_taken = true
	hidden_button.visible = false
 
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return
	var inventory = main_game.get_node("UILayer/InventoryRoot")
	if not inventory.is_open:
		inventory._on_toggle_button_pressed()
	inventory.add_item("tool")
 
# --- Клик по реактору ---
func _on_reactor_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return
	var inventory = main_game.get_node("UILayer/InventoryRoot")
 
	# Реактор ещё не починен — применяем tool
	if not reactor_colored:
		if inventory.get_selected_item_id() == "tool":
			reactor_colored = true
			reactor.texture = REACTOR_COLORED
			inventory.remove_item("tool")
			inventory.clear_selection()
			_open_screen_dialog(messages_reactor_done)
		else:
			_open_screen_dialog(messages_reactor_no_tool)
		return
 
	# Реактор починен — забираем его в инвентарь
	if not reactor_picked_up:
		reactor_picked_up = true
		reactor.visible = false         # убираем спрайт со сцены
		reactor_button.visible = false  # убираем кнопку
		if not inventory.is_open:
			inventory._on_toggle_button_pressed()
		inventory.add_item("reactor")   # добавляем реактор в инвентарь
 
# --- Вспомогательный диалог ---
func _open_screen_dialog(messages: Array[String]) -> void:
	_open_dialog(screen_dialog, screen_label, screen_next, messages)
 
# -------------------------------------------------------
 
func _on_screen_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return
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
	if main_game.screen_unlocked:
		main_game.open_panel()
	else:
		_open_dialog(stars_dialog, stars_label, stars_next, messages_no_access)
 
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
