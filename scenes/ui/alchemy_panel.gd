class_name AlchemyPanel
extends CanvasLayer
## AlchemyPanel — Modal de combinação de elementos.
## Abre/fecha com Q. Slots locais; consume GameState só ao MISTURAR.

signal panel_opened

const ALL_RECIPES := ["H2O", "SO2", "HCl", "CO2", "NaCl", "NaOH"]

# Cada slot: {} (vazio) | {type: "element"|"compound", id: String}
var _slots: Array = [{}, {}, {}]
var _is_open := false

enum TutStep { NONE = 0, H1 = 1, H2 = 2, ADD_O = 3, MIX = 4 }
var _tut_step: int = TutStep.NONE
var tutorial_unlock  := false  # permite Q durante pausa forçada pelo tutorial
var panel_unlocked   := false  # true após concluir o tutorial H2O — painel sempre acessível

const TUT_TEXTS := {
	TutStep.H1:    "1/3 — Clique em [H]   Hidrogênio — número atômico 1, o mais abundante do universo!",
	TutStep.H2:    "2/3 — Mais um [H]!   H₂O precisa de 2 átomos de Hidrogênio.",
	TutStep.ADD_O: "3/3 — Clique em [O]   Oxigênio — número atômico 8, essencial à respiração!",
	TutStep.MIX:   "H + H + O formam H₂O!   Clique em MISTURAR para criar a molécula da água!",
}

@onready var _panel_root: Control       = $Bg/Panel
@onready var _inv_list: VBoxContainer   = $Bg/Panel/Margin/VBox/HBox/Left/InvList
@onready var _slot0: Button             = $Bg/Panel/Margin/VBox/HBox/Right/Slots/Slot0
@onready var _slot1: Button             = $Bg/Panel/Margin/VBox/HBox/Right/Slots/Slot1
@onready var _slot2: Button             = $Bg/Panel/Margin/VBox/HBox/Right/Slots/Slot2
@onready var _result_label: Label       = $Bg/Panel/Margin/VBox/HBox/Right/ResultLabel
@onready var _mix_btn: Button           = $Bg/Panel/Margin/VBox/HBox/Right/Btns/MixBtn
@onready var _clear_btn: Button         = $Bg/Panel/Margin/VBox/HBox/Right/Btns/ClearBtn
@onready var _bg: ColorRect             = $Bg
@onready var _tut_label: Label          = $Bg/Panel/Margin/VBox/TutorialLabel

func _ready() -> void:
	layer = 10
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mix_btn.pressed.connect(_on_mix)
	_clear_btn.pressed.connect(_on_clear)
	_slot0.pressed.connect(_on_slot_clicked.bind(0))
	_slot1.pressed.connect(_on_slot_clicked.bind(1))
	_slot2.pressed.connect(_on_slot_clicked.bind(2))
	_bg.gui_input.connect(_on_bg_input)
	GameState.element_collected.connect(_on_state_changed)
	GameState.element_consumed.connect(_on_state_changed)
	GameState.compound_created.connect(_on_compound_changed)

	# Connect close button
	var close_btn: Button = $Bg/Panel/Margin/VBox/TitleRow/CloseBtn
	close_btn.pressed.connect(_close)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_alchemy") and not event.is_echo():
		if get_tree().paused and not tutorial_unlock and not _is_open:
			return  # não abre enquanto dialog/pausa ativa (exceto tutorial H2O ou fechar o próprio painel)
		if not tutorial_unlock and not panel_unlocked and not _is_open and not can_craft_anything():
			return  # nada para craftar ainda
		tutorial_unlock = false
		_toggle()
		get_viewport().set_input_as_handled()
	elif _is_open:
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			_close()
		if event is InputEventKey or event is InputEventMouseButton:
			get_viewport().set_input_as_handled()

# ── Abertura / Fechamento ──────────────────────────────────────────────────────
func _toggle() -> void:
	if _is_open:
		_close()
	else:
		_open()

func _open() -> void:
	_is_open = true
	visible  = true
	get_tree().paused = true
	panel_opened.emit()
	_tut_label.visible = false
	_refresh_inventory()
	_refresh_slots_ui()
	_refresh_result()

func _close() -> void:
	if _tut_step != TutStep.NONE:
		return  # não pode fechar durante tutorial
	_on_clear()   # devolve itens pendentes (sem consumir GameState)
	_is_open = false
	visible  = false
	get_tree().paused = false

