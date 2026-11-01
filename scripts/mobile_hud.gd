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
var zone_status_label: Label
var match_stats_label: Label
var account_panel: PanelContainer
var account_info_label: Label
var skin_name_label: Label
var weapon_name_label: Label
var account_manager: Node
var skin_index := 0
var weapon_index := 0

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

	var account_id_label := Label.new()
	account_id_label.text = "PLAYER ID  1000000001  •  WARFOX ELITE"
	account_id_label.position = Vector2(24, 43)
	account_id_label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.94))
	account_id_label.add_theme_font_size_override("font_size", 13)
	root.add_child(account_id_label)

	health_text = Label.new()
	health_text.text = "HP 200 / 200"
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
	health_bar.max_value = 200
	health_bar.value = 200
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

	zone_status_label = Label.new()
	zone_status_label.text = "SAFE ZONE  •  PREPARING"
	zone_status_label.position = Vector2(25, 72)
	zone_status_label.size = Vector2(290, 24)
	zone_status_label.add_theme_color_override("font_color", Color(0.35, 0.82, 1.0))
	zone_status_label.add_theme_font_size_override("font_size", 14)
	root.add_child(zone_status_label)

	match_stats_label = Label.new()
	match_stats_label.text = "KILLS 0  |  BOTS 0"
	match_stats_label.position = Vector2(25, 96)
	match_stats_label.size = Vector2(250, 24)
	match_stats_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.28))
	match_stats_label.add_theme_font_size_override("font_size", 15)
	root.add_child(match_stats_label)


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

	var radar := MiniRadar.new()
	radar.name = "WARFOX_Mini_Map"
	radar.player = player
	radar.position = Vector2(-174, 92)
	radar.anchor_left = 1.0
	radar.anchor_right = 1.0
	radar.size = Vector2(148, 148)
	radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(radar)

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
	_build_armory_panel(root)

func _build_armory_panel(root: Control) -> void:
	var world := get_tree().current_scene
	if world != null:
		account_manager = world.get_node_or_null("WARFOX_Account")
	var armory_button := Button.new()
	armory_button.text = "ARMORY"
	armory_button.position = Vector2(24, 128)
	armory_button.size = Vector2(112, 42)
	armory_button.add_theme_font_size_override("font_size", 14)
	_style_button(armory_button, Color(0.22, 0.30, 0.36))
	armory_button.pressed.connect(_toggle_armory)
	root.add_child(armory_button)

	account_panel = PanelContainer.new()
	account_panel.name = "WARFOX_Armory_Panel"
	account_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	account_panel.position = Vector2(-190, -205)
	account_panel.size = Vector2(380, 410)
	account_panel.custom_minimum_size = Vector2(380, 410)
	account_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.045, 0.06, 0.96)
	panel_style.border_color = Color(1.0, 0.38, 0.08, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	account_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(account_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	account_panel.add_child(content)
	var heading := Label.new()
	heading.text = "WARFOX  //  ELITE ARMORY"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color(1.0, 0.48, 0.12))
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)
	account_info_label = Label.new()
	account_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	account_info_label.add_theme_color_override("font_color", Color(0.82, 0.91, 0.94))
	content.add_child(account_info_label)
	var skin_title := Label.new()
	skin_title.text = "OPERATOR SKIN"
	skin_title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35))
	content.add_child(skin_title)
	skin_name_label = Label.new()
	skin_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skin_name_label.add_theme_font_size_override("font_size", 17)
	content.add_child(skin_name_label)
	var skin_row := HBoxContainer.new()
	var skin_prev := Button.new()
	skin_prev.text = "‹ PREVIOUS"
	skin_prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(skin_prev, Color(0.18, 0.27, 0.32))
	skin_prev.pressed.connect(func(): _change_loadout(-1, true))
	skin_row.add_child(skin_prev)
	var skin_next := Button.new()
	skin_next.text = "NEXT ›"
	skin_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(skin_next, Color(0.18, 0.27, 0.32))
	skin_next.pressed.connect(func(): _change_loadout(1, true))
	skin_row.add_child(skin_next)
	content.add_child(skin_row)
	var weapon_title := Label.new()
	weapon_title.text = "PRIMARY WEAPON"
	weapon_title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35))
	content.add_child(weapon_title)
	weapon_name_label = Label.new()
	weapon_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_name_label.add_theme_font_size_override("font_size", 17)
	content.add_child(weapon_name_label)
	var weapon_row := HBoxContainer.new()
	var weapon_prev := Button.new()
	weapon_prev.text = "‹ PREVIOUS"
	weapon_prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(weapon_prev, Color(0.18, 0.27, 0.32))
	weapon_prev.pressed.connect(func(): _change_loadout(-1, false))
	weapon_row.add_child(weapon_prev)
	var weapon_next := Button.new()
	weapon_next.text = "NEXT ›"
	weapon_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(weapon_next, Color(0.18, 0.27, 0.32))
	weapon_next.pressed.connect(func(): _change_loadout(1, false))
	weapon_row.add_child(weapon_next)
	content.add_child(weapon_row)
	var close_button := Button.new()
	close_button.text = "CLOSE ARMORY"
	_style_button(close_button, Color(0.55, 0.16, 0.08))
	close_button.pressed.connect(_toggle_armory)
	content.add_child(close_button)
	_refresh_armory()

