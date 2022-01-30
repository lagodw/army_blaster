extends Area2D

var speed = 750
var player

func _ready():
	self.connect("body_entered", self, "_on_Bullet_body_entered")

func _physics_process(delta):
	position += transform.x * speed * delta

func _on_Bullet_body_entered(body):
	if body.is_in_group("unit") and not body.is_in_group(player):
		body.queue_free()
		queue_free()
#	queue_free()
