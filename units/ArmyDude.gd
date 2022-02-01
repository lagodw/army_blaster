extends KinematicBody2D

export (int) var speed = 500
export (PackedScene) var Bullet = preload("res://units/Bullet.tscn")

var target = Vector2(0, 0)
var velocity = Vector2()
var last_position = Vector2()

export var player = "P1"

var army_units = {'marine': 1}
var hitpoints = 1

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


func _input(event):
	if event.is_action_pressed('click') and $Outline.visible == true:
		target = get_global_mouse_position()

func _physics_process(delta):
	velocity = (target - position).normalized() * speed
	$Rotating.rotation = velocity.angle()
	if (target - position).length() > 10:
		velocity = move_and_slide(velocity)

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
				for unit in get_parent().selected:
					if unit.collider == self or unit.collider == army:
						get_parent().selected.erase(unit)
						was_selected = true
				if was_selected:
					get_parent().selected.append_array([{'collider': self}])
					self.select()
				army_units = new_units
				var new_position = (position + army.position) / 2
				position = new_position
				army.queue_free()
				update_counter()
				print(get_parent().selected)


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
