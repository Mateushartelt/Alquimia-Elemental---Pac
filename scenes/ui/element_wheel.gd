extends CanvasLayer
## ElementWheel — Roda de seleção de compostos (aberta com E / botão direito).
## Mostra todos os compostos disponíveis no nível atual.
## Verde = tem ingredientes para craftar. Cinza = não tem.

const SLOT_RADIUS   := 32.0
const SLOT_SIZE     := Vector2(20, 20)
const CENTER        := Vector2(160, 90)

var _slots: Array[Control] = []
var _open := false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.element_collected.connect(_on_inventory_changed)
	GameState.element_consumed.connect(_on_inventory_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_wheel"):
		_open_wheel()
	elif event.is_action_released("open_wheel"):
		_close_wheel()
	elif _open and event.is_action_pressed("wheel_next"):
		_cycle(1)
	elif _open and event.is_action_pressed("wheel_prev"):
		_cycle(-1)

# ════════════════════════════════════════════════════════════════════════════
func _open_wheel() -> void:
	_open = true
	visible = true
	_rebuild_slots()
	get_tree().paused = true

func _close_wheel() -> void:
	_open = false
	visible = false
	get_tree().paused = false

# ════════════════════════════════════════════════════════════════════════════
func _rebuild_slots() -> void:
	for s in _slots:
		s.queue_free()
	_slots.clear()

	# Mostra TODAS as receitas do nível atual (não apenas já descobertas)
	var compounds := ElementDatabase.get_recipes_for_level(GameState.current_level)
	if compounds.is_empty():
		return

	var count := compounds.size()
	for i in count:
		var angle := (TAU / count) * i - PI / 2.0
		var pos := CENTER + Vector2(cos(angle), sin(angle)) * SLOT_RADIUS
		var slot := _make_slot(compounds[i], pos)
		add_child(slot)
		_slots.append(slot)

	_highlight_active()

func _make_slot(recipe_id: String, pos: Vector2) -> Control:
	var recipe := ElementDatabase.get_recipe(recipe_id)
	var craftable := GameState.has_elements_for(recipe_id)
	var base_color := Color(recipe.get("projectile_color", "#ffffff"))
	# Esmaece se não tiver ingredientes
	var display_color := base_color if craftable else base_color.darkened(0.55)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = pos - SLOT_SIZE / 2.0
	panel.size = SLOT_SIZE
	panel.self_modulate = display_color
	panel.set_meta("recipe_id", recipe_id)

	var lbl := Label.new()
	lbl.text = recipe.get("formula", recipe_id)
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(lbl)

	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(func():
		GameState.set_active_compound(recipe_id)
		_close_wheel()
	)
	panel.add_child(btn)

	return panel

func _highlight_active() -> void:
	var active := GameState.active_compound
	for slot in _slots:
		var rid: String = slot.get_meta("recipe_id", "")
		slot.size = SLOT_SIZE * (1.4 if rid == active else 1.0)

# ════════════════════════════════════════════════════════════════════════════
func _cycle(direction: int) -> void:
	var compounds := ElementDatabase.get_recipes_for_level(GameState.current_level)
	if compounds.is_empty():
		return
	var idx := compounds.find(GameState.active_compound)
	# Se não encontrou (active não está na lista), começa do início
	if idx == -1:
		idx = 0
	else:
		idx = (idx + direction) % compounds.size()
	GameState.set_active_compound(compounds[idx])
	_highlight_active()

func _on_inventory_changed(_id: String, _amt: int = 0) -> void:
	if _open:
		_rebuild_slots()
