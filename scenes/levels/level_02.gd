extends Node2D
## Level02 — Caldeira Vulcânica. Metroidvania Lock & Key.
## O (Oxigênio) exclusivo na Sala Alta → player sobe shaft → crafta H₂O
## → dissolve barreira de lava → Zona 2 (plataformas sobre lava) → Zona 3 arena
## → mata G3 → portal do boss Golem de Lava.

const KILL_PLANE_Y  := 640.0
const SPAWN_POS     := Vector2(100, 330)
const ELARA         := "Mestra Elara"
const ENCYCLOPEDIA  := "Enciclopédia"

@onready var player          : Player       = $Player
@onready var _dialog         : DialogBox    = $DialogBox
@onready var _alchemy        : AlchemyPanel = $AlchemyPanel
@onready var _boss           : BossBattle   = $BossBattle
@onready var _cam            : Camera2D     = $Player/Camera2D
@onready var _fog            : ColorRect    = $DarkAreas/SalaAltaFog
@onready var _fade           : ColorRect    = $FadeOverlay
@onready var _barrier_visual : ColorRect    = $LavaBarrier/Visual
@onready var _barrier_wall   : StaticBody2D = $LavaBarrier/Wall

const TOTAL_ENEMIES := 3

var _respawning        := false
var _seen_elements     : Array[String] = []
var _fog_cleared       := false
var _boss_started      := false
var _in_sala_alta      := false
var _enemy_dialog_done := false
var _barrier_dissolved := false
var _zoom_tween        : Tween = null
var _enemies_killed    := 0
var _boss_portal       : BossPortal = null

func _ready() -> void:
	_cam.zoom                       = Vector2(3, 3)
	_cam.limit_left                 = 0
	_cam.limit_top                  = 60
	_cam.limit_right                = 2400
	_cam.limit_bottom               = 450
	_cam.position_smoothing_enabled = true
	_cam.drag_horizontal_enabled    = true
	# Fade de entrada
	_fade.color   = Color(0, 0, 0, 1)
	_fade.visible = true
	var tw := create_tween()
	tw.tween_property(_fade, "color", Color(0, 0, 0, 0), 1.0)
	tw.tween_callback(func() -> void: _fade.visible = false)
	GameState.element_collected.connect(_on_element_collected)
	get_tree().create_timer(1.0).timeout.connect(_show_intro)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_signal("died"):
			enemy.connect("died", _on_enemy_died)

func _process(_delta: float) -> void:
	if not _respawning and player.global_position.y > KILL_PLANE_Y:
		_respawn()
	_update_camera()

func _update_camera() -> void:
	var in_alta := player.global_position.y < -80.0
	if in_alta and not _in_sala_alta:
		_in_sala_alta = true
		_cam.drag_horizontal_enabled    = false
		_cam.position_smoothing_enabled = true
		_set_zoom(Vector2(4, 4), 0.6)
		_cam.limit_left   = 0
		_cam.limit_top    = -380
		_cam.limit_right  = 704
		_cam.limit_bottom = -80
	elif not in_alta and _in_sala_alta:
		_in_sala_alta = false
		_cam.drag_horizontal_enabled    = true
		_cam.position_smoothing_enabled = true
		_set_zoom(Vector2(3, 3), 0.5)
		_cam.limit_left   = 0
		_cam.limit_top    = 60
		_cam.limit_right  = 2400
		_cam.limit_bottom = 450

func _set_zoom(target: Vector2, duration: float) -> void:
	if _zoom_tween:
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(_cam, "zoom", target, duration)

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
		[ELARA, "A Caldeira Vulcânica! Enxofre e calor dominam este lugar."],
		[ELARA, "Colete H (Hidrogênio) aqui embaixo — mas o Oxigênio está LÁ EM CIMA!"],
		[ELARA, "A barreira de lava bloqueia o caminho. Suba, colete O, crie H₂O e dissolva-a!"],
	])

