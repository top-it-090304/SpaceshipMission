## FinalScene.gd
## Корабль улетает → варп-вспышка в стиле Star Trek (звезда из лучей)
extends Node2D

@onready var ship: Sprite2D = $Ship

const FLY_DURATION := 7.0

func _ready() -> void:
	PycoLog.log_event_by_type("quest_complete", {})
	await get_tree().create_timer(0.6).timeout
	_fly_away()

# ── Полёт ─────────────────────────────────────────────────────────────────────
func _fly_away() -> void:
	var vp_size := get_viewport_rect().size
	var target_pos   := Vector2(ship.position.x, vp_size.y * 0.21)
	var target_scale := ship.scale * 0.012

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ship, "position", target_pos, FLY_DURATION) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(ship, "scale", target_scale, FLY_DURATION) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	# Ждём бо́льшую часть полёта, потом запускаем вспышку пока корабль ещё виден
	await get_tree().create_timer(FLY_DURATION - 0.9).timeout

	var flash_pos := ship.position   # корабль уже крошечный, но ещё на экране
	ship.visible = false
	tw.kill()                        # тween больше не нужен
	await _show_flash(flash_pos)

	# Через несколько секунд после вспышки — открываем настройки
	await get_tree().create_timer(3.0).timeout
	var menu := preload("res://scenes/PauseMenu.tscn").instantiate()
	add_child(menu)
	menu.get_node("Background/ResumeButton").visible = false

# ── Варп-вспышка ──────────────────────────────────────────────────────────────
func _show_flash(pos: Vector2) -> void:
	# Мягкое синее послесвечение (задний план)
	var glow := _circle(pos, Color(0.10, 0.45, 1.00, 0.38), 18.0)

	# Горизонтальные лучи — самые длинные (главный варп-эффект)
	var h_r := _streak(pos,  0.0,         340.0, Color(0.80, 0.96, 1.00, 1.0), 6.0)
	var h_l := _streak(pos,  PI,          340.0, Color(0.80, 0.96, 1.00, 1.0), 6.0)

	# Вертикальные лучи — средние
	var v_u := _streak(pos, -PI * 0.5,   110.0, Color(0.55, 0.83, 1.00, 0.9), 3.5)
	var v_d := _streak(pos,  PI * 0.5,   110.0, Color(0.55, 0.83, 1.00, 0.9), 3.5)

	# Диагональные лучи — короткие
	var d1  := _streak(pos,  PI * 0.25,   62.0, Color(0.42, 0.73, 1.00, 0.75), 2.0)
	var d2  := _streak(pos,  PI * 0.75,   62.0, Color(0.42, 0.73, 1.00, 0.75), 2.0)
	var d3  := _streak(pos,  PI * 1.25,   62.0, Color(0.42, 0.73, 1.00, 0.75), 2.0)
	var d4  := _streak(pos,  PI * 1.75,   62.0, Color(0.42, 0.73, 1.00, 0.75), 2.0)

	# Яркое белое ядро поверх всего
	var core := _circle(pos, Color(1.00, 1.00, 1.00, 1.00), 7.0)

	var all_streaks := [h_r, h_l, v_u, v_d, d1, d2, d3, d4]

	# Добавляем в сцену (порядок = z-слои)
	add_child(glow)
	for s in all_streaks:
		s.scale = Vector2.ZERO
		add_child(s)
	core.scale = Vector2.ZERO
	glow.scale = Vector2.ZERO
	add_child(core)

	# ── Анимация ─────────────────────────────────────────────────────────────
	var anim := create_tween()
	anim.set_parallel(true)

	# Белое ядро: мгновенная вспышка
	anim.tween_property(core, "scale",      Vector2(3.0, 3.0), 0.08) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	anim.tween_property(core, "modulate:a", 0.0,               0.30) \
		.set_delay(0.05)

	# Послесвечение: медленно расширяется и гаснет
	anim.tween_property(glow, "scale",      Vector2(10.0, 10.0), 1.0) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	anim.tween_property(glow, "modulate:a", 0.0,                 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Горизонтальные — быстро вылетают, чуть дольше держатся
	for s in [h_r, h_l]:
		anim.tween_property(s, "scale",      Vector2(1.0, 1.0), 0.18) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		anim.tween_property(s, "modulate:a", 0.0,               0.55) \
			.set_delay(0.12)

	# Вертикальные
	for s in [v_u, v_d]:
		anim.tween_property(s, "scale",      Vector2(1.0, 1.0), 0.16) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		anim.tween_property(s, "modulate:a", 0.0,               0.42) \
			.set_delay(0.08)

	# Диагональные — самые быстрые
	for s in [d1, d2, d3, d4]:
		anim.tween_property(s, "scale",      Vector2(1.0, 1.0), 0.13) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		anim.tween_property(s, "modulate:a", 0.0,               0.32) \
			.set_delay(0.05)

	await anim.finished

	core.queue_free()
	glow.queue_free()
	for s in all_streaks:
		s.queue_free()

# ── Вспомогательные ───────────────────────────────────────────────────────────

# Закрашенный круг (для ядра и свечения)
func _circle(pos: Vector2, color: Color, radius: float) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color    = color
	poly.position = pos
	var pts := PackedVector2Array()
	for i in range(64):
		var a := i * TAU / 64.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = pts
	return poly

# Сужающийся луч (Line2D с кривой ширины — широкий у центра, точка на конце)
func _streak(pos: Vector2, angle: float, length: float,
			 color: Color, base_width: float) -> Line2D:
	var line := Line2D.new()
	line.default_color = color
	line.width         = base_width
	line.position      = pos
	line.rotation      = angle
	line.points        = PackedVector2Array([Vector2.ZERO, Vector2(length, 0.0)])

	# Кривая ширины: 1.0 у начала → 0.0 на кончике
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	line.width_curve = curve

	return line
