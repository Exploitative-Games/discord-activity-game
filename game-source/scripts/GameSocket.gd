extends Node

# signals are used for each socket to handle them easily

# these ones can be sent using their respective functions.
signal create_lobby_received(res:Dictionary)
signal join_lobby_received(res:Dictionary)
signal leave_lobby_received(res:Dictionary)
signal get_lobby_list_received(res:Dictionary)
signal vote_category_received(res:Dictionary)
signal answer_received(res:Dictionary) # bruh
signal answer_question_received(res:Dictionary)

# these ones are receive-only
signal player_joined_received(res:Dictionary)
signal player_left_received(res:Dictionary)
signal game_start_received(res:Dictionary)
signal game_start_countdown_start_received(res:Dictionary)
signal game_start_countdown_cancel_received(res:Dictionary)
signal game_quiz_start_received(res:Dictionary)
signal turn_change_received(res:Dictionary)

# regularly called ping signal to maintain the socket connection
signal ping_received

# these ones should be obvious
signal connection_failed
signal reconnect

@onready var sock:WebSocketPeer

const PING_INTERVAL:float = 5.0
const CONNECTION_TIMEOUT_INTERVAL:float = 10.0

var TOKEN:String # scary
var ping_timer:Timer

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
	
	var timer := get_tree().create_timer(CONNECTION_TIMEOUT_INTERVAL)
	while true:
		sock.poll()
		if sock.get_available_packet_count():
			var res := _get_response()
			var d:Dictionary = res["d"]
			TOKEN = d["access_token"]
			res["d"]["access_token"] = "[HIDDEN]"
			print("[SOCK] packet received: ", res)
			Global.user = dict_to_user(d["user"])
			break
		await get_tree().physics_frame
		if timer.time_left == 0:
			printerr("[SOCK] connection timed out")
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
				if not has_signal(sig): push_error("[SOCK] Signal for \"%s\" doesn't exist." % sig)
				emit_signal(sig, res["d"])
				if res["op"] != "ping": print("[SOCK] packet received: ", JSON.stringify(res, "\t", false))
		WebSocketPeer.STATE_CONNECTING:
			pass
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CLOSED:
			var code = sock.get_close_code()
			var reason = sock.get_close_reason()
			print("[SOCK] socket closed.\n\tcode: %d\n\treason %s\n\tclean: %s" % [code, reason, code != -1])
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

func vote_category(id:int) -> void:
	var req := {
		"op": "vote_category",
		"d": {
			"category_id": id
		}
	}
	_send_request(req)
	await vote_category_received
	return

func answer_question(answer:String) -> Dictionary:
	var req := {
		"op": "answer_question",
		"d": {
			"answer": answer
		}
	}
	_send_request(req)
	return await answer_received # bruh
	
