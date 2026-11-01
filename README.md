# HICHAM WARFOX

An original, free, Android-first third-person Battle Royale project built with Godot 4. The project uses original procedural geometry and built-in materials so the prototype does not depend on paid assets.

## Current milestone: playable movement and collision foundation

The current prototype includes:
- Procedural island terrain with a generated trimesh collision surface.
- Five named island locations.
- Enterable landmark buildings with separate floor, roof, and wall collision bodies.
- A third-person tactical soldier model built from original primitive geometry.
- A CharacterBody3D capsule collider for the player, with walking, sprinting, jumping, and crouching.
- A SpringArm camera to help prevent the camera from passing through nearby geometry.
- An arcade raycast firing system with a centered reticle and mobile fire button.
- Three training targets with health values, hit feedback, and automatic respawn.
- Mobile joystick and touch buttons for movement, sprint, jump, and crouch.

## Important status

This is an early playable foundation, not a finished Battle Royale game. The character is a temporary procedural model; production-quality animated character assets, weapon handling, bots, inventory, match flow, optimization, and multiplayer still need implementation and device testing.

## Open the project

1. Install Godot 4.
2. Clone or download this repository.
3. Import the folder containing `project.godot` into Godot.
4. Run the main scene.

## First island locations

- Central Command City
- Air Defense Base
- Airport Hangar
- Industrial Zone
- Coastal Village

## Development roadmap

1. Test player movement, terrain collision, and building collision on Android.
2. Fix any clipping, collision, camera, or touch-control bugs found during testing.
3. Expand the weapon sandbox with weapon selection, reload, and polished hit feedback.
4. Add animated player and bot characters with navigation and combat AI.
5. Add loot, inventory, health, match flow, and shrinking safe zone.
6. Add lobby, cosmetics, rewards, and store interfaces.
7. Develop online services and multiplayer infrastructure after offline gameplay is stable.
8. Develop the separate WARFOX ADMIN application.

A reliable 50-player online mode requires dedicated server infrastructure and extensive network and security testing.
