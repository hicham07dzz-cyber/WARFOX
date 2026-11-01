extends CanvasLayer
class_name WarfoxBootScreen

var root: Control
var intro_panel: Control
var menu_panel: PanelContainer
var settings_panel: PanelContainer
var profile_panel: PanelContainer
var skin_panel: PanelContainer
var skin_name_label: Label
var account_manager: Node
var selected_skin_index := 0
const SKIN_NAMES := ["FOX COMMANDER", "SHADOW RECON", "DESERT PHANTOM", "ARCTIC WOLF", "EMBER GUARD", "NEON HUNTER"]
var progress_bar: ProgressBar
var progress_label: Label
var status_label: Label
var logo_label: Label
var intro_clock := 0.0
var loading_value := 0.0
var phase := "intro"
var ready_to_start := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_build_interface()
	_show_intro()

func _build_interface() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.012, 0.022, 0.032, 1.0)
	root.add_child(backdrop)

	var top_line := ColorRect.new()
	top_line.color = Color(1.0, 0.34, 0.075, 0.95)
	top_line.anchor_right = 1.0
	top_line.offset_bottom = 4
	root.add_child(top_line)

	var bottom_line := ColorRect.new()
	bottom_line.color = Color(0.08, 0.62, 0.76, 0.85)
	bottom_line.anchor_top = 1.0
	bottom_line.anchor_right = 1.0
	bottom_line.offset_top = -3
	root.add_child(bottom_line)

	intro_panel = Control.new()
	intro_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(intro_panel)

	logo_label = Label.new()
	logo_label.text = "🦊"
	logo_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	logo_label.position = Vector2(-54, -142)
	logo_label.size = Vector2(108, 92)
	logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	logo_label.add_theme_color_override("font_color", Color(1.0, 0.38, 0.08))
	logo_label.add_theme_font_size_override("font_size", 68)
	intro_panel.add_child(logo_label)

	var title := Label.new()
	title.text = "WARFOX"
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title.position = Vector2(-220, -42)
	title.size = Vector2(440, 72)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.96, 0.97, 0.95))
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.12, 0.15))
	intro_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "TACTICAL ISLAND  •  SURVIVE THE DROP"
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	subtitle.position = Vector2(-260, 28)
	subtitle.size = Vector2(520, 32)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.48, 0.72, 0.79))
	subtitle.add_theme_font_size_override("font_size", 16)
	intro_panel.add_child(subtitle)

	var loading_title := Label.new()
	loading_title.text = "INITIALIZING WARFOX SYSTEMS"
	loading_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	loading_title.position = Vector2(-190, 132)
	loading_title.size = Vector2(380, 24)
	loading_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_title.add_theme_color_override("font_color", Color(0.88, 0.91, 0.91))
	loading_title.add_theme_font_size_override("font_size", 13)
	intro_panel.add_child(loading_title)

	progress_bar = ProgressBar.new()
	progress_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	progress_bar.position = Vector2(-190, 164)
	progress_bar.size = Vector2(380, 12)
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.36, 0.07)
	fill.set_corner_radius_all(6)
	progress_bar.add_theme_stylebox_override("fill", fill)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.12, 0.17, 0.20)
	track.set_corner_radius_all(6)
	progress_bar.add_theme_stylebox_override("background", track)
	intro_panel.add_child(progress_bar)

	progress_label = Label.new()
	progress_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	progress_label.position = Vector2(-190, 182)
	progress_label.size = Vector2(380, 24)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_color_override("font_color", Color(0.72, 0.79, 0.82))
	progress_label.add_theme_font_size_override("font_size", 12)
	intro_panel.add_child(progress_label)

	status_label = Label.new()
	status_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	status_label.position = Vector2(-250, 222)
	status_label.size = Vector2(500, 24)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(0.34, 0.68, 0.75))
	status_label.add_theme_font_size_override("font_size", 12)
	intro_panel.add_child(status_label)

	menu_panel = PanelContainer.new()
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_panel.position = Vector2(-190, -190)
	menu_panel.size = Vector2(380, 380)
	menu_panel.custom_minimum_size = Vector2(380, 380)
	menu_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.045, 0.06, 0.97)
	panel_style.border_color = Color(1.0, 0.38, 0.08, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(18)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24
	menu_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(menu_panel)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 16)
	menu_panel.add_child(menu)

	var menu_title := Label.new()
	menu_title.text = "WARFOX"
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_color_override("font_color", Color(1.0, 0.42, 0.10))
	menu_title.add_theme_font_size_override("font_size", 38)
	menu.add_child(menu_title)

	var menu_subtitle := Label.new()
	menu_subtitle.text = "TACTICAL ISLAND"
	menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_subtitle.add_theme_color_override("font_color", Color(0.72, 0.82, 0.85))
	menu_subtitle.add_theme_font_size_override("font_size", 14)
	menu.add_child(menu_subtitle)

	var separator := HSeparator.new()
	menu.add_child(separator)

	var start_button := Button.new()
	start_button.text = "ENTER THE ISLAND"
	start_button.custom_minimum_size = Vector2(0, 58)
	start_button.add_theme_font_size_override("font_size", 19)
	_style_menu_button(start_button, Color(0.72, 0.23, 0.06))
	start_button.pressed.connect(_start_game)
	menu.add_child(start_button)

	var skins_button := Button.new()
	skins_button.text = "OPERATOR SKINS"
	skins_button.custom_minimum_size = Vector2(0, 46)
	_style_menu_button(skins_button, Color(0.35, 0.22, 0.12))
	skins_button.pressed.connect(_show_skins)
	menu.add_child(skins_button)

	var profile_button := Button.new()
	profile_button.text = "PLAYER PROFILE"
	profile_button.custom_minimum_size = Vector2(0, 46)
	_style_menu_button(profile_button, Color(0.16, 0.30, 0.35))
	profile_button.pressed.connect(_show_profile)
	menu.add_child(profile_button)

	var settings_button := Button.new()
	settings_button.text = "SETTINGS"
	settings_button.custom_minimum_size = Vector2(0, 46)
	_style_menu_button(settings_button, Color(0.16, 0.25, 0.30))
	settings_button.pressed.connect(_show_settings)
	menu.add_child(settings_button)

	_build_settings_panel()
	_build_profile_panel()
	_build_skins_panel()

	var footer := Label.new()
	footer.text = "BUILD  0.1  •  WARFOX PROJECT"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color(0.48, 0.57, 0.61))
	footer.add_theme_font_size_override("font_size", 11)
	menu.add_child(footer)

