extends Node

var file : FileAccess

var SongInfo : Dictionary = {}
var block_type
var block_header
var block_length

var title = false
var artist = false

func _ready():
	pass
	#OpenFile("res://TestMusic/MetadataTest/Bag Raiders - Shooting Stars.flac")


func OpenFile(filepath):
	title = false
	artist = false
	SongInfo = Dictionary()
	file = FileAccess.open(filepath, FileAccess.READ)
	#if file.get_buffer(4).get_string_from_ascii() != "fLaC":
		#print("Not a valid FLAC file.")
		#return
	#while true:
		#break
		#block_header = file.get_buffer(4)
		#if not block_header:
				#break
		#block_type = block_header[0] & 0x7F
		##block_length = struct.unpack('>I', b'\x00' + block_header[1:])[0]
		#block_length = block_header[1]
		#if block_type == 4:
			#var comment_data = file.get_buffer(block_length).get_string_from_ascii()
			#
			#var artist_index = comment_data.to_lower().find('artist=')
			#print(comment_data)
			#if artist_index != -1:
				#print('a')
				#var artist_end_index = comment_data.find(artist_index)
				#var artist2 = comment_data.get_slice(artist_index + len('artist='), artist_end_index)#.get_string_from_ascii()
				#print(artist2)
		
		#print(file.get_buffer(4))
		#print(file.get_buffer(block_length))
	#return
	while true:
		#print(filepath)
		#block_header = file.get_buffer(4)
		#if not block_header:
			#break 
		#block_type = block_header[0] & 0x7F
		#block_type = str(block_type).hex_decode().get_string_from_ascii()
		#TITLE
		block_type = file.get_buffer(1).get_string_from_ascii().to_lower()
		#print(block_type)
		if title == false:
			if block_type == "t":
				block_type = file.get_buffer(1).get_string_from_ascii().to_lower()
				if block_type == "i":
					block_type = file.get_buffer(1).get_string_from_ascii().to_lower()
					if block_type == "t":
						block_type = file.get_buffer(1).get_string_from_ascii().to_lower()
						if block_type == "l":
							block_type = file.get_buffer(1).get_string_from_ascii().to_lower()
							if block_type == "e":
								file.get_buffer(1).get_string_from_ascii()
								SongInfo["TIT2"] = METATEST(file)
								#SongInfo["TIT2"] = file.get_buffer(16).get_string_from_ascii().strip_edges(false,true)
								#print(SongInfo["TIT2"])
								title = true
							
		if artist == false:
			if block_type == "a":
				block_type = file.get_buffer(1).get_string_from_ascii().to_lower()
				if block_type == "r":
					block_type = file.get_buffer(1).get_string_from_ascii().to_lower()
					if block_type == "t":
						block_type = file.get_buffer(1).get_string_from_ascii().to_lower()
						if block_type == "i":
							block_type = file.get_buffer(1).get_string_from_ascii().to_lower()
							if block_type == "s":
								block_type = file.get_buffer(1).get_string_from_ascii().to_lower()
								if block_type == "t":
									file.get_buffer(1).get_string_from_ascii()
									SongInfo["TPE1"] = METATEST(file)
									#SongInfo["TPE1"] = file.get_buffer(16).get_string_from_ascii().strip_edges(false,true)
									#print(SongInfo["TPE1"])
									artist = true
		if (title == true and artist == true) or file.eof_reached():
			print(SongInfo)
			return
		
		#print(block_type)
	#with open(flac_file, 'rb') as f:
		#header = f.read(4)
		#if header != b'fLaC':
			#print("Not a valid FLAC file.")
			#return None
		
		#metadata = []

		#while True:
			#block_header = f.read(4)
			#if not block_header:
				#break 
			#block_type = block_header[0] & 0x7F
#
			#block_length = struct.unpack('>I', b'\x00' + block_header[1:])[0]
#
			#if block_type == 4:
				#comment_data = f.read(block_length)
#
				#artist_index = comment_data.lower().find(b'artist=')
				#if artist_index != -1:
					#artist_end_index = comment_data.find(b'\x00', artist_index)
					#artist = comment_data[artist_index + len(b'artist='):artist_end_index].decode('utf-8')
					#metadata.append(artist)
#
				#title_index = comment_data.lower().find(b'title=')
				#if title_index != -1:
					#title_end_index = comment_data.find(b'\x00', title_index)  
					#title = comment_data[title_index + len(b'title='):title_end_index].decode('utf-8')
					#metadata.append(title)
#
				#album_index = comment_data.lower().find(b'album=')
				#if title_index != -1:
					#album_end_index = comment_data.find(b'\x00', album_index)
					#album = comment_data[album_index + len(b'album='):album_end_index].decode('utf-8')
					#metadata.append(album)
#
			#f.seek(block_length, 1)
		#return metadata
#
#flac_file = 'c2c.flac'
#metadata = extract_flac_title(flac_file)
#if metadata:
	#print("Artist:", metadata[0][:-1])
	#print("Title:", metadata[1][:-1])
	#print("Album:", metadata[2][:-1])
#
#else:
	#print("No metadata found")

func METATEST(file):
	var Final = ""
	for i in 1024:
		var char = file.get_buffer(1).get_string_from_utf8()
		if char != "":
			Final += char
		else:
			print(i)
			print(Final)
			print(char)
			return Final

