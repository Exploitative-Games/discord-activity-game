extends Button

var count := 0;

func _ready() -> void:
	Global.label = $"../Label"
	Global.button = self

func _user_updated(data):
	Global.label.text = str(data)
	if (data.global_name != null):
		Global.label.text = data["global_name"] + " (@" + data["username"] + ")"
	else:
		Global.label.text = data["username"] + " (@" + data["username"] + ")"

func _pressed():
	count += 1;
	text = str(count);
