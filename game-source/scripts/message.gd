@tool
class_name Message extends Label

const MSG_LEFT = preload("res://themes/msg_left.tres")
const MSG_RIGHT = preload("res://themes/msg_right.tres")
@onready var avatar_left: TextureRect = $"Avatar Left"
@onready var avatar_right: TextureRect = $"Avatar Right"
@onready var checkmark_left: TextureRect = $"Checkmark Left"
@onready var checkmark_right: TextureRect = $"Checkmark Right"
@onready var cross_left: TextureRect = $"Cross Left"
@onready var cross_right: TextureRect = $"Cross Right"

enum Directions {Left, Right}
@export var direction:Directions = Directions.Left:
	set(val):
		if not is_inside_tree():
			await tree_entered
			await get_tree().physics_frame
		if val == 0:
			theme = MSG_LEFT
			avatar_left.show()
			avatar_right.hide()
			#checkmark_left.show()
			#checkmark_right.hide()
			#set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			size_flags_horizontal = SizeFlags.SIZE_SHRINK_BEGIN
			if not Engine.is_editor_hint():
				avatar_left.texture = Global.opponent_avatar
		else:
			theme = MSG_RIGHT
			avatar_right.show()
			avatar_left.hide()
			#checkmark_right.show()
			#checkmark_left.hide()
			#set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			size_flags_horizontal = SizeFlags.SIZE_SHRINK_END
			if not Engine.is_editor_hint():
				avatar_right.texture = Global.user_avatar
		direction = val

enum State {Neutral, Wrong, Correct}
@export var state:State = State.Neutral:
	set(val):
		if not is_inside_tree():
			await tree_entered
			await get_tree().physics_frame
		checkmark_left.hide()
		checkmark_right.hide()
		cross_left.hide()
		cross_right.hide()
		match val:
			State.Neutral:
				state = val
				return
			State.Correct:
				if direction == Directions.Left:
					checkmark_left.show()
				else:
					checkmark_right.show()
			State.Wrong:
				if direction == Directions.Left:
					cross_left.show()
				else:
					cross_right.show()
		state = val

func _init() -> void:
	visible = false
