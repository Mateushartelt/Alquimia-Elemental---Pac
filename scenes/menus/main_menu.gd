extends Control
## MainMenu — Tela inicial do jogo. Caverna de cristais estilo retrô.
## Toda a UI é construída via código (sem nós no .tscn), no mesmo padrão do boss_battle.gd.

const LEVEL_01 := "res://scenes/levels/level_01.tscn"
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
const COL_GEM      := "#5ac8ff"
const COL_BORDER   := "#0a0726"

const FONT_PIXEL_PATH := "res://assets/fonts/PressStart2P-Regular.ttf"
const FONT_MONO_PATH  := "res://assets/fonts/VT323-Regular.ttf"
const MENU_MUSIC_PATH := "res://assets/audio/music/menu_music.wav"
const MENU_MUSIC_VOLUME_DB := -22.0   # bem baixinho — só ambientação, toca apenas neste menu

var _font_pixel: Font
var _font_mono: Font

var _buttons: Array[Dictionary] = []
var _selected_idx: int = 0

func _ready() -> void:
	get_tree().paused = false
	_font_pixel = load(FONT_PIXEL_PATH)
	_font_mono  = load(FONT_MONO_PATH)
	_play_menu_music()
	_build_background()
	_build_glow()
	_build_stalactites()
	_build_crystals()
	_build_gems()
	_build_scanlines()
	_build_vignette()
	_build_ground()
	_build_content()

## Música ambiente do menu — player local (não via AudioManager) para tocar só
## enquanto esta cena existir; some sozinho ao trocar de cena.
func _play_menu_music() -> void:
	var stream: AudioStream = load(MENU_MUSIC_PATH)
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		var bytes_per_sample := 1 if wav.format == AudioStreamWAV.FORMAT_8_BITS else 2
		var channels := 2 if wav.stereo else 1
		wav.loop_mode  = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end   = wav.data.size() / (bytes_per_sample * channels)
	var player := AudioStreamPlayer.new()
	player.stream    = stream
	player.volume_db = MENU_MUSIC_VOLUME_DB
	add_child(player)
	player.play()

## Retorna uma variação da fonte com letter-spacing extra (em px, aprox. igual ao CSS letter-spacing).
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

func _build_glow() -> void:
	var blobs := [
		{ "pos": Vector2(0.30, 0.55), "size": Vector2(0.40, 0.60), "color": Color(120.0/255.0, 105.0/255.0, 1.0, 0.28) },
		{ "pos": Vector2(0.72, 0.48), "size": Vector2(0.38, 0.55), "color": Color(95.0/255.0, 80.0/255.0, 230.0/255.0, 0.25) },
	]
	for b: Dictionary in blobs:
		var col: Color = b["color"]
		var grad := Gradient.new()
		grad.colors = PackedColorArray([col, Color(col.r, col.g, col.b, 0.0)])
		var tex := GradientTexture2D.new()
		tex.gradient  = grad
		tex.fill      = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to   = Vector2(1.0, 0.5)
		tex.width     = 256
		tex.height    = 256
		var tr := TextureRect.new()
		tr.texture      = tex
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sz: Vector2 = b["size"]
		var w := W * sz.x * 2.2
		var h := H * sz.y * 2.2
		var pos: Vector2 = b["pos"]
		tr.size     = Vector2(w, h)
		tr.position = Vector2(W * pos.x - w * 0.5, H * pos.y - h * 0.5)
		add_child(tr)

# ── Estalactites (topo) ──────────────────────────────────────────────────────
func _build_stalactites() -> void:
	var heights: Array[float] = [150, 90, 170, 110, 140, 80, 160, 100, 130, 120]
	var count   := heights.size()
	var pad     := W * 0.02
	var usable  := W - pad * 2.0
	var widths: Array[float] = []
	for i in count:
		widths.append(60.0 + float(i % 3) * 22.0)
	var total_w := 0.0
	for w: float in widths:
		total_w += w
	var gap := (usable - total_w) / float(count - 1)
	var x := pad
	for i in count:
		var w: float = widths[i]
		var h: float = heights[i]
		var shade := Color("#0c0930") if i % 2 == 1 else Color("#080622")
		var tri := Polygon2D.new()
		tri.polygon  = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w * 0.5, h)])
		tri.color    = shade
		tri.position = Vector2(x, 0)
		add_child(tri)
		x += w + gap

