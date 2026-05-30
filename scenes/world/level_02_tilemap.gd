@tool
extends Node2D
## Level02TileMap — Geometria estrutural da Caldeira Vulcânica.
## Apenas paredes, chão e teto. Plataformas são PlatformBlock nodes em level_02.tscn.

const TILE     := 16
const C_ACCENT := Color(0.9, 0.35, 0.05, 0.7)
const ACCENT_H := 3

const WALL_TEX     := preload("res://scenes/world/assets/wall_tile.png")
const PLATFORM_TEX := preload("res://scenes/world/assets/platform_tile.png")
const LAVA_TEX     := preload("res://scenes/world/assets/lava_tile.png")

## [col, row, w, h, tex_type]  tex_type: 0=auto  1=lava  (omitir = 0)
## col×16=x  |  row×16=y
const TILES: Array = [
	# ━━ SHAFT (x:224-304) y:-160→304  — lava nas paredes ━━━━━━━━━━━━━━━━━━━━
	[14, -10,  1, 29, 1],  # parede esq shaft  x:224  y:-160→304 (entra no hub)
	[19, -10,  1, 29, 1],  # parede dir shaft  x:304  y:-160→304 (entra no hub)

	# ━━ SALA ALTA (x:0-704, y:-320→-160) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[0,  -20, 44,  2],  # teto           x:0-704   y=-320
	[0,  -20,  1, 10],  # parede esq     x:0       y:-320→-160
	[43, -20,  1, 10],  # parede dir     x:688     y:-320→-160
	[0,  -10, 14,  2],  # chão esq shaft x:0-224   y=-160
	[19, -10, 24,  2],  # chão dir shaft x:304-688 y=-160

	# ━━ ZONA 1 HUB (x:0-640, y:112-368) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[0,   7, 14,  2],   # teto esq shaft  x:0-224   y=112
	[19,  7, 21,  2],   # teto dir shaft  x:304-640 y=112
	[0,  23, 40,  2],   # chão            x:0-640   y=368

	# ━━ TETO ZONA 2 (x:640-1440, y:112) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[40,  7, 50,  2],   # teto zona 2  x:640-1440  y=112 (fecha gap sobre a barreira)

	# ━━ ZONA 3 ARENA (x:1440-2400, y:112-368) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[90,  7, 60,  2],   # teto             x:1440-2400 y=112
	[90, 23, 60,  2],   # chão             x:1440-2400 y=368
	[150, 7,  1, 18],   # parede dir       x:2400 y:112-400

	# ━━ PAREDE ESQ TOTAL ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[-1, -20,  1, 50],
]

var _wall_shader: Shader
var _plat_shader: Shader

func _ready() -> void:
	var code := """
shader_type canvas_item;
uniform sampler2D wall_tex : repeat_enable, filter_nearest;
uniform vec2 world_offset = vec2(0.0);
uniform vec2 block_px = vec2(16.0);
uniform float tile_size = 64.0;
void fragment() {
	vec2 world_uv = (world_offset + UV * block_px) / tile_size;
	COLOR = texture(wall_tex, world_uv);
}
"""
	_wall_shader = Shader.new()
	_wall_shader.code = code
	_plat_shader = Shader.new()
	_plat_shader.code = code

	for block: Array in TILES:
		_spawn_block(block[0], block[1], block[2], block[3],
			block[4] if block.size() > 4 else 0)

func _spawn_block(col: int, row: int, w: int, h: int, tex_type: int = 0) -> void:
	var px  := Vector2(w * TILE, h * TILE)
	var pos := Vector2(col * TILE, row * TILE)

	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask  = 0
	body.position        = pos

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size     = px
	cs.position = px / 2.0
	cs.shape    = rs
	body.add_child(cs)

	var tex: Texture2D
	var shd: Shader
	if tex_type == 1:
		tex = LAVA_TEX
		shd = _wall_shader
	elif h == 1:
		tex = PLATFORM_TEX
		shd = _plat_shader
	else:
		tex = WALL_TEX
		shd = _wall_shader

	var bg := ColorRect.new()
	bg.size = px
	var mat := ShaderMaterial.new()
	mat.shader = shd
	mat.set_shader_parameter("wall_tex", tex)
	mat.set_shader_parameter("world_offset", pos)
	mat.set_shader_parameter("block_px", px)
	mat.set_shader_parameter("tile_size", 64.0)
	bg.material = mat
	body.add_child(bg)

	var top := ColorRect.new()
	top.size  = Vector2(px.x, ACCENT_H)
	top.color = C_ACCENT
	body.add_child(top)

	add_child(body)
