extends Control
## MainMenu — Tela inicial do jogo.

const LEVEL_01 := "res://scenes/levels/level_01.tscn"

func _ready() -> void:
	get_tree().paused = false

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_01)

func _on_quit_pressed() -> void:
	get_tree().quit()
