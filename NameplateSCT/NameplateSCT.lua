---------------
-- LIBRARIES --
---------------
local AceAddon = LibStub("AceAddon-3.0");
local LibEasing = LibStub("LibEasing-1.0");
local SharedMedia = LibStub("LibSharedMedia-3.0");

NameplateSCT = AceAddon:NewAddon("NameplateSCT", "AceConsole-3.0", "AceEvent-3.0");
NameplateSCT.frame = CreateFrame("Frame", nil, UIParent);


------------
-- LOCALS --
------------
local _;
local animating = {};

local playerGUID;
local unitToGuid = {};
local guidToUnit = {};

local targetFrames = {};
for level = 1, 3 do
    targetFrames[level] = CreateFrame("Frame", nil, UIParent);
end

local offTargetFrames = {};
for level = 1, 3 do
    offTargetFrames[level] = CreateFrame("Frame", nil, UIParent);
end


--------
-- DB --
--------
local defaultFont = "Friz Quadrata TT";
if (SharedMedia:IsValid("font", "Bazooka")) then
    defaultFont = "Bazooka";
end

local defaults = {
    global = {
        enabled = true,
        xOffset = 0,
        yOffset = 0,

        font = defaultFont,
        damageColor = true,
        defaultColor = "ffff00",

        truncate = true,
        truncateLetter = true,
        commaSeperate = true,

        sizing = {
            crits = true,
            critsScale = 1.5,

            smallHits = true,
            smallHitsScale = 0.66,
        },

        animations = {
            normal = "fountain",
            crit = "verticalUp",
            miss = "verticalUp",
        },

        formatting = {
            size = 20,
            icon = "right",
            alpha = 1,
        },

        useOffTarget = true,
        offTargetFormatting = {
            size = 15,
            icon = "right",
            alpha = 0.5,
        },
    },
};


---------------------
-- LOCAL CONSTANTS --
---------------------
local SMALL_HIT_EXPIRY_WINDOW = 30;
local SMALL_HIT_MULTIPIER = 0.5;

local ANIMATION_VERTICAL_DISTANCE = 75;

local ANIMATION_ARC_X_MIN = 50;
local ANIMATION_ARC_X_MAX = 150;
local ANIMATION_ARC_Y_TOP_MIN = 10;
local ANIMATION_ARC_Y_TOP_MAX = 50;
local ANIMATION_ARC_Y_BOTTOM_MIN = 10;
local ANIMATION_ARC_Y_BOTTOM_MAX = 50;

-- local ANIMATION_SHAKE_DEFLECTION = 15;
-- local ANIMATION_SHAKE_NUM_SHAKES = 4;

local ANIMATION_RAINFALL_X_MAX = 75;
local ANIMATION_RAINFALL_Y_MIN = 50;
local ANIMATION_RAINFALL_Y_MAX = 100;
local ANIMATION_RAINFALL_Y_START_MIN = 5
local ANIMATION_RAINFALL_Y_START_MAX = 15;

local ANIMATION_LENGTH = 1;

local DAMAGE_TYPE_COLORS = {
    [SCHOOL_MASK_PHYSICAL] = "FFFF00",
    [SCHOOL_MASK_HOLY] = "FFE680",
    [SCHOOL_MASK_FIRE] = "FF8000",
    [SCHOOL_MASK_NATURE] = "4DFF4D",
    [SCHOOL_MASK_FROST] = "80FFFF",
    [SCHOOL_MASK_SHADOW] = "8080FF",
    [SCHOOL_MASK_ARCANE] = "FF80FF",
};

local MISS_EVENT_STRINGS = {
    ["ABSORB"] = "Absorbed",
    ["BLOCK"] = "Blocked",
    ["DEFLECT"] = "Deflected",
    ["DODGE"] = "Dodged",
    ["EVADE"] = "Evaded",
    ["IMMUNE"] = "Immune",
    ["MISS"] = "Missed",
    ["PARRY"] = "Parried",
    ["REFLECT"] = "Reflected",
    ["RESIST"] = "Resisted",
};

local FRAME_LEVEL_OVERLAY = 3;
local FRAME_LEVEL_ABOVE = 2;
local FRAME_LEVEL_BELOW = 1;


----------------
-- FONTSTRING --
----------------
local function getFontPath(fontName)
    local fontPath = SharedMedia:Fetch("font", fontName);

    if (fontPath == nil) then
        fontPath = "Fonts\\FRIZQT__.TTF";
    end

    return fontPath;
end

local fontStringCache = {};
local function getFontString()
    local fontString;

    if (next(fontStringCache)) then
        fontString = table.remove(fontStringCache);
    else
        fontString = NameplateSCT.frame:CreateFontString();
    end

    fontString:SetParent(NameplateSCT.frame);
    fontString:SetFont(getFontPath(NameplateSCT.db.global.font), 15, "OUTLINE");
    fontString:SetAlpha(1);
    fontString:SetDrawLayer("OVERLAY");
    fontString:SetText("");
    fontString:Show();

    return fontString;
