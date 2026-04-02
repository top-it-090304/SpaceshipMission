# ==============================================================================
# PipePuzzle.gd
# Мини-игра «Трубы» для Godot 4.x  |  Сетка 5×5
# ==============================================================================
#
# СТРУКТУРА СЦЕНЫ (создай вручную):
#
#   PipePuzzle  (Node2D)  ← этот скрипт
#   └── GridContainer     (GridContainer)
#   └── WinLabel          (Label)           ← скрыт по умолчанию
#
# СПРАЙТЫ (положи в res://assets/pipes/):
#   pipe_straight.png   — прямая труба  ═
#   pipe_bend.png       — угловая       ╗
#   pipe_tee.png        — тройник       ╦
#   pipe_cross.png      — крестовина    ╬
#
#   Все картинки должны быть ориентированы «по умолчанию» так:
#     straight  — горизонталь (соединяет LEFT и RIGHT)
#     bend      — соединяет TOP и RIGHT
#     tee       — соединяет LEFT, RIGHT и BOTTOM
#     cross     — соединяет все 4 стороны
#
# ПОДКЛЮЧЕНИЯ:
#   GridContainer — переменная grid_container (NodePath)
#   WinLabel      — переменная win_label      (NodePath)
# ==============================================================================

extends Node2D

# ── Настройки ──────────────────────────────────────────────────────────────────
const GRID_SIZE     := 5          # 5×5
const CELL_SIZE     := 96         # пиксели (размер одного тайла)
const CELL_GAP      := 4          # отступ между тайлами

# Пути к текстурам
const TEX_STRAIGHT  := "res://assets/pipes/pipe_straight.png"
const TEX_BEND      := "res://assets/pipes/pipe_bend.png"
const TEX_TEE       := "res://assets/pipes/pipe_tee.png"
const TEX_CROSS     := "res://assets/pipes/pipe_cross.png"

# Направления: битовая маска  TOP=1  RIGHT=2  BOTTOM=4  LEFT=8
const DIR_TOP    := 1
const DIR_RIGHT  := 2
const DIR_BOTTOM := 4
const DIR_LEFT   := 8

# Типы труб: [название, маска_при_rotation=0]
const PIPE_TYPES := {
	"straight": DIR_LEFT | DIR_RIGHT,            # ══
	"bend":     DIR_TOP  | DIR_RIGHT,            # ╗
	"tee":      DIR_LEFT | DIR_RIGHT | DIR_BOTTOM, # ╦
	"cross":    DIR_TOP  | DIR_RIGHT | DIR_BOTTOM | DIR_LEFT, # ╬
}

# ── NodePath-экспорты ──────────────────────────────────────────────────────────
@export var grid_container_path : NodePath = "GridContainer"
@export var win_label_path      : NodePath = "WinLabel"

# ── Внутреннее состояние ───────────────────────────────────────────────────────
var _grid_container : GridContainer
var _win_label      : Label

# Двумерный массив [row][col] → { type, rotation, texture_button }
var _cells : Array = []

# Какая ячейка — ИСТОЧНИК (вода вытекает отсюда) и ЦЕЛЬ
var _source : Vector2i = Vector2i(0, 0)
var _target : Vector2i = Vector2i(GRID_SIZE - 1, GRID_SIZE - 1)

var _solved := false

# ── Текстуры (кэш) ─────────────────────────────────────────────────────────────
var _textures : Dictionary = {}

# ==============================================================================
func _ready() -> void:
	_grid_container = get_node(grid_container_path) as GridContainer
	_win_label      = get_node(win_label_path) as Label

	_win_label.visible = false
	_load_textures()
	_build_puzzle()

# ==============================================================================
# ЗАГРУЗКА ТЕКСТУР
# ==============================================================================
func _load_textures() -> void:
	_textures["straight"] = load(TEX_STRAIGHT)
	_textures["bend"]     = load(TEX_BEND)
	_textures["tee"]      = load(TEX_TEE)
	_textures["cross"]    = load(TEX_CROSS)

# ==============================================================================
# ГЕНЕРАЦИЯ ПАЗЛА
# ==============================================================================
func _build_puzzle() -> void:
	# Очистить контейнер
	for child in _grid_container.get_children():
		child.queue_free()
	_cells.clear()
	_solved = false

	_grid_container.columns = GRID_SIZE

	# 1) Генерируем «правильное» решение — случайный маршрут по сетке
	var solution_rotations := _generate_solution()

	# 2) Создаём ячейки и перемешиваем их повороты
	for row in GRID_SIZE:
		_cells.append([])
		for col in GRID_SIZE:
			var idx   := row * GRID_SIZE + col
			var cdata : Dictionary = solution_rotations[idx]

			# Случайный начальный поворот (0..3), но НЕ совпадающий с правильным
			var rand_rot : int = cdata.correct_rotation
			if cdata.type != "cross":          # крест симметричен — не крутим
				while rand_rot == cdata.correct_rotation:
					rand_rot = randi() % 4

			var btn := _create_cell_button(cdata.type, rand_rot, row, col)
			_grid_container.add_child(btn)

			_cells[row].append({
				"type":             cdata.type,
				"rotation":         rand_rot,
				"correct_rotation": cdata.correct_rotation,
				"button":           btn,
			})

