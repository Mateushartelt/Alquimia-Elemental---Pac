extends Node
## AudioManager — toca efeitos sonoros. Autoload singleton.

const SFX := {
	"jump":            "res://assets/audio/sfx/jump.wav",
	"attack":          "res://assets/audio/sfx/attack.wav",
	"hit_enemy":       "res://assets/audio/sfx/hit_enemy.wav",
	"hurt_player":     "res://assets/audio/sfx/hurt_player.wav",
	"pickup":          "res://assets/audio/sfx/pickup.wav",
	"craft_success":   "res://assets/audio/sfx/craft_success.wav",
	"ui_click":        "res://assets/audio/sfx/ui_click.wav",
	"ui_open":         "res://assets/audio/sfx/ui_open.wav",
	"ui_close":        "res://assets/audio/sfx/ui_close.wav",
	"boss_hit":        "res://assets/audio/sfx/boss_hit.wav",
	"boss_heal":       "res://assets/audio/sfx/boss_heal.wav",
	"game_over":       "res://assets/audio/sfx/game_over.wav",
	"victory":         "res://assets/audio/sfx/victory.wav",
	"checkpoint":      "res://assets/audio/sfx/checkpoint.wav",
	"door_open":       "res://assets/audio/sfx/door_open.wav",
	"special":         "res://assets/audio/sfx/special.wav",
	"fire_extinguish": "res://assets/audio/sfx/fire_extinguish.wav",
	"fire_burn":       "res://assets/audio/sfx/fire_burn.wav",
	"menu_move":       "res://assets/audio/sfx/menu_move.wav",
}

## Volume individual de cada som, em decibéis, somado ao volume geral (sfx_volume).
## Ajuste um valor aqui para deixar aquele som específico mais alto (positivo) ou
## mais baixo (negativo) sem afetar os demais. 0.0 = sem ajuste.
const SFX_VOLUME_DB := {
	"jump":            -10.0,
	"attack":          0.0,
	"hit_enemy":       0.0,
	"hurt_player":     0.0,
	"pickup":          0.0,
	"craft_success":   0.0,
	"ui_click":        0.0,
	"ui_open":         0.0,
	"ui_close":        0.0,
	"boss_hit":        0.0,
	"boss_heal":       0.0,
	"game_over":       0.0,
	"victory":         0.0,
	"checkpoint":      0.0,
	"door_open":       0.0,
	"special":         0.0,
	"fire_extinguish": -10.0,
	"fire_burn":       -2.0,   # sutil e posicional — mais baixo à distância, sobe perto do fogo
	"menu_move":       0.0,
}

const SFX_POOL_SIZE := 8
const SILENCE_DB     := -80.0

var sfx_volume: float = 1.0

var _sfx_streams: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_idx := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for key: String in SFX:
		var stream: AudioStream = load(SFX[key])
		if key == "fire_burn" and stream is AudioStreamWAV:
			var wav := stream as AudioStreamWAV
			wav.loop_mode  = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end   = wav.data.size() / 2   # 16-bit mono: 2 bytes/frame
		_sfx_streams[key] = stream

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)

func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _sfx_streams.get(sfx_name)
	if not stream:
		return
	var player := _sfx_pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % _sfx_pool.size()
	player.stream    = stream
	player.volume_db = linear_to_db(sfx_volume) + SFX_VOLUME_DB.get(sfx_name, 0.0) + volume_db
	player.play()

## Cria um AudioStreamPlayer2D configurado (posicional — só é audível perto da
## câmera) para um som em loop, como o crepitar do fogo. O chamador é
## responsável por posicionar, adicionar à árvore e chamar .play().
func make_positional_loop(sfx_name: String, max_distance: float = 320.0, attenuation: float = 1.4) -> AudioStreamPlayer2D:
	var stream: AudioStream = _sfx_streams.get(sfx_name)
	if not stream:
		return null
	var p := AudioStreamPlayer2D.new()
	p.stream        = stream
	p.max_distance  = max_distance
	p.attenuation   = attenuation
	p.volume_db     = linear_to_db(sfx_volume) + SFX_VOLUME_DB.get(sfx_name, 0.0)
	return p

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
