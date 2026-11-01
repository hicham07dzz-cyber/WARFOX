extends Node3D

# WARFOX first playable foundation: a generated island map preview.
# All geometry is built from Godot primitives so the project needs no paid assets.

const GRID_SIZE := 100
const CELL_SIZE := 12.0
const ISLAND_RADIUS := 570.0
const WATER_LEVEL := 0.0

func _ready() -> void:
	_build_environment()
	_build_island()
	_build_water()
	_build_landmarks()
	_build_preview_camera()
	_build_title()

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
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

func _height_at(x: float, z: float) -> float:
	var distance := Vector2(x, z).length()
	var edge := clampf(1.0 - distance / ISLAND_RADIUS, 0.0, 1.0)
	var hills := sin(x * 0.012) * 17.0 + cos(z * 0.015) * 13.0
	var ridges := sin((x + z) * 0.006) * 24.0
	var central_mass := pow(edge, 0.62) * 92.0
	return maxf(-9.0, central_mass + hills * edge + ridges * edge - 8.0)

func _build_island() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := GRID_SIZE * CELL_SIZE * 0.5
	for iz in range(GRID_SIZE):
		for ix in range(GRID_SIZE):
			var x0 := float(ix) * CELL_SIZE - half
			var x1 := x0 + CELL_SIZE
			var z0 := float(iz) * CELL_SIZE - half
			var z1 := z0 + CELL_SIZE
			var center := Vector2((x0 + x1) * 0.5, (z0 + z1) * 0.5)
			if center.length() > ISLAND_RADIUS:
				continue
			# Upward-facing triangle winding for the island surface.
			_add_terrain_triangle(surface, Vector3(x0, _height_at(x0, z0), z0), Vector3(x0, _height_at(x0, z1), z1), Vector3(x1, _height_at(x1, z0), z0))
			_add_terrain_triangle(surface, Vector3(x1, _height_at(x1, z0), z0), Vector3(x0, _height_at(x0, z1), z1), Vector3(x1, _height_at(x1, z1), z1))
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

func _add_terrain_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
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
	water.name = "Ocean"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1800.0, 1800.0)
	water.mesh = plane
	water.position.y = WATER_LEVEL - 1.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.025, 0.16, 0.23)
	material.metallic = 0.28
	material.roughness = 0.24
	water.material_override = material
	add_child(water)

func _add_landmark(label: String, position: Vector3, size: Vector3, color: Color) -> void:
	var building := MeshInstance3D.new()
	building.name = label
	var box := BoxMesh.new()
	box.size = size
	building.mesh = box
	building.position = position + Vector3(0.0, size.y * 0.5, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	building.material_override = material
	add_child(building)

func _build_landmarks() -> void:
	# Initial named regions; detailed layouts and original assets come in later stages.
	_add_landmark("Central_Command_City", Vector3(0, _height_at(0, 0), 0), Vector3(100, 34, 90), Color(0.24, 0.29, 0.32))
	_add_landmark("Air_Defense_Base", Vector3(-235, _height_at(-235, -80), -80), Vector3(90, 20, 75), Color(0.27, 0.30, 0.29))
	_add_landmark("Airport_Hangar", Vector3(245, _height_at(245, 115), 115), Vector3(110, 16, 55), Color(0.36, 0.37, 0.35))
	_add_landmark("Industrial_Zone", Vector3(60, _height_at(60, 300), 300), Vector3(105, 23, 80), Color(0.34, 0.29, 0.23))
	_add_landmark("Coastal_Village", Vector3(-330, _height_at(-330, 210), 210), Vector3(65, 12, 60), Color(0.49, 0.40, 0.28))

func _build_preview_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "MapPreviewCamera"
	camera.position = Vector3(1050.0, 1000.0, 1050.0)
	camera.look_at(Vector3(0.0, 25.0, 0.0), Vector3.UP)
	camera.current = true
	camera.fov = 48.0
	add_child(camera)

func _build_title() -> void:
	var label := Label3D.new()
	label.name = "WARFOX_Title"
	label.text = "WARFOX  |  ISLAND MAP PROTOTYPE"
	label.font_size = 48
	label.pixel_size = 0.012
	label.modulate = Color(1.0, 0.43, 0.08)
	label.position = Vector3(0.0, 175.0, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
