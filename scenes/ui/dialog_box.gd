class_name DialogBox
extends CanvasLayer
## DialogBox — Fila de diálogos com efeito de digitação.
## Não pausa o jogo. Avança com ESPAÇO / ENTER / clique esquerdo.

signal dialog_queue_finished

const CHARS_PER_SEC := 60.0

var _queue: Array = []          # Array de {speaker, text}
var _is_typing  := false
var _full_text  := ""
var _shown_chars: float = 0.0
var _hint_timer : float = 0.0

@onready var _panel       : PanelContainer = $Panel
@onready var _speaker_lbl : Label          = $Panel/VBox/SpeakerLabel
@onready var _text_lbl    : RichTextLabel  = $Panel/VBox/TextLabel
@onready var _hint_lbl    : Label          = $Panel/VBox/HintLabel

func _ready() -> void:
	layer = 15
	visible = false
	set_process(false)

func _process(delta: float) -> void:
	if _is_typing:
		_shown_chars += CHARS_PER_SEC * delta
		var n := mini(int(_shown_chars), len(_full_text))
		_text_lbl.visible_characters = n
		if n >= len(_full_text):
			_is_typing = false
			_hint_lbl.visible = true
	else:
		_hint_timer += delta
		_hint_lbl.modulate.a = 0.5 + 0.5 * sin(_hint_timer * 4.0)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var advance: bool = event.is_action_pressed("ui_accept") \
	or (event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed)
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if _is_typing:
		_shown_chars = len(_full_text)
		_text_lbl.visible_characters = len(_full_text)
		_is_typing = false
		_hint_lbl.visible = true
	else:
		_next()

## Adiciona várias falas de uma vez. dialogs = [[speaker, text], ...]
func queue_dialogs(dialogs: Array) -> void:
	for d in dialogs:
		_queue.append({speaker = d[0], text = d[1]})
	if not visible:
		_next()

## Atalho para uma única fala
func show_dialog(speaker: String, text: String) -> void:
	queue_dialogs([[speaker, text]])

func _next() -> void:
	if _queue.is_empty():
		visible = false
		set_process(false)
		dialog_queue_finished.emit()
		return
	var entry: Dictionary = _queue.pop_front()
	_speaker_lbl.text  = entry.get("speaker", "")
	_full_text         = entry.get("text", "")
	_text_lbl.text     = _full_text
	_text_lbl.visible_characters = 0
	_shown_chars = 0.0
	_is_typing   = true
	_hint_lbl.visible = false
	_hint_timer  = 0.0
	visible = true
	set_process(true)
