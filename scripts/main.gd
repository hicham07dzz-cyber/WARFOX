extends Node3D

const GRID_SIZE := 100
const CELL_SIZE := 12.0
const ISLAND_RADIUS := 570.0
var transport_plane: Node3D
var match_intro_time := 0.0
var drop_started := false
var match_player: WarfoxPlayer

func _ready() -> void:
	_setup_input()
	_build_environment()
	var terrain := _build_island()
	_build_water()
	_build_landmarks()
	_spawn_player(terrain)
	_build_transport_plane()
	_spawn_training_targets()
	_spawn_bots()
	_spawn_loot()
	_build_hud()

func _setup_input() -> void:
	_add_key("move_forward", KEY_W)
	_add_key("move_back", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("jump", KEY_SPACE)
	_add_key("sprint", KEY_SHIFT)
	_add_key("crouch", KEY_CTRL)
	_add_key("fire", KEY_F)
	_add_key("heal", KEY_H)
	_add_key("parachute", KEY_P)
	_add_key("reload", KEY_R)
	var mouse_fire := InputEventMouseButton.new()
	mouse_fire.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", mouse_fire)

func _add_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.12, 0.22, 0.34)
	sky_material.sky_horizon_color = Color(0.72, 0.62, 0.43)
	sky_material.ground_bottom_color = Color(0.10, 0.12, 0.13)
	sky_material.ground_horizon_color = Color(0.42, 0.39, 0.31)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

func _height_at(x: float, z: float) -> float:
	var distance := Vector2(x, z).length()
	var edge := clampf(1.0 - distance / ISLAND_RADIUS, 0.0, 1.0)
	var hills := sin(x * 0.012) * 17.0 + cos(z * 0.015) * 13.0
	var ridges := sin((x + z) * 0.006) * 24.0
	return maxf(-9.0, pow(edge, 0.62) * 92.0 + hills * edge + ridges * edge - 8.0)

func _build_island() -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := GRID_SIZE * CELL_SIZE * 0.5
	for iz in range(GRID_SIZE):
		for ix in range(GRID_SIZE):
			var x0 := float(ix) * CELL_SIZE - half
			var x1 := x0 + CELL_SIZE
			var z0 := float(iz) * CELL_SIZE - half
			var z1 := z0 + CELL_SIZE
			if Vector2((x0 + x1) * 0.5, (z0 + z1) * 0.5).length() > ISLAND_RADIUS:
				continue
			_add_triangle(surface, Vector3(x0, _height_at(x0, z0), z0), Vector3(x0, _height_at(x0, z1), z1), Vector3(x1, _height_at(x1, z0), z0))
			_add_triangle(surface, Vector3(x1, _height_at(x1, z0), z0), Vector3(x0, _height_at(x0, z1), z1), Vector3(x1, _height_at(x1, z1), z1))
	surface.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "WARFOX_Island_Terrain"
	mesh_instance.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material
	add_child(mesh_instance)

	var ground := StaticBody3D.new()
	ground.name = "IslandCollision"
	var collision := CollisionShape3D.new()
	collision.shape = mesh_instance.mesh.create_trimesh_shape()
	ground.add_child(collision)
	add_child(ground)
	return mesh_instance

func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a, b, c]:
		var color := Color(0.22, 0.34, 0.20)
		if point.y > 52.0:
			color = Color(0.39, 0.39, 0.34)
		elif point.y < 12.0:
			color = Color(0.62, 0.54, 0.35)
		surface.set_color(color)
		surface.add_vertex(point)

func _build_water() -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1800, 1800)
	water.mesh = plane
	water.position.y = -1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.025, 0.16, 0.23)
	mat.metallic = 0.28
	mat.roughness = 0.24
	water.material_override = mat
	add_child(water)

