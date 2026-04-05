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

# ── Hardcoded puzzle layout ────────────────────────────────────────────────────
# Format per cell: [pipe_type, correct_rotation, start_rotation]
# Empty cells use [4, 0, 0]. start_rotation must differ from correct_rotation
# for every non-empty tile so the puzzle is not pre-solved.
#
# Pipeline path by (col, row):
#   Entry (0,1) — left border, outward direction = LEFT
#   (0,1)→(0,2)→(1,2)→(1,3)→(2,3)→(3,3)→(3,2)
#   Exit  (3,2) — right border, outward direction = RIGHT
#
# Mask verification (BEND base=3=TOP|RIGHT, rot CW each step):
#   rot0=3  TOP|RIGHT
#   rot1=6  RIGHT|BOTTOM
#   rot2=12 BOTTOM|LEFT
#   rot3=9  TOP|LEFT
#
#   (0,1) BEND rot2=12 BOTTOM|LEFT  → LEFT(border)+DOWN to (0,2)         ✓
#   (0,2) BEND rot0= 3 TOP|RIGHT    → UP to (0,1)+RIGHT to (1,2)         ✓
#   (1,2) BEND rot2=12 BOTTOM|LEFT  → LEFT to (0,2)+DOWN to (1,3)        ✓
#   (1,3) BEND rot0= 3 TOP|RIGHT    → UP to (1,2)+RIGHT to (2,3)         ✓
#   (2,3) STRAIGHT rot0=10 LEFT|RIGHT → LEFT to (1,3)+RIGHT to (3,3)     ✓
#   (3,3) BEND rot3= 9 TOP|LEFT     → LEFT to (2,3)+UP to (3,2)          ✓
#   (3,2) BEND rot1= 6 RIGHT|BOTTOM → RIGHT(border)+DOWN to (3,3)        ✓
#
# All 7 non-empty cells reachable by flood fill from entry, exit reached.  ✓
const PUZZLE_LAYOUT := [
	# row 0: all empty
	[[4, 0, 0], [4, 0, 0], [4, 0, 0], [4, 0, 0]],
	# row 1: entry cell at col 0 (BEND correct=2 start=0), rest empty
	[[1, 2, 0], [4, 0, 0], [4, 0, 0], [4, 0, 0]],
	# row 2: BEND c=0 s=2 | BEND c=2 s=1 | empty | BEND c=1 s=3 (exit)
	[[1, 0, 2], [1, 2, 1], [4, 0, 0], [1, 1, 3]],
	# row 3: empty | BEND c=0 s=3 | STRAIGHT c=0 s=1 | BEND c=3 s=1
	[[4, 0, 0], [1, 0, 3], [0, 0, 1], [1, 3, 1]],
]

# Entry: col=0, row=1 — opens LEFT toward the left border.
# Exit:  col=3, row=2 — opens RIGHT toward the right border.
const ENTRY_POS := Vector2i(0, 1)
const EXIT_POS  := Vector2i(3, 2)

# ── State ──────────────────────────────────────────────────────────────────────
var _won: bool = false

var _grid_types: Array = []
var _grid_rots:  Array = []
var _tex_rects:  Array = []
var _textures:   Dictionary = {}

@onready var _grid_container: GridContainer = $GridContainer
@onready var _win_label:      Label         = $WinLabel
@onready var _exit_button:    TextureButton = $TextureButton
@onready var _check_button:   Button        = $CheckButton

# Created in code so it always has a correct viewport-sized rect and sits on top.
var _red_flash: ColorRect


# ── Life-cycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_exit_button.pressed.connect(_on_exit_pressed)
	_check_button.pressed.connect(_on_check_pressed)
	_style_check_button()
	_load_textures()
	_setup_puzzle()
	_build_grid()
	_create_red_flash()


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


