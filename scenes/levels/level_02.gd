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
@onready var _barrier_visual  : ColorRect    = $LavaBarrier/Visual
@onready var _barrier_wall    : StaticBody2D = $LavaBarrier/Wall
@onready var _barrier2_visual : ColorRect    = $LavaBarrier2/Visual
@onready var _barrier2_wall   : StaticBody2D = $LavaBarrier2/Wall

const TOTAL_ENEMIES := 4
const ARENA_X       := 1440.0   # x ≥ isto = arena do boss
const ARENA_GUARDS  := 2        # golems que travam o portão da arena

var _arena_kills       := 0
var _respawning        := false
var _seen_elements     : Array[String] = []
var _fog_cleared       := false
var _boss_started      := false
var _in_sala_alta      := false
var _enemy_dialog_done := false
var _barrier_dissolved  := false
var _barrier2_dissolved := false
var _zoom_tween        : Tween = null
var _enemies_killed    := 0
var _boss_portal       : BossPortal = null

func _ready() -> void:
	# Snapshot da entrada da fase — estado-base do "Tente Novamente"
	if GameState.retry_snapshot.is_empty():
		GameState.save_retry_snapshot()
	_cam.zoom                       = Vector2(3, 3)
	_cam.limit_left                 = 0
	_cam.limit_top                  = 60
	_cam.limit_right                = 672   # Zona 1 — avança ao dissolver barreiras
	_cam.limit_bottom               = 450
	_cam.position_smoothing_enabled = true
	_cam.drag_horizontal_enabled    = true
	_setup_background()
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
	_boss.battle_finished.connect(_on_boss_finished)

func _process(_delta: float) -> void:
	if not _respawning and player.global_position.y > KILL_PLANE_Y:
		_respawn()
	_update_camera()

func _update_camera() -> void:
	var py      := player.global_position.y
	var px      := player.global_position.x
	var in_alta := py < -80.0

	if in_alta and not _in_sala_alta:
		_in_sala_alta = true
		_cam.drag_horizontal_enabled = false
		_set_zoom(Vector2(4, 4), 0.6)
	elif not in_alta and _in_sala_alta:
		_in_sala_alta = false
		_cam.drag_horizontal_enabled = true
		_set_zoom(Vector2(3, 3), 0.5)

	if in_alta:
		_cam.limit_left   = 0
		_cam.limit_top    = -380
		_cam.limit_right  = 704
		_cam.limit_bottom = -80
	elif py < 120.0 and px > 208.0 and px < 316.0:
		_cam.limit_left   = 0
		_cam.limit_top    = -160
		_cam.limit_right  = 2400
		_cam.limit_bottom = 450
	else:
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
		_cam.limit_right = 2400
		_dialog.show_dialog(ELARA, "A lava solidificou em Obsidiana! Zona 2 aberta!"))

func _on_lava_barrier2_hit(area: Node) -> void:
	if _barrier2_dissolved:
		return
	if area.get("compound_id") != "H2O":
		_dialog.show_dialog(ELARA, "A lava resiste novamente! H₂O (2×H + 1×O) para solidificá-la.")
		return
	_barrier2_dissolved = true
	var tw := create_tween()
	tw.tween_property(_barrier2_visual, "color", Color(0.2, 0.1, 0.4, 0.0), 0.8)
	tw.tween_callback(func() -> void:
		_barrier2_wall.process_mode = Node.PROCESS_MODE_DISABLED
		_barrier2_visual.visible = false
		_cam.limit_right = 2400
		_dialog.show_dialog(ELARA, "Obsidiana! A Arena está aberta — cuidado com o Golem de Lava!"))

func _on_lava_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _respawning:
		return
	_respawning = true
	GameState.take_damage(34)   # lava queima — 3 toques = morte
	player.global_position = SPAWN_POS
	player.reset_state()
	await get_tree().process_frame
	_respawning = false

func _on_enemy_died(enemy: Node) -> void:
	_enemies_killed += 1
	if not _enemy_dialog_done:
		_enemy_dialog_done = true
		_dialog.show_dialog(ELARA,
			"H₂O resfria e endurece a lava — reação endotérmica!")
	else:
		_dialog.show_dialog(ELARA,
			"%d/%d Golems eliminados!" % [_enemies_killed, TOTAL_ENEMIES])
	# Golem da arena (x ≥ ARENA_X) morto → conta pro portão
	var in_arena := enemy is Node2D and (enemy as Node2D).global_position.x >= ARENA_X
	if in_arena:
		_arena_kills += 1
		if _arena_kills >= ARENA_GUARDS:
			_open_arena_gate()
			_spawn_boss_portal()
		else:
			_dialog.show_dialog(ELARA,
				"Mais um guardião resta na arena! Elimine-o para liberar o portal.")

func _open_arena_gate() -> void:
	var gate := get_node_or_null("ArenaGate")
	if not gate:
		return
	var wall := gate.get_node_or_null("Wall")
	if wall:
		wall.process_mode = Node.PROCESS_MODE_DISABLED
	var vis := gate.get_node_or_null("Visual")
	if vis:
		var tw := create_tween()
		tw.tween_property(vis, "color", Color(0.2, 0.1, 0.4, 0.0), 0.8)
		tw.tween_callback(func() -> void: vis.visible = false)

func _spawn_boss_portal() -> void:
	if is_instance_valid(_boss_portal):
		return   # já existe
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(_boss_portal):
		return
	_dialog.show_dialog(ELARA,
		"Todos os Golems eliminados! Um portal surgiu na Arena — enfrente o Golem de Lava!")
	_boss_portal = BossPortal.new()
	var spawn := get_node_or_null("BossPortalSpawn") as Marker2D
	_boss_portal.position = spawn.position if spawn else Vector2(2200, 320)
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

func _setup_background() -> void:
	var bg_tex: Texture2D = load("res://scenes/world/assets/bg_cave.png")
	if not bg_tex:
		return

	# ParallaxBackground é CanvasLayer — usa 'layer' não 'z_index'
	var parallax := ParallaxBackground.new()
	parallax.layer = -10
	add_child(parallax)

	# Nível vai de y=-320 (Sala Alta) até y=450 = ~770px de altura total
	# bg_cave.png tem 941px de altura — estica para cobrir tudo
	var level_top    := -520.0
	var level_height := 1040.0   # cobre sala alta + hub + abaixo

	var layer := ParallaxLayer.new()
	layer.motion_scale     = Vector2(0.25, 0.15)
	layer.motion_mirroring = Vector2(bg_tex.get_width(), 0.0)
	parallax.add_child(layer)

	for i in 3:   # 3 cópias horizontais para cobrir nível largo (2400px)
		var tr := TextureRect.new()
		tr.texture      = bg_tex
		tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.size         = Vector2(bg_tex.get_width(), level_height)
		tr.position     = Vector2(i * bg_tex.get_width(), level_top)
		layer.add_child(tr)
