extends Control

@onready var story_label: RichTextLabel = $TextStart

var full_text: String = "Произошла авария! Космический корабль попал в аномальную зону и вышел из строя. Вся твоя команда осталась запертой в блоке, где вот-вот закончится кислород. Тебе необходимо перезапустить ядро, включить питание корабля, разблокировать дверь, тем самым выпустив команду, и вылететь из проблемной зоны. Исследуй 4 комнаты и решай головоломки, каждая из которых будет приближать тебя к выполнению миссии. Действуй быстро — времени мало!"
var char_index: int = 0
var type_speed: float = 0.02

func start_typing() -> void:
	story_label.text = ""
	char_index = 0
	_type_next_char()

func _type_next_char() -> void:
	if char_index > full_text.length():
		return

	story_label.text = full_text.substr(0, char_index)
	char_index += 1

	if char_index <= full_text.length():
		await get_tree().create_timer(type_speed).timeout
		_type_next_char()