end

local function recycleFontString(fontString)
    fontString:SetAlpha(0);
    fontString:Hide();

    animating[fontString] = nil;

    fontString.distance = nil;
    fontString.arcTop = nil;
    fontString.arcBottom = nil;
    fontString.arcXDist = nil;
    fontString.deflection = nil;
    fontString.numShakes = nil;
    fontString.animation = nil;
    fontString.animatingDuration = nil;
    fontString.animatingStartTime = nil;
    fontString.anchorFrame = nil;

    fontString.unit = nil;
    fontString.guid = nil;

    fontString.pow = nil;
    fontString.startHeight = nil;
    fontString.NSCTFontSize = nil;
    fontString:SetFont(getFontPath(NameplateSCT.db.global.font), 15, "OUTLINE");

    fontString:SetParent(NameplateSCT.frame);

    table.insert(fontStringCache, fontString);
end


----------------
-- NAMEPLATES --
----------------
local nameplatePositionTicker;
local guidNameplatePositionX = {}; -- why two tables? Because creating tables creates garbage, at least that's the idea
local guidNameplatePositionY = {};
local function saveNameplatePositions_Awful()
    -- look, this isn't a good way of doing this, but it's quick and easy and I don't
    -- understand why GetCenter of the nameplate isn't actually where it is and why I can't
    -- figure out how to scale it properly with GetEffectiveScale or whatever
    local fontString = getFontString();

    for unit, guid in pairs(unitToGuid) do
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit);
        if (nameplate and not UnitIsDead(unit) and nameplate:IsShown()) then
            fontString:SetPoint("CENTER", nameplate, "CENTER", 0, 0);
            guidNameplatePositionX[guid], guidNameplatePositionY[guid] = fontString:GetCenter();
        end
    end

    recycleFontString(fontString);
end

local function startSavingNameplatePositions()
    if (not nameplatePositionTicker) then
        nameplatePositionTicker =  C_Timer.NewTicker(1/10, saveNameplatePositions_Awful);
    end
end

local function stopSavingNameplatePositions()
    nameplatePositionTicker:Cancel();
    nameplatePositionTicker = nil;
end

-- NameplateSCT.SaveNameplatePositions_Awful = saveNameplatePositions_Awful;

--[[ this should work for reasonable nameplate systems, but doesn't work with a bunch of them -.-
local function setNameplateFrameLevels()
    local targetStrata;
    local offTargetStrata;
    local targetFrameLevel;
    local offTargetFrameLevelLow;
    local offTargetFrameLevelHigh;

    -- get strata/framelevels for target and max for offtargets
    for unit, guid in pairs(unitToGuid) do
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit);
        if (nameplate and not UnitIsDead(unit) and nameplate:IsShown()) then
            local nameplateFrame = _G[nameplate:GetName().."UnitFrame"];

            if (nameplateFrame) then
                if (UnitIsUnit("target", unit)) then
                    targetStrata = nameplateFrame:GetFrameStrata();
                    targetFrameLevel = nameplateFrame:GetFrameLevel();
                else
                    offTargetStrata = nameplateFrame:GetFrameStrata();

                    local frameLevel = nameplateFrame:GetFrameLevel();
                    if (not offTargetFrameLevelHigh or offTargetFrameLevelHigh < frameLevel) then
                        offTargetFrameLevelHigh = frameLevel;
                    end

                    if (not offTargetFrameLevelLow or offTargetFrameLevelLow < frameLevel) then
                        offTargetFrameLevelLow = frameLevel;
                    end
                end
            end
        end
    end

    if (targetStrata and targetFrameLevel) then
        local lowFrameLevel = targetFrameLevel - 1;
        if (lowFrameLevel < 0) then
            lowFrameLevel = 0;
        end

        for _, frame in pairs(targetFrames) do
            frame:SetFrameStrata(targetStrata);
        end
        targetFrames[FRAME_LEVEL_OVERLAY]:SetFrameLevel(targetFrameLevel + 4);
        targetFrames[FRAME_LEVEL_ABOVE]:SetFrameLevel(targetFrameLevel + 3);
        targetFrames[FRAME_LEVEL_BELOW]:SetFrameLevel(lowFrameLevel);
    end

    if (offTargetStrata and offTargetFrameLevelHigh and offTargetFrameLevelLow) then
        local lowFrameLevel = offTargetFrameLevelLow - 2;
        if (lowFrameLevel < 0) then
            lowFrameLevel = 0;
        end

        for _, frame in pairs(offTargetFrames) do
            frame:SetFrameStrata(offTargetStrata);
        end
        offTargetFrames[FRAME_LEVEL_OVERLAY]:SetFrameLevel(offTargetFrameLevelHigh + 2);
        offTargetFrames[FRAME_LEVEL_ABOVE]:SetFrameLevel(offTargetFrameLevelHigh + 1);
        offTargetFrames[FRAME_LEVEL_BELOW]:SetFrameLevel(lowFrameLevel);
    end
end
]]--

