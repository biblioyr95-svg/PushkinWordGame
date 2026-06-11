# КОД ОТ ДЖИПИТИ
extends Area2D
class_name Word

# Сигнал пропуска слова
signal missed(word: Word)

# Текст слова
@export var word_text: String = ""

# Является ли слово правильным
@export var is_correct: bool = true

# Скорость падения
@export var fall_speed: float = 100.0

# Ширина одной буквы
@export var base_width: float = 25.0

# Высота коллизии
@export var collision_height: float = 40.0

# Цвет слова
var word_color: Color = Color.WHITE


func _ready() -> void:

	# Включаем обнаружение столкновений
	monitoring = true
	monitorable = true

	var label := $Label

	if label:

		# Устанавливаем текст
		label.text = word_text

		# Генерируем цвет если ещё не задан
		if word_color == Color.WHITE:
			word_color = generate_random_color()

		# Цвет текста
		label.add_theme_color_override(
			"font_color",
			word_color
		)

		# Контур
		label.add_theme_color_override(
			"font_outline_color",
			Color.BLACK
		)

		label.add_theme_constant_override(
			"outline_size",
			2
		)

	update_collision_size()


func _process(delta: float) -> void:

	# Падение слова
	position.y += fall_speed * delta

	# Получаем актуальную высоту экрана
	var screen_height := get_viewport_rect().size.y

	# Ушло за экран
	if position.y > screen_height + 100:

		# Сообщаем Game что слово пропущено
		missed.emit(self)

		queue_free()


func set_word(text: String, correct: bool) -> void:

	word_text = text
	is_correct = correct

	word_color = generate_random_color()


func update_collision_size() -> void:

	var label := $Label
	var collision := $CollisionShape2D

	if not label:
		return

	if not collision:
		return

	if collision.shape == null:
		return

	var text_width := word_text.length() * base_width

	if collision.shape is RectangleShape2D:

		collision.shape.size = Vector2(
			text_width,
			collision_height
		)

	label.custom_minimum_size = Vector2(
		text_width,
		collision_height
	)

	label.position = Vector2(
		-text_width / 2.0,
		-collision_height / 2.0
	)


func generate_random_color() -> Color:

	return Color.from_hsv(
		randf(),
		randf_range(0.7, 1.0),
		randf_range(0.8, 1.0)
	)

## КОДА ОТ ДИПСИКА
#extends Area2D
#class_name Word
#
#@export var word_text: String = ""
#@export var is_correct: bool = true
#@export var fall_speed: float = 100.0
#@export var base_width: float = 25.0  # Базовая ширина на одну букву
#@export var height: float = 40.0       # Высота коллизии
#
#var screen_height: float
#var word_color: Color
#
#func _ready():
	#monitoring = true
	#monitorable = true
	#
	#var label = $Label
	#if label:
		#label.text = word_text
		#
		#if word_color == Color.WHITE or word_color == Color(0, 0, 0, 0):
			#word_color = generate_random_color()
		#
		#label.add_theme_color_override("font_color", word_color)
		#label.add_theme_color_override("font_outline_color", Color.BLACK)
		#label.add_theme_constant_override("outline_size", 2)
	#
	## Подгоняем размер коллизии под длину слова
	#update_collision_size()
	#
	#screen_height = get_viewport_rect().size.y
#
#func _process(delta):
	#position.y += fall_speed * delta
	#
	#if position.y > screen_height + 100:
		#queue_free()
#
#func set_word(text: String, correct: bool):
	#word_text = text
	#is_correct = correct
	#word_color = generate_random_color()
#
#func update_collision_size():
	#var label = $Label
	#var collision = $CollisionShape2D
	#
	#if not label or not collision:
		#return
	#
	## Вычисляем ширину текста (примерно)
	#var text_width = word_text.length() * base_width
	#
	## Для букв разной ширины можно использовать более точный метод
	## Но для кириллицы обычно хватает пропорционального расчёта
	#
	## Обновляем размер коллизии
	#var shape = collision.shape
	#if shape is RectangleShape2D:
		#shape.size = Vector2(text_width, height)
	#
	## Обновляем размер Label
	#label.size = Vector2(text_width, height)
	#
	## Центрируем Label относительно Area2D
	#label.position = Vector2(-text_width / 2, -height / 2)
#
#func generate_random_color() -> Color:
	#randomize()
	#
	#var hue = randf()
	#var saturation = randf_range(0.7, 1.0)
	#var value = randf_range(0.8, 1.0)
	#
	#return Color.from_hsv(hue, saturation, value, 1.0)
