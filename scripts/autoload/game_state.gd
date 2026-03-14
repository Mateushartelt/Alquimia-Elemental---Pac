extends Node
## GameState — Autoload singleton
## Guarda o estado em tempo real da partida: elementos coletados,
## compostos descobertos, saúde do jogador e progresso de nível.

# ── Sinais ──────────────────────────────────────────────────────────────────
signal element_collected(element_id: String, amount: int)
signal element_consumed(element_id: String, amount: int)
signal compound_created(compound_id: String)
signal health_changed(current: int, maximum: int)
signal player_died()
signal checkpoint_reached(checkpoint_id: String)
signal level_completed(level_id: int)

# ── Estado do Jogador ───────────────────────────────────────────────────────
var player_max_health: int = 100
var player_health: int = 100
var player_position: Vector2 = Vector2.ZERO
var current_level: int = 1
var last_checkpoint_id: String = ""
var last_checkpoint_position: Vector2 = Vector2.ZERO

# ── Inventário de Elementos ─────────────────────────────────────────────────
## { "H": 3, "O": 2, ... }
var collected_elements: Dictionary = {}

# ── Compostos Descobertos ───────────────────────────────────────────────────
var discovered_compounds: Array[String] = []

# ── Composto Ativo (para atirar) ────────────────────────────────────────────
var active_compound: String = ""

# ── Habilidades Desbloqueadas ───────────────────────────────────────────────
var unlocked_abilities: Array[String] = []   # ex: ["double_jump", "dash"]

# ══════════════════════════════════════════════════════════════════════════════
#  Saúde
# ══════════════════════════════════════════════════════════════════════════════
func take_damage(amount: int) -> void:
	player_health = max(0, player_health - amount)
	health_changed.emit(player_health, player_max_health)
	if player_health == 0:
		player_died.emit()

func heal(amount: int) -> void:
	player_health = min(player_max_health, player_health + amount)
	health_changed.emit(player_health, player_max_health)

func set_max_health(new_max: int) -> void:
	player_max_health = new_max
	player_health = min(player_health, player_max_health)
	health_changed.emit(player_health, player_max_health)

# ══════════════════════════════════════════════════════════════════════════════
#  Elementos
# ══════════════════════════════════════════════════════════════════════════════
func collect_element(element_id: String, amount: int = 1) -> void:
	var el := ElementDatabase.get_element(element_id)
	if el.is_empty():
		push_warning("GameState: elemento desconhecido '%s'" % element_id)
		return
	var max_stack: int = int(el.get("max_stack", 9))
	var current: int = int(collected_elements.get(element_id, 0))
	var added: int = min(amount, max_stack - current)
	if added <= 0:
		return
	collected_elements[element_id] = current + added
	element_collected.emit(element_id, added)

func consume_elements(recipe: Dictionary) -> bool:
	## Verifica e consome os elementos de uma receita.
	## Retorna false se não houver quantidade suficiente.
	for element_id in recipe:
		if collected_elements.get(element_id, 0) < recipe[element_id]:
			return false
	for element_id in recipe:
		collected_elements[element_id] -= recipe[element_id]
		element_consumed.emit(element_id, recipe[element_id])
	return true

func get_element_count(element_id: String) -> int:
	return int(collected_elements.get(element_id, 0))

func has_elements_for(recipe_id: String) -> bool:
	var recipe := ElementDatabase.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var ingredients: Dictionary = recipe.get("ingredients", {})
	for el in ingredients:
		if collected_elements.get(el, 0) < ingredients[el]:
			return false
	return true

# ══════════════════════════════════════════════════════════════════════════════
#  Compostos
# ══════════════════════════════════════════════════════════════════════════════
func try_craft(recipe_id: String) -> bool:
	var recipe := ElementDatabase.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var ingredients: Dictionary = recipe.get("ingredients", {})
	if not consume_elements(ingredients):
		return false
	if recipe_id not in discovered_compounds:
		discovered_compounds.append(recipe_id)
	active_compound = recipe_id
	compound_created.emit(recipe_id)
	SaveManager.save_game()
	return true

func set_active_compound(recipe_id: String) -> void:
	if recipe_id == "" or not ElementDatabase.get_recipe(recipe_id).is_empty():
		active_compound = recipe_id

# ══════════════════════════════════════════════════════════════════════════════
#  Progresso
# ══════════════════════════════════════════════════════════════════════════════
func reach_checkpoint(checkpoint_id: String, pos: Vector2) -> void:
	last_checkpoint_id = checkpoint_id
	last_checkpoint_position = pos
	checkpoint_reached.emit(checkpoint_id)
	SaveManager.save_game()

func complete_level(level_id: int) -> void:
	if level_id >= current_level:
		current_level = level_id + 1
	level_completed.emit(level_id)
	SaveManager.save_game()

func unlock_ability(ability_id: String) -> void:
	if ability_id not in unlocked_abilities:
		unlocked_abilities.append(ability_id)

func has_ability(ability_id: String) -> bool:
	return ability_id in unlocked_abilities

# ══════════════════════════════════════════════════════════════════════════════
#  Serialização (chamada pelo SaveManager)
# ══════════════════════════════════════════════════════════════════════════════
func to_dict() -> Dictionary:
	return {
		"player_health": player_health,
		"player_max_health": player_max_health,
		"current_level": current_level,
		"last_checkpoint_id": last_checkpoint_id,
		"last_checkpoint_position": {"x": last_checkpoint_position.x, "y": last_checkpoint_position.y},
		"collected_elements": collected_elements.duplicate(),
		"discovered_compounds": discovered_compounds.duplicate(),
		"active_compound": active_compound,
		"unlocked_abilities": unlocked_abilities.duplicate(),
	}

func from_dict(data: Dictionary) -> void:
	player_health = data.get("player_health", 100)
	player_max_health = data.get("player_max_health", 100)
	current_level = data.get("current_level", 1)
	last_checkpoint_id = data.get("last_checkpoint_id", "")
	var pos_dict: Dictionary = data.get("last_checkpoint_position", {"x": 0.0, "y": 0.0})
	last_checkpoint_position = Vector2(pos_dict.get("x", 0.0), pos_dict.get("y", 0.0))
	collected_elements = data.get("collected_elements", {})
	var dc: Array = data.get("discovered_compounds", [])
	discovered_compounds.assign(dc)
	active_compound = data.get("active_compound", "")
	var ua: Array = data.get("unlocked_abilities", [])
	unlocked_abilities.assign(ua)
	health_changed.emit(player_health, player_max_health)
