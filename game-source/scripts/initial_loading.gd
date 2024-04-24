extends CanvasLayer

@onready var spinner: TextureRect = $Panel/Spinner

const MAIN_MENU = preload("res://scenes/main_menu.tscn")

func _ready() -> void:
	Global.initialized.connect(Callable(self, "_on_initialized"))

func _physics_process(delta: float) -> void:
	spinner.rotation -= 0.1

func _on_initialized():
	get_tree().change_scene_to_packed(MAIN_MENU)
