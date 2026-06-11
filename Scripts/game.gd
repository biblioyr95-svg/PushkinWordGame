## КОД ОТ ДЖИПИТИ
extends Node2D

# ==================================================
# КОНСТАНТЫ
# ==================================================

const WORD_SCENE = preload("res://Scenes/word.tscn")

const DEFAULT_VOLUME: float = 0.8
const VOLUME_SAVE_PATH: String = "user://music_volume.save"

const GAME_DURATION: float = 180.0


# ==================================================
# НАСТРОЙКИ ИГРЫ
# ==================================================

@export var initial_fall_speed: float = 100.0
@export var max_fall_speed: float = 350.0
@export var speed_increase_rate: float = 3.0

@export var spawn_interval: float = 2.0
@export var min_spawn_interval: float = 0.6
@export var spawn_interval_decrease: float = 0.05

@export var points_per_word: int = 10
@export var penalty_per_miss: int = 5

# Стартовые жизни
@export var lives: int = 7


# ==================================================
# СОСТОЯНИЕ ИГРЫ
# ==================================================

var score: int = 0

var current_fall_speed: float
var current_spawn_interval: float

var is_paused: bool = false
var is_game_over: bool = false

var game_time: float = 0.0
var time_left: float = GAME_DURATION


# ==================================================
# ССЫЛКИ НА УЗЛЫ
# ==================================================

@onready var player: Player = $Player

@onready var score_label: Label = \
	$CanvasLayer/VBoxContainer/ScoreLabel

@onready var lives_label: Label = \
	$CanvasLayer/VBoxContainer/LivesLabel

@onready var time_label: Label = \
	$CanvasLayer/VBoxContainer/TimeLabel

@onready var spawn_timer: Timer = $SpawnTimer

@onready var pause_overlay: ColorRect = \
	$CanvasLayer/PauseOverlay

@onready var volume_slider: HSlider = \
	$CanvasLayer/PauseOverlay/VBoxContainer/VolumeSlider

@onready var music_player: AudioStreamPlayer = \
	$MusicPlayer

@onready var words_container: Node2D = \
	$WordsContainer


# ==================================================
# СПИСКИ СЛОВ
# ==================================================

var correct_words := [
	"БОРДЮР",
	"ВОЯЖ",
	"БРАВАДА",
	"ЭЛИКСИР",
	"МЕЦЕНАТ",
	"КОРИФЕЙ",
	"ДИОРАМА",
	"ЭСТАКАДА",
	"ПАЛИТРА",
	"ПАНОРАМА",
	"КОЛИБРИ",
	"ВИРТУОЗ"
]

var incorrect_words := [
	"БАРДЮР",
	"ВАЯЖ",
	"БРОВАДА",
	"ЭЛЕКСИР",
	"МЕЦИНАТ",
	"КАРИФЕЙ",
	"КОРЕФЕЙ",
	"ДИАРАМА",
	"ДЕОРАМА",
	"ЭСТОКАДА",
	"ПОЛИТРА",
	"ПОНОРАМА",
	"ПАНАРАМА",
	"КАЛИБРИ",
	"ВЕРТУОЗ"
]


# ==================================================
# ЗАПУСК ИГРЫ
# ==================================================

func _ready() -> void:

	randomize()

	print("=== ИГРА ЗАПУЩЕНА ===")
	print("Размер viewport: ", get_viewport_rect().size)

	current_fall_speed = initial_fall_speed
	current_spawn_interval = spawn_interval

	time_left = GAME_DURATION

	# Загружаем громкость
	var saved_volume := load_volume()

	if volume_slider:
		volume_slider.value = saved_volume * 100.0
		volume_slider.value_changed.connect(
			_on_volume_changed
		)

	set_music_volume(saved_volume)

	# Запуск музыки
	if music_player and music_player.stream:
		music_player.play()

	# Подключаем игрока
	if player:
		player.area_entered.connect(
			_on_player_catch
		)

	# Таймер появления слов
	if spawn_timer:
		spawn_timer.timeout.connect(
			_on_spawn_timer_timeout
		)

		spawn_timer.wait_time = current_spawn_interval
		spawn_timer.start()

	update_ui()
	update_time_label()

	# Тестовое слово
	spawn_word()


