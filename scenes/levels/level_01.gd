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
@onready var _fire_wall    : Node2D        = $FireWall
@onready var _door_in      : Area2D        = $DoorIn
@onready var _cam          : Camera2D      = $Player/Camera2D

var _respawning             := false
var _h2o_dialog_done   := false
var _enemy_dialog_done := false
var _enemy_kill_count  := 0
var _special_hint_shown := false
var _fire_cleared        := false
var _came_from_tutorial  := false
var _shaft_fog_cleared   := false
var _shaft_b_fog_cleared := false
var _cave_fog_cleared    := false
var _cave_exited_once    := false
var _cinematic_done      := false
var _portal_hint_done    := false
var _in_tunnel           := false
var _zoom_tween          : Tween = null
var _cam_look_x          := 0.0
var _portal_exploded           := false
var _hub_invaded               := false
var _entered_tunnel_after_fire := false
const SLIME_SCENE = preload("res://scenes/enemies/slime_sodio.tscn")

# Fire propagation
const FIRE_SPREAD_INTERVAL := 3.5    # segundos entre cada avanço do fogo
const FIRE_STOP_X          := 450.0   # não passa do portal (esquerda)
const FIRE_STOP_RIGHT_X    := 1750.0  # não passa dos inimigos (direita)
const FIRE_SEG_W           := 48
const FIRE_ORIGIN_X        := 1352.0   # = 1400 - FIRE_SEG_W
var _fire_timer       : float = 0.0
var _fire_dmg_timer   : float = 0.0
var _fire_segments    : Array = []
var _fire_occupied    : Dictionary = {}   # float(x) → true, posições com fogo ativo
var _fire_alert_shown    := false
var _player_fire_count   : int = 0

# Tutorial state
var _seen_elements          : Array[String] = []
var _moved_done             := false
var _alchemy_done           := false
var _attack_done            := false
var _tutorial_h2o_triggered := false

func _ready() -> void:
	$HUD.visible = true
	_make_debug_label()
	_cam.limit_left                 = 800
	_cam.limit_right                = int(FIRE_ORIGIN_X) + FIRE_SEG_W
	_cam.limit_top                  = 80
	_cam.limit_bottom               = 400
	_cam.zoom                       = Vector2(3, 3)
	_cam.drag_horizontal_enabled    = false   # POV fixo: sem drag acumulado
	_cam.position_smoothing_enabled = false   # POV fixo: sem lag de smoothing
	if "H2O" in GameState.discovered_compounds:
		_came_from_tutorial = true
		_cinematic_done     = true
		_h2o_dialog_done    = true
		_portal_hint_done   = true
		# Spawn próximo ao portal no túnel (não no hub)
		player.global_position = Vector2(300, 310)
		_in_tunnel = true
		_cam.limit_left   = 226
		_cam.limit_top    = -500
		_cam.limit_bottom = 680
		_cam.zoom         = Vector2(4, 4)
		# Spawna inimigos no túnel para o player treinar a arma de água
		_spawn_tutorial_enemies()
		if is_instance_valid(_door_in):
			_door_in.set_deferred("monitoring", false)
		# Restaurar segmentos de fogo que existiam antes de ir ao módulo de síntese
		if GameState.fire_next_x >= 0.0:
			_fire_alert_shown = true
			var target_x := GameState.fire_next_x  # salva antes do loop alterar
			var left_x := FIRE_ORIGIN_X
			var right_x := FIRE_ORIGIN_X + float(FIRE_SEG_W)
			_spawn_fire_segment(left_x)
			_spawn_fire_segment(right_x)
			while left_x - float(FIRE_SEG_W) >= target_x:
				left_x -= float(FIRE_SEG_W)
				right_x += float(FIRE_SEG_W)
				_spawn_fire_segment(left_x)
				_spawn_fire_segment(right_x)
		get_tree().create_timer(0.4).timeout.connect(func() -> void:
			_dialog.show_dialog(ELARA,
				"H₂O pronto! Equipe o composto (Scroll do mouse) e atire (J) na Parede de Fogo!"))
	else:
		player.input_locked = true
		get_tree().create_timer(1.0).timeout.connect(_show_intro)
	GameState.compound_created.connect(_on_compound_created)
	GameState.checkpoint_reached.connect(_on_checkpoint_reached)
	GameState.element_collected.connect(_on_element_first_collected)
	_alchemy.panel_opened.connect(_on_first_alchemy_open)
	_dialog.dialog_queue_finished.connect(_on_any_dialog_closed)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.connect("died", _on_enemy_died)

