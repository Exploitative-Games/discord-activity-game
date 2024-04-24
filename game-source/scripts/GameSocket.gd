extends Node

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
	
	authenticate()
	
	while true:
		sock.poll()
		if sock.get_available_packet_count():
			var res = _get_response()
			TOKEN = res["access_token"]
			Global.user = _dict_to_user(res["user"])
			break
		await get_tree().physics_frame
	
	Global.initialized.emit()
	set_process(true)

func _process(delta: float) -> void:
	sock.poll()
	match sock.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			while sock.get_available_packet_count():
				print("packet: ", sock._get_respose())
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

func _dict_to_user(data:Dictionary) -> Global.User:
	var user:Global.User = Global.User.new(
		data["username"] if (data.global_name == "") else data["global_name"],
		data["username"],
		int(data["id"]),
		data["avatar"]
	)
	return user

func authenticate():
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
