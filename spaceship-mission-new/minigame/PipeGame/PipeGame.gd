extends Node2D

signal puzzle_solved
signal puzzle_exit

const GRID_SIZE := 4
const TILE_SIZE := 130

# ── Pipe type IDs ──────────────────────────────────────────────────────────────
const STRAIGHT := 0  # pipe_straight.png — LEFT | RIGHT          at rot 0
const BEND     := 1  # pipe_bend.png     — TOP  | RIGHT          at rot 0
const TEE      := 2  # pipe_tee.png      — RIGHT | BOTTOM | LEFT at rot 0
const CROSS    := 3  # pipe_cross.png    — all four directions
const EMPTY    := 4  # empty.png         — no connections, never rotates

const PIPE_FILES := {
	STRAIGHT: "res://minigame/PipeGame/images/pipe_straight.png",
	BEND:     "res://minigame/PipeGame/images/pipe_bend.png",
	TEE:      "res://minigame/PipeGame/images/pipe_tee.png",
	CROSS:    "res://minigame/PipeGame/images/pipe_cross.png",
	EMPTY:    "res://minigame/PipeGame/images/empty.png",
}

# ── Direction bitmasks ─────────────────────────────────────────────────────────
const TOP    := 1
const RIGHT  := 2
const BOTTOM := 4
const LEFT   := 8

# ── Base connection masks at rotation step 0 ──────────────────────────────────
const BASE_MASKS := {
	STRAIGHT: 10,  # RIGHT(2) + LEFT(8)
	BEND:      3,  # TOP(1)   + RIGHT(2)
	TEE:      14,  # RIGHT(2) + BOTTOM(4) + LEFT(8)
	CROSS:    15,  # all four
	EMPTY:     0,
}

# ── State ──────────────────────────────────────────────────────────────────────
var _won: bool = false

var _grid_types:    Array = []   # STRAIGHT / BEND / TEE / CROSS / EMPTY per cell
var _grid_rots:     Array = []   # current player rotation steps (0–3)
var _solution_rots: Array = []   # correct rotation steps for each pipe tile
var _tex_rects:     Array = []   # TextureRect nodes (the rotating parts)
var _textures:      Dictionary = {}

# Entry and exit: border cells where the pipeline begins and ends.
# Each has a pos (Vector2i) and an outward direction bit (toward the grid edge).
var _entry_pos: Vector2i
var _entry_dir: int
var _exit_pos:  Vector2i
var _exit_dir:  int

@onready var _grid_container: GridContainer = $GridContainer
@onready var _win_label:      Label         = $WinLabel
@onready var _exit_button:    TextureButton = $TextureButton


# ── Life-cycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_exit_button.pressed.connect(_on_exit_pressed)
	_load_textures()
	_generate_puzzle()
	_build_grid()


func _on_exit_pressed() -> void:
	if _won:
		return
	puzzle_exit.emit()


# ── Textures ───────────────────────────────────────────────────────────────────
func _load_textures() -> void:
	for t in [STRAIGHT, BEND, TEE, CROSS, EMPTY]:
		_textures[t] = load(PIPE_FILES[t])


# ── Bitmask helpers ────────────────────────────────────────────────────────────
# Rotate mask 90° clockwise: TOP→RIGHT→BOTTOM→LEFT→TOP
func _rot_cw(mask: int) -> int:
	return ((mask << 1) | (mask >> 3)) & 0xF


# Effective bitmask for pipe_type after `steps` CW rotations.
func _get_mask(pipe_type: int, steps: int) -> int:
	var m: int = BASE_MASKS[pipe_type]
	for _i in steps:
		m = _rot_cw(m)
	return m


# Direction bit from `from` toward the adjacent cell `to`.
func _dir_toward(from: Vector2i, to: Vector2i) -> int:
	var d := to - from
	if d == Vector2i(0, -1): return TOP
	if d == Vector2i(1,  0): return RIGHT
	if d == Vector2i(0,  1): return BOTTOM
	return LEFT  # d == Vector2i(-1, 0)


# Outward border direction for a border cell (points away from the grid).
func _border_dir(pos: Vector2i) -> int:
	if pos.x == 0:             return LEFT
	if pos.x == GRID_SIZE - 1: return RIGHT
	if pos.y == 0:             return TOP
	return BOTTOM


# Convert a connection bitmask to [pipe_type, rotation] by trying every
# combination until the rotated base mask matches exactly.
func _mask_to_pipe(mask: int) -> Array:
	for ptype in [STRAIGHT, BEND, TEE, CROSS]:
		for rot in 4:
			if _get_mask(ptype, rot) == mask:
				return [ptype, rot]
	return [STRAIGHT, 0]  # should never be reached for valid 2-bit masks


