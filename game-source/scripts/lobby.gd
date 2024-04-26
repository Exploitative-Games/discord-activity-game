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

func _update_players():
	for player in Global.lobby.players:
		if player.id == Global.user.id:
			player_2.get_node("VBoxContainer/name").text = player.name
			player_2.get_node("VBoxContainer/handle").text = "@" + player.handle
			player_2.get_node("Avatar").texture = await Global.get_avatar(player)
		else:
			player_1.get_node("VBoxContainer/name").text = player.name
			player_1.get_node("VBoxContainer/handle").text = "@" + player.handle
			player_1.get_node("Avatar").texture = await Global.get_avatar(player)

func _ready() -> void:
	await Global.lobby_loaded
	_connect_signals()
	_update_players()
	
	category_select.scale = Vector2.ZERO
	category_select.show()
	create_tween().tween_property(category_select, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUINT)
	_selection_timer()
	await selection_finished
	
	line.grab_focus()

func _physics_process(delta: float) -> void:
	if timer != null:
		counter.text = "%.1f" % timer.time_left

func _selection_timer() -> void:
	counter = $"Category Select/Counter"
	timer = get_tree().create_timer(10)
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
