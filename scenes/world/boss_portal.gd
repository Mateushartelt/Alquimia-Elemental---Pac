class_name BossPortal
extends Node2D
## Portal do Boss — aparece no centro da fase após eliminar todos os inimigos.
## Emite body_entered via Area2D quando o player entra.

signal player_entered

const PORTAL_TEX := "res://scenes/world/assets/portal_closed.png"

var _sprite : Sprite2D = null

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

	# Sprite do portal (tom roxo de boss)
	var tex: Texture2D = load(PORTAL_TEX)
	if tex:
		_sprite = Sprite2D.new()
		_sprite.texture        = tex
		_sprite.centered       = true
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_sprite.modulate       = Color(1.0, 0.5, 1.0)   # tinta roxa
		var s := 90.0 / float(tex.get_height())
		_sprite.scale = Vector2(s, s)
		add_child(_sprite)

	var lbl := Label.new()
	lbl.text = "BOSS"
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	lbl.position = Vector2(-10, -58)
	add_child(lbl)

func _process(_delta: float) -> void:
	if not is_instance_valid(_sprite):
		queue_redraw()
		return
	# Pulso suave de escala + brilho
	var t := Time.get_ticks_msec() * 0.001
	var pulse := 1.0 + sin(t * 3.0) * 0.06
	var base_s := 90.0 / float(_sprite.texture.get_height())
	_sprite.scale = Vector2(base_s * pulse, base_s * pulse)
	_sprite.modulate.a = 0.85 + sin(t * 2.5) * 0.15

func _draw() -> void:
	# Fallback procedural caso a textura não carregue
	if is_instance_valid(_sprite):
		return
	var t := Time.get_ticks_msec() * 0.001
	var pulse := 1.0 + sin(t * 3.0) * 0.1
	draw_circle(Vector2.ZERO, 28.0 * pulse, Color(0.54, 0.0, 1.0, 0.15))
	for i: int in 12:
		var a := (TAU / 12.0) * i + t * 1.2
		draw_circle(Vector2(cos(a), sin(a)) * 22.0, 2.5, Color(0.54, 0.0, 1.0, 0.8))
	draw_circle(Vector2.ZERO, 9.0 * pulse, Color(0.7, 0.2, 1.0, 0.9))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_entered.emit()
