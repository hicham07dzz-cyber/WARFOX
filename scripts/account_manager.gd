extends Node
class_name WarfoxAccount

const PLAYER_ID := "1000000001"
const SAVE_PATH := "user://warfox_profile.cfg"
const STARTING_CREDITS := 999999999

const SKINS := [
	"FOX COMMANDER",
	"SHADOW RECON",
	"DESERT PHANTOM",
	"ARCTIC WOLF",
	"EMBER GUARD",
	"NEON HUNTER"
]

const WEAPONS := [
	"WARFOX RIFLE",
	"STRIKER SMG",
	"FALCON DMR",
	"BREACH SHOTGUN",
	"VANGUARD SNIPER",
	"TACTICAL PISTOL"
]

var credits := STARTING_CREDITS
var owned_skins: Array[String] = []
var owned_weapons: Array[String] = []
var equipped_skin := "FOX COMMANDER"
var equipped_weapon := "WARFOX RIFLE"
var total_kills := 0
var matches_played := 0

func _ready() -> void:
	load_profile()

func load_profile() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error == OK:
		credits = int(config.get_value("account", "credits", STARTING_CREDITS))
		total_kills = int(config.get_value("stats", "total_kills", 0))
		matches_played = int(config.get_value("stats", "matches_played", 0))
		equipped_skin = str(config.get_value("loadout", "skin", "FOX COMMANDER"))
		equipped_weapon = str(config.get_value("loadout", "weapon", "WARFOX RIFLE"))
	owned_skins.clear()
	owned_weapons.clear()
	for skin in SKINS:
		owned_skins.append(skin)
	for weapon in WEAPONS:
		owned_weapons.append(weapon)
	if not SKINS.has(equipped_skin):
		equipped_skin = SKINS[0]
	if not WEAPONS.has(equipped_weapon):
		equipped_weapon = WEAPONS[0]
	save_profile()

func save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("account", "player_id", PLAYER_ID)
	config.set_value("account", "credits", credits)
	config.set_value("inventory", "skins", owned_skins)
	config.set_value("inventory", "weapons", owned_weapons)
	config.set_value("loadout", "skin", equipped_skin)
	config.set_value("loadout", "weapon", equipped_weapon)
	config.set_value("stats", "total_kills", total_kills)
	config.set_value("stats", "matches_played", matches_played)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("WARFOX profile could not be saved: " + str(error))

func equip_skin(skin_name: String) -> bool:
	if not owned_skins.has(skin_name):
		return false
	equipped_skin = skin_name
	save_profile()
	return true

func equip_weapon(weapon_name: String) -> bool:
	if not owned_weapons.has(weapon_name):
		return false
	equipped_weapon = weapon_name
	save_profile()
	return true

func register_kill() -> void:
	total_kills += 1
	save_profile()

func register_match() -> void:
	matches_played += 1
	save_profile()

func get_account_summary() -> Dictionary:
	return {
		"player_id": PLAYER_ID,
		"credits": credits,
		"skins_unlocked": owned_skins.size(),
		"weapons_unlocked": owned_weapons.size(),
		"equipped_skin": equipped_skin,
		"equipped_weapon": equipped_weapon,
		"total_kills": total_kills,
		"matches_played": matches_played
	}
