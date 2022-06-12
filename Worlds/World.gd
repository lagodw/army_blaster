extends Node2D

var dragging = false  # Are we currently dragging?
var selected = []  # Array of selected units.
var drag_start = Vector2.ZERO  # Location where drag began.
var drag_end = Vector2.ZERO
var select_rect = RectangleShape2D.new()  # Collision shape for drag box.

var player = "P1"

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
#			if unit.collider.is_in_group('unit') and unit.collider.player == player:
			if unit.collider.is_in_group('army'):
				unit.collider.add_to_group('new_selected')
				has_unit = true
		if not has_unit:
			for unit in new_selected:
				if unit.collider.is_in_group('building'):
					unit.collider.add_to_group('new_selected')
				
		if Input.is_action_pressed('shift'):
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
			if unit == army.unit_id:
				army.position = positions[unit]['P']
