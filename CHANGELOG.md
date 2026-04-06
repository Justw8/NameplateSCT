# Changelog

## [2.0-midnight] - 2026-04-06

Complete rewrite for WoW Midnight (12.0.1) compatibility. Zero external dependencies.

### Breaking Changes
- Removed all Ace3/LibEasing/LibSharedMedia dependencies
- Single file architecture: `NameplateSCT.lua` + `NameplateSCT.toc` only
- Removed `embeds.xml`, `Locales/`, `Libs/` folders (Classic TOC files preserved)

### Midnight Compatibility
- Replaced `COMBAT_LOG_EVENT_UNFILTERED` (blocked by taint/Secret Values) with `UNIT_COMBAT`
- `UNIT_COMBAT` registered via `RegisterEvent()` for ALL units, not just player+target
- All restricted API calls wrapped in `pcall()` for safety
- `StaticPopup_Show` hooked to suppress `ADDON_ACTION_FORBIDDEN` popups
- `SetFrameStrata` calls wrapped in pcall (API changed on Midnight)
- `C_RestrictedActions.IsAddOnRestrictionActive(0)` used with integer argument
- `sourceFlags` with `bit.band()` used instead of direct GUID comparison (GUIDs can be secret)

### New Features
- **Multi-target damage display** — damage shows on ALL mobs with nameplates, not just target
- **Elastic animation** — new Blizzard-style animation (pop big, bounce shrink, float up)
- **Full localization** of miss strings — EN, FR, DE, ES, PT, IT, RU, KO, ZH-CN, ZH-TW
- **Font selector** — dropdown with live preview, scans WoW built-in fonts + LibSharedMedia
- **Font style selector** — Outline, Thick Outline, Monochrome, None, Outline+Mono
- **Proper dropdown menus** — scrollable popup lists with checkmark on selected item, click-outside-to-close
- **Spell icon caching** — 30s fallback window for DoT/AoE spells (Consecration ticks, etc.)
- **Spell tracking** via `UNIT_SPELLCAST_SUCCEEDED`, `UNIT_SPELLCAST_START`, `UNIT_SPELLCAST_CHANNEL_START`

### Options Panel Overhaul
- Native options panel with no template dependencies (no `InterfaceOptionsCheckButtonTemplate`)
- Gold/amber WoW-style theme
- Section headers with separators
- Clickable checkbox rows with tooltips
- Sliders with value display and min/max labels
- Real dropdown popups (not click-to-cycle)
- Font preview in the font selector
- Registered in WoW's Settings panel (`/nsct` or AddOns menu)

### Bug Fixes
- Fixed AceEvent-3.0 taint propagation from `AccWideUILayoutSelection` contaminating shared `AceEvent30Frame`
- Fixed `...` vararg usage inside nested closures (Lua 5.1 limitation)
- Fixed `SetFrameStrata` crash on Midnight
- Fixed `LastSpell` forward reference error
- Fixed parent frame invisible (FontStrings not showing because parent hidden by default)
- Fixed incoming damage showing outgoing spell icons (forced `spId=nil` for player damage)
- Fixed duplicate/triple damage events (CLEU + UNIT_COMBAT dedup issues, resolved by disabling CLEU)
- Fixed options panel crash caused by boolean `truncate` key used as slider value
- Fixed `db nil at load time` when `getFontString()` accessed before `PLAYER_LOGIN`

### Internal
- Custom easing functions: `eIQ`, `eIE`, `eOQ`, `eIQn` (replacing LibEasing)
- FontString object pool with parent frame recycling
- AceDB migration layer for seamless upgrade from v1.x saved variables
- Theme system (`T` table) for consistent UI colors
- `GetAllFonts()` discovers both built-in and LibSharedMedia fonts at runtime
