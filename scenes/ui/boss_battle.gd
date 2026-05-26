class_name BossBattle
extends CanvasLayer
## BossBattle — Batalha estilo Pokémon contra o boss da fase.
## Chame show_battle(boss_id) para iniciar. Emite battle_finished(won).

signal battle_finished(won: bool)

const BOSSES: Dictionary = {
	"snail": {
		"name":        "Lesma Gigante",
		"color":       Color(0.18, 0.55, 0.12),
		"sprite":      "res://scenes/enemies/assets/snail/idle snail.jpg",
		"sprite_cols": 4,
		"sprite_rows": 2,
		"max_hp":      6,
		"attack_dmg":  15,
		"intro":       "Uma enorme Lesma Gigante bloqueia o caminho!",
		"hint":        "Dica: lesmas se dissolvem em sal — NaCl (Na + Cl) é a fraqueza dela!",
		"hint_detail": "A Lesma Gigante segrega muco que a protege de ataques.\nAlgo que resseque esse muco seria muito eficaz...\n\nDica: Na + Cl formam um composto muito conhecido na cozinha!\n(Água — H2O — não ajuda: lesmas adoram umidade!)",
		"boss_atk":    "A Lesma lança gosma viscosa!",
		"no_reaction": "O composto não causou reação perceptível na lesma...",
		"win":         "Vitória! NaCl age por osmose — resseca o muco e desidrata a lesma!",
		"lose":        "Você foi derrotado pela Lesma Gigante...",
		"drops":       ["Na", "Cl"],
		"drop_msg":    "A lesma soltou %s com o impacto! (+1 %s)",
		"reactions": {
			"NaCl": {
				"damage":  2,
				"message": "Por osmose, o NaCl resseca o muco! Dano duplo!",
				"effect":  "none",
				"flash":   Color(2.0, 0.5, 0.1),
			},
			"H2O": {
				"damage":  -1,
				"message": "A lesma absorve a água e se recupera! Lesmas precisam de umidade para sobreviver!",
				"effect":  "heal",
				"flash":   Color(0.3, 0.8, 2.0),
			},
			"HCl": {
				"damage":  1,
				"message": "O ácido clorídrico corrói o muco da lesma! Dano ácido!",
				"effect":  "none",
				"flash":   Color(0.5, 2.0, 0.3),
			},
			"SO2": {
				"damage":  1,
				"message": "A fumaça tóxica atordoa a lesma! Próximo ataque cancelado!",
				"effect":  "stun",
				"flash":   Color(2.0, 2.0, 0.2),
			},
			"CO2": {
				"damage":  1,
				"message": "O CO₂ resfria e endurece o muco da lesma!",
				"effect":  "none",
				"flash":   Color(0.7, 0.8, 2.0),
			},
			"NaOH": {
				"damage":  1,
				"message": "A base forte reage com o muco ácido da lesma!",
				"effect":  "none",
				"flash":   Color(0.8, 0.5, 2.0),
			},
		}
	},
	"virus": {
		"name":        "Vírus Mutante",
		"color":       Color(0.54, 0.0, 1.0),
		"sprite":      "",
		"sprite_cols": 1,
		"sprite_rows": 1,
		"max_hp":      8,
		"attack_dmg":  15,
		"intro":       "Um Vírus Mutante colossal contaminou o Núcleo de Controle!",
		"hint":        "Dica: álcool etílico (Etanol) desnatura proteínas virais — é a fraqueza dele!",
		"hint_detail": "O Vírus Mutante possui proteínas de superfície que o protegem.\nEtanol (C+2H+O) desnatura essas proteínas — dano triplo!\nHCl corrói a cápsula viral (2× dano)\n\nCuidado: H₂O CURA o vírus — ele adora umidade!\nAprendizado: por isso lavamos mãos com álcool, não só com água!",
		"boss_atk":    "O Vírus Mutante injeta RNA viral!",
		"no_reaction": "O composto não causou reação perceptível no vírus...",
		"win":         "Vitória! Etanol desnaturou as proteínas virais — o vírus se desintegrou!",
		"lose":        "O Vírus Mutante foi forte demais... Crie Etanol (C+H+H+O) no painel!",
		"draw_mode":        "virus_proc",
		"smart_drop_recipe":"Etanol",
		"drops":            ["C", "H", "O"],
		"drop_msg":         "O vírus liberou %s ao se desintegrar! (+1 %s)",
		"reactions": {
			"Etanol": {
				"damage":  3,
				"message": "O Etanol desnatura as proteínas de superfície! Triplo dano!",
				"effect":  "stun",
				"flash":   Color(0.5, 2.0, 0.8),
			},
			"HCl": {
				"damage":  2,
				"message": "O ácido clorídrico corrói a cápsula viral! Dano duplo!",
				"effect":  "none",
				"flash":   Color(0.5, 2.0, 0.3),
			},
			"H2O": {
				"damage":  -1,
				"message": "O vírus absorve a umidade e se recupera! Vírus adoram ambientes úmidos!",
				"effect":  "heal",
				"flash":   Color(0.3, 0.8, 2.0),
			},
			"NaCl": {
				"damage":  1,
				"message": "O sal resseca a membrana viral por osmose!",
				"effect":  "none",
				"flash":   Color(2.0, 1.5, 1.0),
			},
			"CO2": {
				"damage":  1,
				"message": "O CO₂ acidifica o meio intracelular do vírus!",
				"effect":  "none",
				"flash":   Color(0.7, 0.8, 2.0),
			},
			"NaOH": {
				"damage":  1,
				"message": "A base forte destrói o envelope lipídico viral!",
				"effect":  "none",
				"flash":   Color(0.8, 0.5, 2.0),
			},
			"SO2": {
				"damage":  1,
				"message": "O gás tóxico atordoa o vírus!",
				"effect":  "stun",
				"flash":   Color(2.0, 2.0, 0.2),
			},
		}
	},
	"golem": {
		"name":        "Golem de Lava",
		"color":       Color(0.75, 0.28, 0.03),
		"sprite":      "res://scenes/enemies/assets/golem/golem_fire.png",
		"sprite_cols": 6,
		"sprite_rows": 2,
		"max_hp":      8,
		"attack_dmg":  20,
		"intro":       "Um colossal Golem de Lava bloqueia a saída da Caldeira!",
		"hint":        "Dica: lava solidifica com água — H₂O é a fraqueza principal do Golem!",
		"hint_detail": "O Golem de Lava é feito de rocha fundida rica em enxofre.\nH₂O apaga o fogo e solidifica a lava! (3× de dano!)\nCO₂ remove o oxigênio das chamas! (2× + stun)\n\nCuidado: SO₂ é componente do magma vulcânico!\nO golem ABSORVE SO₂ e se recupera — escolha errada = aprendizado!",
		"boss_atk":    "O Golem lança pedras de lava incandescentes!",
		"no_reaction": "O composto não causou reação significativa no golem...",
		"win":         "Vitória! H₂O solidificou a lava — reação endotérmica de resfriamento!",
		"lose":        "O Golem de Lava foi forte demais...",
		"drops":       ["S", "Si"],
		"drop_msg":    "O golem soltou %s com o impacto! (+1 %s)",
		"reactions": {
			"H2O": {
				"damage":  3,
				"message": "A água reage com a lava incandescente — solidificação imediata! Triplo dano!",
				"effect":  "none",
				"flash":   Color(0.3, 0.8, 2.0),
			},
			"CO2": {
				"damage":  2,
				"message": "O CO₂ remove o oxigênio que alimenta o fogo interno do golem! Dano duplo + stun!",
				"effect":  "stun",
				"flash":   Color(0.7, 0.8, 2.0),
			},
			"SO2": {
				"damage":  -1,
				"message": "O golem absorve o SO₂ — enxofre é componente do magma vulcânico! Ele se recupera!",
				"effect":  "heal",
				"flash":   Color(2.0, 2.0, 0.2),
			},
			"NaCl": {
				"damage":  1,
				"message": "O cloreto de sódio reage com os minerais basálticos do golem!",
				"effect":  "none",
				"flash":   Color(2.0, 1.5, 1.0),
			},
			"HCl": {
				"damage":  1,
				"message": "O ácido clorídrico corrói a superfície rochosa do golem!",
				"effect":  "none",
				"flash":   Color(0.5, 2.0, 0.3),
			},
			"NaOH": {
				"damage":  1,
				"message": "A base forte reage com os óxidos metálicos do golem!",
				"effect":  "none",
				"flash":   Color(0.8, 0.5, 2.0),
			},
		}
	}
}

