extends KinematicBody2D
class_name Army

export (PackedScene) var Marine = preload("res://units/Marine.tscn")
export (PackedScene) var MarineTen = preload("res://units/Marine10.tscn")
export (PackedScene) var MarineHundred = preload("res://units/Marine100.tscn")

export (int) var speed = 250

enum STATES { IDLE, FOLLOW }
var _state = null

var path = []
var target_point_world = Vector2()
var target_position = Vector2()
var rotating = false
var rotate_target

var velocity = Vector2()
var last_position = Vector2()

export var player = "P1"

var army_units = {'Marine': 0, 'MarineTen': 0, 'MarineHundred': 0}
var hitpoints = 1

var unit_id
var army_count = 0

func _ready():
	set_process(true)
	
	$Timer.wait_time = Global.timer
	
	$CombineArea.connect('body_entered', self, 'combine_army')
	$Timer.connect('timeout', self, 'check_for_armies')
	
	if target_position.length() >0:
		_change_state(STATES.FOLLOW)
	else:
		_change_state(STATES.IDLE)
		
	for unit in $Units.get_children():
		unit.player = player
		if "Marine" in unit.name:
			army_units['Marine'] += 1
	
	self.add_to_group(player)
	
	get_node("Flag").modulate = Global.player_colors[player]
	get_node("Outline").modulate = Global.player_colors[player]
	get_node("NumOutline").modulate = Global.player_colors[player]
	get_node("UnitCount").add_color_override("font_color", Global.player_colors[player])
	
	update_counter()
	
	$Health.max_value = 100
	update_hp()

func _input(event):
	if event.is_action_pressed('touch') and is_in_group('selected'):
		target_position = get_global_mouse_position()
		$UnitDetection.look_at(get_global_mouse_position())
		for unit in $Units.get_children():
			unit.rotate_to(get_global_mouse_position())
		_change_state(STATES.FOLLOW)
	elif event.is_action_pressed('rotate') and is_in_group('selected'):
		rotating = true
	elif event.is_action_released('rotate'):
		rotating = false

func _change_state(new_state):
	if new_state == STATES.FOLLOW:
		path = get_parent().get_node('TileMap').find_path(global_position, target_position)
		if not path or len(path) == 1:
			_change_state(STATES.IDLE)
			return
		# The index 0 is the starting cell
		# we don't want the character to move back to it in this example
		target_point_world = path[1]
		if is_in_group('selected'):
			$MoveTarget.visible = true
	elif new_state == STATES.IDLE:
		for unit in $Units.get_children():
			unit.stop_animation()
		$MoveTarget.visible = false
	_state = new_state

func _process(delta):
	if player != Global.player:
		return
		
	if rotating:
		rotate_target = get_global_mouse_position()
		
	if (global_position - rotate_target).length() < 80:
		rotate_target = global_position + rotate_target.normalized() * 80

	for unit in $Units.get_children():
		unit.rotate_to(rotate_target)
	$UnitDetection.look_at(rotate_target)

	Server.SendUnitState({unit_id:{'T':OS.get_system_time_msecs(),
	  "P":get_global_position(), "R":rotate_target}})

	if not _state == STATES.FOLLOW:
		return
	var arrived_to_next_point = move_to(target_point_world)
	if arrived_to_next_point:
		path.remove(0)
		if len(path) == 0:
			_change_state(STATES.IDLE)
			return
		target_point_world = path[0]
		rotate_target = target_point_world
	
	$MoveTarget.global_position = target_position


func move_to(world_position):
	var ARRIVE_DISTANCE = 10.0

	var desired_velocity = (world_position - position).normalized() * speed
	var steering = desired_velocity - velocity
	velocity += steering
	move_and_slide(velocity)
	for unit in $Units.get_children():
		unit.move_animation(rad2deg(velocity.angle_to_point(Vector2(0, 0))))
	return position.distance_to(world_position) < ARRIVE_DISTANCE

func select():
	$Outline.visible = true
	if _state == STATES.FOLLOW:
		$MoveTarget.visible = true
	remove_from_group('new_selected')
	add_to_group('selected')
	
func deselect():
	$Outline.visible = false
	$MoveTarget.visible = false
	remove_from_group('selected')

