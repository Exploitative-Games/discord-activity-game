extends Node

@onready var sock:WebSocketPeer = WebSocketPeer.new()

const URL:String = "https://pchy.fun"

func _init() -> void:
	set_process(false)

func start() -> void:
	sock.connect_to_url(URL)
	set_process(true)

func _process(delta: float) -> void:
	sock.poll()
	match sock.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			while sock.get_available_packet_count():
				print("packet: ", sock.get_packet())
		WebSocketPeer.STATE_CONNECTING:
			pass
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CLOSED:
			var code = sock.get_close_code()
			var reason = sock.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			set_process(false)
