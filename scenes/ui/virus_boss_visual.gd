class_name VirusBossVisual
extends Control
## Visual procedural animado do Supervírus — boss do Level 03.
## Substitui o TextureRect quando draw_mode == "virus_proc".

var flash_color: Color = Color.TRANSPARENT
var flash_timer: float = 0.0

func _process(delta: float) -> void:
	flash_timer = maxf(0.0, flash_timer - delta)
	if flash_timer <= 0.0:
		flash_color = Color.TRANSPARENT
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var base   := Color(0.54, 0.0, 1.0)
	var fa     := clampf(flash_timer / 0.15, 0.0, 1.0)
	var col    := base.lerp(flash_color if fa > 0.0 else base, fa)
	var dark   := Color(0.15, 0.0, 0.30)
	var spike  := col.lightened(0.3)

	var t      := Time.get_ticks_msec() * 0.001
	var pulse  := 1.0 + sin(t * 2.0) * 0.06
	var radius := 80.0 * pulse

	# ── Aura pulsante multicamadas ────────────────────────────────────────
	for ring: int in 3:
		var rp := 1.0 + sin(t * 1.5 + ring * 0.8) * 0.12
		var rc := Color(col.r, col.g, col.b, 0.07 - ring * 0.02)
		draw_circle(center, radius * (1.5 + ring * 0.25) * rp, rc)

	# ── Anel de membrana duplo (rotações opostas) ─────────────────────────
	for seg: int in 24:
		var a1 := (TAU / 24.0) * seg + t * 0.4
		var a2 := a1 + TAU / 48.0
		draw_line(
			center + Vector2(cos(a1), sin(a1)) * radius * 1.18,
			center + Vector2(cos(a2), sin(a2)) * radius * 1.22,
			col.darkened(0.25), 2.0)

	for seg: int in 18:
		var a1 := (TAU / 18.0) * seg - t * 0.3
		var a2 := a1 + TAU / 36.0
		draw_line(
			center + Vector2(cos(a1), sin(a1)) * radius * 1.30,
			center + Vector2(cos(a2), sin(a2)) * radius * 1.34,
			spike, 1.5)

	# ── Corpo central ────────────────────────────────────────────────────
	draw_circle(center, radius, col)
	draw_arc(center, radius, 0.0, TAU, 64, dark, 2.5)

	# ── Núcleo interno brilhante ─────────────────────────────────────────
	draw_circle(center, radius * 0.45, Color(col.r + 0.3, col.g, col.b + 0.3, 0.55))

	# ── 16 espículas longas (camada externa, rotação horária) ─────────────
	for i: int in 16:
		var angle := (TAU / 16.0) * i + t * 0.35
		var tip   := center + Vector2(cos(angle), sin(angle)) * (radius + 30.0)
		var lv    := center + Vector2(cos(angle + 0.18), sin(angle + 0.18)) * radius * 0.9
		var rv    := center + Vector2(cos(angle - 0.18), sin(angle - 0.18)) * radius * 0.9
		draw_colored_polygon([lv, tip, rv], spike)

	# ── 8 espículas curtas (camada interna, rotação anti-horária) ─────────
	for i: int in 8:
		var angle := (TAU / 8.0) * i - t * 0.5 + 0.2
		var tip   := center + Vector2(cos(angle), sin(angle)) * (radius + 18.0)
		var lv    := center + Vector2(cos(angle + 0.25), sin(angle + 0.25)) * radius * 0.85
		var rv    := center + Vector2(cos(angle - 0.25), sin(angle - 0.25)) * radius * 0.85
		draw_colored_polygon([lv, tip, rv], col.lightened(0.4))

	# ── 3 Olhos vermelhos em triângulo ───────────────────────────────────
	var eye_r := radius * 0.28
	var eyes  := [
		center + Vector2(-eye_r, -eye_r * 0.6),
		center + Vector2( eye_r, -eye_r * 0.6),
		center + Vector2(0.0,    eye_r * 0.5),
	]
	for eye: Vector2 in eyes:
		draw_circle(eye, 9.0, Color(0.9, 0.0, 0.0))
		draw_circle(eye + Vector2(2.5, -2.5), 3.5, Color.WHITE)
		draw_arc(eye, 9.0, 0.0, TAU, 16, Color(0.5, 0.0, 0.0), 1.0)

	# ── Boca dentada (zigue-zague) ───────────────────────────────────────
	var mouth_y := center.y + eye_r * 0.9
	var mouth_w := radius * 0.45
	var pts     : PackedVector2Array = []
	for k: int in 7:
		var mx := center.x - mouth_w + k * (mouth_w * 2.0 / 6.0)
		var my := mouth_y + (6.0 if k % 2 == 0 else -6.0)
		pts.append(Vector2(mx, my))
	for k: int in pts.size() - 1:
		draw_line(pts[k], pts[k + 1], dark, 2.5)

func apply_flash(color: Color) -> void:
	flash_color = color
	flash_timer = 0.15
