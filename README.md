# NameplateSCT

Spell icon overlay + Blizzard FCT customization for World of Warcraft nameplates.

Works on **WoW Midnight (12.0.1+)** with full backward compatibility for Classic/TBC/Wrath/Cata/Mists.

## Philosophy

Blizzard's native floating combat text (FCT) already does an excellent job displaying **your** damage numbers — perfectly filtered, no duplicates, no other players' damage. Instead of replacing it, NameplateSCT **enhances** it:

- **Blizzard handles**: damage numbers, source filtering, positioning
- **NameplateSCT handles**: spell icons, font, text scale, gravity, animation style

## Features

- **Spell icons on nameplates** — shows your spell's icon floating alongside Blizzard's damage numbers
- **Font selector** — change Blizzard's damage text font (Friz Quadrata, Arial Narrow, Morpheus, Skurri, 2002, + LibSharedMedia fonts) with live preview
- **Text scale** — adjust the size of floating damage numbers
- **Animation style** — Scroll Up, Scroll Down, or Arc (like Blizzard's built-in options)
- **Gravity** — control how fast damage numbers fall
- **Ramp Duration** — control how long damage numbers stay visible
- **Floating icons** — icons drift upward matching Blizzard's FCT movement
- **Configurable icons** — scale, opacity, duration, float speed, position (Left/Right/Top/Bottom), X/Y offset
- **Zero dependencies** — no Ace3, no LibEasing, no LibSharedMedia required (on Midnight)
- **Midnight compatible** — all API calls wrapped in `pcall()`, handles Secret Values system
- **Backward compatible** — Classic/TBC/Wrath/Cata/Mists use the original author's code unchanged

## Installation

1. Download and extract to `World of Warcraft/_retail_/Interface/AddOns/`
2. Folder should be `NameplateSCT` containing `Core.lua` and `NameplateSCT.toc`
3. `/reload` in-game

## Usage

| Command | Description |
|---------|-------------|
| `/nsct` | Toggle the options panel |
| `/nsct reset` | Reset all settings to defaults |
| `/nscttest` | Show a test icon on target nameplate |
| `/nsctdebug` | Show diagnostics (event status, counters) |

## Options Panel

Access via `/nsct` — standalone draggable frame, close with ESC or X button.

### General
- Enable/disable the addon

### Blizzard Damage Numbers
- Font selector (dropdown with live preview, scans LibSharedMedia)
- Text scale slider (adjusts `WorldTextScale_v2`)
- Animation style: Scroll Up, Scroll Down, Arc
- Gravity: how fast numbers fall
- Ramp Duration: how long numbers stay visible

### Spell Icons
- Show/hide icons (disabled by default)
- Icon scale, position (Left/Right/Top/Bottom)
- Icon duration, float speed, opacity
- X/Y offset fine-tuning

## Architecture

### Midnight (Retail 12.x)
```
NameplateSCT.toc -> Core.lua (single file, ~640 lines)
```
- `UNIT_COMBAT` event detects damage on nameplates
- `UNIT_SPELLCAST_SUCCEEDED/START/CHANNEL_START` tracks player's spells
- Icons only appear if player cast recently (1.5s direct, 5s DoT window)
- Icon textures recycled via pool, float upward with fade-out
- Blizzard FCT configured via CVars (`DAMAGE_TEXT_FONT`, `WorldTextScale_v2`, `WorldTextGravity_v2`, `WorldTextRampDuration_v2`, `floatingCombatTextFloatMode`)
- Standalone options panel (not dependent on Settings API)

### Classic / TBC / Wrath / Cata / Mists
```
NameplateSCT_*.toc -> embeds.xml (Ace3) -> Locales/ -> NameplateSCT.lua (original code)
```
Original author's code runs unchanged with full Ace3 dependency chain.

## File Structure

```
NameplateSCT/
  Core.lua               <- Midnight code (spell icons + FCT config)
  NameplateSCT.lua        <- Original author code (Classic, unchanged)
  NameplateSCT.toc        <- Retail/Midnight: loads Core.lua
  NameplateSCT_Vanilla.toc
  NameplateSCT_TBC.toc
  NameplateSCT_Wrath.toc
  NameplateSCT_Cata.toc
  NameplateSCT_Mists.toc
  embeds.xml              <- Ace3 libs (Classic only)
  Locales/                <- AceLocale files (Classic only)
  Libs/                   <- Ace3 libraries (Classic only)
  LICENSE
```

## Credits

- **mpstark** — original NameplateSCT author
- **Justwait** — maintainer
- **NiceDamage** — inspiration for gravity/ramp duration options
- **MikScrollingBattleText** — inspiration for the hybrid FCT + icon approach

## License

MIT License. See [LICENSE](LICENSE) for details.

Addon listing: https://www.curseforge.com/wow/addons/nameplate-scrolling-combat-text
