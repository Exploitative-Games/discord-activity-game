@tool
class_name Message extends Label

const MSG_LEFT = preload("res://themes/msg_left.tres")
const MSG_RIGHT = preload("res://themes/msg_right.tres")
@onready var avatar_left: TextureRect = $"Avatar Left"
@onready var avatar_right: TextureRect = $"Avatar Right"

enum Directions {Left, Right}
@export var direction:Directions = 0:
	set(val):
		if not is_inside_tree():
			await tree_entered
			await get_tree().physics_frame
		if val == 0:
			theme = MSG_LEFT
			avatar_left.show()
			avatar_right.hide()
			#set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			size_flags_horizontal = SizeFlags.SIZE_SHRINK_BEGIN
		else:
			theme = MSG_RIGHT
			avatar_right.show()
			avatar_left.hide()
			#set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			size_flags_horizontal = SizeFlags.SIZE_SHRINK_END
		direction = val

func _init() -> void:
	visible = false