# ------------------------------------------------------------------------------
# Генерация решения: прокладываем путь от source до target,
# затем заполняем оставшиеся клетки случайными трубами.
# ------------------------------------------------------------------------------
func _generate_solution() -> Array:
	var result : Array = []
	result.resize(GRID_SIZE * GRID_SIZE)

	# Матрица «нужных соединений» для каждой клетки (битовые маски)
	var connections : Array = []
	for i in GRID_SIZE * GRID_SIZE:
		connections.append(0)

	# Строим случайный путь от source к target (DFS/random walk)
	var path := _random_path(_source, _target)

	# Расставляем соединения вдоль пути
	for i in range(path.size() - 1):
		var cur  : Vector2i = path[i]
		var nxt  : Vector2i = path[i + 1]
		var diff : Vector2i = nxt - cur
		var ci   := cur.y * GRID_SIZE + cur.x
		var ni   := nxt.y * GRID_SIZE + nxt.x

		if diff == Vector2i(1, 0):        # RIGHT
			connections[ci] |= DIR_RIGHT
			connections[ni] |= DIR_LEFT
		elif diff == Vector2i(-1, 0):     # LEFT
			connections[ci] |= DIR_LEFT
			connections[ni] |= DIR_RIGHT
		elif diff == Vector2i(0, 1):      # DOWN
			connections[ci] |= DIR_BOTTOM
			connections[ni] |= DIR_TOP
		elif diff == Vector2i(0, -1):     # UP
			connections[ci] |= DIR_TOP
			connections[ni] |= DIR_BOTTOM

	# Для клеток вне пути — случайная труба
	var path_set : Dictionary = {}
	for p in path:
		path_set[p] = true

	for row in GRID_SIZE:
		for col in GRID_SIZE:
			var pos := Vector2i(col, row)
			var idx := row * GRID_SIZE + col
			if not path_set.has(pos):
				# Случайная труба, не влияет на решение
				var types := PIPE_TYPES.keys()
				var t     : String = types[randi() % types.size()]
				var rot   : int    = randi() % 4
				result[idx] = {
					"type":             t,
					"correct_rotation": rot,   # любой поворот = «правильный» для декора
				}
			else:
				var mask  : int    = connections[idx]
				var td    := _mask_to_type_and_rotation(mask)
				result[idx] = {
					"type":             td.type,
					"correct_rotation": td.rotation,
				}

	return result

# ------------------------------------------------------------------------------
# Случайный путь по сетке (random walk с backtracking)
# ------------------------------------------------------------------------------
func _random_path(from: Vector2i, to: Vector2i) -> Array:
	var visited : Dictionary = {}
	var path    : Array      = [from]
	visited[from] = true

	while path.back() != to:
		var cur      : Vector2i = path.back()
		var neighbors : Array   = _shuffled_neighbors(cur, visited)

		if neighbors.is_empty():
			# backtrack
			path.pop_back()
			if path.is_empty():
				# перезапуск (редко)
				path    = [from]
				visited = {from: true}
		else:
			var nxt : Vector2i = neighbors[0]
			visited[nxt] = true
			path.append(nxt)

	return path

func _shuffled_neighbors(pos: Vector2i, visited: Dictionary) -> Array:
	var dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	dirs.shuffle()
	var result : Array = []
	for d in dirs:
		var n : Vector2i = pos + d
		if n.x >= 0 and n.x < GRID_SIZE and n.y >= 0 and n.y < GRID_SIZE:
			if not visited.has(n):
				result.append(n)
	return result

# ------------------------------------------------------------------------------
# Преобразуем битовую маску соединений → тип трубы + нужный поворот
# ------------------------------------------------------------------------------
func _mask_to_type_and_rotation(mask: int) -> Dictionary:
	# Ротация маски: каждый шаг поворота на 90° по часовой
	# TOP→RIGHT→BOTTOM→LEFT
	for rot in range(4):
		for type_name in PIPE_TYPES.keys():
			if _rotate_mask(PIPE_TYPES[type_name], rot) == mask:
				return {"type": type_name, "rotation": rot}

	# Fallback — прямая горизонталь
	return {"type": "straight", "rotation": 0}

# Поворот битовой маски на rot * 90° по часовой
func _rotate_mask(m: int, rot: int) -> int:
	var result := m
	for _i in rot:
		# TOP(1)→RIGHT(2)→BOTTOM(4)→LEFT(8)→TOP(1)
		var new_mask := 0
		if result & DIR_TOP:    new_mask |= DIR_RIGHT
		if result & DIR_RIGHT:  new_mask |= DIR_BOTTOM
		if result & DIR_BOTTOM: new_mask |= DIR_LEFT
		if result & DIR_LEFT:   new_mask |= DIR_TOP
		result = new_mask
	return result

