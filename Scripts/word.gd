extends Area2D
class_name Word

@export var word_text: String = ""
@export var is_correct: bool = true
@export var fall_speed: float = 100.0
@export var base_width: float = 25.0  # Базовая ширина на одну букву
@export var height: float = 40.0       # Высота коллизии

var screen_height: float
var word_color: Color

func _ready():
	monitoring = true
	monitorable = true
	
	var label = $Label
	if label:
		label.text = word_text
		
		if word_color == Color.WHITE or word_color == Color(0, 0, 0, 0):
			word_color = generate_random_color()
		
		label.add_theme_color_override("font_color", word_color)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 2)
	
	# Подгоняем размер коллизии под длину слова
	update_collision_size()
	
	screen_height = get_viewport_rect().size.y

func _process(delta):
	position.y += fall_speed * delta
	
	if position.y > screen_height + 100:
		queue_free()

func set_word(text: String, correct: bool):
	word_text = text
	is_correct = correct
	word_color = generate_random_color()

func update_collision_size():
	var label = $Label
	var collision = $CollisionShape2D
	
	if not label or not collision:
		return
	
	# Вычисляем ширину текста (примерно)
	var text_width = word_text.length() * base_width
	
	# Для букв разной ширины можно использовать более точный метод
	# Но для кириллицы обычно хватает пропорционального расчёта
	
	# Обновляем размер коллизии
	var shape = collision.shape
	if shape is RectangleShape2D:
		shape.size = Vector2(text_width, height)
	
	# Обновляем размер Label
	label.size = Vector2(text_width, height)
	
	# Центрируем Label относительно Area2D
	label.position = Vector2(-text_width / 2, -height / 2)

func generate_random_color() -> Color:
	randomize()
	
	var hue = randf()
	var saturation = randf_range(0.7, 1.0)
	var value = randf_range(0.8, 1.0)
	
	return Color.from_hsv(hue, saturation, value, 1.0)
