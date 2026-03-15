extends Node2D
## Level01 — Fase de teste de plataformer.

const KILL_PLANE_Y := 520.0
const SPAWN_POS    := Vector2(70, 350)
const ELARA        := "Mestra Elara"
const ENCYCLOPEDIA := "Enciclopédia"

@onready var player  : Player        = $Player
@onready var _dialog : DialogBox     = $DialogBox
@onready var _hints  : TutorialHints = $TutorialHints
@onready var _alchemy: AlchemyPanel  = $AlchemyPanel

var _respawning        := false
var _h2o_dialog_done   := false
var _enemy_dialog_done := false

# Tutorial state
var _seen_elements          : Array[String] = []
var _moved_done             := false
var _alchemy_done           := false
var _attack_done            := false
var _tutorial_h2o_triggered := false

func _ready() -> void:
	GameState.player_died.connect(_respawn)
	get_tree().create_timer(1.0).timeout.connect(_show_intro)
	GameState.compound_created.connect(_on_compound_created)
	GameState.checkpoint_reached.connect(_on_checkpoint_reached)
	GameState.element_collected.connect(_on_element_first_collected)
	_alchemy.panel_opened.connect(_on_first_alchemy_open)
	_dialog.dialog_queue_finished.connect(_on_any_dialog_closed)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.connect("died", _on_enemy_died)

func _process(_delta: float) -> void:
	if not _respawning and player.global_position.y > KILL_PLANE_Y:
		_respawn()
	if not _moved_done and abs(player.velocity.x) > 5.0:
		_moved_done = true
		_hints.hide_hint()

func _unhandled_input(event: InputEvent) -> void:
	if not _attack_done and GameState.active_compound != "":
		if event.is_action_pressed("attack") and not event.is_echo():
			_attack_done = true
			_hints.hide_hint()

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
		[ELARA, "Kael! Finalmente acordou. A explosão criou fendas dimensionais por todo o laboratório!"],
		[ELARA, "Explore o laboratório — colete os elementos H e O nos dispensadores ao redor."],
		[ELARA, "Cada elemento tem propriedades únicas. Combinados, formam compostos poderosos!"],
	])

func _on_any_dialog_closed() -> void:
	if not _moved_done:
		_hints.show_hint("WASD / ← →   Mover        ESPAÇO   Pular")
		return

	if _tutorial_h2o_triggered and not _alchemy_done:
		_alchemy.tutorial_unlock = true
		_hints.show_hint("Q — Abrir o Painel de Alquimia e misture seus elementos!")
		get_tree().paused = true
		return

	if not _alchemy_done:
		if _alchemy.can_craft_anything():
			_hints.show_hint("Q — Painel de Alquimia")
	elif not _attack_done and GameState.active_compound != "":
		_hints.show_hint("J / Click — Atirar composto")

func _on_element_first_collected(element_id: String, _amt: int) -> void:
	# Dialog de primeira coleta
	if element_id not in _seen_elements:
		_seen_elements.append(element_id)
		var el       := ElementDatabase.get_element(element_id)
		var el_name  : String = el.get("name", element_id)
		var el_desc  : String = el.get("description", "")
		var el_curio : String = el.get("curiosity", "")
		_dialog.show_dialog(ENCYCLOPEDIA,
			"%s (%s) — %s  ★ %s" % [el_name, element_id, el_desc, el_curio])

	# Checar trigger H2O após QUALQUER coleta (não só a primeira)
	if not _tutorial_h2o_triggered:
		var h : int = GameState.collected_elements.get("H", 0)
		var o : int = GameState.collected_elements.get("O", 0)
		if h >= 2 and o >= 1:
			_tutorial_h2o_triggered = true
			_dialog.show_dialog(ELARA,
				"Kael! Você tem H×2 e O×1 — ingredientes da ÁGUA (H₂O)! Abra o Painel de Alquimia para misturá-los!")

func _on_first_alchemy_open() -> void:
	_alchemy_done = true
	_hints.hide_hint()
	if _tutorial_h2o_triggered and not _h2o_dialog_done:
		_alchemy.start_h2o_tutorial()

func _on_compound_created(compound_id: String) -> void:
	if compound_id == "H2O" and not _h2o_dialog_done:
		_h2o_dialog_done = true
		_alchemy.panel_unlocked = true  # painel livre a partir daqui
		_dialog.show_dialog(ELARA,
			"Perfeito! Você criou H₂O — Água! 2 átomos de H + 1 de O formam a molécula mais importante para a vida. Agora use-a para derrotar os Slimes!")

func _on_enemy_died(_enemy: Node) -> void:
	if not _enemy_dialog_done:
		_enemy_dialog_done = true
		_dialog.show_dialog(ELARA,
			"Muito bem! Fogo é derrotado pela água — reação de extinção térmica!")

func _on_checkpoint_reached(_checkpoint_id: String) -> void:
	_dialog.show_dialog(ELARA,
		"Você chegou longe, Kael. Hora de provar seus conhecimentos. Responda o quiz para continuar!")
