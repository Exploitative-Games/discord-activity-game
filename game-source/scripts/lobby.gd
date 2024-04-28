extends CanvasLayer

signal selection_finished

@onready var msg_history: VBoxContainer = $Messages/VBoxContainer/Panel/ScrollContainer/VBoxContainer
@onready var line: LineEdit = $Messages/VBoxContainer/LineEdit
@onready var category_select: Panel = $"Category Select"
@onready var container: VBoxContainer = $"Category Select/VBoxContainer"

@onready var player_1: HBoxContainer = $"Players/HBoxContainer/Player 1"
@onready var player_2: HBoxContainer = $"Players/HBoxContainer/Player 2"

const MESSAGE = preload("res://scenes/message.tscn")

var players:Array[Global.User]
var timer:SceneTreeTimer
var counter:Label
var selected_category:int = 1
var categories:Array

func _connect_signals():
	for i in range(1,4):
		category_select.get_child(1).get_child(i).pressed.connect(Callable(self, "_on_category_selected").bind(i))
	$Messages/VBoxContainer/Send.pressed.connect(Callable(self, "_on_message_sent"))
	line.text_submitted.connect(Callable(self, "_on_message_sent").unbind(1))
	GameSocket.player_joined_received.connect(Callable(self, "_on_player_joined"))
	GameSocket.game_start_received.connect(Callable(self, "_on_game_start"))
	GameSocket.game_start_countdown_start_received.connect(Callable(self, "_on_game_start_countdown_start"))
	GameSocket.game_start_countdown_cancel_received.connect(Callable(self, "_on_game_start_countdown_cancel"))

func _update_players():
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
			Global.opponent_avatar = await Global.get_avatar(player)
			player_1.get_node("VBoxContainer/name").text = player.name
			player_1.get_node("VBoxContainer/handle").text = "@" + player.handle
			player_1.get_node("Avatar").texture = Global.opponent_avatar
	player_2.get_node("VBoxContainer/name").text = Global.user.name
	player_2.get_node("VBoxContainer/handle").text = "@" + Global.user.handle
	player_2.get_node("Avatar").texture = Global.user_avatar

func _ready() -> void:
	_connect_signals()
	
func load_lobby():
	Global.main_menu.hide()
	show()
	await Global.lobby_loaded
	_update_players()

func _on_game_start(res:Dictionary):
	category_select.scale = Vector2.ZERO
	category_select.show()
	create_tween().tween_property(category_select, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUINT)
	_timer($"Category Select/Counter", res["countdown"])
	categories = res["categories"]
	for i in 3:
		$"Category Select/VBoxContainer".get_child(i+1).text = categories[i].name
	await selection_finished
	
	line.grab_focus()

func _on_game_start_countdown_start(res:Dictionary):
	_timer($Messages/VBoxContainer/Panel/Counter, res["countdown"])

func _on_game_start_countdown_cancel(res:Dictionary):
	player_1.get_node("VBoxContainer/name").text = ""
	player_1.get_node("VBoxContainer/handle").text = ""
	player_1.get_node("Avatar").texture = Global.DEFAULT_AVATAR
	for child in container.get_children():
		if child is Button:
			child.disabled = false
			child.get_child(0).hide()
			child.get_child(1).hide()
	category_select.hide()
	timer = null
	counter = null
	$Messages/VBoxContainer/Panel/Counter.text = "waiting for another player"

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

var tflag:int = 0
func _timer(label:Label, secs:int) -> void:
	tflag += 1
	counter = label
	timer = get_tree().create_timer(secs)
	await timer.timeout
	if tflag > 0:
		return
	counter = null
	timer = null
	tflag = 0

func _on_category_selected(idx:int):
	container.get_child(selected_category).get_node("Right Arrow").hide()
	container.get_child(idx).get_node("Right Arrow").show()
	GameSocket.vote_category(categories[idx-1]["id"])
	selected_category = idx
	for child in container.get_children():
		if child is Button:
			child.disabled = true

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