# ── Cristais (base, com flutuação suave) ─────────────────────────────────────
func _build_crystals() -> void:
	var defs := [
		{ "l": 0.04, "w": 110.0, "h": 250.0, "tone": Color("#2a2270"), "hi": Color("#5b4fd6") },
		{ "l": 0.16, "w": 150.0, "h": 320.0, "tone": Color("#3a2f9a"), "hi": Color("#7a6ff0") },
		{ "l": 0.34, "w": 120.0, "h": 210.0, "tone": Color("#241d63"), "hi": Color("#4f45c0") },
		{ "l": 0.54, "w": 170.0, "h": 300.0, "tone": Color("#3a2f9a"), "hi": Color("#8f84ff") },
		{ "l": 0.72, "w": 130.0, "h": 260.0, "tone": Color("#2a2270"), "hi": Color("#6f63e8") },
		{ "l": 0.86, "w": 150.0, "h": 230.0, "tone": Color("#241d63"), "hi": Color("#5b4fd6") },
	]
	for i in defs.size():
		var d: Dictionary = defs[i]
		var w: float = d["w"]
		var h: float = d["h"]
		var base_x := W * float(d["l"])
		var base_y := H - h

		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(w * 0.5, 0.0), Vector2(w, h * 0.34), Vector2(w * 0.78, h),
			Vector2(w * 0.22, h),  Vector2(0.0, h * 0.34),
		])
		poly.color    = d["tone"]
		poly.position = Vector2(base_x, base_y)
		add_child(poly)

		var hi_poly := Polygon2D.new()
		hi_poly.polygon = PackedVector2Array([
			Vector2(w * 0.5, 0.0), Vector2(0.0, h * 0.34), Vector2(w * 0.22, h), Vector2(w * 0.5, h * 0.5),
		])
		var hi_col: Color = d["hi"]
		hi_poly.color    = Color(hi_col.r, hi_col.g, hi_col.b, 0.35)
		hi_poly.position = poly.position
		add_child(hi_poly)

		var dur := 7.0 + float(i)
		_float_loop(poly, base_y, dur)
		_float_loop(hi_poly, base_y, dur)

func _float_loop(node: Node2D, base_y: float, dur: float) -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(node, "position:y", base_y - 10.0, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position:y", base_y, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ── Gemas cintilantes ─────────────────────────────────────────────────────────
func _build_gems() -> void:
	var defs := [
		{ "t": 0.62, "l": 0.26, "s": 14.0 }, { "t": 0.70, "l": 0.40, "s": 10.0 },
		{ "t": 0.58, "l": 0.63, "s": 12.0 }, { "t": 0.74, "l": 0.78, "s": 9.0 },
		{ "t": 0.50, "l": 0.12, "s": 11.0 }, { "t": 0.66, "l": 0.90, "s": 10.0 },
	]
	for i in defs.size():
		var d: Dictionary = defs[i]
		var s: float = d["s"]
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(s * 0.5, 0.0), Vector2(s, s * 0.34), Vector2(s * 0.5, s * 0.85), Vector2(0.0, s * 0.34),
		])
		poly.color    = Color(COL_GEM)
		poly.position = Vector2(W * float(d["l"]), H * float(d["t"]))
		poly.modulate.a = 0.25
		add_child(poly)

		var dur := 2.5 + float(i) * 0.4
		var tw := create_tween().set_loops()
		tw.tween_property(poly, "modulate:a", 1.0, dur * 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(poly, "modulate:a", 0.25, dur * 0.5).set_trans(Tween.TRANS_SINE)

# ── Scanlines ──────────────────────────────────────────────────────────────────
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

# ── Vinheta ──────────────────────────────────────────────────────────────────
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

# ── Chão ─────────────────────────────────────────────────────────────────────
func _build_ground() -> void:
	var rect := ColorRect.new()
	rect.color        = Color(COL_BG_4)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rect.offset_top    = -16.0
	rect.offset_bottom = 0.0
	add_child(rect)

# ── Conteúdo (título, subtítulo, botões, dica) ────────────────────────────────
func _build_content() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 28)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vb)

	var text_box := VBoxContainer.new()
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 4)
	vb.add_child(text_box)

	var kicker := Label.new()
	kicker.text = "QUÍMICA · PLATAFORMA"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_font_override("font", _spaced_font(_font_mono, 5.6))
	kicker.add_theme_font_size_override("font_size", 20)
	kicker.add_theme_color_override("font_color", Color(COL_KICKER))
	kicker.add_theme_color_override("font_shadow_color", Color(COL_BG_4))
	kicker.add_theme_constant_override("shadow_offset_x", 2)
	kicker.add_theme_constant_override("shadow_offset_y", 2)
	text_box.add_child(kicker)

	var title_spacer := Control.new()
	title_spacer.custom_minimum_size = Vector2(0, 10)
	text_box.add_child(title_spacer)

	_add_title(text_box)

	var sub_spacer := Control.new()
	sub_spacer.custom_minimum_size = Vector2(0, 6)
	text_box.add_child(sub_spacer)

	var subtitle := Label.new()
	subtitle.text = "Colete elementos · Combine substâncias · Vença o chefe"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", _font_mono)
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(COL_SUBTITLE))
	subtitle.add_theme_color_override("font_shadow_color", Color(COL_BG_4))
	subtitle.add_theme_constant_override("shadow_offset_x", 1)
	subtitle.add_theme_constant_override("shadow_offset_y", 1)
	text_box.add_child(subtitle)

	var menu_box := VBoxContainer.new()
	menu_box.alignment              = BoxContainer.ALIGNMENT_CENTER
	menu_box.size_flags_horizontal  = Control.SIZE_SHRINK_CENTER   # não esticar — centralizar em relação ao título/subtítulo
	menu_box.add_theme_constant_override("separation", 18)
	vb.add_child(menu_box)

	menu_box.add_child(_make_pixel_button(
		"▶ JOGAR", Color("#7ce24a"), Color("#4aa326"), Color("#2f7315"), Color("#082206"), _on_play_pressed))
	menu_box.add_child(_make_pixel_button(
		"SAIR", Color("#3a2f9a"), Color("#2a2270"), Color("#120d3a"), Color("#cbc4ff"), _on_quit_pressed))
	_select_button(0, false)   # JOGAR já vem destacado ao abrir o menu

	var hint := Label.new()
	hint.text = "▲▼ selecionar   ⏎ confirmar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", _spaced_font(_font_mono, 2.2))
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(COL_ACCENT))
	hint.add_theme_color_override("font_shadow_color", Color(COL_BG_4))
	hint.add_theme_constant_override("shadow_offset_x", 2)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	vb.add_child(hint)
	_blink(hint)

