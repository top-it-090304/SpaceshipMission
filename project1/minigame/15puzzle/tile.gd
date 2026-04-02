extends Button


@export var number: int = 1          
@export var board_path: NodePath     

var board: Node                      
var index_in_board: int = 0         

func _ready() -> void:
	board = get_node(board_path)

	var label := $NumberLabel
	label.text = str(number)

	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	board.on_tile_pressed(self)
