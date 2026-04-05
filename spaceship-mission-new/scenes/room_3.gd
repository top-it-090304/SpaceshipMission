extends Node2D
 
signal go_left
signal go_right
 
# --- Текстура реактора ---
const REACTOR_TEXTURE := preload("res://ImagesBackground/reacterwithcolor (1).png")
 
# --- Typewriter ---
const TYPE_SPEED: float = 0.03
var is_typing: bool = false
var full_text: String = ""
var current_index: int = 0
var current_messages: Array[String] = []
 
# --- Сообщения ---
var messages_no_reactor: Array[String] = [
	"Здесь нужно установить реактор. Найди его сначала.",
]
var messages_reactor_installed: Array[String] = [
	"✅ Реактор успешно установлен! Ядро запущено" ,
]
 
var reactor_installed: bool = false
 
@onready var reactor_button: TextureButton  = $ReactorButton
@onready var reactor_place: Sprite2D        = $ReactorPlace
 
# Диалоговая панель — добавь в сцену узлы как описано ниже
@onready var dialog_panel: Panel            = $DialogPanel
@onready var dialog_label: RichTextLabel    = $DialogPanel/DialogLabel
@onready var next_button: TextureButton     = $DialogPanel/NextButton
 
func _ready() -> void:
	$LeftArrow.pressed.connect(_on_left_pressed)
	$RightArrow.pressed.connect(_on_right_pressed)
 
	reactor_button.pressed.connect(_on_reactor_button_pressed)
	dialog_panel.visible = false
	next_button.pressed.connect(_on_next_pressed)
 
	# Восстанавливаем состояние реактора из GameState
	if GameState.reactor_installed:
		reactor_installed = true
		reactor_place.texture = REACTOR_TEXTURE
		reactor_place.visible = true
	else:
		reactor_place.visible = false
 
func _on_left_pressed() -> void:
	emit_signal("go_left")
 
func _on_right_pressed() -> void:
	emit_signal("go_right")
 
# --- Нажатие на слот реактора ---
func _on_reactor_button_pressed() -> void:
	if reactor_installed:
		return
 
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return
 
	var inventory = main_game.get_node("UILayer/InventoryRoot")
 
	if inventory.get_selected_item_id() == "reactor":
		reactor_installed = true
		GameState.reactor_installed = true  # сохраняем в глобальный стейт
		reactor_place.texture = REACTOR_TEXTURE
		reactor_place.visible = true
		inventory.remove_item("reactor")
		inventory.clear_selection()
		if inventory.is_open:
			inventory._on_toggle_button_pressed()
		_open_dialog(messages_reactor_installed)
	else:
		_open_dialog(messages_no_reactor)
 
# --- Диалог с typewriter ---
func _open_dialog(messages: Array[String]) -> void:
	current_messages = messages
	current_index = 0
	dialog_panel.visible = true
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
		dialog_panel.visible = false
		return
	_show_message(current_index)
 
# -------------------------------------------------------
 
func _on_puzzle_button_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return
	if main_game.puzzle_solved_15:
		return
	main_game.open_board()
 
func _on_flask_button_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return
	if main_game.flask_solved:
		return
	main_game.open_flask()
 
func _on_platformer_button_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return
	if main_game.platformer_solved:
		return
	main_game.open_platformer()
 
func _on_jumper_button_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return
	if main_game.jumper_solved:
		return
	main_game.open_jumper()
 
func _on_pipe_game_button_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game == null:
		return
	if main_game.pipe_game_solved:
		return
	main_game.open_pipe_game()
