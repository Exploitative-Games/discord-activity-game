extends Panel

@onready var nickname: Label = $HBoxContainer/VBoxContainer/name
@onready var handle: Label = $HBoxContainer/VBoxContainer/handle
@onready var avatar: TextureRect = $HBoxContainer/Avatar

func _ready() -> void:
	if Global.user == null: return
	nickname.text = Global.user.name
	handle.text = "@" + Global.user.handle
	#avatar = await Global.get_avatar(Global.user.id)
	#avatar = await Global.download_avatar("https/cdn.discordapp.com/avatars/%d/%s.png" % [Global.user.id, Global.user.avatar])
