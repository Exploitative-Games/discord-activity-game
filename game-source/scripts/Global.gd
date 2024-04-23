extends Node

signal auth_done
signal user_updated
signal avatar_fetched
signal lobby_loaded

var main_menu:CanvasLayer

const LOBBY = preload("res://scenes/lobby.tscn")
const CLIENT_ID = "1229029126980112476"

#var label:Label
#var button:Button
var user:User = null
var lobby:Lobby = null
var temp_image:ImageTexture
var token # scary
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

var flag:int = 0:
	set(val):
		print("%d -> %d" % [flag, val])
		flag = val
		if flag >= 2:
			auth_done.emit()

func _connect_signals():
	await get_tree().physics_frame
	DiscordSDK.dispatch_current_user_update.connect(Callable(self, "_user_updated"))
	flag += 1

func _ready():
	print("start")
	_connect_signals()
	DiscordSDK.init(CLIENT_ID);
	await DiscordSDK.dispatch_ready;
	var auth = await DiscordSDK.command_authorize("code", ["identify", "guilds"], "");
	var hreq = HTTPRequest.new();
	hreq.accept_gzip = false # funny issue: https://forum.godotengine.org/t/-/37681/19
	add_child(hreq);
	var token_res = hreq.request(
		"https://" + CLIENT_ID + ".discordsays.com/api/auth" + "?code=" + auth["code"],
		["Content-Type: application/x-www-url-encoded"],
		HTTPClient.METHOD_GET,
	)
	var response = await hreq.request_completed
	hreq.queue_free()
	var json = response[3].get_string_from_utf8()
	var token_json = JSON.parse_string(json)
	token = token_json["access_token"]
	var authRes = await DiscordSDK.command_authenticate(token)
	DiscordSDK.subscribe_to_events()
	flag += 1
	print("done")

func _user_updated(data):
	user = User.new(
		data["username"] if (data.global_name == null) else data["global_name"],
		data["username"],
		int(data["id"]),
		data["avatar"]
	)
	user_updated.emit()
	print(data)
	#Global.label.text = str(data)
	#if (data.global_name != null):
		#Global.label.text = data["global_name"] + " (@" + data["username"] + ")"
	#else:
		#Global.label.text = data["username"] + " (@" + data["username"] + ")"

func get_avatar(id:int):
	var hreq = HTTPRequest.new()
	add_child(hreq)
	hreq.request_completed.connect(Callable(self, "_on_request_completed"))
	hreq.request("https://discord.com/api/v10/users/%d" % id , ["Authorization: Bot " + token], HTTPClient.METHOD_GET)
	await avatar_fetched
	hreq.queue_free()
	return temp_image

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200: # Assuming 200 means success
		var user_data = JSON.parse_string(body)
		var avatar_url = "https/cdn.discordapp.com/avatars/525315481767247872/" + user_data["avatar"] + ".png"
		download_avatar(avatar_url)

func download_avatar(url):
	var hreq = HTTPRequest.new()
	add_child(hreq)
	hreq.request_completed.connect(Callable(self, "_on_avatar_download_completed"))
	hreq.request(url)
	await avatar_fetched
	hreq.queue_free()
	return temp_image

func _on_avatar_download_completed(result, response_code, headers, body):
	if response_code == 200: # Assuming 200 means success
		var avatar_texture = ImageTexture.new()
		var image_data = Image.new()
		image_data.load_png_from_buffer(body)
		avatar_texture.create_from_image(image_data)
		temp_image = avatar_texture
		avatar_fetched.emit()
		# Display the avatar texture in your Godot scene

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
