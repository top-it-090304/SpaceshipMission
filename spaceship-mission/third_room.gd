extends Node2D

@onready var puzzle_board := $PuzzleBoard     
@onready var link_button := $PuzzleBoardLink   
@onready var computer_green := $GreenScreen1  

var puzzle_done: bool = false

func _ready() -> void:
	puzzle_board.hide()
	computer_green.hide()

	link_button.pressed.connect(_on_link_pressed)
	puzzle_board.puzzle_solved.connect(_on_puzzle_solved)  

func _on_link_pressed() -> void:
	if puzzle_done:
		return            
	puzzle_board.reset_puzzle()
	puzzle_board.show()

func _on_puzzle_solved() -> void:
	puzzle_done = true       
	computer_green.show()
