## LevelTileMap — Gera a geometria do nível a partir de um array de blocos.
## Edite TILES para redesenhar o nível sem tocar no .tscn.
##
## Formato de cada entrada: [col_início, linha, largura, altura]
## Tamanho de tile: TILE px × TILE px (16×16)
## Coluna 0 / Linha 0 = canto superior-esquerdo do mundo.
##
## MAPA (6 salas, Hollow Knight style, mundo 3200×1120px):
##   Corredor Hub (x:0-1760,   y:112-368)  — plano do portal ao hub/spawn
##   Corredor Dir (x:1760-3200,y:160-368)  — industrial, longo
##   Sala Alta    (x:640-2800, y:-320-112) — via shaft A e B
##   Boss Room    (x:640-1280, y:-480--320)— dead-end, requer Na+Cl
##   Sala Secreta (x:2896-3200,y:-480--320)— dead-end, via shaft B
##   Underground  (x:0-3200,   y:432-640) — conecta tudo via corredor
##
## Drop holes (80px): col145-150(B) col175-180(C)
## Shaft A (col80-86, x:1280-1376): hub↔sala alta↔boss room
## Shaft B (col175-181, x:2800-2896): corredor↔sala secreta
extends Node2D

const TILE     := 16
const C_SOIL   := Color(0.32, 0.24, 0.15)
const C_ACCENT := Color(0.55, 0.44, 0.28)
const ACCENT_H := 4  # espessura da faixa de destaque no topo (px)

