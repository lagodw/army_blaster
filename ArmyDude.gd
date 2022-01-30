extends KinematicBody2D

export (int) var speed = 500
export (PackedScene) var Bullet = preload("res://units/Bullet.tscn")

var target = Vector2()
var velocity = Vector2()
var last_position = Vector2()

export var player = "P1"

func _ready():
	target = self.position
	last_position = self.position
	
	$Timer.connect('timeout', self, '_on_timeout')
	self.add_to_group(player)

func _input(event):
	if event.is_action_pressed('click'):
		target = get_global_mouse_position()

func _physics_process(delta):
	velocity = (target - position).normalized() * speed
	rotation = velocity.angle()
	if (target - position).length() > 10:
		velocity = move_and_slide(velocity)


func _on_timeout():
	if (last_position - position).length() <= 10:
		shoot()
	last_position = position
	
func shoot():
	var b = Bullet.instance()
	b.player = player
	get_parent().add_child(b)
	b.transform = $Muzzle.global_transform
