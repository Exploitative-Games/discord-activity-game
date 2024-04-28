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

const CLIENT_ID = "1229029126980112476"
const DEFAULT_AVATAR = preload("res://assets/default_avatar.tres")

#var label:Label
#var button:Button
var lobby:Lobby = null
var load_cancel_flag:bool = false
var opponent_avatar:Texture2D = null
var user_avatar:Texture2D = null
var user:User = null

class User:
	var name:String
	var handle:String
	var id:int
	var avatar:String
	
	func _init(name:String, handle:String, discriminator:int, id:int, avatar:String) -> void:
		self.name = name
		self.handle = handle
		self.id = id
		if avatar == "":
			if discriminator > 0:
				self.avatar = "https://cdn.discordapp.com/embed/avatars/%d.png" % [discriminator % 5]
			else:
				self.avatar = "https://cdn.discordapp.com/embed/avatars/%d.png" % [(id >> 22) % 6]
		else:
			self.avatar = "https://cdn.discordapp.com/avatars/%d/%s.png?size=256" % [id, avatar]
	
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
	await GameSocket.start()

func create_lobby(_room_name:String = "") -> Lobby:
	#var lobby:Lobby = Lobby.new(room_name, [user], 0)
	var res := await GameSocket.create_lobby()
	var players:Array[User] = [user]
	var lobby := Lobby.new("", players, res["lobby_id"])
	return lobby

func load_lobby(lob:Lobby, new:bool = false) -> void:
	if not new: await _loading_screen(lob.id)
	if not load_cancel_flag: 
		main_menu.hide()
		#var l = LOBBY.instantiate()
		#get_tree().root.add_child(l)
		GameLobby.load_lobby()
		lobby = lob
	load_cancel_flag = false
	await get_tree().physics_frame
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
	var url = user.avatar
	print("[FETCH] getting the image from url:", url)
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