local function setNameplateFrameLevels()
    for _, frame in pairs(targetFrames) do
        frame:SetFrameStrata("LOW");
    end
    targetFrames[FRAME_LEVEL_OVERLAY]:SetFrameLevel(1001);
    targetFrames[FRAME_LEVEL_ABOVE]:SetFrameLevel(1000);
    targetFrames[FRAME_LEVEL_BELOW]:SetFrameLevel(999);

    for _, frame in pairs(offTargetFrames) do
        frame:SetFrameStrata("LOW");
    end
    offTargetFrames[FRAME_LEVEL_OVERLAY]:SetFrameLevel(901);
    offTargetFrames[FRAME_LEVEL_ABOVE]:SetFrameLevel(900);
    offTargetFrames[FRAME_LEVEL_BELOW]:SetFrameLevel(899);
end

----------
-- CORE --
----------
function NameplateSCT:OnInitialize()
    -- setup db
    self.db = LibStub("AceDB-3.0"):New("NameplateSCTDB", defaults, true);

    -- setup chat commands
    self:RegisterChatCommand("nsct", "OpenMenu");

    -- setup menu
    self:RegisterMenu();

    setNameplateFrameLevels();

    -- if the addon is turned off in db, turn it off
    if (self.db.global.enabled == false) then
        self:Disable();
    end
end

function NameplateSCT:OnEnable()
    playerGUID = UnitGUID("player");

    self:RegisterEvent("NAME_PLATE_UNIT_ADDED");
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");

    self.db.global.enabled = true;
end

function NameplateSCT:OnDisable()
    self:UnregisterAllEvents();

    for fontString, _ in pairs(animating) do
        recycleFontString(fontString);
    end

    self.db.global.enabled = false;
end


---------------
-- ANIMATION --
---------------
local function verticalPath(elapsed, duration, distance)
    return 0, LibEasing.InQuad(elapsed, 0, distance, duration);
end

local function arcPath(elapsed, duration, xDist, yStart, yTop, yBottom)
    local x, y;
    local progress = elapsed/duration;

    x = progress * xDist;

    -- progress 0 to 1
    -- at progress 0, y = yStart
    -- at progress 0.5 y = yTop
    -- at progress 1 y = yBottom

    -- -0.25a + .5b + yStart = yTop
    -- -a + b + yStart = yBottom

    -- -0.25a + .5b + yStart = yTop
    -- .5b + yStart - yTop = 0.25a
    -- 2b + 4yStart - 4yTop = a

    -- -(2b + 4yStart - 4yTop) + b + yStart = yBottom
    -- -2b - 4yStart + 4yTop + b + yStart = yBottom
    -- -b - 3yStart + 4yTop = yBottom

    -- -3yStart + 4yTop - yBottom = b

    -- 2(-3yStart + 4yTop - yBottom) + 4yStart - 4yTop = a
    -- -6yStart + 8yTop - 2yBottom + 4yStart - 4yTop = a
    -- -2yStart + 4yTop - 2yBottom = a

    -- -3yStart + 4yTop - yBottom = b
    -- -2yStart + 4yTop - 2yBottom = a

    local a = -2 * yStart + 4 * yTop - 2 * yBottom;
    local b = -3 * yStart + 4 * yTop - yBottom;

    y = -a * math.pow(progress, 2) + b * progress + yStart;

    return x, y;
end

local function powSizing(elapsed, duration, start, middle, finish)
    local size = finish;
    if (elapsed < duration) then
        if (elapsed/duration < 0.5) then
            size = LibEasing.OutQuint(elapsed, start, middle - start, duration/2);
        else
            size = LibEasing.InQuint(elapsed - elapsed/2, middle, finish - middle, duration/2);
        end
    end
    return size;
end

