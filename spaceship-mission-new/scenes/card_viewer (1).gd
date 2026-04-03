extends Control

const CARD_TEXTURE: Texture2D = preload("res://items/paperbig.png")
const CLOSE_ARROW: Texture2D  = preload("res://items/right-arrow.png")

@onready var card_image: TextureRect   = $CardImage
@onready var close_button: TextureButton = $CloseButton

func _ready() -> void:
	card_image.texture   = CARD_TEXTURE
	close_button.texture_normal = CLOSE_ARROW
	close_button.pressed.connect(_on_close_pressed)
	visible = false

func show_card() -> void:
	visible = true

func _on_close_pressed() -> void:
	visible = false
