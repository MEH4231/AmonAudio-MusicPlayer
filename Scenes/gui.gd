extends Control

var SongList = []
var PreviousSongs = []
var PlayingSong = []

var Shuffle = false
var Loop = LoopType.OFF
enum LoopType{
	OFF,
	ON,
	SINGLE
}

var Remove = false
var Discord = false

var MetadataThread = Thread.new()

func _ready():
	print(Loop)
	if Discord == true:
		DiscordRPC.app_id = 1224614529456017498 # Application ID
		DiscordRPC.details = "Playing music"
		DiscordRPC.state = "Nothing Playing"
		#DiscordRPC.state = ""

		DiscordRPC.large_image = "icon" # Image key from "Art Assets"
		#DiscordRPC.large_image_text = "Try it now!"
		DiscordRPC.small_image = "volume" # Image key from "Art Assets"
		DiscordRPC.small_image_text = "Volume: " + str($Controls/VolumeSlider.value) + " | Shuffle: " + str(Shuffle).capitalize() + " | Loop: " + str(Loop)

		#DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
		#DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
		DiscordRPC.refresh()
		DiscordRPC.details = "Playing " + str(SongList.size()) + " songs"
		DiscordRPC.refresh()
	#GetDirectories("C:/Users/XLR8/Documents/Godot/projects/AmonAudio-MusicPlayer/TestMusic")
	#GetDirectories("C:/Users/XLR8/Music/")
	#GetDirectories("/run/media/kirby/MoreStore/Music")
	print(SongList.size())
	MetadataThread.start(GetMeta)
	for Song in SongList:
		$SongList.add_item(Song[0])

@onready var LastRefresh = snapped($SongPlayer.get_playback_position(), 1)

func _process(_delta):
	if $SongPlayer.get_playback_position() > LastRefresh + 1:
		$Controls/TimeLeft.value = $SongPlayer.get_playback_position()
		LastRefresh = snapped($SongPlayer.get_playback_position(), 1)
	
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
			GetDirectories(Path + "/" + Directory)
	if Dir.get_files():
		for File in Dir.get_files():
			if File.get_extension() == "mp3" or File.get_extension() == "flac":
				var NewFile = File.erase(File.length() - (File.get_extension().length() + 1),File.get_extension().length() + 1)
				SongList.append([NewFile, Path + "/" + File, File.get_extension(), SongList.size(),{}])
			elif File.get_extension() == "AA-MP":
				var PlaylistFile = FileAccess.open(Path + "/" + File,FileAccess.READ)
				var PlayListSongs = str_to_var(PlaylistFile.get_as_text())
				for Song in PlayListSongs:
					if Song.get_extension() == "mp3" or Song.get_extension() == "flac":
						var NewFile = Song.erase(Song.length() - (Song.get_extension().length() + 1),Song.get_extension().length() + 1)
						SongList.append([NewFile, Song, Song.get_extension(), SongList.size(),{}])

func GetSong(Path: String):
	if Path.get_extension() == "mp3" or Path.get_extension() == "flac":
		var NewFile = Path.erase(Path.length() - (Path.get_extension().length() + 1),Path.get_extension().length() + 1)
		SongList.append([NewFile, Path, Path.get_extension(), SongList.size(),{}])
	elif Path.get_extension() == "AA-MP":
		var PlaylistFile = FileAccess.open(Path,FileAccess.READ)
		var PlayListSongs = str_to_var(PlaylistFile.get_as_text())
		for Song in PlayListSongs:
			if Song.get_extension() == "mp3" or Song.get_extension() == "flac":
				var NewFile = Song.erase(Song.length() - (Song.get_extension().length() + 1),Song.get_extension().length() + 1)
				SongList.append([NewFile, Song, Song.get_extension(), SongList.size(),{}])


func _on_song_list_item_activated(index):
	LoadSong(index, true)

var LastDiscordTime = Time.get_unix_time_from_system()

