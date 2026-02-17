class_name Player
extends CharacterBody2D

@export var animated_sprite: AnimatedSprite2D

var speed_walk:float = 100
var speed_run:float = 175
var input_direction:Vector2
var last_direction:String = "down"

var can_move:bool = true

#para las transiciones
func _ready():
	add_to_group("player")
	NavigationManager.on_trigger_player_spawn.connect(_on_spawn)

func set_can_move(value: bool):
	can_move = value
	if !value:
		velocity = Vector2.ZERO
		update_animation("idle")

func _on_spawn(positions: Vector2, direction: String):
	global_position = positions
	last_direction = direction
	update_animation("idle")
	

#movimiento
func _physics_process(_delta):
	if !can_move:
		update_animation("idle")
		return
	get_input()
	move_and_slide()


func get_input():
	input_direction = Input.get_vector("left","right","up","down")
	
	#comprobar si se está moviendo
	if input_direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		update_animation("idle")
		return
	
	#comprobar si se mueve horizontal o vertical
	if abs(input_direction.x) > abs(input_direction.y):
		#mov horizontal, ahora calcular el sentido
		if input_direction.x > 0:
			last_direction = "right"
		else:
			last_direction = "left"
	else:
		if input_direction.y > 0:
			last_direction = "down"
		else:
			last_direction = "up"
	
	#Verifica si corre o camina
	if Input.is_action_pressed("run"):
		velocity = input_direction * speed_run
		update_animation("run")
	else:
		velocity = input_direction * speed_walk
		update_animation("walk")
	
func update_animation(state):
	animated_sprite.play(state + "_" + last_direction)
