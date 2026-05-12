extends Node2D
## Level03 — Complexo Subaquático Viral.
## Introduz C (Carbono) e Cl (Cloro). Boss: Vírus Mutante (fraco a Etanol e HCl).

const KILL_PLANE_Y  := 620.0
const SPAWN_POS     := Vector2(80, 300)
const ELARA         := "Mestra Elara"
const ENCYCLOPEDIA  := "Enciclopédia"

@onready var player   : Player       = $Player
@onready var _dialog  : DialogBox    = $DialogBox
@onready var _alchemy : AlchemyPanel = $AlchemyPanel
@onready var _boss    : BossBattle   = $BossBattle
@onready var _cam     : Camera2D     = $Player/Camera2D
@onready var _fog     : ColorRect    = $DarkAreas/SalaAltaFog
@onready var _fade    : ColorRect    = $FadeOverlay

var _respawning        := false
var _seen_elements     : Array[String] = []
var _fog_cleared       := false
var _boss_started      := false
var _in_sala_alta      := false
var _enemy_dialog_done := false
var _zoom_tween        : Tween = null

func _ready() -> void:
	_cam.zoom                       = Vector2(3, 3)
	_cam.limit_left                 = 0
	_cam.limit_top                  = 60
	_cam.limit_right                = 2400
	_cam.limit_bottom               = 450
	_cam.position_smoothing_enabled = true
	_cam.drag_horizontal_enabled    = true
	_fade.color   = Color(0, 0, 0, 1)
	_fade.visible = true
	var tw := create_tween()
	tw.tween_property(_fade, "color", Color(0, 0, 0, 0), 1.0)
	tw.tween_callback(func() -> void: _fade.visible = false)
	_alchemy.enable_fourth_slot()
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
		_cam.limit_top    = -400
		_cam.limit_right  = 1650
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
		[ELARA, "O Complexo Subaquático — contaminado por vírus mutantes!"],
		[ELARA, "Procure C (Carbono) e Cl (Cloro) espalhados pelo complexo."],
		[ELARA, "Combine C + H + H + O no painel de alquimia para criar Etanol!"],
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

func _on_enemy_died(_enemy: Node) -> void:
	if not _enemy_dialog_done:
		_enemy_dialog_done = true
		_dialog.show_dialog(ELARA,
			"Etanol a 70% desnatura proteínas virais! Água não mata vírus — eles adoram umidade.")

func _on_sala_alta_fog_entered(body: Node2D) -> void:
	if _fog_cleared or not body.is_in_group("player"):
		return
	_fog_cleared = true
	var tw := create_tween()
	tw.tween_property(_fog, "color", Color(0, 0, 0, 0), 1.2)
	get_tree().create_timer(0.4).timeout.connect(func() -> void:
		_dialog.show_dialog(ELARA,
			"O Núcleo de Controle! O Vírus Mutante habita aqui — use Etanol (3× dano) ou HCl!"))

func _on_boss_trigger_entered(body: Node2D) -> void:
	if _boss_started or not body.is_in_group("player"):
		return
	_boss_started = true
	$BossTrigger.monitoring = false
	_boss.show_battle("virus")
	_boss.battle_finished.connect(_on_boss_finished, CONNECT_ONE_SHOT)

func _on_boss_finished(won: bool) -> void:
	if won:
		_dialog.queue_dialogs([
			[ELARA, "Incrível! Etanol desnaturou as proteínas do Vírus Mutante!"],
			[ELARA, "Parabéns! Você completou o Complexo Subaquático!"],
		])
		GameState.complete_level(3)
		await _dialog.dialog_queue_finished
		_fade.visible = true
		var tw := create_tween()
		tw.tween_property(_fade, "color", Color(0, 0, 0, 1), 1.2)
		await tw.finished
		get_tree().change_scene_to_file("res://scenes/levels/level_03.tscn")
	else:
		_dialog.show_dialog(ELARA,
			"O vírus foi forte demais... Crie Etanol (C+H+H+O) — supera qualquer composto contra vírus!")
