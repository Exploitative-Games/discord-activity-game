extends CanvasLayer

@onready var spinner: TextureRect = $Connecting/Spinner
@onready var connecting: Panel = $Connecting
@onready var no_connecton: Panel = $"No Connecton"

const MAIN_MENU = preload("res://scenes/main_menu.tscn")

func _ready() -> void:
	Global.initialized.connect(Callable(self, "_on_initialized"))
	GameSocket.connection_failed.connect(Callable(self, "_on_connection_failed"))

func _physics_process(_delta: float) -> void:
	spinner.rotation -= 0.1

func _on_initialized():
	get_tree().change_scene_to_packed(MAIN_MENU)

func _on_connection_failed():
	connecting.hide()
	no_connecton.show()
	await $"No Connecton/Retry".pressed
	connecting.show()
	no_connecton.hide()
	GameSocket.reconnect.emit()
