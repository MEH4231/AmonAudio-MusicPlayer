extends Node

var MainGUI = preload("res://Scenes/gui.tscn")

func _ready():
	add_child(MainGUI.instantiate())
