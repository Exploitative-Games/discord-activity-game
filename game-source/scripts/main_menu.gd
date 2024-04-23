extends CanvasLayer

@onready var list:ItemList = $"Lobby Select/VBoxContainer/ItemList"
@onready var join_button:Button = $"Lobby Select/VBoxContainer/HBoxContainer/Join"
@onready var loading_screen:Panel = $"Loading Screen"

var selected_lobby
var lobbies:Array[Global.Lobby]

var lock = false
var active_menu:Panel:
	set(val):
		if active_menu == null:
			active_menu = val
			return
		
		if lock: return
		lock = true
		val.show()
		
		var mul = 1
		if val.position.x > 0: mul = -1
		
		var tw := create_tween()
		tw.tween_property(
			active_menu,
			"position",
			Vector2(active_menu.position.x + get_viewport().size.x * mul, active_menu.position.y),
			0.5
		).set_trans(Tween.TRANS_BACK)
		
		tw = create_tween()
		tw.tween_property(
			val,
			"position",
			Vector2(get_viewport().size / 2) - val.size / 2,
			0.5
		).set_trans(Tween.TRANS_BACK)
		
		await tw.finished
		active_menu.hide()
		active_menu = val
		
		lock = false

func _fetch_lobbies() -> void:
	list.deselect_all()
	list.clear()
	join_button.disabled = true
	
	lobbies = [ # todo: a proper fetch
		Global.Lobby.new("gsdgsdgsdg", [
			Global.User.new("test", "handle", 4235325325262, "0")
		], 0),
		Global.Lobby.new("fetewyerhergerg", [
			Global.User.new("test1", "handle", 423534325325262, "0"),
			Global.User.new("test2", "handle", 124235325325262, "0")
		], 0),
		Global.Lobby.new("vgfwsgd", [], 0)
	]
	
	for i in lobbies.size():
		var item = lobbies[i]
		list.add_item(item.name)
		if item.players.size() >= 2:
			list.set_item_disabled(i, true)
		list.set_item_tooltip(i, item.tooltip())

func _ready() -> void:
	list.item_selected.connect(Callable(self, "_on_item_selected"))
	Global.main_menu = self
	
	for panel in get_children():
		if panel is not Panel: continue
		if panel.name != "Player Info" && panel.name != "Loading Screen":
			if panel.name != "Main Menu":
				panel.position.x += get_viewport().size.x
				panel.hide()
			else:
				active_menu = panel
				panel.show()
		for boxcon in panel.get_children():
			if boxcon is BoxContainer:
				_connect_signal(boxcon, panel)

func _on_item_selected(i:int):
	selected_lobby = i
	join_button.disabled = lobbies[i].players.size() >= 2

func _connect_signal(boxcon:BoxContainer, panel:Panel) -> void:
	for button in boxcon.get_children():
		if button is BoxContainer:
			_connect_signal(button, panel)
		if button is Button:
			button.pressed.connect(Callable(self, "_" + _str_normalize(panel.name))
				.bind(button.name)
			)

func _str_normalize(s:String) -> String:
	return s.replace(" ", "_").to_lower()

func switch_menu(menu:String) -> void:
	for panel in get_children():
		if panel is not Panel: continue
		if panel.name == menu:
			active_menu = panel
			return
	assert(false, "Menu \"%s\" not found." % menu)

func _main_menu(button:String) -> void:
	match button:
		"Play":
			switch_menu("Lobby Select")
			await _fetch_lobbies()
		"Settings":
			print("settings pressed")
		"Credits":
			switch_menu("Credits")

func _lobby_select(button:String) -> void:
	match button:
		"Back":
			switch_menu("Main Menu")
		"Join":
			var items = list.get_selected_items()
			if items.is_empty():
				return
			else:
				var i = items[0]
				Global.load_lobby(lobbies[selected_lobby])
		"New Room":
			switch_menu("Create Room")
			var line:LineEdit = $"Create Room/VBoxContainer/LineEdit"
			line.clear()
			line.grab_focus()
		"Refresh":
			await _fetch_lobbies()

func _loading_screen(button:String) -> void:
	match button:
		"Cancel":
			Global.load_cancel_flag = true
			Global.lobby_loaded.emit()

func _credits(button:String) -> void:
	match button:
		"Back":
			switch_menu("Main Menu")

func _create_room(button:String) -> void:
	match button:
		"Back":
			switch_menu("Lobby Select")
		"Create":
			var line:LineEdit = $"Create Room/VBoxContainer/LineEdit"
			var lobby:Global.Lobby = Global.create_lobby(line.text)
			Global.load_lobby(lobby)
