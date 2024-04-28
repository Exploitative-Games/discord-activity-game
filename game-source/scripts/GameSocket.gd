extends Node

signal create_lobby_received(res:Dictionary)
signal join_lobby_received(res:Dictionary)
signal leave_lobby_received(res:Dictionary)
signal get_lobby_list_received(res:Dictionary)
signal vote_received(res:Dictionary)

signal player_joined_received(res:Dictionary)
signal player_left_received(res:Dictionary)
signal game_start_received(res:Dictionary)
signal game_start_countdown_start_received(res:Dictionary)

signal ping_received

signal connection_failed
signal reconnect

@onready var sock:WebSocketPeer

const PING_INTERVAL:float = 5.0
const CONNECTION_TIMEOUT_INTERVAL:float = 10.0

var TOKEN:String # scary
var ping_timer:Timer

func _connect_signals():
	player_joined_received.connect(Callable(self, "_on_player_joined"))

func _ready() -> void:
	set_process(false)
	_connect_signals()

func start() -> void:
	sock = WebSocketPeer.new()
	
	sock.connect_to_url("wss://" + Global.CLIENT_ID + ".discordsays.com/ws")
	while true:
		sock.poll()
		if sock.get_ready_state() == WebSocketPeer.STATE_OPEN:
			break
		await get_tree().physics_frame
	
	_authenticate()
	
	var timer := get_tree().create_timer(CONNECTION_TIMEOUT_INTERVAL)
	while true:
		sock.poll()
		if sock.get_available_packet_count():
			var res := _get_response()
			var d:Dictionary = res["d"]
			TOKEN = d["access_token"]
			res["d"]["access_token"] = "[HIDDEN]"
			print("[PACKET] ", res)
			Global.user = dict_to_user(d["user"])
			break
		await get_tree().physics_frame
		if timer.time_left == 0:
			printerr("connection timed out")
			sock.close(-1, "connection timed out")
			connection_failed.emit()
			await reconnect
			start()
			return
	
	await get_tree().physics_frame
	Global.initialized.emit()
	
	ping_timer = Timer.new()
	add_child(ping_timer)
	ping_timer.wait_time = PING_INTERVAL
	ping_timer.autostart = true
	ping_timer.timeout.connect(Callable(self, "_ping"))
	ping_timer.start()
	
	set_process(true)

func _process(_delta: float) -> void:
	sock.poll()
	match sock.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			while sock.get_available_packet_count():
				var res = _get_response()
				var sig:String = res["op"] + "_received"
				assert(has_signal(sig), "[ERROR] Signal for \"%s\" doesn't exist." % sig)
				#assert(not emit_signal(sig, res["d"]), "[ERROR] Signal for \"%s\" doesn't match the given arguments." % sig)
				var err := emit_signal(sig, res["d"])
				if err:
					print(get_signal_connection_list(sig))
				if res["op"] != "ping": print("[PACKET] ERR: ", err, " ", JSON.stringify(res, "\t", false))
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
	var string := sock.get_packet().get_string_from_ascii()
	var parsed := JSON.parse_string(string) as Dictionary
	return parsed

func dict_to_user(data:Dictionary) -> Global.User:
	var user:Global.User = Global.User.new(
		data["username"] if (data.global_name == "") else data["global_name"],
		data["username"],
		int(data["discriminator"]),
		int(data["id"]),
		data["avatar"]
	)
	return user

func _authenticate():
	var req := {
		"op": "auth",
	}
	
	var access_token = OS.get_environment("DCGAME_ACCESS_TOKEN")
	if OS.is_debug_build() and access_token != "":
		req["d"] = {
			"access_token": access_token
		}
	else:
		DiscordSDK.init(Global.CLIENT_ID)
		await DiscordSDK.dispatch_ready
		var auth = await DiscordSDK.command_authorize("code", ["identify", "guilds"], "")
		
		req["d"] = {
			"code": auth["code"]
		}
		
	sock.poll()
	_send_request(req)

func _ping() -> void:
	var req := {
		"op": "ping",
		"d": {}
	}
	_send_request(req)
	var t := Time.get_ticks_msec()
	await ping_received
	print("[PING] delay: ", Time.get_ticks_msec() - t, "ms")

# Below are all the sockets that are sent without a request.
# Signals are used for each socket to handle them easily.

func _on_player_joined(res:Dictionary) -> void:
	pass

# Below are all the socket requests, remember to call them with "await".

func create_lobby() -> Dictionary:
	var req := {
		"op": "create_lobby",
		"d": {}
	}
	_send_request(req)
	return await create_lobby_received

func join_lobby(id:int) -> void:
	var req := {
		"op": "join_lobby",
		"d": {
			"lobby_id": id
		}
	}
	_send_request(req)
	await join_lobby_received
	return

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

func vote(id:int) -> Dictionary:
	var req := {
		"op": "vote",
		"d": {}
	}
	_send_request(req)
	return await vote_received
