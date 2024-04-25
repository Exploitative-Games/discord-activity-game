extends Panel

@onready var nickname: Label = $HBoxContainer/VBoxContainer/name
@onready var handle: Label = $HBoxContainer/VBoxContainer/handle
@onready var avatar: TextureRect = $HBoxContainer/Avatar

func _ready() -> void:
	if Global.user == null: return
	nickname.text = Global.user.name
	handle.text = "@" + Global.user.handle
	avatar.texture = await Global.get_avatar(Global.user)