func LoadSong(SongNumber: int, Forward: bool):
	if Discord == true:
		if Time.get_unix_time_from_system() > LastDiscordTime + 60:
			DiscordRPC.clear(true)
			DiscordRPC.app_id = 1224614529456017498
			DiscordRPC.details = "Playing " + str(SongList.size()) + " songs"
			DiscordRPC.state = "Nothing Playing"
			DiscordRPC.large_image = "icon"
			DiscordRPC.small_image = "volume"
			LastDiscordTime = Time.get_unix_time_from_system()
	
	if SongNumber > SongList.size() - 1 or SongNumber < 0:
		$SongPlayer.stop()
		$SongPlayer.stream = AudioStream.new()
		$Controls/SongName.text = "None playing"
		$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Play.png")
		$Controls/TimeLeft/Length.text = "0h 0m 0s"
		$Controls/TimeLeft/Left.text = "0h 0m 0s"
		$Controls/TimeLeft.value = 0
		
		if PlayingSong.size() > 0:
			if Forward == true:
				PreviousSongs.insert(0,PlayingSong.duplicate())
				if PreviousSongs.size() > 250:
					PreviousSongs.remove_at(250)
			elif Forward == false:
				if PreviousSongs.size() > 0:
					PreviousSongs.remove_at(0)
		$History.clear()
		for Song in PreviousSongs:
			$History.add_item(Song[0])
		PlayingSong.clear()
		
		if Discord == true:
			DiscordRPC.state = "Nothing Playing"
			DiscordRPC.start_timestamp = int()
			DiscordRPC.large_image_text = ""
			DiscordRPC.refresh()
		if Loop == LoopType.ON:
			LoadSong(0, true)
		return
	var SelectedSong = SongList[SongNumber].duplicate()
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
	
	if PlayingSong.size() > 0:
		if Forward == true:
			PreviousSongs.insert(0,PlayingSong.duplicate())
			if PreviousSongs.size() > 250:
				PreviousSongs.remove_at(250)
		elif Forward == false:
			if PreviousSongs.size() > 0:
				PreviousSongs.remove_at(0)
	$History.clear()
	for Song in PreviousSongs:
		if Song[4]:
			if Song[4].get("TPE1") and Song[4].get("TIT2"):
				$History.add_item(Song[4].get("TPE1") + " - " + Song[4].get("TIT2"))
			else:
				$History.add_item(Song[0])
		else:
			$History.add_item(Song[0])
	
	PlayingSong = SongList[SongNumber].duplicate()
	
	$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Pause.png")
	$SongList.select(SongNumber)
	$SongList.ensure_current_is_visible()
	if PlayingSong[4].get("TIT2") and PlayingSong[4].get("TPE1"):
		$Controls/SongName.text = PlayingSong[4].get("TPE1") + " - " + PlayingSong[4].get("TIT2")
	else:
		$Controls/SongName.text = SelectedSong[0]
	$Controls/TimeLeft.max_value = MusicStream.get_length()
	LastRefresh = snapped(-1, 1)
	var time = snapped(MusicStream.get_length(),1)
	var hours = (int(time) / 60) / 60
	var mins = int(time) / 60
	time -= mins * 60
	var secs = int(time)
	$Controls/TimeLeft/Length.text = (str(hours) + "h " + str(mins) + "m " + str(secs) + "s")
	
	if Discord == true:
		DiscordRPC.state = "Total: "+ (str(hours) + "h " + str(mins) + "m " + str(secs) + "s")
		DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
		if PlayingSong[4].get("TIT2") and PlayingSong[4].get("TPE1"):
			DiscordRPC.large_image_text = PlayingSong[4].get("TPE1") + " - " + PlayingSong[4].get("TIT2")
		else:
			DiscordRPC.large_image_text = PlayingSong[0]
		DiscordRPC.small_image_text = "Volume: " + str($Controls/VolumeSlider.value) + " | Shuffle: " + str(Shuffle).capitalize() + " | Loop: " + str(Loop)
		DiscordRPC.refresh()

