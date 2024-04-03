extends Node

func _ready():
	# Replace with the actual path to your MP3 file
	var mp3_filename: String = "res://TestMusic/07. Daft Punk - Superheroes.mp3"

	# Read the first 128 bytes (ID3v2 header)
	var mp3_data: PackedByteArray = load_mp3_data(mp3_filename, 128)

	# Check if it's an ID3v2 tag
	if is_id3v2_tag(mp3_data):
		# Extract relevant fields
		var title: String = extract_id3v2_field(mp3_data, 3, 30)
		var artist: String = extract_id3v2_field(mp3_data, 33, 30)
		var album: String = extract_id3v2_field(mp3_data, 63, 30)
		var year: String = extract_id3v2_field(mp3_data, 93, 4)
		var genre: String = extract_id3v2_field(mp3_data, 127, 1)

		# Print the extracted metadata
		print("Title:", title)
		print("Artist:", artist)
		print("Album:", album)
		print("Year:", year)
		print("Genre:", genre)
	else:
		print("No ID3v2 tags found in this MP3 file.")

func load_mp3_data(filename: String, num_bytes: int) -> PackedByteArray:
	var file = FileAccess.open(filename, FileAccess.READ)
	#var file: File = File.new()
	#if file.open(filename, File.READ) == OK:
	var data: PackedByteArray = file.get_buffer(num_bytes)
	file.close()
	return data
	#else:
		#print("Error opening the MP3 file.")
		#return PackedByteArray()

func is_id3v2_tag(data: PackedByteArray) -> bool:
	# Check if the first three bytes spell "ID3"
	return data[0] == 73 && data[1] == 68 && data[2] == 51

func extract_id3v2_field(data: PackedByteArray, start: int, length: int) -> String:
	return data.slice(start, start + length).get_string_from_utf8()

# Run this script to read ID3v2 tags from an MP3 file
