extends Area2D
## Projectile — Projétil lançado pelo jogador com o composto ativo.
## Instanciado via código; não deve ser colocado manualmente no nível.

@export var compound_id: String = "H2O"
@export var direction: Vector2  = Vector2.RIGHT
@export var speed: float        = 200.0
@export var lifetime: float     = 2.0
@export var is_special: bool    = false

@onready var sprite: ColorRect       = $Sprite
@onready var anim: AnimationPlayer   = $AnimationPlayer
@onready var _anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _timer := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_apply_recipe_visuals()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_timer += delta
	if _timer >= lifetime:
		queue_free()

func _apply_recipe_visuals() -> void:
	var recipe := ElementDatabase.get_recipe(compound_id)
	if recipe.is_empty():
		return
	var color := Color(recipe.get("projectile_color", "#ffffff"))
	sprite.color = color
	var size: float = recipe.get("projectile_size", 6)
	sprite.size = Vector2(size, size)
	sprite.position = -sprite.size / 2.0
	if compound_id == "H2O":
		if is_special:
			_setup_water_spell()
		else:
			_setup_water_ball()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return
	_apply_effect(body)
	queue_free()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("player_hitbox"):
		return
	_apply_effect(area)
	queue_free()

func _apply_effect(target: Node) -> void:
	var recipe := ElementDatabase.get_recipe(compound_id)
	if recipe.is_empty():
		return
	var damage: int = recipe.get("damage", 0)
	var effect: String = recipe.get("effect", "")
	var special: String = recipe.get("special", "")

	# Dano em inimigos
	if target.has_method("take_damage"):
		var final_damage := damage * 3 if is_special else damage
		target.take_damage(final_damage, compound_id)
		GameState.add_charge(25.0)

	# Efeitos especiais de ambiente
	match effect:
		"extinguish_fire":
			if target.is_in_group("fire"):
				target.queue_free()
		"toxic_cloud":
			_spawn_cloud(target.global_position)
		"acid_burn":
			if target.is_in_group("metal_block"):
				target.dissolve()
		"freeze":
			if target.has_method("freeze"):
				target.freeze(2.0)
		"crystal_platform":
			_spawn_crystal(global_position)

	# Especiais extras
	match special:
		"dissolves_sodium":
			if target.is_in_group("sodium") or target.get("element_id") == "Na":
				if target.has_method("dissolve"):
					target.dissolve()
		"dissolves_metal_blocks":
			if target.is_in_group("metal_block"):
				target.queue_free()

func _setup_water_ball() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_speed("fly", 12.0)
	frames.set_animation_loop("fly", true)
	for i in range(1, 13):
		frames.add_frame("fly", load("res://scenes/player/assets/water_ball/water_ball_%02d.png" % i))
	_anim_sprite.sprite_frames = frames
	_anim_sprite.scale  = Vector2(0.02, 0.02)
	_anim_sprite.flip_h = direction.x < 0.0
	_anim_sprite.visible = true
	_anim_sprite.play("fly")
	sprite.visible = false

func _setup_water_spell() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_speed("fly", 12.0)
	frames.set_animation_loop("fly", true)
	for i in range(1, 9):
		frames.add_frame("fly", load("res://scenes/player/assets/water_spell/water_spell_%02d.png" % i))
	_anim_sprite.sprite_frames = frames
	_anim_sprite.scale  = Vector2(0.04, 0.04)
	_anim_sprite.flip_h = direction.x > 0.0
	_anim_sprite.visible = true
	_anim_sprite.play("fly")
	sprite.visible = false

func _spawn_cloud(pos: Vector2) -> void:
	var cloud := ColorRect.new()
	cloud.size = Vector2(24, 16)
	cloud.position = pos - cloud.size / 2.0
	cloud.color = Color(0.8, 0.8, 0.2, 0.5)
	get_tree().current_scene.add_child(cloud)
	var tween := get_tree().current_scene.create_tween()
	tween.tween_property(cloud, "modulate:a", 0.0, 2.0)
	tween.tween_callback(cloud.queue_free)

func _spawn_crystal(pos: Vector2) -> void:
	# Plataforma temporária de cristal de NaCl
	var platform := StaticBody2D.new()
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 8)
	shape_node.shape = shape
	platform.add_child(shape_node)
	var vis := ColorRect.new()
	vis.size = shape.size
	vis.position = -shape.size / 2.0
	vis.color = Color(0.9, 0.9, 1.0, 0.8)
	platform.add_child(vis)
	platform.global_position = pos
	platform.collision_layer = 2
	get_tree().current_scene.add_child(platform)
	# Remove após 8 segundos
	get_tree().create_timer(8.0).timeout.connect(platform.queue_free)
