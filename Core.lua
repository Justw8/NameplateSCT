---------------------------------------------------------------
-- NameplateSCT v3.1  –  Midnight (12.0.1+)
--
-- Blizzard handles damage numbers (perfectly filtered).
-- We add: spell icons, font/scale CVars, FCT toggles.
---------------------------------------------------------------

-- ========================
--  LOCALIZATION
-- ========================
local L = {}
local locale = GetLocale()

-- English (default)
local enUS = {
    -- Chat messages
    LOADED = "v3.1 loaded.",
    NOT_READY = "Not ready",
    PANEL_ERROR = "Panel error:",
    PANEL_FAILED = "Failed to create options panel",
    UC_FAILED = "UNIT_COMBAT failed",
    SPELL_FAILED = "Spell tracking failed",
    FONT_RESTART_WARN = "Note: changing damage font requires FULL GAME RESTART (quit, not /reload)",
    NICEDAMAGE_WARN = "NiceDamage detected — it overrides damage font. Disable it or change font there.",
    TEST_ICON = "Test icon",
    TARGET_MOB_FIRST = "Target a mob first",
    -- Panel: Window
    TITLE = "NameplateSCT v3.1",
    VERSION = "v3.1 — Blizzard FCT + Icons",
    SETTINGS_DESC = "Blizzard FCT enhancement — spell icons + font customization.\nType |cFFFFD100/nsct|r to open the full options panel.",
    OPEN_OPTIONS = "Open Options  /nsct",
    RESET_DEFAULTS = "Reset to Defaults",
    -- Panel: Sections
    SEC_GENERAL = "General",
    SEC_FONT_SCALE = "Font & Scale",
    SEC_FONT_ADV = "Font Advanced",
    SEC_PHYSICS = "Physics",
    SEC_FCT_DISPLAY = "FCT Display",
    SEC_SPELL_ICONS = "Alpha Function - Spell Icons",
    SEC_ICON_ANIM = "Alpha - Icon Animation",
    -- Panel: Warnings
    WARN_ND_LOADED = "NiceDamage is loaded! It overrides our font.",
    WARN_ND_DISABLE = "Disable NiceDamage for font change to work.",
    WARN_FULL_RESTART = "FULL GAME RESTART REQUIRED for damage font!",
    WARN_QUIT_GAME = "(quit the game completely, not just /reload)",
    WARN_OUTLINE = "Outline/Shadow = instant (incoming dmg/heal text)",
    WARN_UI_FONT = "UI font change = /reload may suffice",
    WARN_UI_FONT_EMPTY = "UI/SCT font — empty = same as damage font",
    -- Panel: Labels
    LBL_ENABLE = "Enable",
    LBL_ENABLE_TIP = "Master toggle",
    LBL_FONT = "Font",
    LBL_SAME_AS_DAMAGE = "(Same as damage font)",
    LBL_TEXT_SCALE = "Text Scale",
    LBL_ANIM_STYLE = "Animation Style",
    LBL_SCROLL_UP = "Scroll Up",
    LBL_SCROLL_DOWN = "Scroll Down",
    LBL_ARC = "Arc",
    LBL_FONT_OUTLINE = "Font Outline",
    LBL_OUTLINE = "Outline",
    LBL_THICK_OUTLINE = "Thick Outline",
    LBL_MONOCHROME = "Monochrome",
    LBL_NONE = "None",
    LBL_FONT_SHADOW = "Font Shadow",
    LBL_GRAVITY = "Gravity",
    LBL_RAMP_DURATION = "Ramp Duration",
    LBL_RAMP_POW = "Ramp Power",
    LBL_RAMP_POW_CRIT = "Ramp Power (Crit)",
    LBL_RANDOM_XY = "Random XY Spread",
    -- FCT toggles
    LBL_DODGE_PARRY = "Dodge / Parry / Miss",
    LBL_DODGE_PARRY_TIP = "Show avoidance text",
    LBL_SPELL_MECH = "Spell Mechanics (Stun, Silence...)",
    LBL_SPELL_MECH_TIP = "Show CC effects",
    LBL_AURAS = "Auras (Buff/Debuff)",
    LBL_AURAS_TIP = "Show buff/debuff text",
    LBL_ALL_AUTOS = "All Auto-Attacks",
    LBL_ALL_AUTOS_TIP = "Show every auto-attack",
    LBL_COMBO_POINTS = "Combo Points",
    LBL_COMBO_POINTS_TIP = "Show combo point gains",
    LBL_REACTIVES = "Reactive Abilities (Procs)",
    LBL_REACTIVES_TIP = "Show procs",
    LBL_DMG_REDUCTION = "Damage Reduction",
    LBL_DMG_REDUCTION_TIP = "Show resistance",
    LBL_LOW_HEALTH = "Low Mana/Health Warning",
    LBL_LOW_HEALTH_TIP = "Low resource warning",
    LBL_REP_CHANGES = "Reputation Changes",
    LBL_REP_CHANGES_TIP = "Show rep changes",
    LBL_HONOR_GAINS = "Honor Gains",
    LBL_HONOR_GAINS_TIP = "Show honor",
    -- Spell icons
    LBL_SHOW_ICONS = "Show Spell Icons",
    LBL_SHOW_ICONS_TIP = "Show spell icon on nameplate",
    LBL_ICON_SCALE = "Icon Scale",
    LBL_ICON_POSITION = "Icon Position",
    LBL_LEFT = "Left", LBL_RIGHT = "Right", LBL_TOP = "Top", LBL_BOTTOM = "Bottom",
    LBL_ICON_OPACITY = "Icon Opacity",
    LBL_ICON_DURATION = "Icon Duration",
    LBL_FLOAT_SPEED = "Float Speed",
    LBL_ICON_X = "Icon X Offset",
    LBL_ICON_Y = "Icon Y Offset",
}