# ── UI refs ────────────────────────────────────────────────────────────────────
var _boss_hp_bar     : ProgressBar
var _player_hp_bar   : ProgressBar
var _boss_sprite       : Control   # TextureRect se tiver sprite, ColorRect se não
var _boss_anim_frames  : Array[AtlasTexture] = []
var _boss_anim_idx     : int = 0
var _boss_name_lbl   : Label
var _dialog_lbl      : Label
var _compound_row    : HBoxContainer   # botões dos compostos disponíveis
var _elem_row        : HBoxContainer   # inventário de elementos (craft panel)
var _slot_row        : HBoxContainer   # slots de crafting
var _craft_panel_node: Control         # painel colapsível de crafting
var _attack_btn      : Button
var _mix_toggle_btn  : Button
var _hint_panel      : Control         # popup de dica (ℹ)
var _hint_text_lbl   : Label           # label de texto dentro do popup
var _no_compound_lbl : Label           # aviso "Sem compostos"

# ── State ──────────────────────────────────────────────────────────────────────
var _boss_data        : Dictionary = {}
var _boss_hp          : int = 0
var _boss_max_hp      : int = 0
var _boss_stunned     : bool = false
var _battle_compounds : Dictionary = {}   # compound_id -> usos restantes
var _selected_compound: String = ""
var _craft_panel_open : bool = false
var _slots            : Array = [{}, {}, {}, {}]
var _busy             : bool = false
var _battle_over      : bool = false

