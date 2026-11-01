extends Node3D

const GRID_SIZE := 100
const CELL_SIZE := 12.0
const ISLAND_RADIUS := 570.0
var transport_plane: Node3D
var match_intro_time := 0.0
var drop_started := false
var match_player: WarfoxPlayer
var safe_zone_visual: MeshInstance3D
var safe_zone_elapsed := 0.0
var safe_zone_damage_clock := 0.0
var safe_zone_bot_damage_clock := 0.0
var safe_zone_radius := 520.0
var safe_zone_last_visual_radius := 520.0

func _ready() -> void:
	var account_manager := Node.new()
	account_manager.name = "WARFOX_Account"
	account_manager.set_script(load("res://scripts/account_manager.gd"))
	add_child(account_manager)
	account_manager.call("register_match")
	set_meta("account_manager", account_manager)
	_setup_input()
	_build_environment()
	var terrain := _build_island()
	_build_water()
	_build_landmarks()
	_build_nature_dressing()
	_build_roads()
	_build_region_details()
	_spawn_player(terrain)
	_build_transport_plane()
	_spawn_training_targets()
	_spawn_bots()
	_spawn_loot()
	_build_safe_zone()
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
	# Ten named regions from design/ISLAND_MAP.md. Coordinates are kept
	# inside the island and spread to create distinct combat routes.
	_add_building("01_Central_Command_City", 0, 0, Vector3(100, 34, 90), Color(0.24, 0.29, 0.32))
	_add_building("01_Central_Command_Tower", 58, -28, Vector3(24, 52, 24), Color(0.19, 0.24, 0.29))

	_add_building("02_Air_Defense_Base", -235, -80, Vector3(90, 20, 75), Color(0.27, 0.30, 0.29))
	_add_building("02_Radar_Control_Building", -280, -112, Vector3(28, 13, 24), Color(0.20, 0.25, 0.25))

	_add_building("03_WARFOX_International_Airfield", 245, 115, Vector3(110, 16, 55), Color(0.36, 0.37, 0.35))
	_add_building("03_Airfield_Terminal", 305, 150, Vector3(52, 12, 30), Color(0.42, 0.44, 0.43))

	_add_building("04_Ironworks_Industrial_Zone", 60, 300, Vector3(105, 23, 80), Color(0.34, 0.29, 0.23))
	_add_building("04_Ironworks_Warehouse", 112, 345, Vector3(42, 17, 32), Color(0.28, 0.30, 0.30))

	_add_building("05_Coastal_Village", -330, 210, Vector3(65, 12, 60), Color(0.49, 0.40, 0.28))
	_add_building("05_Coastal_Market_Hall", -285, 245, Vector3(28, 9, 22), Color(0.52, 0.42, 0.29))

	_add_building("06_Pinecrest_Forest_Cabin_East", 350, -180, Vector3(24, 9, 20), Color(0.32, 0.25, 0.17))
	_add_building("06_Pinecrest_Forest_Cabin_West", 325, -215, Vector3(20, 8, 18), Color(0.36, 0.28, 0.18))

	_add_building("07_Redstone_Highlands_Lookout", -410, -230, Vector3(30, 11, 26), Color(0.40, 0.34, 0.27))
	_add_building("07_Redstone_Ridge_Shelter", -375, -265, Vector3(18, 7, 16), Color(0.35, 0.30, 0.25))

	_add_building("08_Sunset_Resort_Hotel", -150, 350, Vector3(58, 20, 38), Color(0.47, 0.36, 0.28))
	_add_building("08_Sunset_Resort_Beach_Club", -120, 375, Vector3(30, 8, 20), Color(0.56, 0.43, 0.31))

	_add_building("09_Old_Quarry_Processing_House", 410, 220, Vector3(34, 13, 28), Color(0.36, 0.34, 0.29))
	_add_building("09_Old_Quarry_Machinery_Shed", 390, 250, Vector3(22, 8, 18), Color(0.30, 0.31, 0.29))

	_add_building("10_Signal_Station_Main", 150, -390, Vector3(36, 16, 30), Color(0.25, 0.31, 0.34))
	_add_building("10_Signal_Station_Generator", 190, -360, Vector3(18, 8, 16), Color(0.22, 0.26, 0.28))


