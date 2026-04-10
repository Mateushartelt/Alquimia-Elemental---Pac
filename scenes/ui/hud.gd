extends CanvasLayer
## HUD — Interface in-game: barra de vida, inventário de elementos e composto ativo.

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

@onready var health_bar: ProgressBar = $MarginContainer/VBox/HealthBar
@onready var health_label: Label     = $MarginContainer/VBox/HealthLabel
@onready var _charge_bar:  ProgressBar = $MarginContainer/VBox/ChargeBar
@onready var _charge_label: Label      = $MarginContainer/VBox/ChargeLabel
@onready var elements_container: HBoxContainer = $MarginContainer/VBox/ElementsContainer

var _kill_count: int = 0
@onready var active_compound_panel: Panel = $ActiveCompound
@onready var active_compound_label: Label = $ActiveCompound/Label
@onready var active_compound_icon: ColorRect = $ActiveCompound/Icon

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.attacked.connect(_on_player_attacked)
	GameState.health_changed.connect(_on_health_changed)
	GameState.charge_changed.connect(_on_charge_changed)
	GameState.element_collected.connect(_on_elements_changed)
	GameState.element_consumed.connect(_on_elements_changed)
	GameState.compound_created.connect(_on_compound_created)
	_on_health_changed(GameState.player_health, GameState.player_max_health)
	_on_charge_changed(GameState.charge, GameState.charge_max)
	_update_elements()
	_update_active_compound()
	# Conecta ao died de todos os inimigos presentes e futuros
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)
	get_tree().node_added.connect(func(node: Node) -> void:
		if node.is_in_group("enemies") and node.has_signal("died"):
			node.died.connect(_on_enemy_died))

func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d/%d" % [current, maximum]
	# Muda cor da barra conforme HP
	var ratio := float(current) / float(maximum)
	if ratio > 0.5:
		health_bar.modulate = Color(0.2, 0.9, 0.2)
	elif ratio > 0.25:
		health_bar.modulate = Color(1.0, 0.7, 0.0)
	else:
		health_bar.modulate = Color(1.0, 0.2, 0.2)

func _on_charge_changed(current: float, maximum: float) -> void:
	_charge_bar.max_value = maximum
	_charge_bar.value     = current
	var key_hint := " [E]" if _charge_label.visible else ""
	_charge_label.text    = "Especial%s: %d/%d" % [key_hint, int(current), int(maximum)]
	_charge_bar.modulate  = Color(0.4, 0.8, 1.0) if current >= maximum else Color(0.27, 0.53, 1.0)

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

func _on_enemy_died(_enemy: Node) -> void:
	_kill_count += 1
	if _kill_count >= 2:
		_charge_label.text    = "Especial [E]: 0/100"
		_charge_label.visible = true
		_charge_bar.visible   = true

func _on_compound_created(compound_id: String) -> void:
	_update_active_compound()
	_flash_active()

func _update_active_compound() -> void:
	var cid := GameState.active_compound
	if cid == "":
		active_compound_panel.visible = false
		return
	active_compound_panel.visible = true
	var recipe := ElementDatabase.get_recipe(cid)
	active_compound_label.text = recipe.get("formula", cid)
	active_compound_icon.color = Color(recipe.get("projectile_color", "#ffffff"))

func _on_player_attacked(_compound_id: String, _dir: Vector2, _origin: Vector2) -> void:
	if not active_compound_panel.visible:
		return
	var tw := create_tween()
	tw.tween_property(active_compound_panel, "modulate", Color(0.3, 0.3, 0.3), 0.05)
	tw.tween_property(active_compound_panel, "modulate", Color.WHITE, 0.55)

func _flash_active() -> void:
	var tween := create_tween()
	tween.tween_property(active_compound_panel, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(active_compound_panel, "modulate", Color.WHITE, 0.2)
