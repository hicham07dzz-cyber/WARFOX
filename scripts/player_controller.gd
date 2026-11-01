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
var reload_requested := false
var fire_cooldown := 0.0
const MAGAZINE_SIZE := 30
var ammo := MAGAZINE_SIZE
var reserve_ammo := 120
var is_reloading := false
var reload_time := 0.0
var weapon_root: Node3D
var magazine_visual: MeshInstance3D
var magazine_stripe: MeshInstance3D
var muzzle_flash: MeshInstance3D
var muzzle_light: OmniLight3D
var muzzle_flash_time := 0.0
var reload_animation_time := 0.0
var fox_spirit: Node3D
var black_fox_skin: Node3D
var black_fox_coat_left: Node3D
var black_fox_coat_right: Node3D
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
var fire_animation_time := 0.0
var damage_animation_time := 0.0
var healing := false
var medkits := 3
var heal_time := 0.0
var parachute_deployed := false
var landing_roll_time := 0.0
var parachute_visual: Node3D
var medkit_visual: MeshInstance3D
var medkit_cross: MeshInstance3D
var standing_height := 1.85
var crouched_height := 1.15
const MAX_HEALTH := 200
var health := MAX_HEALTH
var kills := 0
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
	_build_weapon()
	_build_fox_spirit()
	_build_camera()
	spawn_position = global_position
	add_to_group("warfox_player")
	var account := get_parent().get_node_or_null("WARFOX_Account")
	if account != null:
		apply_equipped_loadout(account)

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

func apply_equipped_loadout(account: Node) -> void:
	var skin_name := str(account.get("equipped_skin"))
	var weapon_name := str(account.get("equipped_weapon"))
	_apply_skin_palette(skin_name)
	_apply_weapon_palette(weapon_name)

func _apply_skin_palette(skin_name: String) -> void:
	var armor_color := Color(0.12, 0.19, 0.20)
	var fabric_color := Color(0.25, 0.29, 0.24)
	var accent_color := Color(0.95, 0.29, 0.055)
	var helmet_color := Color(0.055, 0.075, 0.085)
	match skin_name:
		"BLACK FOX RED", "BLACK FOX BLUE", "BLACK FOX GOLD", "BLACK FOX PURPLE", "BLACK FOX":
			armor_color = Color(0.025, 0.018, 0.028)
			fabric_color = Color(0.045, 0.035, 0.052)
			accent_color = Color(1.0, 0.018, 0.035)
			helmet_color = Color(0.012, 0.012, 0.022)
		"SHADOW RECON":
			armor_color = Color(0.055, 0.065, 0.085)
			fabric_color = Color(0.12, 0.14, 0.18)
			accent_color = Color(0.20, 0.62, 0.92)
			helmet_color = Color(0.025, 0.035, 0.055)
		"DESERT PHANTOM":
			armor_color = Color(0.43, 0.32, 0.19)
			fabric_color = Color(0.57, 0.45, 0.28)
			accent_color = Color(0.95, 0.68, 0.22)
			helmet_color = Color(0.24, 0.18, 0.12)
		"ARCTIC WOLF":
			armor_color = Color(0.48, 0.60, 0.68)
			fabric_color = Color(0.70, 0.77, 0.80)
			accent_color = Color(0.22, 0.82, 1.0)
			helmet_color = Color(0.15, 0.23, 0.29)
		"EMBER GUARD":
			armor_color = Color(0.25, 0.07, 0.055)
			fabric_color = Color(0.19, 0.12, 0.11)
			accent_color = Color(1.0, 0.30, 0.045)
			helmet_color = Color(0.075, 0.035, 0.03)
		"NEON HUNTER":
			armor_color = Color(0.08, 0.12, 0.18)
			fabric_color = Color(0.11, 0.16, 0.22)
			accent_color = Color(0.12, 1.0, 0.72)
			helmet_color = Color(0.025, 0.06, 0.09)
	if black_fox_skin != null:
		black_fox_skin.visible = skin_name.begins_with("BLACK FOX")
		_apply_black_fox_variant(skin_name)
	if fox_spirit != null:
		fox_spirit.visible = skin_name.begins_with("BLACK FOX") and fox_spirit.get_meta("spirit_active", false)
	var armor_mat := _material(armor_color, 0.32, 0.48)
	var fabric_mat := _material(fabric_color, 0.05, 0.78)
	var accent_mat := _material(accent_color, 0.24, 0.4)
	var helmet_mat := _material(helmet_color, 0.28, 0.42)
	var dark_mat := _material(Color(0.035, 0.045, 0.052), 0.28, 0.58)
	for node in visual_root.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if part.name in ["Torso_Armor", "Chest_Plate"]:
			part.material_override = armor_mat if part.name == "Torso_Armor" else helmet_mat
		elif part.name in ["UpperArm", "Thigh"]:
			part.material_override = fabric_mat
		elif part.name in ["Forearm_Guard", "Boot_Leg", "Boot", "Belt", "Backpack", "Helmet", "Left_Shoulder_Pad", "Right_Shoulder_Pad", "Knee_Guard_Left", "Knee_Guard_Right", "Backpack_Flap", "Helmet_Side_Left", "Helmet_Side_Right"]:
			part.material_override = helmet_mat
		elif part.name in ["Chest_Insignia", "Helmet_Visor", "Shoulder_Patch", "Radio_Antenna", "Helmet_Rear_Ridge", "Shoulder_Trim_Left", "Shoulder_Trim_Right", "Chest_Center_Buckle", "Knee_Stripe_Left", "Knee_Stripe_Right"]:
			part.material_override = accent_mat
		elif part.name in ["Chest_Pouch_Left", "Chest_Pouch_Right", "Chest_Radio", "Helmet_Comms_Left", "Helmet_Comms_Right", "Helmet_Front_Brim", "Chest_Lower_Armor", "Waist_Utility_Belt", "Elbow_Guard_Left", "Elbow_Guard_Right"]:
			part.material_override = dark_mat
		elif part.name in ["Belt_Pouch_Left", "Belt_Pouch_Right", "Neck_Gaiter", "Backpack_Side_Left", "Backpack_Side_Right", "Chest_Straps_Left", "Chest_Straps_Right", "Thigh_Plate_Left", "Thigh_Plate_Right"]:
			part.material_override = fabric_mat

