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
var camera_pivot: Node3D
var collision_capsule: CollisionShape3D
var visual_root: Node3D
var standing_height := 1.85
var crouched_height := 1.15

func _ready() -> void:
	floor_snap_length = 0.25
	floor_max_angle = deg_to_rad(48.0)
	_build_collision()
	_build_visual()
	_build_camera()

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

	var dark := _material(Color(0.075, 0.105, 0.12), 0.12)
	var armor := _material(Color(0.16, 0.21, 0.20), 0.08)
	var fabric := _material(Color(0.27, 0.29, 0.23))
	var accent := _material(Color(0.88, 0.25, 0.055), 0.18, 0.42)
	var skin := _material(Color(0.55, 0.38, 0.27))

	_add_box(visual_root, "Torso_Armor", Vector3(0.68, 0.68, 0.36), Vector3(0, 1.22, 0), armor)
	_add_box(visual_root, "Chest_Plate", Vector3(0.48, 0.30, 0.045), Vector3(0, 1.31, -0.205), dark)
	_add_box(visual_root, "Chest_Insignia", Vector3(0.18, 0.055, 0.025), Vector3(0, 1.38, -0.234), accent)
	_add_box(visual_root, "Belt", Vector3(0.66, 0.13, 0.37), Vector3(0, 0.84, 0), dark)

	_add_capsule(visual_root, "Head", 0.205, 0.43, Vector3(0, 1.79, 0), skin)
	_add_box(visual_root, "Helmet", Vector3(0.47, 0.16, 0.46), Vector3(0, 1.99, 0.015), dark)
	_add_box(visual_root, "Helmet_Visor", Vector3(0.32, 0.055, 0.025), Vector3(0, 1.91, -0.222), accent)

	for side in [-1.0, 1.0]:
		_add_capsule(visual_root, "UpperArm", 0.13, 0.48, Vector3(side * 0.43, 1.27, 0), fabric)
		_add_capsule(visual_root, "Forearm_Guard", 0.115, 0.38, Vector3(side * 0.45, 0.91, -0.015), armor)
		_add_capsule(visual_root, "Thigh", 0.17, 0.52, Vector3(side * 0.19, 0.56, 0), fabric)
		_add_capsule(visual_root, "Boot_Leg", 0.135, 0.43, Vector3(side * 0.19, 0.22, -0.035), dark)
		_add_box(visual_root, "Boot", Vector3(0.27, 0.13, 0.40), Vector3(side * 0.19, 0.075, -0.09), dark)

	_add_box(visual_root, "Backpack", Vector3(0.48, 0.55, 0.22), Vector3(0, 1.24, 0.27), dark)
	_add_box(visual_root, "Shoulder_Patch", Vector3(0.16, 0.12, 0.08), Vector3(-0.43, 1.43, 0), accent)

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
	camera.rotation_degrees.x = -7.0
	camera.current = true
	spring.add_child(camera)

func set_mobile_input(direction: Vector2, sprint: bool, jump: bool, crouch: bool = false) -> void:
	move_input = direction.limit_length(1.0)
	sprinting = sprint
	crouching = crouch
	jump_requested = jump_requested or jump

func _set_crouch_state() -> void:
	var wants_crouch := crouching or Input.is_action_pressed("crouch")
	var capsule := collision_capsule.shape as CapsuleShape3D
	var target_height := crouched_height if wants_crouch else standing_height
	if absf(capsule.height - target_height) > 0.01:
		capsule.height = move_toward(capsule.height, target_height, 0.12)
		collision_capsule.position.y = capsule.height * 0.5
		visual_root.scale.y = capsule.height / standing_height
		visual_root.position.y = 0.0

func _physics_process(delta: float) -> void:
	_set_crouch_state()
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_dir := move_input if move_input.length() > 0.08 else keyboard
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
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
