extends Node2D
## Level02 — Caldeira Vulcânica. Introduz S, Si, O novos.

const KILL_PLANE_Y := 620.0
const SPAWN_POS    := Vector2(80, 300)
const ELARA        := "Mestra Elara"
const ENCYCLOPEDIA := "Enciclopédia"

@onready var player   : Player    = $Player
@onready var _dialog  : DialogBox = $DialogBox
@onready var _alchemy : AlchemyPanel = $AlchemyPanel

var _respawning    := false
var _seen_elements : Array[String] = []
var _intro_done    := false

func _ready() -> void:
	get_tree().create_timer(1.2).timeout.connect(_show_intro)
	GameState.element_collected.connect(_on_element_collected)

func _process(_delta: float) -> void:
	if not _respawning and player.global_position.y > KILL_PLANE_Y:
		_respawn()

func _respawn() -> void:
	if _respawning:
		return
	_respawning = true
	player.global_position = SPAWN_POS
	player.reset_state()
	GameState.heal(GameState.player_max_health)
	await get_tree().process_frame
	_respawning = false

func _show_intro() -> void:
	_dialog.queue_dialogs([
		[ELARA, "A Caldeira Vulcânica! Calor intenso e enxofre dominam este lugar."],
		[ELARA, "Colete S (Enxofre) — combinado com O₂ forma SO₂, um gás sufocante e devastador!"],
		[ELARA, "Cuidado: as criaturas aqui são mais resistentes. Explore com calma."],
	])

func _on_element_collected(element_id: String, _amt: int) -> void:
	if element_id in _seen_elements:
		return
	_seen_elements.append(element_id)
	var el       := ElementDatabase.get_element(element_id)
	var el_name  : String = el.get("name", element_id)
	var el_desc  : String = el.get("description", "")
	var el_curio : String = el.get("curiosity", "")
	_dialog.show_dialog(ENCYCLOPEDIA,
		"%s (%s) — %s  ★ %s" % [el_name, element_id, el_desc, el_curio])