func _on_bg_input(event: InputEvent) -> void:
	if _tut_step != TutStep.NONE:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed \
			and not _panel_root.get_global_rect().has_point(event.global_position):
		_close()

# ── Inventário ─────────────────────────────────────────────────────────────────
func _refresh_inventory() -> void:
	for c in _inv_list.get_children():
		c.queue_free()

	# Elementos pendentes já nos slots (subtraem do total exibido)
	var pending_els := _pending_elements()
	var pending_cmp := _pending_compounds()

	# Elementos
	for el_id in GameState.collected_elements:
		var total: int = GameState.collected_elements[el_id]
		var in_slot: int = pending_els.get(el_id, 0)
		var avail := total - in_slot
		if avail <= 0:
			continue
		var el_data := ElementDatabase.get_element(el_id)
		var col := Color(el_data.get("color", "#ffffff"))
		var btn := _make_inv_button("%s x%d" % [el_id, avail], col)
		btn.pressed.connect(_on_inv_element_pressed.bind(el_id))
		_inv_list.add_child(btn)

	# Compostos descobertos usáveis como ingredientes
	for cid in GameState.discovered_compounds:
		if cid in pending_cmp:
			continue
		# Só mostra se houver alguma receita que precise desse composto
		if not _compound_is_ingredient(cid):
			continue
		var recipe := ElementDatabase.get_recipe(cid)
		var col    := Color(recipe.get("projectile_color", "#ffffff"))
		var btn    := _make_inv_button(recipe.get("formula", cid), col)
		btn.pressed.connect(_on_inv_compound_pressed.bind(cid))
		_inv_list.add_child(btn)

	# Re-aplicar tutorial se ativo
	if _tut_step != TutStep.NONE:
		_apply_tut_ui()

func _make_inv_button(txt: String, col: Color) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.add_theme_font_size_override("font_size", 24)
	btn.modulate = col
	btn.custom_minimum_size = Vector2(280, 40)
	return btn

func _compound_is_ingredient(cid: String) -> bool:
	for rid in ALL_RECIPES:
		var r := ElementDatabase.get_recipe(rid)
		if r.is_empty(): continue
		if cid in r.get("ingredients", {}):
			return true
	return false

# ── Slots ──────────────────────────────────────────────────────────────────────
func _on_inv_element_pressed(el_id: String) -> void:
	_add_to_slot("element", el_id)

func _on_inv_compound_pressed(cid: String) -> void:
	_add_to_slot("compound", cid)

func _add_to_slot(type: String, id: String) -> void:
	for i in 3:
		if _slots[i].is_empty():
			_slots[i] = {type = type, id = id}
			_refresh_inventory()
			_refresh_slots_ui()
			_refresh_result()
			if _tut_step in [TutStep.H1, TutStep.H2, TutStep.ADD_O]:
				_tut_step += 1
				_apply_tut_ui()
			return

func _on_slot_clicked(index: int) -> void:
	if _slots[index].is_empty():
		return
	_slots[index] = {}
	_refresh_inventory()
	_refresh_slots_ui()
	_refresh_result()

func _refresh_slots_ui() -> void:
	var slot_nodes := [_slot0, _slot1, _slot2]
	for i in 3:
		var btn: Button = slot_nodes[i]
		if _slots[i].is_empty():
			btn.text = "[ ]"
			btn.modulate = Color.WHITE
		else:
			var sid: String = _slots[i].get("id", "?")
			btn.text = sid
			btn.modulate = _id_color(sid)

func _id_color(id: String) -> Color:
	var el := ElementDatabase.get_element(id)
	if not el.is_empty():
		return Color(el.get("color", "#ffffff"))
	var r := ElementDatabase.get_recipe(id)
	if not r.is_empty():
		return Color(r.get("projectile_color", "#ffffff"))
	return Color.WHITE

# ── Resultado ─────────────────────────────────────────────────────────────────
func _refresh_result() -> void:
	var rid := _find_matching_recipe()
	_mix_btn.disabled = rid == ""
	if rid != "":
		var r := ElementDatabase.get_recipe(rid)
		_result_label.text = "-> " + r.get("formula", rid)
		_result_label.modulate = Color(r.get("projectile_color", "#ffffff"))
	else:
		_result_label.text = "-> ???"
		_result_label.modulate = Color.GRAY