func _ready() -> void:
	layer        = 25
	visible      = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

# ── Build UI ───────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.10, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	bg.add_child(root)

	# ─ HP bars ────────────────────────────────────────────────────────────────
	var top_mc := MarginContainer.new()
	top_mc.add_theme_constant_override("margin_left",   40)
	top_mc.add_theme_constant_override("margin_right",  40)
	top_mc.add_theme_constant_override("margin_top",    14)
	top_mc.add_theme_constant_override("margin_bottom",  8)
	root.add_child(top_mc)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 40)
	top_mc.add_child(hp_row)

	# Kael (esquerda) — corresponde ao sprite do player no campo (bottom-left)
	var player_vb := VBoxContainer.new()
	player_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(player_vb)

	var player_name_lbl := Label.new()
	player_name_lbl.text = "Kael"
	player_name_lbl.add_theme_font_size_override("font_size", 22)
	player_name_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	player_vb.add_child(player_name_lbl)

	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.custom_minimum_size = Vector2(0, 20)
	_player_hp_bar.show_percentage = false
	var player_fill := StyleBoxFlat.new()
	player_fill.bg_color = Color(0.2, 0.75, 0.25)
	_player_hp_bar.add_theme_stylebox_override("fill", player_fill)
	player_vb.add_child(_player_hp_bar)

	# Boss (direita) — corresponde ao sprite do boss no campo (top-right)
	var boss_vb := VBoxContainer.new()
	boss_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(boss_vb)

	_boss_name_lbl = Label.new()
	_boss_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_boss_name_lbl.add_theme_font_size_override("font_size", 22)
	_boss_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.2))
	boss_vb.add_child(_boss_name_lbl)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.custom_minimum_size = Vector2(0, 20)
	_boss_hp_bar.show_percentage = false
	var boss_fill := StyleBoxFlat.new()
	boss_fill.bg_color = Color(0.85, 0.2, 0.1)
	_boss_hp_bar.add_theme_stylebox_override("fill", boss_fill)
	boss_vb.add_child(_boss_hp_bar)

	# ─ Campo de batalha ───────────────────────────────────────────────────────
	var field := HBoxContainer.new()
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.add_theme_constant_override("separation", 0)
	root.add_child(field)

	var player_side := Control.new()
	player_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(player_side)

	var player_sprite := ColorRect.new()
	player_sprite.color = Color(0.3, 0.5, 1.0)
	player_sprite.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	player_sprite.offset_left   = 80
	player_sprite.offset_right  = 180
	player_sprite.offset_top    = -150
	player_sprite.offset_bottom = 0
	player_side.add_child(player_sprite)

	var p_lbl := Label.new()
	p_lbl.text = "Kael"
	p_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	p_lbl.offset_left   = 80
	p_lbl.offset_right  = 180
	p_lbl.offset_top    = 4
	p_lbl.offset_bottom = 26
	p_lbl.add_theme_font_size_override("font_size", 16)
	p_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	player_side.add_child(p_lbl)

	var boss_side := Control.new()
	boss_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(boss_side)

	var tr := TextureRect.new()
	tr.name = "BossSprite"
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.offset_left   = -320
	tr.offset_right  = -60
	tr.offset_top    = 10
	tr.offset_bottom = 210
	tr.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode   = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	boss_side.add_child(tr)
	_boss_sprite = tr

	# ─ Caixa de diálogo ───────────────────────────────────────────────────────
	var dialog_bg := ColorRect.new()
	dialog_bg.color = Color(0.08, 0.07, 0.16, 0.97)
	dialog_bg.custom_minimum_size = Vector2(0, 66)
	root.add_child(dialog_bg)

	var dialog_mc := MarginContainer.new()
	dialog_mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog_mc.add_theme_constant_override("margin_left",   30)
	dialog_mc.add_theme_constant_override("margin_right",  30)
	dialog_mc.add_theme_constant_override("margin_top",    10)
	dialog_mc.add_theme_constant_override("margin_bottom", 10)
	dialog_bg.add_child(dialog_mc)

	_dialog_lbl = Label.new()
	_dialog_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_lbl.add_theme_font_size_override("font_size", 22)
	_dialog_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
	dialog_mc.add_child(_dialog_lbl)

	# ─ Painel de ação ─────────────────────────────────────────────────────────
	var action_panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.05, 0.13, 0.99)
	action_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(action_panel)

	var action_mc := MarginContainer.new()
	action_mc.add_theme_constant_override("margin_left",   20)
	action_mc.add_theme_constant_override("margin_right",  20)
	action_mc.add_theme_constant_override("margin_top",    10)
	action_mc.add_theme_constant_override("margin_bottom", 10)
	action_panel.add_child(action_mc)

	var action_vb := VBoxContainer.new()
	action_vb.add_theme_constant_override("separation", 8)
	action_mc.add_child(action_vb)

	# Linha 1 — compostos disponíveis ─────────────────────────────────────────
	var comp_header := HBoxContainer.new()
	comp_header.add_theme_constant_override("separation", 8)
	action_vb.add_child(comp_header)

	var comp_lbl := Label.new()
	comp_lbl.text = "Compostos:"
	comp_lbl.add_theme_font_size_override("font_size", 18)
	comp_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.8))
	comp_lbl.custom_minimum_size = Vector2(110, 0)
	comp_header.add_child(comp_lbl)

	_compound_row = HBoxContainer.new()
	_compound_row.add_theme_constant_override("separation", 8)
	_compound_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comp_header.add_child(_compound_row)

	_no_compound_lbl = Label.new()
	_no_compound_lbl.text = "Nenhum — use Misturar para criar um!"
	_no_compound_lbl.add_theme_font_size_override("font_size", 18)
	_no_compound_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	_no_compound_lbl.visible = false
	_compound_row.add_child(_no_compound_lbl)

	# Linha 2 — botões de ação ────────────────────────────────────────────────
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	action_vb.add_child(action_row)

	# Botão Misturar (toggle)
	_mix_toggle_btn = Button.new()
	_mix_toggle_btn.text = "Misturar ▼"
	_mix_toggle_btn.add_theme_font_size_override("font_size", 20)
	_mix_toggle_btn.pressed.connect(_on_toggle_craft_panel)
	action_row.add_child(_mix_toggle_btn)

	# Botão ℹ (dica circular)
	var hint_btn := Button.new()
	hint_btn.text = " ℹ "
	hint_btn.add_theme_font_size_override("font_size", 22)
	hint_btn.custom_minimum_size = Vector2(46, 46)
	hint_btn.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	hint_btn.pressed.connect(_on_hint_pressed)
	action_row.add_child(hint_btn)

	# Espaço
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(spacer)

	# Botão Atacar
	_attack_btn = Button.new()
	_attack_btn.text = "Selecione um composto"
	_attack_btn.add_theme_font_size_override("font_size", 20)
	_attack_btn.disabled = true
	_attack_btn.pressed.connect(_on_attack_pressed)
	action_row.add_child(_attack_btn)

	# Linha 3 — painel de crafting (colapsível, começa oculto) ─────────────────
	_craft_panel_node = _build_craft_panel()
	_craft_panel_node.visible = false
	action_vb.add_child(_craft_panel_node)

	# ─ Popup de dica (ℹ) ──────────────────────────────────────────────────────
	_hint_panel = _build_hint_panel()
	_hint_panel.visible = false
	bg.add_child(_hint_panel)

