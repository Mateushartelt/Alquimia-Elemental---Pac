extends Node2D
## TutorialRoom — Laboratório de Emergência.
## Sala isolada onde o jogador aprende a coletar elementos e criar H₂O
## antes de retornar ao Level 01 para apagar a Parede de Fogo.

const ELARA        := "Mestra Elara"
const ENCYCLOPEDIA := "Enciclopédia"

@onready var _dialog  : DialogBox     = $DialogBox
@onready var _hints   : TutorialHints = $TutorialHints
@onready var _alchemy : AlchemyPanel  = $AlchemyPanel

var _tutorial_h2o_triggered := false
var _alchemy_done            := false
var _h2o_done                := false
var _seen_elements : Array[String] = []

func _ready() -> void:
	# Limpa inventário para garantir tutorial limpo
	GameState.collected_elements.clear()
	GameState.active_compound = ""

	get_tree().create_timer(0.5).timeout.connect(_show_intro)
	GameState.element_collected.connect(_on_element_collected)
	GameState.compound_created.connect(_on_compound_created)
	_alchemy.panel_opened.connect(_on_alchemy_open)
	_dialog.dialog_queue_finished.connect(_on_dialog_closed)
	$ReturnDoor.body_entered.connect(_on_return_door_entered)

func _show_intro() -> void:
	_dialog.queue_dialogs([
		[ELARA, "Este é o Módulo de Síntese de Emergência — intacto após a explosão!"],
		[ELARA, "Colete os elementos H e O nos dispensadores aqui dentro e crie H₂O para apagar o fogo lá fora!"],
	])

func _on_element_collected(element_id: String, _amt: int) -> void:
	if element_id not in _seen_elements:
		_seen_elements.append(element_id)
		var el       := ElementDatabase.get_element(element_id)
		var el_name  : String = el.get("name", element_id)
		var el_desc  : String = el.get("description", "")
		var el_curio : String = el.get("curiosity", "")
		_dialog.show_dialog(ENCYCLOPEDIA,
			"%s (%s) — %s  ★ %s" % [el_name, element_id, el_desc, el_curio])

	if not _tutorial_h2o_triggered:
		var h : int = GameState.collected_elements.get("H", 0)
		var o : int = GameState.collected_elements.get("O", 0)
		if h >= 2 and o >= 1:
			_tutorial_h2o_triggered = true
			_dialog.show_dialog(ELARA,
				"Você tem H×2 e O×1 — os ingredientes da ÁGUA (H₂O)! Abra o Painel de Alquimia (Q) para combiná-los!")

func _on_dialog_closed() -> void:
	if _tutorial_h2o_triggered and not _alchemy_done:
		_alchemy.tutorial_unlock = true
		_hints.show_hint("Q — Abrir o Painel de Alquimia e misture seus elementos!")
		get_tree().paused = true

func _on_alchemy_open() -> void:
	_alchemy_done = true
	_hints.hide_hint()
	if _tutorial_h2o_triggered and not _h2o_done:
		_alchemy.start_h2o_tutorial()

func _on_compound_created(compound_id: String) -> void:
	if compound_id == "H2O" and not _h2o_done:
		_h2o_done = true
		_alchemy.panel_unlocked = true
		_dialog.show_dialog(ELARA,
			"Perfeito! H₂O criado! Agora volte pelo portal — atire no Fogo (J) para abrir o corredor!")
		$DoorVisual.color = Color(0.1, 1.0, 0.4, 0.9)

func _on_return_door_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not _h2o_done:
		_dialog.show_dialog(ELARA,
			"Crie H₂O primeiro! Colete H×2 e O×1 e abra o Painel de Alquimia (Q).")
		return
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")
