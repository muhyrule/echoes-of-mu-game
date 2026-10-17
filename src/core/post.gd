extends CanvasLayer
## Crisp gothic colour grade applied beneath the HUD.

var mat: ShaderMaterial
var t := 0.0
var grit := 0.7
var scratches := 0.0


func _ready() -> void:
	layer = 5
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = load("res://src/core/post.gdshader")
	mat.set_shader_parameter("grit", grit)
	mat.set_shader_parameter("scratches", scratches)
	r.material = mat
	add_child(r)


func _process(delta: float) -> void:
	t += delta
	mat.set_shader_parameter("time", t)
