extends Panel

const NEXT_ARROW: Texture2D = preload("res://items/right-arrow.png")
const TYPE_SPEED: float = 0.04  # секунд на букву

# Сюда вписывай свои сообщения
var messages: Array[String] = [
	"Сообщение 1...",
	"Сообщение 2...",
	"Сообщение 3...",
]

var current_index: int = 0
var is_typing: bool = false
var full_text: String = ""

@onready var dialog_label: RichTextLabel = $DialogLabel
@onready var next_button: TextureButton = $NextButton

signal dialog_finished

func _ready() -> void:
	next_button.texture_normal = NEXT_ARROW
	next_button.pressed.connect(_on_next_pressed)
	next_button.visible = false
	dialog_label.text = ""
	visible = false

func start() -> void:
	current_index = 0
	visible = true
	_show_message(current_index)

func _show_message(index: int) -> void:
	full_text = messages[index]
	dialog_label.text = ""
	next_button.visible = false
	is_typing = true
	_type_next_char(0)

func _type_next_char(char_idx: int) -> void:
	if char_idx > full_text.length():
		is_typing = false
		next_button.visible = true
		return

	dialog_label.text = full_text.substr(0, char_idx)
	await get_tree().create_timer(TYPE_SPEED).timeout
	_type_next_char(char_idx + 1)

func _on_next_pressed() -> void:
	# Если ещё печатается — показать весь текст сразу
	if is_typing:
		is_typing = false
		dialog_label.text = full_text
		next_button.visible = true
		return

	current_index += 1

	if current_index >= messages.size():
		# Все сообщения показаны — скрываем диалог
		visible = false
		emit_signal("dialog_finished")
		return

	_show_message(current_index)
