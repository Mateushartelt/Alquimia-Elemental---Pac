class_name PeriodicTable
extends CanvasLayer
## PeriodicTable — Tabela Periódica de Descobertas (tecla TAB).
## Abre/fecha com TAB. Mostra os elementos do jogo em suas posições reais.

const CELL_W := 52
const CELL_H := 62
const COLS   := 18
const ROWS   := 3  # Períodos 1–3 cobrem todos os 7 elementos atuais

var _is_open      := false
var _grid         : Control
var _progress_lbl : Label

func _ready() -> void:
	layer        = 20
	visible      = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	GameState.element_collected.connect(_on_state_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.physical_keycode == KEY_TAB:
			if get_tree().paused and not _is_open:
				return  # não abre enquanto outro modal está ativo
			_toggle()
			get_viewport().set_input_as_handled()
			return
	if _is_open and event.is_action_pressed("ui_cancel") and not event.is_echo():
		_close()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	if _is_open: _close()
	else:        _open()

func _open() -> void:
	_is_open = true
	visible  = true
	get_tree().paused = true
	_refresh()

func _close() -> void:
	_is_open = false
	visible  = false
	get_tree().paused = false

# ── Construção da UI (chamada uma vez em _ready) ───────────────────────────────
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.09, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   60)
	margin.add_theme_constant_override("margin_right",  60)
	margin.add_theme_constant_override("margin_top",    40)
	margin.add_theme_constant_override("margin_bottom", 30)
	bg.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Tabela Periódica de Descobertas"
	title.add_theme_font_size_override("font_size", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_progress_lbl = Label.new()
	_progress_lbl.add_theme_font_size_override("font_size", 22)
	_progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_progress_lbl)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(center)

	_grid = Control.new()
	_grid.custom_minimum_size = Vector2(COLS * CELL_W, ROWS * CELL_H)
	center.add_child(_grid)

	var hint := Label.new()
	hint.text = "TAB / ESC — Fechar"
	hint.add_theme_font_size_override("font_size", 18)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.55, 0.55, 0.55)
	vbox.add_child(hint)

# ── Atualização do grid ────────────────────────────────────────────────────────
func _refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()

	var found       := 0
	var total       := 0
	var all_elements: Dictionary = ElementDatabase.elements

	for sym in all_elements:
		var el: Dictionary = all_elements[sym]
		if not el.has("period") or not el.has("group"):
			continue
		total += 1
		if GameState.collected_elements.get(sym, 0) > 0:
			found += 1
		_add_cell(sym, el)

	_progress_lbl.text = "%d / %d elementos descobertos" % [found, total]

func _add_cell(sym: String, el: Dictionary) -> void:
	var period: int     = el.get("period", 1)
	var group:  int     = el.get("group",  1)
	var collected: bool = GameState.collected_elements.get(sym, 0) > 0

	var panel := PanelContainer.new()
	panel.position            = Vector2((group - 1) * CELL_W + 1, (period - 1) * CELL_H + 1)
	panel.custom_minimum_size = Vector2(CELL_W - 2, CELL_H - 2)
	_grid.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var num_lbl := Label.new()
	num_lbl.text = str(el.get("atomic_number", ""))
	num_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(num_lbl)

	var sym_lbl := Label.new()
	sym_lbl.text = sym
	sym_lbl.add_theme_font_size_override("font_size", 24)
	sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sym_lbl)

	var name_lbl := Label.new()
	var el_name: String = el.get("name", "") if collected else "???"
	name_lbl.text = el_name.substr(0, 7) if el_name.length() > 7 else el_name
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	if collected:
		panel.modulate = Color(el.get("color", "#888888"))
	else:
		panel.modulate = Color(0.22, 0.22, 0.28)

func _on_state_changed(_id: String, _amt: int = 0) -> void:
	if _is_open:
		_refresh()