func _toggle_armory() -> void:
	if account_panel != null:
		account_panel.visible = not account_panel.visible
		_refresh_armory()

func _change_loadout(direction: int, change_skin: bool) -> void:
	if account_manager == null:
		return
	var names: Array = account_manager.get("owned_skins") if change_skin else account_manager.get("owned_weapons")
	if names.is_empty():
		return
	if change_skin:
		skin_index = posmod(skin_index + direction, names.size())
		account_manager.call("equip_skin", str(names[skin_index]))
	else:
		weapon_index = posmod(weapon_index + direction, names.size())
		account_manager.call("equip_weapon", str(names[weapon_index]))
	if player != null and player.has_method("apply_equipped_loadout"):
		player.apply_equipped_loadout(account_manager)
	_refresh_armory()

func _refresh_armory() -> void:
	if account_manager == null:
		return
	var summary: Dictionary = account_manager.call("get_account_summary")
	account_info_label.text = "ID  " + str(summary["player_id"]) + "    CREDITS  " + str(summary["credits"]) + "\n" + str(summary["skins_unlocked"]) + " SKINS UNLOCKED   •   " + str(summary["weapons_unlocked"]) + " WEAPONS UNLOCKED"
	var skins: Array = account_manager.get("owned_skins")
	var weapons: Array = account_manager.get("owned_weapons")
	if skins.size() > 0:
		var selected_skin := str(account_manager.get("equipped_skin"))
		skin_index = maxi(0, skins.find(selected_skin))
		skin_name_label.text = "★  " + selected_skin
	if weapons.size() > 0:
		var selected_weapon := str(account_manager.get("equipped_weapon"))
		weapon_index = maxi(0, weapons.find(selected_weapon))
		weapon_name_label.text = "◆  " + selected_weapon

