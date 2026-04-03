extends Node2D

signal puzzle_solved

const GRID_SIZE := 4
const TILE_SIZE := 96

# ── Pipe type IDs ──────────────────────────────────────────────────────────────
const STRAIGHT := 0  # pipe_straight.png – horizontal line at rot 0
const BEND     := 1  # pipe_bend.png     – L-corner (BOTTOM+LEFT) at rot 0
const TEE      := 2  # pipe_tee.png      – T-shape (LEFT+RIGHT+BOTTOM) at rot 0
const CROSS    := 3  # pipe_cross.png    – plus (all 4)

const PIPE_FILES := {
	STRAIGHT: "pipe_straight.png",
	BEND:     "pipe_bend.png",
	TEE:      "pipe_tee.png",
	CROSS:    "pipe_cross.png",
}

# ── Bitmask directions: TOP=1, RIGHT=2, BOTTOM=4, LEFT=8 ──────────────────────
const TOP    := 1
const RIGHT  := 2
const BOTTOM := 4
const LEFT   := 8

# Base masks at rotation-step 0.
# Rotating 1 step CW shifts bits left by 1 (with wrap): TOP→RIGHT→BOTTOM→LEFT→TOP
const BASE_MASKS := {
	STRAIGHT: 10,  # RIGHT(2) + LEFT(8)
	BEND:     12,  # BOTTOM(4) + LEFT(8)
	TEE:      14,  # RIGHT(2) + BOTTOM(4) + LEFT(8)
	CROSS:    15,  # all
}

# ── State ──────────────────────────────────────────────────────────────────────
var _grid_types: Array = []   # pipe type per cell
var _grid_rots:  Array = []   # current rotation steps (0-3) per cell
var _tex_rects:  Array = []   # inner TextureRect per cell (the rotating part)
var _textures:   Dictionary = {}

@onready var _grid_container: GridContainer = $GridContainer
@onready var _win_label:      Label         = $WinLabel


# ── Life-cycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_textures()
	_generate_puzzle()
	_build_grid()


# ── Textures ───────────────────────────────────────────────────────────────────
func _load_textures() -> void:
	var base := "res://minigame/PipeGame/"
	for t in [STRAIGHT, BEND, TEE, CROSS]:
		_textures[t] = load(base + PIPE_FILES[t])


# ── Bitmask helpers ────────────────────────────────────────────────────────────

# Rotate mask 90° clockwise once: TOP→RIGHT→BOTTOM→LEFT→TOP
func _rot_cw(mask: int) -> int:
	return ((mask << 1) | (mask >> 3)) & 0xF


# Effective bitmask for pipe_type after `steps` CW rotations.
func _get_mask(pipe_type: int, steps: int) -> int:
	var m: int = BASE_MASKS[pipe_type]
	for _i in steps:
		m = _rot_cw(m)
	return m


# ── Position rules ─────────────────────────────────────────────────────────────
#
#   Corners (both axes on boundary)  → must be BEND
#   Edges   (one axis on boundary)   → must be STRAIGHT
#   Interior (1 ≤ x ≤ 2, 1 ≤ y ≤ 2) → any type
#
# Returns BEND, STRAIGHT, or -1 (interior, no constraint).
func _forced_type_for(cell: Vector2i) -> int:
	var on_col_edge := (cell.x == 0 or cell.x == GRID_SIZE - 1)
	var on_row_edge := (cell.y == 0 or cell.y == GRID_SIZE - 1)
	if on_col_edge and on_row_edge: return BEND      # corner
	if on_col_edge or on_row_edge:  return STRAIGHT  # non-corner edge
	return -1                                         # interior


# Return the first rotation step (0-3) where pipe_type's mask is a
# superset of req_mask (i.e. all required bits are present).
# Returns 0 as fallback — callers guarantee valid inputs.
func _find_rotation_for(pipe_type: int, req_mask: int) -> int:
	for r in 4:
		if (_get_mask(pipe_type, r) & req_mask) == req_mask:
			return r
	return 0


# True if every forced cell on the path can satisfy its required connections.
# A forced cell is valid when at least one rotation of its forced type
# produces a mask that is a superset of the bits required by its path neighbours.
func _path_valid_for_constraints(path: Array) -> bool:
	for i in path.size():
		var cell: Vector2i = path[i]
		var ftype := _forced_type_for(cell)
		if ftype == -1:
			continue  # interior cells are unconstrained

		var req := 0
		if i > 0:
			req |= _dir_bit(cell, path[i - 1])
		if i < path.size() - 1:
			req |= _dir_bit(cell, path[i + 1])

		var ok := false
		for r in 4:
			if (_get_mask(ftype, r) & req) == req:
				ok = true
				break
		if not ok:
			return false
	return true


