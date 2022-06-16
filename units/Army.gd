extends KinematicBody2D
class_name Army

export (PackedScene) var Marine = preload("res://units/Marine.tscn")

export (int) var speed = 250
export (PackedScene) var Bullet = preload("res://units/Bullet.tscn")

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

var army_units = {'Marine': 0}
var hitpoints = 1

var unit_id


func _ready():
	set_process(true)
	
	$Timer.wait_time = Global.timer
	
	$CombineArea.connect('body_entered', self, 'combine_army')
	$Timer.connect('timeout', self, 'check_for_armies')
	
#	player = Global.player
#
#	Server.RequestCounter(player)
#	while Global.waiting_for_server:
#		yield(get_tree().create_timer(.01), "timeout")
#	Global.waiting_for_server = true
#	unit_id = Global.unit_counter
	
	if target_position.length() >0:
		_change_state(STATES.FOLLOW)
	else:
		_change_state(STATES.IDLE)
		
	for unit in $Units.get_children():
		unit.player = player
		if "Marine" in unit.name:
			army_units['Marine'] += 1
	
	self.add_to_group(player)
	if player == "P1":
		get_node("Flag").modulate = Color.blue
		get_node("Outline").modulate = Color.blue
		get_node("NumOutline").modulate = Color.blue
		get_node("UnitCount").add_color_override("font_color", Color.blue)
	elif player == "P2":
		get_node("Flag").modulate = Color.red
		get_node("Outline").modulate = Color.red
		get_node("NumOutline").modulate = Color.red
		get_node("UnitCount").add_color_override("font_color", Color.red)
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
#		for unit in $Units.get_children():
#			unit.move_animation()
		path = get_parent().get_node('TileMap').find_path(global_position, target_position)
		if not path or len(path) == 1:
			_change_state(STATES.IDLE)
			return
		# The index 0 is the starting cell
		# we don't want the character to move back to it in this example
		target_point_world = path[1]
	elif new_state == STATES.IDLE:
		for unit in $Units.get_children():
			unit.stop_animation()
	_state = new_state

func _process(delta):
	if player != Global.player:
		return
		
	if rotating:
		for unit in $Units.get_children():
			unit.rotate_to(get_global_mouse_position())
		$UnitDetection.look_at(get_global_mouse_position())
		rotate_target = get_global_mouse_position()
	else:
		rotate_target = target_point_world

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
	remove_from_group('new_selected')
	add_to_group('selected')
	
func deselect():
	$Outline.visible = false
	remove_from_group('selected')

func combine_army(area):
	if area.is_in_group('army') and area.player == player:
		if self.get_instance_id() < area.get_instance_id():
			var offset = global_position - area.global_position
			for unit in area.get_node('Units').get_children():
				army_units['Marine'] += 1
				unit.name = "Marine" + str(army_units['Marine'])
				area.get_node('Units').remove_child(unit)
				$Units.add_child(unit)
				unit.position -= offset
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
	var count = 0
	for unit in army_units:
		count += army_units[unit]
	$UnitCount.text = str(count)
	var circle_scale = min(.2 + count * .025, .4)
	$Outline.scale = Vector2(circle_scale, circle_scale)
	
func take_damage(dmg):
	var new_hp = hitpoints - dmg
	while new_hp <= 0.000001:
		if army_units['Marine'] == 1:
			die()
		else:
			get_node("Units/Marine" + str(army_units['Marine'])).queue_free()
			army_units['Marine'] -= 1
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
