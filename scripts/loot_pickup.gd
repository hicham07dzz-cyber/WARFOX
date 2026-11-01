extends Area3D
class_name WarfoxLootPickup

@export_enum("ammo", "medkit") var pickup_type := "ammo"
@export var amount := 60
var spin_clock := 0.0
var visual_root: Node3D

func _ready() -> void:
	name = "Loot_" + pickup_type.capitalize()
	monitoring = true
	monitorable = true
	var trigger := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.35
	trigger.shape = sphere
	add_child(trigger)
	_build_visual()
	body_entered.connect(_on_body_entered)

func _build_visual() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	var crate_mat := StandardMaterial3D.new()
	crate_mat.albedo_color = Color(0.12, 0.20, 0.22) if pickup_type == "ammo" else Color(0.16, 0.28, 0.17)
	crate_mat.metallic = 0.22
	crate_mat.roughness = 0.58
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = Color(1.0, 0.48, 0.08) if pickup_type == "ammo" else Color(0.95, 0.88, 0.72)
	accent_mat.emission_enabled = true
	accent_mat.emission = accent_mat.albedo_color
	accent_mat.emission_energy_multiplier = 0.7
	var crate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.65, 0.75)
	crate.mesh = box
	crate.material_override = crate_mat
	visual_root.add_child(crate)
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(0.94, 0.12, 0.79)
	stripe.mesh = stripe_mesh
	stripe.position.y = 0.18
	stripe.material_override = accent_mat
	visual_root.add_child(stripe)
	if pickup_type == "medkit":
		var vertical := MeshInstance3D.new()
		var vertical_mesh := BoxMesh.new()
		vertical_mesh.size = Vector3(0.16, 0.38, 0.08)
		vertical.mesh = vertical_mesh
		vertical.position = Vector3(0, 0.38, -0.39)
		vertical.material_override = accent_mat
		visual_root.add_child(vertical)
		var horizontal := MeshInstance3D.new()
		var horizontal_mesh := BoxMesh.new()
		horizontal_mesh.size = Vector3(0.38, 0.14, 0.08)
		horizontal.mesh = horizontal_mesh
		horizontal.position = Vector3(0, 0.38, -0.39)
		horizontal.material_override = accent_mat
		visual_root.add_child(horizontal)

func _process(delta: float) -> void:
	spin_clock += delta
	if visual_root != null:
		visual_root.rotation.y = spin_clock * 0.75
		visual_root.position.y = 0.16 + sin(spin_clock * 2.2) * 0.10

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("warfox_player") and body.has_method("apply_pickup"):
		if body.apply_pickup(pickup_type, amount):
			queue_free()