func _apply_weapon_palette(weapon_name: String) -> void:
	var base_color := Color(0.035, 0.045, 0.052)
	var metal_color := Color(0.16, 0.19, 0.20)
	var accent_color := Color(0.92, 0.12, 0.045)
	match weapon_name:
		"STRIKER SMG":
			base_color = Color(0.07, 0.10, 0.12)
			metal_color = Color(0.25, 0.34, 0.38)
			accent_color = Color(0.10, 0.82, 0.95)
		"FALCON DMR":
			base_color = Color(0.18, 0.16, 0.12)
			metal_color = Color(0.48, 0.40, 0.26)
			accent_color = Color(0.95, 0.72, 0.20)
		"BREACH SHOTGUN":
			base_color = Color(0.12, 0.065, 0.045)
			metal_color = Color(0.34, 0.22, 0.14)
			accent_color = Color(1.0, 0.36, 0.08)
		"VANGUARD SNIPER":
			base_color = Color(0.055, 0.10, 0.075)
			metal_color = Color(0.25, 0.38, 0.29)
			accent_color = Color(0.58, 1.0, 0.38)
		"TACTICAL PISTOL":
			base_color = Color(0.045, 0.05, 0.065)
			metal_color = Color(0.28, 0.30, 0.36)
			accent_color = Color(0.76, 0.35, 1.0)
	var dark_mat := _material(base_color, 0.52, 0.34)
	var metal_mat := _material(metal_color, 0.72, 0.28)
	var accent_mat := _material(accent_color, 0.28, 0.36)
	if weapon_root == null:
		return
	for node in weapon_root.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if part.name in ["Rifle_Receiver", "Rifle_Barrel"]:
			part.material_override = metal_mat
		elif part.name in ["Rifle_Handguard", "Rifle_Stock", "Rifle_Grip", "Rifle_Sight", "Detachable_Magazine"]:
			part.material_override = dark_mat
		elif part.name in ["Rifle_Sight_Glow", "Magazine_Red_Stripe"]:
			part.material_override = accent_mat

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
	_add_box(visual_root, "Left_Shoulder_Pad", Vector3(0.28, 0.19, 0.34), Vector3(-0.43, 1.49, 0.015), armor)
	_add_box(visual_root, "Right_Shoulder_Pad", Vector3(0.28, 0.19, 0.34), Vector3(0.43, 1.49, 0.015), armor)
	_add_box(visual_root, "Chest_Pouch_Left", Vector3(0.19, 0.17, 0.12), Vector3(-0.20, 1.08, -0.235), dark)
	_add_box(visual_root, "Chest_Pouch_Right", Vector3(0.19, 0.17, 0.12), Vector3(0.20, 1.08, -0.235), dark)
	_add_box(visual_root, "Chest_Radio", Vector3(0.12, 0.22, 0.09), Vector3(0.29, 1.43, 0.20), dark)
	_add_box(visual_root, "Radio_Antenna", Vector3(0.025, 0.20, 0.025), Vector3(0.31, 1.61, 0.20), accent)
	_add_box(visual_root, "Belt_Pouch_Left", Vector3(0.17, 0.20, 0.17), Vector3(-0.29, 0.84, -0.015), fabric)
	_add_box(visual_root, "Belt_Pouch_Right", Vector3(0.17, 0.20, 0.17), Vector3(0.29, 0.84, -0.015), fabric)
	_add_box(visual_root, "Knee_Guard_Left", Vector3(0.25, 0.20, 0.12), Vector3(-0.19, 0.39, -0.145), armor)
	_add_box(visual_root, "Knee_Guard_Right", Vector3(0.25, 0.20, 0.12), Vector3(0.19, 0.39, -0.145), armor)
	_add_box(visual_root, "Backpack_Flap", Vector3(0.36, 0.18, 0.045), Vector3(0, 1.48, 0.39), armor)
	_add_box(visual_root, "Helmet_Side_Left", Vector3(0.10, 0.16, 0.20), Vector3(-0.25, 1.91, 0.015), armor)
	_add_box(visual_root, "Helmet_Side_Right", Vector3(0.10, 0.16, 0.20), Vector3(0.25, 1.91, 0.015), armor)
	_add_box(visual_root, "Helmet_Rear_Ridge", Vector3(0.32, 0.07, 0.10), Vector3(0, 2.075, 0.12), accent)

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

	# Extra silhouette and material details for a more finished operator model.
	var trim := _material(Color(0.055, 0.075, 0.082), 0.38, 0.42)
	var rubber := _material(Color(0.018, 0.024, 0.028), 0.04, 0.9)
	var fabric_detail := _material(Color(0.18, 0.22, 0.20), 0.02, 0.86)
	var lens := StandardMaterial3D.new()
	lens.albedo_color = Color(0.08, 0.62, 0.76)
	lens.metallic = 0.25
	lens.roughness = 0.22
	lens.emission_enabled = true
	lens.emission = Color(0.015, 0.18, 0.24)
	lens.emission_energy_multiplier = 0.65

	_add_capsule(visual_root, "Neck_Gaiter", 0.14, 0.20, Vector3(0, 1.58, 0), fabric_detail)
	_add_box(visual_root, "Chest_Lower_Armor", Vector3(0.42, 0.12, 0.055), Vector3(0, 1.13, -0.22), trim)
	_add_box(visual_root, "Chest_Center_Buckle", Vector3(0.10, 0.10, 0.035), Vector3(0, 0.91, -0.205), accent)
	_add_box(visual_root, "Waist_Utility_Belt", Vector3(0.70, 0.075, 0.39), Vector3(0, 0.78, 0), trim)
	_add_box(visual_root, "Backpack_Side_Left", Vector3(0.13, 0.38, 0.15), Vector3(-0.29, 1.22, 0.28), fabric_detail)
	_add_box(visual_root, "Backpack_Side_Right", Vector3(0.13, 0.38, 0.15), Vector3(0.29, 1.22, 0.28), fabric_detail)
	_add_box(visual_root, "Helmet_Front_Brim", Vector3(0.42, 0.045, 0.16), Vector3(0, 1.93, -0.20), trim)
	_add_box(visual_root, "Helmet_Visor_Lens", Vector3(0.25, 0.035, 0.018), Vector3(0, 1.91, -0.242), lens)
	_add_box(visual_root, "Helmet_Comms_Left", Vector3(0.09, 0.13, 0.13), Vector3(-0.27, 1.88, 0.035), trim)
	_add_box(visual_root, "Helmet_Comms_Right", Vector3(0.09, 0.13, 0.13), Vector3(0.27, 1.88, 0.035), trim)
	_add_box(visual_root, "Shoulder_Trim_Left", Vector3(0.25, 0.045, 0.29), Vector3(-0.43, 1.58, -0.015), accent)
	_add_box(visual_root, "Shoulder_Trim_Right", Vector3(0.25, 0.045, 0.29), Vector3(0.43, 1.58, -0.015), accent)
	_add_box(visual_root, "Chest_Straps_Left", Vector3(0.055, 0.32, 0.035), Vector3(-0.12, 1.25, -0.238), fabric_detail)
	_add_box(visual_root, "Chest_Straps_Right", Vector3(0.055, 0.32, 0.035), Vector3(0.12, 1.25, -0.238), fabric_detail)
	_add_box(visual_root, "Thigh_Plate_Left", Vector3(0.24, 0.20, 0.10), Vector3(-0.19, 0.61, -0.12), armor)
	_add_box(visual_root, "Thigh_Plate_Right", Vector3(0.24, 0.20, 0.10), Vector3(0.19, 0.61, -0.12), armor)
	_add_box(visual_root, "Boot_Toe_Left", Vector3(0.28, 0.11, 0.16), Vector3(-0.19, 0.075, -0.25), rubber)
	_add_box(visual_root, "Boot_Toe_Right", Vector3(0.28, 0.11, 0.16), Vector3(0.19, 0.075, -0.25), rubber)
	_add_box(visual_root, "Boot_Sole_Left", Vector3(0.29, 0.045, 0.42), Vector3(-0.19, 0.025, -0.07), trim)
	_add_box(visual_root, "Boot_Sole_Right", Vector3(0.29, 0.045, 0.42), Vector3(0.19, 0.025, -0.07), trim)
	_add_box(left_arm_pivot, "Elbow_Guard_Left", Vector3(0.20, 0.15, 0.16), Vector3(0, -0.40, -0.01), trim)
	_add_box(right_arm_pivot, "Elbow_Guard_Right", Vector3(0.20, 0.15, 0.16), Vector3(0, -0.40, -0.01), trim)
	_add_box(left_arm_pivot, "Glove_Left", Vector3(0.19, 0.16, 0.17), Vector3(0.015, -0.76, -0.02), rubber)
	_add_box(right_arm_pivot, "Glove_Right", Vector3(0.19, 0.16, 0.17), Vector3(-0.015, -0.76, -0.02), rubber)
	_add_box(visual_root, "Knee_Stripe_Left", Vector3(0.17, 0.035, 0.025), Vector3(-0.19, 0.40, -0.211), accent)
	_add_box(visual_root, "Knee_Stripe_Right", Vector3(0.17, 0.035, 0.025), Vector3(0.19, 0.40, -0.211), accent)

	_build_black_fox_skin()

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
	canopy_mesh.is_hemisphere = true
	canopy_mesh.radial_segments = 24
	canopy_mesh.rings = 12
	canopy.mesh = canopy_mesh
	canopy.scale = Vector3(2.15, 0.52, 1.05)
	var canopy_mat := _material(Color(0.92, 0.27, 0.055), 0.08, 0.48)
	canopy.material_override = canopy_mat
	parachute_visual.add_child(canopy)