# ==================================================
# ОСНОВНОЙ ЦИКЛ
# ==================================================

func _process(delta: float) -> void:

	if Input.is_action_just_pressed("pause"):
		toggle_pause()

	if is_paused:
		return

	if is_game_over:
		return

	# Таймер игры
	time_left -= delta

	if time_left <= 0.0:

		time_left = 0.0

		print("ВРЕМЯ ВЫШЛО")

		game_over()

		return

	update_time_label()

	# Рост сложности
	game_time += delta

	current_fall_speed = min(
		initial_fall_speed +
		speed_increase_rate * game_time,
		max_fall_speed
	)

	current_spawn_interval = max(
		spawn_interval -
		spawn_interval_decrease * game_time,
		min_spawn_interval
	)

	if spawn_timer:

		if abs(
			spawn_timer.wait_time -
			current_spawn_interval
		) > 0.1:

			spawn_timer.wait_time = \
				current_spawn_interval


# ==================================================
# СОЗДАНИЕ СЛОВА
# ==================================================

func spawn_word() -> void:

	if is_game_over:
		return

	var word_instance: Word = \
		WORD_SCENE.instantiate()

	if not word_instance:

		push_error(
			"Не удалось создать Word"
		)

		return

	var is_correct := randf() > 0.3

	var word_text: String

	if is_correct:

		word_text = \
			correct_words.pick_random()

	else:

		word_text = \
			incorrect_words.pick_random()

	word_instance.set_word(
		word_text,
		is_correct
	)

	word_instance.fall_speed = \
		current_fall_speed

	var screen_width := \
		get_viewport_rect().size.x

	word_instance.position = Vector2(
		randf_range(
			80.0,
			screen_width - 80.0
		),
		-50.0
	)

	word_instance.missed.connect(
		_on_word_missed
	)

	words_container.add_child(
		word_instance
	)

	print(
		"Создано слово: ",
		word_text,
		" правильное=",
		is_correct
	)


# ==================================================
# ПРОПУЩЕНО СЛОВО
# ==================================================

func _on_word_missed(word: Word) -> void:

	if is_game_over:
		return

	if not is_instance_valid(word):
		return

	if word.is_correct:

		score -= penalty_per_miss

		if score < 0:
			score = 0

		print(
			"Пропущено правильное слово. -",
			penalty_per_miss
		)

		update_ui()


# ==================================================
# ПОЙМАНО СЛОВО
# ==================================================

func _on_player_catch(area: Area2D) -> void:

	if is_game_over:
		return

	if not area is Word:
		return

	var word := area as Word

	if word.is_correct:

		score += points_per_word

		if player:
			player.start_correct_blink()

	else:

		lives -= 1

		if player:
			player.start_incorrect_blink()

		print(
			"Неверное слово. Осталось жизней: ",
			lives
		)

		if lives <= 0:

			game_over()

			return

	word.queue_free()

	update_ui()


# ==================================================
# ОБНОВЛЕНИЕ UI
# ==================================================

func update_ui() -> void:

	if score_label:
		score_label.text = \
			"Счёт: %d" % score

	if lives_label:
		lives_label.text = \
			"Жизни: %d" % lives


func update_time_label() -> void:

	if not time_label:
		return

	var minutes := int(time_left / 60)
	var seconds := int(time_left) % 60

	time_label.text = \
		"Время: %d:%02d" % [
			minutes,
			seconds
		]


# ==================================================
# ПАУЗА
# ==================================================

func toggle_pause() -> void:

	is_paused = !is_paused

	if pause_overlay:
		pause_overlay.visible = is_paused

	for child in words_container.get_children():

		if child is Word:

			child.set_process(
				!is_paused
			)

	print("Пауза: ", is_paused)


# ==================================================
# ГРОМКОСТЬ
# ==================================================

func _on_volume_changed(value: float) -> void:

	var volume := value / 100.0

	set_music_volume(volume)

	save_volume(volume)


