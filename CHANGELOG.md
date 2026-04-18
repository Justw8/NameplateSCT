# Changelog

## [3.1] - 2026-04-06

Bug fixes, floating icons, NiceDamage-style options, standalone panel.

### Fixed
- **Options panel now standalone** — `/nsct` opens a draggable frame (ESC to close, X button). No longer depends on `Settings.RegisterCanvasLayoutCategory` which fails on Midnight
- **Secret Values handling** — removed `issecretvalue` rejection in SpellTex; all spell ID comparisons wrapped in `pcall()` to prevent silent handler crashes on Midnight
- **Other players' damage filtered** — icons only appear if you cast a spell recently (1.5s direct, 5s DoT/AoE window). No icon = not your damage
- **Icons disabled by default** — first load doesn't auto-enable icons, user opts in via `/nsct`

### Added
- **Floating icons** — icons drift upward like Blizzard's damage numbers (configurable speed)
- **Gravity slider** — controls how fast damage numbers fall (`WorldTextGravity_v2` CVar, from NiceDamage)
- **Ramp Duration slider** — controls how long damage numbers stay visible (`WorldTextRampDuration_v2` CVar, from NiceDamage)
- **Animation Style dropdown** — Scroll Up, Scroll Down, Arc (`floatingCombatTextFloatMode` CVar)
- **Float Speed slider** — adjust icon drift speed to match Blizzard's FCT
- **`/nsctdebug` command** — full diagnostics: event registration, spell tracking counters, icon counts, panel status
- **Startup warnings** — red chat messages if UNIT_COMBAT or spell tracking fails to register

### Changed
- Icon anchors to TOP of nameplate (where damage text spawns) instead of CENTER
- Icon default position: X=-15, Y=20 (left of damage numbers)
- Icon duration: 1.5s (was 0.8s, matches longer float)
- DD() dropdown supports onChange callback
- BuildOptionsPanel guards on `optCatId` (final success) not `optFrame` (first line)

---

## [3.0] - 2026-04-06

Complete architecture change: let Blizzard handle damage numbers, addon provides spell icons + font customization.

### Philosophy Change
- **v1.x/v2.x**: Addon replaces Blizzard's floating combat text entirely (custom numbers, animations, colors)
- **v3.0**: Addon **enhances** Blizzard's native FCT (which handles damage display perfectly) by adding spell icons and font options
- This eliminates all source-filtering issues (CLEU taint, other players' damage, duplicates)

### New in v3.0
- **Blizzard FCT integration** — enables and configures native floating combat text via CVars
- **Font selector** — change `DAMAGE_TEXT_FONT` globally, scans WoW built-in fonts + LibSharedMedia
- **Text scale** — adjust `WorldTextScale_v2` CVar for damage number size
- **Spell icon overlay** — texture attached to nameplate frame, fades out over configurable duration
- **Icon pool** — recycled textures for performance
- **Minimal codebase** — single `Core.lua` file

### Architecture
- `Core.lua` — single file for Midnight (spell icons + FCT config)
- `NameplateSCT.lua` — original author code preserved for Classic
- Separate TOCs: Retail loads `Core.lua`, Classic loads original code with Ace3
- No shared code between Midnight and Classic paths (zero conflict)

### Options Panel
- Gold/amber WoW-style theme
- Sections: General, Blizzard Damage Numbers, Spell Icons
- Font selector with live preview ("123 AaBb")
- Sliders: text scale, icon scale, duration, opacity, X/Y offsets
- Icon position dropdown: Left, Right, Top, Bottom
- Reset to defaults button

### Technical
- `UNIT_COMBAT` for icon trigger (fires on all nameplates)
- `UNIT_SPELLCAST_SUCCEEDED/START/CHANNEL_START` for spell tracking
- 1.5s direct cast window + 30s DoT/AoE fallback cache
- Dedup: same GUID within 50ms = skip (target fires twice)
- `StaticPopup_Show` hooked to suppress `ADDON_ACTION_FORBIDDEN`
- All API calls wrapped in `pcall()`

---

## [2.0-midnight] - 2026-04-06

Full rewrite attempting custom SCT on Midnight. Replaced by v3.0 due to CLEU taint/filtering issues.

### Why it was replaced
- `COMBAT_LOG_EVENT_UNFILTERED` has intermittent taint issues on Midnight
- `UNIT_COMBAT` doesn't provide sourceGUID — impossible to reliably filter "my damage only"
- Splitting into Core.lua + Events_Retail.lua caused local variable synchronization bugs
