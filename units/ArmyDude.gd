extends KinematicBody2D

export (int) var speed = 500
export (PackedScene) var Bullet = preload("res://units/Bullet.tscn")

#var target = Vector2(0, 0)
enum STATES { IDLE, FOLLOW }
var _state = null

var path = []
var target_point_world = Vector2()
var target_position = Vector2()

var velocity = Vector2()
var last_position = Vector2()

export var player = "P1"

var army_units = {'marine': 1}
var hitpoints = 1



func _ready():
	$Timer.wait_time = Global.timer
	
#	if target == Vector2(0, 0):
#		target = self.position
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

	if target_position.length() >0:
		_change_state(STATES.FOLLOW)
	else:
		_change_state(STATES.IDLE)


func _input(event):
	if event.is_action_pressed('touch') and $Outline.visible == true:
		target_position = get_global_mouse_position()
		_change_state(STATES.FOLLOW)

func _change_state(new_state):
	if new_state == STATES.FOLLOW:
		path = get_parent().get_node('TileMap').find_path(global_position, target_position)
		if not path or len(path) == 1:
			_change_state(STATES.IDLE)
			return
		# The index 0 is the starting cell
		# we don't want the character to move back to it in this example
		target_point_world = path[1]
	_state = new_state


func _process(delta):
	if not _state == STATES.FOLLOW:
		return
	var arrived_to_next_point = move_to(target_point_world)
	if arrived_to_next_point:
		path.remove(0)
		if len(path) == 0:
			_change_state(STATES.IDLE)
			return
		target_point_world = path[0]


func move_to(world_position):
	var ARRIVE_DISTANCE = 10.0

	var desired_velocity = (world_position - position).normalized() * speed
	var steering = desired_velocity - velocity
	velocity += steering
#	position += velocity * get_process_delta_time()
	move_and_slide(velocity)
	rotation = velocity.angle()
	return position.distance_to(world_position) < ARRIVE_DISTANCE


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