-- French
local frFR = {
    LOADED = "v3.1 chargé.",
    NOT_READY = "Non prêt",
    PANEL_ERROR = "Erreur panneau :",
    PANEL_FAILED = "Impossible de créer le panneau d'options",
    UC_FAILED = "UNIT_COMBAT a échoué",
    SPELL_FAILED = "Suivi des sorts a échoué",
    FONT_RESTART_WARN = "Note : changer la police de dégâts nécessite un REDÉMARRAGE COMPLET DU JEU (quitter, pas /reload)",
    NICEDAMAGE_WARN = "NiceDamage détecté — il écrase notre police. Désactive-le ou change la police là-bas.",
    TEST_ICON = "Icône de test",
    TARGET_MOB_FIRST = "Cible un mob d'abord",
    TITLE = "NameplateSCT v3.1",
    VERSION = "v3.1 — FCT Blizzard + Icônes",
    SETTINGS_DESC = "Amélioration du FCT Blizzard — icônes de sort + personnalisation de police.\nTape |cFFFFD100/nsct|r pour ouvrir le panneau complet.",
    OPEN_OPTIONS = "Ouvrir les options  /nsct",
    RESET_DEFAULTS = "Réinitialiser",
    SEC_GENERAL = "Général",
    SEC_FONT_SCALE = "Police & Taille",
    SEC_FONT_ADV = "Police Avancé",
    SEC_PHYSICS = "Physique",
    SEC_FCT_DISPLAY = "Affichage FCT",
    SEC_SPELL_ICONS = "Fonction Alpha - Icônes de sort",
    SEC_ICON_ANIM = "Alpha - Animation des icônes",
    WARN_ND_LOADED = "NiceDamage est chargé ! Il écrase notre police.",
    WARN_ND_DISABLE = "Désactive NiceDamage pour que le changement de police fonctionne.",
    WARN_FULL_RESTART = "REDÉMARRAGE COMPLET DU JEU REQUIS pour la police !",
    WARN_QUIT_GAME = "(quitte le jeu complètement, pas juste /reload)",
    WARN_OUTLINE = "Contour/Ombre = instantané (texte dégâts/soins reçus)",
    WARN_UI_FONT = "Changement police UI = /reload peut suffire",
    WARN_UI_FONT_EMPTY = "Police UI/SCT — vide = identique à la police de dégâts",
    LBL_ENABLE = "Activer",
    LBL_ENABLE_TIP = "Interrupteur principal",
    LBL_FONT = "Police",
    LBL_SAME_AS_DAMAGE = "(Identique à la police de dégâts)",
    LBL_TEXT_SCALE = "Taille du texte",
    LBL_ANIM_STYLE = "Style d'animation",
    LBL_SCROLL_UP = "Défilement haut",
    LBL_SCROLL_DOWN = "Défilement bas",
    LBL_ARC = "Arc",
    LBL_FONT_OUTLINE = "Contour de police",
    LBL_OUTLINE = "Contour",
    LBL_THICK_OUTLINE = "Contour épais",
    LBL_MONOCHROME = "Monochrome",
    LBL_NONE = "Aucun",
    LBL_FONT_SHADOW = "Ombre de police",
    LBL_GRAVITY = "Gravité",
    LBL_RAMP_DURATION = "Durée d'affichage",
    LBL_RAMP_POW = "Puissance de fondu",
    LBL_RAMP_POW_CRIT = "Puissance fondu (Critique)",
    LBL_RANDOM_XY = "Dispersion XY aléatoire",
    LBL_DODGE_PARRY = "Esquive / Parade / Raté",
    LBL_DODGE_PARRY_TIP = "Afficher le texte d'évitement",
    LBL_SPELL_MECH = "Alertes de sorts (Stun, Silence...)",
    LBL_SPELL_MECH_TIP = "Afficher les effets de CC",
    LBL_AURAS = "Auras (Buff/Debuff)",
    LBL_AURAS_TIP = "Afficher texte buff/debuff",
    LBL_ALL_AUTOS = "Toutes les attaques auto",
    LBL_ALL_AUTOS_TIP = "Afficher toutes les attaques auto",
    LBL_COMBO_POINTS = "Points de combo",
    LBL_COMBO_POINTS_TIP = "Afficher les gains de combo",
    LBL_REACTIVES = "Capacités réactives (Procs)",
    LBL_REACTIVES_TIP = "Afficher les procs",
    LBL_DMG_REDUCTION = "Réduction de dégâts",
    LBL_DMG_REDUCTION_TIP = "Afficher la résistance",
    LBL_LOW_HEALTH = "Avertissement Mana/Vie faible",
    LBL_LOW_HEALTH_TIP = "Avertissement ressources faibles",
    LBL_REP_CHANGES = "Changements de réputation",
    LBL_REP_CHANGES_TIP = "Afficher les changements de rep",
    LBL_HONOR_GAINS = "Gains d'honneur",
    LBL_HONOR_GAINS_TIP = "Afficher l'honneur",
    LBL_SHOW_ICONS = "Afficher les icônes de sort",
    LBL_SHOW_ICONS_TIP = "Afficher l'icône du sort sur la plaque",
    LBL_ICON_SCALE = "Taille de l'icône",
    LBL_ICON_POSITION = "Position de l'icône",
    LBL_LEFT = "Gauche", LBL_RIGHT = "Droite", LBL_TOP = "Haut", LBL_BOTTOM = "Bas",
    LBL_ICON_OPACITY = "Opacité",
    LBL_ICON_DURATION = "Durée de l'icône",
    LBL_FLOAT_SPEED = "Vitesse de montée",
    LBL_ICON_X = "Décalage X",
    LBL_ICON_Y = "Décalage Y",
}

-- Select locale (fallback to enUS)
local src = (locale == "frFR" and frFR) or enUS
for k, v in pairs(enUS) do L[k] = src[k] or v end

-- ========================
--  COMPAT
-- ========================
local RawSpellTex = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
local function SpellTex(id)
    if not id then return nil end
    local zOk, isZero = pcall(function() return id == 0 or id == "" end)
    if zOk and isZero then return nil end
    local ok, t = pcall(RawSpellTex, id)
    if ok and t then return t end
    local ok2, info = pcall(function()
        if C_Spell and C_Spell.GetSpellInfo then return C_Spell.GetSpellInfo(id) end
    end)
    if ok2 and info and info.iconID then return info.iconID end
end

