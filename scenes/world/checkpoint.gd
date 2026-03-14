extends Area2D
## Checkpoint — Salva posição de respawn e progresso do jogador.
## Visual: ColorRect que muda de cinza → dourado ao ser ativado.

@export var checkpoint_id: String = "cp_01"

@onready var sprite: ColorRect = $Sprite
@onready var anim: AnimationPlayer = $AnimationPlayer

var _activated := false

const COLOR_INACTIVE := Color(0.5, 0.5, 0.5)
const COLOR_ACTIVE   := Color(1.0, 0.85, 0.0)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.color = COLOR_INACTIVE
	# Restaura visual se já estava ativo no save
	if GameState.last_checkpoint_id == checkpoint_id:
		_activate_visual()

func _on_body_entered(body: Node) -> void:
	if _activated:
		return
	if not body.is_in_group("player"):
		return
	_activate(body.global_position)

func _activate(player_pos: Vector2) -> void:
	_activated = true
	GameState.reach_checkpoint(checkpoint_id, player_pos)
	_activate_visual()
	_show_message()

func _activate_visual() -> void:
	sprite.color = COLOR_ACTIVE
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)

func _show_message() -> void:
	var lbl := Label.new()
	lbl.text = "✓ Checkpoint"
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.modulate = COLOR_ACTIVE
	lbl.position = global_position + Vector2(-20, -28)
	get_tree().current_scene.add_child(lbl)
	var tween := get_tree().current_scene.create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 14, 1.5)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.5)
	tween.tween_callback(lbl.queue_free)