# ── Puzzle generation ──────────────────────────────────────────────────────────
func _generate_puzzle() -> void:
	var total := GRID_SIZE * GRID_SIZE
	_grid_types.resize(total)
	_grid_rots.resize(total)

	# ── Step 1: find a path that respects type constraints ─────────────────────
	# The DFS is randomised; most edge-hugging paths are valid. Re-roll up to
	# 100 times. If none passes validation, use a guaranteed fallback L-path.
	var path: Array = []
	for _try in 100:
		var candidate: Array = []
		var visited: Dictionary = {}
		_dfs(Vector2i(0, 0), Vector2i(GRID_SIZE - 1, GRID_SIZE - 1), visited, candidate)
		if _path_valid_for_constraints(candidate):
			path = candidate
			break

	if path.is_empty():
		# Guaranteed-valid fallbacks: two L-shapes around the grid border.
		# Both respect the edge/corner rules (straight edges, bent corners).
		if randi() % 2 == 0:
			# right along top edge, then down the right edge
			path = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0),
					Vector2i(3,1), Vector2i(3,2), Vector2i(3,3)]
		else:
			# down the left edge, then right along the bottom edge
			path = [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3),
					Vector2i(1,3), Vector2i(2,3), Vector2i(3,3)]

	# ── Step 2: stamp correct types + solution rotations on path cells ─────────
	var path_set: Dictionary = {}
	for i in path.size():
		var cell: Vector2i = path[i]
		path_set[cell] = true

		# Build required connection bitmask from path neighbours.
		var req := 0
		if i > 0:
			req |= _dir_bit(cell, path[i - 1])
		if i < path.size() - 1:
			req |= _dir_bit(cell, path[i + 1])

		# Override type based on position, then find the rotation that satisfies req.
		var ftype := _forced_type_for(cell)
		var pipe_type: int = ftype if ftype != -1 else (randi() % 4)
		var correct_rot := _find_rotation_for(pipe_type, req)

		var idx := cell.y * GRID_SIZE + cell.x
		_grid_types[idx] = pipe_type
		_grid_rots[idx]  = correct_rot  # store SOLUTION rotation; scrambled below

	# ── Step 3: fill every non-path cell ──────────────────────────────────────
	# Corners and edges are still forced to their required type; interiors are random.
	for ry in GRID_SIZE:
		for cx in GRID_SIZE:
			var cell := Vector2i(cx, ry)
			if path_set.has(cell):
				continue
			var idx := ry * GRID_SIZE + cx
			var ftype := _forced_type_for(cell)
			_grid_types[idx] = ftype if ftype != -1 else (randi() % 4)
			_grid_rots[idx]  = randi() % 4

	# ── Step 4: scramble every cell by a non-zero offset ──────────────────────
	# Adding 1-3 guarantees no cell starts at its solution orientation.
	for i in total:
		_grid_rots[i] = (_grid_rots[i] + 1 + randi() % 3) % 4


# ── DFS path-finder with backtracking (unchanged) ─────────────────────────────
func _dfs(cur: Vector2i, goal: Vector2i, visited: Dictionary, path: Array) -> bool:
	visited[cur] = true
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
		if _dfs(nxt, goal, visited, path):
			return true

	visited.erase(cur)
	path.pop_back()
	return false


# Bitmask bit for the direction from `from` toward `to`.
func _dir_bit(from: Vector2i, to: Vector2i) -> int:
	var d: Vector2i = to - from
	if d == Vector2i(0, -1): return TOP
	if d == Vector2i(1,  0): return RIGHT
	if d == Vector2i(0,  1): return BOTTOM
	return LEFT


# ── Grid construction (Control cell + inner TextureRect) ───────────────────────
func _build_grid() -> void:
	_grid_container.columns = GRID_SIZE

	for r in GRID_SIZE:
		for c in GRID_SIZE:
			var idx := r * GRID_SIZE + c

			# Outer cell: fixed 96×96 Control, never rotates, catches clicks.
			var cell := Control.new()
			cell.custom_minimum_size   = Vector2(TILE_SIZE, TILE_SIZE)
			cell.size                  = Vector2(TILE_SIZE, TILE_SIZE)
			cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			cell.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
			cell.clip_contents         = true

			# Inner TextureRect: the ONLY node that rotates.
			# Pivot at its own centre → image stays inside the cell at any angle.
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
		_grid_rots[idx]               = (_grid_rots[idx] + 1) % 4
		_tex_rects[idx].rotation_degrees = _grid_rots[idx] * 90.0
		if _check_win_by_flow():
			_win_label.show()
			puzzle_solved.emit()


# ── Win check: flood-fill via bitmask ─────────────────────────────────────────
# Enters a neighbour only when current mask opens toward it AND neighbour opens back.
func _check_win_by_flow() -> bool:
	var goal  := Vector2i(GRID_SIZE - 1, GRID_SIZE - 1)
	var start := Vector2i(0, 0)
	var visited: Dictionary = {start: true}
	var queue: Array        = [start]

	# [grid offset, bit I must open, bit neighbour must open back]
	var conns := [
		[Vector2i(0, -1), TOP,    BOTTOM],
		[Vector2i(1,  0), RIGHT,  LEFT  ],
		[Vector2i(0,  1), BOTTOM, TOP   ],
		[Vector2i(-1, 0), LEFT,   RIGHT ],
	]

	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == goal:
			return true

		var idx     := cur.y * GRID_SIZE + cur.x
		var my_mask := _get_mask(_grid_types[idx], _grid_rots[idx])

		for conn in conns:
			if not (my_mask & conn[1]):
				continue
			var nxt: Vector2i = cur + conn[0]
			if nxt.x < 0 or nxt.x >= GRID_SIZE or nxt.y < 0 or nxt.y >= GRID_SIZE:
				continue
			if visited.has(nxt):
				continue
			var nidx   := nxt.y * GRID_SIZE + nxt.x
			var n_mask := _get_mask(_grid_types[nidx], _grid_rots[nidx])
			if n_mask & conn[2]:
				visited[nxt] = true
				queue.append(nxt)

	return false
