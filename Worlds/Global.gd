extends Node

var unit_stats = {
	'marine': {'damage': 0.1, 'hp': 1}
}
var player_colors = {
	'P1': Color.blue,
	'P2': Color.red,
	'P3': Color.green,
	'P4': Color.yellow
}

var player = "P0"
var num_players = 0
var waiting_for_server = true
var game_mode = 'single'

var timer = .25

var unit_counter = 1

export (PackedScene) var army = preload('res://units/Army.tscn')

func _ready():
	pass

func spawn_army(player, start, target, id = null):
	var unit = army.instance()
	unit.global_position = start
	unit.player = player
	unit.target_position = target
	unit.rotate_target = target
	if id != null:
		unit.unit_id = id
	else:
		Server.RequestCounter(player)
		while Global.waiting_for_server:
			yield(get_tree().create_timer(.01), "timeout")
		Global.waiting_for_server = true
		unit.unit_id = Global.unit_counter
	
	Server.unit_state_collection[unit.unit_id] = {"T": OS.get_system_time_msecs(),
	  "P": start, "R": target}
	get_node('/root/Map').add_child(unit)
#	if player != "P0":
	if id == null:
		Server.SendSpawnArmy(player, start, target, unit.unit_id)
