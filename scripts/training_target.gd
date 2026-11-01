extends StaticBody3D
class_name WarfoxTrainingTarget

const MAX_HEALTH := 100
var health := MAX_HEALTH
var respawning := false
var visual: MeshInstance3D
var health_label: Label3D
var target_material: StandardMaterial3D
var hit_flash_time := 0.0

func _ready() -> void:
	_build_target()

func _build_target() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.9
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.95
	add_child(collision)

	visual = MeshInstance3D.new()
	visual.name = "TrainingDummyVisual"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.46
	mesh.height = 1.85
	visual.mesh = mesh
	visual.position.y = 0.95
	target_material = StandardMaterial3D.new()
	target_material.albedo_color = Color(0.78, 0.24, 0.12)
	target_material.roughness = 0.8
	visual.material_override = target_material
	add_child(visual)

	var plate := MeshInstance3D.new()
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(0.5, 0.32, 0.08)
	plate.mesh = plate_mesh
	plate.position = Vector3(0, 1.2, -0.43)
	var plate_material := StandardMaterial3D.new()
	plate_material.albedo_color = Color(0.12, 0.16, 0.18)
	plate.material_override = plate_material
	add_child(plate)

	health_label = Label3D.new()
	health_label.text = "100 HP"
	health_label.position = Vector3(0, 2.15, 0)
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 32
	health_label.modulate = Color(1.0, 0.85, 0.65)
	add_child(health_label)

func _process(delta: float) -> void:
	if hit_flash_time > 0.0:
		hit_flash_time = maxf(0.0, hit_flash_time - delta)
		var blend := hit_flash_time / 0.12
		target_material.albedo_color = Color(1.0, 0.82, 0.68).lerp(Color(0.78, 0.24, 0.12), 1.0 - blend)

func receive_hit(damage: int) -> void:
	if respawning:
		return
	health = maxi(0, health - damage)
	hit_flash_time = 0.12
	target_material.albedo_color = Color(1.0, 0.82, 0.68)
	health_label.text = str(health) + " HP"
	if health == 0:
		respawning = true
		visual.visible = false
		health_label.text = "TARGET DOWN"
		set_collision_layer_value(1, false)
		var timer := get_tree().create_timer(2.5)
		timer.timeout.connect(_respawn)

func _respawn() -> void:
	health = MAX_HEALTH
	respawning = false
	visual.visible = true
	target_material.albedo_color = Color(0.78, 0.24, 0.12)
	health_label.text = "100 HP"
	set_collision_layer_value(1, true)