func _add_box_body(parent: Node3D, label: String, size: Vector3, local_position: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = label
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.84
	mesh.material_override = material
	body.add_child(mesh)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	body.position = local_position
	parent.add_child(body)

func _add_building(label: String, x: float, z: float, size: Vector3, color: Color) -> void:
	var building := Node3D.new()
	building.name = label
	building.position = Vector3(x, _height_at(x, z), z)
	add_child(building)

	var width := size.x
	var depth := size.z
	var height := size.y
	var wall := 1.2
	var door_width := minf(4.0, width * 0.12)
	var door_height := minf(3.2, height * 0.42)
	var half_w := width * 0.5
	var half_d := depth * 0.5

	_add_box_body(building, "Interior_Floor", Vector3(width, 1.0, depth), Vector3(0, 0.5, 0), color.darkened(0.22))
	_add_box_body(building, "Back_Wall", Vector3(width, height, wall), Vector3(0, height * 0.5, -half_d), color)
	_add_box_body(building, "Left_Wall", Vector3(wall, height, depth), Vector3(-half_w, height * 0.5, 0), color)
	_add_box_body(building, "Right_Wall", Vector3(wall, height, depth), Vector3(half_w, height * 0.5, 0), color)

	var side_width := (width - door_width) * 0.5
	_add_box_body(building, "Front_Wall_Left", Vector3(side_width, height, wall), Vector3(-(door_width + side_width) * 0.5, height * 0.5, half_d), color)
	_add_box_body(building, "Front_Wall_Right", Vector3(side_width, height, wall), Vector3((door_width + side_width) * 0.5, height * 0.5, half_d), color)
	_add_box_body(building, "Door_Lintel", Vector3(door_width, height - door_height, wall), Vector3(0, door_height + (height - door_height) * 0.5, half_d), color.darkened(0.12))
	_add_box_body(building, "Roof", Vector3(width + 1.0, 1.0, depth + 1.0), Vector3(0, height + 0.5, 0), color.darkened(0.3))

func _build_landmarks() -> void:
	_add_building("Central_Command_City", 0, 0, Vector3(100, 34, 90), Color(0.24, 0.29, 0.32))
	_add_building("Air_Defense_Base", -235, -80, Vector3(90, 20, 75), Color(0.27, 0.30, 0.29))
	_add_building("Airport_Hangar", 245, 115, Vector3(110, 16, 55), Color(0.36, 0.37, 0.35))
	_add_building("Industrial_Zone", 60, 300, Vector3(105, 23, 80), Color(0.34, 0.29, 0.23))
	_add_building("Coastal_Village", -330, 210, Vector3(65, 12, 60), Color(0.49, 0.40, 0.28))

func _spawn_player(_terrain: MeshInstance3D) -> void:
	var player_script = load("res://scripts/player_controller.gd")
	var player := CharacterBody3D.new()
	player.name = "WARFOX_Player"
	player.set_script(player_script)
	player.position = Vector3(-35, 174, 0)
	add_child(player)
	player.velocity = Vector3(0, -15, 0)
	match_player = player
	set_meta("player", player)

func _build_hud() -> void:
	var hud_script = load("res://scripts/mobile_hud.gd")
	var hud := CanvasLayer.new()
	hud.set_script(hud_script)
	add_child(hud)
	hud.player = get_meta("player")

func _spawn_training_targets() -> void:
	var target_script = load("res://scripts/training_target.gd")
	for x in [-4.0, 0.0, 4.0]:
		var target := StaticBody3D.new()
		target.name = "Training_Target_" + str(int(x))
		target.set_script(target_script)
		target.position = Vector3(x, _height_at(x, 54.0), 54.0)
		add_child(target)


func _spawn_bots() -> void:
	var bot_script = load("res://scripts/warfox_bot.gd")
	for point in [Vector2(-9.0, 56.0), Vector2(9.0, 56.0)]:
		var bot := CharacterBody3D.new()
		bot.name = "WARFOX_Training_Bot"
		bot.set_script(bot_script)
		bot.position = Vector3(point.x, _height_at(point.x, point.y), point.y)
		add_child(bot)


func _build_transport_plane() -> void:
	transport_plane = Node3D.new()
	transport_plane.name = "WARFOX_Transport_Aircraft"
	transport_plane.position = Vector3(-145, 183, 0)
	transport_plane.rotation.y = -PI * 0.5
	add_child(transport_plane)
	var hull_mat := StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.16, 0.20, 0.20)
	hull_mat.metallic = 0.48
	hull_mat.roughness = 0.52
	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = Color(0.88, 0.25, 0.055)
	trim_mat.metallic = 0.25
	_add_aircraft_box(transport_plane, "Fuselage", Vector3(3.4, 3.2, 22.0), Vector3(0, 0, 0), hull_mat)
	_add_aircraft_box(transport_plane, "Main_Wing", Vector3(31.0, 0.55, 5.2), Vector3(0, 0.3, -1.0), hull_mat)
	_add_aircraft_box(transport_plane, "Tail_Wing", Vector3(12.0, 0.4, 3.0), Vector3(0, 1.0, 8.2), hull_mat)
	_add_aircraft_box(transport_plane, "Tail_Fin", Vector3(0.55, 4.2, 3.5), Vector3(0, 2.3, 8.7), hull_mat)
	_add_aircraft_box(transport_plane, "Nose_Stripe", Vector3(3.1, 1.0, 1.0), Vector3(0, -0.2, -10.8), trim_mat)
	for side in [-1.0, 1.0]:
		var engine := MeshInstance3D.new()
		var engine_mesh := CylinderMesh.new()
		engine_mesh.top_radius = 0.8
		engine_mesh.bottom_radius = 0.8
		engine_mesh.height = 4.0
		engine.mesh = engine_mesh
		engine.rotation.x = PI * 0.5
		engine.position = Vector3(side * 8.0, -0.25, -1.0)
		engine.material_override = hull_mat
		transport_plane.add_child(engine)
		_add_aircraft_box(transport_plane, "Engine_Orange_Marking", Vector3(1.7, 0.12, 1.0), Vector3(side * 8.0, 0.35, -1.0), trim_mat)
	_add_aircraft_box(transport_plane, "Rear_Ramp", Vector3(2.8, 0.25, 3.0), Vector3(0, -1.4, 12.0), trim_mat)