func set_music_volume(volume: float) -> void:

	if music_player:

		music_player.volume_db = \
			linear_to_db(volume)


func save_volume(volume: float) -> void:

	var file := FileAccess.open(
		VOLUME_SAVE_PATH,
		FileAccess.WRITE
	)

	if file:
		file.store_float(volume)


func load_volume() -> float:

	if FileAccess.file_exists(
		VOLUME_SAVE_PATH
	):

		var file := FileAccess.open(
			VOLUME_SAVE_PATH,
			FileAccess.READ
		)

		if file:
			return file.get_float()

	return DEFAULT_VOLUME


# ==================================================
# GAME OVER
# ==================================================

func game_over() -> void:

	if is_game_over:
		return

	is_game_over = true

	print("GAME OVER")

	if spawn_timer:
		spawn_timer.stop()

	if player:

		player.set_process(false)
		player.set_process_input(false)

	for child in words_container.get_children():

		if child is Word:
			child.set_process(false)

	GameData.score = score
	GameData.save_high_score(score)

	var fade_overlay := ColorRect.new()

	fade_overlay.size = \
		get_viewport_rect().size

	fade_overlay.color = \
		Color(0, 0, 0, 0)

	fade_overlay.z_index = 100

	add_child(fade_overlay)

	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		fade_overlay,
		"color",
		Color(0, 0, 0, 1),
		1.0
	)

	if music_player:

		tween.tween_property(
			music_player,
			"volume_db",
			-30,
			1.0
		)

	await tween.finished

	get_tree().change_scene_to_file(
		"res://Scenes/game_over.tscn"
	)


# ==================================================
# ТАЙМЕР СПАВНА
# ==================================================

func _on_spawn_timer_timeout() -> void:

	if is_paused:
		return

	if is_game_over:
		return

	spawn_word()

## КОД ОТ ДИПСИКА
#extends Node2D
#
#const WORD_SCENE = preload("res://scenes/word.tscn")
#const DEFAULT_VOLUME = 0.8  # 80% громкости по умолчанию
#const VOLUME_SAVE_PATH = "user://music_volume.save"
#const GAME_DURATION: float = 180.0  # 3 минуты в секундах
#
#@export var initial_fall_speed: float = 100.0
#@export var max_fall_speed: float = 350.0
#@export var speed_increase_rate: float = 3.0
#@export var spawn_interval: float = 2.0
#@export var min_spawn_interval: float = 0.6
#@export var spawn_interval_decrease: float = 0.05
#@export var points_per_word: int = 10
#@export var penalty_per_miss: int = 5
#@export var lives: int = 3
#
#var score: int = 0
#var current_fall_speed: float
#var current_spawn_interval: float
#var is_paused: bool = false
#var is_game_over: bool = false
#var game_time: float = 0.0
#var time_left: float = GAME_DURATION
#
#@onready var player = $Player
#@onready var score_label = $CanvasLayer/VBoxContainer/ScoreLabel
#@onready var lives_label = $CanvasLayer/VBoxContainer/LivesLabel
#@onready var time_label = $CanvasLayer/VBoxContainer/TimeLabel
#@onready var spawn_timer = $SpawnTimer
#@onready var pause_overlay = $CanvasLayer/PauseOverlay
#@onready var volume_slider = $CanvasLayer/PauseOverlay/VBoxContainer/VolumeSlider
#@onready var music_player = $MusicPlayer
#@onready var words_container = $WordsContainer
#
#var correct_words = [
	#"БОРДЮР", "ВОЯЖ", "БРАВАДА", "ЭЛИКСИР", "МЕЦЕНАТ",
	#"КОРИФЕЙ", "ДИОРАМА", "ЭСТАКАДА", "ПАЛИТРА", "ПАНОРАМА",
	#"КОЛИБРИ", "ВИРТУОЗ"
