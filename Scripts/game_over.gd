extends Control

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var high_score_label = $VBoxContainer/HighScoreLabel
@onready var restart_button = $VBoxContainer/Button
@onready var reset_button = $VBoxContainer/ResetButton

func _ready():
	# Получаем данные из синглтона
	var final_score = GameData.score
	var high_score = GameData.high_score
	
	score_label.text = "Ваш счёт: %d" % final_score
	high_score_label.text = "Рекорд: %d" % high_score
	restart_button.pressed.connect(_on_restart_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

func _on_restart_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	
func _on_reset_pressed():
	# Сбрасываем рекорд
	GameData.reset_high_score()
	# Обновляем отображение
	high_score_label.text = "Рекорд: 0"
	print("Рекорд сброшен!")
