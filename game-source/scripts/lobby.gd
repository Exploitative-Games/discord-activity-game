extends CanvasLayer

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
var countdown:int

func _connect_signals():
	for i in range(1,4):
		category_select.get_child(1).get_child(i).pressed.connect(Callable(self, "_on_category_selected").bind(i))
	$Messages/VBoxContainer/Send.pressed.connect(Callable(self, "_on_message_sent"))
	line.text_submitted.connect(Callable(self, "_on_message_sent").unbind(1))
	GameSocket.player_joined_received.connect(Callable(self, "_on_player_joined"))
	GameSocket.game_start_received.connect(Callable(self, "_on_game_start"))
	GameSocket.game_start_countdown_start_received.connect(Callable(self, "_on_game_start_countdown_start"))
	GameSocket.game_start_countdown_cancel_received.connect(Callable(self, "_on_game_start_countdown_cancel"))
	GameSocket.game_quiz_start_received.connect(Callable(self, "_on_game_quiz_start"))
	GameSocket.answer_received.connect(Callable(self, "_on_answer_received"))
	GameSocket.turn_change_received.connect(Callable(self, "_on_turn_change"))
	$Messages/VBoxContainer/Panel/ScrollContainer.get_v_scroll_bar().changed.connect(_scroll_length_changed)

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
	line.clear()
	line.editable = false
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

func _on_game_start_countdown_start(res:Dictionary):
	await _timer($Messages/VBoxContainer/Panel/Counter, res["countdown"])
	$Messages/VBoxContainer/Panel/Counter.text = ""

func _on_game_start_countdown_cancel(_res:Dictionary):
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
	$Messages/VBoxContainer/Question.text = ""
	for msg in $Messages/VBoxContainer/Panel/ScrollContainer/VBoxContainer.get_children():
		msg.queue_free()

func _on_game_quiz_start(res:Dictionary):
	category_select.hide()
	line.grab_focus()
	$Messages/VBoxContainer/Question.text = res["question"]
	if int(res["current_player"]) == Global.user.id:
		line.editable = true
		countdown = int(res["question_cooldown"])
		_timer($Messages/VBoxContainer/Panel/Timer/Label, countdown * 2)

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

#var tflag:int = 0
func _timer(label:Label, secs:int) -> void:
	#tflag += 1
	counter = label
	timer = get_tree().create_timer(secs)
	await timer.timeout
	return
	#if tflag > 0:
		#return
	#counter = null
	#timer = null
	#tflag = 0

func _on_category_selected(idx:int):
	container.get_child(selected_category).get_node("Right Arrow").hide()
	container.get_child(idx).get_node("Right Arrow").show()
	GameSocket.vote_category(categories[idx-1]["id"])
	selected_category = idx
	for child in container.get_children():
		if child is Button:
			child.disabled = true

func _on_message_sent():
	var text = line.text
	if text.length() > 0:
		line.clear()
		var msg := _send(text, Message.Directions.Right)
		var res := await GameSocket.answer_question(text)
		msg.state = Message.State.Correct if res["correct"] else Message.State.Wrong

func _on_answer_received(res:Dictionary):
	if int(res["player"]) != Global.user.id:
		var msg := _send(res["answer"], Message.Directions.Left)
		msg.state = Message.State.Correct if res["correct"] else Message.State.Wrong

func _send(answer:String, direction:Message.Directions) -> Message:
	var msg:Message = MESSAGE.instantiate()
	msg.direction = direction
	msg.text = answer
	msg_history.add_child(msg)
	msg.show()
	return msg

func _scroll_length_changed():
	$Messages/VBoxContainer/Panel/ScrollContainer.scroll_vertical = 99999999

func _on_turn_change(res:Dictionary):
	if int(res["current_player"]) == Global.user.id:
		line.editable = true
		_timer($Messages/VBoxContainer/Panel/Timer/Label, countdown)
	else:
		line.editable = false
		line.clear()
		
