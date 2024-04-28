extends CanvasLayer

signal selection_finished

@onready var msg_history: VBoxContainer = $Messages/VBoxContainer/Panel/ScrollContainer/VBoxContainer
@onready var line: LineEdit = $Messages/VBoxContainer/LineEdit
@onready var category_select: Panel = $"Category Select"

@onready var player_1: HBoxContainer = $"Players/HBoxContainer/Player 1"
@onready var player_2: HBoxContainer = $"Players/HBoxContainer/Player 2"

const MESSAGE = preload("res://scenes/message.tscn")

var players:Array[Global.User]
var timer:SceneTreeTimer
var counter:Label
var selected_category:int = 1

func _connect_signals():
	for i in range(1,4):
		category_select.get_child(1).get_child(i).pressed.connect(Callable(self, "_on_category_selected").bind(i))
	$Messages/VBoxContainer/Send.pressed.connect(Callable(self, "_on_message_sent"))
	line.text_submitted.connect(Callable(self, "_on_message_sent").unbind(1))
	GameSocket.player_joined_received.connect(Callable(self, "_on_player_joined"))
	GameSocket.game_start_received.connect(Callable(self, "_on_game_start"))
	GameSocket.game_start_countdown_start_received.connect(Callable(self, "_on_game_start_countdown_start"))

func _update_players():
	print(Global.lobby.players)
	#for player in Global.lobby.players:
		#if player.id == Global.user.id:
			#player_2.get_node("VBoxContainer/name").text = player.name
			#player_2.get_node("VBoxContainer/handle").text = "@" + player.handle
			#player_2.get_node("Avatar").texture = await Global.get_avatar(player)
		#else:
			#player_1.get_node("VBoxContainer/name").text = player.name
			#player_1.get_node("VBoxContainer/handle").text = "@" + player.handle
			#player_1.get_node("Avatar").texture = await Global.get_avatar(player)
		
	for player in Global.lobby.players:
		if player.id != Global.user.id:
			player_1.get_node("VBoxContainer/name").text = player.name
			player_1.get_node("VBoxContainer/handle").text = "@" + player.handle
			player_1.get_node("Avatar").texture = await Global.get_avatar(player)
	player_2.get_node("VBoxContainer/name").text = Global.user.name
	player_2.get_node("VBoxContainer/handle").text = "@" + Global.user.handle
	player_2.get_node("Avatar").texture = await Global.get_avatar(Global.user)

func _ready() -> void:
	_connect_signals()
	
func load():
	Global.main_menu.hide()
	show()
	await Global.lobby_loaded
	_update_players()

func _on_game_start(res:Dictionary):
	category_select.scale = Vector2.ZERO
	category_select.show()
	create_tween().tween_property(category_select, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUINT)
	_timer($"Category Select/Counter", 10)
	await selection_finished
	
	line.grab_focus()

func _on_game_start_countdown_start(res:Dictionary):
	_timer($Messages/VBoxContainer/Panel/Counter, res["countdown"])
	print("it werks")

func _physics_process(_delta: float) -> void:
	if timer != null:
		counter.text = "%.1f" % timer.time_left

func _on_player_joined(res:Dictionary):
	var new_player := GameSocket.dict_to_user(res["player"])
	if new_player.id == Global.user.id: return
	Global.lobby.players.append(new_player)
	player_1.get_node("VBoxContainer/name").text = new_player.name
	player_1.get_node("VBoxContainer/handle").text = "@" + new_player.handle
	player_1.get_node("Avatar").texture = await Global.get_avatar(new_player)

func _timer(label:Label, secs:int) -> void:
	counter = label
	timer = get_tree().create_timer(secs)
	await timer.timeout
	counter = null
	timer = null

func _on_category_selected(idx:int):
	category_select.get_child(1).get_child(selected_category).get_node("Right Arrow").hide()
	category_select.get_child(1).get_child(idx).get_node("Right Arrow").show()
	selected_category = idx

func _on_message_sent():
	if line.text.length() > 0:
		_send(line.text)
		line.clear()

func _send(answer:String):
	var msg:Message = MESSAGE.instantiate()
	msg.direction = Message.Directions.Right
	msg.text = answer
	msg_history.add_child(msg)
	await get_tree().physics_frame
	msg.show()
