extends MultiMeshInstance2D

const SHAPE_COUNT = 600
var speeds:Array[float]
var rots:Array[float]

func _ready() -> void:
	multimesh.instance_count = SHAPE_COUNT
	for i in SHAPE_COUNT:
		multimesh.set_instance_transform_2d(i, Transform2D(
			randf()*2*PI,
			Vector2.ONE * randf_range(0.2, 0.4),
			0.0,
			Vector2(randf_range(-50, get_viewport_rect().end.x + 50), randf_range(-50, get_viewport_rect().end.y + 50))
		))
		multimesh.set_instance_color(i, Color(randf(), randf(), randf(), 0.2))
		#multimesh.set_instance_color(i, Color(0.825 + randf() * 0.1, 0.672 + randf() * 0.1, 0.582 + randf() * 0.1, 0.5))
		speeds.append(randf_range(0.3, 1.0))
		rots.append(randf_range(0.01, 0.04))

func _physics_process(_delta: float) -> void:
	for i in SHAPE_COUNT:
		var t = multimesh.get_instance_transform_2d(i)
		if t.get_origin().y < -50:
			t.origin = Vector2(randf()*get_viewport_rect().end.x, get_viewport_rect().end.y + 50)
			speeds[i] = randf_range(0.3, 1.0)
			rots[i] = randf_range(0.01, 0.04)
		multimesh.set_instance_transform_2d(i, Transform2D(
			t.get_rotation() + rots[i],
			t.get_scale(),
			0.0,
			t.get_origin() + speeds[i] * Vector2.UP
		))

