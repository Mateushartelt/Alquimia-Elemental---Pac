class_name QuizModal
extends CanvasLayer
## QuizModal — Quiz de múltipla escolha exibido após a primeira coleta de elemento.
## Toda a UI é construída em código (_build_ui). Chame show_quiz(element_id) para abrir.

signal quiz_closed

var _correct_index : int = -1

# Referências criadas em _build_ui
var _symbol_lbl   : Label
var _symbol_bg    : ColorRect
var _name_lbl     : Label
var _question_lbl : Label
var _opts_box     : VBoxContainer
var _feedback_lbl : Label
var _continue_btn : Button

func _ready() -> void:
	layer        = 16
	visible      = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

# ── Construção da UI ──────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Fundo escuro semi-transparente
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.78)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Painel central
	var panel := ColorRect.new()
	panel.color = Color(0.07, 0.06, 0.14, 0.97)
	panel.offset_left   = 340.0
	panel.offset_top    = 110.0
	panel.offset_right  = 940.0
	panel.offset_bottom = 610.0
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   24)
	margin.add_theme_constant_override("margin_right",  24)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# ── Cabeçalho: ícone do elemento + nome ──
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	vbox.add_child(header)

	_symbol_bg = ColorRect.new()
	_symbol_bg.custom_minimum_size = Vector2(72, 72)
	_symbol_bg.color = Color(0.3, 0.3, 0.5)
	header.add_child(_symbol_bg)

	_symbol_lbl = Label.new()
	_symbol_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_symbol_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_symbol_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_symbol_lbl.add_theme_font_size_override("font_size", 36)
	_symbol_bg.add_child(_symbol_lbl)

	var header_right := VBoxContainer.new()
	header_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_right.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(header_right)

	var quiz_tag := Label.new()
	quiz_tag.text = "QUIZ"
	quiz_tag.add_theme_font_size_override("font_size", 18)
	quiz_tag.add_theme_color_override("font_color", Color(0.6, 0.6, 0.75))
	header_right.add_child(quiz_tag)

	_name_lbl = Label.new()
	_name_lbl.add_theme_font_size_override("font_size", 28)
	_name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	header_right.add_child(_name_lbl)

	# Separador
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Pergunta
	_question_lbl = Label.new()
	_question_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question_lbl.add_theme_font_size_override("font_size", 24)
	_question_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
	vbox.add_child(_question_lbl)

	# Opções
	_opts_box = VBoxContainer.new()
	_opts_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_opts_box)

	# Feedback
	_feedback_lbl = Label.new()
	_feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_lbl.add_theme_font_size_override("font_size", 22)
	_feedback_lbl.visible = false
	vbox.add_child(_feedback_lbl)

	# Botão continuar
	_continue_btn = Button.new()
	_continue_btn.text = "Continuar"
	_continue_btn.add_theme_font_size_override("font_size", 26)
	_continue_btn.visible = false
	_continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(_continue_btn)

# ── API pública ───────────────────────────────────────────────────────────────
func show_quiz(element_id: String) -> void:
	var el    := ElementDatabase.get_element(element_id)
	var quiz  : Dictionary = el.get("quiz", {})

	# Sem quiz configurado: fecha imediatamente
	if el.is_empty() or quiz.is_empty():
		quiz_closed.emit()
		return

	# Preenche o cabeçalho
	_symbol_lbl.text = el.get("symbol", element_id)
	_name_lbl.text   = el.get("name", element_id)
	var el_color := Color(el.get("color", "#888888"))
	_symbol_bg.color = el_color.darkened(0.3)

	# Pergunta
	_question_lbl.text = quiz.get("question", "")
	_correct_index     = int(quiz.get("correct", 0))

	# Limpa opções anteriores
	for child in _opts_box.get_children():
		child.queue_free()

	# Cria botões de opção
	var options : Array = quiz.get("options", [])
	for i in options.size():
		var btn := Button.new()
		btn.text = options[i]
		btn.add_theme_font_size_override("font_size", 22)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_option_pressed.bind(i, btn))
		_opts_box.add_child(btn)

	_feedback_lbl.visible = false
	_continue_btn.visible = false
	visible = true
	get_tree().paused = true

# ── Callbacks internos ────────────────────────────────────────────────────────
func _on_option_pressed(index: int, btn: Button) -> void:
	# Trava todos os botões
	for child in _opts_box.get_children():
		(child as Button).disabled = true

	var opts := _opts_box.get_children()
	if index == _correct_index:
		btn.modulate = Color(0.3, 1.0, 0.4)
		_feedback_lbl.text = "Correto! Muito bem!"
		_feedback_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	else:
		btn.modulate = Color(1.0, 0.3, 0.3)
		(opts[_correct_index] as Button).modulate = Color(0.3, 1.0, 0.4)
		_feedback_lbl.text = "Errado! A resposta correta está marcada em verde."
		_feedback_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	_feedback_lbl.visible = true
	_continue_btn.visible = true

func _on_continue_pressed() -> void:
	get_tree().paused = false
	visible = false
	quiz_closed.emit()
