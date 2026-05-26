extends Node2D
## Level02TileMap — Geometria da Caldeira Vulcânica.
## Layout: Metroidvania Lock & Key
##   Zona1 Hub    (x:0-640,  y:112-368) — spawn, H e S, sem O
##   Shaft        (x:224-304, 80px)     — wall jump c/ plataformas de descanso
##   Sala Alta    (x:0-704,  y:-320→-160) — único lugar com O e C
##   Zona2 Lava   (x:672-1440, sem chão) — plataformas sobre lava
##   Zona3 Arena  (x:1440-2400)         — G3 Guardião + portal boss
##
## [col, row, w, h] | TILE=16px | col×16=x | row×16=y

const TILE     := 16
const C_ROCK   := Color(0.18, 0.10, 0.05)   # rocha vulcânica escura
const C_ACCENT := Color(0.65, 0.30, 0.05)   # borda laranja/lava
const ACCENT_H := 4

## [col, row, largura_tiles, altura_tiles]
## row 7=y112 | row 23=y368 | row -10=y-160 | row -20=y-320
## ZONAS: Zona1(col0-40) | Barreira(col40-42) | Zona2(col42-90) | Zona3(col90-150)
const TILES: Array = [
	# ━━ SHAFT (x:224-304, 80px) y:-320→304 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[14, -10,  1, 29],  # parede esq shaft  x:224  y:-160→304 (não entra na Sala Alta)
	[19, -10,  1, 29],  # parede dir shaft  x:304  y:-160→304

	# ━━ SALA ALTA (x:0-704, y:-320→-160) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[0,  -20, 44,  2],  # teto           x:0-704   y=-320
	[0,  -20,  1, 10],  # parede esq     x:0       y:-320→-160
	[43, -20,  1, 10],  # parede dir     x:688     y:-320→-160
	[0,  -10, 14,  2],  # chão esq shaft x:0-224   y=-160
	[19, -10, 24,  2],  # chão dir shaft x:304-688 y=-160
	# Plataformas zig-zag (caminho até os pickups de O e C)
	[2,  -18,  8,  1],  # plat I   x:32-160   y=-288
	[11, -16,  4,  1],  # plat J esq  x:176-240  y=-256 (para antes do shaft)
	[20, -16,  4,  1],  # plat J dir  x:320-384  y=-256 (depois do shaft)
	[20, -18,  8,  1],  # plat K   x:320-448  y=-288
	[30, -16,  8,  1],  # plat L   x:480-608  y=-256
	[36, -14,  8,  1],  # plat M   x:576-704  y=-224

	# ━━ ZONA 1 HUB (x:0-640, y:112-368) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[0,   7, 14,  2],   # teto esq shaft  x:0-224   y=112
	[19,  7, 21,  2],   # teto dir shaft  x:304-640 y=112
	[0,  23, 40,  2],   # chão            x:0-640   y=368
	# Plataformas Zona 1
	[4,  19,  8,  1],   # plat A  x:64-192   y=304
	[20, 17, 10,  1],   # plat B  x:320-480  y=272 (fora do shaft)
	[30, 15,  8,  1],   # plat C  x:480-608  y=240

	# ━━ TETO ZONA 2 (x:672-1440, y:112) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	# Sem chão — lava é ColorRect+Area2D em level_02.tscn
	[42,  7, 48,  2],   # teto zona 2  x:672-1440  y=112
	# Plataformas flutuantes sobre lava
	[46, 17,  8,  1],   # plat D  x:736-864   y=272
	[58, 19,  8,  1],   # plat E  x:928-1056  y=304
	[68, 16,  8,  1],   # plat F  x:1088-1216 y=256
	[82, 18,  8,  1],   # plat G  x:1312-1440 y=288

	# ━━ ZONA 3 ARENA (x:1440-2400, y:112-368) ━━━━━━━━━━━━━━━━━━━━━━━━━
	[90,  7, 60,  2],   # teto             x:1440-2400 y=112
	[90, 23, 60,  2],   # chão             x:1440-2400 y=368
	[90,  7,  1, 18],   # parede esq       x:1440 y:112-400
	[150, 7,  1, 18],   # parede dir       x:2400 y:112-400
	# Plataformas arena
	[93, 18, 10,  1],   # plat H  x:1488-1648 y=288
	[107,15, 12,  1],   # plat I  x:1712-1904 y=240
	[120,18, 10,  1],   # plat J  x:1920-2080 y=288
	[136,15, 12,  1],   # plat K  x:2176-2368 y=240
	[148,17,  2,  1],   # plat L  x:2368-2400 y=272

	# ━━ PAREDE ESQ TOTAL ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[-1, -20,  1, 50],  # cobre sala alta + hub
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