var _debug_zoom : Label

func _make_debug_label() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_debug_zoom = Label.new()
	_debug_zoom.position = Vector2(8, 8)
	_debug_zoom.add_theme_font_size_override("font_size", 16)
	layer.add_child(_debug_zoom)

func _process(delta: float) -> void:
	_debug_zoom.text = "zoom: %.0f  %s" % [_cam.zoom.x, "TUNEL" if _in_tunnel else "HUB"]
	# Pulso suave nos segmentos de fogo (roda mesmo pausado)
	var t := Time.get_ticks_msec() * 0.001
	for seg in _fire_segments:
		if is_instance_valid(seg):
			var ph := float(seg.get_meta("phase", 0.0))
			seg.modulate.a = 0.85 + sin(t * 2.5 + ph) * 0.15
	if get_tree().paused:
		return
	# Propagação do fogo
	if not _fire_cleared:
		_fire_timer += delta
		if _fire_timer >= FIRE_SPREAD_INTERVAL:
			_fire_timer = 0.0
			# Coleta candidatos adjacentes a fogos existentes
			var gaps  : Array[float] = []
			var edges : Array[float] = []
			var seen  : Dictionary  = {}
			for x_var in _fire_occupied:
				var x := float(x_var)
				for dx in [-float(FIRE_SEG_W), float(FIRE_SEG_W)]:
					var nx: float = x + float(dx)
					if nx < FIRE_STOP_X or nx > FIRE_STOP_RIGHT_X or _fire_occupied.has(nx) or seen.has(nx):
						continue
					seen[nx] = true
					var has_l := _fire_occupied.has(nx - float(FIRE_SEG_W))
					var has_r := _fire_occupied.has(nx + float(FIRE_SEG_W))
					if has_l and has_r:
						gaps.append(nx)   # lacuna: fogo dos dois lados
					else:
						edges.append(nx)  # fronteira normal
			if gaps.size() > 0:
				for gx in gaps:
					_spawn_fire_segment(gx)   # preenche todas lacunas
			elif edges.size() > 0:
				edges.sort()
				_spawn_fire_segment(edges[0])          # expande esquerda
				if edges.size() > 1:
					_spawn_fire_segment(edges[-1])     # expande direita
		_fire_dmg_timer += delta
		if _player_fire_count > 0:
			player.velocity.x = clamp(player.velocity.x, -50.0, 50.0)
		if _fire_dmg_timer >= 0.5:
			_fire_dmg_timer = 0.0
			for seg in _fire_segments:
				if not is_instance_valid(seg):
					continue
				var area: Area2D = seg.get_node_or_null("FireDmg") as Area2D
				if is_instance_valid(area):
					for body in area.get_overlapping_bodies():
						if body.is_in_group("player"):
							GameState.take_damage(_fire_damage())
	# Ativa inimigos por proximidade após o fogo ser apagado
	if _fire_cleared:
		for enemy in $Enemies.get_children():
			if not enemy.visible and is_instance_valid(enemy):
				if enemy.global_position.distance_to(player.global_position) < 300.0:
					enemy.visible = true
					enemy.process_mode = Node.PROCESS_MODE_INHERIT
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
	# Zoom + limites por sala (sempre ativo)
	if player.global_position.x > 820.0 and _in_tunnel:
		_in_tunnel = false
		_cam.limit_left   = 800   # hub: travado no step wall
		_cam.limit_top    = 80
		_cam.limit_bottom = 400
		_set_zoom(Vector2(3, 3), 0.5)
		if _fire_cleared and _entered_tunnel_after_fire and not _hub_invaded:
			_hub_invaded = true
			_spawn_hub_invasion()
	elif player.global_position.x <= 780.0 and not _in_tunnel:
		_in_tunnel = true
		if _fire_cleared:
			_entered_tunnel_after_fire = true
		_cam.limit_left   = 0 if _portal_exploded else 226  # para no portal até ele explodir
		_cam.limit_top    = -500
		_cam.limit_bottom = 680
		_set_zoom(Vector2(4, 4), 0.5)
	# Lookahead horizontal no túnel
	var target_look_x := 0.0
	if _in_tunnel:
		if player.velocity.x < -5.0 and _portal_exploded:
			target_look_x = -80.0  # esquerda só após portal explodir
		elif player.velocity.x > 5.0:
			target_look_x = 80.0
	_cam_look_x = lerp(_cam_look_x, target_look_x, delta * 3.0)
	_cam.offset = Vector2(_cam_look_x, -20)

