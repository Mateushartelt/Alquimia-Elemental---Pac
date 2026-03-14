extends Node
## SaveManager — Autoload singleton
## Grava e carrega o progresso do jogador em JSON no diretório user://.

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1

func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": GameState.to_dict(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: não foi possível abrir arquivo para escrita: %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("SaveManager: jogo salvo em %s" % SAVE_PATH)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("SaveManager: nenhum save encontrado.")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: não foi possível abrir arquivo para leitura.")
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not parsed is Dictionary:
		push_error("SaveManager: arquivo de save corrompido.")
		return false
	var data := parsed as Dictionary
	var version: int = int(data.get("version", 0))
	if version != SAVE_VERSION:
		push_warning("SaveManager: versão de save incompatível (%d). Iniciando novo jogo." % version)
		return false
	var gs_data: Dictionary = data.get("game_state", {}) as Dictionary
	GameState.from_dict(gs_data)
	print("SaveManager: jogo carregado com sucesso.")
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		print("SaveManager: save deletado.")

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