func _apply_black_fox_variant(skin_name: String) -> void:
	var glow := Color(1.0, 0.015, 0.025)
	match skin_name:
		"BLACK FOX BLUE":
			glow = Color(0.025, 0.30, 1.0)
		"BLACK FOX GOLD":
			glow = Color(1.0, 0.42, 0.015)
		"BLACK FOX PURPLE":
			glow = Color(0.62, 0.04, 1.0)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = glow
	glow_mat.metallic = 0.22
	glow_mat.roughness = 0.3
	glow_mat.emission_enabled = true
	glow_mat.emission = glow
	glow_mat.emission_energy_multiplier = 2.4
	for node in black_fox_skin.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if part.name.contains("Eye") or part.name.contains("Line") or part.name.contains("Edge") or part.name.contains("Crest") or part.name.contains("Piping") or part.name.contains("Emblem") or part.name.contains("Trim") or part.name.contains("Seam"):
			part.material_override = glow_mat

func _build_black_fox_skin() -> void:
	black_fox_skin = Node3D.new()
	black_fox_skin.name = "BLACK_FOX_EXCLUSIVE_DETAILS"
	black_fox_skin.visible = true
	visual_root.add_child(black_fox_skin)
	var black := _material(Color(0.012, 0.014, 0.022), 0.42, 0.34)
	var cloth := _material(Color(0.035, 0.022, 0.032), 0.12, 0.82)
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(1.0, 0.012, 0.025)
	red.metallic = 0.24
	red.roughness = 0.28
	red.emission_enabled = true
	red.emission = Color(0.9, 0.006, 0.015)
	red.emission_energy_multiplier = 2.2
	var white_red := StandardMaterial3D.new()
	white_red.albedo_color = Color(1.0, 0.12, 0.12)
	white_red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white_red.emission_enabled = true
	white_red.emission = Color(1.0, 0.015, 0.025)
	white_red.emission_energy_multiplier = 3.0

	# Mask and sharp fox-inspired helmet silhouette.
	_add_box(black_fox_skin, "BlackFox_Face_Mask", Vector3(0.34, 0.16, 0.075), Vector3(0, 1.76, -0.205), black)
	_add_box(black_fox_skin, "BlackFox_Mask_Red_Line", Vector3(0.29, 0.018, 0.012), Vector3(0, 1.78, -0.248), red)
	_add_box(black_fox_skin, "BlackFox_Eye_Left", Vector3(0.075, 0.018, 0.014), Vector3(-0.085, 1.86, -0.239), white_red)
	_add_box(black_fox_skin, "BlackFox_Eye_Right", Vector3(0.075, 0.018, 0.014), Vector3(0.085, 1.86, -0.239), white_red)
	_add_box(black_fox_skin, "BlackFox_Hood_Crown", Vector3(0.52, 0.12, 0.48), Vector3(0, 2.075, 0.015), black)
	_add_box(black_fox_skin, "BlackFox_Hood_Red_Seam", Vector3(0.025, 0.19, 0.035), Vector3(0, 2.14, -0.18), red)

	# Long split coat tails, inspired by the reference silhouette.
	black_fox_coat_left = Node3D.new()
	black_fox_coat_left.name = "BLACK_FOX_COAT_LEFT_RIG"
	black_fox_coat_left.position = Vector3(-0.34, 0.99, 0.12)
	black_fox_coat_left.rotation.z = -0.18
	black_fox_skin.add_child(black_fox_coat_left)
	_add_box(black_fox_coat_left, "BlackFox_Coat_Tail_Left", Vector3(0.34, 0.88, 0.10), Vector3(0, -0.44, 0), cloth)
	black_fox_coat_right = Node3D.new()
	black_fox_coat_right.name = "BLACK_FOX_COAT_RIGHT_RIG"
	black_fox_coat_right.position = Vector3(0.34, 0.99, 0.12)
	black_fox_coat_right.rotation.z = 0.20
	black_fox_skin.add_child(black_fox_coat_right)
	_add_box(black_fox_coat_right, "BlackFox_Coat_Tail_Right", Vector3(0.34, 0.92, 0.10), Vector3(0, -0.46, 0), cloth)
	_add_box(black_fox_skin, "BlackFox_Coat_Edge_Left", Vector3(0.035, 0.86, 0.025), Vector3(-0.49, 0.55, 0.055), red).rotation.z = -0.18
	_add_box(black_fox_skin, "BlackFox_Coat_Edge_Right", Vector3(0.035, 0.90, 0.025), Vector3(0.49, 0.53, 0.055), red).rotation.z = 0.20
	_add_box(black_fox_skin, "BlackFox_Coat_Belt", Vector3(0.72, 0.075, 0.045), Vector3(0, 0.88, -0.225), red)

	# Glowing fox crest and red armor piping.
	_add_box(black_fox_skin, "BlackFox_Chest_Crest", Vector3(0.20, 0.15, 0.025), Vector3(0, 1.43, -0.235), red)
	_add_box(black_fox_skin, "BlackFox_Chest_Piping_Left", Vector3(0.025, 0.42, 0.025), Vector3(-0.25, 1.27, -0.23), red).rotation.z = -0.18
	_add_box(black_fox_skin, "BlackFox_Chest_Piping_Right", Vector3(0.025, 0.42, 0.025), Vector3(0.25, 1.27, -0.23), red).rotation.z = 0.18
	_add_box(black_fox_skin, "BlackFox_Thigh_Emblem", Vector3(0.16, 0.12, 0.025), Vector3(0.19, 0.62, -0.19), red)
	_add_box(black_fox_skin, "BlackFox_Glove_Left_Trim", Vector3(0.20, 0.025, 0.19), Vector3(-0.40, 0.78, -0.04), red)
	_add_box(black_fox_skin, "BlackFox_Glove_Right_Trim", Vector3(0.20, 0.025, 0.19), Vector3(0.40, 0.78, -0.04), red)
	_add_box(black_fox_skin, "BlackFox_Boot_Left_Glow", Vector3(0.28, 0.035, 0.40), Vector3(-0.19, 0.12, -0.07), red)
	_add_box(black_fox_skin, "BlackFox_Boot_Right_Glow", Vector3(0.28, 0.035, 0.40), Vector3(0.19, 0.12, -0.07), red)

