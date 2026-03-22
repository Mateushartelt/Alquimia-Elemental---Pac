extends Node2D
## FireWall — Obstáculo de fogo que bloqueia passagem.
## Destruído por um projétil de H₂O. Emite sinal 'extinguished' antes de se remover.

signal extinguished

func _ready() -> void:
	$FireDetect.area_entered.connect(_on_area_entered)

func _process(_delta: float) -> void:
	# Efeito de chamas: pulsa opacidade levemente
	modulate.a = 0.85 + sin(Time.get_ticks_msec() * 0.008) * 0.15

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