# ── Puzzle generation ──────────────────────────────────────────────────────────
#
# Algorithm:
#  1. Fill the entire grid with EMPTY.
#  2. Pick a random border cell as entry and another as exit.
#  3. Find a random non-self-crossing path between them via randomised DFS.
#  4. For each path cell, build the connection bitmask from its path neighbours
#     (plus the outward border direction at the two endpoints).
#  5. Convert each bitmask to the correct pipe type and rotation.
#  6. Scramble every pipe tile (non-empty) by adding 1–3 rotation steps so that
#     no tile starts in the solved position.
func _generate_puzzle() -> void:
	var total := GRID_SIZE * GRID_SIZE
	_grid_types.resize(total)
	_solution_rots.resize(total)
	_grid_rots.resize(total)

	# ── 1. Start with a fully empty grid ──────────────────────────────────────
	for i in total:
		_grid_types[i]    = EMPTY
		_solution_rots[i] = 0
		_grid_rots[i]     = 0

	# ── 2. Pick entry and exit on the border ──────────────────────────────────
	var border_cells: Array = []
	for ry in GRID_SIZE:
		for cx in GRID_SIZE:
			if cx == 0 or cx == GRID_SIZE - 1 or ry == 0 or ry == GRID_SIZE - 1:
				border_cells.append(Vector2i(cx, ry))
	border_cells.shuffle()

	_entry_pos = border_cells[0]
	_entry_dir = _border_dir(_entry_pos)

	# Exit: any other border cell (prefer opposite side for a longer path)
	_exit_pos = border_cells[border_cells.size() - 1]
	if _exit_pos == _entry_pos:
		_exit_pos = border_cells[1]
	_exit_dir = _border_dir(_exit_pos)

	# ── 3. Random walk from entry to exit ─────────────────────────────────────
	var path:    Array      = []
	var visited: Dictionary = {_entry_pos: true}
	_dfs_path(_entry_pos, _exit_pos, visited, path)

	# ── 4 & 5. Assign pipe types and solution rotations along the path ────────
	for i in path.size():
		var cell: Vector2i = path[i]
		var mask := 0

		if i == 0:
			# Entry cell: outward opening toward grid edge + opening to next cell.
			mask |= _entry_dir
			mask |= _dir_toward(cell, path[i + 1])
		elif i == path.size() - 1:
			# Exit cell: outward opening toward grid edge + opening to prev cell.
			mask |= _exit_dir
			mask |= _dir_toward(cell, path[i - 1])
		else:
			# Middle cell: connects previous and next path cells.
			mask |= _dir_toward(cell, path[i - 1])
			mask |= _dir_toward(cell, path[i + 1])

		var result := _mask_to_pipe(mask)
		var idx    := cell.y * GRID_SIZE + cell.x
		_grid_types[idx]    = result[0]
		_solution_rots[idx] = result[1]

	# ── 6. Scramble: non-empty cells get a random non-zero rotation offset ────
	for i in total:
		if _grid_types[i] == EMPTY:
			_grid_rots[i] = 0
		else:
			_grid_rots[i] = (_solution_rots[i] + 1 + randi() % 3) % 4


# ── Randomised DFS path-finder with backtracking ──────────────────────────────
func _dfs_path(cur: Vector2i, goal: Vector2i,
			   visited: Dictionary, path: Array) -> bool:
	path.append(cur)
	if cur == goal:
		return true

	var dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	dirs.shuffle()

	for d in dirs:
		var nxt: Vector2i = cur + d
		if nxt.x < 0 or nxt.x >= GRID_SIZE or nxt.y < 0 or nxt.y >= GRID_SIZE:
			continue
		if visited.has(nxt):
			continue
		visited[nxt] = true
		if _dfs_path(nxt, goal, visited, path):
			return true
		visited.erase(nxt)

	path.pop_back()
	return false


# ── Grid construction ──────────────────────────────────────────────────────────
func _build_grid() -> void:
	_grid_container.columns = GRID_SIZE

	for r in GRID_SIZE:
		for c in GRID_SIZE:
			var idx := r * GRID_SIZE + c

			var cell := Control.new()
			cell.custom_minimum_size   = Vector2(TILE_SIZE, TILE_SIZE)
			cell.size                  = Vector2(TILE_SIZE, TILE_SIZE)
			cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			cell.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
			cell.clip_contents         = true

			var tex := TextureRect.new()
			tex.texture          = _textures[_grid_types[idx]]
			tex.expand_mode      = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tex.stretch_mode     = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.position         = Vector2.ZERO
			tex.size             = Vector2(TILE_SIZE, TILE_SIZE)
			tex.pivot_offset     = Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
			tex.rotation_degrees = _grid_rots[idx] * 90.0
			tex.mouse_filter     = Control.MOUSE_FILTER_IGNORE

			cell.add_child(tex)
			_grid_container.add_child(cell)
			_tex_rects.append(tex)

			cell.gui_input.connect(_on_cell_input.bind(idx))