func _style_menu_button(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(12)
	normal.border_color = Color(1.0, 0.48, 0.14, 0.85)
	normal.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)

func _show_intro() -> void:
	phase = "intro"
	intro_clock = 0.0
	loading_value = 0.0
	intro_panel.visible = true
	menu_panel.visible = false
	logo_label.modulate.a = 0.0
	logo_label.scale = Vector2(0.65, 0.65)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(logo_label, "modulate:a", 1.0, 0.9)
	tween.parallel().tween_property(logo_label, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if phase != "intro":
		return
	intro_clock += delta
	loading_value = minf(100.0, loading_value + delta * 34.0)
	progress_bar.value = loading_value
	progress_label.text = "%02d%%" % int(loading_value)
	if loading_value < 30.0:
		status_label.text = "LOADING ISLAND DATA..."
	elif loading_value < 65.0:
		status_label.text = "PREPARING OPERATOR PROFILE..."
	elif loading_value < 100.0:
		status_label.text = "CALIBRATING MOBILE INTERFACE..."
	else:
		status_label.text = "SYSTEM READY"
	if intro_clock >= 3.2 and loading_value >= 100.0:
		phase = "menu"
		intro_panel.visible = false
		menu_panel.visible = true

func _start_game() -> void:
	get_tree().paused = false
	queue_free()



func _build_settings_panel() -> void:
	settings_panel = _make_secondary_panel("WARFOX  //  SETTINGS")
	var content := settings_panel.get_child(0) as VBoxContainer
	var volume_title := Label.new()
	volume_title.text = "MASTER VOLUME"
	volume_title.add_theme_color_override("font_color", Color(0.85, 0.91, 0.92))
	content.add_child(volume_title)
	var volume_value := Label.new()
	volume_value.name = "Volume_Value"
	volume_value.text = "100%"
	volume_value.add_theme_color_override("font_color", Color(1.0, 0.55, 0.20))
	content.add_child(volume_value)
	var volume_slider := HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 1
	volume_slider.value = _get_master_volume()
	volume_slider.custom_minimum_size = Vector2(0, 34)
	volume_slider.value_changed.connect(func(value: float):
		_set_master_volume(value)
		volume_value.text = str(int(value)) + "%"
	)
	content.add_child(volume_slider)
	var note := Label.new()
	note.text = "Mobile graphics presets will be added after device testing."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color(0.62, 0.72, 0.76))
	note.add_theme_font_size_override("font_size", 12)
	content.add_child(note)
	var back := Button.new()
	back.text = "BACK TO MAIN MENU"
	back.custom_minimum_size = Vector2(0, 48)
	_style_menu_button(back, Color(0.20, 0.30, 0.34))
	back.pressed.connect(_show_main_menu)
	content.add_child(back)

func _build_profile_panel() -> void:
	profile_panel = _make_secondary_panel("WARFOX  //  PLAYER PROFILE")
	var content := profile_panel.get_child(0) as VBoxContainer
	var info := Label.new()
	info.name = "Profile_Info"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", Color(0.84, 0.91, 0.93))
	content.add_child(info)
	var back := Button.new()
	back.text = "BACK TO MAIN MENU"
	back.custom_minimum_size = Vector2(0, 48)
	_style_menu_button(back, Color(0.20, 0.30, 0.34))
	back.pressed.connect(_show_main_menu)
	content.add_child(back)