# Temporary procedural nature dressing. These meshes are shared and lightweight;
# replace them with licensed GLB assets when the art pack is imported.
func _build_nature_dressing() -> void:
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.25, 0.16, 0.09)
	trunk_mat.roughness = 1.0
	var pine_mat := StandardMaterial3D.new()
	pine_mat.albedo_color = Color(0.075, 0.20, 0.13)
	pine_mat.roughness = 1.0
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.12, 0.29, 0.16)
	leaf_mat.roughness = 1.0
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.34, 0.33, 0.29)
	rock_mat.roughness = 1.0

	# Pinecrest Forest: dense tree clusters around, not on top of, the cabins.
	for i in range(42):
		var angle := float(i) * 2.399
		var radius := 28.0 + float(i % 7) * 8.0
		var x := 350.0 + cos(angle) * radius
		var z := -180.0 + sin(angle) * radius
		_add_pine_tree(x, z, 0.82 + float(i % 5) * 0.10, trunk_mat, pine_mat)

	# Redstone ridges and Old Quarry get scattered boulders for a stronger silhouette.
	for i in range(22):
		var angle := float(i) * 2.17
		var radius := 16.0 + float(i % 6) * 7.0
		_add_rock(-410.0 + cos(angle) * radius, -230.0 + sin(angle) * radius,
			0.9 + float(i % 4) * 0.28, rock_mat)
	for i in range(16):
		var angle := float(i) * 2.41
		var radius := 22.0 + float(i % 5) * 6.0
		_add_rock(410.0 + cos(angle) * radius, 220.0 + sin(angle) * radius,
			0.8 + float(i % 3) * 0.25, rock_mat)

	# Coastal Village and Sunset Resort receive palm silhouettes.
	for i in range(12):
		var angle := float(i) * TAU / 12.0
		_add_palm_tree(-330.0 + cos(angle) * 52.0, 210.0 + sin(angle) * 48.0,
			1.0 + float(i % 3) * 0.12, trunk_mat, leaf_mat)
	for i in range(10):
		var angle := float(i) * TAU / 10.0
		_add_palm_tree(-150.0 + cos(angle) * 62.0, 350.0 + sin(angle) * 48.0,
			1.05 + float(i % 2) * 0.12, trunk_mat, leaf_mat)

func _add_pine_tree(x: float, z: float, tree_scale: float, trunk_mat: Material, leaf_mat: Material) -> void:
	var tree := Node3D.new()
	tree.name = "Pinecrest_Pine"
	tree.position = Vector3(x, _height_at(x, z), z)
	tree.scale = Vector3.ONE * tree_scale
	add_child(tree)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.25
	trunk_mesh.height = 2.8
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.4
	trunk.material_override = trunk_mat
	tree.add_child(trunk)
	for tier in range(3):
		var crown := MeshInstance3D.new()
		var crown_mesh := ConeMesh.new()
		crown_mesh.bottom_radius = 1.25 - float(tier) * 0.25
		crown_mesh.height = 2.15
		crown.mesh = crown_mesh
		crown.position.y = 2.0 + float(tier) * 0.92
		crown.material_override = leaf_mat
		tree.add_child(crown)

func _add_palm_tree(x: float, z: float, tree_scale: float, trunk_mat: Material, leaf_mat: Material) -> void:
	var tree := Node3D.new()
	tree.name = "Coastal_Palm"
	tree.position = Vector3(x, _height_at(x, z), z)
	tree.scale = Vector3.ONE * tree_scale
	add_child(tree)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.13
	trunk_mesh.bottom_radius = 0.23
	trunk_mesh.height = 4.8
	trunk.mesh = trunk_mesh
	trunk.position.y = 2.4
	trunk.rotation.z = -0.10
	trunk.material_override = trunk_mat
	tree.add_child(trunk)
	for frond in range(6):
		var leaf := MeshInstance3D.new()
		var leaf_mesh := BoxMesh.new()
		leaf_mesh.size = Vector3(0.22, 0.10, 2.25)
		leaf.mesh = leaf_mesh
		leaf.position = Vector3(0, 4.65, 0)
		leaf.rotation.y = float(frond) * TAU / 6.0
		leaf.rotation.x = -0.18
		leaf.material_override = leaf_mat
		tree.add_child(leaf)

