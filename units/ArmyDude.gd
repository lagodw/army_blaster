extends KinematicBody2D

export (int) var speed = 500
var path : PoolVector2Array
var levelNavigation
var index = 0

export (PackedScene) var Bullet = preload("res://units/Bullet.tscn")

var target = Vector2(0, 0)
var velocity = Vector2()
var last_position = Vector2()

export var player = "P1"

var army_units = {'marine': 1}
var hitpoints = 1

onready var line = $Line2D

func _ready():
	$Timer.wait_time = Global.timer
	
	if target == Vector2(0, 0):
		target = self.position
	last_position = self.position
	
	$Health.max_value = 100
	update_hp()
	
	$Timer.connect('timeout', self, '_on_timeout')
	$CombineArea.connect('body_entered', self, 'combine_army')
	
	self.add_to_group(player)
	if player == "P1":
		get_node("Rotating/Flag").modulate = Color.blue
		get_node("Outline").modulate = Color.blue
		get_node("NumOutline").modulate = Color.blue
		get_node("UnitCount").add_color_override("font_color", Color.blue)
	elif player == "P2":
		get_node("Rotating/Flag").modulate = Color.red
		get_node("Outline").modulate = Color.red
		get_node("NumOutline").modulate = Color.red
		get_node("UnitCount").add_color_override("font_color", Color.red)
	update_counter()
	
	generate_path()
	
	yield(get_tree(), "idle_frame")
	if get_tree().has_group('Navigation'):
		levelNavigation = get_tree().get_nodes_in_group('Navigation')[0]


func _input(event):
	if event.is_action_pressed('click') and $Outline.visible == true:
		target = get_global_mouse_position()

#func _physics_process(delta):
#	velocity = (target - position).normalized() * speed
#	$Rotating.rotation = velocity.angle()
#	if (target - position).length() > 10:
#		velocity = move_and_slide(velocity)

#func _physics_process(delta):
#	line.global_position = Vector2.ZERO
#	if levelNavigation and target:
#		generate_path()
#		navigate()
#	move()

func _physics_process(delta):
	generate_path()
	if path:
		var vel : Vector2

		if index < path.size()-1:
			vel = path[index+1] - path[index]
			if close_to_target(global_position, path[index+1]):
				index += 1
		else:
			vel = Vector2.ZERO
		vel = move_and_slide(vel.normalized()*speed)

func close_to_target(a, b):
	var res := false
	var mar := 5
	if (abs(abs(a.x) - abs(b.x)) < mar) and (abs(abs(a.y) - abs(b.y)) < mar):
		res = true
	return res
	
func move():
	velocity = move_and_slide(velocity)

func navigate():
	if path.size() > 0:
		velocity = global_position.direction_to(path[1]) * speed
				
		if global_position == path[0]:
			pass
#			print(typeof(path))
#			path.pop_front()

func generate_path():
	if levelNavigation != null:
		path = levelNavigation.get_simple_path(global_position, target, false)
		line.points = path

func _on_timeout():
	var units_in_range = $Rotating/UnitDetection.get_overlapping_bodies()
	for unit in units_in_range:
		if unit.is_in_group('unit') and not unit.is_in_group(player) and (last_position - position).length() <= 10:
			shoot()	
	last_position = position
	
func shoot():
	var damage = 0
	for unit in army_units:
		damage += Global.unit_stats[unit]['damage'] * army_units[unit]
	var b = Bullet.instance()
	b.player = player
	b.damage = damage
	get_parent().add_child(b)
	b.transform = $Rotating/Muzzle.global_transform
	
func select():
	$Outline.visible = true
	
func deselect():
	$Outline.visible = false

func combine_army(army):
	if army.is_in_group('unit'):
		if army.player == player and army != self:
			if self.get_instance_id() > army.get_instance_id():
				var new_units = {}
				for unit in self.army_units:
					if unit in new_units:
						new_units[unit] += self.army_units[unit]
					else:
						new_units[unit] = self.army_units[unit]
				for unit in army.army_units:
					if unit in new_units:
						new_units[unit] += army.army_units[unit]
					else:
						new_units[unit] = army.army_units[unit]
						
				var was_selected = false
				var remove_unit = []
				for unit in get_parent().selected:
					if unit.collider == self or unit.collider == army:
						remove_unit.append(unit)
						was_selected = true
				for unit in remove_unit:
					get_parent().selected.erase(unit)
				if was_selected:
					get_parent().selected.append_array([{'collider': self}])
					self.select()
				
				army_units = new_units
				var new_position = (position + army.position) / 2
				position = new_position
				army.queue_free()
				update_counter()



func update_counter():
	var count = 0
	for unit in army_units:
		count += army_units[unit]
	$UnitCount.text = str(count)

func take_damage(dmg):
	var new_hp = hitpoints - dmg
	while new_hp <= 0.000001:
		if army_units['marine'] == 1:
			die()
		else:
			army_units['marine'] -= 1
			update_counter()
		new_hp += 1
	hitpoints = new_hp
	update_hp()
	
func update_hp():
	var val = hitpoints * 100
	if val < 100:
		$Health.visible = true
	else:
		$Health.visible = false
	$Health.value = val	
	if val <= 20:
		$Health.tint_progress = Color.lightcoral
	elif val <= 50:
		$Health.tint_progress = Color.yellow
	else:
		$Health.tint_progress = Color.webgreen
	
func die():
	for unit in get_parent().selected:
		if self == unit.collider:
			get_parent().selected.erase(unit)
	self.queue_free()