#]
#
#var incorrect_words = [
	#"БАРДЮР", "ВАЯЖ", "БРОВАДА", "ЭЛЕКСИР", "МЕЦИНАТ",
	#"КАРИФЕЙ", "КОРЕФЕЙ", "ДИАРАМА", "ДЕОРАМА", "ЭСТОКАДА",
	#"ПОЛИТРА", "ПОНОРАМА", "ПАНАРАМА", "КАЛИБРИ", "ВЕРТУОЗ"
#]
#
#func _ready():
	#print("=== ИГРА ЗАПУЩЕНА ===")
	#
	#if has_node("ColorRect"):
		#$ColorRect.size = get_viewport_rect().size
		#print("Фон настроен")
	#
	## Загружаем сохранённую громкость
	#var saved_volume = load_volume()
	#volume_slider.value = saved_volume * 100
	#
	## Применяем громкость
	#set_music_volume(saved_volume)
	#
	## Подключаем сигнал слайдера
	#volume_slider.value_changed.connect(_on_volume_changed)
	#
	## Запускаем музыку
	#if music_player and music_player.stream:
		#music_player.play()
		#print("Музыка запущена")
	#
	#current_fall_speed = initial_fall_speed
	#current_spawn_interval = spawn_interval
	#
	#update_ui()
	#
	#spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	#spawn_timer.wait_time = current_spawn_interval
	#spawn_timer.start()
	#
	#print("Таймер запущен с интервалом: ", spawn_timer.wait_time)
	#
	#if player:
		#player.area_entered.connect(_on_player_catch)
		#print("Сигнал игрока подключен")
	#else:
		#print("ОШИБКА: Player не найден!")
	#
	#if words_container:
		#print("WordsContainer найден")
	#else:
		#print("ОШИБКА: WordsContainer не найден!")
	#
	#print("Создаём тестовое слово...")
	#spawn_word()
#
#func _process(delta):
	#if Input.is_action_just_pressed("pause"):
		#toggle_pause()
		#print("Пауза: ", is_paused)
	#
	#if is_paused or is_game_over:
		#return
	## Уменьшаем время
	#time_left -= delta
	#
	#if time_left <= 0:
		#time_left = 0
		#print("ВРЕМЯ ВЫШЛО!")
		#call_deferred("game_over")
		#return
		#
	#update_time_label()
	#
	#game_time += delta
	#current_fall_speed = min(initial_fall_speed + speed_increase_rate * game_time, max_fall_speed)
	#current_spawn_interval = max(spawn_interval - spawn_interval_decrease * game_time, min_spawn_interval)
	#spawn_timer.wait_time = current_spawn_interval
#
#func update_time_label():
	#var minutes = int(time_left / 60)
	#var seconds = int(time_left) % 60
	#time_label.text = "Время: %d:%02d" % [minutes, seconds]
#
#func spawn_word():
	#if is_game_over:
		#return
		#
	#print(">>> spawn_word вызван")
	#
	#if not WORD_SCENE:
		#print("ОШИБКА: WORD_SCENE не загружена!")
		#return
	#
	#var word_instance = WORD_SCENE.instantiate()
	#if not word_instance:
		#print("ОШИБКА: не удалось создать экземпляр Word!")
		#return
	#
	#var is_correct = randf() > 0.3
	#
	#var word_text: String
	#if is_correct:
		#word_text = correct_words[randi() % correct_words.size()]
	#else:
		#word_text = incorrect_words[randi() % incorrect_words.size()]
	#
	#print("Создано слово: ", word_text, " (правильное: ", is_correct, ")")
	#
	#word_instance.set_word(word_text, is_correct)
	#word_instance.fall_speed = current_fall_speed
	#
	#var screen_width = get_viewport_rect().size.x
	#word_instance.position = Vector2(
		#randf_range(80, screen_width - 80),
		#-50
	#)
	#
	#word_instance.visible = true
	#word_instance.modulate = Color.WHITE
	## Если игра на паузе, останавливаем новое слово
	#if is_paused:
		#word_instance.set_process(false)
		#
	#word_instance.tree_exiting.connect(_on_word_missed.bind(word_instance))
	#
	#print("Позиция слова: ", word_instance.position)
	#
	#if words_container:
		#words_container.add_child(word_instance)
		#print("Слово добавлено в контейнер")
		#print("Всего слов в контейнере: ", words_container.get_child_count())
	#else:
		#add_child(word_instance)
		#print("Слово добавлено в корень сцены (контейнер не найден)")
