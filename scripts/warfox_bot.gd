extends CharacterBody3D
class_name WarfoxBot

const MOVE_SPEED := 2.8
const GRAVITY := 22.0
const MAX_HEALTH := 100
const HIT_DAMAGE := 8
const ATTACK_RANGE := 1.65
const ATTACK_COOLDOWN := 1.1
const RESPAWN_DELAY := 3.0

var health := MAX_HEALTH
var player: Node3D
var attack_timer := 0.0
var spawn_position := Vector3.ZERO
var visual_root: Node3D
var body_material: StandardMaterial3D

func _ready() -> void:
	spawn_position = global_position
	_build_bot()
	add_to_group("warfox_bots")

func _build_bot() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)

	visual_root = Node3D.new()
	visual_root.name = "BotVisual"
	add_child(visual_root)
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.18, 0.27, 0.34)
	body_material.metallic = 0.18
	body_material.roughness = 0.62
	var accent := StandardMaterial3D.new()
	accent.albedo_color = Color(1.0, 0.32, 0.08)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.055, 0.075, 0.09)

	_add_part(BoxMesh.new(), Vector3(0.68, 0.7, 0.38), Vector3(0, 1.12, 0), body_material)
	_add_part(CapsuleMesh.new(), Vector3(0.36, 0.42, 0.36), Vector3(0, 1.76, 0), dark)
	_add_part(BoxMesh.new(), Vector3(0.42, 0.09, 0.045), Vector3(0, 1.78, -0.19), accent)
	_add_part(BoxMesh.new(), Vector3(0.48, 0.52, 0.24), Vector3(0, 1.18, 0.28), dark)
	for side in [-1.0, 1.0]:
		_add_part(CapsuleMesh.new(), Vector3(0.24, 0.62, 0.24), Vector3(side * 0.2, 0.43, 0), body_material)

	var marker := Label3D.new()
	marker.name = "BotHealthLabel"
	marker.text = "BOT 100"
	marker.position = Vector3(0, 2.25, 0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.font_size = 28
	marker.modulate = Color(1.0, 0.58, 0.28)
	add_child(marker)

func _add_part(mesh: PrimitiveMesh, dimensions: Vector3, pos: Vector3, material: Material) -> void:
	mesh.set("size", dimensions) if mesh is BoxMesh else null
	if mesh is CapsuleMesh:
		mesh.radius = dimensions.x * 0.5
		mesh.height = dimensions.y
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	part.material_override = material
	visual_root.add_child(part)

func _physics_process(delta: float) -> void:
	attack_timer = maxf(0.0, attack_timer - delta)
	if player == null or not is_instance_valid(player):
		var players := get_tree().get_nodes_in_group("warfox_player")
		if not players.is_empty():
			player = players[0]
			return
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED * delta)
		velocity.z = move_toward(velocity.z, 0.0, MOVE_SPEED * delta)
		_apply_gravity(delta)
		move_and_slide()
		return

	var offset := player.global_position - global_position
	var flat := Vector3(offset.x, 0.0, offset.z)
	if flat.length() < 24.0 and flat.length() > ATTACK_RANGE:
		var direction := flat.normalized()
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
		rotation.y = atan2(-direction.x, -direction.z)
	elif flat.length() <= ATTACK_RANGE:
		velocity.x = 0.0
		velocity.z = 0.0
		if attack_timer <= 0.0 and _can_see_player():
			if player.has_method("receive_damage"):
				player.receive_damage(HIT_DAMAGE)
			attack_timer = ATTACK_COOLDOWN
	else:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED * delta)
		velocity.z = move_toward(velocity.z, 0.0, MOVE_SPEED * delta)

	_apply_gravity(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

func _can_see_player() -> bool:
	var from := global_position + Vector3.UP * 1.1
	var to := player.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == player

func receive_hit(damage: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - damage)
	var label := get_node_or_null("BotHealthLabel") as Label3D
	if label != null:
		label.text = "BOT " + str(health)
	if health == 0:
		_defeat()

func _defeat() -> void:
	set_physics_process(false)
	visible = false
	collision_layer = 0
	collision_mask = 0
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if not is_inside_tree():
		return
	health = MAX_HEALTH
	global_position = spawn_position
	velocity = Vector3.ZERO
	visible = true
	collision_layer = 1
	collision_mask = 1
	var label := get_node_or_null("BotHealthLabel") as Label3D
	if label != null:
		label.text = "BOT 100"
	set_physics_process(true)