## [col, row, largura_tiles, altura_tiles]
## TILE=16px | col×16=x | row×16=y | row 7=y112 | row 23=y368 | row -20=y-320 | row -30=y-480
const TILES: Array = [
	# ━━ TÚNEL (x:0-800, y:240-368) + HUB (x:800-1760, y:112-368) ━━━━━━━━━━━━
	# Túnel: teto row15=y240 (baixo) | Hub: teto row7=y112 | Chão row23=y368 SÓLIDO
	# Step wall col50 liga tetos | Shaft A gap col80-86 no teto hub
	[50,   7,  30,  2],  # teto hub   col50-80  x:800-1280 (gap shaft A: col80-86)
	[86,   7,  24,  2],  # teto hub dir col86-110 x:1376-1760
	[0,   18,  50,  2],  # teto tunel col0-50   x:0-800    y=288 (baixo, túnel estreito)
	[50,   9,   1,   9], # step wall  col50     x=800      y=144-288 (liga tetos)
	[0,   23, 110,  2],  # chão       col0-110  x:0-1760 SÓLIDO

	# ━━ CORREDOR DIREITO (x:1760-3200, y:160-368) ━━━━━━━━━━━━━━━━━━━━━━━━━━
	# Teto row10=y160 | Chão row23=y368
	# Shaft B gap col175-181 no teto | Drop B col145-150 | Drop C col175-180
	[110, 10,  65,  2],  # teto cor esq  col110-175 x:1760-2800 (gap shaft B)
	[181, 10,  19,  2],  # teto cor dir  col181-200 x:2896-3200
	[110, 23,  35,  2],  # chão cor esq  col110-145 x:1760-2320
	# gap drop B: col145-150 (x:2320-2400, 80px)
	[150, 23,  25,  2],  # chão cor mid  col150-175 x:2400-2800
	# gap drop C: col175-180 (x:2800-2880, 80px)
	[180, 23,  20,  2],  # chão cor dir  col180-200 x:2880-3200
	[200, 10,   1,  16], # parede dir total  col200
	[115, 16,  20,  1],  # plat cor A    x:1840-2160 y=256 (Na, Cl)
	[155, 16,  20,  1],  # plat cor B    x:2480-2800 y=256 (Na, C)

	# ━━ SHAFT A (col80-86, x:1280-1376) y=-320→112 ━━━━━━━━━━━━━━━━━━━━━━━━━
	# Interior 80px — wall-jump para sala alta / boss room
	[80,  -20,  1,  27], # parede esq shaft A  x:1280  y=-320→112
	[86,  -20,  1,  27], # parede dir shaft A  x:1376  y=-320→112

	# ━━ SHAFT B (col175-181, x:2800-2896) y=-320→160 ━━━━━━━━━━━━━━━━━━━━━━━
	# Interior 80px — wall-jump para sala secreta
	[175, -20,  1,  30], # parede esq shaft B  x:2800  y=-320→160
	[181, -20,  1,  30], # parede dir shaft B  x:2896  y=-320→160

	# ━━ SALA ALTA (x:1376-2800, y:-320→112) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	# Teto row-20 col86-175 | Chão = teto hub/corredor (row7/row10)
	[86,  -20,  89,  2], # teto sala alta  col86-175  x:1376-2800  y=-320
	[45,  -17,  10,   1], # plat 1  x:720-880   y=-272
	[62,  -13,  12,   1], # plat 2  x:992-1184  y=-208
	[78,  -17,  10,   1], # plat 3  x:1248-1408 y=-272
	[95,  -13,  12,   1], # plat 4  x:1520-1712 y=-208
	[115, -17,  12,   1], # plat 5  x:1840-2032 y=-272
	[135, -13,  10,   1], # plat 6  x:2160-2320 y=-208
	[152, -17,  12,   1], # plat 7  x:2432-2624 y=-272
	[165, -13,  10,   1], # plat 8  x:2640-2800 y=-208

	# ━━ BOSS ROOM (col40-80, x:640-1280) y=-480→-320 ━━━━━━━━━━━━━━━━━━━━━━━
	# Acesso via shaft A (gap col80-86 no chão)
	[40,  -30,  40,  2],  # teto boss   x:640-1280  y=-480
	[40,  -20,  40,  2],  # chão boss   x:640-1280  y=-320 (gap col80-86 = shaft A topo)
	[40,  -30,   1,  10], # parede esq boss
	[42,  -27,   8,   1], # plat boss A  x:672-800   y=-432
	[53,  -25,  10,   1], # plat boss B  x:848-1008  y=-400
	[65,  -23,  12,   1], # plat boss C  x:1040-1232 y=-368

	# ━━ SALA SECRETA (col181-200, x:2896-3200) y=-480→-320 ━━━━━━━━━━━━━━━━━
	# Acesso via shaft B (gap col175-181 no chão)
	[181, -30,  19,  2],  # teto secreta  x:2896-3200 y=-480
	[181, -20,  19,  2],  # chão secreta  x:2896-3200 y=-320
	[200, -30,   1,  10], # parede dir secreta

	# ━━ UNDERGROUND (x:0-3200, y:432-640) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	# Teto row27=y432 com gaps: col145-150(B) col175-180(C)
	[0,   27,  47,  2],  # teto ug A  col0-47  (sem gap cave)
	[52,  27,  93,  2],  # teto ug B  col52-145
	[150, 27,  25,  2],  # teto ug D  col150-175
	[180, 27,  20,  2],  # teto ug E  col180-200
	[0,   40, 200,  2],  # chão underground  y=640
	[200, 27,   1,  14], # parede dir underground
	[20,  29,   4,  11], # pilar A  x:320-384
	[60,  31,   4,   9], # pilar B  x:960-1024
	[100, 29,   4,  11], # pilar C  x:1600-1664
	[140, 31,   4,   9], # pilar D  x:2240-2304
	[170, 29,   4,  11], # pilar E  x:2720-2784
	[10,  30,   8,   1], # plat ug 1  x:160-288   y=480
	[40,  32,   8,   1], # plat ug 2  x:640-768   y=512
	[75,  30,   8,   1], # plat ug 3  x:1200-1328 y=480
	[115, 32,   8,   1], # plat ug 4  x:1840-1968 y=512
	[155, 30,   8,   1], # plat ug 5  x:2480-2608 y=480
	[185, 32,   8,   1], # plat ug 6  x:2960-3088 y=512

	# ━━ PAREDE ESQ TOTAL ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	[-1, -30,   1,  80], # parede esq  x:-16  y=-480→640
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

	# Visual: fundo
	var bg := ColorRect.new()
	bg.size  = px
	bg.color = C_SOIL
	body.add_child(bg)

	# Visual: faixa de destaque no topo
	var top := ColorRect.new()
	top.size  = Vector2(px.x, ACCENT_H)
	top.color = C_ACCENT
	body.add_child(top)

	add_child(body)