-- ========================
--  DATABASE
-- ========================
local db
local D = {
    enabled = true,
    -- Font & Scale
    damageFont = "Fonts\\FRIZQT__.TTF",
    damageScale = 1.5,
    floatMode = "3",
    -- Font Advanced
    fontOutline = "OUTLINE",
    fontShadow = 1,
    uiFont = "",
    -- Physics
    textGravity = 0.5,
    textRampDuration = 1.0,
    rampPow = 0,
    rampPowCrit = 0,
    randomXY = 0,
    -- FCT Display (Blizzard defaults)
    fctDodgeParryMiss = false,
    fctSpellMechanics = true,
    fctAuras = false,
    fctAllAutos = false,
    fctComboPoints = false,
    fctReactives = false,
    fctDamageReduction = false,
    fctLowManaHealth = true,
    fctRepChanges = false,
    fctHonorGains = false,
    -- Spell Icons (off by default)
    showIcon = false,
    iconScale = 1.2,
    iconPosition = "LEFT",
    iconAlpha = 0.9,
    iconDuration = 1.5,
    iconOffsetX = -15,
    iconOffsetY = 20,
    floatSpeed = 55,
}

local function InitDB()
    NameplateSCTDB = NameplateSCTDB or {}
    if NameplateSCTDB.global then NameplateSCTDB.global = nil end
    for k, v in pairs(D) do if NameplateSCTDB[k] == nil then NameplateSCTDB[k] = v end end
    db = NameplateSCTDB
end

-- Apply font ASAP at file load (SavedVariables might not be loaded yet)
if NameplateSCTDB and NameplateSCTDB.damageFont then
    DAMAGE_TEXT_FONT = NameplateSCTDB.damageFont
end

-- ADDON_LOADED: fires when our SavedVariables are ready — set font BEFORE PLAYER_LOGIN
local earlyFrame = CreateFrame("Frame")
earlyFrame:RegisterEvent("ADDON_LOADED")
earlyFrame:SetScript("OnEvent", function(self, _, addonName)
    if addonName == "NameplateSCT" then
        if NameplateSCTDB and NameplateSCTDB.damageFont then
            DAMAGE_TEXT_FONT = NameplateSCTDB.damageFont
        end
        self:UnregisterAllEvents()
    end
end)

-- ========================
--  FONT APPLICATION (NiceDamage approach)
-- ========================
local function SCV(name, val)
    pcall(function() SetCVar(name, val) end)
    pcall(function() SetCVar(name .. "_v2", val) end)
end

local function ResolveFont(path)
    if not path or path == "" then return "Fonts\\FRIZQT__.TTF" end
    -- Validate: try to use it on a test FontString
    local ok = pcall(function() local fs = UIParent:CreateFontString(); fs:SetFont(path, 12); fs:Hide() end)
    if ok then return path end
    -- Fallback: try LSM by treating 'path' as a font name
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local resolved = LSM:Fetch("font", path, true)
        if resolved then return resolved end
    end
    -- Last resort: default Blizzard font
    return "Fonts\\FRIZQT__.TTF"
end

local function ApplyFontCVars()
    if not db then return end
    DAMAGE_TEXT_FONT = ResolveFont(db.damageFont)
    SCV("WorldTextScale", db.damageScale)
    SCV("floatingCombatTextFloatMode", tonumber(db.floatMode) or 3)
    SCV("combatTextFloatMode", tonumber(db.floatMode) or 3)
    SCV("WorldTextGravity", db.textGravity)
    SCV("WorldTextRampDuration", db.textRampDuration)
    pcall(function() SetCVar("WorldTextRampPow", db.rampPow) end)
    pcall(function() SetCVar("WorldTextRampPowCrit", db.rampPowCrit) end)
    pcall(function() SetCVar("WorldTextRandomXY", db.randomXY) end)
    SCV("floatingCombatTextCombatDamage", 1)
    SCV("floatingCombatTextCombatHealing", 1)
    local function B(v) return v and 1 or 0 end
    SCV("floatingCombatTextDodgeParryMiss", B(db.fctDodgeParryMiss))
    SCV("floatingCombatTextSpellMechanics", B(db.fctSpellMechanics))
    SCV("floatingCombatTextAuras", B(db.fctAuras))
    SCV("floatingCombatTextCombatDamageAllAutos", B(db.fctAllAutos))
    SCV("floatingCombatTextComboPoints", B(db.fctComboPoints))
    SCV("floatingCombatTextReactives", B(db.fctReactives))
    SCV("floatingCombatTextDamageReduction", B(db.fctDamageReduction))
    SCV("floatingCombatTextLowManaHealth", B(db.fctLowManaHealth))
    SCV("floatingCombatTextRepChanges", B(db.fctRepChanges))
    SCV("floatingCombatTextHonorGains", B(db.fctHonorGains))
end

local function ApplyFontObjects()
    if not db then return end
    local outline = db.fontOutline or "OUTLINE"
    if outline == "NONE" then outline = "" end
    local shadow = db.fontShadow or 1
    local uiPath = (db.uiFont ~= "" and db.uiFont) or db.damageFont
    for _, name in ipairs({"CombatTextFont", "DamageNumberFont", "WorldFont"}) do
        local obj = _G[name]
        if obj then pcall(function()
            local _, size = obj:GetFont()
            obj:SetFont(uiPath, size or 16, outline)
            obj:SetShadowOffset(shadow, -shadow)
            obj:SetShadowColor(0, 0, 0, 1)
        end) end
    end
end

-- ========================
--  SPELL TRACKING
-- ========================
local lastSpellId, lastSpellTime, lastSpellName
local dbgSpellCount, dbgCombatCount, dbgIconCount = 0, 0, 0
local SPELL_WIN = 1.5
local DOT_WIN = 30
local dotCache = {}

