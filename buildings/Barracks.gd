extends KinematicBody2D

export var player = "P0"
var max_status = 100
var capture_status
var spawn_radius = 250
export var spawn_start = Vector2() #should be global position

export (PackedScene) var Marine = preload("res://units/Army.tscn")

func _ready():

	capture_status = max_status
	$Progress.max_value = max_status
	$Progress.value = capture_status

	$CaptureTimer.wait_time = Global.timer
	$CaptureTimer.connect('timeout', self, '_on_timeout')
	update_owner()
	
	if spawn_start:
		set_rally(spawn_start)
	
	$SpawnTimer.connect('timeout', self, 'spawn_marine')
	
func _on_timeout():
	var units = $CaptureZone.get_overlapping_bodies()
	var players = {'P0': 0, 'P1': 0, 'P2': 0, 'P3': 0, 'P4': 0}
	for unit in units:
		if unit.is_in_group('army'):
			players[unit.player] += unit.army_units['Marine'] + \
			unit.army_units['MarineTen'] * 10 + unit.army_units['MarineHundred'] * 100
	
	var max_player
	var max_amount = 0
	var second_amount = 0
	for player in players:
		if players[player] > max_amount:
			second_amount = max_amount
			max_amount = players[player]
			max_player = player
		if players[player] > second_amount and player != max_player:
			second_amount = players[player]
	
	var change = max_amount - second_amount
	if player == max_player:
		capture_status = min(capture_status + change, max_status)
	else:
		capture_status -= change
		if capture_status <= 0:
			player = max_player
			update_owner()
	$Progress.value = capture_status

func update_owner():
	
	if player in ["P1", "P2", "P3", "P4"]:
		get_node("icon").modulate = Global.player_colors[player]
		$Progress.tint_progress = Global.player_colors[player]
		$Outline.modulate = Global.player_colors[player]
		$RallyFlag.modulate = Global.player_colors[player]
	else:
		deselect()
		get_node('icon').modulate = Color.gray
		$Progress.tint_progress = Color.gray
	
func _input(event):
	if event.is_action_pressed('touch') and is_in_group('selected'):
		var target_position = get_global_mouse_position()
		set_rally(target_position)

func set_rally(target_position):
		$Rally.global_position = target_position
		$RallyFlag.global_position = target_position
		
		if $Rally.position.length() < spawn_radius:
			$Rally.position = $Rally.position.normalized() * spawn_radius
			$RallyFlag.position = $RallyFlag.position.normalized() * spawn_radius
		
		$SpawnPoint.position = $Rally.position.normalized() * spawn_radius

		
func spawn_marine():
	if player == Global.player:
		Global.spawn_army(player, $SpawnPoint.global_position
		  , $Rally.global_position, null)

func select():
	if player != "P0":
		$Outline.visible = true
		$RallyFlag.visible = true
		remove_from_group('new_selected')
		add_to_group('selected')
	
func deselect():
	$Outline.visible = false
	$RallyFlag.visible = false
	remove_from_group('selected')
	
