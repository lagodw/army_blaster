extends Node

var network = NetworkedMultiplayerENet.new()
var ip = '127.0.0.1'
var port = 4099
var max_players = 2

var players = {}
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
	
	network.connect("peer_connected", self, "_Peer_Connected")
	network.connect("peer_disconnected", self, "_Peer_Disconnected")
func _Peer_Connected(player_id):
	var new_player = 'P' + str(len(players) + 1)
	players[player_id] = new_player
	print('User ' + str(player_id) + " Connected as " + new_player)
	
	rpc_id(player_id, 'ReceivePlayerNum', new_player)
	if new_player == "P2":
		SendStart()
func _Peer_Disconnected(player_id):
	players.erase(player_id)
	print('User ' + str(player_id) + " Disconnected")
	print('Remaining players: ' + str(players))


remote func SendCounter(player):
	rpc_id(ids[player], "ReceiveCounter", Global.unit_counter)
	Global.unit_counter += 1

func SendStart():
	for player in players:
		ids[players[player]] = player
		rpc_id(player, 'StartGame', players[player])
	Global.player = "P1"
	get_tree().change_scene("res://Worlds/Combat.tscn")
	
remote func ReceiveUnitState(unit_state):
	var unit_id = unit_state.keys()[0]
	if unit_state_collection.has(unit_id):
		if unit_state_collection[unit_id]["T"] < unit_state[unit_id]["T"]:
			unit_state_collection[unit_id] = unit_state[unit_id]
#	else:
#		unit_state_collection[unit_id] = unit_state[unit_id]
	get_node('../Map').update_positions(unit_state_collection)
	
remote func ServerSpawnArmy(receive_player, start, target, id):
	print('received request to spawn from ' + receive_player)
	for send_player in players:
		if players[send_player] != receive_player:
			rpc_id(send_player, 'ReceiveSpawnArmy', receive_player, start, target, id)

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
	print('Successfully connected')
	
func RequestCounter(player):
	rpc_id(1, 'SendCounter', player)
remote func ReceiveCounter(count):
	print('received count ' + str(count))
	Global.unit_counter = count
	Global.waiting_for_server = false
remote func ReceivePlayerNum(num):
	print("You are " + num)
remote func StartGame(player):
	print('starting')
	Global.player = player
	get_tree().change_scene("res://Worlds/Combat.tscn")

func SendUnitState(unit_state):
	rpc_unreliable_id(0, "ReceiveUnitState", unit_state)

func SendSpawnArmy(player, start, target, id):
	rpc_id(1, 'ServerSpawnArmy', player, start, target, id)

remote func ReceiveSpawnArmy(player, start, target, id):
	Global.spawn_army(player, start, target, id)

###########################################
################## BOTH ###################
###########################################

