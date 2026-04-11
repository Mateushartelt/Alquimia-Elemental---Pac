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
var _tooltip      : PanelContainer
var _tooltip_lbl  : Label
var _toast        : PanelContainer
var _toast_lbl    : Label
var _announced    : Array[String] = []

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
				return
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
	_tooltip.visible = false

# ── Construção da UI ──────────────────────────────────────────────────────────
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
	hint.text = "TAB / ESC — Fechar    |    Passe o mouse sobre um elemento para ver detalhes"
	hint.add_theme_font_size_override("font_size", 18)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.55, 0.55, 0.55)
	vbox.add_child(hint)

	# ── Tooltip (visível só com tabela aberta) ────────────────────────────────
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.z_index = 10
	bg.add_child(_tooltip)

	var tooltip_margin := MarginContainer.new()
	tooltip_margin.add_theme_constant_override("margin_left",   12)
	tooltip_margin.add_theme_constant_override("margin_right",  12)
	tooltip_margin.add_theme_constant_override("margin_top",    8)
	tooltip_margin.add_theme_constant_override("margin_bottom", 8)
	_tooltip.add_child(tooltip_margin)

	_tooltip_lbl = Label.new()
	_tooltip_lbl.add_theme_font_size_override("font_size", 16)
	_tooltip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_lbl.custom_minimum_size = Vector2(280, 0)
	tooltip_margin.add_child(_tooltip_lbl)

	# ── Toast (visível mesmo com tabela fechada) ──────────────────────────────
	_toast = PanelContainer.new()
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.anchor_left   = 0.5
	_toast.anchor_right  = 0.5
	_toast.anchor_top    = 0.0
	_toast.anchor_bottom = 0.0
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = 12.0

	var toast_style := StyleBoxFlat.new()
	toast_style.bg_color = Color(0.1, 0.1, 0.18, 0.92)
	toast_style.border_width_left   = 2
	toast_style.border_width_right  = 2
	toast_style.border_width_top    = 2
	toast_style.border_width_bottom = 2
	toast_style.border_color = Color(0.4, 0.7, 1.0, 0.8)
	toast_style.corner_radius_top_left     = 6
	toast_style.corner_radius_top_right    = 6
	toast_style.corner_radius_bottom_left  = 6
	toast_style.corner_radius_bottom_right = 6
	_toast.add_theme_stylebox_override("panel", toast_style)

	var toast_margin := MarginContainer.new()
	toast_margin.add_theme_constant_override("margin_left",   16)
	toast_margin.add_theme_constant_override("margin_right",  16)
	toast_margin.add_theme_constant_override("margin_top",    8)
	toast_margin.add_theme_constant_override("margin_bottom", 8)
	_toast.add_child(toast_margin)

	_toast_lbl = Label.new()
	_toast_lbl.add_theme_font_size_override("font_size", 20)
	_toast_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	toast_margin.add_child(_toast_lbl)

	# Toast fica numa CanvasLayer própria para aparecer por cima de tudo
	add_child(_toast)

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
		if sym in GameState.discovered_elements:
			found += 1
		_add_cell(sym, el)

	_progress_lbl.text = "%d / %d elementos descobertos" % [found, total]

func _add_cell(sym: String, el: Dictionary) -> void:
	var period: int     = el.get("period", 1)
	var group:  int     = el.get("group",  1)
	var collected: bool = sym in GameState.discovered_elements

	var panel := PanelContainer.new()
	panel.position            = Vector2((group - 1) * CELL_W + 1, (period - 1) * CELL_H + 1)
	panel.custom_minimum_size = Vector2(CELL_W - 2, CELL_H - 2)
	panel.mouse_filter        = Control.MOUSE_FILTER_STOP
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

	# Tooltip ao passar o mouse (só mostra informação se coletado)
	panel.mouse_entered.connect(func() -> void:
		if not _is_open:
			return
		var lines: Array[String] = []
		if collected:
			lines.append("%s — %s" % [sym, el.get("name", sym)])
			lines.append("Nº %s  |  Massa: %s u" % [el.get("atomic_number", "?"), el.get("atomic_mass", "?")])
			var desc: String = el.get("description", "")
			if desc != "":
				lines.append("")
				lines.append(desc)
			var curio: String = el.get("curiosity", "")
			if curio != "":
				lines.append("")
				lines.append("★ " + curio)
		else:
			lines.append("??? — Elemento não descoberto")
		_tooltip_lbl.text = "\n".join(lines)
		await get_tree().process_frame
		var gpos := panel.get_global_rect()
		var tw2: float = _tooltip.size.x if _tooltip.size.x > 0 else 300.0
		var th: float  = _tooltip.size.y if _tooltip.size.y > 0 else 160.0
		var tx := clampf(gpos.position.x, 8.0, 1280.0 - tw2 - 8.0)
		var ty := gpos.position.y + gpos.size.y + 6.0
		if ty + th > 720.0:
			ty = gpos.position.y - th - 6.0
		_tooltip.position = Vector2(tx, ty)
		_tooltip.visible = true)

	panel.mouse_exited.connect(func() -> void:
		_tooltip.visible = false)

# ── Notificação de novo elemento ──────────────────────────────────────────────
func _on_state_changed(sym: String, _amt: int = 0) -> void:
	if _is_open:
		_refresh()

	# Só notifica na primeira vez que o elemento é coletado
	if sym in _announced:
		return
	_announced.append(sym)

	var el: Dictionary = ElementDatabase.get_element(sym)
	var el_name: String = el.get("name", sym)

	var is_first := _announced.size() == 1

	if is_first:
		_show_toast("Novo elemento: %s (%s)!\nPressione TAB para ver sua Tabela Periódica." % [el_name, sym], 4.0)
	else:
		_show_toast("%s (%s) adicionado à Tabela Periódica!  [TAB]" % [el_name, sym], 2.5)

func _show_toast(text: String, duration: float) -> void:
	_toast_lbl.text = text
	_toast.visible  = true
	_toast.modulate = Color.WHITE

	var tw := create_tween()
	tw.tween_interval(duration - 0.5)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: _toast.visible = false)
