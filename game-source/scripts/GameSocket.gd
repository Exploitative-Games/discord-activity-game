extends Node

signal create_lobby_received(res:Dictionary)
signal join_lobby_received(res:Dictionary)
signal leave_lobby_received(res:Dictionary)
signal get_lobby_list_received(res:Dictionary)

@onready var sock:WebSocketPeer

var TOKEN:String # scary

func _ready() -> void:
	set_process(false)

func start() -> void:
	sock = WebSocketPeer.new()
	
	sock.connect_to_url("wss://" + Global.CLIENT_ID + ".discordsays.com/ws")
	while true:
		sock.poll()
		if sock.get_ready_state() == WebSocketPeer.STATE_OPEN:
			break
		await get_tree().physics_frame
	
	_authenticate()
	
	while true:
		sock.poll()
		if sock.get_available_packet_count():
			var res := _get_response()
			print("packet received: ", res)
			var d:Dictionary = res["d"]
			TOKEN = d["access_token"]
			Global.user = dict_to_user(d["user"])
			break
		await get_tree().physics_frame
	
	await get_tree().physics_frame
	Global.initialized.emit()
	set_process(true)

func _process(delta: float) -> void:
	sock.poll()
	match sock.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			while sock.get_available_packet_count():
				var res = _get_response()
				emit_signal(res["op"] + "_received", res["d"])
				print("packet received: ", res)
		WebSocketPeer.STATE_CONNECTING:
			pass
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CLOSED:
			var code = sock.get_close_code()
			var reason = sock.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			set_process(false)

func _send_request(req:Dictionary) -> void:
	var err = sock.send_text(JSON.stringify(req))
	if err != OK: printerr("error sending request, code: ", err)

func _get_response() -> Dictionary:
	var str := sock.get_packet().get_string_from_ascii()
	var parsed := JSON.parse_string(str) as Dictionary
	return parsed

func dict_to_user(data:Dictionary) -> Global.User:
	var user:Global.User = Global.User.new(
		data["username"] if (data.global_name == "") else data["global_name"],
		data["username"],
		int(data["id"]),
		data["avatar"]
	)
	return user

func _authenticate():
	DiscordSDK.init(Global.CLIENT_ID)
	await DiscordSDK.dispatch_ready
	var auth = await DiscordSDK.command_authorize("code", ["identify", "guilds"], "")
	var req := {
		"op": "auth",
		"d": {
			"code": auth["code"]
		}
	}
	sock.poll()
	_send_request(req)

# below are all the socket requests, remember to call them with "await"

func create_lobby() -> Dictionary:
	var req := {
		"op": "create_lobby",
		"d": {}
	}
	_send_request(req)
	return await create_lobby_received

func join_lobby(id:int) -> Dictionary:
	var req := {
		"op": "join_lobby",
		"d": {
			"lobby_id": id
		}
	}
	_send_request(req)
	return await join_lobby_received

func leave_lobby() -> Dictionary:
	var req := {
		"op": "leave_lobby",
		"d": {}
	}
	_send_request(req)
	return await leave_lobby_received

func get_lobby_list() -> Dictionary:
	var req := {
		"op": "get_lobby_list",
		"d": {}
	}
	_send_request(req)
	return await get_lobby_list_received
