extends CharacterBody3D
class_name WarfoxPlayer

const WALK_SPEED := 6.5
const SPRINT_SPEED := 9.5
const CROUCH_SPEED := 3.2
const JUMP_VELOCITY := 6.2
const GRAVITY := 22.0
const ACCELERATION := 24.0
const DECELERATION := 30.0

var move_input := Vector2.ZERO
var sprinting := false
var crouching := false
var jump_requested := false
var fire_requested := false
var fire_cooldown := 0.0
const FIRE_INTERVAL := 0.22
const HIT_DAMAGE := 25
var camera_pivot: Node3D
var collision_capsule: CollisionShape3D
var visual_root: Node3D
var left_arm_pivot: Node3D
var right_arm_pivot: Node3D
var left_leg_pivot: Node3D
var right_leg_pivot: Node3D
var animation_clock := 0.0
var healing := false
var medkits := 3
var heal_time := 0.0
var parachute_deployed := false
var parachute_visual: Node3D
var medkit_visual: MeshInstance3D
var medkit_cross: MeshInstance3D
var standing_height := 1.85
var crouched_height := 1.15
const MAX_HEALTH := 100
var health := MAX_HEALTH
var spawn_position := Vector3.ZERO
var is_knocked_out := false
const LOOK_SENSITIVITY := 0.0035
const MIN_PITCH := deg_to_rad(-32.0)
const MAX_PITCH := deg_to_rad(24.0)

func _ready() -> void:
	floor_snap_length = 0.25
	floor_max_angle = deg_to_rad(48.0)
	_build_collision()
	_build_visual()
	_build_camera()
	spawn_position = global_position
	add_to_group("warfox_player")

func _build_collision() -> void:
	collision_capsule = CollisionShape3D.new()
	collision_capsule.name = "PlayerCapsule"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = standing_height
	collision_capsule.shape = capsule
	collision_capsule.position.y = standing_height * 0.5
	add_child(collision_capsule)

func _material(color: Color, metal: float = 0.0, rough: float = 0.72) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = rough
	return mat

