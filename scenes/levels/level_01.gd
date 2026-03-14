extends Node2D
## Level01 — Fase de teste de plataformer.

const KILL_PLANE_Y := 520.0
const SPAWN_POS    := Vector2(70, 350)
const E            := "Mestra Elara"

@onready var player : Player    = $Player
@onready var _dialog: DialogBox = $DialogBox

var _respawning        := false
var _h2o_dialog_done   := false
var _enemy_dialog_done := false

func _ready() -> void:
	GameState.player_died.connect(_respawn)
	get_tree().create_timer(1.0).timeout.connect(_show_intro)
	GameState.compound_created.connect(_on_compound_created)
	GameState.checkpoint_reached.connect(_on_checkpoint_reached)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.died.connect(_on_enemy_died)

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
		[E, "Kael! Finalmente acordou. A explosão criou fendas dimensionais por todo o laboratório!"],
		[E, "Caminhe sobre os dispensadores para coletar H e O. Depois pressione Q para abrir o painel de Alquimia."],
		[E, "Combine H + H + O para criar H2O — Água. Use-a para apagar o fogo e derrotar inimigos!"],
	])

func _on_compound_created(compound_id: String) -> void:
	if compound_id == "H2O" and not _h2o_dialog_done:
		_h2o_dialog_done = true
		_dialog.show_dialog(E,
			"Excelente! H2O criado! Dois Hidrogênios e um Oxigênio formam a molécula de água. Agora use-a!")

func _on_enemy_died(_enemy: Node) -> void:
	if not _enemy_dialog_done:
		_enemy_dialog_done = true
		_dialog.show_dialog(E,
			"Muito bem! Fogo é derrotado pela água — reação de extinção térmica!")

func _on_checkpoint_reached(_checkpoint_id: String) -> void:
	_dialog.show_dialog(E,
		"Você chegou longe, Kael. Hora de provar seus conhecimentos. Responda o quiz para continuar!")
