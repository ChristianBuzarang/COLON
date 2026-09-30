extends Node

var _ambience_player_a: AudioStreamPlayer
var _ambience_player_b: AudioStreamPlayer
var _active_ambience_is_a: bool = true
var _current_ambience_path: String = ""

var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 8

var _heartbeat_player: AudioStreamPlayer
var _heartbeat_base_pitch: float = 1.0

func _ready() -> void:
	_ambience_player_a = _make_player("Ambience")
	_ambience_player_b = _make_player("Ambience")
	_heartbeat_player = _make_player("Heartbeat")
	_heartbeat_player.stream_paused = true

	for i in range(SFX_POOL_SIZE):
		_sfx_players.append(_make_player("SFX"))

func _make_player(bus_name: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	if AudioServer.get_bus_index(bus_name) != -1:
		p.bus = bus_name
	add_child(p)
	return p

func play_ambience(stream_path: String, fade_time: float = 1.5, volume_db: float = 0.0) -> void:
	if stream_path == _current_ambience_path:
		return
	_current_ambience_path = stream_path

	var incoming = _ambience_player_b if _active_ambience_is_a else _ambience_player_a
	var outgoing = _ambience_player_a if _active_ambience_is_a else _ambience_player_b

	if stream_path != "":
		incoming.stream = load(stream_path)
		incoming.volume_db = -40.0
		incoming.play()

	var tween = create_tween().set_parallel(true)
	tween.tween_property(incoming, "volume_db", volume_db, fade_time)
	tween.tween_property(outgoing, "volume_db", -40.0, fade_time)
	tween.chain().tween_callback(outgoing.stop)

	_active_ambience_is_a = not _active_ambience_is_a

func stop_ambience(fade_time: float = 1.5) -> void:
	_current_ambience_path = ""
	var current = _ambience_player_a if _active_ambience_is_a else _ambience_player_b
	var tween = create_tween()
	tween.tween_property(current, "volume_db", -40.0, fade_time)
	tween.tween_callback(current.stop)

func play_sfx(stream_path: String, volume_db: float = 0.0, pitch_variance: float = 0.0) -> void:
	for p in _sfx_players:
		if not p.playing:
			p.stream = load(stream_path)
			p.volume_db = volume_db
			p.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
			p.play()
			return
	push_warning("AudioManager: SFX pool exhausted, sound dropped: " + stream_path)

func set_heartbeat_intensity(panic_level: float) -> void:
	if panic_level <= 0.0:
		if not _heartbeat_player.stream_paused:
			_heartbeat_player.stream_paused = true
		return

	if _heartbeat_player.stream == null:
		return  # no heartbeat stream assigned yet

	if _heartbeat_player.stream_paused:
		_heartbeat_player.stream_paused = false
		if not _heartbeat_player.playing:
			_heartbeat_player.play()

	_heartbeat_player.volume_db = lerp(-30.0, -5.0, panic_level)
	_heartbeat_player.pitch_scale = lerp(_heartbeat_base_pitch, _heartbeat_base_pitch * 1.3, panic_level)

func set_heartbeat_stream(stream_path: String) -> void:
	_heartbeat_player.stream = load(stream_path)
	_heartbeat_player.stream.loop = true if _heartbeat_player.stream.has_method("set_loop") else _heartbeat_player.stream
