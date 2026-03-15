extends CanvasLayer
## GameOver — Exibido quando o jogador perde todo HP (GameState.player_died).
## Queda no kill plane ainda faz respawn direto (tratado pelo level).

const MAIN_MENU := "res://scenes/menus/main_menu.tscn"

func _ready() -> void:
	visible = false
	GameState.player_died.connect(_show)

func _show() -> void:
	visible = true
	get_tree().paused = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)
