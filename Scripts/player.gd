extends Area2D
class_name Player

@export var move_speed: float = 800.0
@export var blink_duration: float = 0.3
@export var blink_count: int = 1

var screen_width: float
var original_modulate: Color = Color.WHITE
var original_scale: Vector2

func _ready():
	monitoring = true
	monitorable = true
	screen_width = get_viewport_rect().size.x
	original_scale = scale
	original_modulate = $Sprite2D.modulate

func _process(delta):
	# Движение игрока
	var input_direction = 0
	
	if Input.is_action_pressed("move_left"):
		input_direction -= 1
	if Input.is_action_pressed("move_right"):
		input_direction += 1
	
	position.x += input_direction * move_speed * delta
	
	# Отражаем спрайт по горизонтали в зависимости от направления
	if input_direction < 0:
		$Sprite2D.flip_h = true
	elif input_direction > 0:
		$Sprite2D.flip_h = false
	
	var half_width = $CollisionShape2D.shape.size.x / 2
	position.x = clamp(position.x, half_width, screen_width - half_width)
	

func blink(color: Color):
	var sprite = $Sprite2D
	if not sprite:
		return
		
	var tween = create_tween()
	var single_blink = blink_duration / (blink_count * 2)
	for i in range(blink_count):
		tween.tween_callback(func(): sprite.modulate = color)
		tween.tween_interval(single_blink)
		tween.tween_callback(func(): sprite.modulate = original_modulate)
		tween.tween_interval(single_blink)
		
func start_correct_blink():
	blink(Color.GREEN)

func start_incorrect_blink():
	blink(Color.RED)