func _on_element_collected(element_id: String, _amt: int) -> void:
	if element_id in _seen_elements:
		return
	_seen_elements.append(element_id)
	var el      := ElementDatabase.get_element(element_id)
	var el_name : String = el.get("name", element_id)
	var el_desc : String = el.get("description", "")
	var el_curio: String = el.get("curiosity", "")
	_dialog.show_dialog(ENCYCLOPEDIA,
		"%s (%s) — %s  ★ %s" % [el_name, element_id, el_desc, el_curio])

func _on_lava_barrier_hit(area: Node) -> void:
	if _barrier_dissolved:
		return
	if area.get("compound_id") != "H2O":
		_dialog.show_dialog(ELARA, "A lava resiste! Use H₂O (2×H + 1×O) para solidificá-la.")
		return
	_barrier_dissolved = true
	var tw := create_tween()
	tw.tween_property(_barrier_visual, "color", Color(0.2, 0.1, 0.4, 0.0), 0.8)
	tw.tween_callback(func() -> void:
		_barrier_wall.process_mode = Node.PROCESS_MODE_DISABLED
		_barrier_visual.visible = false
		_dialog.show_dialog(ELARA, "A lava solidificou em Obsidiana! Zona 2 aberta!"))

func _on_lava_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_respawn()

func _on_enemy_died(_enemy: Node) -> void:
	_enemies_killed += 1
	if not _enemy_dialog_done:
		_enemy_dialog_done = true
		_dialog.show_dialog(ELARA,
			"H₂O resfria e endurece a lava — reação endotérmica!")
	else:
		_dialog.show_dialog(ELARA,
			"%d/%d Golems eliminados!" % [_enemies_killed, TOTAL_ENEMIES])
	if _enemies_killed >= TOTAL_ENEMIES:
		_spawn_boss_portal()

func _spawn_boss_portal() -> void:
	await get_tree().create_timer(1.2).timeout
	_dialog.show_dialog(ELARA,
		"Todos os Golems eliminados! Um portal surgiu na Arena — enfrente o Golem de Lava!")
	_boss_portal = BossPortal.new()
	_boss_portal.position = Vector2(2200, 320)
	_boss_portal.player_entered.connect(_on_portal_entered)
	add_child(_boss_portal)

func _on_portal_entered() -> void:
	if _boss_started:
		return
	_boss_started = true
	if _boss_portal:
		_boss_portal.queue_free()
	_boss.show_battle("golem")
	_boss.battle_finished.connect(_on_boss_finished, CONNECT_ONE_SHOT)

func _on_sala_alta_fog_entered(body: Node2D) -> void:
	if _fog_cleared or not body.is_in_group("player"):
		return
	_fog_cleared = true
	var tw := create_tween()
	tw.tween_property(_fog, "color", Color(0, 0, 0, 0), 1.2)
	get_tree().create_timer(0.4).timeout.connect(func() -> void:
		_dialog.show_dialog(ELARA,
			"A Sala Alta! O (Oxigênio) está aqui — colete e desça para criar H₂O!"))

func _on_boss_finished(won: bool) -> void:
	if won:
		_dialog.queue_dialogs([
			[ELARA, "Incrível! H₂O solidificou a lava — resfriamento endotérmico em ação!"],
			[ELARA, "A Caldeira está vencida! O Complexo Subaquático aguarda... (em desenvolvimento)"],
		])
		GameState.complete_level(2)
		await _dialog.dialog_queue_finished
		_fade.visible = true
		var tw := create_tween()
		tw.tween_property(_fade, "color", Color(0, 0, 0, 1), 1.2)
		await tw.finished
		get_tree().change_scene_to_file("res://scenes/levels/level_03.tscn")
	else:
		_dialog.show_dialog(ELARA,
			"O Golem resistiu! Certifique-se de ter H₂O (2×H + 1×O) equipado.")
