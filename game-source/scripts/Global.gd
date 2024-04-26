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
signal avatar_loaded
signal lobby_loaded

var main_menu:CanvasLayer

const LOBBY = preload("res://scenes/lobby.tscn")
const CLIENT_ID = "1229029126980112476"

#var label:Label
#var button:Button
var user:User = null
var lobby:Lobby = null
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

func create_lobby(_room_name:String = "") -> Lobby:
	#var lobby:Lobby = Lobby.new(room_name, [user], 0)
	var res := await GameSocket.create_lobby()
	var players:Array[User] = []
	var lobby := Lobby.new("", players, res["lobby_id"])
	return lobby

func load_lobby(lob:Lobby, new:bool = false) -> void:
	print(lobby)
	if not new: await _loading_screen(lob.id)
	if not load_cancel_flag: 
		main_menu.hide()
		var l = LOBBY.instantiate()
		get_tree().root.add_child(l)
		lobby = lob
	load_cancel_flag = false
	lobby_loaded.emit()
	return

func _loading_screen(id:int) -> void:
	var loading_screen = main_menu.loading_screen
	loading_screen.scale = Vector2.ZERO
	loading_screen.show()
	#var tw := create_tween()
	create_tween().tween_property(loading_screen, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUINT)
	await GameSocket.join_lobby(id)
	if load_cancel_flag:
		await create_tween().tween_property(loading_screen, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_QUINT).finished
	loading_screen.hide()

func get_avatar(user:User) -> Texture2D:
	var url := "https://cdn.discordapp.com/avatars/%d/%s.png?size=256" % [user.id, user.avatar]
	print("fetching the image from: ", url)
	var hreq := HTTPRequest.new()
	add_child(hreq)
	hreq.request(url)
	hreq.request_completed.connect(Callable(self, "_create_avatar_image"))
	var av:Texture2D = await avatar_loaded
	hreq.queue_free()
	return av

func _create_avatar_image(res, _code, _headers, body) -> void:
	if res != HTTPRequest.RESULT_SUCCESS: print("error at fetching, code: ", res)
	var img := Image.new()
	img.load_png_from_buffer(body)
	var tex : = ImageTexture.create_from_image(img)
	avatar_loaded.emit(tex)
