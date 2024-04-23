extends Panel

@onready var nickname: Label = $HBoxContainer/VBoxContainer/name
@onready var handle: Label = $HBoxContainer/VBoxContainer/handle
@onready var avatar: TextureRect = $HBoxContainer/Avatar

func _ready() -> void:
	Global.user_updated.connect(Callable(self, "_user_updated"))

func _user_updated():
	if Global.user == null: return
	print("1")
	nickname.text = Global.user.name
	handle.text = "@" + Global.user.handle
	#avatar = await Global.get_avatar(Global.user.id)
	avatar = await Global.download_avatar("https/cdn.discordapp.com/avatars/%d/%s.png" % [Global.user.id, Global.user.avatar])
	print("2")