func _add_rock(x: float, z: float, rock_scale: float, rock_mat: Material) -> void:
	var rock := MeshInstance3D.new()
	rock.name = "Terrain_Boulder"
	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 1.0
	rock_mesh.height = 1.7
	rock_mesh.radial_segments = 7
	rock_mesh.rings = 4
	rock.mesh = rock_mesh
	rock.scale = Vector3(rock_scale * 1.35, rock_scale * 0.72, rock_scale)
	rock.position = Vector3(x, _height_at(x, z) + rock_scale * 0.35, z)
	rock.rotation = Vector3(float(int(x) % 7) * 0.08, float(int(z) % 9), 0.12)
	rock.material_override = rock_mat
	add_child(rock)

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
	# Distributed combatants across the island; two remain near the initial landing area.
	var spawn_points := [
		Vector2(-9.0, 56.0), Vector2(9.0, 56.0),
		Vector2(-235.0, -80.0), Vector2(-205.0, -55.0),
		Vector2(245.0, 115.0), Vector2(275.0, 135.0),
		Vector2(60.0, 300.0), Vector2(95.0, 325.0),
		Vector2(-330.0, 210.0), Vector2(-300.0, 235.0),
		Vector2(360.0, -180.0), Vector2(325.0, -215.0),
		Vector2(-410.0, -230.0), Vector2(-375.0, -265.0),
		Vector2(150.0, -390.0), Vector2(190.0, -360.0)
	]
	for index in range(spawn_points.size()):
		var point: Vector2 = spawn_points[index]
		var bot := CharacterBody3D.new()
		bot.name = "WARFOX_Bot_%02d" % (index + 1)
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
	if transport_plane != null and match_player != null:
		match_intro_time += delta
		transport_plane.position.x += 48.0 * delta
		transport_plane.position.z = sin(match_intro_time * 0.42) * 7.0
		transport_plane.rotation.z = sin(match_intro_time * 0.42) * 0.025
		if not drop_started and match_intro_time >= 2.4:
			drop_started = true
			match_player.deploy_parachute()
		if match_intro_time >= 9.0:
			transport_plane.visible = false
	_update_safe_zone(delta)

func _build_safe_zone() -> void:
	safe_zone_visual = MeshInstance3D.new()
	safe_zone_visual.name = "WARFOX_Safe_Zone_Boundary"
	var ring := TorusMesh.new()
	ring.inner_radius = safe_zone_radius - 1.2
	ring.outer_radius = safe_zone_radius + 1.2
	ring.rings = 6
	ring.ring_segments = 128
	safe_zone_visual.mesh = ring
	safe_zone_visual.position = Vector3(0, 25, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.72, 1.0, 0.78)
	material.emission_enabled = true
	material.emission = Color(0.05, 0.42, 1.0)
	material.emission_energy_multiplier = 1.6
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	safe_zone_visual.material_override = material
	add_child(safe_zone_visual)

func _update_safe_zone(delta: float) -> void:
	if match_player == null or safe_zone_visual == null:
		return
	safe_zone_elapsed += delta
	var shrink_progress := clampf((safe_zone_elapsed - 30.0) / 240.0, 0.0, 1.0)
	safe_zone_radius = lerpf(520.0, 90.0, shrink_progress)
	if absf(safe_zone_radius - safe_zone_last_visual_radius) >= 1.0:
		var ring := safe_zone_visual.mesh as TorusMesh
		ring.inner_radius = maxf(1.0, safe_zone_radius - 1.2)
		ring.outer_radius = safe_zone_radius + 1.2
		safe_zone_last_visual_radius = safe_zone_radius
	var player_distance := Vector2(match_player.global_position.x, match_player.global_position.z).length()
	if player_distance > safe_zone_radius:
		safe_zone_damage_clock += delta
		if safe_zone_damage_clock >= 1.5:
			safe_zone_damage_clock = 0.0
			match_player.receive_damage(5)
	else:
		safe_zone_damage_clock = 0.0

	safe_zone_bot_damage_clock += delta
	if safe_zone_bot_damage_clock >= 1.5:
		safe_zone_bot_damage_clock = 0.0
		for bot in get_tree().get_nodes_in_group("warfox_bots"):
			if not is_instance_valid(bot) or bot.health <= 0:
				continue
			var bot_distance := Vector2(bot.global_position.x, bot.global_position.z).length()
			if bot_distance > safe_zone_radius and bot.has_method("receive_zone_damage"):
				bot.receive_zone_damage(5)


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
		{"type": "medkit", "amount": 2, "position": Vector2(-330, 210)},
		{"type": "ammo", "amount": 90, "position": Vector2(360, -180)},
		{"type": "medkit", "amount": 1, "position": Vector2(325, -215)},
		{"type": "ammo", "amount": 60, "position": Vector2(-410, -230)},
		{"type": "medkit", "amount": 1, "position": Vector2(-375, -265)},
		{"type": "ammo", "amount": 90, "position": Vector2(150, -390)},
		{"type": "medkit", "amount": 2, "position": Vector2(190, -360)},
		{"type": "ammo", "amount": 60, "position": Vector2(-150, 350)},
		{"type": "medkit", "amount": 1, "position": Vector2(-120, 375)},
		{"type": "ammo", "amount": 90, "position": Vector2(410, 220)},
		{"type": "medkit", "amount": 1, "position": Vector2(390, 250)},
		{"type": "ammo", "amount": 60, "position": Vector2(-40, -420)},
		{"type": "medkit", "amount": 2, "position": Vector2(-10, -390)}
	]
	for data in pickups:
		var pickup := Area3D.new()
		pickup.set_script(loot_script)
		pickup.pickup_type = data["type"]
		pickup.amount = data["amount"]
		var point: Vector2 = data["position"]
		pickup.position = Vector3(point.x, _height_at(point.x, point.y) + 0.9, point.y)
		add_child(pickup)


