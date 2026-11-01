# WARFOX Island — World Layout

## World concept
A large circular island surrounded by ocean, designed for 50-player Battle Royale matches. The first prototype uses procedural Godot geometry and placeholder landmark blocks; all regions are original and will receive detailed art passes later.

## Regions
1. **Central Command City** — dense futuristic downtown, central plaza, rooftops, broad avenues and multi-level combat lanes.
2. **Air Defense Base** — military compound, radar yard, barracks, vehicle parking and perimeter roads.
3. **WARFOX International Airfield** — runway, hangars, terminal and service roads; designed as a high-risk loot destination.
4. **Ironworks Industrial Zone** — factories, warehouses, cooling towers and container yards.
5. **Coastal Village** — compact homes, market square, small streets and shoreline cover.
6. **Pinecrest Forest** — wooded slopes, scattered cabins and winding dirt tracks.
7. **Redstone Highlands** — rocky ridges, lookout points and steep valleys.
8. **Sunset Resort** — hotels, pools, boardwalk and open beach approaches.
9. **Old Quarry** — terraced excavation, machinery pads and exposed sightlines.
10. **Signal Station** — hilltop communications complex and radar structures.

## Match-flow principles
- Keep multiple routes between major regions so players are not forced through one choke point.
- Mix dense close-range areas, medium-range streets and long-range ridgelines.
- Keep the coast visually readable and use the terrain to shape the playable island boundary.
- Place the ten revive machines later across distinct high-traffic regions, not all in one cluster.
- Special airdrop locations must be selectable and visible to all players.
- Daylight is the default; weather changes are a later gameplay system.

## Current implementation status
The current Godot scene builds a procedural terrain surface, ocean plane, basic placeholder landmark blocks, a preview camera and a title. This is a visual blockout only: there is not yet a player controller, collision/navigation, weapons, match logic, multiplayer, or final art.
