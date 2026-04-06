# NameplateSCT

Nameplate-based Scrolling Combat Text for World of Warcraft.

Displays damage numbers, miss/dodge/parry text, and spell icons directly on enemy nameplates. Works on **WoW Midnight (12.0.1)** with full compatibility for the new restricted API system.

## Features

- **Damage numbers on all nameplates** — not just your current target, all mobs with visible nameplates show damage
- **Spell icons** next to damage numbers with configurable position and scale
- **Color by spell school** — fire, frost, shadow, holy, etc. each have distinct colors
- **Multiple animations** — Vertical Up/Down, Fountain, Rainfall, Elastic (Blizzard-style pop + float)
- **Critical hit scaling** — crits appear larger with configurable scale
- **Small hit filtering** — shrink or hide insignificant damage numbers
- **Personal SCT** — optionally show incoming damage on your own nameplate
- **Miss/Dodge/Parry/Block** text with full localization (EN, FR, DE, ES, PT, IT, RU, KO, ZH)
- **Font selector** — choose from WoW built-in fonts + any fonts from LibSharedMedia (other addons)
- **Font style options** — Outline, Thick Outline, Monochrome, None
- **Zero dependencies** — no Ace3, no LibEasing, no LibSharedMedia required. Single `.lua` file
- **Midnight compatible** — works around Blizzard's Secret Values API restrictions using `UNIT_COMBAT` events with `pcall` safety wrappers
- **Backward compatible** — Classic/TBC/Wrath/Cata/Mists TOC files preserved

## Installation

1. Download and extract to your `World of Warcraft/_retail_/Interface/AddOns/` folder
2. The folder should be named `NameplateSCT` containing `NameplateSCT.lua` and `NameplateSCT.toc`
3. Restart WoW or `/reload`

## Usage

| Command | Description |
|---------|-------------|
| `/nsct` | Open the options panel |
| `/nsct reset` | Reset all settings to defaults |
| `/nsctdebug` | Show addon diagnostic info |
| `/nsctdebugon` | Enable debug output |
| `/nsctdebugoff` | Disable debug output |
| `/nscttest` | Display a test animation |

## Options Panel

Access via `/nsct` or WoW's AddOns settings menu.

### General
- Enable/disable the addon
- Personal SCT (incoming damage)
- Off-target text visibility
- Overkill and absorbed damage display

### Appearance
- Font selection (with live preview) — includes all LibSharedMedia fonts
- Font style (Outline, Thick, Monochrome, None)
- Font size, opacity, animation speed
- X/Y offsets
- Text shadow, damage school colors, crit colors

### Spell Icons
- Toggle icons on/off
- Scale, position (Left/Right/Top/Bottom)
- X/Y icon offset fine-tuning

### Animations
- Per-type animation: Ability, Crit, Miss, Auto-Attack, AA Crit
- Available styles: Vertical Up, Vertical Down, Fountain, Rainfall, Elastic (Blizzard-style), Disabled

### Scaling
- Enlarge crits with configurable scale
- Shrink or hide small hits
- Truncate large numbers (1.5k instead of 1500)

### Personal Nameplate
- Separate X/Y offsets for incoming damage position

## Technical Notes

### Midnight (12.0.1) Compatibility
- `COMBAT_LOG_EVENT_UNFILTERED` is not used due to taint issues with Blizzard's Secret Values system
- All damage detection uses `UNIT_COMBAT` registered via `RegisterEvent()` for all units
- Spell icons are tracked via `UNIT_SPELLCAST_SUCCEEDED` with a fallback cache (30s window for DoTs/AoE)
- All restricted API calls are wrapped in `pcall()` for safety
- `StaticPopup_Show` is hooked to suppress `ADDON_ACTION_FORBIDDEN` popups from this addon

### Architecture
- Single file (`NameplateSCT.lua`), no external dependencies
- Custom easing functions replacing LibEasing
- FontString object pool with parent frame recycling
- AceDB migration layer for users upgrading from the original version

## Credits

- **mpstark** — original NameplateSCT author
- **Justwait** — maintainer
- **MidnightBattleText** by SheaGlass — reference patterns for Midnight API compatibility

## License

MIT License. See [LICENSE](LICENSE) for details.

Addon listing: https://www.curseforge.com/wow/addons/nameplate-scrolling-combat-text
