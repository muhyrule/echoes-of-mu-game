extends CanvasLayer
## Full-screen gritty gothic grade applied beneath the HUD.

var mat: ShaderMaterial
var t := 0.0


func _ready() -> void:
	layer = 5
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = load("res://src/core/post.gdshader")
	r.material = mat
	add_child(r)


func _process(delta: float) -> void:
	t += delta
	mat.set_shader_parameter("time", t)
