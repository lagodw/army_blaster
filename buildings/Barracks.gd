extends KinematicBody2D

var player = "P0"
var max_status = 100
var capture_status

export (PackedScene) var Marine = preload("res://units/ArmyDude.tscn")

func _ready():

	capture_status = max_status
	$Progress.max_value = max_status
	$Progress.value = capture_status

	$CaptureTimer.wait_time = Global.timer
	$CaptureTimer.connect('timeout', self, '_on_timeout')
	update_owner()
	
	$SpawnTimer.connect('timeout', self, 'spawn_marine')
	
func _on_timeout():
	var units = $CaptureZone.get_overlapping_bodies()
	var players = {'P0': 0, 'P1': 0, 'P2': 0}
	for unit in units:
		if unit.is_in_group('unit'):
			players[unit.player] += unit.army_units['marine']
	
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
	if player == "P1":
		get_node("icon").modulate = Color.blue
		$Progress.tint_progress = Color.blue
	elif player == "P2":
		get_node("icon").modulate = Color.red
		$Progress.tint_progress = Color.red
	else:
		get_node('icon').modulate = Color.gray
		$Progress.tint_progress = Color.gray

func spawn_marine():
	if player != 'P0':
		var unit = Marine.instance()
		unit.global_position = $SpawnPoint.global_position
		unit.player = player
		unit.target = $Rally.global_position
		get_parent().add_child(unit)