func _add_title(parent: Control) -> void:
	var line1 := Label.new()
	line1.text = "ALQUIMIA"
	line1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line1.add_theme_font_override("font", _font_pixel)
	line1.add_theme_font_size_override("font_size", 32)
	line1.add_theme_color_override("font_color", Color(COL_TITLE))
	line1.add_theme_color_override("font_shadow_color", Color(COL_BG_4))
	line1.add_theme_constant_override("shadow_offset_x", 4)
	line1.add_theme_constant_override("shadow_offset_y", 4)
	parent.add_child(line1)

	var line_gap := Control.new()
	line_gap.custom_minimum_size = Vector2(0, 14)
	parent.add_child(line_gap)

	var line2 := Label.new()
	line2.text = "ELEMENTAL"
	line2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line2.add_theme_font_override("font", _font_pixel)
	line2.add_theme_font_size_override("font_size", 32)
	line2.add_theme_color_override("font_color", Color(COL_ACCENT))
	line2.add_theme_color_override("font_shadow_color", Color(COL_BG_4))
	line2.add_theme_constant_override("shadow_offset_x", 4)
	line2.add_theme_constant_override("shadow_offset_y", 4)
	parent.add_child(line2)

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
	face_rect.color    = face
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

	var idx := _buttons.size()
	_buttons.append({ "face_rect": face_rect, "face": face, "face_hi": face_hi, "callback": callback })

	var btn := Button.new()
	btn.flat          = true
	btn.size          = Vector2(total_w, total_h)
	btn.self_modulate = Color(1, 1, 1, 0)
	btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		callback.call())
	btn.mouse_entered.connect(func() -> void: _select_button(idx))
	btn.button_down.connect(func() -> void: face_rect.position = Vector2(BORDER, BORDER + 4.0))
	btn.button_up.connect(func() -> void: face_rect.position = Vector2(BORDER, BORDER))
	wrap.add_child(btn)

	return wrap

## Atualiza qual botão está destacado (seleção do teclado/mouse).
func _select_button(idx: int, play_sound: bool = true) -> void:
	if idx == _selected_idx and play_sound:
		return
	_selected_idx = idx
	for i in _buttons.size():
		var b: Dictionary = _buttons[i]
		(b["face_rect"] as ColorRect).color = b["face_hi"] if i == idx else b["face"]
	if play_sound:
		AudioManager.play_sfx("menu_move")

func _unhandled_input(event: InputEvent) -> void:
	if _buttons.is_empty():
		return
	if event.is_action_pressed("ui_down") and not event.is_echo():
		_select_button((_selected_idx + 1) % _buttons.size())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") and not event.is_echo():
		_select_button((_selected_idx - 1 + _buttons.size()) % _buttons.size())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		AudioManager.play_sfx("ui_click")
		(_buttons[_selected_idx]["callback"] as Callable).call()
		get_viewport().set_input_as_handled()

## Pisca via alpha (não via 'visible') — mudar 'visible' remove o nó do
## cálculo de layout do VBoxContainer e faz todo o conteúdo acima pular de posição.
func _blink(node: CanvasItem) -> void:
	var tw := create_tween().set_loops()
	tw.tween_interval(0.55)
	tw.tween_callback(func() -> void: node.modulate.a = 0.0)
	tw.tween_interval(0.55)
	tw.tween_callback(func() -> void: node.modulate.a = 1.0)

# ── Ações ────────────────────────────────────────────────────────────────────
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_01)

func _on_quit_pressed() -> void:
	get_tree().quit()