# Curved terrain-following roads connect the ten named regions.
# Roads are generated as one static mesh per route to keep node counts low.
func _build_roads() -> void:
	var road_material := StandardMaterial3D.new()
	road_material.albedo_color = Color(0.105, 0.12, 0.125)
	road_material.roughness = 0.96
	road_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var route_sets: Array = [
		[Vector2(-12, 8), Vector2(-72, -18), Vector2(-145, -42), Vector2(-235, -80)],
		[Vector2(10, 5), Vector2(82, 34), Vector2(160, 75), Vector2(245, 115)],
		[Vector2(4, 18), Vector2(28, 105), Vector2(48, 205), Vector2(60, 300)],
		[Vector2(-8, 15), Vector2(-92, 70), Vector2(-205, 142), Vector2(-330, 210)],
		[Vector2(12, -8), Vector2(105, -58), Vector2(220, -112), Vector2(350, -180)],
		[Vector2(-12, -10), Vector2(-120, -78), Vector2(-255, -150), Vector2(-410, -230)],
		[Vector2(-8, 18), Vector2(-52, 112), Vector2(-100, 226), Vector2(-150, 350)],
		[Vector2(15, 5), Vector2(120, 70), Vector2(250, 145), Vector2(410, 220)],
		[Vector2(5, -18), Vector2(48, -115), Vector2(95, -245), Vector2(150, -390)],
		[Vector2(-235, -80), Vector2(-180, -190), Vector2(-95, -300), Vector2(0, -405), Vector2(150, -390)]
	]
	for index in range(route_sets.size()):
		_add_road(route_sets[index], 8.5 if index < 9 else 6.5, road_material)

func _add_road(points: Array, road_width: float, road_material: Material) -> void:
	if points.size() < 2:
		return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_width := road_width * 0.5
	for index in range(points.size() - 1):
		var start: Vector2 = points[index]
		var finish: Vector2 = points[index + 1]
		var direction := (finish - start).normalized()
		if direction.length_squared() < 0.001:
			continue
		var side := Vector2(-direction.y, direction.x) * half_width
		var left_start := start + side
		var right_start := start - side
		var left_end := finish + side
		var right_end := finish - side
		var a := Vector3(left_start.x, _height_at(left_start.x, left_start.y) + 0.34, left_start.y)
		var b := Vector3(right_start.x, _height_at(right_start.x, right_start.y) + 0.34, right_start.y)
		var c := Vector3(left_end.x, _height_at(left_end.x, left_end.y) + 0.34, left_end.y)
		var d := Vector3(right_end.x, _height_at(right_end.x, right_end.y) + 0.34, right_end.y)
		surface.add_vertex(a)
		surface.add_vertex(b)
		surface.add_vertex(c)
		surface.add_vertex(c)
		surface.add_vertex(b)
		surface.add_vertex(d)
	surface.generate_normals()
	var road := MeshInstance3D.new()
	road.name = "WARFOX_Road_Route"
	road.mesh = surface.commit()
	road.material_override = road_material
	add_child(road)