#
#func _on_word_missed(word):
	#if is_game_over or not is_instance_valid(word):
		#return
	#
	#var screen_bottom = get_viewport_rect().size.y
	#if word.is_correct and word.position.y > screen_bottom:
		#score -= penalty_per_miss
		#print("Пропущено правильное слово! -%d очков. Счёт: %d" % [penalty_per_miss, score])
		#
		#if score < 0:
			#score = 0
		#
		#update_ui()
#
#func _on_player_catch(area):
	#if not is_instance_valid(area) or is_game_over:
		#return
	#
	#if area is Word:
		#print("Поймано слово: ", area.word_text, " (правильное: ", area.is_correct, ")")
		#
		#if area.is_correct:
			#score += points_per_word
			#print("+%d очков" % points_per_word)
			#if player:
				#player.start_correct_blink()
		#else:
			#lives -= 1
			#print("-1 жизнь. Осталось: ", lives)
			#if player:
				#player.start_incorrect_blink()
			#
			#if lives <= 0:
				#print("ИГРА ОКОНЧЕНА!")
				#call_deferred("game_over")
				#return
		#
		#area.call_deferred("queue_free")
		#update_ui()
#
#func update_ui():
	#score_label.text = "Счёт: %d" % score
	#lives_label.text = "Жизни: %d" % lives
#
#func toggle_pause():
	#is_paused = !is_paused
	#pause_overlay.visible = is_paused
	## Ставим на паузу или снимаем с паузы все слова  
	#for child in words_container.get_children():
		#if child is Word:
			#child.set_process(!is_paused)
#
#func _on_volume_changed(value: float):
	#var volume = value / 100.0  # Конвертируем 0-100 в 0.0-1.0
	#set_music_volume(volume)
	#save_volume(volume)
	#print("Громкость изменена: %.2f" % volume)
#
#func set_music_volume(volume: float):
	#if music_player:
		#music_player.volume_db = linear_to_db(volume)
#
#func save_volume(volume: float):
	#var file = FileAccess.open(VOLUME_SAVE_PATH, FileAccess.WRITE)
	#if file:
		#file.store_float(volume)
		#file.close()
#
#func load_volume() -> float:
	#if FileAccess.file_exists(VOLUME_SAVE_PATH):
		#var file = FileAccess.open(VOLUME_SAVE_PATH, FileAccess.READ)
		#if file:
			#var volume = file.get_float()
			#file.close()
			#return volume
	#return DEFAULT_VOLUME
#
#func game_over():
	#if is_game_over:
		#return
	#
	#is_game_over = true
	#
	## Останавливаем таймер
	#spawn_timer.stop()
	#set_process(false)
	#
	## Отключаем игрока
	#if player:
		#player.set_process(false)
		#player.set_process_input(false)
	#
	## Останавливаем слова
	#for child in words_container.get_children():
		#child.set_process(false)
	#
	## Плавно затемняем экран
	#var fade_overlay = ColorRect.new()
	#fade_overlay.name = "FadeOverlay"
	#fade_overlay.size = get_viewport_rect().size
	#fade_overlay.color = Color(0, 0, 0, 0)
	#fade_overlay.z_index = 100
	#add_child(fade_overlay)
	#
	#var tween = create_tween()
	#tween.set_parallel(true)   
	## Плавное затемнение
	#tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 1.0)
	## Плавное затухание музыки
	#if music_player:
		#tween.tween_property(music_player, "volume_db", -30, 1.0)
	#
	## Сохраняем рекорд
	#GameData.score = score
	#GameData.save_high_score(score)
	#
	## Ждём окончания анимации и переходим
	#await tween.finished
	#get_tree().change_scene_to_file("res://scenes/game_over.tscn")
#
#func _on_spawn_timer_timeout():
	#print("Таймер сработал!")
	#if not is_paused and not is_game_over:
		#spawn_word()
