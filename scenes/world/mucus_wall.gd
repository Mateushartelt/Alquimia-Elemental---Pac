extends Node2D
## MucusWall — Obstáculo orgânico que bloqueia a entrada do shaft.
## Destruído por um projétil de HCl. Emite sinal 'dissolved' antes de se remover.

signal dissolved

func _ready() -> void:
	$MucusDetect.area_entered.connect(_on_area_entered)

func _process(_delta: float) -> void:
	# Efeito orgânico: pulsa levemente
	modulate.a = 0.88 + sin(Time.get_ticks_msec() * 0.005) * 0.12

func _on_area_entered(area: Area2D) -> void:
	if area.get("compound_id") == "HCl":
		_dissolve()

func _dissolve() -> void:
	set_process(false)
	$MucusBody/CollisionShape2D.disabled = true
	dissolved.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.6)
	tw.tween_callback(queue_free)
