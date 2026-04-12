extends Node
## Manages SFX and music playback across audio buses.

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8


func _ready() -> void:
	_setup_audio_buses()
	_setup_players()


func _setup_audio_buses() -> void:
	# Ensure audio buses exist: Master (default), Music, SFX
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")


func _setup_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)


func play_sfx(stream: AudioStream) -> void:
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	# All players busy — skip


func play_music(stream: AudioStream, fade_in: float = 1.0) -> void:
	if _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, 0.5)
		tween.tween_callback(func():
			_music_player.stream = stream
			_music_player.volume_db = -40.0
			_music_player.play()
			var fade_tween := create_tween()
			fade_tween.tween_property(_music_player, "volume_db", 0.0, fade_in)
		)
	else:
		_music_player.stream = stream
		_music_player.volume_db = -40.0
		_music_player.play()
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", 0.0, fade_in)


func stop_music(fade_out: float = 1.0) -> void:
	if _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_out)
		tween.tween_callback(_music_player.stop)