func _find_matching_recipe() -> String:
	var items: Array = []
	for s in _slots:
		if not s.is_empty():
			items.append(s.get("id", ""))
	if items.is_empty():
		return ""
	items.sort()

	for rid in ALL_RECIPES:
		var r := ElementDatabase.get_recipe(rid)
		if r.is_empty(): continue
		var ings: Dictionary = r.get("ingredients", {})
		var ing_list: Array = []
		for k in ings:
			for _j in range(ings[k]):
				ing_list.append(k)
		ing_list.sort()
		if ing_list == items:
			return rid
	return ""

# ── Misturar ──────────────────────────────────────────────────────────────────
func _on_mix() -> void:
	var rid := _find_matching_recipe()
	if rid == "":
		return
	_tut_step = TutStep.NONE

	# Consumir elementos dos slots
	for s in _slots:
		if s.get("type", "") == "element":
			var el_id: String = s.get("id", "")
			var cur := GameState.get_element_count(el_id)
			GameState.collected_elements[el_id] = maxi(0, cur - 1)
			GameState.element_consumed.emit(el_id, 1)

	# Consumir compostos dos slots
	for s in _slots:
		if s.get("type", "") == "compound":
			var cid: String = s.get("id", "")
			GameState.discovered_compounds.erase(cid)
			if GameState.active_compound == cid:
				GameState.set_active_compound("")

	# Registrar novo composto
	if rid not in GameState.discovered_compounds:
		GameState.discovered_compounds.append(rid)
	GameState.set_active_compound(rid)

	_slots = [{}, {}, {}]
	_close()                               # fecha e despausa PRIMEIRO
	GameState.compound_created.emit(rid)   # depois emite (dialog pode pausar)

# ── Limpar ────────────────────────────────────────────────────────────────────
func _on_clear() -> void:
	_slots = [{}, {}, {}]
	if _is_open:
		_refresh_inventory()
		_refresh_slots_ui()
		_refresh_result()

# ── Helpers ───────────────────────────────────────────────────────────────────
func _pending_elements() -> Dictionary:
	var d := {}
	for s in _slots:
		if s.get("type", "") == "element":
			var id: String = s.get("id", "")
			d[id] = d.get(id, 0) + 1
	return d

func _pending_compounds() -> Array:
	var arr := []
	for s in _slots:
		if s.get("type", "") == "compound":
			arr.append(s.get("id", ""))
	return arr

## Retorna true se o player tem ingredientes suficientes para pelo menos uma receita.
func can_craft_anything() -> bool:
	for rid in ALL_RECIPES:
		var r := ElementDatabase.get_recipe(rid)
		if r.is_empty():
			continue
		var ings: Dictionary = r.get("ingredients", {})
		var ok := true
		for el_id in ings:
			if GameState.collected_elements.get(el_id, 0) < ings[el_id]:
				ok = false
				break
		if ok:
			return true
	return false

func _on_state_changed(_id: String, _amt: int = 0) -> void:
	if _is_open: _refresh_inventory()

func _on_compound_changed(_id: String) -> void:
	if _is_open: _refresh_inventory()

# ── Tutorial guiado ───────────────────────────────────────────────────────────
func start_h2o_tutorial() -> void:
	_tut_step = TutStep.H1
	_slots = [{}, {}, {}]
	_refresh_inventory()
	_refresh_slots_ui()
	_refresh_result()
	_apply_tut_ui()

func _apply_tut_ui() -> void:
	if _tut_step == TutStep.NONE:
		_tut_label.visible  = false
		_mix_btn.modulate   = Color.WHITE
		_clear_btn.disabled = false
		for btn in _inv_list.get_children():
			(btn as Button).modulate = Color.WHITE
			(btn as Button).disabled = false
		return

	_tut_label.visible  = true
	_tut_label.text     = TUT_TEXTS.get(_tut_step, "")
	_clear_btn.disabled = true

	var target := _tut_target_id()
	for btn in _inv_list.get_children():
		var b       := btn as Button
		var btn_id  := b.text.split(" ")[0]
		if btn_id == target:
			b.modulate = Color.YELLOW
			b.disabled = false
		else:
			b.modulate = Color(0.35, 0.35, 0.35)
			b.disabled = true

	_mix_btn.modulate = Color.YELLOW if _tut_step == TutStep.MIX else Color(0.35, 0.35, 0.35)
	_mix_btn.disabled = (_tut_step != TutStep.MIX)

func _tut_target_id() -> String:
	match _tut_step:
		TutStep.H1, TutStep.H2: return "H"
		TutStep.ADD_O:           return "O"
	return ""
