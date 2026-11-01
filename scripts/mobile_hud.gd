extends CanvasLayer
class_name WarfoxHUD

var player: WarfoxPlayer
var joystick_vector := Vector2.ZERO
var sprint_active := false
var crouch_active := false
var jump_pulse := false
var fire_pulse := false
var heal_pulse := false
var parachute_pulse := false
var reload_pulse := false
var ammo_text: Label
var reload_button: Button
var flight_hint: Label
var health_bar: ProgressBar
var health_text: Label
var medkit_button: Button

func _ready() -> void:
	_build_hud()

func _style_button(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(color, 0.72))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.15), 0.88))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.2), 0.95))

func _button_style(color: Color, alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, alpha)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.42, 0.12, 0.85)
	return style

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	var look_area := TouchLook.new()
	look_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	look_area.anchor_left = 0.5
	look_area.mouse_filter = Control.MOUSE_FILTER_STOP
	look_area.look_changed.connect(func(value: Vector2):
		if player != null:
			player.add_look_delta(value)
	)
	root.add_child(look_area)

	var title := Label.new()
	title.text = "HICHAM  |  WARFOX"
	title.position = Vector2(24, 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.42, 0.08))
	title.add_theme_font_size_override("font_size", 23)
	root.add_child(title)

	health_text = Label.new()
	health_text.text = "HP 100 / 100"
	health_text.anchor_left = 1.0
	health_text.anchor_right = 1.0
	health_text.position = Vector2(-220, 22)
	health_text.size = Vector2(190, 24)
	health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	health_text.add_theme_color_override("font_color", Color(0.9, 0.96, 0.92))
	health_text.add_theme_font_size_override("font_size", 16)
	root.add_child(health_text)

	health_bar = ProgressBar.new()
	health_bar.anchor_left = 1.0
	health_bar.anchor_right = 1.0
	health_bar.position = Vector2(-220, 50)
	health_bar.size = Vector2(190, 15)
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.18, 0.78, 0.39)
	bar_fill.corner_radius_top_left = 5
	bar_fill.corner_radius_top_right = 5
	bar_fill.corner_radius_bottom_left = 5
	bar_fill.corner_radius_bottom_right = 5
	health_bar.add_theme_stylebox_override("fill", bar_fill)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.04, 0.06, 0.07, 0.8)
	health_bar.add_theme_stylebox_override("background", bar_bg)
	root.add_child(health_bar)

	ammo_text = Label.new()
	ammo_text.text = "AMMO 30 / 120"
	ammo_text.anchor_left = 1.0
	ammo_text.anchor_right = 1.0
	ammo_text.anchor_top = 1.0
	ammo_text.anchor_bottom = 1.0
	ammo_text.position = Vector2(-245, -330)
	ammo_text.size = Vector2(220, 28)
	ammo_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_text.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
	ammo_text.add_theme_font_size_override("font_size", 17)
	root.add_child(ammo_text)

	reload_button = Button.new()
	reload_button.text = "RELOAD"
	reload_button.size = Vector2(92, 48)
	reload_button.anchor_left = 1.0
	reload_button.anchor_top = 1.0
	reload_button.anchor_right = 1.0
	reload_button.anchor_bottom = 1.0
	reload_button.position = Vector2(-350, -222)
	reload_button.add_theme_font_size_override("font_size", 14)
	_style_button(reload_button, Color(0.35, 0.30, 0.12))
	reload_button.pressed.connect(func(): reload_pulse = true)
	root.add_child(reload_button)

	flight_hint = Label.new()
	flight_hint.text = "PARACHUTE DEPLOYED  •  STEER WITH LEFT STICK"
	flight_hint.anchor_left = 0.5
	flight_hint.anchor_right = 0.5
	flight_hint.position = Vector2(-190, 92)
	flight_hint.size = Vector2(380, 28)
	flight_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flight_hint.add_theme_color_override("font_color", Color(1.0, 0.68, 0.25))
	flight_hint.add_theme_font_size_override("font_size", 15)
	flight_hint.visible = false
	root.add_child(flight_hint)

	var mode := Label.new()
	mode.text = "ISLAND TEST  •  THIRD PERSON"
	mode.position = Vector2(25, 50)
	mode.add_theme_color_override("font_color", Color(0.88, 0.92, 0.94))
	mode.add_theme_font_size_override("font_size", 13)
	root.add_child(mode)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -18)
	crosshair.add_theme_color_override("font_color", Color(1.0, 0.9, 0.72, 0.95))
	crosshair.add_theme_font_size_override("font_size", 30)
	root.add_child(crosshair)

	var jump := Button.new()
	jump.text = "JUMP"
	jump.size = Vector2(100, 68)
	jump.anchor_left = 1.0
	jump.anchor_top = 1.0
	jump.anchor_right = 1.0
	jump.anchor_bottom = 1.0
	jump.position = Vector2(-126, -108)
	jump.add_theme_font_size_override("font_size", 18)
	_style_button(jump, Color(0.10, 0.27, 0.34))
	jump.pressed.connect(func(): jump_pulse = true)
	root.add_child(jump)

	var fire := Button.new()
	fire.text = "FIRE"
	fire.size = Vector2(104, 68)
	fire.anchor_left = 1.0
	fire.anchor_top = 1.0
	fire.anchor_right = 1.0
	fire.anchor_bottom = 1.0
	fire.position = Vector2(-126, -190)
	fire.add_theme_font_size_override("font_size", 18)
	_style_button(fire, Color(0.65, 0.16, 0.08))
	fire.button_down.connect(func(): fire_pulse = true)
	root.add_child(fire)

	medkit_button = Button.new()
	medkit_button.text = "MEDKIT x3"
	medkit_button.size = Vector2(104, 52)
	medkit_button.anchor_left = 1.0
	medkit_button.anchor_top = 1.0
	medkit_button.anchor_right = 1.0
	medkit_button.anchor_bottom = 1.0
	medkit_button.position = Vector2(-126, -270)
	medkit_button.add_theme_font_size_override("font_size", 15)
	_style_button(medkit_button, Color(0.16, 0.48, 0.28))
	medkit_button.pressed.connect(func(): heal_pulse = true)
	root.add_child(medkit_button)

	var chute := Button.new()
	chute.text = "CHUTE"
	chute.size = Vector2(92, 48)
	chute.anchor_left = 1.0
	chute.anchor_top = 1.0
	chute.anchor_right = 1.0
	chute.anchor_bottom = 1.0
	chute.position = Vector2(-238, -222)
	chute.add_theme_font_size_override("font_size", 15)
	_style_button(chute, Color(0.12, 0.34, 0.52))
	chute.pressed.connect(func(): parachute_pulse = true)
	root.add_child(chute)

	var sprint := Button.new()
	sprint.text = "RUN"
	sprint.size = Vector2(88, 54)
	sprint.anchor_left = 1.0
	sprint.anchor_top = 1.0
	sprint.anchor_right = 1.0
	sprint.anchor_bottom = 1.0
	sprint.position = Vector2(-238, -94)
	sprint.toggle_mode = true
	sprint.toggled.connect(func(value: bool): sprint_active = value)
	_style_button(sprint, Color(0.65, 0.24, 0.06))
	root.add_child(sprint)

	var crouch := Button.new()
	crouch.text = "CROUCH"
	crouch.size = Vector2(92, 50)
	crouch.anchor_left = 1.0
	crouch.anchor_top = 1.0
	crouch.anchor_right = 1.0
	crouch.anchor_bottom = 1.0
	crouch.position = Vector2(-238, -158)
	crouch.toggle_mode = true
	crouch.toggled.connect(func(value: bool): crouch_active = value)
	_style_button(crouch, Color(0.12, 0.28, 0.22))
	root.add_child(crouch)

	var joystick := TouchStick.new()
	joystick.position = Vector2(34, -194)
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.stick_changed.connect(func(value: Vector2): joystick_vector = value)
	root.add_child(joystick)