local spellFrame = CreateFrame("Frame")
local spOk1 = pcall(function() spellFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet") end)
local spOk2 = pcall(function() spellFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player") end)
local spOk3 = pcall(function() spellFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player") end)

spellFrame:SetScript("OnEvent", function(_, _, unit, _, spellId)
    local uOk, isPlayer = pcall(function() return unit == "player" end)
    if not uOk or not isPlayer then return end
    if not spellId then return end
    local zOk, isZero = pcall(function() return spellId == 0 end)
    if zOk and isZero then return end
    lastSpellId = spellId
    lastSpellTime = GetTime()
    dbgSpellCount = dbgSpellCount + 1
    local ok, n = pcall(function()
        return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellId)
    end)
    lastSpellName = ok and n or nil
    dotCache[spellId] = { name = lastSpellName, expire = GetTime() + DOT_WIN }
end)

local function GetSpellIcon()
    local now = GetTime()
    if lastSpellId and lastSpellTime and (now - lastSpellTime < SPELL_WIN) then
        local tex = SpellTex(lastSpellId)
        if tex then return tex end
    end
    if not lastSpellTime or (now - lastSpellTime > 5) then return nil end
    local best, bestExp
    for sid, info in pairs(dotCache) do
        if now < info.expire then
            if not bestExp or info.expire > bestExp then best = sid; bestExp = info.expire end
        else dotCache[sid] = nil end
    end
    if best then return SpellTex(best) end
end

-- ========================
--  ICON POOL
-- ========================
local iconPool = {}
local activeIcons = {}

local function GetIcon(nameplate)
    if not nameplate then return nil end
    local icon
    if #iconPool > 0 then
        icon = table.remove(iconPool)
    else
        icon = nameplate:CreateTexture(nil, "OVERLAY")
    end
    icon:SetParent(nameplate)
    icon:ClearAllPoints()
    icon:SetAlpha(db.iconAlpha)
    icon:Show()
    return icon
end

local function RecycleIcon(icon)
    if not icon then return end
    icon:Hide(); icon:SetAlpha(0); icon:ClearAllPoints()
    activeIcons[icon] = nil
    table.insert(iconPool, icon)
end

local animFrame = CreateFrame("Frame")
animFrame:SetScript("OnUpdate", function()
    if not next(activeIcons) then return end
    local now = GetTime()
    local speed = db and db.floatSpeed or 55
    for icon, info in pairs(activeIcons) do
        local elapsed = now - info.start
        if elapsed >= info.dur then
            RecycleIcon(icon)
        else
            local drift = elapsed * speed
            icon:ClearAllPoints()
            icon:SetPoint(info.anchor, info.np, "TOP", info.ofsX, info.ofsY + drift)
            local fadeStart = info.dur * 0.6
            if elapsed > fadeStart then
                icon:SetAlpha(db.iconAlpha * (1 - (elapsed - fadeStart) / (info.dur - fadeStart)))
            end
        end
    end
end)

-- ========================
--  SHOW ICON
-- ========================
local INV = { LEFT = "RIGHT", RIGHT = "LEFT", TOP = "BOTTOM", BOTTOM = "TOP" }

local function ShowSpellIcon(unit)
    if not db or not db.enabled or not db.showIcon then return end
    local tex = GetSpellIcon()
    if not tex then return end
    local npOk, np = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if not npOk or not np then return end
    local icon = GetIcon(np)
    if not icon then return end
    dbgIconCount = dbgIconCount + 1
    local sz = db.iconScale * 20
    icon:SetTexture(tex); icon:SetSize(sz, sz)
    local pos = db.iconPosition or "LEFT"
    local anchor = INV[pos] or "RIGHT"
    icon:SetPoint(anchor, np, "TOP", db.iconOffsetX, db.iconOffsetY)
    activeIcons[icon] = {
        start = GetTime(), dur = db.iconDuration,
        np = np, anchor = anchor,
        ofsX = db.iconOffsetX, ofsY = db.iconOffsetY,
    }
end

-- ========================
--  EVENTS
-- ========================
local lastUC = {}
local DEDUP_WIN = 0.05

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
local ucOk = pcall(function() ev:RegisterEvent("UNIT_COMBAT") end)

ev:SetScript("OnEvent", function(_, event, a1, a2)
    if event == "PLAYER_LOGIN" then
        InitDB(); ApplyFontCVars(); ApplyFontObjects()
        pcall(RegisterSettings)
        local pOk, pErr = pcall(BuildOptionsPanel)
        if not pOk then print("|cFFFF0000[NSCT] " .. L.PANEL_ERROR .. "|r " .. tostring(pErr)) end
        print("|cFF00FF00NameplateSCT|r " .. L.LOADED .. "  /nsct = options")
        if not ucOk then print("|cFFFF0000[NSCT]|r " .. L.UC_FAILED) end
        if not spOk1 and not spOk2 and not spOk3 then print("|cFFFF0000[NSCT]|r " .. L.SPELL_FAILED) end
        print("|cFFFF6600[NSCT]|r " .. L.FONT_RESTART_WARN)
        local ndOk, ndLoaded = pcall(function()
            if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded("NiceDamage") end
            if IsAddOnLoaded then return IsAddOnLoaded("NiceDamage") end
        end)
        if ndOk and ndLoaded then print("|cFFFF6600[NSCT]|r " .. L.NICEDAMAGE_WARN) end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        if db then ApplyFontCVars(); ApplyFontObjects() end
        return
    end
    if not db then return end
    if event == "NAME_PLATE_UNIT_REMOVED" then
        local rOk, np = pcall(C_NamePlate.GetNamePlateForUnit, a1)
        if rOk and np then
            for icon in pairs(activeIcons) do
                if icon:GetParent() == np then RecycleIcon(icon) end
            end
        end
    elseif event == "UNIT_COMBAT" then
        dbgCombatCount = dbgCombatCount + 1
        local unit, action = a1, a2
        if not unit or type(unit) ~= "string" then return end
        if unit == "player" then return end
        if action ~= "WOUND" then return end
        -- Only process nameplateX tokens — skip target/focus/party/raid to avoid duplicates
        -- and API restrictions (GetNamePlateForUnit rejects party/raid, target/nameplateX dedup)
        if not unit:match("^nameplate%d+$") then return end
        -- Simple dedup by unit token (nameplateX tokens are regular strings, not secret values)
        local now = GetTime()
        if lastUC[unit] and (now - lastUC[unit]) < DEDUP_WIN then return end
        lastUC[unit] = now
        ShowSpellIcon(unit)
    end
end)

-- ========================
--  OPTIONS PANEL HELPERS
-- ========================
local optFrame, optCatId

local T = {
    gold = {1,.82,0}, accent = {.85,.65,.13},
    bg = {.10,.10,.10,.92}, text = {.90,.90,.90},
    check = {.85,.65,.13}, pad = 16, W = 340,
}

local function Sep(p, y)
    local t = p:CreateTexture(nil, "ARTWORK")
    t:SetPoint("TOPLEFT", T.pad-2, y); t:SetPoint("TOPRIGHT", -T.pad+2, y)
    t:SetHeight(1); t:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], .25)
    return y - 8
end