func _build_weapon() -> void:
	weapon_root = Node3D.new()
	weapon_root.name = "WARFOX_Assault_Rifle"
	weapon_root.position = Vector3(0.02, -0.52, -0.22)
	right_arm_pivot.add_child(weapon_root)
	var gun_dark := _material(Color(0.035, 0.045, 0.052), 0.55, 0.34)
	var gun_metal := _material(Color(0.16, 0.19, 0.20), 0.72, 0.28)
	var red := _material(Color(0.92, 0.12, 0.045), 0.28, 0.36)
	_add_box(weapon_root, "Rifle_Receiver", Vector3(0.16, 0.18, 0.62), Vector3(0, 0, -0.08), gun_metal)
	_add_box(weapon_root, "Rifle_Handguard", Vector3(0.13, 0.14, 0.40), Vector3(0, 0.015, -0.52), gun_dark)
	_add_box(weapon_root, "Rifle_Stock", Vector3(0.13, 0.16, 0.32), Vector3(0, 0.015, 0.38), gun_dark)
	_add_box(weapon_root, "Rifle_Grip", Vector3(0.10, 0.23, 0.12), Vector3(0, -0.18, 0.08), gun_dark)
	_add_box(weapon_root, "Rifle_Sight", Vector3(0.11, 0.09, 0.16), Vector3(0, 0.13, -0.05), gun_dark)
	_add_box(weapon_root, "Rifle_Sight_Glow", Vector3(0.035, 0.025, 0.035), Vector3(0, 0.19, -0.05), red)
	var barrel := MeshInstance3D.new()
	barrel.name = "Rifle_Barrel"
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.035
	barrel_mesh.bottom_radius = 0.035
	barrel_mesh.height = 0.58
	barrel.mesh = barrel_mesh
	barrel.rotation.x = PI * 0.5
	barrel.position = Vector3(0, 0.015, -0.91)
	barrel.material_override = gun_metal
	weapon_root.add_child(barrel)
	magazine_visual = _add_box(weapon_root, "Detachable_Magazine", Vector3(0.11, 0.25, 0.15), Vector3(0, -0.20, -0.03), gun_dark)
	magazine_stripe = _add_box(weapon_root, "Magazine_Red_Stripe", Vector3(0.115, 0.035, 0.16), Vector3(0, -0.19, -0.03), red)
	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.name = "Muzzle_Flash"
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.11
	flash_mesh.height = 0.22
	muzzle_flash.mesh = flash_mesh
	muzzle_flash.position = Vector3(0, 0.015, -1.24)
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.48, 0.08)
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.22, 0.025)
	flash_mat.emission_energy_multiplier = 5.0
	muzzle_flash.material_override = flash_mat
	muzzle_flash.visible = false
	weapon_root.add_child(muzzle_flash)
	muzzle_light = OmniLight3D.new()
	muzzle_light.name = "Muzzle_Flash_Light"
	muzzle_light.position = muzzle_flash.position
	muzzle_light.light_color = Color(1.0, 0.34, 0.08)
	muzzle_light.light_energy = 0.0
	muzzle_light.omni_range = 5.0
	weapon_root.add_child(muzzle_light)

