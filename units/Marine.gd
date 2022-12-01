extends KinematicBody2D
export (PackedScene) var Bullet = preload("res://units/Bullet.tscn")

var target = Vector2(0, 0)
var speed = 150
var velocity = Vector2()
var orient = "E"
var damage = .1

var player

func _ready():
	yield(self.get_parent().get_parent(), 'ready')
	get_node("Flag").modulate = Global.player_colors[player]

func _physics_process(delta):
	velocity = position.direction_to(target) * speed
	if position.distance_to(target) > 20:
		velocity = move_and_slide(velocity)

func shoot():
	yield(get_tree().create_timer(rand_range(0, .25)), 'timeout')
	var b = Bullet.instance()
	b.player = player
	b.damage = damage
	get_node("../../..").add_child(b)
	b.transform = $Rotating/Muzzle.global_transform
	$AnimationPlayer.play('Shoot_' + orient)

func move_animation(deg):
	orient = get_orientation(deg)
	$AnimationPlayer.play("Walk_" + orient)
	
func stop_animation():
	$AnimationPlayer.stop()
	if orient == 'E':
		$Sprite.frame = 0
	elif orient == 'N':
		$Sprite.frame = 10
	elif orient == 'NE':
		$Sprite.frame = 20
	elif orient == 'NW':
		$Sprite.frame = 30
	elif orient == 'S':
		$Sprite.frame = 40
	elif orient == 'SE':
		$Sprite.frame = 50
	elif orient == 'SW':
		$Sprite.frame = 60
	elif orient == 'W':
		$Sprite.frame = 70

func rotate_to(pos):
	var deg = rad2deg(pos.angle_to_point(global_position))
	var new_orient = get_orientation(deg)
	$Rotating.look_at(pos)
	if new_orient != orient:
		stop_animation()
		orient = new_orient

func get_orientation(deg):
	if deg > -15 and deg < 15:
		return("E")
	elif deg > -60 and deg < -15:
		return("NE")
	elif deg > -120 and deg < -60:
		return("N")
	elif deg > -165 and deg < -120:
		return("NW")
	elif deg > 15 and deg < 60:
		return("SE")
	elif deg > 60 and deg < 120:
		return('S')
	elif deg > 120 and deg < 165:
		return('SW')
	else:
		return('W')
