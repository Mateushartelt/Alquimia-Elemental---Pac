extends Area2D
## ElementPickup — Elemento químico coletável no mapa.
## Visual 100% procedural via _draw(). Sem nós filhos de sprite.

@export var element_id: String = "H"

var _collected  := false
var _bob_origin := 0.0
var _bob_time   := 0.0

const COLORS := {
	"H":  Color(0.40, 0.65, 1.00, 1),
	"O":  Color(0.20, 0.75, 0.95, 1),
	"Na": Color(1.00, 0.80, 0.10, 1),
	"S":  Color(0.95, 0.95, 0.10, 1),
	"Cl": Color(0.50, 1.00, 0.40, 1),
	"C":  Color(0.55, 0.55, 0.55, 1),
	"Si": Color(0.65, 0.50, 0.80, 1),
}

func _ready() -> void:
	_bob_origin = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_bob_time  += delta * 2.5
	position.y  = _bob_origin + sin(_bob_time) * 4.0
	queue_redraw()

func _draw() -> void:
	var base: Color = COLORS.get(element_id, Color(0.8, 0.8, 0.8, 1))
	var pulse: float = (sin(Time.get_ticks_msec() * 0.003) * 0.5 + 0.5) * 0.12

	# Glow externo pulsante
	draw_circle(Vector2.ZERO, 8.0, Color(base.r, base.g, base.b, 0.22 + pulse))

	# Corpo principal
	draw_circle(Vector2.ZERO, 6.5, base)

	# Borda sutil
	draw_arc(Vector2.ZERO, 6.5, 0.0, TAU, 24, Color(0, 0, 0, 0.3), 0.75)

	# Highlight arc (canto superior esquerdo)
	draw_arc(Vector2.ZERO, 4.0, 3.5, 5.5, 10, Color(1, 1, 1, 0.45), 1.5)

	# Símbolo químico centrado
	var font     := ThemeDB.fallback_font
	var lum      := base.get_luminance()
	var txt_col  := Color(0.05, 0.05, 0.05) if lum > 0.5 else Color.WHITE
	var fsize    := 7
	var x_off    := -2.0 if element_id.length() == 1 else -4.5
	draw_string(font, Vector2(x_off, 3.0), element_id,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, txt_col)

func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if not body is Player:
		return
	_collected = true
	body.collect(element_id)
	queue_free()
