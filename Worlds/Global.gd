extends Node

var unit_stats = {
	'marine': {'damage': 0.1, 'hp': 1}
}

var timer = .25

func _ready():
	pass

var player
var waiting_for_server = true
var game_mode = 'single'
