extends Control
## VictoryScreen — Tela de vitória exibida após derrotar o Vírus Mutante (fim do Level 03).
## Toda a UI é construída via código, no mesmo padrão do main_menu.gd.

const MAIN_MENU := "res://scenes/menus/main_menu.tscn"
const W := 1280.0
const H := 720.0

const COL_BG_1     := "#3a2f8f"
const COL_BG_2     := "#241d63"
const COL_BG_3     := "#130f3e"
const COL_BG_4     := "#0a0726"
const COL_ACCENT   := "#8f84ff"
const COL_TITLE    := "#efeaff"
const COL_KICKER   := "#7be0ff"
const COL_SUBTITLE := "#b7b0e8"
const COL_BORDER   := "#0a0726"

const FONT_PIXEL_PATH := "res://assets/fonts/PressStart2P-Regular.ttf"
const FONT_MONO_PATH  := "res://assets/fonts/VT323-Regular.ttf"

var _font_pixel: Font
var _font_mono: Font
var _discoveries_panel: Control

func _ready() -> void:
	get_tree().paused = false
	_font_pixel = load(FONT_PIXEL_PATH)
	_font_mono  = load(FONT_MONO_PATH)
	AudioManager.play_sfx("victory")
	_build_background()
	_build_scanlines()
	_build_vignette()
	_build_content()
	_discoveries_panel = _build_discoveries_panel()
	_discoveries_panel.visible = false
	add_child(_discoveries_panel)

## Retorna uma variação da fonte com letter-spacing extra (em px).
func _spaced_font(base: Font, spacing_px: float) -> Font:
	if spacing_px == 0.0:
		return base
	var fv := FontVariation.new()
	fv.base_font     = base
	fv.spacing_glyph = int(round(spacing_px))
	return fv

# ── Fundo ────────────────────────────────────────────────────────────────────
func _build_background() -> void:
	var grad := Gradient.new()
	grad.colors  = PackedColorArray([Color(COL_BG_1), Color(COL_BG_2), Color(COL_BG_3), Color(COL_BG_4)])
	grad.offsets = PackedFloat32Array([0.0, 0.3, 0.6, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient  = grad
	tex.fill      = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.2)
	tex.fill_to   = Vector2(1.15, 1.0)
	tex.width     = 512
	tex.height    = 512
	var bg := TextureRect.new()
	bg.texture      = tex
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _build_scanlines() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float line_alpha = 0.22;
void fragment() {
	float line = mod(FRAGCOORD.y, 4.0);
	float a = line < 2.0 ? line_alpha : 0.0;
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var rect := ColorRect.new()
	rect.color         = Color(0, 0, 0, 0)
	rect.material      = mat
	rect.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(rect)

func _build_vignette() -> void:
	var grad := Gradient.new()
	grad.colors  = PackedColorArray([Color(0.024, 0.016, 0.102, 0.0), Color(0.024, 0.016, 0.102, 0.85)])
	grad.offsets = PackedFloat32Array([0.55, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient  = grad
	tex.fill      = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to   = Vector2(1.0, 0.5)
	tex.width     = 512
	tex.height    = 512
	var tr := TextureRect.new()
	tr.texture      = tex
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tr)

# ── Conteúdo (título, mensagem educativa, estatísticas, botão) ────────────────
func _build_content() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 22)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vb)

	var kicker := Label.new()
	kicker.text = "VITÓRIA"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_font_override("font", _spaced_font(_font_mono, 5.6))
	kicker.add_theme_font_size_override("font_size", 20)
	kicker.add_theme_color_override("font_color", Color(COL_KICKER))
	kicker.add_theme_color_override("font_shadow_color", Color(COL_BG_4))
	kicker.add_theme_constant_override("shadow_offset_x", 2)
	kicker.add_theme_constant_override("shadow_offset_y", 2)
	vb.add_child(kicker)

	var title := Label.new()
	title.text = "VOCÊ SALVOU O LABORATÓRIO!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(760, 0)
	title.add_theme_font_override("font", _font_pixel)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(COL_TITLE))
	title.add_theme_color_override("font_shadow_color", Color(COL_BG_4))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	vb.add_child(title)

	var message := Label.new()
	message.text = "A Química está em tudo — do álcool que desinfeta as mãos até a água que bebemos. Cada elemento que você coletou nessa jornada é uma peça fundamental da matéria que forma o nosso mundo!"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size = Vector2(700, 0)
	message.add_theme_font_override("font", _font_mono)
	message.add_theme_font_size_override("font_size", 24)
	message.add_theme_color_override("font_color", Color(COL_SUBTITLE))
	message.add_theme_color_override("font_shadow_color", Color(COL_BG_4))
	message.add_theme_constant_override("shadow_offset_x", 1)
	message.add_theme_constant_override("shadow_offset_y", 1)
	vb.add_child(message)

	var stats_box := VBoxContainer.new()
	stats_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_box.add_theme_constant_override("separation", 2)
	vb.add_child(stats_box)

	var elements_lbl := Label.new()
	elements_lbl.text = "Elementos descobertos: %d/%d" % [
		GameState.discovered_elements.size(), ElementDatabase.elements.size()]
	_style_stat_label(elements_lbl)
	stats_box.add_child(elements_lbl)

	var compounds_lbl := Label.new()
	compounds_lbl.text = "Compostos descobertos: %d/%d" % [
		GameState.discovered_compounds.size(), ElementDatabase.recipes.size()]
	_style_stat_label(compounds_lbl)
	stats_box.add_child(compounds_lbl)

	var btn_spacer := Control.new()
	btn_spacer.custom_minimum_size = Vector2(0, 8)
	vb.add_child(btn_spacer)

	vb.add_child(_make_pixel_button(
		"VER DESCOBERTAS", Color("#5ac8ff"), Color("#2f7ab8"), Color("#123a5c"), Color("#eaf6ff"),
		func() -> void: _toggle_discoveries_panel()))

	vb.add_child(_make_pixel_button(
		"MENU PRINCIPAL", Color("#7ce24a"), Color("#4aa326"), Color("#2f7315"), Color("#082206"),
		func() -> void: get_tree().change_scene_to_file(MAIN_MENU)))

