extends CharacterBody3D
class_name WarfoxBot

const MOVE_SPEED := 2.8
const GRAVITY := 22.0
const MAX_HEALTH := 100
const MIN_DAMAGE := 5
const MAX_DAMAGE := 10
const ATTACK_RANGE := 1.65
const SHOT_RANGE := 22.0
const ATTACK_COOLDOWN := 1.35

var health := MAX_HEALTH
var player: Node3D
var attack_timer := 0.0
var spawn_position := Vector3.ZERO
var visual_root: Node3D
var body_material: StandardMaterial3D
var shot_visual: MeshInstance3D
var shot_flash_time := 0.0

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

	shot_visual = MeshInstance3D.new()
	shot_visual.name = "Bot_Muzzle_Tracer"
	var tracer_mesh := BoxMesh.new()
	tracer_mesh.size = Vector3(0.045, 0.045, 1.0)
	shot_visual.mesh = tracer_mesh
	var tracer_material := StandardMaterial3D.new()
	tracer_material.albedo_color = Color(1.0, 0.46, 0.12)
	tracer_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tracer_material.emission_enabled = true
	tracer_material.emission = Color(1.0, 0.20, 0.035)
	tracer_material.emission_energy_multiplier = 3.0
	shot_visual.material_override = tracer_material
	shot_visual.visible = false
	add_child(shot_visual)

	var marker := Label3D.new()
	marker.name = "BotHealthLabel"
	marker.text = "BOT 100"
	marker.position = Vector3(0, 2.25, 0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.font_size = 28
	marker.modulate = Color(1.0, 0.58, 0.28)
	add_child(marker)

func _add_part(mesh: PrimitiveMesh, dimensions: Vector3, pos: Vector3, material: Material) -> void:
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = dimensions
	elif mesh is CapsuleMesh:
		(mesh as CapsuleMesh).radius = dimensions.x * 0.5
		(mesh as CapsuleMesh).height = dimensions.y
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	part.material_override = material
	visual_root.add_child(part)

func _process(delta: float) -> void:
	shot_flash_time = maxf(0.0, shot_flash_time - delta)
	if shot_visual != null:
		shot_visual.visible = shot_flash_time > 0.0

func _show_shot_tracer() -> void:
	if shot_visual == null or player == null:
		return
	var start := global_position + Vector3.UP * 1.35 + (-global_transform.basis.z * 0.45)
	var finish := player.global_position + Vector3.UP * 1.0
	var segment := finish - start
	shot_visual.global_position = start + segment * 0.5
	shot_visual.look_at(finish, Vector3.UP)
	shot_visual.scale = Vector3(1.0, 1.0, maxf(0.25, segment.length()))
	shot_flash_time = 0.09
	shot_visual.visible = true

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
	var distance := flat.length()
	if distance < SHOT_RANGE and distance > ATTACK_RANGE:
		velocity.x = 0.0
		velocity.z = 0.0
		if flat.length() > 0.01:
			rotation.y = atan2(-flat.normalized().x, -flat.normalized().z)
		if attack_timer <= 0.0 and _can_see_player():
			if player.has_method("receive_damage"):
				player.receive_damage(randi_range(MIN_DAMAGE, MAX_DAMAGE))
			_show_shot_tracer()
			attack_timer = ATTACK_COOLDOWN
	elif distance <= ATTACK_RANGE:
		velocity.x = 0.0
		velocity.z = 0.0
		if attack_timer <= 0.0 and _can_see_player():
			if player.has_method("receive_damage"):
				player.receive_damage(randi_range(MIN_DAMAGE, MAX_DAMAGE))
			attack_timer = ATTACK_COOLDOWN
	elif distance < 38.0:
		var direction := flat.normalized()
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
		rotation.y = atan2(-direction.x, -direction.z)
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

func receive_zone_damage(damage: int) -> void:
	if health <= 0 or damage <= 0:
		return
	health = maxi(0, health - damage)
	var label := get_node_or_null("BotHealthLabel") as Label3D
	if label != null:
		label.text = "BOT " + str(health)
	if health == 0:
		_defeat(false)


func _defeat(count_player_kill: bool = true) -> void:
	if count_player_kill:
		var players := get_tree().get_nodes_in_group("warfox_player")
		if not players.is_empty() and players[0].has_method("register_kill"):
			players[0].register_kill()
	_drop_loot()
	queue_free()


func _drop_loot() -> void:
	var loot_script = load("res://scripts/loot_pickup.gd")
	if loot_script == null:
		return
	var pickup := Area3D.new()
	pickup.set_script(loot_script)
	if randf() < 0.72:
		pickup.pickup_type = "ammo"
		pickup.amount = 45
	else:
		pickup.pickup_type = "medkit"
		pickup.amount = 1
	pickup.position = Vector3(global_position.x, global_position.y + 0.8, global_position.z)
	get_parent().add_child(pickup)
