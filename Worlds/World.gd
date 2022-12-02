extends Node2D

var dragging = false  # Are we currently dragging?
var selected = []  # Array of selected units.
var drag_start = Vector2.ZERO  # Location where drag began.
var drag_end = Vector2.ZERO
var select_rect = RectangleShape2D.new()  # Collision shape for drag box.

var player

func _ready():
	player = Global.player
	
	for i in range(1, Global.num_players + 1):
		var p = 'P' + str(i)
		var start = get_node("StartingPos/" + p)
		get_node("Racks/" + p).player = p
		get_node("Racks/" + p).update_owner()
		get_node("Racks/" + p + '/Rally').global_position = start.global_position
		get_node("Racks/" + p + '/RallyFlag').global_position = start.global_position
		if p == player:
			Global.spawn_army(player, start.position, start.position)
			
	$Camera2D.global_position = get_node("StartingPos/Camera_" + player).global_position

func get_units_in_box(event):
	if event.pressed:
		dragging = true
		drag_start = get_global_mouse_position()
	elif dragging:
		dragging = false
		update()
		drag_end = get_global_mouse_position()
		select_rect.extents = (drag_end - drag_start) / 2
		var space = get_world_2d().direct_space_state
		var query = Physics2DShapeQueryParameters.new()
		query.set_shape(select_rect)
		query.transform = Transform2D(0, (drag_end + drag_start) / 2)
		var new_selected = space.intersect_shape(query)
		selected = get_tree().get_nodes_in_group('selected')
		
		var has_unit = false
		for unit in new_selected:
			if unit.collider.is_in_group('army') and unit.collider.player == player:
				unit.collider.add_to_group('new_selected')
				has_unit = true
		if not has_unit:
			for unit in new_selected:
				if unit.collider.is_in_group('building') and unit.collider.player == player:
					unit.collider.add_to_group('new_selected')
				
		if Input.is_action_pressed('shift') or len(get_tree().get_nodes_in_group('new_selected')) == 0:
			pass
		else:
			get_tree().call_group('selected', 'deselect')
		
		get_tree().call_group('new_selected', 'select')
			
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		get_units_in_box(event)
		
	if event is InputEventMouseMotion and dragging:
		update()
		
#	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed:
#		for unit in selected:
#			var new_path = $Navigation2D.get_simple_path(unit.collider.global_position, event.global_position)
#			unit.path = new_path
	
func _draw():
	if dragging:
		draw_rect(Rect2(drag_start, get_global_mouse_position() - drag_start),
				Color(1, 1, 1, 1), true)

func update_positions(positions):
	for unit in positions.keys():
		for army in get_tree().get_nodes_in_group('army'):
			if unit == army.unit_id and army.player != Global.player:
				army.position = positions[unit]['P']
				for marine in army.get_node('Units').get_children():
					marine.rotate_to(positions[unit]['R'])
				army.get_node('UnitDetection').look_at(positions[unit]['R'])