func _cine_begin() -> void:
	if _zoom_tween:
		_zoom_tween.kill()
		_zoom_tween = null

func _cine_end() -> void:
	if _zoom_tween:
		_zoom_tween.kill()
		_zoom_tween = null
	_cam_look_x       = 0.0
	_cam.zoom         = Vector2(4, 4) if _in_tunnel else Vector2(3, 3)
	_cam.limit_left   = (0 if _portal_exploded else 226) if _in_tunnel else 800
	_cam.limit_top    = -500 if _in_tunnel else 80
	_cam.limit_bottom = 680  if _in_tunnel else 400
	_cam.offset       = Vector2(0, -20)

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
	_player_fire_count = 0
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
	_cine_begin()
	var offset_to_fire := 1400.0 - player.global_position.x

	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	process_mode        = Node.PROCESS_MODE_ALWAYS
	get_tree().paused   = true

	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_cam, "offset", Vector2(offset_to_fire, -20), 2.0)
	tw.tween_interval(0.30)
	tw.tween_callback(func() -> void:
		_spawn_fire_segment(FIRE_ORIGIN_X)
		_spawn_fire_segment(FIRE_ORIGIN_X + float(FIRE_SEG_W)))
	tw.tween_interval(0.65)
	tw.tween_callback(func() -> void:
		_spawn_fire_segment(FIRE_ORIGIN_X - float(FIRE_SEG_W))
		_spawn_fire_segment(FIRE_ORIGIN_X + 2.0 * float(FIRE_SEG_W)))
	tw.tween_interval(0.55)
	tw.tween_property(_cam, "offset", Vector2(0, -20), 2.0)
	await tw.finished

	get_tree().paused    = false
	process_mode         = Node.PROCESS_MODE_INHERIT
	player.process_mode  = Node.PROCESS_MODE_INHERIT
	player.input_locked  = false
	_cine_end()
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
		_hints.show_hint("J / Botão Esquerdo — Atirar composto")

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
			_hints.show_hint("Pressione  Q  para abrir o Painel de Alquimia!")
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
	_enemy_kill_count += 1
	if not _enemy_dialog_done:
		_enemy_dialog_done = true
		_dialog.show_dialog(ELARA,
			"Muito bem! Fogo é derrotado pela água — reação de extinção térmica!")
	if _enemy_kill_count >= 2 and not _special_hint_shown:
		_special_hint_shown = true
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			_hints.show_hint("E — Especial  (barra cheia)"))

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

func _on_cave_fog_exited(body: Node2D) -> void:
	if not body.is_in_group("player") or _cave_exited_once:
		return
	_cave_exited_once = true
	if _fire_cleared:
		_reveal_corridor_pickups()

func _reveal_corridor_pickups() -> void:
	for pickup in $Pickups.get_children():
		if is_instance_valid(pickup):
			pickup.visible = true

func _on_door_in_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/levels/tutorial_room.tscn")

func _on_fire_extinguished() -> void:
	_fire_cleared = true
	GameState.fire_next_x = -1.0  # fogo extinto, não restaurar na próxima visita
	for seg in _fire_segments:
		if is_instance_valid(seg):
			seg.queue_free()
	_fire_segments.clear()
	_fire_occupied.clear()
	# Revela pickups só se o jogador já saiu da caverna
	if _cave_exited_once:
		_reveal_corridor_pickups()
	# Não toca no zoom nem em _in_tunnel — _process continua gerindo as transições
	_dialog.queue_dialogs([
		[ELARA, "Excelente! H₂O absorveu o calor e extinguiu o fogo — reação endotérmica!"],
		[ELARA, "O corredor está livre! Explore também o lado esquerdo — há elementos escondidos na cave!"],
	])
	await _dialog.dialog_queue_finished
	_run_portal_explosion()

func _run_portal_explosion() -> void:
	_portal_exploded = true
	_cam.limit_left  = 0
	_cam.limit_right = 3200
	_cam.zoom        = Vector2(3, 3)

	_cine_begin()
	var offset_to_portal := 250.0 - player.global_position.x

	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	process_mode        = Node.PROCESS_MODE_ALWAYS
	get_tree().paused   = true

	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_cam, "offset", Vector2(offset_to_portal, -20), 1.5)
	await tw.finished

	if is_instance_valid(_door_in):
		_door_in.queue_free()

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

	var tw2 := create_tween()
	tw2.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(_cam, "offset", Vector2(0, -20), 1.0)
	await tw2.finished

	get_tree().paused   = false
	process_mode        = Node.PROCESS_MODE_INHERIT
	player.process_mode = Node.PROCESS_MODE_INHERIT
	_cine_end()

