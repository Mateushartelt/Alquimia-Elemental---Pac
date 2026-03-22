extends Node2D
## Level01 — Fase de teste de plataformer.

const KILL_PLANE_Y := 700.0
const SPAWN_POS    := Vector2(950, 310)
const ELARA        := "Mestra Elara"
const ENCYCLOPEDIA := "Enciclopédia"

@onready var player        : Player        = $Player
@onready var _dialog       : DialogBox     = $DialogBox
@onready var _hints        : TutorialHints = $TutorialHints
@onready var _alchemy      : AlchemyPanel  = $AlchemyPanel
@onready var _boss_battle  : BossBattle    = $BossBattle
@onready var _barrier_wall : StaticBody2D  = $BarrierWall
@onready var _fire_wall    : Node2D        = $FireWall
@onready var _door_in      : Area2D        = $DoorIn
@onready var _cam          : Camera2D      = $Player/Camera2D

var _respawning             := false
var _h2o_dialog_done   := false
var _enemy_dialog_done := false
var _barrier_opened    := false
var _fire_cleared        := false
var _came_from_tutorial  := false
var _shaft_fog_cleared   := false
var _shaft_b_fog_cleared := false
var _cave_fog_cleared    := false
var _cinematic_done      := false
var _portal_hint_done    := false
var _in_tunnel           := false
var _zoom_tween          : Tween = null

# Tutorial state
var _seen_elements          : Array[String] = []
var _moved_done             := false
var _alchemy_done           := false
var _attack_done            := false
var _tutorial_h2o_triggered := false

func _ready() -> void:
	_cam.limit_left   = 0
	_cam.limit_right  = 1600
	_cam.limit_top    = 80
	_cam.limit_bottom = 400
	_cam.zoom         = Vector2(3, 3)  # zoom inicial do hub (espaço aberto)
	_cam.limit_left   = 800            # bloqueia esquerda no step wall
	if "H2O" in GameState.discovered_compounds:
		_came_from_tutorial = true
		_cinematic_done     = true
		_h2o_dialog_done    = true
		_portal_hint_done   = true
		get_tree().create_timer(0.4).timeout.connect(func() -> void:
			_dialog.show_dialog(ELARA,
				"H₂O pronto! Equipe o composto (Scroll do mouse) e atire (J) na Parede de Fogo!"))
	else:
		get_tree().create_timer(1.0).timeout.connect(_show_intro)
	GameState.compound_created.connect(_on_compound_created)
	GameState.checkpoint_reached.connect(_on_checkpoint_reached)
	GameState.element_collected.connect(_on_element_first_collected)
	_alchemy.panel_opened.connect(_on_first_alchemy_open)
	_dialog.dialog_queue_finished.connect(_on_any_dialog_closed)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.connect("died", _on_enemy_died)

func _process(_delta: float) -> void:
	if get_tree().paused:
		return
	if not _respawning and player.global_position.y > KILL_PLANE_Y:
		_respawn()
	if not _moved_done and abs(player.velocity.x) > 5.0:
		_moved_done = true
		_hints.hide_hint()
	# Dica do portal: quando player chega perto o suficiente para ver o portal
	if not _portal_hint_done and not _h2o_dialog_done and player.global_position.x < 380.0:
		_portal_hint_done = true
		_dialog.show_dialog(ELARA,
			"Um portal de emergência! Entre por ele — lá você poderá criar H₂O para apagar o fogo!")
	# Zoom túnel ↔ hub (sempre ativo; limit_left só muda antes do fogo ser extinto)
	if player.global_position.x > 820.0 and _in_tunnel:
		_in_tunnel = false
		if not _fire_cleared:
			_cam.limit_left = 800
		_set_zoom(Vector2(3, 3), 0.5)
	elif player.global_position.x <= 780.0 and not _in_tunnel:
		_in_tunnel = true
		if not _fire_cleared:
			_cam.limit_left = 250
		_set_zoom(Vector2(8, 8), 0.5)

