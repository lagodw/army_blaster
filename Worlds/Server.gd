extends Node

var network = NetworkedMultiplayerENet.new()
var ip = '127.0.0.1'
var port = 4099
var max_players = 4
var game_started = false

var players = {}
var player_assignments = []
var opponents = {}
var player_moves = {}
var player_deployments = {}
var ids = {}

var unit_state_collection = {}

###########################################
################# HOSTING #################
###########################################
func _ready():
#	StartServer()
	pass
func StartServer():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	print('Server Started')
	Global.game_mode = 'server'
	
	player_assignments = [1]
	get_node("/root/Main_Menu/Lobby").visible = true
	get_node("/root/Main_Menu/Lobby/P1").visible = true
	get_node("/root/Main_Menu/Lobby/Start").visible = true
	
	network.connect("peer_connected", self, "_Peer_Connected")
	network.connect("peer_disconnected", self, "_Peer_Disconnected")
func _Peer_Connected(player_id):
	var new_player_assignment = player_assignments.max() + 1
	player_assignments.append(new_player_assignment)
	
	var new_player = 'P' + str(new_player_assignment)
	players[player_id] = new_player
	print('User ' + str(player_id) + " Connected as " + new_player)
	
	rpc_id(player_id, 'ReceivePlayerNum', new_player)
	if not game_started:
		get_node("/root/Main_Menu/Lobby/"+new_player).visible = true
#	if new_player == "P2":
#		SendStart()
func _Peer_Disconnected(player_id):
	var player_assignment = players[player_id][1]
	
	if not game_started:
		get_node("/root/Main_Menu/Lobby/"+players[player_id]).visible = false
	
	player_assignments.erase(int(player_assignment))
	players.erase(player_id)
	print('User ' + str(player_id) + " Disconnected")
	print('Remaining players: ' + str(players))


remote func SendCounter(player):
	rpc_id(ids[player], "ReceiveCounter", Global.unit_counter)
	Global.unit_counter += 1

func SendStart():
	game_started = true
	Global.unit_counter = 1
	Global.player = "P1"
	Global.num_players = player_assignments.max()
	for player in players:
		ids[players[player]] = player
		rpc_id(player, 'StartGame', players[player], player_assignments.max())
	get_tree().change_scene("res://Worlds/Combat.tscn")
	
remote func ReceiveUnitState(unit_state):
	var unit_id = unit_state.keys()[0]
	if unit_state_collection.has(unit_id):
		if unit_state_collection[unit_id]["T"] < unit_state[unit_id]["T"]:
			unit_state_collection[unit_id] = unit_state[unit_id]
	get_node('../Map').update_positions(unit_state_collection)
	
#remote func ServerSpawnArmy(receive_player, start, target, id):
#	print('received request to spawn from ' + receive_player)
#	for send_player in players:
#		if players[send_player] != receive_player:
#			rpc_id(send_player, 'ReceiveSpawnArmy', receive_player, start, target, id)

###########################################
################## PLAYER #################
###########################################
func ConnectToServer():
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	
	network.connect('connection_failed', self, "_OnConnectionFailed")
	network.connect('connection_succeeded', self, "_OnConnectionSucceeded")
func _OnConnectionFailed():
	print('Failed to connect')
func _OnConnectionSucceeded():
	get_node("/root/Main_Menu/Lobby").visible = true
	get_node("/root/Main_Menu/Lobby/WaitingMsg").visible = true
	print('Successfully connected')
	
func RequestCounter(player):
	if Global.player == "P1":
		ReceiveCounter(Global.unit_counter)
		Global.unit_counter += 1
	else:
		rpc_id(1, 'SendCounter', player)
remote func ReceiveCounter(count):
	print('received count ' + str(count))
	Global.unit_counter = count
	Global.waiting_for_server = false
remote func ReceivePlayerNum(num):
	print("You are " + num)
remote func StartGame(player, num_players):
	print('starting')
	Global.player = player
	Global.num_players = num_players
	get_tree().change_scene("res://Worlds/Combat.tscn")

func SendUnitState(unit_state):
	rpc_unreliable_id(0, "ReceiveUnitState", unit_state)

func SendSpawnArmy(player, start, target, id):
	rpc_id(0, 'ReceiveSpawnArmy', player, start, target, id)

remote func ReceiveSpawnArmy(player, start, target, id):
	Global.spawn_army(player, start, target, id)

###########################################
################## BOTH ###################
###########################################

