# my final form
# im made of gold and so much more
# a thousand power cords
# a fucking werewolf in a lightning storm
# im a machine on a mission
# this is lightspeed i have no ignition yet
# an imaginary life will tear right through a human flesh
# i feel most real when im not myself
# emancipated liberated from my human shell
# salvation in a digital heaven
# cause real life is hell

extends Node

signal initialized
signal lobby_loaded

var main_menu:CanvasLayer

const LOBBY = preload("res://scenes/lobby.tscn")
const CLIENT_ID = "1229029126980112476"

#var label:Label
#var button:Button
var user:User = null
var lobby:Lobby = null
var temp_image:ImageTexture
var load_cancel_flag:bool = false

class User:
	var name:String
	var handle:String
	var id:int
	var avatar:String
	
	func _init(name:String, handle:String, id:int, avatar:String) -> void:
		self.name = name
		self.handle = handle
		self.id = id
		self.avatar = avatar
		print(self)
	
	func _to_string() -> String:
		return "%s (@%s)" % [name, handle]

class Lobby:
	var name:String
	var players:Array[Global.User]
	var id:int
	
	func _init(name:String, players:Array[Global.User], id:int) -> void:
		self.name = name
		self.players = players
		self.id = id
	
	func _to_string() -> String:
		return "Lobby {name: %s, players: %s, id: %d}" % [name, players, id]
	
	func tooltip() -> String:
		var out:String = name + "\n"
		if players.size() >= 1: out += "- " + players[0].to_string() + "\n"
		if players.size() >= 2: out += "- " + players[1].to_string() + "\n"
		return out

func _ready():
	print("start")
	await GameSocket.start()

func create_lobby(room_name:String) -> Lobby: #todo
	var lobby:Lobby = Lobby.new(room_name, [user], 0)
	return lobby

func load_lobby(lobby:Lobby) -> void: #todo
	print(lobby)
	await _loading_screen()
	if not load_cancel_flag: 
		main_menu.hide()
		var l = LOBBY.instantiate()
		get_tree().root.add_child(l)
		self.lobby = lobby
	load_cancel_flag = false
	return

func _loading_screen() -> void:
	var loading_screen = main_menu.loading_screen
	loading_screen.scale = Vector2.ZERO
	loading_screen.show()
	#var tw := create_tween()
	create_tween().tween_property(loading_screen, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUINT)
	_join_lobby()
	await lobby_loaded
	if load_cancel_flag:
		await create_tween().tween_property(loading_screen, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_QUINT).finished
	loading_screen.hide()

func _join_lobby() -> void:
	await get_tree().create_timer(2.0).timeout
	lobby_loaded.emit()
