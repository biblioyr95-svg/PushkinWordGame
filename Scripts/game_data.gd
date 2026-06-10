extends Node

var score: int = 0
var high_score: int = 0

func _ready():
	load_high_score()

func load_high_score():
	if OS.get_name() == "Web":
		return
	
	if FileAccess.file_exists("user://high_score.save"):
		var file = FileAccess.open("user://high_score.save", FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()

func save_high_score(new_score: int):
	if new_score > high_score:
		high_score = new_score
		if OS.get_name() == "Web":
			return
		
		var file = FileAccess.open("user://high_score.save", FileAccess.WRITE)
		if file:
			file.store_32(high_score)
			file.close()

func reset_high_score():
	high_score = 0
	if OS.get_name() == "Web":
		return
	
	if FileAccess.file_exists("user://high_score.save"):
		DirAccess.remove_absolute("user://high_score.save")