func _add_box(parent: Node3D, label: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	part.material_override = mat
	parent.add_child(part)
	return part

func _add_capsule(parent: Node3D, label: String, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	part.mesh = mesh
	part.position = pos
	part.material_override = mat
	parent.add_child(part)
	return part

func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "TacticalSoldierModel"
	add_child(visual_root)

	var dark := _material(Color(0.055, 0.075, 0.085), 0.16)
	var armor := _material(Color(0.12, 0.19, 0.20), 0.18)
	var fabric := _material(Color(0.25, 0.29, 0.24))
	var accent := _material(Color(0.95, 0.29, 0.055), 0.2, 0.4)
	var skin := _material(Color(0.55, 0.38, 0.27))

	_add_box(visual_root, "Torso_Armor", Vector3(0.68, 0.68, 0.36), Vector3(0, 1.22, 0), armor)
	_add_box(visual_root, "Chest_Plate", Vector3(0.48, 0.30, 0.045), Vector3(0, 1.31, -0.205), dark)
	_add_box(visual_root, "Chest_Insignia", Vector3(0.18, 0.055, 0.025), Vector3(0, 1.38, -0.234), accent)
	_add_box(visual_root, "Belt", Vector3(0.66, 0.13, 0.37), Vector3(0, 0.84, 0), dark)
	_add_capsule(visual_root, "Head", 0.205, 0.43, Vector3(0, 1.79, 0), skin)
	_add_box(visual_root, "Helmet", Vector3(0.47, 0.16, 0.46), Vector3(0, 1.99, 0.015), dark)
	_add_box(visual_root, "Helmet_Visor", Vector3(0.32, 0.055, 0.025), Vector3(0, 1.91, -0.222), accent)
	_add_box(visual_root, "Backpack", Vector3(0.48, 0.55, 0.22), Vector3(0, 1.24, 0.27), dark)
	_add_box(visual_root, "Shoulder_Patch", Vector3(0.16, 0.12, 0.08), Vector3(-0.43, 1.43, 0), accent)

	left_arm_pivot = Node3D.new()
	left_arm_pivot.name = "LeftArm_Animated"
	left_arm_pivot.position = Vector3(-0.39, 1.48, 0)
	visual_root.add_child(left_arm_pivot)
	_add_capsule(left_arm_pivot, "UpperArm", 0.13, 0.48, Vector3(0, -0.20, 0), fabric)
	_add_capsule(left_arm_pivot, "Forearm_Guard", 0.115, 0.38, Vector3(0.02, -0.55, -0.015), armor)

	right_arm_pivot = Node3D.new()
	right_arm_pivot.name = "RightArm_Animated"
	right_arm_pivot.position = Vector3(0.39, 1.48, 0)
	visual_root.add_child(right_arm_pivot)
	_add_capsule(right_arm_pivot, "UpperArm", 0.13, 0.48, Vector3(0, -0.20, 0), fabric)
	_add_capsule(right_arm_pivot, "Forearm_Guard", 0.115, 0.38, Vector3(-0.02, -0.55, -0.015), armor)

	left_leg_pivot = Node3D.new()
	left_leg_pivot.name = "LeftLeg_Animated"
	left_leg_pivot.position = Vector3(-0.19, 0.82, 0)
	visual_root.add_child(left_leg_pivot)
	_add_capsule(left_leg_pivot, "Thigh", 0.17, 0.52, Vector3(0, -0.22, 0), fabric)
	_add_capsule(left_leg_pivot, "Boot_Leg", 0.135, 0.43, Vector3(0, -0.57, -0.035), dark)
	_add_box(left_leg_pivot, "Boot", Vector3(0.27, 0.13, 0.40), Vector3(0, -0.74, -0.09), dark)

	right_leg_pivot = Node3D.new()
	right_leg_pivot.name = "RightLeg_Animated"
	right_leg_pivot.position = Vector3(0.19, 0.82, 0)
	visual_root.add_child(right_leg_pivot)
	_add_capsule(right_leg_pivot, "Thigh", 0.17, 0.52, Vector3(0, -0.22, 0), fabric)
	_add_capsule(right_leg_pivot, "Boot_Leg", 0.135, 0.43, Vector3(0, -0.57, -0.035), dark)
	_add_box(right_leg_pivot, "Boot", Vector3(0.27, 0.13, 0.40), Vector3(0, -0.74, -0.09), dark)

	medkit_visual = _add_box(right_arm_pivot, "Medkit", Vector3(0.22, 0.18, 0.16), Vector3(0, -0.78, -0.12), _material(Color(0.82, 0.84, 0.78)))
	medkit_visual.visible = false
	medkit_cross = _add_box(right_arm_pivot, "Medkit_Cross", Vector3(0.045, 0.13, 0.018), Vector3(0, -0.78, -0.205), accent)
	medkit_cross.visible = false

	parachute_visual = Node3D.new()
	parachute_visual.name = "Parachute_Visual"
	parachute_visual.position = Vector3(0, 3.25, 0.12)
	parachute_visual.visible = false
	visual_root.add_child(parachute_visual)
	var canopy := MeshInstance3D.new()
	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = 1.0
	canopy_mesh.height = 0.8
	canopy_mesh.radial_segments = 24
	canopy_mesh.rings = 12
	canopy.mesh = canopy_mesh
	canopy.scale = Vector3(2.15, 0.52, 1.05)
	var canopy_mat := _material(Color(0.92, 0.27, 0.055), 0.08, 0.48)
	canopy.material_override = canopy_mat
	parachute_visual.add_child(canopy)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0, 1.55, 0)
	add_child(camera_pivot)

	var spring := SpringArm3D.new()
	spring.name = "CameraCollisionArm"
	spring.spring_length = 4.8
	spring.margin = 0.18
	camera_pivot.add_child(spring)

	var camera := Camera3D.new()
	camera.name = "ThirdPersonCamera"
	camera.position = Vector3(0, 0.25, 0)
	camera.rotation_degrees.x = 0.0
	camera.current = true
	spring.add_child(camera)

func start_healing() -> void:
	if healing or health >= MAX_HEALTH or is_knocked_out or medkits <= 0:
		return
	medkits -= 1
	healing = true
	heal_time = 3.0
	if medkit_visual != null:
		medkit_visual.visible = true
	if medkit_cross != null:
		medkit_cross.visible = true

func deploy_parachute() -> void:
	if is_on_floor() or parachute_deployed or is_knocked_out:
		return
	parachute_deployed = true
	parachute_visual.visible = true

func receive_damage(amount: int) -> void:
	if is_knocked_out or amount <= 0:
		return
	health = maxi(0, health - amount)
	if health == 0:
		is_knocked_out = true
		healing = false
		parachute_deployed = false
		if parachute_visual != null:
			parachute_visual.visible = false
		if medkit_visual != null:
			medkit_visual.visible = false
		if medkit_cross != null:
			medkit_cross.visible = false
		velocity = Vector3.ZERO
		await get_tree().create_timer(2.0).timeout
		if not is_inside_tree():
			return
		health = MAX_HEALTH
		global_position = spawn_position
		velocity = Vector3.ZERO
		is_knocked_out = false

func add_look_delta(delta_pixels: Vector2) -> void:
	camera_pivot.rotation.y -= delta_pixels.x * LOOK_SENSITIVITY
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - delta_pixels.y * LOOK_SENSITIVITY, MIN_PITCH, MAX_PITCH)

func set_mobile_input(direction: Vector2, sprint: bool, jump: bool, crouch: bool = false, fire: bool = false, heal: bool = false, parachute: bool = false) -> void:
	move_input = direction.limit_length(1.0)
	sprinting = sprint
	crouching = crouch
	jump_requested = jump_requested or jump
	fire_requested = fire_requested or fire
	if heal:
		start_healing()
	if parachute:
		deploy_parachute()

