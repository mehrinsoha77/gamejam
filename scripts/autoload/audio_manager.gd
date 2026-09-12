extends Node
## AudioManager (autoload singleton)
## Adaptive music state machine + one-shot SFX playback.
##
## IMPORTANT: no audio assets ship with this pass of the project. Every load
## below is guarded with ResourceLoader.exists() so the game runs in total
## silence today and comes alive the instant real files are dropped in at the
## exact paths listed in ASSETS_NEEDED.md. Nothing needs to change in code.

enum MusicState { EXPLORATION, TENSION, COMBAT, PUZZLE, DISCOVERY, BOSS, FINAL }

const MUSIC_PATHS := {
	MusicState.EXPLORATION: "res://assets/audio/music/exploration.ogg",
	MusicState.TENSION: "res://assets/audio/music/tension.ogg",
	MusicState.COMBAT: "res://assets/audio/music/combat.ogg",
	MusicState.PUZZLE: "res://assets/audio/music/puzzle.ogg",
	MusicState.DISCOVERY: "res://assets/audio/music/discovery.ogg",
	MusicState.BOSS: "res://assets/audio/music/boss.ogg",
	MusicState.FINAL: "res://assets/audio/music/final.ogg",
}

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_CROSSFADE_TIME := 1.5

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

var _current_state: int = -1
var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_is_a: bool = true
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_b = AudioStreamPlayer.new()
	_player_a.bus = "Master"
	_player_b.bus = "Master"
	add_child(_player_a)
	add_child(_player_b)
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)

func set_music_state(state: int) -> void:
	if state == _current_state:
		return
	_current_state = state
	var path: String = MUSIC_PATHS.get(state, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream := load(path)
	var incoming: AudioStreamPlayer = _player_b if _active_is_a else _player_a
	var outgoing: AudioStreamPlayer = _player_a if _active_is_a else _player_b
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(incoming, "volume_db", linear_to_db(music_volume * master_volume), MUSIC_CROSSFADE_TIME)
	if outgoing.playing:
		tween.tween_property(outgoing, "volume_db", -80.0, MUSIC_CROSSFADE_TIME)
		tween.chain().tween_callback(outgoing.stop)
	_active_is_a = not _active_is_a

func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
	var path := SFX_DIR + sfx_name + ".ogg"
	if not ResourceLoader.exists(path):
		return
	var player := _get_free_sfx_player()
	player.stream = load(path)
	player.volume_db = linear_to_db(sfx_volume * master_volume) + volume_db
	player.play()

func play_sfx_at(sfx_name: String, position: Vector3, parent: Node) -> void:
	var path := SFX_DIR + sfx_name + ".ogg"
	if not ResourceLoader.exists(path):
		return
	var player := AudioStreamPlayer3D.new()
	parent.add_child(player)
	player.global_position = position
	player.stream = load(path)
	player.volume_db = linear_to_db(sfx_volume * master_volume)
	player.play()
	player.finished.connect(player.queue_free)

func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]

func apply_volume_settings(master: float, music: float, sfx: float) -> void:
	master_volume = master
	music_volume = music
	sfx_volume = sfx
	var db := linear_to_db(music_volume * master_volume)
	if _player_a.playing:
		_player_a.volume_db = db
	if _player_b.playing:
		_player_b.volume_db = db

## Distinctive audio signature for a DOF unlock, per frequency band described
## in the design doc. Falls back to a single generic cue if the three bands
## aren't authored yet.
func play_dof_unlock_stinger() -> void:
	if ResourceLoader.exists(SFX_DIR + "dof_unlock_low.ogg"):
		play_sfx("dof_unlock_low")
	if ResourceLoader.exists(SFX_DIR + "dof_unlock_mid.ogg"):
		play_sfx("dof_unlock_mid")
	if ResourceLoader.exists(SFX_DIR + "dof_unlock_high.ogg"):
		play_sfx("dof_unlock_high")