func _build_craft_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 6)

	var sep := HSeparator.new()
	panel.add_child(sep)

	# Linha elementos
	var elem_header := HBoxContainer.new()
	elem_header.add_theme_constant_override("separation", 8)
	panel.add_child(elem_header)

	var elem_lbl := Label.new()
	elem_lbl.text = "Elementos:"
	elem_lbl.add_theme_font_size_override("font_size", 18)
	elem_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.8))
	elem_lbl.custom_minimum_size = Vector2(110, 0)
	elem_header.add_child(elem_lbl)

	_elem_row = HBoxContainer.new()
	_elem_row.add_theme_constant_override("separation", 8)
	_elem_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elem_header.add_child(_elem_row)

	# Linha slots + criar
	var slot_header := HBoxContainer.new()
	slot_header.add_theme_constant_override("separation", 8)
	panel.add_child(slot_header)

	var slot_lbl := Label.new()
	slot_lbl.text = "Slots:"
	slot_lbl.add_theme_font_size_override("font_size", 18)
	slot_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.8))
	slot_lbl.custom_minimum_size = Vector2(110, 0)
	slot_header.add_child(slot_lbl)

	_slot_row = HBoxContainer.new()
	_slot_row.add_theme_constant_override("separation", 8)
	_slot_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_header.add_child(_slot_row)

	for i: int in 4:
		var slot_btn := Button.new()
		slot_btn.text = "[  ]"
		slot_btn.add_theme_font_size_override("font_size", 20)
		slot_btn.custom_minimum_size = Vector2(80, 0)
		slot_btn.pressed.connect(_on_slot_clicked.bind(i))
		_slot_row.add_child(slot_btn)

	var criar_btn := Button.new()
	criar_btn.text = "Criar ▶"
	criar_btn.add_theme_font_size_override("font_size", 20)
	criar_btn.pressed.connect(_on_craft_pressed)
	slot_header.add_child(criar_btn)

	return panel