# ── Input ──────────────────────────────────────────────────────────────────────
func _on_cell_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		if _grid_types[idx] == EMPTY:
			return  # empty tiles cannot be rotated
		_grid_rots[idx]                  = (_grid_rots[idx] + 1) % 4
		_tex_rects[idx].rotation_degrees = _grid_rots[idx] * 90.0
		if _check_win_by_flow():
			if _won:
				return
			_won = true
			_win_label.show()
			await get_tree().create_timer(2.0).timeout
			puzzle_solved.emit()


# ── Win check: flood-fill from the entry cell ─────────────────────────────────
#
# A step from cell A to neighbour B is valid only when BOTH are true:
#   • A's current rotated mask opens in the direction toward B.
#   • B's current rotated mask opens back in the direction toward A.
#
# Two conditions must both pass:
#   1. The flood fill reaches _exit_pos (the exit border cell).
#   2. visited.size() == total number of non-empty tiles on the grid —
#      guarantees no disconnected pipe segment exists anywhere.
func _check_win_by_flow() -> bool:
	# Count every pipe tile (non-empty) on the actual generated grid.
	var pipe_count := 0
	for i in _grid_types.size():
		if _grid_types[i] != EMPTY:
			pipe_count += 1

	# Flood-fill from the exact entry cell set during puzzle generation.
	var visited: Dictionary = {}
	visited[_entry_pos] = true
	var queue: Array = [_entry_pos]

	var steps := [
		[Vector2i(0, -1), TOP,    BOTTOM],
		[Vector2i(1,  0), RIGHT,  LEFT  ],
		[Vector2i(0,  1), BOTTOM, TOP   ],
		[Vector2i(-1, 0), LEFT,   RIGHT ],
	]

	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		var cur_idx  := cur.y * GRID_SIZE + cur.x
		# Always read _grid_rots (current player rotation), never _solution_rots.
		var cur_mask := _get_mask(_grid_types[cur_idx], _grid_rots[cur_idx])

		for step in steps:
			# A must open toward B.
			if not (cur_mask & step[1]):
				continue
			var nxt: Vector2i = cur + step[0]
			# Stay inside the grid.
			if nxt.x < 0 or nxt.x >= GRID_SIZE or nxt.y < 0 or nxt.y >= GRID_SIZE:
				continue
			if visited.has(nxt):
				continue
			var nxt_idx := nxt.y * GRID_SIZE + nxt.x
			# Empty tiles are never part of the pipeline.
			if _grid_types[nxt_idx] == EMPTY:
				continue
			# B must open back toward A.
			var nxt_mask := _get_mask(_grid_types[nxt_idx], _grid_rots[nxt_idx])
			if not (nxt_mask & step[2]):
				continue
			visited[nxt] = true
			queue.append(nxt)

	# ── DEBUG ─────────────────────────────────────────────────────────────────
	print("=== WIN CHECK ===")
	print("Entry: ", _entry_pos, " dir: ", _entry_dir,
		  "  Exit: ", _exit_pos,  " dir: ", _exit_dir)
	print("Total non-empty cells: ", pipe_count)
	print("Visited cells count:   ", visited.size())
	print("Exit reached:          ", visited.has(_exit_pos))
	for ry in GRID_SIZE:
		for cx in GRID_SIZE:
			var dbg_idx  := ry * GRID_SIZE + cx
			var dbg_mask := _get_mask(_grid_types[dbg_idx], _grid_rots[dbg_idx])
			print("Cell [", ry, ",", cx, "]",
				  "  type=",    _grid_types[dbg_idx],
				  "  cur_rot=", _grid_rots[dbg_idx],
				  "  sol_rot=", _solution_rots[dbg_idx],
				  "  mask=",    dbg_mask)
	# ── END DEBUG ──────────────────────────────────────────────────────────────

	# Condition 1: the exit border cell must be reachable from the entry.
	if not visited.has(_exit_pos):
		return false

	# Condition 2: every pipe tile must have been reached — no floating segments.
	if visited.size() != pipe_count:
		return false

	return true