local function Header(p, y, txt)
    y = y - 4
    local h = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", T.pad, y); h:SetText(txt)
    h:SetTextColor(T.accent[1], T.accent[2], T.accent[3])
    return Sep(p, y - 20)
end

local function Warn(p, y, txt)
    local w = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    w:SetPoint("TOPLEFT", T.pad, y); w:SetText("|cFFFF6600" .. txt .. "|r")
    return y - 14
end

local function CB(p, y, lbl, key, tip, onChange)
    local row = CreateFrame("Button", nil, p); row:SetPoint("TOPLEFT", T.pad, y); row:SetSize(T.W, 20)
    local hl = row:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1,1,1,.07)
    local box = CreateFrame("CheckButton", nil, row); box:SetPoint("LEFT"); box:SetSize(16, 16)
    local bd = box:CreateTexture(nil, "BACKGROUND"); bd:SetPoint("TOPLEFT", -1, 1); bd:SetPoint("BOTTOMRIGHT", 1, -1); bd:SetColorTexture(.35,.35,.35,.8)
    local bg = box:CreateTexture(nil, "BORDER"); bg:SetAllPoints(); bg:SetColorTexture(.1,.1,.1,.92)
    local ck = box:CreateTexture(nil, "ARTWORK"); ck:SetPoint("TOPLEFT", 3, -3); ck:SetPoint("BOTTOMRIGHT", -3, 3)
    ck:SetColorTexture(T.check[1], T.check[2], T.check[3])
    box:SetCheckedTexture(ck); box:SetChecked(db[key] and true or false)
    local t = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("LEFT", box, "RIGHT", 6, 0); t:SetText(lbl); t:SetTextColor(T.text[1], T.text[2], T.text[3])
    local function upd() db[key] = box:GetChecked() and true or false; if onChange then onChange() end end
    local function toggle() box:SetChecked(not box:GetChecked()); upd() end
    row:SetScript("OnClick", toggle)
    box:SetScript("OnClick", function() upd() end)
    if tip then
        row:SetScript("OnEnter", function(s) GameTooltip:SetOwner(s,"ANCHOR_RIGHT"); GameTooltip:SetText(lbl,1,.82,0); GameTooltip:AddLine(tip,1,1,1,true); GameTooltip:Show() end)
        row:SetScript("OnLeave", GameTooltip.Hide)
    end
    return y - 22
end

local function SL(p, y, lbl, key, lo, hi, st, onChange)
    local f = CreateFrame("Frame", nil, p); f:SetPoint("TOPLEFT", T.pad, y); f:SetSize(T.W, 36)
    local t = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); t:SetPoint("TOPLEFT"); t:SetText(lbl); t:SetTextColor(T.text[1], T.text[2], T.text[3])
    local vt = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); vt:SetPoint("TOPRIGHT"); vt:SetTextColor(T.gold[1], T.gold[2], T.gold[3])
    -- Try MinimalSliderTemplate, fallback to basic Slider
    local ok, s = pcall(CreateFrame, "Slider", nil, f, "MinimalSliderTemplate")
    if not ok or not s then s = CreateFrame("Slider", nil, f) end
    s:SetPoint("TOPLEFT", 0, -16); s:SetSize(T.W, 14)
    pcall(function() s:SetMinMaxValues(lo, hi) end)
    pcall(function() s:SetValueStep(st) end)
    if s.SetObeyStepOnDrag then pcall(s.SetObeyStepOnDrag, s, true) end
    -- Thumb texture fallback if no template
    if not s:GetThumbTexture() then
        s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        s:SetBackdrop({bgFile = "Interface\\Buttons\\UI-SliderBar-Background"})
    end
    pcall(function() s:SetValue(db[key] or lo) end)
    vt:SetText(string.format("%.2g", db[key] or lo))
    s:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v / st + .5) * st; db[key] = v; vt:SetText(string.format("%.2g", v))
        if onChange then onChange(v) end
    end)
    return y - 40
end

-- ========================
--  DROPDOWN POPUP (defined BEFORE DD and FontDD)
-- ========================
local ddPopup, ddCloser
local function CloseDD()
    if ddCloser then ddCloser:Hide(); ddCloser = nil end
    if ddPopup then ddPopup:Hide(); ddPopup = nil end
end

local function ShowDD(anchor, vals, names, cur, onSelect, isFont)
    CloseDD()
    local RH = isFont and 24 or 22
    local maxR = 12
    local visH = math.min(#vals, maxR) * RH + 8
    local needScroll = #vals > maxR
    local popW = needScroll and 270 or 250

    ddCloser = CreateFrame("Button", nil, UIParent)
    ddCloser:SetAllPoints(); ddCloser:SetFrameStrata("TOOLTIP"); ddCloser:SetFrameLevel(900)
    ddCloser:SetScript("OnClick", CloseDD); ddCloser:EnableMouse(true); ddCloser:Show()

    ddPopup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    ddPopup:SetFrameStrata("TOOLTIP"); ddPopup:SetFrameLevel(910); ddPopup:SetClampedToScreen(true)
    ddPopup:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    ddPopup:SetBackdropColor(.1,.1,.1,.97); ddPopup:SetBackdropBorderColor(.35,.35,.35,1)
    ddPopup:SetSize(popW, visH); ddPopup:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2); ddPopup:EnableMouse(true)

    local parent, cW = ddPopup, popW - 8
    if needScroll then
        local sc = CreateFrame("ScrollFrame", nil, ddPopup, "UIPanelScrollFrameTemplate")
        sc:SetPoint("TOPLEFT", 3, -3); sc:SetPoint("BOTTOMRIGHT", -22, 3); sc:SetFrameLevel(912)
        local cnt = CreateFrame("Frame", nil, sc); cnt:SetSize(cW - 18, #vals * RH); sc:SetScrollChild(cnt)
        parent = cnt; cW = cW - 18
    end
    for i, val in ipairs(vals) do
        local row = CreateFrame("Button", nil, parent)
        row:SetSize(cW, RH); row:SetPoint("TOPLEFT", 2, -(i-1)*RH - 2)
        if not needScroll then row:SetFrameLevel(912) end
        local rhl = row:CreateTexture(nil, "HIGHLIGHT"); rhl:SetAllPoints(); rhl:SetColorTexture(.85,.65,.13,.22)
        if val == cur then
            local sel = row:CreateTexture(nil, "BACKGROUND"); sel:SetAllPoints(); sel:SetColorTexture(.85,.65,.13,.12)
            local chk = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); chk:SetPoint("RIGHT", -6, 0)
            chk:SetText("\226\156\148"); chk:SetTextColor(T.gold[1], T.gold[2], T.gold[3])
        end
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        if isFont then
            local fok = pcall(label.SetFont, label, val, 13, "OUTLINE")
            if not fok or not label:GetFont() then label:SetFontObject(GameFontHighlightSmall) end
        end
        label:SetPoint("LEFT", 8, 0); label:SetPoint("RIGHT", -24, 0); label:SetJustifyH("LEFT")
        label:SetText(names[val] or val or "?")
        if val == cur then label:SetTextColor(T.gold[1], T.gold[2], T.gold[3])
        else label:SetTextColor(.9,.9,.9) end
        row:SetScript("OnClick", function() onSelect(val); CloseDD() end)
    end
    ddPopup:Show()
