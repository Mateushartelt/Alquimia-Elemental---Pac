extends Node2D
## Level03TileMap — Geometria do Complexo Subaquático Viral.
## Layout idêntico ao Level02 com paleta de cores subaquática (azul/teal).
##
## [col, row, w, h] | TILE=16px | col×16=x | row×16=y

const TILE     := 16
const C_ROCK   := Color(0.04, 0.14, 0.22)   # concreto subaquático escuro
const C_ACCENT := Color(0.10, 0.55, 0.65)   # borda teal úmida
const ACCENT_H := 4

## [col, row, largura_tiles, altura_tiles]
## row 7=y112 | row 23=y368 | row -10=y-160 | row -20=y-320
const TILES: Array = [
	# ━━ HUB + CORREDOR (x:0-2400, y:112-368) ━━━━━━━━━━━━━━━━━━━━━━━━━━
	# Teto com gap para shaft (col14-19 = x:224-304)
	[0,    7,  14,  2],  # teto esq     x:0-224    y=112
	[19,   7, 131,  2],  # teto dir     x:304-2400 y=112
	[0,   23, 150,  2],  # chão total   x:0-2400   y=368
	[150,  7,   1,  18], # parede dir   x:2400     y:112-400

	# Plataformas alternadas
	[5,   16,  10,  1],  # plat A  x:80-240    y=256
	[25,  18,  10,  1],  # plat B  x:400-560   y=288
	[45,  15,  10,  1],  # plat C  x:720-880   y=240
	[60,  18,  10,  1],  # plat D  x:960-1120  y=288
	[80,  15,  10,  1],  # plat E  x:1280-1440 y=240
	[100, 18,  10,  1],  # plat F  x:1600-1760 y=288
	[120, 15,  10,  1],  # plat G  x:1920-2080 y=240
	[135, 18,  10,  1],  # plat H  x:2160-2320 y=288

	# ━━ SHAFT (x:224-304, 80px) y:-320→112 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[14, -20,   1,  27], # parede esq shaft  x:224  y=-320→112
	[19, -20,   1,  27], # parede dir shaft  x:304  y=-320→112

	# ━━ SALA ALTA (x:0-1600, y:-320→-160) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[0,  -20, 100,  2],  # teto         x:0-1600   y=-320
	[0,  -10,  14,  2],  # chão esq     x:0-224    y=-160 (gap shaft)
	[19, -10,  81,  2],  # chão dir     x:304-1600 y=-160
	[100,-20,   1,  10], # parede dir   x:1600     y=-320→-160

	# Plataformas na Sala Alta
	[3,  -18,  10,  1],  # plat I   x:48-208    y=-288
	[20, -16,  10,  1],  # plat J   x:320-480   y=-256
	[38, -14,  10,  1],  # plat K   x:608-768   y=-224
	[55, -17,  10,  1],  # plat L   x:880-1040  y=-272
	[70, -15,  10,  1],  # plat M   x:1120-1280 y=-240
	[83, -13,  10,  1],  # plat N   x:1328-1488 y=-208

	# ━━ PAREDE ESQ TOTAL (x:-16, y:-320→480) ━━━━━━━━━━━━━━━━━━━━━━━━━━
	[-1, -20,   1,  50], # cobre sala alta + hub
]

func _ready() -> void:
	for block: Array in TILES:
		_spawn_block(block[0], block[1], block[2], block[3])

func _spawn_block(col: int, row: int, w: int, h: int) -> void:
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

	var bg := ColorRect.new()
	bg.size  = px
	bg.color = C_ROCK
	body.add_child(bg)

	var top := ColorRect.new()
	top.size  = Vector2(px.x, ACCENT_H)
	top.color = C_ACCENT
	body.add_child(top)

	add_child(body)