func _fire_damage() -> int:
	return 25

func _spawn_fire_segment(at_x: float) -> void:
	var seg := Node2D.new()
	seg.set_meta("phase", randf() * TAU)
	seg.add_child(_create_fire_particles(FIRE_SEG_W))

	var area := Area2D.new()
	area.name            = "FireDmg"
	area.collision_layer = 32
	area.collision_mask  = 1 | 16  # player + projectiles
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size     = Vector2(FIRE_SEG_W, 256)
	cs.position = Vector2(FIRE_SEG_W / 2.0, 128)
	cs.shape    = rs
	area.add_child(cs)
	seg.add_child(area)
	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			_player_fire_count += 1
		if body.has_method("receive_damage"):
			body.receive_damage(_fire_damage()))
	area.body_exited.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			_player_fire_count = max(0, _player_fire_count - 1))
	area.area_entered.connect(func(proj_area: Area2D) -> void:
		if proj_area.get("compound_id") == "H2O":
			_extinguish_segment(seg)
			proj_area.queue_free())

	seg.position = Vector2(at_x, 112)
	add_child(seg)
	_fire_segments.append(seg)
	_fire_occupied[at_x] = true
	# Limita câmera ao edge direito do fogo
	var right_edge := int(at_x) + FIRE_SEG_W
	if right_edge > _cam.limit_right:
		_cam.limit_right = right_edge
	# Persiste fronteira esquerda para restaurar após módulo de síntese
	var keys := _fire_occupied.keys()
	keys.sort()
	GameState.fire_next_x = float(keys[0])

	if not _fire_alert_shown and not get_tree().paused:
		_fire_alert_shown = true
		_dialog.show_dialog(ELARA, "O fogo está se espalhando! Corra!")

func _extinguish_segment(seg: Node2D) -> void:
	if not is_instance_valid(seg):
		return
	_fire_occupied.erase(seg.position.x)
	_fire_segments.erase(seg)
	_fire_timer = 0.0   # reseta o intervalo — dá mais tempo antes da próxima expansão
	_player_fire_count = 0
	for child in seg.get_children():
		if child is Area2D:
			for cs2 in child.get_children():
				if cs2 is CollisionShape2D:
					cs2.set_deferred("disabled", true)
	var tw := seg.create_tween()
	tw.tween_property(seg, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5)
	tw.tween_callback(seg.queue_free)
	if _fire_segments.is_empty() and not _fire_cleared:
		_on_fire_extinguished()

func _create_fire_particles(w: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting              = true
	p.amount                = 50
	p.lifetime              = 1.5
	p.randomness            = 0.5
	p.preprocess            = 1.0
	p.local_coords          = true
	p.emission_shape        = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(float(w) * 0.5, 3.0)
	p.position              = Vector2(float(w) * 0.5, 256.0)
	p.direction             = Vector2(0.0, -1.0)
	p.spread                = 22.0
	p.gravity               = Vector2(0.0, 0.0)
	p.initial_velocity_min  = 80.0
	p.initial_velocity_max  = 180.0
	p.scale_amount_min      = 3.0
	p.scale_amount_max      = 7.0
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.1, 1.0))
	grad.set_color(1, Color(0.75, 0.05, 0.0, 0.0))
	p.color_ramp = grad
	return p

func _spawn_tutorial_enemies() -> void:
	for pos: Vector2 in [Vector2(450, 310), Vector2(620, 310)]:
		var slime := SLIME_SCENE.instantiate()
		slime.global_position = pos
		add_child(slime)
		slime.connect("died", _on_enemy_died)

func _spawn_hub_invasion() -> void:
	$Pickups/Hub_Na1.visible = true
	$Pickups/Hub_Cl1.visible = true
	$Pickups/Hub_Na2.visible = true
	for pos: Vector2 in [Vector2(950, 330), Vector2(1100, 330), Vector2(1250, 330)]:
		var slime := SLIME_SCENE.instantiate()
		slime.global_position = pos
		add_child(slime)
		slime.connect("died", _on_enemy_died)
	_dialog.show_dialog(ELARA,
		"Kael! Criaturas invadiram o hub enquanto você explorava — elimine-as!")

func _on_shaft_b_fog_entered(body: Node2D) -> void:
	if _shaft_b_fog_cleared or not body.is_in_group("player"):
		return
	_shaft_b_fog_cleared = true
	var tw := create_tween()
	tw.tween_property($DarkAreas/ShaftFogB, "color", Color(0, 0, 0, 0), 0.8)


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