func GetMeta():
	for Song in SongList:
		if Song:
			if Song[2] == "mp3":
				Mp3Metadata.OpenFile(Song[1])
				SongList[Song[3]][4] = Mp3Metadata.SongInfo
			elif Song[2] == "flac":
				FlacMetadata.OpenFile(Song[1])
				SongList[Song[3]][4] = FlacMetadata.SongInfo
			#print(SongList[Song[3]][4])
	call_deferred("SongListName")
	print("Done")

func SongListName():
	MetadataThread.wait_to_finish()
	$SongList.clear()
	for Song in SongList:
		if Song[4]:
			if Song[4].get("TPE1") and Song[4].get("TIT2"):
				$SongList.add_item(Song[4].get("TPE1") + " - " + Song[4].get("TIT2"))
			else:
				$SongList.add_item(Song[0])
		else:
			$SongList.add_item(Song[0])
	
	

func _on_volume_slider_gui_input(_event):
	$SongPlayer.volume_db = ($Controls/VolumeSlider.value -100)
	$Controls/VolumeSlider/Percent.text = str(($Controls/VolumeSlider.value)) + "%"
	
	if Discord == true:
		DiscordRPC.small_image_text = "Volume: " + str($Controls/VolumeSlider.value) + " | Shuffle: " + str(Shuffle).capitalize() + " | Loop: " + str(Loop)
		DiscordRPC.refresh()


func _on_song_player_finished():
	if Loop == LoopType.SINGLE:
		$SongPlayer.seek(0)
		$SongPlayer.play()
		LastRefresh = snapped(-1, 1)
		if Discord == true:
			DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
			DiscordRPC.refresh()
	else:
		if Shuffle == true:
			var random = RandomNumberGenerator.new()
			random.randomize()
			LoadSong(random.randi_range(1,SongList.size()) - 1, true)
		else:
			LoadSong($SongList.get_selected_items()[0] + 1, true)


func _on_play_pressed():
	if $SongPlayer.stream.get_length() > 0:
		$SongPlayer.stream_paused = !$SongPlayer.stream_paused
		if $SongPlayer.playing == true:
			$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Pause.png")
			
			
			var time = snapped($SongPlayer.stream.get_length(),1)
			var hours = (int(time) / 60) / 60
			var mins = int(time) / 60
			time -= mins * 60
			var secs = int(time)
			
			if Discord == true:
				DiscordRPC.state = "Total: "+ (str(hours) + "h " + str(mins) + "m " + str(secs) + "s")
				DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system() - $SongPlayer.get_playback_position())
				if PlayingSong[4].get("TIT2") and PlayingSong[4].get("TPE1"):
					DiscordRPC.large_image_text = PlayingSong[4].get("TPE1") + " - " + PlayingSong[4].get("TIT2")
				else:
					DiscordRPC.large_image_text = PlayingSong[0]
		elif $SongPlayer.playing == false:
			$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Play.png")
			
			if Discord == true:
				DiscordRPC.state = "Paused"
				DiscordRPC.start_timestamp = int()
				if PlayingSong[4].get("TIT2") and PlayingSong[4].get("TPE1"):
					DiscordRPC.large_image_text = PlayingSong[4].get("TPE1") + " - " + PlayingSong[4].get("TIT2")
				else:
					DiscordRPC.large_image_text = PlayingSong[0]
	else:
		$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Pause.png")
		if Shuffle == true:
			var random = RandomNumberGenerator.new()
			random.randomize()
			LoadSong(random.randi_range(1,SongList.size()) - 1, true)
		else:
			LoadSong(0, true)
	if Discord == true:
		DiscordRPC.refresh()


func _on_stop_pressed():
	$SongPlayer.stop()
	$SongPlayer.stream = AudioStream.new()
	$Controls/SongName.text = "None playing"
	$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Play.png")
	$Controls/TimeLeft/Length.text = "0h 0m 0s"
	$Controls/TimeLeft/Left.text = "0h 0m 0s"
	$Controls/TimeLeft.value = 0
	PlayingSong.clear()
	
	if Discord == true:
		DiscordRPC.state = "Nothing Playing"
		DiscordRPC.start_timestamp = int()
		DiscordRPC.large_image_text = ""
		DiscordRPC.refresh()


