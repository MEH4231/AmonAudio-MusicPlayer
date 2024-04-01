extends Control

var SongList = []

func _ready():
	GetDirectories("C:/Users/XLR8/Music")
	print(SongList.size())
	for Song in SongList:
		$SongList.add_item(Song[0])

func _process(delta):
	$Controls/TimeLeft.value = $SongPlayer.get_playback_position()
	
	var time = snapped($SongPlayer.get_playback_position(),1)
	var hours = snapped((int(time) / 60) / 60,1)
	var mins = snapped(int(time) / 60,1)
	time -= mins * 60
	var secs = snapped(int(time),1)
	$Controls/TimeLeft/Left.text = (str(hours) + "h " + str(mins) + "m " + str(secs) + "s")

func GetDirectories(Path: String):
	var Dir = DirAccess.open(Path)
	if Dir.get_directories():
		for Directory in Dir.get_directories():
			#print(Path + "/" + Directory)
			GetDirectories(Path + "/" + Directory)
	if Dir.get_files():
		for File in Dir.get_files():
			#print(File)
			if File.ends_with(".mp3"):
				SongList.append([File, Path + "/" + File, "mp3"])
			elif File.ends_with(".flac"):
				SongList.append([File, Path + "/" + File, "flac"])


func _on_song_list_item_activated(index):
	LoadSong(index)

func LoadSong(SongNumber):
	var SelectedSong = SongList[SongNumber]
	
	var MusicStream
	if SelectedSong[2] == "mp3":
		var Song = FileAccess.open(SelectedSong[1], FileAccess.READ)
		MusicStream = AudioStreamMP3.new()
		MusicStream.data = Song.get_buffer(Song.get_length())

	elif SelectedSong[2] == "flac":
		var Song = FileAccess.open(SelectedSong[1], FileAccess.READ)
		MusicStream = AudioStreamFLAC.new()
		MusicStream.data = Song.get_buffer(Song.get_length())
	else:
		return
	$SongPlayer.stream = MusicStream
	$SongPlayer.play()
	
	$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Pause.png")
	$Controls/SongName.text = SelectedSong[0]
	$Controls/TimeLeft.max_value = MusicStream.get_length()
	var time = snapped(MusicStream.get_length(),1)
	var hours = (int(time) / 60) / 60
	var mins = int(time) / 60
	time -= mins * 60
	var secs = int(time)
	$Controls/TimeLeft/Length.text = (str(hours) + "h " + str(mins) + "m " + str(secs) + "s")


func _on_slider_gui_input(_event):
	$SongPlayer.volume_db = ($Controls/Slider.value -100)
	$Controls/Slider/Percent.text = str(($Controls/Slider.value)) + "%"


func _on_play_pressed():
	if $SongPlayer.stream.get_length() > 0:
		$SongPlayer.stream_paused = !$SongPlayer.stream_paused
		if $SongPlayer.playing == true:
			$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Pause.png")
		elif $SongPlayer.playing == false:
			$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Play.png")


func _on_stop_pressed():
	$SongPlayer.stop()
	$Controls/SongName.text = "None playing"
	$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Play.png")
	$Controls/TimeLeft/Length.text = "0h 0m 0s"


func _on_song_player_finished():
	var random = RandomNumberGenerator.new()
	random.randomize()
	LoadSong(random.randi_range(1,SongList.size()) - 1)


func _on_next_pressed():
	var random = RandomNumberGenerator.new()
	random.randomize()
	LoadSong(random.randi_range(1,SongList.size()) - 1)