local function AnimationOnUpdate()
    if (next(animating)) then
        -- setNameplateFrameLevels();

        for fontString, _ in pairs(animating) do
            local elapsed = GetTime() - fontString.animatingStartTime;
            if (elapsed > fontString.animatingDuration) then
                -- the animation is over
                recycleFontString(fontString);
            else
                local isTarget = UnitIsUnit(fontString.unit, "target");

                -- frame level
                if (fontString.frameLevel) then
                    if (isTarget) then
                        if (fontString:GetParent() ~= targetFrames[fontString.frameLevel]) then
                            fontString:SetParent(targetFrames[fontString.frameLevel])
                        end
                    else
                        if (fontString:GetParent() ~= offTargetFrames[fontString.frameLevel]) then
                            fontString:SetParent(offTargetFrames[fontString.frameLevel])
                        end
                    end
                end

                -- alpha
                local startAlpha = NameplateSCT.db.global.formatting.alpha;
                if (NameplateSCT.db.global.useOffTarget and not isTarget) then
                    startAlpha = NameplateSCT.db.global.offTargetFormatting.alpha;
                end

                local alpha = LibEasing.InExpo(elapsed, startAlpha, -startAlpha, fontString.animatingDuration);
                fontString:SetAlpha(alpha);

                -- sizing
                if (fontString.pow) then
                    if (elapsed < fontString.animatingDuration/6) then
                        fontString:SetText(fontString.NSCTTextWithoutIcons);

                        local size = powSizing(elapsed, fontString.animatingDuration/6, fontString.startHeight/2, fontString.startHeight*2, fontString.startHeight);
                        fontString:SetTextHeight(size);
                    else
                        fontString.pow = nil;
                        fontString:SetTextHeight(fontString.startHeight);
                        fontString:SetFont(getFontPath(NameplateSCT.db.global.font), fontString.NSCTFontSize, "OUTLINE");
                        fontString:SetText(fontString.NSCTText);
                    end
                end

                -- position
                local xOffset, yOffset = 0, 0;
                if (fontString.animation == "verticalUp") then
                    xOffset, yOffset = verticalPath(elapsed, fontString.animatingDuration, fontString.distance);
                elseif (fontString.animation == "verticalDown") then
                    xOffset, yOffset = verticalPath(elapsed, fontString.animatingDuration, -fontString.distance);
                elseif (fontString.animation == "fountain") then
                    xOffset, yOffset = arcPath(elapsed, fontString.animatingDuration, fontString.arcXDist, 0, fontString.arcTop, fontString.arcBottom);
                elseif (fontString.animation == "rainfall") then
                    _, yOffset = verticalPath(elapsed, fontString.animatingDuration, -fontString.distance);
                    xOffset = fontString.rainfallX;
                    yOffset = yOffset + fontString.rainfallStartY;
                -- elseif (fontString.animation == "shake") then
                    -- TODO
                end

                if (not UnitIsDead(fontString.unit) and fontString.anchorFrame and fontString.anchorFrame:IsShown()) then
                    fontString:SetPoint("CENTER", fontString.anchorFrame, "CENTER", NameplateSCT.db.global.xOffset + xOffset, NameplateSCT.db.global.yOffset + yOffset);

                    -- remember the last position of the nameplate
                    local x, y = fontString:GetCenter();
                    guidNameplatePositionX[fontString.guid] = x - (NameplateSCT.db.global.xOffset + xOffset);
                    guidNameplatePositionY[fontString.guid] = y - (NameplateSCT.db.global.yOffset + yOffset);
                elseif (guidNameplatePositionX[fontString.guid] and guidNameplatePositionY[fontString.guid]) then
                    fontString.anchorFrame = nil;
                    fontString:ClearAllPoints();
                    fontString:SetPoint("CENTER", UIParent, "BOTTOMLEFT", guidNameplatePositionX[fontString.guid] + NameplateSCT.db.global.xOffset + xOffset, guidNameplatePositionY[fontString.guid] + NameplateSCT.db.global.yOffset + yOffset);
                else
                    recycleFontString(fontString);
                end
            end
        end
    else
        -- nothing in the animation list, so just kill the onupdate
        NameplateSCT.frame:SetScript("OnUpdate", nil);
    end
end

-- NameplateSCT.AnimationOnUpdate = AnimationOnUpdate;

local arcDirection = 1;
function NameplateSCT:Animate(fontString, anchorFrame, duration, animation)
    animation = animation or "verticalUp";

    fontString.animation = animation;
    fontString.animatingDuration = duration;
    fontString.animatingStartTime = GetTime();
    fontString.anchorFrame = anchorFrame;

    if (animation == "verticalUp") then
        fontString.distance = ANIMATION_VERTICAL_DISTANCE;
    elseif (animation == "verticalDown") then
        fontString.distance = ANIMATION_VERTICAL_DISTANCE;
    elseif (animation == "fountain") then
        fontString.arcTop = math.random(ANIMATION_ARC_Y_TOP_MIN, ANIMATION_ARC_Y_TOP_MAX);
        fontString.arcBottom = -math.random(ANIMATION_ARC_Y_BOTTOM_MIN, ANIMATION_ARC_Y_BOTTOM_MAX);
        fontString.arcXDist = arcDirection * math.random(ANIMATION_ARC_X_MIN, ANIMATION_ARC_X_MAX);

        arcDirection = arcDirection * -1;
    elseif (animation == "rainfall") then
        fontString.distance = math.random(ANIMATION_RAINFALL_Y_MIN, ANIMATION_RAINFALL_Y_MAX);
        fontString.rainfallX = math.random(-ANIMATION_RAINFALL_X_MAX, ANIMATION_RAINFALL_X_MAX);
        fontString.rainfallStartY = -math.random(ANIMATION_RAINFALL_Y_START_MIN, ANIMATION_RAINFALL_Y_START_MAX);
    -- elseif (animation == "shake") then
    --     fontString.deflection = ANIMATION_SHAKE_DEFLECTION;
    --     fontString.numShakes = ANIMATION_SHAKE_NUM_SHAKES;
    end

    animating[fontString] = true;

    -- start onupdate if it's not already running
    if (NameplateSCT.frame:GetScript("OnUpdate") == nil) then
        NameplateSCT.frame:SetScript("OnUpdate", AnimationOnUpdate);
    end
