extends Node2D

# Размер сетки — должен совпадать с центральным экраном
const GRID_W: float = 490.0
const GRID_H: float = 400.0
const GRID_COLS: int = 9
const GRID_ROWS: int = 6
const GRID_COLOR: Color = Color(0.2, 1.0, 0.05, 0.8)
const LINE_WIDTH: float = 1.5

func _draw() -> void:
	var cell_w := GRID_W / GRID_COLS
	var cell_h := GRID_H / GRID_ROWS

	# Вертикальные линии
	for i in range(GRID_COLS + 1):
		var x := i * cell_w
		draw_line(Vector2(x, 0), Vector2(x, GRID_H), GRID_COLOR, LINE_WIDTH)

	# Горизонтальные линии
	for i in range(GRID_ROWS + 1):
		var y := i * cell_h
		draw_line(Vector2(0, y), Vector2(GRID_W, y), GRID_COLOR, LINE_WIDTH)