func _process(_delta: float) -> void:
	if player != null:
		player.set_mobile_input(joystick_vector, sprint_active, jump_pulse, crouch_active, fire_pulse, heal_pulse, parachute_pulse, reload_pulse)
		if match_stats_label != null:
			var world := player.get_parent()
			var active_bots := 0
			if world != null:
				for bot in world.get_nodes_in_group("warfox_bots"):
					if bot.visible and bot.health > 0:
						active_bots += 1
			match_stats_label.text = "KILLS " + str(player.kills) + "  |  BOTS " + str(active_bots)
		if flight_hint != null:
			flight_hint.visible = player.parachute_deployed
		if health_bar != null:
			health_bar.value = player.health
			health_text.text = "HP " + str(player.health) + " / " + str(player.MAX_HEALTH)
		if ammo_text != null:
			ammo_text.text = "AMMO " + str(player.ammo) + " / " + str(player.reserve_ammo) + ("  •  RELOADING" if player.is_reloading else "")
		if reload_button != null:
			reload_button.disabled = player.is_reloading or player.ammo >= player.MAGAZINE_SIZE or player.reserve_ammo <= 0
		if medkit_button != null:
			medkit_button.text = "MEDKIT x" + str(player.medkits)
			medkit_button.disabled = player.medkits <= 0 or player.health >= player.MAX_HEALTH or player.healing
		if zone_status_label != null:
			var zone_world := player.get_parent()
			if zone_world != null:
				var elapsed := float(zone_world.get("safe_zone_elapsed"))
				var radius := float(zone_world.get("safe_zone_radius"))
				var remaining := maxi(0, int(30.0 - elapsed)) if elapsed < 30.0 else 0
				var distance := Vector2(player.global_position.x, player.global_position.z).length()
				if distance > radius:
					zone_status_label.text = "⚠ OUTSIDE SAFE ZONE  •  " + str(int(distance - radius)) + "m"
					zone_status_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.16))
				elif remaining > 0:
					zone_status_label.text = "SAFE ZONE SHRINKS IN  " + str(remaining) + "s"
					zone_status_label.add_theme_color_override("font_color", Color(0.35, 0.82, 1.0))
				else:
					zone_status_label.text = "SAFE ZONE  •  " + str(int(radius)) + "m"
					zone_status_label.add_theme_color_override("font_color", Color(0.35, 0.82, 1.0))
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


class MiniRadar extends Control:
	var player: WarfoxPlayer
	var refresh_clock := 0.0
	const RADAR_RANGE := 180.0
	const RADAR_RADIUS := 66.0

	func _process(delta: float) -> void:
		refresh_clock += delta
		if refresh_clock >= 0.18:
			refresh_clock = 0.0
			queue_redraw()

	func _draw() -> void:
		var center := Vector2(74, 74)
		draw_circle(center, 72.0, Color(0.025, 0.045, 0.055, 0.82))
		draw_arc(center, 72.0, 0.0, TAU, 64, Color(1.0, 0.42, 0.10, 0.92), 2.5)
		draw_arc(center, 48.0, 0.0, TAU, 48, Color(0.55, 0.68, 0.70, 0.24), 1.0)
		draw_arc(center, 24.0, 0.0, TAU, 48, Color(0.55, 0.68, 0.70, 0.18), 1.0)
		draw_line(center + Vector2(-66, 0), center + Vector2(66, 0), Color(0.55, 0.68, 0.70, 0.16), 1.0)
		draw_line(center + Vector2(0, -66), center + Vector2(0, 66), Color(0.55, 0.68, 0.70, 0.16), 1.0)
		if player == null or not is_instance_valid(player):
			return
		var world := player.get_parent()
		if world == null:
			return
		var safe_radius := float(world.get("safe_zone_radius")) if world.get("safe_zone_radius") != null else RADAR_RANGE
		var safe_screen_radius := clampf(safe_radius / RADAR_RANGE * RADAR_RADIUS, 2.0, RADAR_RADIUS)
		draw_arc(center, safe_screen_radius, 0.0, TAU, 64, Color(0.12, 0.78, 1.0, 0.82), 1.8)
		var player_pos := Vector2(player.global_position.x, player.global_position.z)
		for node in world.get_children():
			if node == player or not node is Node3D:
				continue
			var point := Vector2(node.global_position.x, node.global_position.z) - player_pos
			if point.length() > RADAR_RANGE:
				continue
			var map_point := center + Vector2(point.x, point.y) / RADAR_RANGE * RADAR_RADIUS
			if node.name.contains("Bot"):
				draw_circle(map_point, 4.0, Color(1.0, 0.16, 0.12, 0.95))
			elif node.name.begins_with("Loot_"):
				var loot_color := Color(1.0, 0.72, 0.12, 0.95) if node.name.contains("Ammo") else Color(0.25, 1.0, 0.55, 0.95)
				draw_rect(Rect2(map_point - Vector2(3, 3), Vector2(6, 6)), loot_color)
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -9), center + Vector2(-6, 6), center + Vector2(6, 6)]), Color(0.95, 0.98, 1.0))
		draw_string(ThemeDB.fallback_font, Vector2(67, 15), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.9, 0.95, 1.0, 0.9))
