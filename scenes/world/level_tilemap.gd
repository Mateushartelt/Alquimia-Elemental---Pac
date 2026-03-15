## LevelTileMap — Gera a geometria do nível a partir de um array de blocos.
## Edite TILES para redesenhar o nível sem tocar no .tscn.
##
## Formato de cada entrada: [col_início, linha, largura, altura]
## Tamanho de tile: TILE px × TILE px (16×16)
## Coluna 0 / Linha 0 = canto superior-esquerdo do mundo.
extends Node2D

const TILE     := 16
const C_SOIL   := Color(0.32, 0.24, 0.15)
const C_ACCENT := Color(0.55, 0.44, 0.28)
const ACCENT_H := 4  # espessura da faixa de destaque no topo (px)

## [col, row, largura_tiles, altura_tiles]
## Linha 23 = y 368 px (chão principal)
const TILES: Array = [
	# Chão principal — 2 tiles de espessura
	[0,    23, 120, 2],

	# Paredes laterais (fora do viewport, apenas colisão)
	[-1,    0,   1, 30],   # esquerda
	[120,   0,   1, 30],   # direita

	# Plataformas  [col, row, largura, 1]
	# row 20 = y 320  |  row 18 = y 288  |  row 15 = y 240
	[12,   20,   8,  1],   # PlatA   x 192–320   y 320
	[27,   18,   7,  1],   # PlatB   x 432–544   y 288
	[42,   15,   6,  1],   # PlatC   x 672–768   y 240
	[55,   18,   7,  1],   # PlatD   x 880–992   y 288
	[66,   20,   8,  1],   # PlatE   x 1056–1184 y 320
	[82,   18,   7,  1],   # PlatF   x 1312–1424 y 288
	[97,   15,   6,  1],   # PlatG   x 1552–1648 y 240
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