# Distinct visual landmarks help players recognize each island region.
# Decorative pieces intentionally have no collision to keep mobile physics light.
func _build_region_details() -> void:
	var concrete := _make_detail_material(Color(0.24, 0.28, 0.30))
	var pale_concrete := _make_detail_material(Color(0.62, 0.63, 0.59))
	var runway_paint := _make_detail_material(Color(0.86, 0.87, 0.81))
	var cyan_glass := _make_detail_material(Color(0.08, 0.56, 0.65), 0.25, 0.25)
	var pool_water := _make_detail_material(Color(0.025, 0.42, 0.58), 0.35, 0.18)
	var warm_light := _make_detail_material(Color(1.0, 0.66, 0.28), 0.1, 0.35)
	var metal := _make_detail_material(Color(0.16, 0.20, 0.22), 0.72, 0.42)

	# Central Command City: glass accents and a readable plaza grid.
	for i in range(4):
		var offset := float(i) * 18.0 - 27.0
		_add_detail_box("City_Plaza_Paving", Vector3(offset, _height_at(offset, 48.0) + 0.18, 48.0),
			Vector3(0.7, 0.12, 34.0), pale_concrete)
	_add_detail_box("City_Tower_Glass_Front", Vector3(58, _height_at(58, -40) + 18.0, -40),
		Vector3(14, 25, 0.35), cyan_glass)

	# Airfield: runway centerline, threshold bars and edge lights.
	for i in range(11):
		var z := 88.0 + float(i) * 5.2
		_add_detail_box("Runway_Center_Marking", Vector3(245, _height_at(245, z) + 0.42, z),
			Vector3(1.0, 0.08, 2.8), runway_paint)
	for side in [-1.0, 1.0]:
		for i in range(7):
			var x := 218.0 + float(i) * 9.0
			_add_detail_box("Runway_Threshold_Marking", Vector3(x, _height_at(x, 88.0 + side * 22.0) + 0.43, 88.0 + side * 22.0),
				Vector3(3.8, 0.08, 0.65), runway_paint)
		for i in range(9):
			var z := 72.0 + float(i) * 10.0
			_add_detail_box("Airfield_Edge_Light", Vector3(188.0 + side * 0.0, _height_at(188.0, z) + 0.65, z),
				Vector3(0.42, 0.75, 0.42), warm_light)

	# Ironworks: three smokestacks create a recognizable industrial skyline.
	for i in range(3):
		var x := 35.0 + float(i) * 24.0
		_add_detail_cylinder("Ironworks_Stack", Vector3(x, _height_at(x, 270.0) + 15.0, 270.0),
			2.1, 30.0, metal)

	# Sunset Resort: pool deck and blue pool beside the hotel.
	_add_detail_box("Resort_Pool_Water", Vector3(-112, _height_at(-112, 326) + 0.28, 326),
		Vector3(23, 0.22, 12), pool_water)
	_add_detail_box("Resort_Pool_Deck", Vector3(-112, _height_at(-112, 326) + 0.12, 326),
		Vector3(29, 0.18, 18), pale_concrete)
	_add_detail_box("Resort_Boardwalk", Vector3(-178, _height_at(-178, 378) + 0.18, 378),
		Vector3(76, 0.28, 5), concrete)

	# Old Quarry: visible stepped retaining walls around the excavation.
	for tier in range(3):
		var radius := 29.0 + float(tier) * 10.0
		var y := _height_at(410.0 + radius, 220.0) + 1.0 + float(tier) * 2.0
		_add_detail_box("Quarry_Terrace_Wall", Vector3(410.0 + radius, y, 220.0),
			Vector3(2.0, 2.2, 35.0 + float(tier) * 7.0), concrete)

	# Signal Station: antenna mast with crossbars and a small beacon.
	_add_detail_cylinder("Signal_Antenna_Mast", Vector3(150, _height_at(150, -390) + 18.0, -390),
		0.48, 36.0, metal)
	for height in [12.0, 22.0, 30.0]:
		_add_detail_box("Signal_Antenna_Crossbar", Vector3(150, _height_at(150, -390) + height, -390),
			Vector3(7.5, 0.28, 0.28), pale_concrete)
	_add_detail_box("Signal_Beacon", Vector3(150, _height_at(150, -390) + 36.8, -390),
		Vector3(0.9, 0.9, 0.9), warm_light)

	# A small number of warm street lamps make the central plaza legible.
	for point in [Vector2(-34, 36), Vector2(34, 36), Vector2(-34, -36), Vector2(34, -36)]:
		_add_street_lamp(point.x, point.y, metal, warm_light)

func _make_detail_material(color: Color, metallic: float = 0.0, roughness: float = 0.86) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

func _add_detail_box(label: String, position: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	add_child(visual)

func _add_detail_cylinder(label: String, position: Vector3, radius: float, height: float, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.82
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	add_child(visual)

func _add_street_lamp(x: float, z: float, metal: Material, lamp_material: Material) -> void:
	var base_y := _height_at(x, z)
	_add_detail_cylinder("City_Lamp_Post", Vector3(x, base_y + 3.0, z), 0.13, 6.0, metal)
	_add_detail_box("City_Lamp_Head", Vector3(x, base_y + 6.2, z), Vector3(1.0, 0.28, 1.0), lamp_material)