end

-- ========================
--  DD (dropdown button) — ShowDD is already defined above
-- ========================
local function DD(p, y, lbl, key, vals, names, onChange)
    local f = CreateFrame("Frame", nil, p); f:SetPoint("TOPLEFT", T.pad, y); f:SetSize(T.W, 38)
    local t = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); t:SetPoint("TOPLEFT"); t:SetText(lbl); t:SetTextColor(T.text[1], T.text[2], T.text[3])
    local b = CreateFrame("Button", nil, f); b:SetPoint("TOPLEFT", 0, -15); b:SetSize(220, 22)
    local bbg = b:CreateTexture(nil, "BACKGROUND"); bbg:SetAllPoints(); bbg:SetColorTexture(.16,.16,.16,.9)
    local bbd = b:CreateTexture(nil, "BORDER"); bbd:SetPoint("TOPLEFT", -1, 1); bbd:SetPoint("BOTTOMRIGHT", 1, -1); bbd:SetColorTexture(.35,.35,.35,.8)
    b:SetNormalFontObject("GameFontHighlightSmall")
    local arr = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); arr:SetPoint("RIGHT", -8, 0)
    arr:SetTextColor(T.accent[1], T.accent[2], T.accent[3]); arr:SetText("\226\150\188")
    local function U()
        local display = names[db[key]] or db[key] or "?"
        b:SetText(display)
        local fs = b:GetFontString()
        if fs then fs:SetPoint("LEFT", 8, 0); fs:SetJustifyH("LEFT") end
    end
    U()
    b:SetScript("OnClick", function()
        ShowDD(b, vals, names, db[key], function(v) db[key] = v; U(); if onChange then onChange(v) end end)
    end)
    return y - 40
end

