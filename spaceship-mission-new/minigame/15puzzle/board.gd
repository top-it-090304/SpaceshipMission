extends Control

signal puzzle_solved

signal puzzle_closed

func _on_exit_button_pressed() -> void:
	emit_signal("puzzle_closed")

func _on_puzzle_solved() -> void:
	print("Puzzle solved!")
	emit_signal("puzzle_solved")
	emit_signal("puzzle_closed")

const SIZE := 4                       
const TILE_SIZE := Vector2i(128, 127) 
var board: Array[int] = []             
var empty_index: int = 15              
var tiles_by_number: Dictionary = {}   


func _ready() -> void:
	_init_board()
	_create_tiles()      
	shuffle(200)
	update_tiles_visual()


func _init_board() -> void:
	board.clear()
	for i in range(1, 16):
		board.append(i)
	board.append(0)       
	empty_index = 15


func index_to_rc(index: int) -> Vector2i:
	
	return Vector2i(index / SIZE, index % SIZE)


func rc_to_index(r: int, c: int) -> int:
	
	return r * SIZE + c


func _create_tiles() -> void:
	tiles_by_number.clear()

	var tile_scene := preload("res://minigame/15puzzle/Tile.tscn")

	for index in range(16):
		var number := board[index]
		if number == 0:
			continue   

		var tile = tile_scene.instantiate()
		tile.number = number
		tile.index_in_board = index
		tile.board_path = get_path()

		var rc := index_to_rc(index)
		tile.position = Vector2(
			rc.y * TILE_SIZE.x,
			rc.x * TILE_SIZE.y
		)

		$Tiles.add_child(tile)
		tiles_by_number[number] = tile


func on_tile_pressed(tile: Node) -> void:
	var tile_index: int = tile.index_in_board

	if move_tile(tile_index):
		update_tiles_visual()

		if is_solved():
			_on_puzzle_solved()

	if move_tile(tile_index):
		update_tiles_visual()

		if is_solved():
			_on_puzzle_solved()


func can_move(tile_index: int) -> bool:
	var e: Vector2i = index_to_rc(empty_index)
	var t: Vector2i = index_to_rc(tile_index)

	var dr: int = abs(e.x - t.x)
	var dc: int = abs(e.y - t.y)

	return dr + dc == 1


func move_tile(tile_index: int) -> bool:
	if not can_move(tile_index):
		return false

	var tile_number: int = board[tile_index]


	board[empty_index] = tile_number
	board[tile_index] = 0

	
	empty_index = tile_index


	var tile: Node = tiles_by_number[tile_number]
	tile.index_in_board = empty_index

	return true


func update_tiles_visual() -> void:
	for number in tiles_by_number.keys():
		var tile: Node = tiles_by_number[number]

		var new_index := board.find(number)
		if new_index == -1:
			continue

		tile.index_in_board = new_index
		var rc := index_to_rc(new_index)
		var target_pos := Vector2(
			rc.y * TILE_SIZE.x,
			rc.x * TILE_SIZE.y
		)

	
		var tween := create_tween()
		tween.tween_property(tile, "position", target_pos, 0.15) \
			.set_trans(Tween.TRANS_QUAD) \
			.set_ease(Tween.EASE_OUT)


func shuffle(steps: int = 200) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(steps):
		var e_rc := index_to_rc(empty_index)
		var neighbors: Array[int] = []

		if e_rc.x > 0:
			neighbors.append(rc_to_index(e_rc.x - 1, e_rc.y))
		if e_rc.x < SIZE - 1:
			neighbors.append(rc_to_index(e_rc.x + 1, e_rc.y))
		if e_rc.y > 0:
			neighbors.append(rc_to_index(e_rc.x, e_rc.y - 1))
		if e_rc.y < SIZE - 1:
			neighbors.append(rc_to_index(e_rc.x, e_rc.y + 1))

		var tile_index := neighbors[rng.randi_range(0, neighbors.size() - 1)]
		move_tile(tile_index)


func is_solved() -> bool:
	for i in range(15):
		if board[i] != i + 1:
			return false
	return board[15] == 0



	
func reset_puzzle() -> void:
	_init_board()
	shuffle(200)
	update_tiles_visual()


	
	
	


func _on_exit_pressed() -> void:
	print("EXIT CLICK")
	emit_signal("puzzle_closed")
	


func _on_button_pressed() -> void:
	emit_signal("puzzle_solved")
	emit_signal("puzzle_closed")