func _process(_delta: float) -> void:
	if player != null:
		player.set_mobile_input(joystick_vector, sprint_active, jump_pulse, crouch_active, fire_pulse, heal_pulse, parachute_pulse, reload_pulse)
		if flight_hint != null:
			flight_hint.visible = player.parachute_deployed
		if health_bar != null:
			health_bar.value = player.health
			health_text.text = "HP " + str(player.health) + " / 100"
		if ammo_text != null:
			ammo_text.text = "AMMO " + str(player.ammo) + " / " + str(player.reserve_ammo) + ("  •  RELOADING" if player.is_reloading else "")
		if reload_button != null:
			reload_button.disabled = player.is_reloading or player.ammo >= player.MAGAZINE_SIZE or player.reserve_ammo <= 0
		if medkit_button != null:
			medkit_button.text = "MEDKIT x" + str(player.medkits)
			medkit_button.disabled = player.medkits <= 0 or player.health >= 100 or player.healing
	jump_pulse = false
	fire_pulse = false
	heal_pulse = false
	parachute_pulse = false
	reload_pulse = false

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
				_reset_stick()
		elif event is InputEventScreenDrag and active:
			_update_knob(event.position)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			active = event.pressed
			if active:
				_update_knob(event.position)
			else:
				_reset_stick()
		elif event is InputEventMouseMotion and active:
			_update_knob(event.position)

	func _reset_stick() -> void:
		knob = Vector2.ZERO
		stick_changed.emit(Vector2.ZERO)
		queue_redraw()

	func _update_knob(local_position: Vector2) -> void:
		knob = (local_position - Vector2(75, 75)).limit_length(RADIUS - 18.0)
		stick_changed.emit(Vector2(knob.x / (RADIUS - 18.0), -knob.y / (RADIUS - 18.0)))
		queue_redraw()

class TouchLook extends Control:
	signal look_changed(value: Vector2)
	var active_touch := -1

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and active_touch == -1:
				active_touch = event.index
			elif not event.pressed and event.index == active_touch:
				active_touch = -1
		elif event is InputEventScreenDrag and event.index == active_touch:
			look_changed.emit(event.relative)
		elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			look_changed.emit(event.relative)