func _make_cine_cam(start_pos: Vector2, zoom: Vector2) -> Camera2D:
	var cc        := Camera2D.new()
	cc.position    = start_pos
	cc.zoom        = zoom
	cc.limit_left  = _cam.limit_left
	cc.limit_right = _cam.limit_right
	cc.limit_top   = _cam.limit_top
	cc.limit_bottom = _cam.limit_bottom
	add_child(cc)
	_cam.enabled = false
	return cc

func _end_cine_cam(cc: Camera2D) -> void:
	cc.enabled    = false
	_cam.offset   = Vector2(0, -20)
	_cam.enabled  = true
	_cam.reset_smoothing()
	cc.queue_free()

func _set_zoom(target: Vector2, duration: float) -> void:
	if _zoom_tween:
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(_cam, "zoom", target, duration)

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
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
		[ELARA, "Kael! O Reator Alfa explodiu — fissão descontrolada está abrindo fendas dimensionais!"],
		[ELARA, "As criaturas do subplano estão invadindo e o corredor está tomado por chamas do reator!"],
		[ELARA, "Para apagar o fogo, você precisará de H₂O. O portal azul aqui perto leva ao Módulo de Síntese!"],
	])

func _run_opening_cinematic() -> void:
	var start_pos := Vector2(player.global_position.x, player.global_position.y - 20)
	var cine_cam  := _make_cine_cam(start_pos, _cam.zoom)

	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	process_mode        = Node.PROCESS_MODE_ALWAYS
	get_tree().paused   = true

	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(cine_cam, "position", Vector2(1400.0, start_pos.y), 2.0)
	tw.tween_interval(1.5)
	tw.tween_property(cine_cam, "position", start_pos, 2.0)
	await tw.finished

	get_tree().paused   = false
	process_mode        = Node.PROCESS_MODE_INHERIT
	player.process_mode = Node.PROCESS_MODE_INHERIT
	_end_cine_cam(cine_cam)
	_hints.show_hint("WASD / ← →   Mover        ESPAÇO   Pular")

func _on_any_dialog_closed() -> void:
	if not _cinematic_done and not _came_from_tutorial:
		_cinematic_done = true
		_run_opening_cinematic()
		return

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
	# Dialog de primeira coleta do elemento
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
			"Perfeito! H₂O criado! 2H + 1O = água — a molécula mais importante da vida. Equipe o composto (Scroll) e atire (J) na Parede de Fogo para abrir o caminho!")

func _on_enemy_died(_enemy: Node) -> void:
	if not _enemy_dialog_done:
		_enemy_dialog_done = true
		_dialog.show_dialog(ELARA,
			"Muito bem! Fogo é derrotado pela água — reação de extinção térmica!")

func _on_checkpoint_reached(_checkpoint_id: String) -> void:
	_dialog.show_dialog(ELARA,
		"Bom trabalho, Kael! Continue avançando — algo grande te espera mais à frente...")

func _on_shaft_fog_entered(body: Node2D) -> void:
	if _shaft_fog_cleared or not body.is_in_group("player"):
		return
	_shaft_fog_cleared = true
	var tw := create_tween()
	tw.tween_property($DarkAreas/ShaftFog, "color", Color(0, 0, 0, 0), 0.8)

func _on_cave_fog_entered(body: Node2D) -> void:
	if _cave_fog_cleared or not body.is_in_group("player"):
		return
	_cave_fog_cleared = true
	var tw := create_tween()
	tw.tween_property($DarkAreas/CaveFog, "color", Color(0, 0, 0, 0), 0.8)
	_dialog.show_dialog(ELARA, "Que lugar sombrio... mas sinto energia química escondida aqui!")

func _on_door_in_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/levels/tutorial_room.tscn")

func _on_fire_extinguished() -> void:
	_fire_cleared = true
	# Não toca no zoom nem em _in_tunnel — _process continua gerindo as transições
	_dialog.queue_dialogs([
		[ELARA, "Excelente! H₂O absorveu o calor e extinguiu o fogo — reação endotérmica!"],
		[ELARA, "O corredor está livre! Explore também o lado esquerdo — há elementos escondidos na cave!"],
	])
	await _dialog.dialog_queue_finished
	_run_portal_explosion()

