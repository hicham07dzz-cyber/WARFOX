extends CanvasLayer
class_name WarfoxHUD

var player: WarfoxPlayer
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var joystick_active := false
var sprint_active := false
var jump_pulse := false
var status_label: Label

func _ready() -> void:
	_build_hud()

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	status_label = Label.new()
	status_label.text = "WARFOX  |  TRAINING"
	status_label.position = Vector2(24, 20)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.08))
	status_label.add_theme_font_size_override("font_size", 22)
	root.add_child(status_label)

	var help := Label.new()
	help.text = "Move: left stick / WASD     Jump: button / Space"
	help.position = Vector2(24, 52)
	help.add_theme_color_override("font_color", Color(0.88, 0.91, 0.94))
	root.add_child(help)

	var jump := Button.new()
	jump.text = "JUMP"
	jump.size = Vector2(104, 72)
	jump.anchor_left = 1.0
	jump.anchor_top = 1.0
	jump.anchor_right = 1.0
	jump.anchor_bottom = 1.0
	jump.position = Vector2(-142, -112)
	jump.add_theme_color_override("font_color", Color.WHITE)
	jump.add_theme_font_size_override("font_size", 20)
	jump.pressed.connect(_on_jump)
	root.add_child(jump)

	var sprint := Button.new()
	sprint.text = "SPRINT"
	sprint.size = Vector2(104, 58)
	sprint.anchor_left = 1.0
	sprint.anchor_top = 1.0
	sprint.anchor_right = 1.0
	sprint.anchor_bottom = 1.0
	sprint.position = Vector2(-260, -92)
	sprint.toggle_mode = true
	sprint.toggled.connect(func(value: bool): sprint_active = value)
	root.add_child(sprint)

	var joystick := TouchStick.new()
	joystick.position = Vector2(34, -204)
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.stick_changed.connect(func(value: Vector2): joystick_vector = value)
	root.add_child(joystick)

func _on_jump() -> void:
	jump_pulse = true

func _process(_delta: float) -> void:
	if player != null:
		player.set_mobile_input(joystick_vector, sprint_active, jump_pulse)
	jump_pulse = false

class TouchStick extends Control:
	signal stick_changed(value: Vector2)
	var active := false
	var knob := Vector2.ZERO
	const RADIUS := 72.0

	func _ready() -> void:
		size = Vector2(150, 150)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		draw_circle(Vector2(75, 75), RADIUS, Color(0.04, 0.07, 0.09, 0.55))
		draw_arc(Vector2(75, 75), RADIUS, 0, TAU, 48, Color(1.0, 0.38, 0.06, 0.8), 3.0)
		draw_circle(Vector2(75, 75) + knob, 30, Color(1.0, 0.38, 0.06, 0.75))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			active = event.pressed
			if active:
				_update_knob(event.position)
			else:
				knob = Vector2.ZERO
				stick_changed.emit(Vector2.ZERO)
				queue_redraw()
		elif event is InputEventScreenDrag and active:
			_update_knob(event.position)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			active = event.pressed
			if not active:
				knob = Vector2.ZERO
				stick_changed.emit(Vector2.ZERO)
				queue_redraw()
		elif event is InputEventMouseMotion and active:
			_update_knob(event.position)

	func _update_knob(local_position: Vector2) -> void:
		knob = (local_position - Vector2(75, 75)).limit_length(RADIUS - 18.0)
		stick_changed.emit(Vector2(knob.x / (RADIUS - 18.0), -knob.y / (RADIUS - 18.0)))
		queue_redraw()
