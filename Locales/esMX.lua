local L = LibStub("AceLocale-3.0"):NewLocale("NameplateSCT", "esMX")
if not L then return end

--L["%s (A: %s)"] = "%s (A: %s)" -- A for Absorb
--L["%s (O: %s)"] = "%s (O: %s)" -- O for Overkill
--L["Abilities"] = "Abilities"
--L["Absorbed"] = "Absorbed"
--L["Alpha"] = "Alpha"
--L["Also show numbers when you take damage on your personal nameplate or center screen"] = "Also show numbers when you take damage on your personal nameplate or center screen"
--L["Animation Speed"] = "Animation Speed"
--L["Animations"] = "Animations"
--L["Appearance/Offsets"] = "Appearance/Offsets"
--L["Auto attacks that are critical hits"] = "Auto attacks that are critical hits"
--L["Auto Attacks"] = "Auto Attacks"
--L["Background"] = "Background"
--L["BlizzardSCT"] = "BlizzardSCT"
--L["Blocked"] = "Blocked"
--L["Bottom Left"] = "Bottom Left"
--L["Bottom Right"] = "Bottom Right"
--L["Bottom"] = "Bottom"
--L["Center"] = "Center"
--L["Comma Seperate"] = "Comma Separate"
--L["Crit Color"] = "Crit Color"
--L["Criticals"] = "Criticals"
--L["Default Color"] = "Default Color"
--L["Default speed: 1"] = "Default speed: 1"
--L["Default"] = "Default"
--L["Deflected"] = "Deflected"
--L["Dialog"] = "Dialog"
--L["Disabled"] = "Disabled"
--L["Display Icon"] = "Display Icon"
--L["Display Icon Only"] = "Display Icon Only"
--L["Display only the icon for damage.\nWill not change Miss, Dodge, Parry, etc displays"] = "Display only the icon for damage.\nWill not change Miss, Dodge, Parry, etc displays"
--L["Display Off-Target Text"] = "Display Off-Target Text"
--L["Display Overkill"] = "Display Overkill"
--L["Display your overkill for a target over your own nameplate"] = "Display your overkill for a target over your own nameplate"
--L["Do Not Truncate"] = "Do Not Truncate"
--L["Dodged"] = "Dodged"
--L["Don't display any numbers on enemies and only use the personal SCT."] = "Don't display any numbers on enemies and only use the personal SCT."
--L["East Asia"] = "East Asia"
--L["Embiggen critical auto attacks"] = "Embiggen critical auto attacks"
--L["Embiggen Crits Scale"] = "Embiggen Crits Scale"
--L["Embiggen Crits"] = "Embiggen Crits"
--L["Embiggen Miss/Parry/Dodge/etc Scale"] = "Embiggen Miss/Parry/Dodge/etc Scale"
--L["Embiggen Miss/Parry/Dodge/etc"] = "Embiggen Miss/Parry/Dodge/etc"
--L["Enable Masque"] = "Enable Masque"
--L["Enable"] = "Enable"
--L["Evaded"] = "Evaded"
--L["Filters"] = "Filters"
--L["Font Flags"] = "Font Flags"
--L["Font"] = "Font"
--L["Fountain"] = "Fountain"
--L["Has soft max/min, you can type whatever you'd like into the editbox"] = "Has soft max/min, you can type whatever you'd like into the editbox"
--L["Hide hits that are below a running average of your recent damage output"] = "Hide hits that are below a running average of your recent damage output"
--L["Hide hits that are below this threshold."] = "Hide hits that are below this threshold."
--L["Hide Hits Threshold"] = "Hide Hits Threshold"
--L["Hide Small Hits"] = "Hide Small Hits"
--L["High"] = "High"
--L["Icon Scale"] = "Icon Scale"
--L["Icon X Offset"] = "Icon X Offset"
--L["Icon Y Offset"] = "Icon Y Offset"
--L["Icons"] = "Icons"
--L["If the addon is enabled."] = "If the addon is enabled."
--L["Immune"] = "Immune"
--L["Inverse Spell Filter"] = "Inverse Spell Filter"
--L["Inverse the logic and only show the spells in the list instead of filtering them away."] = "Inverse the logic and only show the spells in the list instead of filtering them away."
--L["Inverse NPC Filter"] = "Inverse NPC Filter"
--L["Inverse the logic and only show npc's in the list instead of filtering them away."] = "Inverse the logic and only show npc's in the list instead of filtering them away."
--L["Left"] = "Left"
--L["Let Masque skin the icons"] = "Let Masque skin the icons"
--L["Low"] = "Low"
--L["Medium"] = "Medium"
--L["Miss/Parry/Dodge/etc"] = "Miss/Parry/Dodge/etc"
--L["Missed"] = "Missed"
--L["Monochrome Outline"] = "Monochrome Outline"
--L["Monochrome Thick Outline"] = "Monochrome Thick Outline"
--L["Monochrome"] = "Monochrome"
--L["None"] = "None"
--L["NPC id (eg: 23682) seperated by line\n\n The example is the Headless Horseman."] = "NPC id (eg: 23682) seperated by line\n\n The example is the Headless Horseman."
--L["NPCs"] = "NPCs"
--L["Off-Target Strata"] = "Off-Target Strata"
--L["Off-Target Text Appearance"] = "Off-Target Text Appearance"
--L["Only used if Personal Nameplate is Disabled"] = "Only used if Personal Nameplate is Disabled"
--L["Outline"] = "Outline"
--L["Parried"] = "Parried"
--L["Personal SCT Animations"] = "Personal SCT Animations"
--L["Personal SCT Only"] = "Personal SCT Only"
--L["Personal SCT"] = "Personal SCT"
--L["Position"] = "Position"
--L["Rainfall"] = "Rainfall"
--L["Randomly varies the starting horizontal position of each damage number."] = "Randomly varies the starting horizontal position of each damage number."
--L["Randomly varies the starting vertical position of each damage number."] = "Randomly varies the starting vertical position of each damage number."
--L["Reflected"] = "Reflected"
--L["Resisted"] = "Resisted"
--L["Right"] = "Right"
--L["Scale down hits that are below a running average of your recent damage output"] = "Scale down hits that are below a running average of your recent damage output"
--L["Scale Down Small Hits"] = "Scale Down Small Hits"
--L["Scale of the spell icon"] = "Scale of the spell icon"
--L["Shake"] = "Shake"
--L["Show Absorbed Damage shown as: '5 (A: 3)' where A: 3 is the absorbed amount"] = "Show Absorbed Damage shown as: '5 (A: 3)' where A: 3 is the absorbed amount"
--L["Show Absorbed Damage"] = "Show Absorbed Damage"
--L["Show Truncated Letter"] = "Show Truncated Letter"
--L["Size"] = "Size"
--L["Sizing Modifiers"] = "Sizing Modifiers"
--L["Small Hits Scale"] = "Small Hits Scale"
--L["Spellid/Spellname seperated by line\n\nWhite hits/melee = melee\nMiss/Parry/Dodge/etc = missed"] = "Spellid/Spellname seperated by line\n\nWhite hits/melee = melee\nMiss/Parry/Dodge/etc = missed"
--L["Spells"] = "Spells"
--L["Target Strata"] = "Target Strata"
--L["Text Formatting"] = "Text Formatting"
--L["Text Shadow"] = "Text Shadow"
--L["Thick Outline"] = "Thick Outline"
--L["Tooltip"] = "Tooltip"
--L["Top Left"] = "Top Left"
--L["Top Right"] = "Top Right"
--L["Top"] = "Top"
--L["Truncate Letter East Asia"] = "Truncate Letter East Asia"
--L["Truncate Method:\n\nWestern:\n  1000=>1K,\n  1000K=>1M\nAsia East:\n  10000=>1w"] = "Truncate Method:\n\nWestern:\n  1000=>1K,\n  1000K=>1M\nAsia East:\n  10000=>1w"
--L["Truncate Number"] = "Truncate Number"
--L["Use Crit Color"] = "Use Crit Color"
--L["Use Damage Type Color"] = "Use Damage Type Color"
--L["Use Separate Off-Target Strata"] = "Use Separate Off-Target Strata"
--L["Use Seperate Off-Target Text Appearance"] = "Use Separate Off-Target Text Appearance"
--L["Vertical Down"] = "Vertical Down"
--L["Vertical Up"] = "Vertical Up"
--L["Western"] = "Western"
--L["X Offset Personal SCT"] = "X Offset Personal SCT"
--L["X Offset"] = "X Offset"
--L["X Variance"] = "X Variance"
--L["Y Offset Personal SCT"] = "Y Offset Personal SCT"
--L["Y Offset"] = "Y Offset"
--L["Y Variance"] = "Y Variance"
--L["YOUR ENEMY NAMEPLATES ARE DISABLED, NAMEPLATESCT WILL NOT WORK!!"] = "YOUR ENEMY NAMEPLATES ARE DISABLED, NAMEPLATESCT WILL NOT WORK!!"