func _style_stat_label(lbl: Label) -> void:
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", _font_mono)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(COL_ACCENT))
	lbl.add_theme_color_override("font_shadow_color", Color(COL_BG_4))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)

## Botão estilo retrô "chunky": borda escura 3px + ledge inferior 6px (sombra) + face com highlight superior.
func _make_pixel_button(text: String, face_hi: Color, face: Color, shadow: Color, text_color: Color, callback: Callable) -> Control:
	const BTN_W    := 340.0
	const BTN_H    := 50.0
	const SHADOW_H := 6.0
	const BORDER   := 3.0

	var total_w := BTN_W + BORDER * 2.0
	var total_h := BTN_H + SHADOW_H + BORDER * 2.0

	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(total_w, total_h)
	wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var border_rect := ColorRect.new()
	border_rect.color = Color(COL_BORDER)
	border_rect.size  = Vector2(total_w, total_h)
	wrap.add_child(border_rect)

	var shadow_rect := ColorRect.new()
	shadow_rect.color    = shadow
	shadow_rect.position = Vector2(BORDER, BORDER + BTN_H)
	shadow_rect.size     = Vector2(BTN_W, SHADOW_H)
	wrap.add_child(shadow_rect)

	var face_rect := ColorRect.new()
	face_rect.color    = face_hi
	face_rect.position = Vector2(BORDER, BORDER)
	face_rect.size     = Vector2(BTN_W, BTN_H)
	wrap.add_child(face_rect)

	var hi_rect := ColorRect.new()
	hi_rect.color = Color(1, 1, 1, 0.28)
	hi_rect.size  = Vector2(BTN_W, 3)
	face_rect.add_child(hi_rect)

	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", _font_pixel)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", text_color)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face_rect.add_child(lbl)

	var btn := Button.new()
	btn.flat          = true
	btn.size          = Vector2(total_w, total_h)
	btn.self_modulate = Color(1, 1, 1, 0)
	btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		callback.call())
	btn.button_down.connect(func() -> void: face_rect.position = Vector2(BORDER, BORDER + 4.0))
	btn.button_up.connect(func() -> void: face_rect.position = Vector2(BORDER, BORDER))
	wrap.add_child(btn)

	return wrap

# ── Painel de Descobertas (elementos + compostos) ──────────────────────────────
func _toggle_discoveries_panel() -> void:
	_discoveries_panel.visible = not _discoveries_panel.visible

