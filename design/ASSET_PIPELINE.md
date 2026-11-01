# WARFOX Asset Pipeline

## Goal
Replace temporary procedural greybox meshes with optimized, licensed GLB/glTF assets while preserving the ten named island regions and WARFOX's black, orange, and metallic-gray identity.

## Repository layout
Import downloaded assets into these folders (keep each pack's original license file):
- `assets/characters/` — humanoid GLB models with a usable skeleton; animation clips should cover idle, walk, run, jump, crouch, and landing.
- `assets/environment/vegetation/` — trees, bushes, rocks, and ground detail.
- `assets/environment/buildings/` — modular building pieces and complete structures.
- `assets/environment/props/` — radar structures, street props, barriers, signs, and furniture.
- `assets/materials/` — optimized materials and texture sets.
- `assets/licenses/` — source URL, license text, author, and download date for every pack.

## First approved environment source
Kenney Nature Kit:
- Official page: https://kenney.nl/assets/nature-kit
- Kenney states that assets on its asset pages are public-domain CC0 and can be used in commercial projects; keep the pack's included license file with the project.
- Use it first for distant foliage, rocks, and forest dressing. Check model scale on import and standardize it before scattering instances.

Kenney license FAQ: https://kenney.nl/support

## Character asset acceptance checklist
Do not accept a character model just because it looks good in a preview. Confirm:
1. Humanoid skeleton is present and imported correctly in Godot.
2. Mesh deformation works at shoulders, elbows, hips, and knees.
3. Animation clips exist or can be retargeted for idle, walk, run, jump, crouch, landing, healing, and reload.
4. Materials use mobile-friendly texture sizes and reasonable material counts.
5. The exact model license permits the intended use; save a copy of the license and source page.

## Environment acceptance checklist
1. Prefer GLB/glTF for direct Godot import.
2. Keep texture sizes appropriate for Android and avoid unnecessary 4K maps.
3. Use shared materials and instancing for repeated foliage and props.
4. Add collision only to walkable buildings and solid obstacles.
5. Test each imported pack in a small sample scene before replacing the island greybox.

## Ten-region preservation map
1. Central Command City
2. Air Defense Base
3. WARFOX International Airfield
4. Ironworks Industrial Zone
5. Coastal Village
6. Pinecrest Forest
7. Redstone Highlands
8. Sunset Resort
9. Old Quarry
10. Signal Station

## Current status
The island locations and procedural placeholder buildings exist in `scripts/main.gd`. They are still greybox geometry. No external GLB asset pack has been imported yet, and no visual-completion claim should be made until the imported models are inspected in Godot on the target Android device.