end


------------
-- EVENTS --
------------
local guidDeletion = {};
local function scheduleGUIDNameplatePositionWipe(guid)
    local deleteGUIDLocation = function()
        guidNameplatePositionX[guid] = nil;
        guidNameplatePositionY[guid] = nil;
    end

    guidDeletion[guid] = C_Timer.NewTimer(1, deleteGUIDLocation);
end

function NameplateSCT:NAME_PLATE_UNIT_ADDED(event, unitID)
    local guid = UnitGUID(unitID);

    unitToGuid[unitID] = guid;
    guidToUnit[guid] = unitID;

    if (guidDeletion[guid]) then
        guidDeletion[guid]:Cancel();
    end

    guidNameplatePositionX[guid] = nil;
    guidNameplatePositionY[guid] = nil;

    startSavingNameplatePositions();
end

function NameplateSCT:NAME_PLATE_UNIT_REMOVED(event, unitID)
    local guid = unitToGuid[unitID];

    unitToGuid[unitID] = nil;
    guidToUnit[guid] = nil;

    scheduleGUIDNameplatePositionWipe(guid);

    -- stop saving positions if there are no nameplates
    if (not next(guidToUnit)) then
        stopSavingNameplatePositions();
    end
end

function NameplateSCT:COMBAT_LOG_EVENT_UNFILTERED(event, time, cle, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    -- only use player events (or their pet/guardian)
    if ((playerGUID == sourceGUID)
        or (((bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) > 0) or (bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PET) > 0)) and bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0)) then
        local destUnit = guidToUnit[destGUID];

        if (destUnit) then
            if (string.find(cle, "_DAMAGE")) then
                local spellID, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand;

                if (string.find(cle, "SWING")) then
                    spellName, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = "melee", ...;
                else
                    spellID, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = ...;
                end

                self:DamageEvent(destGUID, spellID, amount, school, critical);
            elseif(string.find(cle, "_MISSED")) then
                local spellID, spellName, spellSchool, missType, isOffHand, amountMissed;

                if (string.find(cle, "SWING")) then
                    missType, isOffHand, amountMissed = "melee", ...;
                else
                    spellID, spellName, spellSchool, missType, isOffHand, amountMissed = ...;
                end

                self:MissEvent(destGUID, spellID, missType);
            end
        end
    end
end


-------------
-- DISPLAY --
-------------
local function commaSeperate(number)
    -- https://stackoverflow.com/questions/10989788/lua-format-integer
    local _, _, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)');
    int = int:reverse():gsub("(%d%d%d)", "%1,");
    return minus..int:reverse():gsub("^,", "")..fraction;
end

local numDamageEvents = 0;
local lastDamageEventTime;
local runningAverageDamageEvents = 0;
function NameplateSCT:DamageEvent(guid, spellID, amount, school, crit)
    local text, textWithoutIcons, animation, pow, size, icon, alpha;
    local frameLevel = FRAME_LEVEL_ABOVE;

    local unit = guidToUnit[guid];
    local isTarget = unit and UnitIsUnit(unit, "target");

    if (self.db.global.useOffTarget and not isTarget) then
        size = self.db.global.offTargetFormatting.size;
        icon = self.db.global.offTargetFormatting.icon;
        alpha = self.db.global.offTargetFormatting.alpha;
    else
        size = self.db.global.formatting.size;
        icon = self.db.global.formatting.icon;
        alpha = self.db.global.formatting.alpha;
    end

    -- select an animation
    if (crit) then
        frameLevel = FRAME_LEVEL_OVERLAY;
        animation = self.db.global.animations.crit;
        pow = true;
    else
        animation = self.db.global.animations.normal;
        pow = false;
    end

    if (icon ~= "only") then
        -- truncate
        if (self.db.global.truncate and amount >= 1000000 and self.db.global.truncateLetter) then
            text = string.format("%.1fM", amount / 1000000);
        elseif (self.db.global.truncate and amount >= 1000) then
            text = string.format("%.0f", amount / 1000);

            if (self.db.global.truncateLetter) then
                text = text.."k";
            end
        else
            if (self.db.global.commaSeperate) then
                text = commaSeperate(amount);
            else
                text = tostring(amount);
            end
        end

        -- color text
        if (self.db.global.damageColor and school and DAMAGE_TYPE_COLORS[school]) then
            text = "|Cff"..DAMAGE_TYPE_COLORS[school]..text.."|r";
        else
            text = "|Cff"..self.db.global.defaultColor..text.."|r";
        end

        -- add icons
        textWithoutIcons = text;
        if (icon ~= "none" and spellID) then
            local iconText = "|T"..GetSpellTexture(spellID)..":0|t";

            if (icon == "both") then
                text = iconText..text..iconText;
            elseif (icon == "left") then
                text = iconText..text;
            elseif (icon == "right") then
                text = text..iconText;
            end
        end
    else
        -- showing only icons
        if (not spellID) then
            return;
        end

        text = "|T"..GetSpellTexture(spellID)..":0|t";
        textWithoutIcons = text; -- since the icon is by itself, the fontString won't have the strange scaling bug
    end

    -- shrink small hits
    if (self.db.global.sizing.smallHits) then
        if (not lastDamageEventTime or (lastDamageEventTime + SMALL_HIT_EXPIRY_WINDOW < GetTime())) then
            numDamageEvents = 0;
            runningAverageDamageEvents = 0;
        end

        runningAverageDamageEvents = ((runningAverageDamageEvents*numDamageEvents) + amount)/(numDamageEvents + 1);
        numDamageEvents = numDamageEvents + 1;
        lastDamageEventTime = GetTime();

        if ((not crit and amount < SMALL_HIT_MULTIPIER*runningAverageDamageEvents)
            or (crit and amount/2 < SMALL_HIT_MULTIPIER*runningAverageDamageEvents)) then
            size = size * self.db.global.sizing.smallHitsScale;
        end
    end

    -- embiggen crit's size
    if (self.db.global.sizing.crits and crit) then
        size = size * self.db.global.sizing.critsScale;
    end

    -- make sure that size is larger than 5
    if (size < 5) then
        size = 5;
    end

    self:DisplayText(guid, text, textWithoutIcons, size, animation, frameLevel, pow);