func _make_secondary_panel(heading_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-190, -190)
	panel.size = Vector2(380, 380)
	panel.custom_minimum_size = Vector2(380, 380)
	panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.06, 0.98)
	style.border_color = Color(1.0, 0.38, 0.08, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)
	var heading := Label.new()
	heading.text = heading_text
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color(1.0, 0.46, 0.12))
	heading.add_theme_font_size_override("font_size", 21)
	content.add_child(heading)
	root.add_child(panel)
	return panel

func _show_settings() -> void:
	menu_panel.visible = false
	profile_panel.visible = false
	settings_panel.visible = true

func _show_profile() -> void:
	menu_panel.visible = false
	settings_panel.visible = false
	profile_panel.visible = true
	var world := get_tree().current_scene
	if world != null:
		account_manager = world.get_node_or_null("WARFOX_Account")
	var info := profile_panel.find_child("Profile_Info", true, false) as Label
	if info == null:
		return
	if account_manager != null:
		var summary: Dictionary = account_manager.call("get_account_summary")
		info.text = "PLAYER ID   " + str(summary["player_id"]) + "\n\nMATCHES PLAYED   " + str(summary["matches_played"]) + "\nTOTAL KILLS   " + str(summary["total_kills"]) + "\nUNLOCKED SKINS   " + str(summary["skins_unlocked"]) + "\n\nEQUIPPED SKIN\n" + str(summary["equipped_skin"])
	else:
		info.text = "PLAYER PROFILE\nLocal profile is not available yet."

func _show_main_menu() -> void:
	settings_panel.visible = false
	profile_panel.visible = false
	if skin_panel != null:
		skin_panel.visible = false
	menu_panel.visible = true

func _get_master_volume() -> float:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return 100.0
	return AudioServer.get_bus_volume_linear(bus) * 100.0

func _set_master_volume(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_linear(bus, clampf(value / 100.0, 0.0, 1.0))



func _build_skins_panel() -> void:
	skin_panel = _make_secondary_panel("WARFOX  //  OPERATOR SKINS")
	var content := skin_panel.get_child(0) as VBoxContainer
	skin_name_label = Label.new()
	skin_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skin_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skin_name_label.custom_minimum_size = Vector2(0, 100)
	skin_name_label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.20))
	skin_name_label.add_theme_font_size_override("font_size", 24)
	skin_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(skin_name_label)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 10)
	var previous := Button.new()
	previous.text = "PREVIOUS"
	previous.custom_minimum_size = Vector2(0, 46)
	previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_menu_button(previous, Color(0.16, 0.27, 0.32))
	previous.pressed.connect(_change_skin.bind(-1))
	navigation.add_child(previous)
	var next := Button.new()
	next.text = "NEXT"
	next.custom_minimum_size = Vector2(0, 46)
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_menu_button(next, Color(0.16, 0.27, 0.32))
	next.pressed.connect(_change_skin.bind(1))
	navigation.add_child(next)
	content.add_child(navigation)
	var equip := Button.new()
	equip.text = "EQUIP THIS SKIN"
	equip.custom_minimum_size = Vector2(0, 52)
	_style_menu_button(equip, Color(0.72, 0.23, 0.06))
	equip.pressed.connect(_equip_selected_skin)
	content.add_child(equip)
	var back := Button.new()
	back.text = "BACK TO MAIN MENU"
	back.custom_minimum_size = Vector2(0, 44)
	_style_menu_button(back, Color(0.20, 0.30, 0.34))
	back.pressed.connect(_show_main_menu)
	content.add_child(back)

func _show_skins() -> void:
	menu_panel.visible = false
	settings_panel.visible = false
	profile_panel.visible = false
	skin_panel.visible = true
	var world := get_tree().current_scene
	if world != null:
		account_manager = world.get_node_or_null("WARFOX_Account")
	if account_manager != null:
		var current := str(account_manager.get("equipped_skin"))
		selected_skin_index = maxi(0, SKIN_NAMES.find(current))
	_refresh_skin_label()

func _change_skin(direction: int) -> void:
	selected_skin_index = posmod(selected_skin_index + direction, SKIN_NAMES.size())
	_refresh_skin_label()

func _refresh_skin_label() -> void:
	if skin_name_label == null:
		return
	var selected := SKIN_NAMES[selected_skin_index]
	var equipped := ""
	if account_manager != null:
		equipped = str(account_manager.get("equipped_skin"))
	skin_name_label.text = selected + ("\n\nCURRENTLY EQUIPPED" if selected == equipped else "\n\nAVAILABLE")

func _equip_selected_skin() -> void:
	if account_manager == null:
		return
	var selected := SKIN_NAMES[selected_skin_index]
	if bool(account_manager.call("equip_skin", selected)):
		var world := get_tree().current_scene
		if world != null:
			var player := world.get_node_or_null("WARFOX_Player")
			if player != null and player.has_method("apply_equipped_loadout"):
				player.call("apply_equipped_loadout", account_manager)
		_refresh_skin_label()

