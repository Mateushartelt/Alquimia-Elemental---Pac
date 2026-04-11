extends Node2D
## FireWall — Obstáculo de fogo que bloqueia passagem.
## Destruído por um projétil de H₂O. Emite sinal 'extinguished' antes de se remover.

signal extinguished

func _ready() -> void:
	$FireDetect.area_entered.connect(_on_area_entered)
	$FireBody/CollisionShape2D.disabled = true
	$Visual.hide()
	var p := CPUParticles2D.new()
	p.emitting              = true
	p.amount                = 60
	p.lifetime              = 1.5
	p.randomness            = 0.5
	p.preprocess            = 1.0
	p.local_coords          = true
	p.emission_shape        = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(16.0, 3.0)
	p.position              = Vector2(16.0, 256.0)
	p.direction             = Vector2(0.0, -1.0)
	p.spread                = 22.0
	p.gravity               = Vector2(0.0, 0.0)
	p.initial_velocity_min  = 80.0
	p.initial_velocity_max  = 180.0
	p.scale_amount_min      = 3.0
	p.scale_amount_max      = 7.0
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.1, 1.0))
	grad.set_color(1, Color(0.75, 0.05, 0.0, 0.0))
	p.color_ramp = grad
	add_child(p)

func _process(_delta: float) -> void:
	modulate.a = 0.85 + sin(Time.get_ticks_msec() * 0.007) * 0.15

func _on_area_entered(area: Area2D) -> void:
	if area.get("compound_id") == "H2O":
		_extinguish()

func _extinguish() -> void:
	set_process(false)
	$FireBody/CollisionShape2D.disabled = true
	extinguished.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.8)
	tw.tween_callback(queue_free)
