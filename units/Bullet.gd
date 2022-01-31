extends Area2D

var speed = 750
var damage
var player
var distance_traveled = 0
var max_distance = 750

func _ready():
	self.connect("body_entered", self, "_on_Bullet_body_entered")

func _physics_process(delta):
	position += transform.x * speed * delta
	distance_traveled += speed * delta
	if distance_traveled >= max_distance:
		queue_free()

func _on_Bullet_body_entered(body):
	if body.is_in_group("unit") and not body.is_in_group(player):
		body.take_damage(damage)
		queue_free()
