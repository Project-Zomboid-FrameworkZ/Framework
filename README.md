# FrameworkZ
A roleplay-first framework for Project Zomboid. It provides reusable systems for characters, players, factions, entities, UI, and data sync so gamemodes and plugins can build on a consistent foundation.

## Status
- Early development; APIs and data formats may change.
- Use on test servers first and keep backups of save data.

## Quick Start (Server Owners)
1) Install the mod on your Project Zomboid server (place in `mods` and add the Mod ID/Workshop ID when available).
2) Enable FrameworkZ before any gamemode or plugin that depends on it.
3) Restart the server and review server logs for FrameworkZ initialization lines.

## Quick Start (Developers)
- Read the in-repo docs under `media/lua/shared/_FrameworkZ/__Topics/` (QuickStart, APIOverview, Documentation).
- Explore core modules in `media/lua/shared/_FrameworkZ/_Modules/` (Characters, Players, Factions, Entities, Interfaces).
- Client overrides live in `media/lua/client/zFrameworkZ/`.
- Hooks/events are bridged via `__Foundation.lua`; see the documentation comments in that file for networking and storage helpers.

## Documentation
- Live docs (when published): https://fz.exiguous.net
- Source docs: DocZ comments throughout the Lua modules and the `_Topics` pages listed above.

## Contributing
- Issues and feature requests: open an issue in the repository with proper tagging.
- Pull requests are welcome; expect review while APIs stabilize.
- Please follow Lua formatting used in the project and keep documentation blocks up to date with code changes.

## License
See LICENSE.md for details.
