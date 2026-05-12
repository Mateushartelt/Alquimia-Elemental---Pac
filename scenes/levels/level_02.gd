extends Node2D
## Level02 — Caldeira Vulcânica.
## Introduz S (Enxofre) e Si (Silício). Boss: Golem de Lava (fraco a H₂O e CO₂).

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
	# Fade de entrada (preto → transparente)
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
	# Troca de zona: hub (y > -80) ↔ sala alta (y < -80)
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
		[ELARA, "A Caldeira Vulcânica! Calor intenso e enxofre dominam este lugar."],
		[ELARA, "Colete S (Enxofre) e O (Oxigênio) — formam SO₂, o gás da chuva ácida de Vênus!"],
		[ELARA, "O shaft estreito à esquerda leva a uma área mais alta. Wall Jump para escalar!"],
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

func _on_enemy_died(_enemy: Node) -> void:
	if not _enemy_dialog_done:
		_enemy_dialog_done = true
		_dialog.show_dialog(ELARA,
			"H₂O derrete rocha vulcânica — reação endotérmica. CO₂ sufoca as chamas internas!")

func _on_sala_alta_fog_entered(body: Node2D) -> void:
	if _fog_cleared or not body.is_in_group("player"):
		return
	_fog_cleared = true
	var tw := create_tween()
	tw.tween_property(_fog, "color", Color(0, 0, 0, 0), 1.2)
	get_tree().create_timer(0.4).timeout.connect(func() -> void:
		_dialog.show_dialog(ELARA,
			"A Cratera! O Golem de Lava habita aqui — prepare H₂O ou CO₂ para derrotá-lo!"))

func _on_boss_trigger_entered(body: Node2D) -> void:
	if _boss_started or not body.is_in_group("player"):
		return
	_boss_started = true
	$BossTrigger.monitoring = false
	_boss.show_battle("golem")
	_boss.battle_finished.connect(_on_boss_finished, CONNECT_ONE_SHOT)

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
		# Level 03 ainda não existe — recarrega Level 02 como placeholder
		get_tree().change_scene_to_file("res://scenes/levels/level_02.tscn")
	else:
		_dialog.show_dialog(ELARA,
			"O Golem foi forte demais... Colete mais O para H₂O (2H+1O) ou CO₂ (1C+2O)!")
