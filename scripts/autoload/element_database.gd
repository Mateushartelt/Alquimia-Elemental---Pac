extends Node
## ElementDatabase — Autoload singleton
## Carrega elements.json e recipes.json e expõe consultas.

var elements: Dictionary = {}
var recipes: Dictionary = {}

func _ready() -> void:
	_load_json("res://data/elements.json", "elements", elements)
	_load_json("res://data/recipes.json", "recipes", recipes)

func _load_json(path: String, key: String, target: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ElementDatabase: não foi possível abrir %s" % path)
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_error("ElementDatabase: JSON inválido em %s" % path)
		return
	var parsed_dict := parsed as Dictionary
	if not parsed_dict.has(key):
		push_error("ElementDatabase: chave '%s' não encontrada em %s" % [key, path])
		return
	target.merge(parsed_dict[key] as Dictionary)

# ── Consultas de Elementos ──────────────────────────────────────────────────

func get_element(id: String) -> Dictionary:
	return elements.get(id, {}) as Dictionary

func get_element_color(id: String) -> Color:
	var el := get_element(id)
	if el.is_empty():
		return Color.WHITE
	return Color(str(el.get("color", "#ffffff")))

func get_elements_for_level(level: int) -> Array[String]:
	var result: Array[String] = []
	for id in elements:
		if (elements[id] as Dictionary).get("unlocked_in_level", 99) <= level:
			result.append(id)
	return result

# ── Consultas de Receitas ───────────────────────────────────────────────────

func get_recipe(id: String) -> Dictionary:
	return recipes.get(id, {}) as Dictionary

func find_recipe(ingredients: Dictionary) -> String:
	## Retorna o ID da receita que casa exatamente com os ingredientes,
	## ou "" se nenhuma casa.
	for recipe_id in recipes:
		var req: Dictionary = (recipes[recipe_id] as Dictionary).get("ingredients", {}) as Dictionary
		if req == ingredients:
			return recipe_id
	return ""

func get_recipes_for_level(level: int) -> Array[String]:
	var result: Array[String] = []
	for id in recipes:
		if (recipes[id] as Dictionary).get("unlocked_in_level", 99) <= level:
			result.append(id)
	return result