func combine_army(area):
	if area.is_in_group('army') and area.player == player:
		
		# Only want to combine armies if there is no barrier between them
		var state_space = get_world_2d().direct_space_state
		var sight_check = state_space.intersect_ray(position, area.position, 
		get_node('Units').get_children(), 1, true, true)
		if len(sight_check) > 0:
			if sight_check.collider.name == "TileMap":
				return
			
		# Merge into the bigger army or if tied merge into the first created
		if (army_count > area.army_count) or (army_count == area.army_count and 
		self.get_instance_id() < area.get_instance_id()):
			var offset = global_position - area.global_position
			for unit in area.get_node('Units').get_children():
				#TODO: switch this to a unit property to distinguish type
				if unit.name[6] == "T":
					army_units['MarineTen'] += 1
					unit.name = "MarineTen" + str(army_units['MarineTen'])
				elif unit.name[6] == "H":
					army_units['MarineHundred'] += 1
					unit.name = "MarineHundred" + str(army_units['MarineHundred'])
				else:
					army_units['Marine'] += 1
					unit.name = "Marine" + str(army_units['Marine'])
				area.get_node('Units').remove_child(unit)
				$Units.add_child(unit)
				unit.position -= offset
				
			if _state == STATES.IDLE:
				target_position = area.target_position
				_change_state(STATES.FOLLOW)
			area.queue_free()
			
			if area.is_in_group('selected') and not is_in_group('selected'):
				select()
			update_counter()

func check_for_armies():
	var units_in_range = $UnitDetection.get_overlapping_bodies()
	for unit in units_in_range:
		if unit.is_in_group('army') and not unit.is_in_group(player) and (last_position - position).length() <= 10:
			var space_state = get_world_2d().direct_space_state
			var sight_check = space_state.intersect_ray(position, unit.position, [self], 4)
			if len(sight_check) == 0:
				order_shoot()
	last_position = position
	
func order_shoot():
	for unit in $Units.get_children():
		unit.shoot()
		
func update_counter():
	# Sometimes when merging the names get messed up and end up as @Marine5@@20
	# https://godotengine.org/qa/82028/how-to-get-a-name-with-all-signs
	# Strip off the extra stuff
	for unit in get_node("Units").get_children():
		if unit.name[0] == '@':
			unit.name = unit.name.split('@')[1]
	if army_units['Marine'] >= 10:
		for i in range(army_units['Marine'], army_units['Marine'] - 10, -1):
			get_node("Units/Marine" + str(i)).queue_free()
		army_units['Marine'] -= 10
		spawn_unit('MarineTen')
	if army_units['MarineTen'] >= 10:
		for i in range(army_units['MarineTen'], army_units['MarineTen'] - 10, -1):
			get_node("Units/MarineTen" + str(i)).queue_free()
		army_units['MarineTen'] -= 10
		spawn_unit('MarineHundred')

	army_count = army_units['Marine'] + army_units['MarineTen'] * 10 + \
	  army_units['MarineHundred'] * 100
	$UnitCount.text = str(army_count)
	
func take_damage(dmg):
	var new_hp = hitpoints - dmg
	while new_hp <= 0.000001:
		if (army_units['Marine'] == 1) and (army_units['MarineTen'] == 0):
			die()
		else:
			if army_units['Marine'] > 0:
				get_node("Units/Marine" + str(army_units['Marine'])).queue_free()
				army_units['Marine'] -= 1
			elif army_units['MarineTen'] > 0:
				get_node("Units/MarineTen" + str(army_units['MarineTen'])).queue_free()
				army_units['MarineTen'] -= 1
				for i in range(1, 10):
					spawn_unit('Marine')
			elif army_units['MarineHundred'] > 0:
				get_node("Units/MarineHundred" + str(army_units['MarineHundred'])).queue_free()
				army_units['MarineHundred'] -= 1
				for i in range(1, 10):
					spawn_unit('MarineTen')
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
	self.queue_free()

func spawn_unit(type):
	var unit
	if type == "Marine":
		unit = Marine.instance()
	elif type == "MarineTen":
		unit = MarineTen.instance()
	elif type == "MarineHundred":
		unit = MarineHundred.instance()
	army_units[type] += 1
	unit.name = type + str(army_units[type])
	unit.player = player
	get_node('Units').add_child(unit)
	
	# spawning new units on same location will cause them to stick together
	# add some rng just to spread them out
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var r1 = rng.randf_range(-30.0, 30.0)
	var r2 = rng.randf_range(-30.0, 30.0)
	unit.global_position = self.global_position + Vector2(r1, r2)
