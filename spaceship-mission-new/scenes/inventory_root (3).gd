extends Control

const MAX_SLOTS := 7

# --- Анимация инвентаря ---
const INVENTORY_HEIGHT: float = 130.0
const TWEEN_DURATION: float = 0.35

const ARROW_DOWN: Texture2D = preload("res://items/down-arrow .png")
const ARROW_UP: Texture2D   = preload("res://items/up - arrow.png")

var is_open: bool = false
var tween: Tween

@onready var toggle_button: TextureButton = $ToggleButton

# --- Предметы ---
var items: Array[String] = []
var item_textures := {
	"battery": preload("res://items/battery.png"),
	"screwdriver": preload("res://items/screwdriver.png"),
	"brush": preload("res://items/paint-brush.png"),
	"key": preload("res://items/key_1.png"),
	"card": preload("res://items/result_card1box.png"),
}

@onready var slots := [
	$Slots/Slot1,
	$Slots/Slot2,
	$Slots/Slot3,
	$Slots/Slot4,
	$Slots/Slot5,
	$Slots/Slot6,
	$Slots/Slot7,
]

var selected_index: int = -1

func _ready() -> void:
	# Прячем инвентарь за верхний край при старте
	position.y = -INVENTORY_HEIGHT
	toggle_button.texture_normal = ARROW_DOWN
	toggle_button.pressed.connect(_on_toggle_button_pressed)

	# Слоты
	for i in range(slots.size()):
		var idx := i
		var slot := slots[i] as TextureRect
		slot.gui_input.connect(func(event):
			_on_slot_gui_input(idx, event)
		)
	_update_slots()


# --- Логика кнопки-стрелочки ---
func _on_toggle_button_pressed() -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	if is_open:
		tween.tween_property(self, "position:y", -INVENTORY_HEIGHT, TWEEN_DURATION)
		toggle_button.texture_normal = ARROW_DOWN
		is_open = false
	else:
		tween.tween_property(self, "position:y", 0.0, TWEEN_DURATION)
		toggle_button.texture_normal = ARROW_UP
		is_open = true


# --- Логика инвентаря (без изменений) ---
func add_item(id: String) -> void:
	print("Inventory.add_item:", id)
	if items.size() >= MAX_SLOTS or id in items:
		print("Cannot add, items =", items)
		return
	items.append(id)
	print("Items now:", items)
	if selected_index == -1:
		selected_index = items.size() - 1
	_update_slots()

func remove_item(id: String) -> void:
	if id in items:
		var idx := items.find(id)
		items.erase(id)
		if selected_index == idx:
			selected_index = -1
		elif selected_index > idx:
			selected_index -= 1
		_update_slots()

func has_item(id: String) -> bool:
	return id in items

func get_selected_item_id() -> String:
	if selected_index < 0 or selected_index >= items.size():
		return ""
	return items[selected_index]

func clear_selection() -> void:
	selected_index = -1
	_update_slots()

func _on_slot_gui_input(idx: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if idx >= items.size():
			return
		if selected_index == idx:
			selected_index = -1
		else:
			selected_index = idx
		_update_slots()
		# Если выбрана карточка — показываем крупный вид
		if selected_index >= 0 and items[selected_index] == "card":
			var main_game := get_tree().get_first_node_in_group("MainGame")
			if main_game:
				var card_viewer = main_game.get_node_or_null("UILayer/CardViewer")
				if card_viewer:
					card_viewer.show_card()

func _update_slots() -> void:
	for i in range(slots.size()):
		var slot := slots[i] as TextureRect
		if i < items.size():
			var id := items[i]
			slot.texture = item_textures.get(id, null)
			slot.visible = true
			if i == selected_index:
				slot.modulate = Color(0.5, 1.0, 0.5)
			else:
				slot.modulate = Color(1, 1, 1)
		else:
			slot.texture = null
			slot.visible = false
			slot.modulate = Color(1, 1, 1)
