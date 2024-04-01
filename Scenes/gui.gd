extends Control

var SongList = []


func _ready():
	GetDirectories("C:/Users/XLR8/Music")
	print(SongList.size())
	#print(SongList)
	for Song in SongList:
		$SongList.add_item(Song[0])


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
	var SelectedSong = SongList[index]
	
	var MusicStream
	if SelectedSong[2] == "mp3":
		MusicStream = AudioStreamMP3.new()
	elif SelectedSong[2] == "flac":
		MusicStream = AudioStreamFLAC.new()
	else:
		return
	#var music = $SongPlayer
	#var audio_loader = AudioStream.new()
	#audio_loader.resource_path = SelectedSong
	#music.set_stream(audio_loader)
	#$SongPlayer.stream = get("AudioStream" + SelectedSong[2]).new()
	print(SelectedSong[1])
	print(MusicStream)
	$SongPlayer.stream.resource_path = SelectedSong[1]
	$SongPlayer.play()
