extends AudioStreamPlayer


func _play_music(music: AudioStream, volume: float = 0.0):
	if stream == music:
		return
	stream = music
	volume_db = volume
	play()

func play_music_level(name_track: String):
	var track = load(name_track)
	_play_music(track)