-- ========================
--  FONT DISCOVERY
-- ========================
local function GetAllFonts()
    local fonts, seen = {}, {}
    local BUILTIN = {
        {"Friz Quadrata","Fonts\\FRIZQT__.TTF"},{"Arial Narrow","Fonts\\ARIALN.TTF"},
        {"Morpheus","Fonts\\MORPHEUS.TTF"},{"Skurri","Fonts\\skurri.TTF"},
        {"2002","Fonts\\2002.TTF"},{"2002 Bold","Fonts\\2002B.TTF"},
    }
    for _, fv in ipairs(BUILTIN) do
        local ok = pcall(function() local fs = UIParent:CreateFontString(); fs:SetFont(fv[2], 12); fs:Hide() end)
        if ok then fonts[#fonts+1] = {name=fv[1], path=fv[2]}; seen[fv[2]:lower()] = true end
    end
    if LibStub then
        local LSM = LibStub("LibSharedMedia-3.0", true)
        if LSM then
            local sm = LSM:HashTable("font")
            if sm then for n, p in pairs(sm) do
                if not seen[p:lower()] then
                    local ok = pcall(function() local fs = UIParent:CreateFontString(); fs:SetFont(p, 12); fs:Hide() end)
                    if ok then fonts[#fonts+1] = {name=n, path=p}; seen[p:lower()] = true end
                end
            end end
        end
    end
    table.sort(fonts, function(a, b) return a.name:lower() < b.name:lower() end)
    return fonts
end

-- ========================
--  FONT DROPDOWN (with preview)
-- ========================
local function FontDD(p, y, key)
    local f = CreateFrame("Frame", nil, p); f:SetPoint("TOPLEFT", T.pad, y); f:SetSize(T.W, 54)
    local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); lbl:SetPoint("TOPLEFT")
    lbl:SetText(L.LBL_FONT); lbl:SetTextColor(T.text[1], T.text[2], T.text[3])
    local prev = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); prev:SetPoint("TOPRIGHT")
    prev:SetTextColor(T.gold[1], T.gold[2], T.gold[3])
    local b = CreateFrame("Button", nil, f); b:SetPoint("TOPLEFT", 0, -16); b:SetSize(T.W, 22)
    local fbbg = b:CreateTexture(nil, "BACKGROUND"); fbbg:SetAllPoints(); fbbg:SetColorTexture(.16,.16,.16,.9)
    local bbd = b:CreateTexture(nil, "BORDER"); bbd:SetPoint("TOPLEFT", -1, 1); bbd:SetPoint("BOTTOMRIGHT", 1, -1); bbd:SetColorTexture(.35,.35,.35,.8)
    b:SetNormalFontObject("GameFontHighlightSmall")
    local arr = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); arr:SetPoint("RIGHT", -8, 0)
    arr:SetTextColor(T.accent[1], T.accent[2], T.accent[3]); arr:SetText("\226\150\188")

    local function SetPrev()
        local path = db[key]
        if not path or path == "" then path = db.damageFont or D.damageFont end
        local ok = pcall(prev.SetFont, prev, path, 15, "OUTLINE")
        prev:SetText(ok and "123 AaBb" or "?")
    end
    local function U()
        local cur = db[key] or D[key] or ""
        if cur == "" then
            b:SetText(L.LBL_SAME_AS_DAMAGE)
        else
            local name = cur:match("([^\\]+)%.") or cur
            for _, fv in ipairs(GetAllFonts()) do if fv.path == cur then name = fv.name; break end end
            b:SetText(name)
        end
        local fs = b:GetFontString()
        if fs then fs:SetPoint("LEFT", 8, 0); fs:SetJustifyH("LEFT") end
        SetPrev()
    end
    U()
    b:SetScript("OnClick", function()
        local fonts = GetAllFonts()
        local vals, names = {}, {}
        for _, fv in ipairs(fonts) do vals[#vals+1] = fv.path; names[fv.path] = fv.name end
        ShowDD(b, vals, names, db[key] or D[key], function(v) db[key] = v; U(); ApplyFontCVars() end, true)
    end)
    return y - 46
end

-- ========================
--  BUILD OPTIONS PANEL
-- ========================
function BuildOptionsPanel()
    if optFrame then return end
    local f = CreateFrame("Frame", "NSCTOpts", UIParent, "BackdropTemplate")
    f:SetSize(420, 580); f:SetPoint("CENTER")
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG"); f:SetFrameLevel(100)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    f:SetBackdropColor(.08,.08,.08,.95); f:SetBackdropBorderColor(.30,.30,.30,1)
    table.insert(UISpecialFrames, "NSCTOpts")
    f:Hide()

    -- Title bar
    local titleTxt = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleTxt:SetPoint("TOPLEFT", 10, -8); titleTxt:SetText(L.TITLE); titleTxt:SetTextColor(T.gold[1], T.gold[2], T.gold[3])

    -- Close X
    local xb = CreateFrame("Button", nil, f, "BackdropTemplate")
    xb:SetSize(24, 24); xb:SetPoint("TOPRIGHT", -6, -4); xb:SetFrameLevel(f:GetFrameLevel() + 10)
    xb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    xb:SetBackdropColor(.15,.15,.15,.9); xb:SetBackdropBorderColor(.4,.4,.4,1)
    local xt = xb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); xt:SetPoint("CENTER"); xt:SetText("X")
    xb:SetScript("OnClick", function() f:Hide() end)
    xb:SetScript("OnEnter", function() xb:SetBackdropBorderColor(.8,.2,.2,1); xt:SetTextColor(1,.3,.3) end)
    xb:SetScript("OnLeave", function() xb:SetBackdropBorderColor(.4,.4,.4,1); xt:SetTextColor(.9,.9,.9) end)

    -- Scroll
    local sc = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sc:SetPoint("TOPLEFT", 6, -28); sc:SetPoint("BOTTOMRIGHT", -26, 6)
    local c = CreateFrame("Frame", nil, sc); c:SetSize(380, 1600); sc:SetScrollChild(c)
    local y = -8
    local AC = function() ApplyFontCVars() end
    local AO = function() ApplyFontObjects() end

    -- GENERAL
    y = Header(c, y, L.SEC_GENERAL)
    y = CB(c, y, L.LBL_ENABLE, "enabled", L.LBL_ENABLE_TIP)
    y = y - 6

    -- FONT & SCALE
    y = Header(c, y, L.SEC_FONT_SCALE)
    local hasND = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("NiceDamage")
    if not hasND then hasND = IsAddOnLoaded and IsAddOnLoaded("NiceDamage") end
    if hasND then
        y = Warn(c, y, L.WARN_ND_LOADED)
        y = Warn(c, y, L.WARN_ND_DISABLE)
    end
    y = Warn(c, y, L.WARN_FULL_RESTART)
    y = Warn(c, y, L.WARN_QUIT_GAME)
    y = FontDD(c, y, "damageFont")
    y = SL(c, y, L.LBL_TEXT_SCALE, "damageScale", 0.5, 5, 0.1, AC)
    y = DD(c, y, L.LBL_ANIM_STYLE, "floatMode", {"1","2","3"}, {["1"]=L.LBL_SCROLL_UP,["2"]=L.LBL_SCROLL_DOWN,["3"]=L.LBL_ARC}, AC)
    y = y - 6

    -- FONT ADVANCED
    y = Header(c, y, L.SEC_FONT_ADV)
    y = Warn(c, y, L.WARN_OUTLINE)
    y = Warn(c, y, L.WARN_UI_FONT)
    y = DD(c, y, L.LBL_FONT_OUTLINE, "fontOutline", {"OUTLINE","THICKOUTLINE","MONOCHROME","NONE"}, {OUTLINE=L.LBL_OUTLINE,THICKOUTLINE=L.LBL_THICK_OUTLINE,MONOCHROME=L.LBL_MONOCHROME,NONE=L.LBL_NONE}, AO)
    y = SL(c, y, L.LBL_FONT_SHADOW, "fontShadow", 0, 10, 1, AO)
    y = FontDD(c, y, "uiFont")
    y = Warn(c, y, L.WARN_UI_FONT_EMPTY)
    y = y - 6

    -- PHYSICS
    y = Header(c, y, L.SEC_PHYSICS)
    y = SL(c, y, L.LBL_GRAVITY, "textGravity", -10, 10, 0.5, AC)
    y = SL(c, y, L.LBL_RAMP_DURATION, "textRampDuration", 0.1, 3, 0.05, AC)
    y = SL(c, y, L.LBL_RAMP_POW, "rampPow", 0, 5, 0.1, AC)
    y = SL(c, y, L.LBL_RAMP_POW_CRIT, "rampPowCrit", 0, 5, 0.1, AC)
    y = SL(c, y, L.LBL_RANDOM_XY, "randomXY", 0, 100, 5, AC)
    y = y - 6

    -- FCT DISPLAY
    y = Header(c, y, L.SEC_FCT_DISPLAY)
    y = CB(c, y, L.LBL_DODGE_PARRY, "fctDodgeParryMiss", L.LBL_DODGE_PARRY_TIP, AC)
    y = CB(c, y, L.LBL_SPELL_MECH, "fctSpellMechanics", L.LBL_SPELL_MECH_TIP, AC)
    y = CB(c, y, L.LBL_AURAS, "fctAuras", L.LBL_AURAS_TIP, AC)
    y = CB(c, y, L.LBL_ALL_AUTOS, "fctAllAutos", L.LBL_ALL_AUTOS_TIP, AC)
    y = CB(c, y, L.LBL_COMBO_POINTS, "fctComboPoints", L.LBL_COMBO_POINTS_TIP, AC)
    y = CB(c, y, L.LBL_REACTIVES, "fctReactives", L.LBL_REACTIVES_TIP, AC)
    y = CB(c, y, L.LBL_DMG_REDUCTION, "fctDamageReduction", L.LBL_DMG_REDUCTION_TIP, AC)
    y = CB(c, y, L.LBL_LOW_HEALTH, "fctLowManaHealth", L.LBL_LOW_HEALTH_TIP, AC)
    y = CB(c, y, L.LBL_REP_CHANGES, "fctRepChanges", L.LBL_REP_CHANGES_TIP, AC)
    y = CB(c, y, L.LBL_HONOR_GAINS, "fctHonorGains", L.LBL_HONOR_GAINS_TIP, AC)
    y = y - 6

    -- SPELL ICONS
    y = Header(c, y, L.SEC_SPELL_ICONS)
    y = CB(c, y, L.LBL_SHOW_ICONS, "showIcon", L.LBL_SHOW_ICONS_TIP)
    y = SL(c, y, L.LBL_ICON_SCALE, "iconScale", 0.3, 3, 0.1)
    y = DD(c, y, L.LBL_ICON_POSITION, "iconPosition", {"LEFT","RIGHT","TOP","BOTTOM"}, {LEFT=L.LBL_LEFT,RIGHT=L.LBL_RIGHT,TOP=L.LBL_TOP,BOTTOM=L.LBL_BOTTOM})
    y = y - 2
    y = Header(c, y, L.SEC_ICON_ANIM)
    y = SL(c, y, L.LBL_ICON_OPACITY, "iconAlpha", 0.1, 1, 0.05)
    y = SL(c, y, L.LBL_ICON_DURATION, "iconDuration", 0.3, 3, 0.1)
    y = SL(c, y, L.LBL_FLOAT_SPEED, "floatSpeed", 0, 120, 5)
    y = SL(c, y, L.LBL_ICON_X, "iconOffsetX", -60, 60, 1)
    y = SL(c, y, L.LBL_ICON_Y, "iconOffsetY", -60, 60, 1)
    y = y - 8

    -- RESET
    local rb = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
    rb:SetPoint("TOPLEFT", T.pad, y); rb:SetSize(160, 26); rb:SetText(L.RESET_DEFAULTS)
    rb:SetScript("OnClick", function() for k, v in pairs(D) do NameplateSCTDB[k] = v end; ReloadUI() end)

    c:SetHeight(math.abs(y) + 60)
    optFrame = f