func _set_crouch_state() -> void:
	var wants_crouch := crouching or Input.is_action_pressed("crouch")
	var capsule := collision_capsule.shape as CapsuleShape3D
	var target_height := crouched_height if wants_crouch else standing_height
	if absf(capsule.height - target_height) > 0.01:
		capsule.height = move_toward(capsule.height, target_height, 0.12)
		collision_capsule.position.y = capsule.height * 0.5
		visual_root.scale.y = capsule.height / standing_height
		visual_root.position.y = 0.0


func _process(delta: float) -> void:
	animation_clock += delta
	_update_character_animation(delta)

func _update_character_animation(delta: float) -> void:
	if visual_root == null:
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := horizontal_speed > 0.35 and is_on_floor() and not healing
	var crouch_blend := 1.0 if crouching or Input.is_action_pressed("crouch") else 0.0
	var run_blend := clampf(horizontal_speed / SPRINT_SPEED, 0.0, 1.0) if moving else 0.0
	var stride := sin(animation_clock * (8.0 + horizontal_speed * 1.25)) * run_blend
	var idle_bob := sin(animation_clock * 2.2) * 0.018
	visual_root.position.y = idle_bob + (0.025 if moving else 0.0)
	left_leg_pivot.rotation.x = stride * 0.62 - crouch_blend * 0.38
	right_leg_pivot.rotation.x = -stride * 0.62 - crouch_blend * 0.38
	left_arm_pivot.rotation.x = -stride * 0.48 + crouch_blend * 0.48
	right_arm_pivot.rotation.x = stride * 0.48 + crouch_blend * 0.48
	if not is_on_floor() and not parachute_deployed:
		left_arm_pivot.rotation.x = -0.75
		right_arm_pivot.rotation.x = -0.75
		left_leg_pivot.rotation.x = 0.25
		right_leg_pivot.rotation.x = -0.25
	if healing:
		left_arm_pivot.rotation.x = -0.9
		right_arm_pivot.rotation.x = -1.25 + sin(animation_clock * 7.0) * 0.08
		if medkit_visual != null:
			medkit_visual.visible = true
		if medkit_cross != null:
			medkit_cross.visible = true
		heal_time -= delta
		if heal_time <= 0.0:
			healing = false
			health = mini(MAX_HEALTH, health + 50)
			if medkit_visual != null:
				medkit_visual.visible = false
			if medkit_cross != null:
				medkit_cross.visible = false
	if parachute_deployed:
		left_arm_pivot.rotation.z = -0.65
		right_arm_pivot.rotation.z = 0.65
		velocity.y = maxf(velocity.y, -3.2)
		if is_on_floor():
			parachute_deployed = false
			parachute_visual.visible = false
	else:
		left_arm_pivot.rotation.z = move_toward(left_arm_pivot.rotation.z, 0.0, delta * 5.0)
		right_arm_pivot.rotation.z = move_toward(right_arm_pivot.rotation.z, 0.0, delta * 5.0)

func _physics_process(delta: float) -> void:
	if is_knocked_out:
		return
	if Input.is_action_just_pressed("heal"):
		start_healing()
	if Input.is_action_just_pressed("parachute"):
		deploy_parachute()
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if fire_requested or Input.is_action_just_pressed("fire"):
		_fire_arcade_ray()
	fire_requested = false
	_set_crouch_state()
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_dir := move_input if move_input.length() > 0.08 else keyboard
	var forward := -camera_pivot.global_transform.basis.z
	var right := camera_pivot.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var direction := (right * input_dir.x + forward * -input_dir.y).normalized()

	var is_crouched := crouching or Input.is_action_pressed("crouch")
	var speed := CROUCH_SPEED if is_crouched else (SPRINT_SPEED if sprinting or Input.is_action_pressed("sprint") else WALK_SPEED)
	var target_x := direction.x * speed
	var target_z := direction.z * speed
	var rate := ACCELERATION if direction.length() > 0.01 else DECELERATION
	velocity.x = move_toward(velocity.x, target_x, rate * delta)
	velocity.z = move_toward(velocity.z, target_z, rate * delta)

	if direction.length() > 0.01:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 9.0, 1.0))

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif (jump_requested or Input.is_action_just_pressed("jump")) and not (crouching or Input.is_action_pressed("crouch")):
		velocity.y = JUMP_VELOCITY

	jump_requested = false
	move_and_slide()

func _fire_arcade_ray() -> void:
	if fire_cooldown > 0.0:
		return
	fire_cooldown = FIRE_INTERVAL
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var screen_center := viewport_size * 0.5
	var ray_origin := camera.project_ray_origin(screen_center)
	var ray_direction := camera.project_ray_normal(screen_center)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 180.0)
	query.exclude = [get_rid()]
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider = hit.get("collider")
	if collider != null and collider.has_method("receive_hit"):
		collider.receive_hit(HIT_DAMAGE)
