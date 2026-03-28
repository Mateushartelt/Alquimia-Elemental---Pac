extends CanvasLayer
## HUD — Interface in-game: barra de vida, inventário de elementos e composto ativo.

@onready var health_bar: ProgressBar = $MarginContainer/VBox/HealthBar
@onready var health_label: Label     = $MarginContainer/VBox/HealthLabel
@onready var _charge_bar:  ProgressBar = $MarginContainer/VBox/ChargeBar
@onready var _charge_label: Label      = $MarginContainer/VBox/ChargeLabel
@onready var elements_container: HBoxContainer = $ElementsContainer
@onready var active_compound_panel: Panel = $ActiveCompound
@onready var active_compound_label: Label = $ActiveCompound/Label
@onready var active_compound_icon: ColorRect = $ActiveCompound/Icon

func _ready() -> void:
	GameState.health_changed.connect(_on_health_changed)
	GameState.charge_changed.connect(_on_charge_changed)
	GameState.element_collected.connect(_on_elements_changed)
	GameState.element_consumed.connect(_on_elements_changed)
	GameState.compound_created.connect(_on_compound_created)
	_on_health_changed(GameState.player_health, GameState.player_max_health)
	_on_charge_changed(GameState.charge, GameState.charge_max)
	_update_elements()
	_update_active_compound()

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
	_charge_label.text    = "Especial: %d/%d" % [int(current), int(maximum)]
	_charge_bar.modulate  = Color(0.4, 0.8, 1.0) if current >= maximum else Color(0.27, 0.53, 1.0)

func _on_elements_changed(_id: String, _amt: int = 0) -> void:
	_update_elements()

func _update_elements() -> void:
	# Limpa filhos anteriores
	for c in elements_container.get_children():
		c.queue_free()

	for element_id in GameState.collected_elements:
		var count: int = GameState.collected_elements[element_id]
		if count <= 0:
			continue
		var el := ElementDatabase.get_element(element_id)
		var color := Color(el.get("color", "#ffffff"))

		var container := HBoxContainer.new()
		var icon := ColorRect.new()
		icon.size = Vector2(32, 32)
		icon.color = color
		icon.custom_minimum_size = Vector2(32, 32)

		var lbl := Label.new()
		lbl.text = "%s×%d" % [element_id, count]
		lbl.add_theme_font_size_override("font_size", 24)

		container.add_child(icon)
		container.add_child(lbl)
		elements_container.add_child(container)

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

func _flash_active() -> void:
	var tween := create_tween()
	tween.tween_property(active_compound_panel, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(active_compound_panel, "modulate", Color.WHITE, 0.2)
