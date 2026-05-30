extends EnemyBase
## SlimeSodio — Inimigo básico do Nível 1.
## Fraco a H₂O (dano duplo), imune a NaCl, dropa Na ao morrer.

@onready var _anim : AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	max_health      = 25
	move_speed      = 35.0
	patrol_range    = 56.0
	damage_on_touch = 8
	element_drop    = "Na"
	drop_amount     = 2
	weak_to         = ["H2O"]
	immune_to       = ["NaCl"]
	hp_bar_y        = -42.0
	super._ready()
	_anim.play("walk")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_anim.flip_h = facing_right
	match estate:
		EState.PATROL, EState.CHASE:
			if _anim.animation != "walk": _anim.play("walk")
		EState.HURT:
			if _anim.animation != "hurt": _anim.play("hurt")
	queue_redraw()

# position.y por frame de "death" — alinha a base de cada frame à do "walk"
# (as poças ficam ~6.7px mais altas na folha; valores medidos por pixel).
const _DEATH_OFFY := [3.5, 10.4, 11.2, 10.7]

func _die() -> void:
	estate = EState.DEAD
	set_physics_process(false)
	queue_redraw()   # esconde a barra de vida
	_anim.play("death")
	if not _anim.frame_changed.is_connected(_on_death_frame):
		_anim.frame_changed.connect(_on_death_frame)
	_on_death_frame()   # alinha o frame inicial
	_spawn_curiosity_label()
	died.emit(self)
	_drop_element()
	await _anim.animation_finished
	queue_free()

func _on_death_frame() -> void:
	var f: int = _anim.frame
	if f >= 0 and f < _DEATH_OFFY.size():
		_anim.position.y = _DEATH_OFFY[f]

func _drop_element() -> void:
	if element_drop == "":
		return
	var pickup := PICKUP_SCENE.instantiate()
	pickup.element_id      = element_drop
	pickup.global_position = global_position + Vector2(0, -34)
	get_tree().current_scene.add_child(pickup)

func _spawn_curiosity_label() -> void:
	var lbl := Label.new()
	lbl.text = "Na + H₂O → explosão!"
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.modulate = Color(1, 1, 0)
	lbl.position = global_position + Vector2(-24, -20)
	get_tree().current_scene.add_child(lbl)
	var tween := get_tree().current_scene.create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 18, 1.2)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tween.tween_callback(lbl.queue_free)
