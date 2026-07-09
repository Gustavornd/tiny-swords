class_name Player
extends CharacterBody2D

@export var speed: float = 2
@export var lerp_factor: float = 0.50
@export var controller_deadzone: float = 0.15
@export var sword_damage: int = 2
@export var attack_range: float = 0.45
@export var health: int = 100
@export var max_health: int = 100
@export var death_prefab: PackedScene

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea

var input_vector: Vector2 = Vector2(0, 0)
var is_running: bool = false
var was_running: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var use_second_variation: bool = false
var hitbox_cooldown: float = 0.0

var attack_direction: Vector2 = Vector2(0,0)

# Recebe os comandos de movimento do controle
func readInput() -> void:
	# Obter input vector
	input_vector = Input.get_vector("move_left", "move-rigth", "move_up", "move_down", 0.15)
	
	# Apagar controller_deadzone do input_vector
	if abs(input_vector.x) < controller_deadzone:
		input_vector.x = 0.0
	if abs(input_vector.y) < controller_deadzone:
		input_vector.y = 0.0
	
	# Atualizar o is_running
	was_running = is_running
	is_running = not input_vector.is_zero_approx()

# Alterna entre as animações de "run" e "idle"
func play_run_idle_animation() -> void:
	# Executar animação
	if not is_attacking:
		if was_running != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")

# Roda o sprite de acordo com a direção da movimentação
func rotate_sprite() -> void:
	#Girar sprite
	if input_vector.x > 0:
		# Desmarcar o Flip_H do Sprite2D
		sprite.flip_h = false
	elif input_vector.x < 0:
		# Marcar o Flip_H do Sprite2D
		sprite.flip_h = true

# Atualiza o temporizador de ataque para realizar toda a animação
# antes do próximo ataque
func update_attack_cooldown(delta: float) -> void:
	# Atualizar temporizador do ataque
	if is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")

# Função que causa o dano nos inimigos
func deal_damage_to_enemies() -> void:
	# Calcula quais inimigos estão próximos
	var bodys = sword_area.get_overlapping_bodies()
	
	# Causa dano nos inimigos dentro da área de ataque
	for body in bodys:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var direction_to_enemy =(enemy.position - position).normalized()
			var dot_product = direction_to_enemy.dot(attack_direction)
			if dot_product >= 0.45:
				enemy.damage(sword_damage)

# Executa as animações de ataque de acordo com a direção
func attack(direction: Vector2) -> void:
	if is_attacking:
		return
	
	# Alterna entre diferentes variações de ataque
	var anim_suffix: String = "_2" if use_second_variation else "_1"
	
	# Executar animação de Ataque
	if abs(direction.x) > abs(direction.y):
		attack_direction = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
		animation_player.play("attack_side" + anim_suffix)
	elif direction.y > 0:
		attack_direction = Vector2.DOWN
		animation_player.play("attack_bottom" + anim_suffix)
	elif direction.y < 0:
		attack_direction = Vector2.UP
		animation_player.play("attack_top" + anim_suffix)
	else:
		attack_direction = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
		animation_player.play("attack_side"+anim_suffix)
	
	use_second_variation = not use_second_variation
	# Tempo para resetar o ataque
	attack_cooldown = 0.6
	
	# Indica que o ataque está ocorrendo
	is_attacking = true

func damage(amount: int)-> void:
	if health <= 0: return
	
	health -= amount
	print("Jogador recebeu dano de: ", amount, " e agora tem ", health, " de vida.")
	
	# Piscar quando tomar dano
	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Processar morte
	if health <= 0:
		die()

func die() -> void:
	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
		GameManager.have_player = false
		
		
	queue_free()

func heal(amount: int) -> int:
	health += amount
	if (health >= max_health):
		health = max_health
	print("Player recebeu cura de ", amount, ". A vida total é de ", health,"/",max_health)
	return health
	

func update_hitbox_detection(delta: float) -> void:
	# Temporizador
	hitbox_cooldown -= delta
	if hitbox_cooldown > 0: return
	
	# Frequência
	hitbox_cooldown = 0.5
	
	# Detectar inimigos dentro da HitboxArea
	var bodies = hitbox_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var damage_amount = 10
			damage(damage_amount)

func _process(delta: float) -> void:
	
	# Salvar a posição do jogador no GameManager
	GameManager.player_position = position
	
	# Ler input
	readInput()
	
	# Processar Ataque
	update_attack_cooldown(delta)
	if Input.is_action_just_pressed("attack"):
		attack(input_vector)
	
	# Processar animação
	play_run_idle_animation()
	if not is_attacking:
		rotate_sprite()
	
	# Processar morte
	update_hitbox_detection(delta)

func _physics_process(_delta: float) -> void:
	
	# Modificar a velocidade
	var target_velocity = input_vector * speed * 100.0
	if is_attacking:
		target_velocity *= 0.25
	velocity = lerp(velocity, target_velocity, lerp_factor)
	move_and_slide()
