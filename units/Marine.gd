extends KinematicBody2D
export (PackedScene) var Bullet = preload("res://units/Bullet.tscn")

var target = Vector2(0, 0)
var speed = 150
var velocity = Vector2()

var damage = .1

var player

func _ready():
	yield(owner, 'ready')
	if player == "P1":
		get_node("Flag").modulate = Color.blue
	elif player == "P2":
		get_node("Flag").modulate = Color.red


func _physics_process(delta):
	velocity = position.direction_to(target) * speed
	if position.distance_to(target) > 5:
		velocity = move_and_slide(velocity)

func shoot():
	yield(get_tree().create_timer(rand_range(0, .25)), 'timeout')
	var b = Bullet.instance()
	b.player = player
	b.damage = damage
	get_node("../../..").add_child(b)
	b.transform = $Muzzle.global_transform