end

-- ========================
--  SETTINGS API (WoW AddOns menu)
-- ========================
function RegisterSettings()
    if optCatId then return end
    local sf = CreateFrame("Frame", nil, UIParent)
    sf:SetSize(400, 100)
    local info = sf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOPLEFT", 16, -16); info:SetText(L.TITLE); info:SetTextColor(T.gold[1], T.gold[2], T.gold[3])
    local desc = sf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", 16, -36); desc:SetText(L.SETTINGS_DESC)
    desc:SetTextColor(T.text[1], T.text[2], T.text[3])
    local btn = CreateFrame("Button", nil, sf, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", 16, -68); btn:SetSize(200, 28); btn:SetText(L.OPEN_OPTIONS)
    btn:SetScript("OnClick", function()
        if not optFrame then pcall(BuildOptionsPanel) end
        if optFrame then optFrame:Show() end
    end)
    local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, sf, "NameplateSCT")
    if ok and cat then pcall(Settings.RegisterAddOnCategory, cat); optCatId = cat:GetID() end
end

-- ========================
--  SLASH COMMANDS
-- ========================
local function OpenOpts()
    if not optFrame then
        local ok, err = pcall(BuildOptionsPanel)
        if not ok then print("|cFFFF0000[NSCT] " .. L.PANEL_ERROR .. "|r " .. tostring(err)) end
    end
    if optFrame then
        if optFrame:IsShown() then optFrame:Hide() else optFrame:Show() end
    end
end

SLASH_NSCT1 = "/nsct"
SlashCmdList["NSCT"] = function(msg)
    if not db then print("[NSCT] " .. L.NOT_READY); return end
    local cmd = (msg or ""):lower():match("^(%S*)")
    if cmd == "reset" then for k, v in pairs(D) do NameplateSCTDB[k] = v end; ReloadUI()
    else OpenOpts() end
end

SLASH_NSCTTEST1 = "/nscttest"
SlashCmdList["NSCTTEST"] = function()
    if not db then return end
    if C_NamePlate.GetNamePlateForUnit("target") then
        ShowSpellIcon("target"); print("[NSCT] " .. L.TEST_ICON)
    else print("[NSCT] " .. L.TARGET_MOB_FIRST) end
end

SLASH_NSCTDEBUG1 = "/nsctdebug"
SlashCmdList["NSCTDEBUG"] = function()
    print("|cFF00FF00=== NameplateSCT v3.1 Debug ===|r")
    print("  DB: " .. (db and "yes" or "|cFFFF0000NO|r") .. "  Enabled: " .. (db and db.enabled and "yes" or "no") .. "  Icons: " .. (db and db.showIcon and "yes" or "no"))
    print("  Events — UC:" .. (ucOk and "ok" or "FAIL") .. "  SP1:" .. (spOk1 and "ok" or "FAIL") .. "  SP2:" .. (spOk2 and "ok" or "FAIL") .. "  SP3:" .. (spOk3 and "ok" or "FAIL"))
    print("  Counters — Spells:" .. dbgSpellCount .. "  Combat:" .. dbgCombatCount .. "  Icons:" .. dbgIconCount)
    print("  Spell — ID:" .. tostring(lastSpellId or "-") .. "  Name:" .. tostring(lastSpellName or "-") .. "  Age:" .. (lastSpellTime and string.format("%.1fs", GetTime()-lastSpellTime) or "never"))
    print("  Panel:" .. (optFrame and "ok" or "NO") .. "  Settings:" .. (optCatId and "ok" or "standalone"))
    local fontMatch = (DAMAGE_TEXT_FONT == (db and db.damageFont)) and "|cFF00FF00match|r" or "|cFFFF0000OVERRIDDEN by another addon!|r"
    print("  Font — DAMAGE_TEXT_FONT=" .. tostring(DAMAGE_TEXT_FONT))
    print("  Font — db.damageFont=" .. tostring(db and db.damageFont or "nil") .. "  " .. fontMatch)
    print("  Nameplates: " .. #C_NamePlate.GetNamePlates())
end
