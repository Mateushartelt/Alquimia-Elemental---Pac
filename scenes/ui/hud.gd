extends CanvasLayer
## HUD — Interface in-game: barra de vida, inventário de elementos e compostos.

class ElementIcon extends Control:
	var element_id : String = ""
	var base_color  : Color  = Color.WHITE

	func _draw() -> void:
		var c := Vector2(9.0, 9.0)
		draw_circle(c, 9.0, Color(base_color.r, base_color.g, base_color.b, 0.25))
		draw_circle(c, 7.0, base_color)
		draw_arc(c, 7.0, 0.0, TAU, 24, Color(0, 0, 0, 0.35), 0.75)
		draw_arc(c, 4.5, 3.5, 5.5, 10, Color(1, 1, 1, 0.5), 1.5)
		var font    := ThemeDB.fallback_font
		var lum     := base_color.get_luminance()
		var txt_col := Color(0.05, 0.05, 0.05) if lum > 0.5 else Color.WHITE
		var x_off   := 7.0 if element_id.length() == 1 else 4.5
		draw_string(font, Vector2(x_off, 13.0), element_id,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 7, txt_col)

@onready var health_bar: ProgressBar       = $MarginContainer/VBox/HealthBar
@onready var health_label: Label           = $MarginContainer/VBox/HealthLabel
@onready var _charge_bar:  ProgressBar     = $MarginContainer/VBox/ChargeBar
@onready var _charge_label: Label          = $MarginContainer/VBox/ChargeLabel
@onready var elements_container: HBoxContainer = $MarginContainer/VBox/ElementsContainer
@onready var _compound_bar: HBoxContainer  = $CompoundBar

var _kill_count: int = 0
var _compound_slots: Dictionary = {}   # compound_id → Panel

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.attacked.connect(_on_player_attacked)
	GameState.health_changed.connect(_on_health_changed)
	GameState.charge_changed.connect(_on_charge_changed)
	GameState.element_collected.connect(_on_elements_changed)
	GameState.element_consumed.connect(_on_elements_changed)
	GameState.compound_created.connect(_on_compound_created)
	GameState.active_compound_changed.connect(func(_id: String) -> void: _rebuild_compound_bar())
	_on_health_changed(GameState.player_health, GameState.player_max_health)
	_on_charge_changed(GameState.charge, GameState.charge_max)
	_update_elements()
	_rebuild_compound_bar()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)
	get_tree().node_added.connect(func(node: Node) -> void:
		if node.is_in_group("enemies") and node.has_signal("died"):
			node.died.connect(_on_enemy_died))

# ─── Vida ────────────────────────────────────────────────────────────────────
func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d/%d" % [current, maximum]
	var ratio := float(current) / float(maximum)
	if ratio > 0.5:
		health_bar.modulate = Color(0.2, 0.9, 0.2)
	elif ratio > 0.25:
		health_bar.modulate = Color(1.0, 0.7, 0.0)
	else:
		health_bar.modulate = Color(1.0, 0.2, 0.2)

# ─── Carga especial ───────────────────────────────────────────────────────────
func _on_charge_changed(current: float, maximum: float) -> void:
	_charge_bar.max_value = maximum
	_charge_bar.value     = current
	var key_hint := " [E]" if _charge_label.visible else ""
	_charge_label.text    = "Especial%s: %d/%d" % [key_hint, int(current), int(maximum)]
	_charge_bar.modulate  = Color(0.4, 0.8, 1.0) if current >= maximum else Color(0.27, 0.53, 1.0)

func _on_enemy_died(_enemy: Node) -> void:
	_kill_count += 1
	if _kill_count >= 2:
		_charge_label.text    = "Especial [E]: 0/100"
		_charge_label.visible = true
		_charge_bar.visible   = true

# ─── Elementos coletados ──────────────────────────────────────────────────────
func _on_elements_changed(_id: String, _amt: int = 0) -> void:
	_update_elements()

func _update_elements() -> void:
	for c in elements_container.get_children():
		c.queue_free()
	for element_id in GameState.collected_elements:
		var count: int = GameState.collected_elements[element_id]
		if count <= 0:
			continue
		var el    := ElementDatabase.get_element(element_id)
		var color := Color(el.get("color", "#ffffff"))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		var icon := ElementIcon.new()
		icon.element_id          = element_id
		icon.base_color          = color
		icon.custom_minimum_size = Vector2(22, 22)
		var lbl := Label.new()
		lbl.text = "×%d" % count
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(icon)
		row.add_child(lbl)
		elements_container.add_child(row)

# ─── Barra de compostos ───────────────────────────────────────────────────────
func _on_compound_created(_compound_id: String) -> void:
	_rebuild_compound_bar()
	_flash_active()

func _rebuild_compound_bar() -> void:
	for child in _compound_bar.get_children():
		child.queue_free()
	_compound_slots.clear()

	if GameState.discovered_compounds.is_empty():
		return

	for cid in GameState.discovered_compounds:
		var recipe := ElementDatabase.get_recipe(cid)
		var color  := Color(recipe.get("projectile_color", "#888888"))
		var is_active := cid == GameState.active_compound

		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(64, 56)

		var style := StyleBoxFlat.new()
		style.bg_color = color * Color(0.25, 0.25, 0.25, 1.0)
		style.bg_color.a = 1.0
		style.border_width_left   = 2
		style.border_width_right  = 2
		style.border_width_top    = 2
		style.border_width_bottom = 2
		style.border_color = Color.YELLOW if is_active else Color(0.5, 0.5, 0.5, 0.6)
		style.corner_radius_top_left    = 4
		style.corner_radius_top_right   = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right= 4
		slot.add_theme_stylebox_override("panel", style)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)

		var color_strip := ColorRect.new()
		color_strip.color = color
		color_strip.custom_minimum_size = Vector2(0, 8)
		color_strip.size_flags_horizontal = Control.SIZE_FILL

		var lbl := Label.new()
		lbl.text = recipe.get("formula", cid)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var num_lbl := Label.new()
		num_lbl.text = str(GameState.discovered_compounds.find(cid) + 1)
		num_lbl.add_theme_font_size_override("font_size", 11)
		num_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		vbox.add_child(color_strip)
		vbox.add_child(lbl)
		vbox.add_child(num_lbl)
		slot.add_child(vbox)

		# Click para selecionar
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		var captured_cid := cid
		slot.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				GameState.set_active_compound(captured_cid)
				_rebuild_compound_bar())

		_compound_bar.add_child(slot)
		_compound_slots[cid] = slot

func _on_player_attacked(_compound_id: String, _dir: Vector2, _origin: Vector2) -> void:
	var slot = _compound_slots.get(GameState.active_compound)
	if slot == null:
		return
	var tw := create_tween()
	tw.tween_property(slot, "modulate", Color(0.3, 0.3, 0.3), 0.05)
	tw.tween_property(slot, "modulate", Color.WHITE, 0.55)

func _flash_active() -> void:
	var slot = _compound_slots.get(GameState.active_compound)
	if slot == null:
		return
	var tw := create_tween()
	tw.tween_property(slot, "modulate", Color.YELLOW, 0.1)
	tw.tween_property(slot, "modulate", Color.WHITE, 0.2)
