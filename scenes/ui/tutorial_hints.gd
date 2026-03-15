class_name TutorialHints
extends CanvasLayer
## TutorialHints — Banner contextual de dicas que aparece/some com fade.

@onready var _panel : ColorRect = $HintPanel
@onready var _label : Label     = $HintPanel/HintLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 6
	_panel.visible = false

var _hide_tween: Tween

func show_hint(text: String) -> void:
	if _hide_tween:
		_hide_tween.kill()
		_hide_tween = null
	_label.text = text
	_panel.modulate.a = 1.0
	_panel.visible = true

func hide_hint() -> void:
	if not _panel.visible:
		return
	_hide_tween = create_tween()
	_hide_tween.tween_property(_panel, "modulate:a", 0.0, 0.3)
	_hide_tween.tween_callback(_panel.hide)