# ── Puzzle setup ───────────────────────────────────────────────────────────────
func _setup_puzzle() -> void:
	var total := GRID_SIZE * GRID_SIZE
	_grid_types.resize(total)
	_grid_rots.resize(total)

	for r in GRID_SIZE:
		for c in GRID_SIZE:
			var idx  := r * GRID_SIZE + c
			var cell: Array = PUZZLE_LAYOUT[r][c]
			_grid_types[idx] = cell[0]  # pipe type
			_grid_rots[idx]  = cell[2]  # start rotation (scrambled)


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


# ── Red flash overlay (created in code, always last child = topmost) ──────────
func _create_red_flash() -> void:
	_red_flash = ColorRect.new()
	_red_flash.color = Color(1, 0, 0, 0.45)
	_red_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_red_flash.visible = false
	add_child(_red_flash)
	# Must be called AFTER add_child so the node has a parent/viewport to anchor to.
	_red_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# ── Check button circular style ────────────────────────────────────────────────
func _style_check_button() -> void:
	var sn := StyleBoxFlat.new()
	sn.bg_color              = Color(0.18, 0.55, 0.20)
	sn.corner_radius_top_left     = 28
	sn.corner_radius_top_right    = 28
	sn.corner_radius_bottom_left  = 28
	sn.corner_radius_bottom_right = 28
	_check_button.add_theme_stylebox_override("normal", sn)

	var sh: StyleBoxFlat = sn.duplicate()
	sh.bg_color = Color(0.25, 0.68, 0.28)
	_check_button.add_theme_stylebox_override("hover", sh)

	var sp: StyleBoxFlat = sn.duplicate()
	sp.bg_color = Color(0.10, 0.40, 0.14)
	_check_button.add_theme_stylebox_override("pressed", sp)

	_check_button.add_theme_color_override("font_color", Color(1, 1, 1))
	_check_button.add_theme_font_size_override("font_size", 28)


# ── Input ──────────────────────────────────────────────────────────────────────
func _on_cell_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		if _grid_types[idx] == EMPTY:
			return  # empty tiles cannot be rotated
		_grid_rots[idx]                  = (_grid_rots[idx] + 1) % 4
		_tex_rects[idx].rotation_degrees = _grid_rots[idx] * 90.0


# ── Check button: manual win trigger ──────────────────────────────────────────
func _on_check_pressed() -> void:
	if _won:
		return
	if _check_win_by_flow():
		_won = true
		_win_label.show()
		await get_tree().create_timer(2.0).timeout
		puzzle_solved.emit()
	else:
		_red_flash.show()
		await get_tree().create_timer(1.0).timeout
		_red_flash.hide()


# ── Win check: flood-fill from the entry cell ─────────────────────────────────
#
# A step from cell A to neighbour B is valid only when BOTH are true:
#   • A's current rotated mask opens in the direction toward B.
#   • B's current rotated mask opens back in the direction toward A.
#
# Two conditions must both pass:
#   1. The flood fill reaches EXIT_POS (the exit border cell).
#   2. visited.size() == total number of non-empty tiles on the grid —
#      guarantees no disconnected pipe segment exists anywhere.
func _check_win_by_flow() -> bool:
	# Count every pipe tile (non-empty) on the grid.
	var pipe_count := 0
	for i in _grid_types.size():
		if _grid_types[i] != EMPTY:
			pipe_count += 1

	# Flood-fill from the entry cell.
	var visited: Dictionary = {}
	visited[ENTRY_POS] = true
	var queue: Array = [ENTRY_POS]

	var steps := [
		[Vector2i(0, -1), TOP,    BOTTOM],
		[Vector2i(1,  0), RIGHT,  LEFT  ],
		[Vector2i(0,  1), BOTTOM, TOP   ],
		[Vector2i(-1, 0), LEFT,   RIGHT ],
	]

	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		var cur_idx  := cur.y * GRID_SIZE + cur.x
		# Always read _grid_rots (current player rotation), never correct rotation.
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

	# Condition 1: the exit border cell must be reachable from the entry.
	if not visited.has(EXIT_POS):
		return false

	# Condition 2: every pipe tile must have been reached — no floating segments.
	if visited.size() != pipe_count:
		return false

	return true