func _build_fox_spirit() -> void:
	fox_spirit = Node3D.new()
	fox_spirit.name = "Shoulder_Fox_Spirit"
	fox_spirit.position = Vector3(-0.50, 1.66, -0.02)
	fox_spirit.visible = false
	visual_root.add_child(fox_spirit)
	var spirit_mat := StandardMaterial3D.new()
	spirit_mat.albedo_color = Color(1.0, 0.12, 0.025, 0.78)
	spirit_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spirit_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spirit_mat.emission_enabled = true
	spirit_mat.emission = Color(1.0, 0.055, 0.008)
	spirit_mat.emission_energy_multiplier = 2.4
	var body := _add_capsule(fox_spirit, "Spirit_Body", 0.105, 0.42, Vector3(0, 0, 0), spirit_mat)
	body.rotation.z = PI * 0.5
	var head := MeshInstance3D.new()
	head.name = "Spirit_Fox_Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.13
	head_mesh.height = 0.24
	head.mesh = head_mesh
	head.position = Vector3(0, 0.045, -0.23)
	head.material_override = spirit_mat
	fox_spirit.add_child(head)
	for side in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		var ear_mesh := CylinderMesh.new()
		ear_mesh.bottom_radius = 0.055
		ear_mesh.top_radius = 0.0
		ear_mesh.height = 0.17
		ear.mesh = ear_mesh
		ear.position = Vector3(side * 0.075, 0.17, -0.25)
		ear.material_override = spirit_mat
		fox_spirit.add_child(ear)
	var tail := _add_capsule(fox_spirit, "Spirit_Tail", 0.075, 0.42, Vector3(0, 0.10, 0.28), spirit_mat)
	tail.rotation.x = -0.9
	tail.rotation.z = 0.55

