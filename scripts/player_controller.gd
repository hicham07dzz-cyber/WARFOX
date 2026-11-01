extends CharacterBody3D
class_name WarfoxPlayer

const WALK_SPEED := 7.0
const SPRINT_SPEED := 11.0
const JUMP_VELOCITY := 6.5
const GRAVITY := 20.0

var move_input := Vector2.ZERO
var sprinting := false
var jump_requested := false
var camera_pivot: Node3D

func _ready() -> void:
	_build_visual()
	_build_camera()

func _build_visual() -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.48
	capsule.height = 1.9
	body.mesh = capsule
	body.position.y = 0.95
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.12, 0.16, 0.19)
	body_mat.metallic = 0.55
	body_mat.roughness = 0.38
	body.material_override = body_mat
	add_child(body)

	var chest := MeshInstance3D.new()
	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.72, 0.48, 0.42)
	chest.mesh = chest_mesh
	chest.position = Vector3(0, 1.18, -0.04)
	var orange := StandardMaterial3D.new()
	orange.albedo_color = Color(1.0, 0.28, 0.035)
	orange.metallic = 0.25
	chest.material_override = orange
	add_child(chest)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.27
	head_mesh.height = 0.54
	head.mesh = head_mesh
	head.position.y = 2.02
	head.material_override = body_mat
	add_child(head)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.55, 0)
	add_child(camera_pivot)
	var spring := SpringArm3D.new()
	spring.spring_length = 5.2
	spring.position.z = 0.0
	camera_pivot.add_child(spring)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0.35, 0)
	camera.rotation_degrees.x = -8.0
	camera.current = true
	spring.add_child(camera)

func set_mobile_input(direction: Vector2, sprint: bool, jump: bool) -> void:
	move_input = direction.limit_length(1.0)
	sprinting = sprint
	jump_requested = jump_requested or jump

func _physics_process(delta: float) -> void:
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_dir := move_input if move_input.length() > 0.08 else keyboard
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	var direction := (right * input_dir.x + forward * -input_dir.y).normalized()
	var speed := SPRINT_SPEED if sprinting or Input.is_action_pressed("sprint") else WALK_SPEED
	if direction.length() > 0.01:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 10.0, 1.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 5.0 * delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif jump_requested or Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	jump_requested = false
	move_and_slide()
