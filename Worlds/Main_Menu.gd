extends Control

func _ready():
	get_node("MainMenu/Connect").connect("pressed", self, "connect_server")
	get_node("MainMenu/Server").connect("pressed", self, "start_server")
	get_node("MainMenu/StartButton").connect("pressed", self, "start_game")
	get_node("MainMenu/OptionsButton").connect("pressed", self, "options_menu")
	get_node("MainMenu/QuitButton").connect("pressed", self, "quit_game")
	
	get_node("OptionsMenu/CloseOptions").connect('pressed', self, "close_options")
	
	get_node("Lobby/Start").connect("pressed", self, "start_game")

func start_server():
	Server.StartServer()

func connect_server():
	Global.game_mode = 'server'
	Server.ConnectToServer()
	
func start_game():
	Server.SendStart()

func options_menu():
	get_node("OptionsMenu").visible = true
	get_node("MainMenu").visible = false
	
func quit_game():
	get_tree().quit()
	
func _input(event):
	if event is InputEventKey and event.scancode == KEY_S:
		if get_node("MainMenu").visible == true:
			start_server()
	elif event is InputEventKey and event.scancode == KEY_O:
		if get_node("MainMenu").visible == true:
			options_menu()
	elif event is InputEventKey and event.scancode == KEY_Q:
		if get_node("MainMenu").visible == true:
			quit_game()
	elif event is InputEventKey and event.scancode == KEY_C:
		if get_node("MainMenu").visible == true:
			connect_server()
	

func close_options():
	get_node("MainMenu").visible = true
	get_node("OptionsMenu").visible = false