func _on_next_pressed():
	if $SongPlayer.stream.get_length() > 0:
		if Shuffle == true:
			var random = RandomNumberGenerator.new()
			random.randomize()
			LoadSong(random.randi_range(1,SongList.size()) - 1, true)
		else:
			LoadSong(PlayingSong[3] + 1, true)
	else:
		if Shuffle == true:
			var random = RandomNumberGenerator.new()
			random.randomize()
			LoadSong(random.randi_range(1,SongList.size()) - 1, true)
		else:
			LoadSong(0, true)


func _on_previous_pressed():
	if PreviousSongs.size() > 0:
		LoadSong(PreviousSongs[0][3], false)
	else:
		LoadSong(PlayingSong[3] - 1, false)


func _on_forward_pressed():
	$SongPlayer.seek($SongPlayer.get_playback_position() + 10)
	LastRefresh = snapped(-1, 1)
	
	if Discord == true:
		DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system() - $SongPlayer.get_playback_position())
		DiscordRPC.refresh()


func _on_back_pressed():
	if $SongPlayer.get_playback_position() - 10 < 0:
		$SongPlayer.seek(0)
	else:
		$SongPlayer.seek($SongPlayer.get_playback_position() - 10)
	LastRefresh = snapped(0, 1)
	
	if Discord == true:
		DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system() - $SongPlayer.get_playback_position())
		DiscordRPC.refresh()


func _on_shuffle_toggled(toggled_on):
	Shuffle = toggled_on
	if Discord == true:
		DiscordRPC.small_image_text = "Volume: " + str($Controls/VolumeSlider.value) + " | Shuffle: " + str(Shuffle).capitalize() + " | Loop: " + str(Loop)
		DiscordRPC.refresh()


func _on_discord_toggled(toggled_on):
	Discord = toggled_on
	if Discord == false:
		DiscordRPC.clear(true)
	else:
		DiscordRPC.clear(true)
		DiscordRPC.app_id = 1224614529456017498
		DiscordRPC.details = "Playing music"
		DiscordRPC.state = "Nothing Playing"
		DiscordRPC.large_image = "icon"
		DiscordRPC.small_image = "volume"
		DiscordRPC.small_image_text = "Volume: " + str($Controls/VolumeSlider.value) + " | Shuffle: " + str(Shuffle).capitalize() + " | Loop: " + str(Loop)
		if $SongPlayer.playing == true:
			var time = snapped($SongPlayer.stream.get_length(),1)
			var hours = (int(time) / 60) / 60
			var mins = int(time) / 60
			time -= mins * 60
			var secs = int(time)
			DiscordRPC.state = "Total: "+ (str(hours) + "h " + str(mins) + "m " + str(secs) + "s")
			DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system() - $SongPlayer.get_playback_position())
			#DiscordRPC.large_image_text = PlayingSong[0]
			if PlayingSong[4].get("TPE1") and PlayingSong[4].get("TIT2"):
				DiscordRPC.large_image_text = PlayingSong[4].get("TPE1") + " - " + PlayingSong[4].get("TIT2")
			else:
				DiscordRPC.large_image_text = PlayingSong[0]
			DiscordRPC.small_image_text = "Volume: " + str($Controls/VolumeSlider.value) + " | Shuffle: " + str(Shuffle).capitalize() + " | Loop: " + str(Loop)
		if SongList.size() > 0:
			DiscordRPC.details = "Playing " + str(SongList.size()) + " songs"
		DiscordRPC.refresh()


func _on_history_item_activated(index):
	var SongToPlay = PreviousSongs[index][3]
	PreviousSongs.remove_at(index)
	LoadSong(SongToPlay, true)