func start_reload() -> void:
	if is_reloading or is_knocked_out or ammo >= MAGAZINE_SIZE or reserve_ammo <= 0:
		return
	is_reloading = true
	reload_time = 1.75
	reload_animation_time = 1.75
	if magazine_visual != null:
		magazine_visual.visible = false
	if magazine_stripe != null:
		magazine_stripe.visible = false

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
	if is_on_floor() or velocity.y >= 0.0 or parachute_deployed or is_knocked_out:
		return
	parachute_deployed = true
	parachute_visual.visible = true

func receive_damage(amount: int) -> void:
	if is_knocked_out or amount <= 0:
		return
	health = maxi(0, health - amount)
	damage_animation_time = 0.22
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

func set_mobile_input(direction: Vector2, sprint: bool, jump: bool, crouch: bool = false, fire: bool = false, heal: bool = false, parachute: bool = false, reload: bool = false) -> void:
	move_input = direction.limit_length(1.0)
	sprinting = sprint
	crouching = crouch
	jump_requested = jump_requested or jump
	fire_requested = fire_requested or fire
	if heal:
		start_healing()
	if parachute:
		deploy_parachute()
	if reload:
		start_reload()

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
	fire_animation_time = maxf(0.0, fire_animation_time - delta)
	reload_animation_time = maxf(0.0, reload_animation_time - delta)
	muzzle_flash_time = maxf(0.0, muzzle_flash_time - delta)
	if muzzle_flash != null:
		muzzle_flash.visible = muzzle_flash_time > 0.0
	if muzzle_light != null:
		muzzle_light.light_energy = 2.8 if muzzle_flash_time > 0.0 else 0.0
	if black_fox_coat_left != null and black_fox_skin != null and black_fox_skin.visible:
		var coat_sway := sin(animation_clock * 5.0) * 0.10
		var speed_factor := clampf(Vector2(velocity.x, velocity.z).length() / SPRINT_SPEED, 0.0, 1.0)
		black_fox_coat_left.rotation.x = lerpf(black_fox_coat_left.rotation.x, -0.10 - coat_sway - speed_factor * 0.24, delta * 5.0)
		black_fox_coat_right.rotation.x = lerpf(black_fox_coat_right.rotation.x, -0.10 + coat_sway - speed_factor * 0.24, delta * 5.0)
		black_fox_coat_left.rotation.z = lerpf(black_fox_coat_left.rotation.z, -0.18 - coat_sway * 0.55, delta * 4.0)
		black_fox_coat_right.rotation.z = lerpf(black_fox_coat_right.rotation.z, 0.20 + coat_sway * 0.55, delta * 4.0)
	if fox_spirit != null:
		var fox_cycle := fposmod(animation_clock, 10.0)
		var fox_skin_equipped := black_fox_skin != null and black_fox_skin.visible
		fox_spirit.visible = fox_skin_equipped and fox_cycle > 5.8 and fox_cycle < 8.5
		var fox_fade := minf((fox_cycle - 5.8) / 0.35, (8.5 - fox_cycle) / 0.35)
		fox_spirit.scale = Vector3.ONE * (0.78 + 0.22 * sin(animation_clock * 8.0)) * clampf(fox_fade, 0.0, 1.0)
		fox_spirit.position.y = 1.66 + sin(animation_clock * 3.4) * 0.055
		fox_spirit.rotation.y = sin(animation_clock * 1.8) * 0.18
		var spirit_tail := fox_spirit.get_node_or_null("Spirit_Tail") as MeshInstance3D
		if spirit_tail != null:
			spirit_tail.rotation.x = -0.9 + sin(animation_clock * 7.0) * 0.16
			spirit_tail.rotation.z = 0.55 + cos(animation_clock * 5.0) * 0.12
	damage_animation_time = maxf(0.0, damage_animation_time - delta)
	if is_knocked_out:
		visual_root.rotation.x = lerp(visual_root.rotation.x, -1.0, delta * 5.0)
		return
	if landing_roll_time > 0.0:
		landing_roll_time = maxf(0.0, landing_roll_time - delta)
		visual_root.rotation.x = sin((0.65 - landing_roll_time) / 0.65 * PI) * 0.72
		left_arm_pivot.rotation.x = -1.0
		right_arm_pivot.rotation.x = -1.0
		left_leg_pivot.rotation.x = 0.75
		right_leg_pivot.rotation.x = 0.75
		return
	visual_root.rotation.x = move_toward(visual_root.rotation.x, 0.0, delta * 5.0)
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := horizontal_speed > 0.35 and is_on_floor() and not healing
	var crouch_blend := 1.0 if crouching or Input.is_action_pressed("crouch") else 0.0
	var run_blend := clampf(horizontal_speed / SPRINT_SPEED, 0.0, 1.0) if moving else 0.0
	var stride := sin(animation_clock * (8.0 + horizontal_speed * 1.25)) * run_blend
	var idle_bob := sin(animation_clock * 2.2) * 0.018
	var breathing := sin(animation_clock * 1.65) * 0.012
	var sprint_blend := clampf((horizontal_speed - WALK_SPEED) / (SPRINT_SPEED - WALK_SPEED), 0.0, 1.0) if moving else 0.0
	visual_root.position.y = idle_bob + (0.025 if moving else 0.0)
	# Subtle torso motion gives the procedural operator a more natural idle and run cycle.
	visual_root.rotation.x = lerp(visual_root.rotation.x, -0.10 * sprint_blend + 0.12 * crouch_blend, delta * 7.0)
	visual_root.rotation.y = sin(animation_clock * 1.1) * 0.012 * (1.0 - run_blend)
	left_leg_pivot.rotation.x = stride * (0.62 + sprint_blend * 0.12) - crouch_blend * 0.38
	right_leg_pivot.rotation.x = -stride * (0.62 + sprint_blend * 0.12) - crouch_blend * 0.38
	left_arm_pivot.rotation.x = -stride * 0.48 + crouch_blend * 0.48 + breathing
	right_arm_pivot.rotation.x = stride * 0.48 + crouch_blend * 0.48 - breathing
	if not is_on_floor() and not parachute_deployed:
		left_arm_pivot.rotation.x = -0.75
		right_arm_pivot.rotation.x = -0.75
		left_leg_pivot.rotation.x = 0.25
		right_leg_pivot.rotation.x = -0.25
	if fire_animation_time > 0.0:
		right_arm_pivot.rotation.x -= 0.65 * (fire_animation_time / 0.14)
	if is_reloading:
		right_arm_pivot.rotation.x = -0.85 + sin(animation_clock * 12.0) * 0.12
		left_arm_pivot.rotation.x = -0.65 + sin(animation_clock * 12.0) * 0.10
		weapon_root.rotation.x = sin(animation_clock * 12.0) * 0.08
	if damage_animation_time > 0.0:
		left_arm_pivot.rotation.x -= 0.35 * (damage_animation_time / 0.22)
		right_arm_pivot.rotation.x -= 0.35 * (damage_animation_time / 0.22)
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
	if not is_reloading and weapon_root != null:
		weapon_root.rotation.x = move_toward(weapon_root.rotation.x, 0.0, delta * 4.0)
	if parachute_deployed:
		visual_root.rotation.z = lerp(visual_root.rotation.z, -move_input.x * 0.16, delta * 3.0)
		left_arm_pivot.rotation.z = -0.65
		right_arm_pivot.rotation.z = 0.65
		velocity.y = maxf(velocity.y, -3.2)
		if is_on_floor():
			parachute_deployed = false
			parachute_visual.visible = false
			landing_roll_time = 0.65
	else:
		visual_root.rotation.z = move_toward(visual_root.rotation.z, 0.0, delta * 4.0)
		left_arm_pivot.rotation.z = move_toward(left_arm_pivot.rotation.z, 0.0, delta * 5.0)
		right_arm_pivot.rotation.z = move_toward(right_arm_pivot.rotation.z, 0.0, delta * 5.0)