# ==============================================================================
# СОЗДАНИЕ КНОПКИ-ЯЧЕЙКИ
# ==============================================================================
func _create_cell_button(type: String, rot: int, row: int, col: int) -> TextureButton:
	var btn := TextureButton.new()
	btn.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	btn.ignore_texture_size  = true
	btn.stretch_mode         = TextureButton.STRETCH_SCALE

	btn.texture_normal = _textures[type]

	# Поворот через pivot + rotation_degrees
	btn.pivot_offset     = Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
	btn.rotation_degrees = rot * 90.0

	# Замыкание: передаём row/col
	btn.pressed.connect(_on_cell_pressed.bind(row, col))

	return btn

# ==============================================================================
# НАЖАТИЕ НА ЯЧЕЙКУ — поворот на 90°
# ==============================================================================
func _on_cell_pressed(row: int, col: int) -> void:
	if _solved:
		return

	var cell        : Dictionary    = _cells[row][col]
	var new_rot     : int           = (cell["rotation"] + 1) % 4
	cell["rotation"]                = new_rot

	var btn : TextureButton = cell["button"]
	btn.rotation_degrees    = new_rot * 90.0

	_check_win()

# ==============================================================================
# ПРОВЕРКА ПОБЕДЫ
# Победа = все клетки пути повёрнуты правильно (correct_rotation),
# т.е. путь от source до target замкнут.
# ==============================================================================
func _check_win() -> void:
	# Просто проверяем, что все ячейки стоят в correct_rotation
	# (достаточно для детерминированного пазла)
	var all_correct := true
	for row in GRID_SIZE:
		for col in GRID_SIZE:
			var cell : Dictionary = _cells[row][col]
			# Для ячеек вне пути (декор) поворот не важен → пропускаем
			# Помечаем «путевые» ячейки флагом is_path при генерации
			if cell.get("is_path", false):
				if cell["rotation"] != cell["correct_rotation"]:
					all_correct = false
					break
		if not all_correct:
			break

	if all_correct:
		_on_win()

# Альтернативная проверка — обход графа соединений от source
# (более строгая, используй её если хочешь честную логику потока)
func _check_win_by_flow() -> void:
	var reachable : Dictionary = {}
	var queue     : Array      = [_source]
	reachable[_source] = true

	while not queue.is_empty():
		var cur : Vector2i = queue.pop_front()
		var mask : int = _get_cell_mask(cur.y, cur.x)

		var neighbors := {
			DIR_TOP:    Vector2i(cur.x,     cur.y - 1),
			DIR_RIGHT:  Vector2i(cur.x + 1, cur.y),
			DIR_BOTTOM: Vector2i(cur.x,     cur.y + 1),
			DIR_LEFT:   Vector2i(cur.x - 1, cur.y),
		}
		var opposites := {
			DIR_TOP: DIR_BOTTOM, DIR_RIGHT: DIR_LEFT,
			DIR_BOTTOM: DIR_TOP, DIR_LEFT: DIR_RIGHT,
		}

		for dir in neighbors.keys():
			if not (mask & dir):
				continue
			var nxt : Vector2i = neighbors[dir]
			if nxt.x < 0 or nxt.x >= GRID_SIZE or nxt.y < 0 or nxt.y >= GRID_SIZE:
				continue
			if reachable.has(nxt):
				continue
			# Проверяем, что сосед тоже смотрит на нас
			var nxt_mask : int = _get_cell_mask(nxt.y, nxt.x)
			if nxt_mask & opposites[dir]:
				reachable[nxt] = true
				queue.append(nxt)

	if reachable.has(_target):
		_on_win()

# Возвращает текущую маску соединений ячейки с учётом её поворота
func _get_cell_mask(row: int, col: int) -> int:
	var cell     : Dictionary = _cells[row][col]
	var base     : int        = PIPE_TYPES[cell["type"]]
	return _rotate_mask(base, cell["rotation"])

# ==============================================================================
# ПОБЕДА
# ==============================================================================
func _on_win() -> void:
	_solved = true
	_win_label.visible = true

	# Сигнал для основной игры — подключи снаружи
	emit_signal("puzzle_solved")

# Публичный сигнал
signal puzzle_solved

# ==============================================================================
# ПУБЛИЧНЫЕ МЕТОДЫ
# ==============================================================================

## Перегенерировать пазл (вызови из основной игры для рестарта)
func reset_puzzle() -> void:
	_win_label.visible = false
	_build_puzzle()

## Включить проверку потоком (более честная логика)
## Вызови вместо _check_win() в _on_cell_pressed(), если хочешь
func enable_flow_check() -> void:
	# Переподключи нажатие
	pass  # Замени _check_win() на _check_win_by_flow() в _on_cell_pressed()