func _build_discoveries_panel() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_discoveries_panel.visible = false)

	var panel := ColorRect.new()
	panel.color = Color(COL_BG_3)
	panel.offset_left   = (W - 980.0) * 0.5
	panel.offset_top    = (H - 620.0) * 0.5
	panel.offset_right  = panel.offset_left + 980.0
	panel.offset_bottom = panel.offset_top + 620.0
	panel.mouse_filter  = Control.MOUSE_FILTER_STOP
	overlay.add_child(panel)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_left",   32)
	mc.add_theme_constant_override("margin_right",  32)
	mc.add_theme_constant_override("margin_top",    22)
	mc.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(mc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	mc.add_child(vb)

	var title := Label.new()
	title.text = "SUAS DESCOBERTAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font_pixel)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(COL_TITLE))
	vb.add_child(title)

	var elements_title := Label.new()
	elements_title.text = "Elementos"
	elements_title.add_theme_font_override("font", _font_mono)
	elements_title.add_theme_font_size_override("font_size", 22)
	elements_title.add_theme_color_override("font_color", Color(COL_KICKER))
	vb.add_child(elements_title)

	var elements_center := CenterContainer.new()
	vb.add_child(elements_center)

	var elements_grid := GridContainer.new()
	elements_grid.columns = 6
	elements_grid.add_theme_constant_override("h_separation", 10)
	elements_grid.add_theme_constant_override("v_separation", 10)
	elements_center.add_child(elements_grid)
	_fill_elements_grid(elements_grid)

	vb.add_child(HSeparator.new())

	var compounds_title := Label.new()
	compounds_title.text = "Compostos"
	compounds_title.add_theme_font_override("font", _font_mono)
	compounds_title.add_theme_font_size_override("font_size", 22)
	compounds_title.add_theme_color_override("font_color", Color(COL_KICKER))
	vb.add_child(compounds_title)

	var compounds_scroll := ScrollContainer.new()
	compounds_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(compounds_scroll)

	var compounds_grid := GridContainer.new()
	compounds_grid.columns = 2
	compounds_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	compounds_grid.add_theme_constant_override("h_separation", 12)
	compounds_grid.add_theme_constant_override("v_separation", 12)
	compounds_scroll.add_child(compounds_grid)
	_fill_compounds_list(compounds_grid)

	var close_btn := Button.new()
	close_btn.text = "Fechar"
	close_btn.add_theme_font_override("font", _font_mono)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.pressed.connect(func() -> void: _discoveries_panel.visible = false)
	vb.add_child(close_btn)

	return overlay

func _fill_elements_grid(grid: GridContainer) -> void:
	var syms := ElementDatabase.elements.keys()
	syms.sort_custom(func(a: String, b: String) -> bool:
		var na: int = (ElementDatabase.elements[a] as Dictionary).get("atomic_number", 0)
		var nb: int = (ElementDatabase.elements[b] as Dictionary).get("atomic_number", 0)
		return na < nb)

	for sym: String in syms:
		var el: Dictionary = ElementDatabase.elements[sym]
		var collected: bool = sym in GameState.discovered_elements
		var base_col: Color = Color(el.get("color", "#888888")) if collected else Color(0.30, 0.30, 0.36)

		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(96, 92)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(base_col.r, base_col.g, base_col.b, 0.20 if collected else 0.10)
		style.border_color = base_col
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		style.content_margin_left   = 6
		style.content_margin_right  = 6
		style.content_margin_top    = 8
		style.content_margin_bottom = 8
		cell.add_theme_stylebox_override("panel", style)
		grid.add_child(cell)

		var cvb := VBoxContainer.new()
		cvb.alignment = BoxContainer.ALIGNMENT_CENTER
		cvb.add_theme_constant_override("separation", 2)
		cell.add_child(cvb)

		var sym_lbl := Label.new()
		sym_lbl.text = sym
		sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym_lbl.add_theme_font_override("font", _font_mono)
		sym_lbl.add_theme_font_size_override("font_size", 28)
		sym_lbl.add_theme_color_override("font_color", base_col if collected else Color(0.6, 0.6, 0.66))
		cvb.add_child(sym_lbl)

		var name_lbl := Label.new()
		name_lbl.text = el.get("name", "") if collected else "???"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.custom_minimum_size = Vector2(84, 0)
		name_lbl.add_theme_font_override("font", _font_mono)
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color(COL_SUBTITLE) if collected else Color(0.5, 0.5, 0.56))
		cvb.add_child(name_lbl)

func _fill_compounds_list(grid: GridContainer) -> void:
	for rid: String in ElementDatabase.recipes:
		var r := ElementDatabase.get_recipe(rid)
		if r.is_empty():
			continue
		var discovered: bool = rid in GameState.discovered_compounds
		var formula: String  = r.get("formula", rid)
		var cname: String    = r.get("name", "")
		var ings: Dictionary  = r.get("ingredients", {})
		var ing_parts: Array[String] = []
		for ing: String in ings:
			ing_parts.append("%s×%d" % [ing, int(ings[ing])])
		var ing_text := " + ".join(ing_parts)

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(430, 0)

		var accent := Color(COL_ACCENT) if discovered else Color(0.4, 0.4, 0.46)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.16 if discovered else 0.06)
		style.border_color = accent
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		style.content_margin_left   = 12
		style.content_margin_right  = 12
		style.content_margin_top    = 8
		style.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", style)
		grid.add_child(card)

		var cvb := VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 2)
		card.add_child(cvb)

		var head := Label.new()
		head.text = "%s %s (%s)" % ["✓" if discovered else "○", formula, cname]
		head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		head.add_theme_font_override("font", _font_mono)
		head.add_theme_font_size_override("font_size", 20)
		head.add_theme_color_override("font_color", accent)
		cvb.add_child(head)

		var sub := Label.new()
		sub.text = ing_text if discovered else "%s — não descoberto, você poderia ter combinado!" % ing_text
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.add_theme_font_override("font", _font_mono)
		sub.add_theme_font_size_override("font_size", 15)
		sub.add_theme_color_override("font_color", Color(0.75, 0.73, 0.8) if discovered else Color(0.55, 0.52, 0.62))
		cvb.add_child(sub)