end

function NameplateSCT:MissEvent(guid, spellID, missType)
    local text, animation, pow, size, icon, alpha;

    local unit = guidToUnit[guid];
    local isTarget = unit and UnitIsUnit(unit, "target");

    if (self.db.global.useOffTarget and not isTarget) then
        size = self.db.global.offTargetFormatting.size;
        icon = self.db.global.offTargetFormatting.icon;
        alpha = self.db.global.offTargetFormatting.alpha;
    else
        size = self.db.global.formatting.size;
        icon = self.db.global.formatting.icon;
        alpha = self.db.global.formatting.alpha;
    end

    if (icon == "only") then
        return;
    end

    animation = self.db.global.animations.miss;
    pow = true;

    text = MISS_EVENT_STRINGS[missType] or "Missed";
    text = "|Cff"..self.db.global.defaultColor..text.."|r";

    -- add icons
    local textWithoutIcons = text;
    if (icon ~= "none" and spellID) then
        local iconText = "|T"..GetSpellTexture(spellID)..":0|t";

        if (icon == "both") then
            text = iconText..text..iconText;
        elseif (icon == "left") then
            text = iconText..text;
        elseif (icon == "right") then
            text = text..iconText;
        end
    end

    self:DisplayText(guid, text, textWithoutIcons, size, animation, FRAME_LEVEL_ABOVE, pow)
end

function NameplateSCT:DisplayText(guid, text, textWithoutIcons, size, animation, frameLevel, pow)
    local fontString;
    local unit = guidToUnit[guid];
    local nameplate;

    if (unit) then
        nameplate = C_NamePlate.GetNamePlateForUnit(unit);
    end

    -- if there isn't an anchor frame, make sure that there is a guidNameplatePosition cache entry
    if (not nameplate and not (guidNameplatePositionX[guid] and guidNameplatePositionY[guid])) then
        return;
    end

    fontString = getFontString();

    fontString.NSCTText = text;
    fontString.NSCTTextWithoutIcons = textWithoutIcons;
    fontString:SetText(fontString.NSCTText);

    fontString.NSCTFontSize = size;
    fontString:SetFont(getFontPath(NameplateSCT.db.global.font), fontString.NSCTFontSize, "OUTLINE");
    fontString.startHeight = fontString:GetStringHeight();
    fontString.pow = pow;
    fontString.frameLevel = frameLevel;

    if (fontString.startHeight <= 0) then
        fontString.startHeight = 5;
    end

    fontString.unit = unit;
    fontString.guid = guid;

    -- if there is no nameplate,
    self:Animate(fontString, nameplate, ANIMATION_LENGTH, animation);
end


-------------
-- OPTIONS --
-------------
local function rgbToHex(r, g, b)
    return string.format("%02x%02x%02x", math.floor(255 * r), math.floor(255 * g), math.floor(255 * b));
end

local function hexToRGB(hex)
    return tonumber(hex:sub(1,2), 16)/255, tonumber(hex:sub(3,4), 16)/255, tonumber(hex:sub(5,6), 16)/255, 1;
end

local iconValues = {
    ["none"] = "No Icons",
    ["left"] = "Left Side",
    ["right"] = "Right Side",
    ["both"] = "Both Sides",
    ["only"] = "Icons Only (No Text)",
};

local animationValues = {
    -- ["shake"] = "Shake",
    ["verticalUp"] = "Vertical Up",
    ["verticalDown"] = "Vertical Down",
    ["fountain"] = "Fountain",
    ["rainfall"] = "Rainfall",
};