func _run_portal_explosion() -> void:
	# Expande limites da câmera para o mapa completo
	_cam.limit_left   = 0
	_cam.limit_right  = 3200
	_cam.limit_top    = -500
	_cam.limit_bottom = 680

	var start_pos := Vector2(player.global_position.x, player.global_position.y - 20)
	var cine_cam  := _make_cine_cam(start_pos, Vector2(3, 3))

	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	process_mode        = Node.PROCESS_MODE_ALWAYS
	get_tree().paused   = true

	# Pan câmera esquerda até o portal (x=250)
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(cine_cam, "position", Vector2(250.0, start_pos.y), 1.5)
	await tw.finished

	# Remove portal
	if is_instance_valid(_door_in):
		_door_in.queue_free()

	# Flash de explosão
	var flash := ColorRect.new()
	flash.z_index  = 10
	flash.position = Vector2(226, 288)
	flash.size     = Vector2(48, 80)
	flash.color    = Color(1.0, 0.55, 0.1, 1.0)
	add_child(flash)

	var flash_tw := create_tween()
	flash_tw.set_parallel(true)
	flash_tw.tween_property(flash, "scale",    Vector2(4, 4),                0.6)
	flash_tw.tween_property(flash, "color",    Color(1.0, 0.55, 0.1, 0.0),  0.6)
	flash_tw.tween_property(flash, "position", Vector2(226 - 48, 288 - 120), 0.6)
	await flash_tw.finished
	flash.queue_free()

	# Pan volta ao player
	var tw2 := create_tween()
	tw2.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(cine_cam, "position", start_pos, 1.0)
	await tw2.finished

	get_tree().paused   = false
	process_mode        = Node.PROCESS_MODE_INHERIT
	player.process_mode = Node.PROCESS_MODE_INHERIT
	_end_cine_cam(cine_cam)

func _on_shaft_b_fog_entered(body: Node2D) -> void:
	if _shaft_b_fog_cleared or not body.is_in_group("player"):
		return
	_shaft_b_fog_cleared = true
	var tw := create_tween()
	tw.tween_property($DarkAreas/ShaftFogB, "color", Color(0, 0, 0, 0), 0.8)

func _on_barrier_check_entered(body: Node2D) -> void:
	if _barrier_opened or not body.is_in_group("player"):
		return
	var has_na := GameState.get_element_count("Na") >= 1
	var has_cl := GameState.get_element_count("Cl") >= 1
	if has_na and has_cl:
		_barrier_opened = true
		_barrier_wall.get_node("CollisionShape2D").disabled = true
		_barrier_wall.visible = false
		_dialog.show_dialog(ELARA,
			"Você tem Na e Cl! Combine-os para criar NaCl — a lesma teme o sal!")
	else:
		_dialog.show_dialog(ELARA,
			"Perigoso! Você precisa de ao menos 1 Na e 1 Cl. Volte e colete mais — a lesma resseca com NaCl!")

func _on_boss_trigger_entered(_body: Node2D) -> void:
	_boss_battle.show_battle("snail")
	_boss_battle.battle_finished.connect(_on_boss_battle_finished, CONNECT_ONE_SHOT)

func _on_boss_battle_finished(won: bool) -> void:
	if won:
		_dialog.queue_dialogs([
			[ELARA, "Incrível! NaCl age por osmose — ressecou o muco da lesma!"],
			[ELARA, "Uma fenda dimensional se abre... A Caldeira Vulcânica te aguarda!"],
		])
		GameState.complete_level(1)
		await _dialog.dialog_queue_finished
		var tw := create_tween()
		tw.tween_property($FadeOverlay, "color", Color(0, 0, 0, 1), 1.2)
		await tw.finished
		get_tree().change_scene_to_file("res://scenes/levels/level_02.tscn")
	else:
		_dialog.show_dialog(ELARA, "A Lesma foi forte demais... Colete mais Na e Cl e tente de novo!")