func _add_aircraft_box(parent: Node3D, label: String, size: Vector3, pos: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	part.material_override = material
	parent.add_child(part)

func _process(delta: float) -> void:
	if transport_plane == null or match_player == null:
		return
	match_intro_time += delta
	transport_plane.position.x += 48.0 * delta
	transport_plane.position.z = sin(match_intro_time * 0.42) * 7.0
	transport_plane.rotation.z = sin(match_intro_time * 0.42) * 0.025
	if not drop_started and match_intro_time >= 2.4:
		drop_started = true
		match_player.deploy_parachute()
	if match_intro_time >= 9.0:
		transport_plane.visible = false


func _spawn_loot() -> void:
	var loot_script = load("res://scripts/loot_pickup.gd")
	var pickups := [
		{"type": "ammo", "amount": 60, "position": Vector2(-18, 42)},
		{"type": "medkit", "amount": 2, "position": Vector2(-25, 48)},
		{"type": "ammo", "amount": 60, "position": Vector2(18, 42)},
		{"type": "medkit", "amount": 2, "position": Vector2(25, 48)},
		{"type": "ammo", "amount": 90, "position": Vector2(-235, -80)},
		{"type": "medkit", "amount": 1, "position": Vector2(245, 115)},
		{"type": "ammo", "amount": 60, "position": Vector2(60, 300)},
		{"type": "medkit", "amount": 2, "position": Vector2(-330, 210)}
	]
	for data in pickups:
		var pickup := Area3D.new()
		pickup.set_script(loot_script)
		pickup.pickup_type = data["type"]
		pickup.amount = data["amount"]
		var point: Vector2 = data["position"]
		pickup.position = Vector3(point.x, _height_at(point.x, point.y) + 0.9, point.y)
		add_child(pickup)
