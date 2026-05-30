extends EnemyBase
## FireSpirit — Inimigo de fogo do Nível 1.
## Fraco a H₂O e CO₂. Explode ao se aproximar do player. Dropa Cl.

@onready var _anim : AnimatedSprite2D = $AnimatedSprite2D

var _exploding := false

func _ready() -> void:
	max_health      = 50
	move_speed      = 60.0
	patrol_range    = 64.0
	damage_on_touch = 0
	element_drop    = "Cl"
	drop_amount     = 1
	weak_to         = ["H2O", "CO2"]
	show_hp_bar     = false   # fire spirit não mostra barra de vida
	super._ready()
	_anim.play("idle")

## Chase persegue o player diretamente com velocidade dobrada
func _chase(_delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node2D = players[0]
	facing_right = p.global_position.x > global_position.x
	velocity.x   = move_speed * 2.0 * (1.0 if facing_right else -1.0)

func _physics_process(delta: float) -> void:
	if _exploding:
		return
	super._physics_process(delta)
	_anim.flip_h = not facing_right
	match estate:
		EState.PATROL: if _anim.animation != "idle": _anim.play("idle")
		EState.CHASE:  if _anim.animation != "walk": _anim.play("walk")
		EState.HURT:   if _anim.animation != "hurt": _anim.play("hurt")

## Só explode quando player está perto EM CHASE; senão ignora toque
func _check_player_touch() -> void:
	if _exploding or estate != EState.CHASE:
		return
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if global_position.distance_to(p.global_position) < 30.0:
			_explode(p)
			return

## Quando em CHASE (prestes a explodir), qualquer hit mata instantaneamente
func take_damage(amount: int, compound_id: String = "") -> void:
	if estate == EState.CHASE or _exploding:
		super.take_damage(current_health, compound_id)
	else:
		super.take_damage(amount, compound_id)

## Morte por projétil à distância — some sem explosão
func _die() -> void:
	if _exploding:
		return
	estate = EState.DEAD
	set_physics_process(false)
	died.emit(self)
	_drop_element()
	queue_free()

## Explosão de proximidade — animação + dano no player
func _explode(player: Node) -> void:
	if _exploding:
		return
	_exploding = true
	estate     = EState.DEAD
	velocity   = Vector2.ZERO
	set_physics_process(false)
	died.emit(self)
	player.receive_damage(20, (player.global_position - global_position).normalized())
	_anim.play("explosion")
	await _anim.animation_finished
	if not is_instance_valid(self):
		return
	var lbl := Label.new()
	lbl.text = "H₂O apaga o fogo!"
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.modulate = Color(1.0, 0.5, 0.0)
	lbl.position = global_position + Vector2(-24, -20)
	get_tree().current_scene.add_child(lbl)
	var tw := get_tree().current_scene.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 18, 1.2)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tw.tween_callback(lbl.queue_free)
	_drop_element()
	queue_free()
