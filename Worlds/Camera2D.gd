extends Camera2D

const MAX_ZOOM_LEVEL = .5
const MIN_ZOOM_LEVEL = 4
const ZOOM_INCREMENT = 0.05

var scroll_margin = 100
var scroll_amount = 50

var LEFT_LIMIT = -80000
var TOP_LIMIT = -58000
var RIGHT_LIMIT = 160000
var BOTTOM_LIMIT = 110000

signal moved()
signal zoomed()

var _current_zoom_level = 4
var _drag = false

var size

func _physics_process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	size = get_viewport_rect().size
	
	if mouse_pos.x >= size.x - scroll_margin:
		position.x += scroll_amount
	elif mouse_pos.x <= scroll_margin:
		position.x -= scroll_amount
	if mouse_pos.y >= size.y - scroll_margin:
		position.y += scroll_amount
	elif mouse_pos.y <= scroll_margin:
		position.y -= scroll_amount


func _input(event):
	if event.is_action("cam_zoom_in"):
		_update_zoom(-ZOOM_INCREMENT, get_global_mouse_position())
	elif event.is_action("cam_zoom_out"):
		_update_zoom(ZOOM_INCREMENT, get_global_mouse_position())


func _update_zoom(incr, zoom_anchor):
	if check_for_panel(zoom_anchor):
		return
	
	var old_zoom = _current_zoom_level
	_current_zoom_level += incr
	if _current_zoom_level < MAX_ZOOM_LEVEL:
		_current_zoom_level = MAX_ZOOM_LEVEL
	elif _current_zoom_level > MIN_ZOOM_LEVEL:
		_current_zoom_level = MIN_ZOOM_LEVEL
	if old_zoom == _current_zoom_level:
		return
	
	var zoom_center = zoom_anchor - position
	var ratio = 1-_current_zoom_level/old_zoom
	
	size = get_viewport_rect().size
	var width = size.x
	var height = size.y
	var new_position = position + zoom_center*ratio
	new_position.x = clamp(new_position.x, LEFT_LIMIT + (width * _current_zoom_level) / 2
	, RIGHT_LIMIT - (width * _current_zoom_level) / 2)
	new_position.y = clamp(new_position.y, TOP_LIMIT + (height * _current_zoom_level) / 2
	, BOTTOM_LIMIT - (height * _current_zoom_level) / 2)
	
	if width > (RIGHT_LIMIT - LEFT_LIMIT) / _current_zoom_level:
		new_position.x = (RIGHT_LIMIT + LEFT_LIMIT) / 2
	if height > (BOTTOM_LIMIT - TOP_LIMIT) / _current_zoom_level:
		new_position.y = (BOTTOM_LIMIT + TOP_LIMIT) / 2

	position = new_position
	
	set_zoom(Vector2(_current_zoom_level, _current_zoom_level))
	emit_signal("zoomed")

func check_for_panel(location):
	var space = get_world_2d().direct_space_state
	var local_select_rect = RectangleShape2D.new()
	local_select_rect.extents = Vector2(100, 100)
	var local_query = Physics2DShapeQueryParameters.new()
	local_query.set_shape(local_select_rect)
	local_query.transform = Transform2D(0, location)
	var local_selected = space.intersect_shape(local_query)
	var panel = false
	if len(local_selected) > 0:
		for thing in local_selected:
			if thing.collider.name in ['PlanetPanel', 'ArmyPanel']:
				panel = true
	return(panel)