func _on_select_folder_pressed():
	$RightButtons/SelectFolder/FolderSelect.visible = true

func _on_select_songs_pressed():
	$RightButtons/SelectSongs/SongSelect.visible = true


func _on_clear_list_pressed():
	SongList.clear()
	PreviousSongs.clear()
	PlayingSong.clear()
	
	
	$History.clear()
	$SongList.clear()
	$SongPlayer.stop()
	$SongPlayer.stream = AudioStream.new()
	$Controls/SongName.text = "None playing"
	$Controls/Buttons/Container/Play.texture_normal = ResourceLoader.load("res://Textures/Play.png")
	$Controls/TimeLeft/Length.text = "0h 0m 0s"
	$Controls/TimeLeft/Left.text = "0h 0m 0s"
	$Controls/TimeLeft.value = 0
	
	if Discord == true:
		DiscordRPC.details = "Playing music"
		DiscordRPC.state = "Nothing Playing"
		DiscordRPC.start_timestamp = int()
		DiscordRPC.large_image_text = ""
		DiscordRPC.refresh()


func _on_loop_pressed():
	if Loop == LoopType.OFF:
		Loop = LoopType.ON
		$Controls/Buttons/Loop.button_pressed = true
		$Controls/Buttons/Loop/One.visible = false
	elif Loop == LoopType.ON:
		Loop = LoopType.SINGLE
		$Controls/Buttons/Loop.button_pressed = true
		$Controls/Buttons/Loop/One.visible = true
	elif Loop == LoopType.SINGLE:
		Loop = LoopType.OFF
		$Controls/Buttons/Loop.button_pressed = false
		$Controls/Buttons/Loop/One.visible = false
	if Discord == true:
		DiscordRPC.small_image_text = "Volume: " + str($Controls/VolumeSlider.value) + " | Shuffle: " + str(Shuffle).capitalize() + " | Loop: " + str(Loop)
		DiscordRPC.refresh()




func _on_quit_pressed():
	get_tree().quit()


func _on_folder_select_dir_selected(dir):
	GetDirectories(dir)
	$SongList.clear()
	for Song in SongList:
		$SongList.add_item(Song[0])
	print(SongList.size())
	
	if Discord == true:
		DiscordRPC.details = "Playing " + str(SongList.size()) + " songs"
		DiscordRPC.refresh()
	
	MetadataThread = Thread.new()
	MetadataThread.start(GetMeta)

func _on_song_select_file_selected(path):
	GetSong(path)
	$SongList.clear()
	for Song in SongList:
		$SongList.add_item(Song[0])
	print(SongList.size())
	
	if Discord == true:
		DiscordRPC.details = "Playing " + str(SongList.size()) + " songs"
		DiscordRPC.refresh()
	
	MetadataThread = Thread.new()
	MetadataThread.start(GetMeta)


func _on_song_select_files_selected(paths):
	for File in paths:
		GetSong(File)
	$SongList.clear()
	for Song in SongList:
		$SongList.add_item(Song[0])
	print(SongList.size())
	
	if Discord == true:
		DiscordRPC.details = "Playing " + str(SongList.size()) + " songs"
		DiscordRPC.refresh()
	
	MetadataThread = Thread.new()
	MetadataThread.start(GetMeta)


func _on_remove_song_toggled(toggled_on):
	Remove = toggled_on


func _on_save_playlist_pressed():
	$RightButtons/SavePlaylist/PlaylistSave.visible = true


func _on_playlist_save_file_selected(path):
	var File = FileAccess.open(path,FileAccess.WRITE)
	var PlaylistSongs = []
	for Song in SongList:
		PlaylistSongs.append(Song[1])
	#print(PlaylistSongs)
	File.store_string(str(PlaylistSongs))
	File.close()


func _on_song_list_item_clicked(index, at_position, mouse_button_index):
	if Remove == true:
		SongList.remove_at(index)
		$SongList.remove_item(index)
		print(SongList.size())
		PreviousSongs.clear()
		$History.clear()




