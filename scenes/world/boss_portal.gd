class_name BossPortal
extends Node2D
## Portal do Boss — aparece no centro da fase após eliminar todos os inimigos.
## Emite body_entered via Area2D quando o player entra.

signal player_entered

func _ready() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 1
	var cs    := CollisionShape2D.new()
	var circ  := CircleShape2D.new()
	circ.radius = 22.0
	cs.shape    = circ
	area.add_child(cs)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

	var lbl := Label.new()
	lbl.text = "BOSS"
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	lbl.position = Vector2(-10, -38)
	add_child(lbl)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var t := Time.get_ticks_msec() * 0.001
	var pulse := 1.0 + sin(t * 3.0) * 0.1

	# Aura externa
	draw_circle(Vector2.ZERO, 28.0 * pulse, Color(0.54, 0.0, 1.0, 0.15))

	# Anel giratório externo
	for i: int in 12:
		var a := (TAU / 12.0) * i + t * 1.2
		var p := Vector2(cos(a), sin(a)) * 22.0
		draw_circle(p, 2.5, Color(0.54, 0.0, 1.0, 0.8))

	# Anel interno contra-rotativo
	for i: int in 8:
		var a := (TAU / 8.0) * i - t * 0.8
		var p := Vector2(cos(a), sin(a)) * 15.0
		draw_circle(p, 2.0, Color(0.2, 0.8, 1.0, 0.9))

	# Núcleo pulsante
	draw_circle(Vector2.ZERO, 9.0 * pulse, Color(0.7, 0.2, 1.0, 0.9))
	draw_circle(Vector2.ZERO, 5.0,         Color(1.0, 0.9, 1.0, 0.7))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_entered.emit()