func _physics_process(delta: float) -> void:
	if is_knocked_out:
		return
	if Input.is_action_just_pressed("heal"):
		start_healing()
	if Input.is_action_just_pressed("reload"):
		start_reload()
	if is_reloading:
		reload_time -= delta
		if reload_time <= 0.0:
			var needed := MAGAZINE_SIZE - ammo
			var loaded := mini(needed, reserve_ammo)
			ammo += loaded
			reserve_ammo -= loaded
			is_reloading = false
			if magazine_visual != null:
				magazine_visual.visible = true
			if magazine_stripe != null:
				magazine_stripe.visible = true
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
	if parachute_deployed:
		speed = 7.8
		var wind_drift := Vector3(sin(animation_clock * 0.7) * 0.35, 0.0, cos(animation_clock * 0.55) * 0.25)
		direction = (direction + wind_drift).normalized() if direction.length() > 0.01 else wind_drift
	var target_x := direction.x * speed
	var target_z := direction.z * speed
	var rate := ACCELERATION if direction.length() > 0.01 else DECELERATION
	velocity.x = move_toward(velocity.x, target_x, (ACCELERATION * 0.72 if parachute_deployed else rate) * delta)
	velocity.z = move_toward(velocity.z, target_z, (ACCELERATION * 0.72 if parachute_deployed else rate) * delta)

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
	if fire_cooldown > 0.0 or is_reloading or ammo <= 0:
		return
	fire_cooldown = FIRE_INTERVAL
	ammo -= 1
	fire_animation_time = 0.14
	muzzle_flash_time = 0.065
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


func apply_pickup(pickup_type: String, amount: int) -> bool:
	if is_knocked_out or amount <= 0:
		return false
	if pickup_type == "ammo":
		var before := reserve_ammo
		reserve_ammo = mini(300, reserve_ammo + amount)
		return reserve_ammo > before
	if pickup_type == "medkit":
		var before := medkits
		medkits = mini(5, medkits + amount)
		return medkits > before
	return false


func register_kill() -> void:
	kills += 1
	var account := get_parent().get_node_or_null("WARFOX_Account")
	if account != null:
		account.call("register_kill")
