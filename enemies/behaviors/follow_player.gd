extends Node

@export var speed: float = 1.0

var sprite: AnimatedSprite2D
var enemy: Enemy
var is_running: bool = false
var was_running: bool = false

func _ready():
	enemy = get_parent()
	sprite = enemy.get_node("AnimatedSprite2D")
	pass

func play_run_idle_animation() -> void:
	# Executar animação
	#if not is_attacking:
		if was_running != is_running:
			if is_running:
				sprite.play("run")
			else:
				sprite.play("idle")

func _physics_process(_delta: float) -> void:
	
	# Calcular Direção
	var player_position = GameManager.player_position
	var difference = player_position - enemy.position
	var input_vector = difference.normalized()
	
	# Andar
	enemy.velocity = input_vector * speed * 100
	enemy.move_and_slide()
	
	# Atualizar o is_running
	was_running = is_running
	is_running = not input_vector.is_zero_approx()
	play_run_idle_animation()

	#Girar sprite
	if input_vector.x > 0:
		# Desmarcar o Flip_H do Sprite2D
		sprite.flip_h = false
	elif input_vector.x < 0:
		# Marcar o Flip_H do Sprite2D
		sprite.flip_h = true
