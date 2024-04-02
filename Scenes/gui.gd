extends Control

var SongList = []
var Shuffle = false
var PlayingSong = []

var PreviousSongs = []

func _ready():
	#GetDirectories("C:/Users/XLR8/Music")
	GetDirectories("/run/media/kirby/MoreStore/Music/GuiltyGear/")
	print(SongList.size())
	for Song in SongList:
		$SongList.add_item(Song[0])

func _process(delta):
	$Controls/TimeLeft.value = $SongPlayer.get_playback_position()
	
	var time = snapped($SongPlayer.get_playback_position(),1)
	var hours = snapped((int(time) / 60) / 60,1)
	time -= hours * 60 * 60
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
				SongList.append([File, Path + "/" + File, "mp3", SongList.size()])
			elif File.ends_with(".flac"):
				SongList.append([File, Path + "/" + File, "flac", SongList.size()])


func _on_song_list_item_activated(index):
	LoadSong(index)

func LoadSong(SongNumber: int):
	if SongNumber > SongList.size() - 1 or SongNumber < 0:
		SongNumber = 0
	var SelectedSong = SongList[SongNumber]
	PlayingSong = SongList[SongNumber]
	
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
	if PreviousSongs.size() > 0:
		if PreviousSongs[0] == SelectedSong:
			PreviousSongs.remove_at(0)
		#else:
			#PreviousSongs.insert(0,SelectedSong)
	#else:
	PreviousSongs.insert(0,SelectedSong)
	if PreviousSongs.size() > 100:
		PreviousSongs.remove_at(100)
	$History.clear()
	for Song in PreviousSongs:
		$History.add_item(Song[0])
	
	$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Pause.png")
	$SongList.select(SongNumber)
	$SongList.ensure_current_is_visible()
	$Controls/SongName.text = SelectedSong[0]
	$Controls/TimeLeft.max_value = MusicStream.get_length()
	var time = snapped(MusicStream.get_length(),1)
	var hours = (int(time) / 60) / 60
	var mins = int(time) / 60
	time -= mins * 60
	var secs = int(time)
	$Controls/TimeLeft/Length.text = (str(hours) + "h " + str(mins) + "m " + str(secs) + "s")


func _on_volume_slider_gui_input(_event):
	$SongPlayer.volume_db = ($Controls/VolumeSlider.value -100)
	$Controls/VolumeSlider/Percent.text = str(($Controls/VolumeSlider.value)) + "%"


func _on_song_player_finished():
	if Shuffle == true:
		var random = RandomNumberGenerator.new()
		random.randomize()
		LoadSong(random.randi_range(1,SongList.size()) - 1)
	else:
		LoadSong($SongList.get_selected_items()[0] + 1)

func _on_play_pressed():
	if $SongPlayer.stream.get_length() > 0:
		$SongPlayer.stream_paused = !$SongPlayer.stream_paused
		if $SongPlayer.playing == true:
			$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Pause.png")
		elif $SongPlayer.playing == false:
			$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Play.png")
	else:
		$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Pause.png")
		if Shuffle == true:
			var random = RandomNumberGenerator.new()
			random.randomize()
			LoadSong(random.randi_range(1,SongList.size()) - 1)
		else:
			LoadSong(0)


func _on_stop_pressed():
	$SongPlayer.stop()
	$SongPlayer.stream = AudioStream.new()
	$Controls/SongName.text = "None playing"
	$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Play.png")
	$Controls/TimeLeft/Length.text = "0h 0m 0s"


func _on_next_pressed():
	if $SongPlayer.stream.get_length() > 0:
		if Shuffle == true:
			var random = RandomNumberGenerator.new()
			random.randomize()
			LoadSong(random.randi_range(1,SongList.size()) - 1)
		else:
			LoadSong(PlayingSong[3] + 1)
	else:
		if Shuffle == true:
			var random = RandomNumberGenerator.new()
			random.randomize()
			LoadSong(random.randi_range(1,SongList.size()) - 1)
		else:
			LoadSong(0)


func _on_previous_pressed():
	if PreviousSongs.size() > 0:
		LoadSong(PreviousSongs[1][3])
	else:
		LoadSong(PlayingSong[3] - 1)


func _on_forward_pressed():
	$SongPlayer.seek($SongPlayer.get_playback_position() + 10)


func _on_back_pressed():
	if $SongPlayer.get_playback_position() - 10 < 0:
		$SongPlayer.seek(0)
	else:
		$SongPlayer.seek($SongPlayer.get_playback_position() - 10)


func _on_shuffle_toggled(toggled_on):
	Shuffle = toggled_on