local menu = {
    name = "NameplateSCT",
    handler = NameplateSCT,
    type = 'group',
    args = {
        enable = {
            type = 'toggle',
            name = "Enable",
            desc = "If the addon is enabled.",
            get = "IsEnabled",
            set = function(_, newValue) if (not newValue) then NameplateSCT:Disable(); else NameplateSCT:Enable(); end end,
            order = 1,
            width = "half",
        },

        disableBlizzardFCT = {
            type = 'toggle',
            name = "Disable Blizzard FCT",
            desc = "",
            get = function(_, newValue) return GetCVar("floatingCombatTextCombatDamage") == "0" end,
            set = function(_, newValue)
                if (newValue) then
                    SetCVar("floatingCombatTextCombatDamage", "0");
                else
                    SetCVar("floatingCombatTextCombatDamage", "1");
                end
            end,
            order = 2,
        },

        animations = {
            type = 'group',
            name = "Animations",
            order = 30,
            inline = true,
            disabled = function() return not NameplateSCT.db.global.enabled; end;
            args = {
                normal = {
                    type = 'select',
                    name = "Default",
                    desc = "",
                    get = function() return NameplateSCT.db.global.animations.normal; end,
                    set = function(_, newValue) NameplateSCT.db.global.animations.normal = newValue; end,
                    values = animationValues,
                    order = 1,
                },
                crit = {
                    type = 'select',
                    name = "Criticals",
                    desc = "",
                    get = function() return NameplateSCT.db.global.animations.crit; end,
                    set = function(_, newValue) NameplateSCT.db.global.animations.crit = newValue; end,
                    values = animationValues,
                    order = 2,
                },
                miss = {
                    type = 'select',
                    name = "Miss/Parry/Dodge/etc",
                    desc = "",
                    get = function() return NameplateSCT.db.global.animations.miss; end,
                    set = function(_, newValue) NameplateSCT.db.global.animations.miss = newValue; end,
                    values = animationValues,
                    order = 3,
                },
            },
        },

        appearance = {
            type = 'group',
            name = "Appearance/Offsets",
            order = 50,
            inline = true,
            disabled = function() return not NameplateSCT.db.global.enabled; end;
            args = {
                font = {
                    type = "select",
                    dialogControl = "LSM30_Font",
                    name = "Font",
                    order = 1,
                    values = AceGUIWidgetLSMlists.font,
                    get = function() return NameplateSCT.db.global.font; end,
                    set = function(_, newValue) NameplateSCT.db.global.font = newValue; end,
                },

                damageColor = {
                    type = 'toggle',
                    name = "Use Damage Type Color",
                    desc = "",
                    get = function() return NameplateSCT.db.global.damageColor; end,
                    set = function(_, newValue) NameplateSCT.db.global.damageColor = newValue; end,
                    order = 2,
                },

                defaultColor = {
                    type = 'color',
                    name = "Default Color",
                    desc = "",
                    hasAlpha = false,
                    set = function(_, r, g, b) NameplateSCT.db.global.defaultColor = rgbToHex(r, g, b); end,
                    get = function() return hexToRGB(NameplateSCT.db.global.defaultColor); end,
                    order = 3,
                },

                xOffset = {
                    type = 'range',
                    name = "X Offset",
                    desc = "Has soft max/min, you can type whatever you'd like into the editbox",
                    softMin = -75,
                    softMax = 75,
                    step = 1,
                    get = function() return NameplateSCT.db.global.xOffset; end,
                    set = function(_, newValue) NameplateSCT.db.global.xOffset = newValue; end,
                    order = 10,
                    width = "full",
                },

                yOffset = {
                    type = 'range',
                    name = "Y Offset",
                    desc = "Has soft max/min, you can type whatever you'd like into the editbox",
                    softMin = -75,
                    softMax = 75,
                    step = 1,
                    get = function() return NameplateSCT.db.global.yOffset; end,
                    set = function(_, newValue) NameplateSCT.db.global.yOffset = newValue; end,
                    order = 11,
                    width = "full",
                },
            },
        },

        formatting = {
            type = 'group',
            name = "Text Formatting",
            order = 90,
            inline = true,
            disabled = function() return not NameplateSCT.db.global.enabled; end;
            args = {
                truncate = {
                    type = 'toggle',
                    name = "Truncate Number",
                    desc = "",
                    get = function() return NameplateSCT.db.global.truncate; end,
                    set = function(_, newValue) NameplateSCT.db.global.truncate = newValue; end,
                    order = 1,
                },
                truncateLetter = {
                    type = 'toggle',
                    name = "Show Truncated Letter",
                    desc = "",
                    disabled = function() return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.truncate; end,
                    get = function() return NameplateSCT.db.global.truncateLetter; end,
                    set = function(_, newValue) NameplateSCT.db.global.truncateLetter = newValue; end,
                    order = 2,
                },
                commaSeperate = {
                    type = 'toggle',
                    name = "Comma Seperate",
                    desc = "100000 -> 100,000",
                    disabled = function() return not NameplateSCT.db.global.enabled or NameplateSCT.db.global.truncate; end,
                    get = function() return NameplateSCT.db.global.commaSeperate; end,
                    set = function(_, newValue) NameplateSCT.db.global.commaSeperate = newValue; end,
                    order = 3,
                },

                icon = {
                    type = 'select',
                    name = "Icon",
                    desc = "",
                    get = function() return NameplateSCT.db.global.formatting.icon; end,
                    set = function(_, newValue) NameplateSCT.db.global.formatting.icon = newValue; end,
                    values = iconValues,
                    order = 51,
                },
                size = {
                    type = 'range',
                    name = "Size",
                    desc = "",
                    min = 5,
                    max = 72,
                    step = 1,
                    get = function() return NameplateSCT.db.global.formatting.size; end,
                    set = function(_, newValue) NameplateSCT.db.global.formatting.size = newValue; end,
                    order = 52,
                },
                alpha = {
                    type = 'range',
                    name = "Start Alpha",
                    desc = "",
                    min = 0.1,
                    max = 1,
                    step = .01,
                    get = function() return NameplateSCT.db.global.formatting.alpha; end,
                    set = function(_, newValue) NameplateSCT.db.global.formatting.alpha = newValue; end,
                    order = 53,
                },

                useOffTarget = {
                    type = 'toggle',
                    name = "Use Seperate Off-Target Text Appearance",
                    desc = "",
                    get = function() return NameplateSCT.db.global.useOffTarget; end,
                    set = function(_, newValue) NameplateSCT.db.global.useOffTarget = newValue; end,
                    order = 100,
                    width = "full",
                },
                offTarget = {
                    type = 'group',
                    name = "Off-Target Text Appearance",
                    hidden = function() return not NameplateSCT.db.global.useOffTarget; end,
                    order = 101,
                    inline = true,
                    args = {
                        icon = {
                            type = 'select',
                            name = "Icon",
                            desc = "",
                            get = function() return NameplateSCT.db.global.offTargetFormatting.icon; end,
                            set = function(_, newValue) NameplateSCT.db.global.offTargetFormatting.icon = newValue; end,
                            values = iconValues,
                            order = 1,
                        },
                        size = {
                            type = 'range',
                            name = "Size",
                            desc = "",
                            min = 5,
                            max = 72,
                            step = 1,
                            get = function() return NameplateSCT.db.global.offTargetFormatting.size; end,
                            set = function(_, newValue) NameplateSCT.db.global.offTargetFormatting.size = newValue; end,
                            order = 2,
                        },
                        alpha = {
                            type = 'range',
                            name = "Start Alpha",
                            desc = "",
                            min = 0.1,
                            max = 1,
                            step = .01,
                            get = function() return NameplateSCT.db.global.offTargetFormatting.alpha; end,
                            set = function(_, newValue) NameplateSCT.db.global.offTargetFormatting.alpha = newValue; end,
                            order = 3,
                        },
                    },
                },
            },
        },

        sizing = {
            type = 'group',
            name = "Sizing Modifiers",
            order = 100,
            inline = true,
            disabled = function() return not NameplateSCT.db.global.enabled; end;
            args = {
                crits = {
                    type = 'toggle',
                    name = "Embiggen Crits",
                    desc = "",
                    get = function() return NameplateSCT.db.global.sizing.crits; end,
                    set = function(_, newValue) NameplateSCT.db.global.sizing.crits = newValue; end,
                    order = 1,
                },
                critsScale = {
                    type = 'range',
                    name = "Embiggen Crits Scale",
                    desc = "",
                    disabled = function() return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.sizing.crits; end,
                    min = 1,
                    max = 3,
                    step = .01,
                    get = function() return NameplateSCT.db.global.sizing.critsScale; end,
                    set = function(_, newValue) NameplateSCT.db.global.sizing.critsScale = newValue; end,
                    order = 2,
                    width = "double",
                },

                smallHits = {
                    type = 'toggle',
                    name = "Scale Down Small Hits",
                    desc = "",
                    get = function() return NameplateSCT.db.global.sizing.smallHits; end,
                    set = function(_, newValue) NameplateSCT.db.global.sizing.smallHits = newValue; end,
                    order = 10,
                },
                smallHitsScale = {
                    type = 'range',
                    name = "Small Hits Scale",
                    desc = "",
                    disabled = function() return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.sizing.smallHits; end,
                    min = 0.33,
                    max = 1,
                    step = .01,
                    get = function() return NameplateSCT.db.global.sizing.smallHitsScale; end,
                    set = function(_, newValue) NameplateSCT.db.global.sizing.smallHitsScale = newValue; end,
                    order = 11,
                    width = "double",
                },
            },
        },
    },
};

function NameplateSCT:OpenMenu()
    -- just open to the frame, double call because blizz bug
    InterfaceOptionsFrame_OpenToCategory(self.menu);
    InterfaceOptionsFrame_OpenToCategory(self.menu);
end

function NameplateSCT:RegisterMenu()
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("NameplateSCT", menu);
    self.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateSCT", "NameplateSCT");
end