func _build_hint_panel() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.07, 0.18, 0.98)
	panel.offset_left   = 280
	panel.offset_top    = 150
	panel.offset_right  = 1000
	panel.offset_bottom = 520
	overlay.add_child(panel)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_left",   30)
	mc.add_theme_constant_override("margin_right",  30)
	mc.add_theme_constant_override("margin_top",    24)
	mc.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(mc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	mc.add_child(vb)

	var title := Label.new()
	title.text = "ℹ  Dica do Cientista"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	vb.add_child(title)

	var sep := HSeparator.new()
	vb.add_child(sep)

	var hint_lbl := Label.new()
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_lbl.add_theme_font_size_override("font_size", 22)
	hint_lbl.add_theme_color_override("font_color", Color(0.92, 0.90, 1.0))
	_hint_text_lbl = hint_lbl
	vb.add_child(hint_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)

	var close_btn := Button.new()
	close_btn.text = "Fechar"
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.pressed.connect(func() -> void: _hint_panel.visible = false)
	vb.add_child(close_btn)

	return overlay

# ── API pública ────────────────────────────────────────────────────────────────
func show_battle(boss_id: String) -> void:
	_boss_data = BOSSES.get(boss_id, {})
	if _boss_data.is_empty():
		return

	_boss_max_hp      = _boss_data["max_hp"]
	_boss_hp          = _boss_max_hp
	_boss_stunned     = false
	_slots            = [{}, {}, {}, {}]
	_selected_compound= ""
	_craft_panel_open = false
	_busy             = false
	_battle_over      = false

	# Compostos disponíveis = o que o player já criou no jogo
	_battle_compounds.clear()
	for cid: String in GameState.discovered_compounds:
		_battle_compounds[cid] = _battle_compounds.get(cid, 0) + 1

	_boss_hp_bar.max_value   = _boss_max_hp
	_boss_hp_bar.value       = _boss_max_hp
	_player_hp_bar.max_value = GameState.player_max_health
	_player_hp_bar.value     = GameState.player_health

	_boss_name_lbl.text = _boss_data["name"]
	# Carrega sprite do boss (ou usa cor de fallback)
	var sprite_path: String = _boss_data.get("sprite", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		_start_boss_animation(sprite_path,
			int(_boss_data.get("sprite_cols", 1)),
			int(_boss_data.get("sprite_rows", 1)))
	else:
		var draw_mode: String = _boss_data.get("draw_mode", "")
		if draw_mode == "virus_proc":
			var parent := _boss_sprite.get_parent()
			_boss_sprite.queue_free()
			var vbv := VirusBossVisual.new()
			vbv.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			vbv.offset_left   = -320
			vbv.offset_right  = -60
			vbv.offset_top    = 10
			vbv.offset_bottom = 210
			parent.add_child(vbv)
			_boss_sprite = vbv
		else:
			var img := Image.create(1, 1, false, Image.FORMAT_RGB8)
			img.fill(Color.WHITE)
			(_boss_sprite as TextureRect).texture = ImageTexture.create_from_image(img)
			(_boss_sprite as TextureRect).modulate = _boss_data.get("color", Color.WHITE)

	# Atualiza texto de dica no popup
	_hint_text_lbl.text = _boss_data.get("hint_detail", _boss_data.get("hint", ""))

	_attack_btn.text     = "Selecione um composto"
	_attack_btn.disabled = true
	_craft_panel_node.visible = false
	_hint_panel.visible       = false

	_refresh_compound_buttons()
	_refresh_element_buttons()
	_refresh_slots_ui()

	visible = true
	get_tree().paused = true

	_set_dialog(_boss_data["intro"])
	await get_tree().create_timer(2.2).timeout
	_set_dialog(_boss_data["hint"])
	await get_tree().create_timer(2.5).timeout

	# Se não tem elementos para craftar E não tem compostos, dá drops gratuitos iniciais
	var has_elements := false
	for _el: String in GameState.collected_elements:
		if int(GameState.collected_elements[_el]) > 0:
			has_elements = true
			break
	if _battle_compounds.is_empty() and not has_elements:
		var smart_recipe: String = _boss_data.get("smart_drop_recipe", "")
		if smart_recipe != "":
			var r := ElementDatabase.get_recipe(smart_recipe)
			var ings: Dictionary = r.get("ingredients", {})
			for el: String in ings:
				GameState.collect_element(el, int(ings[el]))
			_set_dialog("O %s liberou elementos ao entrar no campo de batalha! Agora você pode criar compostos!" % _boss_data["name"])
			await get_tree().create_timer(2.0).timeout
		_refresh_element_buttons()

	# Se não tem compostos disponíveis, abre o painel de mistura automaticamente
	if _battle_compounds.is_empty():
		_craft_panel_open = true
		_craft_panel_node.visible = true
		_mix_toggle_btn.text = "Misturar ▲"
		_refresh_element_buttons()
		_refresh_slots_ui()
		_set_dialog("Você não tem compostos! Use os elementos abaixo para criar um.")
	else:
		_set_dialog("O que você vai fazer?")

# ── Compostos disponíveis ──────────────────────────────────────────────────────
func _refresh_compound_buttons() -> void:
	for c in _compound_row.get_children():
		if c != _no_compound_lbl:
			c.queue_free()

	var has_any := false
	for cid: String in _battle_compounds:
		var count: int = _battle_compounds[cid]
		if count <= 0:
			continue
		has_any = true
		var r       := ElementDatabase.get_recipe(cid)
		var col     := Color(r.get("projectile_color", "#ffffff"))
		var btn     := Button.new()
		btn.text = "%s ×%d" % [cid, count]
		btn.add_theme_font_size_override("font_size", 20)
		btn.custom_minimum_size = Vector2(90, 0)
		# Destaca se selecionado
		if cid == _selected_compound:
			btn.modulate = Color(2.0, 2.0, 0.3)
		else:
			btn.modulate = col
		btn.pressed.connect(_on_compound_selected.bind(cid))
		_compound_row.add_child(btn)

	_no_compound_lbl.visible = not has_any
	if not has_any and _selected_compound != "":
		_selected_compound = ""
		_attack_btn.text     = "Selecione um composto"
		_attack_btn.disabled = true

func _on_compound_selected(cid: String) -> void:
	if _busy or _battle_over:
		return
	_selected_compound   = cid
	_attack_btn.text     = "Atacar com %s ▶" % cid
	_attack_btn.disabled = false
	_refresh_compound_buttons()

# ── Toggle craft panel ─────────────────────────────────────────────────────────
func _on_toggle_craft_panel() -> void:
	if _busy or _battle_over:
		return
	_craft_panel_open = not _craft_panel_open
	_craft_panel_node.visible = _craft_panel_open
	_mix_toggle_btn.text = "Misturar ▲" if _craft_panel_open else "Misturar ▼"
	if _craft_panel_open:
		_refresh_element_buttons()
		_refresh_slots_ui()

# ── Dica ──────────────────────────────────────────────────────────────────────
func _on_hint_pressed() -> void:
	_hint_panel.visible = not _hint_panel.visible

# ── Inventário de elementos (craft panel) ─────────────────────────────────────
func _refresh_element_buttons() -> void:
	for c in _elem_row.get_children():
		c.queue_free()

	var pending: Dictionary = {}
	for s: Dictionary in _slots:
		if not s.is_empty():
			var sid: String = s.get("id", "")
			pending[sid] = pending.get(sid, 0) + 1

	for el_id: String in GameState.collected_elements:
		var total : int = GameState.collected_elements[el_id]
		var avail : int = total - pending.get(el_id, 0)
		if avail <= 0:
			continue
		var el_data := ElementDatabase.get_element(el_id)
		var col     := Color(el_data.get("color", "#aaaaaa"))
		var btn     := Button.new()
		btn.text = "%s ×%d" % [el_id, avail]
		btn.add_theme_font_size_override("font_size", 20)
		btn.modulate = col
		btn.custom_minimum_size = Vector2(80, 0)
		btn.pressed.connect(_on_elem_btn_pressed.bind(el_id))
		_elem_row.add_child(btn)

func _on_elem_btn_pressed(el_id: String) -> void:
	if _busy or _battle_over:
		return
	for i: int in _slots.size():
		if _slots[i].is_empty():
			_slots[i] = {id = el_id}
			_refresh_element_buttons()
			_refresh_slots_ui()
			return

func _on_slot_clicked(index: int) -> void:
	if _busy or _battle_over or _slots[index].is_empty():
		return
	_slots[index] = {}
	_refresh_element_buttons()
	_refresh_slots_ui()

func _refresh_slots_ui() -> void:
	var btns := _slot_row.get_children()
	for i: int in _slots.size():
		var btn: Button = btns[i]
		if _slots[i].is_empty():
			btn.text = "[  ]"
			btn.modulate = Color.WHITE
		else:
			var sid: String = _slots[i].get("id", "?")
			btn.text = sid
			var el_data := ElementDatabase.get_element(sid)
			btn.modulate = Color(el_data.get("color", "#ffffff"))

# ── Crafting ───────────────────────────────────────────────────────────────────
func _on_craft_pressed() -> void:
	if _busy or _battle_over:
		return

	var items: Array = []
	for s: Dictionary in _slots:
		if not s.is_empty():
			items.append(s.get("id", ""))
	items.sort()

	if items.is_empty():
		_set_dialog("Selecione elementos nos slots para criar um composto!")
		return

	var recipe_id := _find_recipe_by_list(items)
	if recipe_id == "":
		_set_dialog("Esses elementos não formam nenhum composto...")
		return

	# Consome os elementos
	var r := ElementDatabase.get_recipe(recipe_id)
	var ingredients: Dictionary = r.get("ingredients", {})
	if not GameState.consume_elements(ingredients):
		_set_dialog("Elementos insuficientes para esta receita!")
		return

	# Adiciona ao inventário de batalha
	_battle_compounds[recipe_id] = _battle_compounds.get(recipe_id, 0) + 1

	# Auto-seleciona o composto criado
	_on_compound_selected(recipe_id)

	# Fecha o painel
	_craft_panel_open = false
	_craft_panel_node.visible = false
	_mix_toggle_btn.text = "Misturar ▼"

	# Limpa slots
	_slots = [{}, {}, {}, {}]
	_refresh_element_buttons()
	_refresh_slots_ui()

	_set_dialog("Criado: %s! Clique em 'Atacar com %s' para usar!" % [recipe_id, recipe_id])

## Compara receitas pela lista ordenada de IDs.
func _find_recipe_by_list(sorted_items: Array) -> String:
	for rid: String in ElementDatabase.recipes:
		var r := ElementDatabase.get_recipe(rid)
		if r.is_empty():
			continue
		var ings: Dictionary = r.get("ingredients", {})
		var ing_list: Array = []
		for k: String in ings:
			for _j: int in range(int(ings[k])):
				ing_list.append(k)
		ing_list.sort()
		if ing_list == sorted_items:
			return rid
	return ""

# ── Ataque ─────────────────────────────────────────────────────────────────────
func _on_attack_pressed() -> void:
	if _busy or _battle_over or _selected_compound == "":
		return
	if _battle_compounds.get(_selected_compound, 0) <= 0:
		_set_dialog("Você não tem mais %s!" % _selected_compound)
		return

	_busy = true
	_attack_btn.disabled = true
	_mix_toggle_btn.disabled = true

	# Consome 1 uso do composto
	_battle_compounds[_selected_compound] -= 1

	# Busca reação
	var reactions : Dictionary = _boss_data.get("reactions", {})
	var reaction  : Dictionary = reactions.get(_selected_compound, {})
	var dmg       : int    = reaction.get("damage",  0)
	var effect    : String = reaction.get("effect",  "none")
	var msg       : String = reaction.get("message", _boss_data["no_reaction"])
	var flash     : Color  = reaction.get("flash",   Color(2.0, 2.0, 2.0))

	_set_dialog(msg)

	if dmg > 0:
		_boss_hp = max(0, _boss_hp - dmg)
		_boss_hp_bar.value = _boss_hp
		await _flash_boss(flash)
	elif dmg < 0:
		_boss_hp = min(_boss_max_hp, _boss_hp + abs(dmg))
		_boss_hp_bar.value = _boss_hp
		await _flash_boss(flash)

	if effect == "stun":
		_boss_stunned = true

	await get_tree().create_timer(1.2).timeout

	# Boss dropa elemento ao tomar dano positivo (inclusive no golpe final)
	if dmg > 0:
		var drop := _pick_drop()
		if not drop.is_empty():
			var dropped: String = drop["id"]
			var amount: int     = drop["amount"]
			GameState.collect_element(dropped, amount)
			await get_tree().create_timer(0.8).timeout
			var qty_str := " ×%d" % amount if amount > 1 else ""
			_set_dialog(_boss_data["drop_msg"] % [dropped + qty_str, dropped])
			await get_tree().create_timer(1.2).timeout

	if _boss_hp <= 0:
		await _end_battle(true)
		return

	await _boss_attack()

## Escolhe o elemento a dropar e a quantidade.
## Com smart_drop_recipe: dropa o elemento com maior quantidade faltando, dando tudo de uma vez.
## Sem smart_drop_recipe: dropa 1 aleatório da lista drops.
func _pick_drop() -> Dictionary:
	var drops: Array = _boss_data.get("drops", [])
	if drops.is_empty():
		return {}
	var recipe_id: String = _boss_data.get("smart_drop_recipe", "")
	if recipe_id == "":
		return {id = drops[randi() % drops.size()], amount = 1}
	var recipe := ElementDatabase.get_recipe(recipe_id)
	if recipe.is_empty():
		return {id = drops[randi() % drops.size()], amount = 1}
	# Encontra o elemento com maior quantidade ainda faltando
	var ings: Dictionary = recipe.get("ingredients", {})
	var best_el: String = ""
	var best_missing: int = 0
	for el: String in ings:
		var need: int = int(ings[el])
		var have: int = GameState.collected_elements.get(el, 0)
		# slots não subtraem de collected_elements — não contar duas vezes
		var missing_count: int = maxi(0, need - have)
		if missing_count > best_missing:
			best_missing = missing_count
			best_el = el
	if best_el == "" or best_missing == 0:
		# Player já tem tudo — dropa aleatório da lista padrão
		return {id = drops[randi() % drops.size()], amount = 1}
	return {id = best_el, amount = best_missing}

# ── Turno do boss ──────────────────────────────────────────────────────────────
func _boss_attack() -> void:
	if _boss_stunned:
		_boss_stunned = false
		_set_dialog("%s ainda está atordoado e pula o ataque!" % _boss_data["name"])
		await get_tree().create_timer(1.5).timeout
		_next_player_turn()
		return

	var dmg: int = _boss_data.get("attack_dmg", 15)
	GameState.player_health = max(0, GameState.player_health - dmg)
	GameState.health_changed.emit(GameState.player_health, GameState.player_max_health)
	_player_hp_bar.value = GameState.player_health

	_set_dialog("%s (-%d HP)" % [_boss_data["boss_atk"], dmg])
	var tw := create_tween()
	tw.tween_property(_player_hp_bar, "modulate", Color(2.0, 0.2, 0.2), 0.15)
	tw.tween_property(_player_hp_bar, "modulate", Color.WHITE, 0.15)
	await tw.finished
	await get_tree().create_timer(1.2).timeout

	if GameState.player_health <= 0:
		await _end_battle(false)
		return

	_next_player_turn()

func _next_player_turn() -> void:
	_selected_compound = ""
	_attack_btn.text     = "Selecione um composto"
	_attack_btn.disabled = true
	_mix_toggle_btn.disabled = false
	_refresh_compound_buttons()
	_refresh_element_buttons()
	_busy = false
	_set_dialog("O que você vai fazer?")

func _flash_boss(color: Color) -> void:
	if _boss_sprite is VirusBossVisual:
		(_boss_sprite as VirusBossVisual).apply_flash(color)
		await get_tree().create_timer(0.27).timeout
	else:
		var tw := create_tween()
		tw.tween_property(_boss_sprite, "modulate", color, 0.12)
		tw.tween_property(_boss_sprite, "modulate", Color.WHITE, 0.15)
		await tw.finished

# ── Fim de batalha ─────────────────────────────────────────────────────────────
func _end_battle(won: bool) -> void:
	_battle_over = true
	_attack_btn.disabled     = true
	_mix_toggle_btn.disabled = true

	if won:
		_set_dialog(_boss_data["win"])
		for _i: int in 3:
			await _flash_boss(Color(2.0, 0.1, 0.1))
		var tw := create_tween()
		tw.tween_property(_boss_sprite, "modulate", Color(1, 1, 1, 0), 0.5)
		await tw.finished
	else:
		_set_dialog(_boss_data["lose"])

	await get_tree().create_timer(2.5).timeout
	get_tree().paused = false
	visible = false
	battle_finished.emit(won)

func _start_boss_animation(path: String, cols: int, rows: int) -> void:
	var tex: Texture2D = load(path)
	var fw: float = tex.get_width()  / float(cols)
	var fh: float = tex.get_height() / float(rows)
	_boss_anim_frames.clear()
	for row in rows:
		for col in cols:
			var at := AtlasTexture.new()
			at.atlas  = tex
			at.region = Rect2(col * fw, row * fh, fw, fh)
			_boss_anim_frames.append(at)
	(_boss_sprite as TextureRect).texture = _boss_anim_frames[0]
	var t := Timer.new()
	t.wait_time = 0.18
	t.autostart = true
	t.timeout.connect(_next_boss_frame)
	add_child(t)

func _next_boss_frame() -> void:
	if _boss_anim_frames.is_empty() or not is_instance_valid(_boss_sprite):
		return
	_boss_anim_idx = (_boss_anim_idx + 1) % _boss_anim_frames.size()
	(_boss_sprite as TextureRect).texture = _boss_anim_frames[_boss_anim_idx]

func _set_dialog(text: String) -> void:
	_dialog_lbl.text = text
