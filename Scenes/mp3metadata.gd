extends Node

#internal variables
var file : FileAccess
var ID3pos
var synchbytes
var Tagsize

var MoreTags = true

var SongInfo : Dictionary = {}

enum TagEncoding {
	ISO_8859_1 = 0,
	UTF_16_WITH_BOM = 1,
	UTF_16_WITHOUT_BOM = 2, # assuming big endian
	UTF8 = 3
};

func OpenFile(filepath):
	file = FileAccess.open(filepath, FileAccess.READ)
	file.set_big_endian(true)
	#First we search for the 10 byte ID3 tag header
	#ID3 tags are supposed to, but don't always, prepend the music data in the file
	if file.get_buffer(3).get_string_from_utf8().contains("ID3"):
		print("ID3 found at file beginning")
		ID3pos = file.get_position()
	#And when they don't...
	else:
		var filebytes = file.get_buffer(file.get_length())
		ID3pos = filebytes.hex_encode().find("494433")/2
		print("Alternate ID3 tag finder used")
		file.seek(ID3pos+3)
		print(file.get_position())
		print(file.get_buffer(3).get_string_from_utf8())
	#The next 7 bytes after that are part of the header of the ID3 tag
	#These next two are version number
	print(file.get_buffer(2).hex_encode())
	#After that is the flag byte
	print(file.get_buffer(1).hex_encode())
	#Then the size information. We have to do some funny business here, cause 
	#this is a synchsafe integer
	synchbytes = file.get_32()
	print(synchbytes)
	Synchsafeconversion()
	while MoreTags:
		TagLoad()
		
	print(SongInfo)

var converted = 0
var magic = 0x7F000000
#Max return from this should be 4095
func Synchsafeconversion():
	for byte in range(4):
		converted >>= 1
		converted |= synchbytes & magic
		magic >>= 8
	Tagsize = converted

func TagLoad():
	#Now we start actually loading tags
	var tag = file.get_buffer(4).get_string_from_utf8()
	print(tag)
	if tag == "":
		MoreTags = false
		return
	
	#These next 4 bytes have the information about the tag's size
	# first byte always zeroed
	var size_bytes : String = file.get_buffer(4).hex_encode()
	var tag_size : int = 0
	tag_size = size_bytes.hex_to_int()
	
	#These next two are flags
	file.get_buffer(2).hex_encode()
	
	var bytes = 1
	var input: PackedStringArray
	var temp_buffer: PackedByteArray
	var encoding: int
	var byte_order_mark: PackedByteArray
	while bytes <= tag_size:
		# encoding byte 
		# 0x00: ISO-8859-1 (Latin-1)
		# 0x01: UTF-16 with BOM (Byte Order Mark)
		# 0x02: UTF-16 without BOM
		# 0x03: UTF-8
		encoding = file.get_buffer(1)[0];
		
		# byte order mark
		if encoding == TagEncoding.UTF_16_WITH_BOM:
			byte_order_mark = file.get_buffer(2) 
			if byte_order_mark[0] == 255 and byte_order_mark[1] == 254:
				file.set_big_endian(false)
			else:
				file.set_big_endian(true)
		else:
			# utf16 without bom -> assuming big endian
			file.set_big_endian(true)
		
		# tag data
		temp_buffer = file.get_buffer(tag_size - 3)
		
		match encoding:
			TagEncoding.ISO_8859_1:
				input.append(temp_buffer.get_string_from_utf8())
			TagEncoding.UTF_16_WITH_BOM:
				input.append(temp_buffer.get_string_from_utf16())
			TagEncoding.UTF_16_WITHOUT_BOM:
				input.append(temp_buffer.get_string_from_utf16())
			TagEncoding.UTF8:
				input.append(temp_buffer.get_string_from_utf8())
			_:
				print("ERROR: Invalid Encoding Byte")
		bytes = bytes + tag_size
	
	var output: String
	SongInfo[tag] = output.join(input)
	Tagsize = Tagsize - tag_size
