@tool
class_name PlatformBlock
extends StaticBody2D

const TILE     := 16
const C_FILL   := Color(0.3, 0.15, 0.06, 1.0)
const C_ACCENT := Color(0.9, 0.35, 0.05, 0.9)
const ACCENT_H := 3

const WALL_TEX     := preload("res://scenes/world/assets/wall_tile.png")
const PLATFORM_TEX := preload("res://scenes/world/assets/platform_tile.png")

@export var width_tiles: int = 4:
	set(v):
		width_tiles = maxi(v, 1)
		if is_inside_tree():
			_rebuild()
		queue_redraw()

@export var height_tiles: int = 1:
	set(v):
		height_tiles = maxi(v, 1)
		if is_inside_tree():
			_rebuild()
		queue_redraw()

@export var disappears: bool = false
@export var blink_on:  float = 2.0
@export var blink_off: float = 1.0

func _ready() -> void:
	collision_layer = 2
	collision_mask  = 0
	_rebuild()
	if disappears and not Engine.is_editor_hint():
		_start_blink.call_deferred()

func _start_blink() -> void:
	await get_tree().create_timer(blink_on).timeout
	while is_inside_tree():
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.3)
		await tw.finished
		collision_layer = 0
		await get_tree().create_timer(blink_off).timeout
		collision_layer = 2
		var tw2 := create_tween()
		tw2.tween_property(self, "modulate:a", 1.0, 0.3)
		await tw2.finished
		await get_tree().create_timer(blink_on).timeout

func _rebuild() -> void:
	for child in get_children():
		child.free()

	var px := Vector2(width_tiles * TILE, height_tiles * TILE)

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size     = px
	cs.position = px / 2.0
	cs.shape    = rs
	add_child(cs)

	if Engine.is_editor_hint():
		queue_redraw()
	else:
		_add_visual(px)

func _add_visual(px: Vector2) -> void:
	var tex := PLATFORM_TEX if height_tiles == 1 else WALL_TEX
	var bg  := ColorRect.new()
	bg.size = px
	var mat := ShaderMaterial.new()
	var sh  := Shader.new()
	sh.code = """shader_type canvas_item;
uniform sampler2D wall_tex : repeat_enable, filter_nearest;
uniform vec2 world_offset = vec2(0.0);
uniform vec2 block_px = vec2(16.0);
uniform float tile_size = 64.0;
void fragment() {
	vec2 world_uv = (world_offset + UV * block_px) / tile_size;
	COLOR = texture(wall_tex, world_uv);
}"""
	mat.shader = sh
	mat.set_shader_parameter("wall_tex",     tex)
	mat.set_shader_parameter("world_offset", global_position)
	mat.set_shader_parameter("block_px",     px)
	mat.set_shader_parameter("tile_size",    64.0)
	bg.material = mat
	add_child(bg)

	var top := ColorRect.new()
	top.size  = Vector2(px.x, ACCENT_H)
	top.color = C_ACCENT
	add_child(top)

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var px  := Vector2(width_tiles * TILE, height_tiles * TILE)
	var tex := PLATFORM_TEX if height_tiles == 1 else WALL_TEX
	draw_texture_rect(tex, Rect2(Vector2.ZERO, px), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(px.x, ACCENT_H)), C_ACCENT)
