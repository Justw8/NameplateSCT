---------------
-- LIBRARIES --
---------------
local AceAddon = LibStub("AceAddon-3.0")
local LibEasing = LibStub("LibEasing-1.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("NameplateSCT")
local MSQ = LibStub("Masque", true)

local NameplateSCT = AceAddon:NewAddon("NameplateSCT", "AceConsole-3.0", "AceEvent-3.0")
NameplateSCT.frame = CreateFrame("Frame", nil, UIParent)

-------------------
-- COMPATIBILITY --
-------------------

local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture

------------
-- LOCALS --
------------

local _
local optionsMenuName
local animating = {}
local randomX = {}
local randomY = {}

local playerGUID
local unitToGuid = {}
local guidToUnit = {}

local function rgbToHex(r, g, b)
	return string.format("%02x%02x%02x", math.floor(255 * r), math.floor(255 * g), math.floor(255 * b))
end

local function hexToRGB(hex)
	return tonumber(hex:sub(1,2), 16)/255, tonumber(hex:sub(3,4), 16)/255, tonumber(hex:sub(5,6), 16)/255, 1
end

local animationValues = {
	-- ["shake"] = L["Shake"],
	["verticalUp"] = L["Vertical Up"],
	["verticalDown"] = L["Vertical Down"],
	["fountain"] = L["Fountain"],
	["rainfall"] = L["Rainfall"],
	["disabled"] = L["Disabled"]
}

local fontFlags = {
	[""] = L["None"],
	["OUTLINE"] = L["Outline"],
	["THICKOUTLINE"] = L["Thick Outline"],
	["nil, MONOCHROME"] = L["Monochrome"],
	["OUTLINE , MONOCHROME"] = L["Monochrome Outline"],
	["THICKOUTLINE , MONOCHROME"] = L["Monochrome Thick Outline"]
}

local stratas = {
	[1] = L["Background"],
	[2] = L["Low"],
	[3] = L["Medium"],
	[4] = L["High"],
	[5] = L["Dialog"],
	[6] = L["Tooltip"]
}

local positionValues = {
	["TOP"] = L["Top"],
	["RIGHT"] = L["Right"],
	["BOTTOM"] = L["Bottom"],
	["LEFT"] = L["Left"],
	["TOPRIGHT"] = L["Top Right"],
	["TOPLEFT"] = L["Top Left"],
	["BOTTOMRIGHT"] = L["Bottom Right"],
	["BOTTOMLEFT"] = L["Bottom Left"],
	["CENTER"]  = L["Center"]
}

local truncateMethod = {
	['NONE'] = L["Do Not Truncate"],
	['WESTERN'] = L["Western"],
	['EASTASIA'] = L["East Asia"],
}

local inversePositions = {
	["BOTTOM"] = "TOP",
	["LEFT"] = "RIGHT",
	["TOP"] = "BOTTOM",
	["RIGHT"] = "LEFT",
	["TOPLEFT"] = "BOTTOMRIGHT",
	["TOPRIGHT"] = "BOTTOMLEFT",
	["BOTTOMLEFT"] = "TOPRIGHT",
	["BOTTOMRIGHT"] = "TOPLEFT",
	["CENTER"]  = "CENTER"
}

--------
-- DB --
--------
if MSQ then
    NameplateSCT.frame.MSQGroup = MSQ:Group("NameplateSCT")
end

local defaultFont = "Friz Quadrata TT"
if (SharedMedia:IsValid("font", "Bazooka")) then
	defaultFont = "Bazooka"
end

local defaults = {
	global = {
		enabled = true,
		shouldDisplayOverkill = false,
		showAbsorbDamage = true,
		xOffset = 0,
		yOffset = 0,
		personalOnly = false,
		xOffsetPersonal = 0,
		yOffsetPersonal = -100,

		modOffTargetStrata = false,
		strata = {
			target = "HIGH",
			offTarget = "MEDIUM",
		},

		font = defaultFont,
		fontFlag = "OUTLINE",
		fontShadow = false,
		damageColor = true,
		defaultColor = "ffff00",
		useCritColor = false,
		critColor = "ffff00",

		showIcon = true,
		enableMSQ = true,
		iconScale = 1,
		iconPosition = "RIGHT",
		xOffsetIcon = 0,
		yOffsetIcon = 0,
		xVariance = 0,
		yVariance = 0,

		damageColorPersonal = false,
		defaultColorPersonal = "ff0000",

		truncateMethod = 'WESTERN',
		truncateLetter = true,
		commaSeperate = true,

		sizing = {
			crits = true,
			critsScale = 1.5,

			miss = false,
			missScale = 1.5,

			smallHits = true,
			smallHitsScale = 0.66,
			smallHitsHide = false,
			autoattackcritsizing = true,
			hideSmallHitsThreshold = 0,
		},

		animations = {
			ability = "fountain",
			crit = "verticalUp",
			miss = "verticalUp",
			autoattack = "fountain",
			autoattackcrit = "verticalUp",
			animationspeed = 1,
		},

		animationsPersonal = {
			normal = "rainfall",
			crit = "verticalUp",
			miss = "verticalUp",
		},

		formatting = {
			size = 20,
			alpha = 1,
		},

		useOffTargetAppearance = true,
		displayOffTargetText = true,
		offTargetFormatting = {
			size = 15,
			alpha = 0.5,
		},
		filterEnabled = false,
		inverseSpellFilter = false,
		inverseNPCFilter = false,
		filter = "",
		npcFilter = "",
	},
}

local filtersTable = {}

function NameplateSCT:updateFilterTable(filterData)
	NameplateSCT.db.global.filter = filterData
	local splitData = {strsplit("\n", filterData)}
	filtersTable = {}
	for _, spellInfo in ipairs(splitData) do
		filtersTable[spellInfo] = true
	end
end

local npcFiltersTable = {}

function NameplateSCT:updateNPCFilterTable(npcFilterData)
	NameplateSCT.db.global.npcFilter = npcFilterData
	local splitData = {strsplit("\n", npcFilterData)}
	npcFiltersTable = {}
	for _, npcId in ipairs(splitData) do
		npcFiltersTable[npcId] = true
	end
end

---------------------
-- LOCAL CONSTANTS --
---------------------

local SMALL_HIT_EXPIRY_WINDOW = 30
local SMALL_HIT_MULTIPIER = 0.5

local ANIMATION_VERTICAL_DISTANCE = 75

local ANIMATION_ARC_X_MIN = 50
local ANIMATION_ARC_X_MAX = 150
local ANIMATION_ARC_Y_TOP_MIN = 10
local ANIMATION_ARC_Y_TOP_MAX = 50
local ANIMATION_ARC_Y_BOTTOM_MIN = 10
local ANIMATION_ARC_Y_BOTTOM_MAX = 50

-- local ANIMATION_SHAKE_DEFLECTION = 15
-- local ANIMATION_SHAKE_NUM_SHAKES = 4

local ANIMATION_RAINFALL_X_MAX = 75
local ANIMATION_RAINFALL_Y_MIN = 50
local ANIMATION_RAINFALL_Y_MAX = 100
local ANIMATION_RAINFALL_Y_START_MIN = 5
local ANIMATION_RAINFALL_Y_START_MAX = 15

if not SCHOOL_MASK_PHYSICAL then -- XXX 9.1 PTR Support
	SCHOOL_MASK_PHYSICAL = Enum.Damageclass.MaskPhysical
	SCHOOL_MASK_HOLY = Enum.Damageclass.MaskHoly
	SCHOOL_MASK_FIRE = Enum.Damageclass.MaskFire
	SCHOOL_MASK_NATURE = Enum.Damageclass.MaskNature
	SCHOOL_MASK_FROST = Enum.Damageclass.MaskFrost
	SCHOOL_MASK_SHADOW = Enum.Damageclass.MaskShadow
	SCHOOL_MASK_ARCANE = Enum.Damageclass.MaskArcane
end


local DAMAGE_TYPE_COLORS = {
	[SCHOOL_MASK_PHYSICAL] = "FFFF00",
	[SCHOOL_MASK_HOLY] = "FFE680",
	[SCHOOL_MASK_FIRE] = "FF8000",
	[SCHOOL_MASK_NATURE] = "4DFF4D",
	[SCHOOL_MASK_FROST] = "80FFFF",
	[SCHOOL_MASK_SHADOW] = "8080FF",
	[SCHOOL_MASK_ARCANE] = "FF80FF",
	[SCHOOL_MASK_HOLY + SCHOOL_MASK_PHYSICAL] = "FFF240", -- Holystrike
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_PHYSICAL] = "FFB900", -- Flamestrike
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_HOLY] = "FFD266", -- Radiant
	[SCHOOL_MASK_NATURE + SCHOOL_MASK_PHYSICAL] = "AFFF23", -- Stormstrike
	[SCHOOL_MASK_HOLY + SCHOOL_MASK_NATURE] = "C1EF6E", -- Holystorm
	[SCHOOL_MASK_NATURE + SCHOOL_MASK_FIRE] = "AFB923", -- Volcanic
	[SCHOOL_MASK_FROST + SCHOOL_MASK_PHYSICAL] = "B3FF99", -- Froststrike
	[SCHOOL_MASK_HOLY + SCHOOL_MASK_FROST] = "CCF0B3", -- Holyfrost
	[SCHOOL_MASK_FROST + SCHOOL_MASK_FIRE] = "C0C080", -- Frostfire
	[SCHOOL_MASK_FROST + SCHOOL_MASK_NATURE] = "69FFAF", -- Froststorm
	[SCHOOL_MASK_SHADOW + SCHOOL_MASK_PHYSICAL] = "C6C673", -- Shadowstrike
	[SCHOOL_MASK_HOLY + SCHOOL_MASK_SHADOW] = "D3C2AC", -- Twilight
	[SCHOOL_MASK_SHADOW + SCHOOL_MASK_FIRE] = "B38099", -- Shadowflame
	[SCHOOL_MASK_SHADOW + SCHOOL_MASK_NATURE] = "6CB3B8", -- Plague
	[SCHOOL_MASK_SHADOW + SCHOOL_MASK_FROST] = "80C6FF", -- Shadowfrost
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_PHYSICAL] = "FFCC66", -- Spellstrike
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_HOLY] = "FFCC66", -- Divine
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_FIRE] = "FF808C", -- Spellfire
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_NATURE] = "AFB9AF", -- Astral
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_FROST] = "C0C0FF", -- Spellfrost
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_FROST] = "B980FF", -- Spellshadow
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_FROST + SCHOOL_MASK_NATURE] = "0070DE", -- Elemental
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_FROST + SCHOOL_MASK_ARCANE + SCHOOL_MASK_NATURE + SCHOOL_MASK_SHADOW] = "C0C0C0", -- Chromatic
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_FROST + SCHOOL_MASK_ARCANE + SCHOOL_MASK_NATURE + SCHOOL_MASK_SHADOW + SCHOOL_MASK_HOLY] = "1111FF", -- Magic
	[SCHOOL_MASK_PHYSICAL + SCHOOL_MASK_FIRE + SCHOOL_MASK_FROST + SCHOOL_MASK_ARCANE + SCHOOL_MASK_NATURE + SCHOOL_MASK_SHADOW + SCHOOL_MASK_HOLY] = "FF1111", -- Chaos
	["melee"] = "FFFFFF",
	["pet"] = "CC8400"
}

local MISS_EVENT_STRINGS = {
	["ABSORB"] = L["Absorbed"],
	["BLOCK"] = L["Blocked"],
	["DEFLECT"] = L["Deflected"],
	["DODGE"] = L["Dodged"],
	["EVADE"] = L["Evaded"],
	["IMMUNE"] = L["Immune"],
	["MISS"] = L["Missed"],
	["PARRY"] = L["Parried"],
	["REFLECT"] = L["Reflected"],
	["RESIST"] = L["Resisted"],
}

local STRATAS = {
	"BACKGROUND",
	"LOW",
	"MEDIUM",
	"HIGH",
	"DIALOG",
	"TOOLTIP"
}

----------------
-- FONTSTRING --
----------------
local function getFontPath(fontName)
	local fontPath = SharedMedia:Fetch("font", fontName)
	if (fontPath == nil) then
		fontPath = "Fonts\\FRIZQT__.TTF"
	end
	return fontPath
end

local fontStringCache = {}
local frameCounter = 0
local function getFontString()
	local fontString
	local fontStringFrame
	if (next(fontStringCache)) then
		fontString = table.remove(fontStringCache)
	else
		frameCounter = frameCounter + 1
		fontStringFrame = CreateFrame("Frame", nil, UIParent)
		fontStringFrame:SetFrameStrata(NameplateSCT:GetStrata(NameplateSCT.db.global.strata.target))
		fontStringFrame:SetFrameLevel(frameCounter)
		fontString = fontStringFrame:CreateFontString()
		fontString:SetParent(fontStringFrame)
	end

	fontString:SetFont(getFontPath(NameplateSCT.db.global.font), 15, NameplateSCT.db.global.fontFlag)
	if NameplateSCT.db.global.textShadow then fontString:SetShadowOffset(1,-1) else fontString:SetShadowOffset(0, 0) end
	fontString:SetAlpha(1)
	fontString:SetDrawLayer("OVERLAY")
	fontString:SetText("")
	fontString:Show()

	if NameplateSCT.db.global.showIcon then
		local frame = fontString:GetParent()
		if not fontString.icon then
			fontString.icon = frame:CreateTexture(nil, "OVERLAY")
		end
		fontString.icon:SetAlpha(1)
		fontString.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		fontString.icon:Hide()

		if MSQ and NameplateSCT.db.global.enableMSQ then
			if not fontString.icon.button then
				local button = CreateFrame("Button", nil, fontStringFrame)
				button:EnableMouse(false)
				button:Disable()
				button:Hide()
				fontString.icon.button = button
			end
			local buttonData = {
				Icon = fontString.icon
			}
			NameplateSCT.frame.MSQGroup:AddButton(fontString.icon.button, buttonData)
		end
		if fontString.icon.button then
			fontString.icon.button:Show()
		end
	end
	return fontString
end

local function recycleFontString(fontString)
	fontString:SetAlpha(0)
	fontString:Hide()

	animating[fontString] = nil
	randomX[fontString] = nil
	randomY[fontString] = nil

	fontString.distance = nil
	fontString.arcTop = nil
	fontString.arcBottom = nil
	fontString.arcXDist = nil
	fontString.deflection = nil
	fontString.numShakes = nil
	fontString.animation = nil
	fontString.animatingDuration = nil
	fontString.animatingStartTime = nil
	fontString.anchorFrame = nil

	fontString.unit = nil
	fontString.guid = nil

	fontString.pow = nil
	fontString.startHeight = nil
	fontString.NSCTFontSize = nil

	if fontString.icon then
		fontString.icon:ClearAllPoints()
		fontString.icon:SetAlpha(0)
		fontString.icon:Hide()
		if fontString.icon.button then
			NameplateSCT.frame.MSQGroup:RemoveButton(fontString.icon.button)
			fontString.icon.button:Hide()
			fontString.icon.button:ClearAllPoints()
		end

		fontString.icon.anchorFrame = nil
		fontString.icon.unit = nil
		fontString.icon.guid = nil
	end

	fontString:SetFont(getFontPath(NameplateSCT.db.global.font), 15, NameplateSCT.db.global.fontFlag)
	if NameplateSCT.db.global.textShadow then fontString:SetShadowOffset(1,-1) else fontString:SetShadowOffset(0, 0) end
	fontString:ClearAllPoints()

	table.insert(fontStringCache, fontString)
end

----------------
-- NAMEPLATES --
----------------

local function adjustStrata()
	local offStrata

	if (NameplateSCT.db.global.modOffTargetStrata) then
		return
	end

	if (NameplateSCT.db.global.strata.target == 1) then -- Background
		NameplateSCT.db.global.strata.offTarget = 1
		return
	else
		for k, v in ipairs(STRATAS) do
			if (k == NameplateSCT.db.global.strata.target) then
				offStrata = k - 1
			end
		end
	end

	NameplateSCT.db.global.strata.offTarget = offStrata
end

function NameplateSCT:GetStrata(strataNumber)
	if type(strataNumber) == "number" then
		return STRATAS[strataNumber]
	end
end

----------
-- CORE --
----------

function NameplateSCT:ConvertDB()
	if type(NameplateSCT.db.global.strata.offTarget) == "string" then
		for k, v in ipairs(STRATAS) do
			if (v == NameplateSCT.db.global.strata.offTarget) then
				NameplateSCT.db.global.strata.offTarget = k
			end
		end
	end
	if type(NameplateSCT.db.global.strata.target) == "string" then
		for k, v in ipairs(STRATAS) do
			if (v == NameplateSCT.db.global.strata.target) then
				NameplateSCT.db.global.strata.target = k
			end
		end
	end
end

function NameplateSCT:OnInitialize()
	-- setup db
	self.db = LibStub("AceDB-3.0"):New("NameplateSCTDB", defaults, true)

	-- Adjust anything that was edited in the db to be correct
	self:ConvertDB()

	-- setup chat commands
	self:RegisterChatCommand("nsct", "OpenMenu")

	-- setup menu
	self:RegisterMenu()

	-- Update Filters
	self:updateFilterTable(self.db.global.filter)
	self:updateNPCFilterTable(self.db.global.npcFilter)

	-- if the addon is turned off in db, turn it off
	if (self.db.global.enabled == false) then
		self:Disable()
	end
end

function NameplateSCT:OnEnable()
	playerGUID = UnitGUID("player")

	self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self.db.global.enabled = true
end

function NameplateSCT:OnDisable()
	self:UnregisterAllEvents()

	for fontString, _ in pairs(animating) do
		recycleFontString(fontString)
	end

	self.db.global.enabled = false
end


---------------
-- ANIMATION --
---------------
local function verticalPath(elapsed, duration, distance)
	return 0, LibEasing.InQuad(elapsed, 0, distance, duration)
end

local function arcPath(elapsed, duration, xDist, yStart, yTop, yBottom)
	local x, y
	local progress = elapsed/duration

	x = progress * xDist

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

	local a = -2 * yStart + 4 * yTop - 2 * yBottom
	local b = -3 * yStart + 4 * yTop - yBottom

	y = -a * math.pow(progress, 2) + b * progress + yStart

	return x, y
end

local function powSizing(elapsed, duration, start, middle, finish)
	local size = finish
	if (elapsed < duration) then
		if (elapsed/duration < 0.5) then
			size = LibEasing.OutQuint(elapsed, start, middle - start, duration/2)
		else
			size = LibEasing.InQuint(elapsed - elapsed/2, middle, finish - middle, duration/2)
		end
	end
	return size
end

local function AnimationOnUpdate()
	if (next(animating)) then
		for fontString, _ in pairs(animating) do
			local elapsed = GetTime() - fontString.animatingStartTime
			if (elapsed > fontString.animatingDuration) then
				-- the animation is over
				recycleFontString(fontString)
			else
				local isTarget = false
				if fontString.unit then
					isTarget = UnitIsUnit(fontString.unit, "target")
				else
					fontString.unit = "player"
				end

				-- frame level
				local frame = fontString:GetParent()
				local strataRequired = (isTarget) and NameplateSCT:GetStrata(NameplateSCT.db.global.strata.target) or NameplateSCT:GetStrata(NameplateSCT.db.global.strata.offTarget)
				frame:SetFrameStrata(strataRequired)

				-- alpha
				local startAlpha = NameplateSCT.db.global.formatting.alpha
				if (NameplateSCT.db.global.useOffTargetAppearance and not isTarget and fontString.unit ~= "player") then
					startAlpha = NameplateSCT.db.global.offTargetFormatting.alpha
				end

				local alpha = LibEasing.InExpo(elapsed, startAlpha, -startAlpha, fontString.animatingDuration)
				if alpha > 1 then alpha = 1 elseif alpha < 0 then alpha = 0 end -- avoid rare occurences of eg: 1.0003 from the Lib being used to set Alpha
				fontString:SetAlpha(alpha)

				-- sizing
				if (fontString.pow) then
					local iconScale = NameplateSCT.db.global.iconScale
					local height = fontString.startHeight
					if (elapsed < fontString.animatingDuration/6) then
						fontString:SetText(fontString.NSCTText)
						local size = powSizing(elapsed, fontString.animatingDuration/6, height/2, height*2, height)
						fontString:SetTextHeight(size)
						if fontString.icon then
							if MSQ and NameplateSCT.db.global.enableMSQ then
								fontString.icon.button:SetSize(size*iconScale, size*iconScale)
							else
								fontString.icon:SetSize(size*iconScale, size*iconScale)
							end
						end
					else
						fontString.pow = nil
						fontString:SetTextHeight(height)
						fontString:SetFont(getFontPath(NameplateSCT.db.global.font), fontString.NSCTFontSize, NameplateSCT.db.global.fontFlag)
						if NameplateSCT.db.global.textShadow then fontString:SetShadowOffset(1,-1) else fontString:SetShadowOffset(0, 0) end
						fontString:SetText(fontString.NSCTText)
						if fontString.icon then
							if MSQ and NameplateSCT.db.global.enableMSQ then
								fontString.icon.button:SetSize(height*iconScale, height*iconScale)
							else
								fontString.icon:SetSize(height*iconScale, height*iconScale)
							end
						end
					end
				end

				-- position
				local xOffset, yOffset = 0, 0
				if (fontString.animation == "verticalUp") then
					xOffset, yOffset = verticalPath(elapsed, fontString.animatingDuration, fontString.distance)
				elseif (fontString.animation == "verticalDown") then
					xOffset, yOffset = verticalPath(elapsed, fontString.animatingDuration, -fontString.distance)
				elseif (fontString.animation == "fountain") then
					xOffset, yOffset = arcPath(elapsed, fontString.animatingDuration, fontString.arcXDist, 0, fontString.arcTop, fontString.arcBottom)
				elseif (fontString.animation == "rainfall") then
					_, yOffset = verticalPath(elapsed, fontString.animatingDuration, -fontString.distance)
					xOffset = fontString.rainfallX
					yOffset = yOffset + fontString.rainfallStartY
				-- elseif (fontString.animation == "shake") then
					-- TODO
				end

				if (not UnitIsDead(fontString.unit) and fontString.anchorFrame and fontString.anchorFrame:IsShown()) then
					if fontString.unit == "player" then -- player frame
					fontString:SetPoint("CENTER", fontString.anchorFrame, "CENTER", NameplateSCT.db.global.xOffsetPersonal + xOffset + randomX[fontString], NameplateSCT.db.global.yOffsetPersonal + yOffset + randomY[fontString]) -- Only allows for adjusting vertical offset
					else -- nameplate frames
					fontString:SetPoint("CENTER", fontString.anchorFrame, "CENTER", NameplateSCT.db.global.xOffset + xOffset + randomX[fontString], NameplateSCT.db.global.yOffset + yOffset + randomY[fontString])
					end
				else
					recycleFontString(fontString)
				end
			end
		end
		if MSQ and NameplateSCT.db.global.enableMSQ then
			NameplateSCT.frame.MSQGroup:ReSkin()
		end
	else
		-- nothing in the animation list, so just kill the onupdate
		NameplateSCT.frame:SetScript("OnUpdate", nil)
	end
end

local arcDirection = 1
function NameplateSCT:Animate(fontString, anchorFrame, duration, animation)
	animation = animation or "verticalUp"

	fontString.animation = animation
	fontString.animatingDuration = duration
	fontString.animatingStartTime = GetTime()
	fontString.anchorFrame = anchorFrame == "player" and UIParent or anchorFrame

	if (animation == "verticalUp") then
		fontString.distance = ANIMATION_VERTICAL_DISTANCE
	elseif (animation == "verticalDown") then
		fontString.distance = ANIMATION_VERTICAL_DISTANCE
	elseif (animation == "fountain") then
		fontString.arcTop = math.random(ANIMATION_ARC_Y_TOP_MIN, ANIMATION_ARC_Y_TOP_MAX)
		fontString.arcBottom = -math.random(ANIMATION_ARC_Y_BOTTOM_MIN, ANIMATION_ARC_Y_BOTTOM_MAX)
		fontString.arcXDist = arcDirection * math.random(ANIMATION_ARC_X_MIN, ANIMATION_ARC_X_MAX)

		arcDirection = arcDirection * -1
	elseif (animation == "rainfall") then
		fontString.distance = math.random(ANIMATION_RAINFALL_Y_MIN, ANIMATION_RAINFALL_Y_MAX)
		fontString.rainfallX = math.random(-ANIMATION_RAINFALL_X_MAX, ANIMATION_RAINFALL_X_MAX)
		fontString.rainfallStartY = -math.random(ANIMATION_RAINFALL_Y_START_MIN, ANIMATION_RAINFALL_Y_START_MAX)
	-- elseif (animation == "shake") then
	--	 fontString.deflection = ANIMATION_SHAKE_DEFLECTION
	--	 fontString.numShakes = ANIMATION_SHAKE_NUM_SHAKES
	end

	animating[fontString] = true
	randomX[fontString] = NameplateSCT.db.global.xVariance > 0 and math.random(-NameplateSCT.db.global.xVariance, NameplateSCT.db.global.xVariance) or 0
	randomY[fontString] = NameplateSCT.db.global.yVariance > 0 and math.random(-NameplateSCT.db.global.yVariance, NameplateSCT.db.global.yVariance) or 0

	-- start onupdate if it's not already running
	if (NameplateSCT.frame:GetScript("OnUpdate") == nil) then
		NameplateSCT.frame:SetScript("OnUpdate", AnimationOnUpdate)
	end
end


------------
-- EVENTS --
------------

function NameplateSCT:NAME_PLATE_UNIT_ADDED(event, unitID)
	local guid = UnitGUID(unitID)

	unitToGuid[unitID] = guid
	guidToUnit[guid] = unitID
end

function NameplateSCT:NAME_PLATE_UNIT_REMOVED(event, unitID)
	local guid = unitToGuid[unitID]

	unitToGuid[unitID] = nil
	guidToUnit[guid] = nil

	-- recycle any fontStrings attachedk to this unit
	for fontString, _ in pairs(animating) do
		if fontString.unit == unitID then
			recycleFontString(fontString)
		end
	end
end

function NameplateSCT:CombatFilter(_, clue, _, sourceGUID, _, sourceFlags, _, destGUID, _, _, _, ...)
if NameplateSCT.db.global.personalOnly and NameplateSCT.db.global.personal and playerGUID ~= destGUID then return end -- Cancel out any non player targetted abilities if you have personalSCT only enabled
	if NameplateSCT.db.global.filterEnabled then -- Filter out mobId's if needed
		local _, _, _, _, _, destUnitId = strsplit("-", destGUID)
		destUnitId = tostring(destUnitId) or "1"
		if (NameplateSCT.db.global.inverseNPCFilter and not npcFiltersTable[destUnitId]) -- Inverse filter
			or
		(not NameplateSCT.db.global.inverseNPCFilter and npcFiltersTable[destUnitId]) -- Normal Filter
		then return end
	end
	if playerGUID == sourceGUID or (NameplateSCT.db.global.personal and playerGUID == destGUID) then -- Player events
		local destUnit = guidToUnit[destGUID]
		if (destUnit) or (destGUID == playerGUID and NameplateSCT.db.global.personal) then
			if (string.find(clue, "_DAMAGE")) then
				local spellName, amount, overkill, school, critical, spellId, absorbed
				if (string.find(clue, "SWING")) then
					spellName, amount, overkill, _, _, _, absorbed, critical = "melee", ...
				elseif (string.find(clue, "ENVIRONMENTAL")) then
					spellName, amount, overkill, school, _, _, absorbed, critical = ...
				else
					spellId, spellName, _, amount, overkill, school, _, _, absorbed, critical = ...
				end
				if spellId and spellId == 0 then
					spellId = nil -- Don't pass spellId 0
				end
				if NameplateSCT.db.global.filterEnabled then
					local spellInFilter = filtersTable[tostring(spellId)] or filtersTable[spellName]
					if (NameplateSCT.db.global.inverseSpellFilter and not spellInFilter) or (not NameplateSCT.db.global.inverseSpellFilter and spellInFilter) then
						return
					end
				end
				self:DamageEvent(destGUID, spellName, amount, overkill, school, critical, spellId, absorbed)
			elseif(string.find(clue, "_MISSED")) then
				local spellName, missType, spellId, amount, school

				if (string.find(clue, "SWING")) then
					if destGUID == playerGUID then
						missType, _, amount, critical = ...
					else
						missType, _, amount, critical = "melee", ...
					end
				else
					spellId, spellName, school, missType, _, amount, critical = ...
				end
				if spellId and spellId == 0 then
					spellId = nil -- Don't pass spellId 0
				end
				if NameplateSCT.db.global.filterEnabled then
					local spellInFilter = filtersTable[tostring(spellId)] or filtersTable[spellName]
					if (NameplateSCT.db.global.inverseSpellFilter and not spellInFilter) or (not NameplateSCT.db.global.inverseSpellFilter and spellInFilter) then
						return
					end
				end
				if missType == "ABSORB" then --Show absorbed as damage
					self:DamageEvent(destGUID, spellName, 0, -1, school, critical, spellId, amount)
				else
					self:MissEvent(destGUID, spellName, missType, spellId)
				end
			end
		end
	elseif (bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) > 0 or bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PET) > 0)	and bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then -- Pet/Guardian events
		local destUnit = guidToUnit[destGUID]
		if (destUnit) or (destGUID == playerGUID and NameplateSCT.db.global.personal) then
			if (string.find(clue, "_DAMAGE")) then
				local spellName, amount, overkill, critical, spellId, absorbed
				if (string.find(clue, "SWING")) then
					spellName, amount, overkill, _, _, _, absorbed, critical, _, _, _ = "pet", ...
				elseif (string.find(clue, "ENVIRONMENTAL")) then
					spellName, amount, overkill, _, _, _, absorbed, critical= ...
				else
					spellId, spellName, _, amount, overkill, _, _, _, absorbed, critical = ...
				end
				if spellId and spellId == 0 then
					spellId = nil -- Don't pass spellId 0
				end
				if NameplateSCT.db.global.filterEnabled then
					local spellInFilter = filtersTable[tostring(spellId)] or filtersTable[spellName]
					if (NameplateSCT.db.global.inverseSpellFilter and not spellInFilter) or (not NameplateSCT.db.global.inverseSpellFilter and spellInFilter) then
						return
					end
				end
				self:DamageEvent(destGUID, spellName, amount, overkill, "pet", critical, spellId, absorbed)
			elseif(string.find(clue, "_MISSED")) then -- Check for absorbed damage
				local spellName, missType, spellId, amount

				if (string.find(clue, "SWING")) then
					if destGUID == playerGUID then
					missType, _, amount, critical = ...
					else
					missType, _, amount, critical = "melee", ...
					end
				else
					spellId, spellName, _, missType, _, amount, critical = ...
				end
				if spellId and spellId == 0 then
					spellId = nil -- Don't pass spellId 0
				end
				if NameplateSCT.db.global.filterEnabled then
					local spellInFilter = filtersTable[tostring(spellId)] or filtersTable[spellName]
					if (NameplateSCT.db.global.inverseSpellFilter and not spellInFilter) or (not NameplateSCT.db.global.inverseSpellFilter and spellInFilter) then
						return
					end
				end
				if missType == "ABSORB" then
					self:DamageEvent(destGUID, spellName, 0, -1, "pet", critical, spellId, amount)
				end
			end
		end
	end
end

function NameplateSCT:COMBAT_LOG_EVENT_UNFILTERED ()
	return NameplateSCT:CombatFilter(CombatLogGetCurrentEventInfo())
end

-------------
-- DISPLAY --
-------------

local function commaSeperate(number)
	-- https://stackoverflow.com/questions/10989788/lua-format-integer
	local _, _, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus..int:reverse():gsub("^,", "")..fraction
end

function NameplateSCT:truncateText(amount)
	local text = ''
	if self.db.global.truncateMethod == 'NONE' then
		if (self.db.global.commaSeperate) then
			text = commaSeperate(amount)
		else
			text = tostring(amount)
		end

	elseif self.db.global.truncateMethod == 'WESTERN' then
		local unitLetter = ''
		if self.db.global.truncateLetter then
			unitLetter = 'k'
		end

		if amount >= 1000000 and self.db.global.truncateLetter then
			text = string.format("%.1fM", amount / 1000000)
		elseif amount >= 10000 then
			text = string.format("%.0f%s", amount / 1000, unitLetter)
		elseif amount >= 1000 then
			text = string.format("%.1f%s", amount / 1000, unitLetter)
		else
			text = tostring(amount)
		end
	elseif self.db.global.truncateMethod == 'EASTASIA' then

		local unitLetter = ''
		if self.db.global.truncateLetter then
			unitLetter = L["Truncate Letter East Asia"]
			if unitLetter == 'Truncate Letter East Asia' then
				-- miss locale, Use its pronunciation instead
				-- 'w' means 'wan', 1wan = 10000
				unitLetter = 'w'
			end
		end

		if amount >= 100000 then
			text = string.format("%.0f%s", amount / 10000, unitLetter)
		elseif amount >= 10000 then
			text = string.format("%.1f%s", amount / 10000, unitLetter)
		else
			text = tostring(amount)
		end
	else
		-- Never reach
		text = tostring(amount)
	end

	return text
end

local numDamageEvents = 0
local lastDamageEventTime
local runningAverageDamageEvents = 0
function NameplateSCT:DamageEvent(guid, spellName, amount, overkill, school, crit, spellId, absorbed)
	local amount = amount or 0
	local absorbed = absorbed or 0

	-- Hide small hits based on threshold
	if self.db.global.sizing.hideSmallHitsThreshold > (amount + absorbed) then
		return
	end

	local text, animation, pow, size, alpha
	local autoattack = spellName == "melee" or spellName == "pet"

	-- select an animation
	if (autoattack and crit) then
		animation = guid ~= playerGUID and self.db.global.animations.autoattackcrit or self.db.global.animationsPersonal.crit
		pow = true
	elseif (autoattack) then
		animation = guid ~= playerGUID and self.db.global.animations.autoattack or self.db.global.animationsPersonal.normal
		pow = false
	elseif (crit) then
		animation = guid ~= playerGUID and self.db.global.animations.crit or self.db.global.animationsPersonal.crit
		pow = true
	elseif (not autoattack and not crit) then
		animation = guid ~= playerGUID and self.db.global.animations.ability or self.db.global.animationsPersonal.normal
		pow = false
	end

	-- skip if this damage event is disabled
	if (animation == "disabled") then
		return
	end

	local unit = guidToUnit[guid]
	local isTarget = unit and UnitIsUnit(unit, "target")

	if (not isTarget and not self.db.global.displayOffTargetText) then
		return
	end

	if (self.db.global.useOffTargetAppearance and not isTarget and playerGUID ~= guid) then
		size = self.db.global.offTargetFormatting.size
		alpha = self.db.global.offTargetFormatting.alpha
	else
		size = self.db.global.formatting.size
		alpha = self.db.global.formatting.alpha
	end

	-- truncate
	text = self:truncateText(amount)

	if NameplateSCT.db.global.showAbsorbDamage and absorbed > 0 then
		local absorbedText = self:truncateText(absorbed)
		text = L["%s (A: %s)"]:format(text, absorbedText)
	end
	-- color text
	text = self:ColorText(text, guid, playerGUID, school, spellName, crit)

	-- shrink small hits
	if (self.db.global.sizing.smallHits or self.db.global.sizing.smallHitsHide) and playerGUID ~= guid then
		if (not lastDamageEventTime or (lastDamageEventTime + SMALL_HIT_EXPIRY_WINDOW < GetTime())) then
			numDamageEvents = 0
			runningAverageDamageEvents = 0
		end

		runningAverageDamageEvents = ((runningAverageDamageEvents*numDamageEvents) + amount)/(numDamageEvents + 1)
		numDamageEvents = numDamageEvents + 1
		lastDamageEventTime = GetTime()

		if ((not crit and amount < SMALL_HIT_MULTIPIER*runningAverageDamageEvents)
			or (crit and amount/2 < SMALL_HIT_MULTIPIER*runningAverageDamageEvents)) then
			if self.db.global.sizing.smallHitsHide then
				-- skip this damage event, it's too small
				return
			else
				size = size * self.db.global.sizing.smallHitsScale
			end
		end
	end

	-- embiggen crit's size
	if (self.db.global.sizing.crits and crit) and playerGUID ~= guid then
		if (autoattack and not self.db.global.sizing.autoattackcritsizing) then
			-- don't embiggen autoattacks
			pow = false
		else
			size = size * self.db.global.sizing.critsScale
		end
	end

	-- make sure that size is larger than 5
	if (size < 5) then
		size = 5
	end

	if (overkill > 0 and self.db.global.shouldDisplayOverkill) then
		text = self:ColorText(L["%s (O: %s)"]:format(text, overkill), guid, playerGUID, school, spellName, crit)
		self:DisplayTextOverkill(guid, text, size, animation, spellId, pow, spellName)
	else
		self:DisplayText(guid, text, size, animation, spellId, pow, spellName)
	end
end

function NameplateSCT:MissEvent(guid, spellName, missType, spellId)
	local text, animation, pow, size, alpha, color
	local unit = guidToUnit[guid]
	local isTarget = unit and UnitIsUnit(unit, "target")

	if playerGUID ~= guid then
	animation = self.db.global.animations.miss
	color = self.db.global.defaultColor
	else
	animation = self.db.global.animationsPersonal.miss
	color = self.db.global.defaultColorPersonal
	end

	-- No animation set, cancel out
	if (animation == "disabled") then
	return
	end

	if (self.db.global.useOffTargetAppearance and not isTarget and playerGUID ~= guid) then
		size = self.db.global.offTargetFormatting.size
		alpha = self.db.global.offTargetFormatting.alpha
	else
		size = self.db.global.formatting.size
		alpha = self.db.global.formatting.alpha
	end

	-- embiggen miss size
	if self.db.global.sizing.miss and playerGUID ~= guid then
		size = size * self.db.global.sizing.missScale
	end

	pow = true

	text = MISS_EVENT_STRINGS[missType] or L["Missed"]
	text = "|Cff"..color..text.."|r"

	self:DisplayText(guid, text, size, animation, spellId, pow, spellName)
end

function NameplateSCT:DisplayText(guid, text, size, animation, spellId, pow, spellName)
	local fontString
	local icon
	local unit = guidToUnit[guid]
	local nameplate

	if (unit) then
		nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	end

	-- if there isn't an anchor frame, make sure that there is a guidNameplatePosition cache entry
	if playerGUID == guid and not unit then
		nameplate = "player"
	elseif (not nameplate) then
		return
	end

	fontString = getFontString()

	fontString.NSCTText = text
	fontString:SetText(fontString.NSCTText)

	fontString.NSCTFontSize = size
	fontString:SetFont(getFontPath(NameplateSCT.db.global.font), fontString.NSCTFontSize, NameplateSCT.db.global.fontFlag)
	if NameplateSCT.db.global.textShadow then fontString:SetShadowOffset(1,-1) else fontString:SetShadowOffset(0, 0) end
	fontString.startHeight = fontString:GetStringHeight()
	fontString.pow = pow

	if (fontString.startHeight <= 0) then
		fontString.startHeight = 5
	end

	fontString.unit = unit
	fontString.guid = guid

	local texture = GetSpellTexture(spellId or spellName or "")
	if NameplateSCT.db.global.showIcon and texture then
		icon = fontString.icon
		icon:Show()
		icon:SetTexture(texture)
		if MSQ and NameplateSCT.db.global.enableMSQ then
			icon.button:SetSize(size * NameplateSCT.db.global.iconScale, size * NameplateSCT.db.global.iconScale)
			icon.button:SetPoint(
				inversePositions[NameplateSCT.db.global.iconPosition],
				fontString,
				NameplateSCT.db.global.iconPosition,
				NameplateSCT.db.global.xOffsetIcon,
				NameplateSCT.db.global.yOffsetIcon
			)
			icon.button:Show()
		else
			icon:SetSize(size*NameplateSCT.db.global.iconScale, size*NameplateSCT.db.global.iconScale)
			icon:SetPoint(
				inversePositions[NameplateSCT.db.global.iconPosition],
				fontString,
				NameplateSCT.db.global.iconPosition,
				NameplateSCT.db.global.xOffsetIcon,
				NameplateSCT.db.global.yOffsetIcon
			)
		end
			fontString.icon = icon
		else
		if fontString.icon then
			fontString.icon:Hide()
			if MSQ and NameplateSCT.db.global.enableMSQ then
				fontString.icon.button:Hide()
			end
		end
	end
	self:Animate(fontString, nameplate, NameplateSCT.db.global.animations.animationspeed, animation)
end

function NameplateSCT:DisplayTextOverkill(guid, text, size, animation, spellId, pow, spellName)
	local fontString
	local icon
	local unit = guidToUnit[guid]
	local nameplate

	nameplate = "player"

	fontString = getFontString()

	fontString.NSCTText = text
	fontString:SetText(fontString.NSCTText)

	fontString.NSCTFontSize = size
	fontString:SetFont(getFontPath(NameplateSCT.db.global.font), fontString.NSCTFontSize, NameplateSCT.db.global.fontFlag)
	if NameplateSCT.db.global.textShadow then fontString:SetShadowOffset(1,-1) else fontString:SetShadowOffset(0, 0) end
	fontString.startHeight = fontString:GetStringHeight()
	fontString.pow = pow

	if (fontString.startHeight <= 0) then
		fontString.startHeight = 5
	end

	fontString.unit = "player"
	fontString.guid = guid
	local texture = GetSpellTexture(spellId or spellName or "")
	if NameplateSCT.db.global.showIcon and texture then
	icon = fontString.icon
	icon:Show()
	icon:SetTexture(texture)
	if MSQ and NameplateSCT.db.global.enableMSQ then
		icon.button:SetSize(size*NameplateSCT.db.global.iconScale, size*NameplateSCT.db.global.iconScale)
		icon.button:SetPoint(
		inversePositions[NameplateSCT.db.global.iconPosition],
		fontString,
		NameplateSCT.db.global.iconPosition,
		NameplateSCT.db.global.xOffsetIcon,
		NameplateSCT.db.global.yOffsetIcon
		)
		icon.button:Show()
	else
		icon:SetSize(size*NameplateSCT.db.global.iconScale, size*NameplateSCT.db.global.iconScale)
		icon:SetPoint(
		inversePositions[NameplateSCT.db.global.iconPosition],
		fontString,
		NameplateSCT.db.global.iconPosition,
		NameplateSCT.db.global.xOffsetIcon,
		NameplateSCT.db.global.yOffsetIcon
		)
	end
	fontString.icon = icon
	else
	if fontString.icon then
		fontString.icon:Hide()
		if MSQ and NameplateSCT.db.global.enableMSQ then
		fontString.icon.button:Hide()
		end
	end
	end
	self:Animate(fontString, nameplate, NameplateSCT.db.global.animations.animationspeed, animation)
end

function NameplateSCT:ColorText(startingText, guid, playerGUID, school, spellName, crit)
	local finalText
	if guid ~= playerGUID then
		if crit and self.db.global.useCritColor then
			finalText = "|Cff"..self.db.global.critColor..startingText.."|r"
		elseif self.db.global.damageColor and school and DAMAGE_TYPE_COLORS[school] then
			finalText = "|Cff"..DAMAGE_TYPE_COLORS[school]..startingText.."|r"
		elseif self.db.global.damageColor and spellName == "melee" and DAMAGE_TYPE_COLORS[spellName] then
			finalText = "|Cff"..DAMAGE_TYPE_COLORS[spellName]..startingText.."|r"
		else
			finalText = "|Cff"..self.db.global.defaultColor..startingText.."|r"
		end
	else
		if self.db.global.damageColorPersonal and school and DAMAGE_TYPE_COLORS[school] then
			finalText = "|Cff"..DAMAGE_TYPE_COLORS[school]..startingText.."|r"
		elseif self.db.global.damageColorPersonal and spellName == "melee" and DAMAGE_TYPE_COLORS[spellName] then
			finalText = "|Cff"..DAMAGE_TYPE_COLORS[spellName]..startingText.."|r"
		else
			finalText = "|Cff"..self.db.global.defaultColorPersonal..startingText.."|r"
		end
	end

	return finalText
end

-------------
-- OPTIONS --
-------------

local menu = {
	name = "NameplateSCT",
	handler = NameplateSCT,
	type = 'group',
	args = {
		nameplatesEnabled = {
			type = 'description',
			name = "|cFFFF0000"..L["YOUR ENEMY NAMEPLATES ARE DISABLED, NAMEPLATESCT WILL NOT WORK!!"].."|r",
			hidden = function() return GetCVar("nameplateShowEnemies") == "1" end,
			order = 1,
			width = "full",
		},
		-- enemyNameplatesEnabler = {
		--	 type = 'toggle',
		--	 name = "Enemy Nameplates - Enabling Required",
		--	 get = function(_, newValue) return GetCVar("nameplateShowEnemies") == "1" end,
		--	 set = function(_, newValue)
		--		 if (newValue) then
		--			 SetCVar("nameplateShowEnemies", 1)
		--		 end
		--	 end,
		--	 hidden = function() return GetCVar("nameplateShowEnemies") == "1" end,
		--	 order = 2,
		--	 width = "full",
		-- },
		nameplatesEnabled2 = {
			type = 'description',
			name = "|cFFFF0000"..L["YOUR ENEMY NAMEPLATES ARE DISABLED, NAMEPLATESCT WILL NOT WORK!!"].."|r",
			hidden = function() return GetCVar("nameplateShowEnemies") == "1" end,
			order = 3,
			width = "full",
		},
		enable = {
			type = 'toggle',
			name = L["Enable"],
			desc = L["If the addon is enabled."],
			get = "IsEnabled",
			set = function(_, newValue) if (not newValue) then NameplateSCT:Disable() else NameplateSCT:Enable() end end,
			order = 4,
			width = "full",
		},

		disableBlizzardFCT = {
			type = 'toggle',
			name = L["BlizzardSCT"],
			get = function(_, newValue) return GetCVar("floatingCombatTextCombatDamage") == "1" end,
			set = function(_, newValue)
				if (newValue) then
					SetCVar("floatingCombatTextCombatDamage", 1)
				else
					SetCVar("floatingCombatTextCombatDamage", 0)
				end
			end,
			order = 5,
			width = "full",
		},

		displayOverkill = {
			type = 'toggle',
			name = L["Display Overkill"],
			desc = L["Display your overkill for a target over your own nameplate"],
			get = function() return NameplateSCT.db.global.shouldDisplayOverkill end,
			set = function(_, newValue) NameplateSCT.db.global.shouldDisplayOverkill = newValue end,
			order = 6,
		},

		showAbsorbs = {
			type = 'toggle',
			name = L["Show Absorbed Damage"],
			desc = L["Show Absorbed Damage shown as: '5 (A: 3)' where A: 3 is the absorbed amount"],
			get = function() return NameplateSCT.db.global.showAbsorbDamage end,
			set = function(_, newValue) NameplateSCT.db.global.showAbsorbDamage = newValue end,
			order = 6.3,
		},

		divider = {
			type = 'description',
			name = "",
			order = 6.6,
			width = "full",
		},

		personalNameplate = {
			type = 'toggle',
			name = L["Personal SCT"],
			desc = L["Also show numbers when you take damage on your personal nameplate or center screen"],
			get = function() return NameplateSCT.db.global.personal end,
			set = function(_, newValue) NameplateSCT.db.global.personal = newValue end,
			order = 7,
			disabled = function() return not NameplateSCT.db.global.enabled end
		},

		personalNameplateOnly = {
			type = 'toggle',
			name = L["Personal SCT Only"],
			desc = L["Don't display any numbers on enemies and only use the personal SCT."],
				get = function() return NameplateSCT.db.global.personalOnly end,
				set = function(_, newValue) NameplateSCT.db.global.personalOnly = newValue end,
			order = 8,
			disabled = function() return (not NameplateSCT.db.global.personal or not NameplateSCT.db.global.enabled) end
		},
		animations = {
			type = 'group',
			name = L["Animations"],
			order = 30,
			inline = true,
			disabled = function() return not NameplateSCT.db.global.enabled end,
			args = {
				speed = {
					type = 'range',
					name = L["Animation Speed"],
					desc = L["Default speed: 1"],
					disabled = function() return not NameplateSCT.db.global.enabled end,
					min = 0.5,
					max = 2,
					step = .1,
					get = function() return NameplateSCT.db.global.animations.animationspeed end,
					set = function(_, newValue) NameplateSCT.db.global.animations.animationspeed = newValue end,
					order = 1,
					width = "full",
				},
				ability = {
					type = 'select',
					name = L["Abilities"],
					desc = "",
					get = function() return NameplateSCT.db.global.animations.ability end,
					set = function(_, newValue) NameplateSCT.db.global.animations.ability = newValue end,
					values = animationValues,
					order = 2,
				},
				crit = {
					type = 'select',
					name = L["Criticals"],
					desc = "",
					get = function() return NameplateSCT.db.global.animations.crit end,
					set = function(_, newValue) NameplateSCT.db.global.animations.crit = newValue end,
					values = animationValues,
					order = 3,
				},
				miss = {
					type = 'select',
					name = L["Miss/Parry/Dodge/etc"],
					desc = "",
					get = function() return NameplateSCT.db.global.animations.miss end,
					set = function(_, newValue) NameplateSCT.db.global.animations.miss = newValue end,
					values = animationValues,
					order = 4,
				},
				autoattack = {
					type = 'select',
					name = L["Auto Attacks"],
					desc = "",
					get = function() return NameplateSCT.db.global.animations.autoattack end,
					set = function(_, newValue) NameplateSCT.db.global.animations.autoattack = newValue end,
					values = animationValues,
					order = 5,
				},
				autoattackcrit = {
					type = 'select',
					name = L["Criticals"],
					desc = L["Auto attacks that are critical hits"],
					get = function() return NameplateSCT.db.global.animations.autoattackcrit end,
					set = function(_, newValue) NameplateSCT.db.global.animations.autoattackcrit = newValue end,
					values = animationValues,
					order = 6,
				},
				autoattackcritsizing = {
					type = 'toggle',
					name = L["Embiggen Crits"],
					desc = L["Embiggen critical auto attacks"],
					get = function() return NameplateSCT.db.global.sizing.autoattackcritsizing end,
					set = function(_, newValue) NameplateSCT.db.global.sizing.autoattackcritsizing = newValue end,
					order = 7,
				},
			},
		},
		appearance = {
			type = 'group',
			name = L["Appearance/Offsets"],
			order = 50,
			inline = true,
			disabled = function() return not NameplateSCT.db.global.enabled end,
			args = {
				font = {
					type = "select",
					dialogControl = "LSM30_Font",
					name = L["Font"],
					order = 1,
					values = AceGUIWidgetLSMlists.font,
					get = function() return NameplateSCT.db.global.font end,
					set = function(_, newValue) NameplateSCT.db.global.font = newValue end,
				},
				fontFlag = {
					type = 'select',
					name = L["Font Flags"],
					desc = "",
					get = function() return NameplateSCT.db.global.fontFlag end,
					set = function(_, newValue) NameplateSCT.db.global.fontFlag = newValue end,
					values = fontFlags,
					order = 2,
				},
				fontShadow = {
					type = 'toggle',
					name = L["Text Shadow"],
					get = function() return NameplateSCT.db.global.textShadow end,
					set = function(_, newValue) NameplateSCT.db.global.textShadow = newValue end,
					order = 3,
				},
				damageColor = {
					type = 'toggle',
					name = L["Use Damage Type Color"],
					desc = "",
					get = function() return NameplateSCT.db.global.damageColor end,
					set = function(_, newValue) NameplateSCT.db.global.damageColor = newValue end,
					order = 4,
				},
				defaultColor = {
					type = 'color',
					name = L["Default Color"],
					desc = "",
					disabled = function() return NameplateSCT.db.global.damageColor end,
					hasAlpha = false,
					set = function(_, r, g, b) NameplateSCT.db.global.defaultColor = rgbToHex(r, g, b) end,
					get = function() return hexToRGB(NameplateSCT.db.global.defaultColor) end,
					order = 5,
				},
				critColorNewLine = {
					type = 'description',
					name = "",
					desc = "",
					order = 6,
				},
				useCritColor = {
					type = 'toggle',
					name = L["Use Crit Color"],
					desc = "",
					get = function() return NameplateSCT.db.global.useCritColor end,
					set = function(_, newValue) NameplateSCT.db.global.useCritColor = newValue end,
					order = 7,
				},
				critColor = {
					type = 'color',
					name = L["Crit Color"],
					desc = "",
					disabled = function() return not NameplateSCT.db.global.useCritColor end,
					hasAlpha = false,
					set = function(_, r, g, b) NameplateSCT.db.global.critColor = rgbToHex(r, g, b) end,
					get = function() return hexToRGB(NameplateSCT.db.global.critColor) end,
					order = 8,
				},
				offsetNewLine = {
					type = 'description',
					name = "",
					desc = "",
					order = 9,
				},
				targetStrata = {
					type = 'select',
					name = L["Target Strata"],
					desc = "",
					get = function() return NameplateSCT.db.global.strata.target end,
					set = function(_, newValue)
						NameplateSCT.db.global.strata.target = newValue
						adjustStrata()
					end,
					values = stratas,
					order = 10,
				},
				modOffTargetStrata = {
					type = 'toggle',
					name = L["Use Separate Off-Target Strata"],
					desc = "",
					get = function() return NameplateSCT.db.global.modOffTargetStrata end,
					set = function(_, newValue) NameplateSCT.db.global.modOffTargetStrata = newValue end,
					order = 11,
				},
				offTargetStrata = {
					type = 'select',
					name = L["Off-Target Strata"],
					desc = "",
					disabled = function() return not NameplateSCT.db.global.modOffTargetStrata end,
					get = function() return NameplateSCT.db.global.strata.offTarget end,
					set = function(_, newValue) NameplateSCT.db.global.strata.offTarget = newValue end,
					values = stratas,
					order = 12,
				},
				xOffset = {
					type = 'range',
					name = L["X Offset"],
					desc = L["Has soft max/min, you can type whatever you'd like into the editbox"],
					softMin = -75,
					softMax = 75,
					step = 1,
					get = function() return NameplateSCT.db.global.xOffset end,
					set = function(_, newValue) NameplateSCT.db.global.xOffset = newValue end,
					order = 13,
					width = 1.5,
				},
				yOffset = {
					type = 'range',
					name = L["Y Offset"],
					desc = L["Has soft max/min, you can type whatever you'd like into the editbox"],
					softMin = -75,
					softMax = 75,
					step = 1,
					get = function() return NameplateSCT.db.global.yOffset end,
					set = function(_, newValue) NameplateSCT.db.global.yOffset = newValue end,
					order = 14,
					width = 1.5,
				},
				xVariance = {
					type = 'range',
					name = L["X Variance"],
					desc = L["Randomly varies the starting horizontal position of each damage number."],
					min = 0,
					softMax = 50,
					step = 1,
					get = function() return NameplateSCT.db.global.xVariance end,
					set = function(_, newValue) NameplateSCT.db.global.xVariance = newValue end,
					order = 15,
					width = 1.5,
				},
				yVariance = {
					type = 'range',
					name = L["Y Variance"],
					desc = L["Randomly varies the starting vertical position of each damage number."],
					min = 0,
					softMax = 50,
					step = 1,
					get = function() return NameplateSCT.db.global.yVariance end,
					set = function(_, newValue) NameplateSCT.db.global.yVariance = newValue end,
					order = 16,
					width = 1.5,
				},
				iconAppearance = {
				type = 'group',
				name = L["Icons"],
				order = 60,
				inline = true,
				disabled = function() return not NameplateSCT.db.global.enabled end,
				args = {
					showIcon = {
						type = 'toggle',
						name = L["Display Icon"],
						desc = "",
						get = function() return NameplateSCT.db.global.showIcon end,
						set = function(_, newValue) NameplateSCT.db.global.showIcon = newValue end,
						order = 1,
						width = "Half"
					},
					enableMSQ = {
						type = 'toggle',
						name = L["Enable Masque"],
						desc = L["Let Masuqe skin the icons"],
						hidden = function() return not NameplateSCT.db.global.showIcon end,
						get = function() return NameplateSCT.db.global.enableMSQ end,
						set = function(_, newValue) NameplateSCT.db.global.enableMSQ = newValue end,
						order = 2,
						width = "Half"
					},
					iconScale = {
						type = 'range',
						name = L["Icon Scale"],
						desc = L["Scale of the spell icon"],
						softMin = 0.5,
						softMax = 2,
						isPercent = true,
						step = 0.01,
						hidden = function() return not NameplateSCT.db.global.showIcon end,
						get = function() return NameplateSCT.db.global.iconScale end,
						set = function(_, newValue) NameplateSCT.db.global.iconScale = newValue end,
						order = 3,
						width = "Half"
					},
					iconPosition = {
						type = 'select',
						name = L["Position"],
						desc = "",
						hidden = function() return not NameplateSCT.db.global.showIcon end,
						get = function() return NameplateSCT.db.global.iconPosition or "Right" end,
						set = function(_, newValue) NameplateSCT.db.global.iconPosition = newValue end,
						values = positionValues,
						order = 6,
					},
					xOffsetIcon = {
						type = 'range',
						name = L["Icon X Offset"],
						hidden = function() return not NameplateSCT.db.global.showIcon end,
						softMin = -30,
						softMax = 30,
						step = 1,
						get = function() return NameplateSCT.db.global.xOffsetIcon or 0 end,
						set = function(_, newValue) NameplateSCT.db.global.xOffsetIcon = newValue end,
						order = 7,
						width = "Half",
					},
					yOffsetIcon = {
						type = 'range',
						name = L["Icon Y Offset"],
						hidden = function() return not NameplateSCT.db.global.showIcon end,
						softMin = -30,
						softMax = 30,
						step = 1,
						get = function() return NameplateSCT.db.global.yOffsetIcon or 0 end,
						set = function(_, newValue) NameplateSCT.db.global.yOffsetIcon = newValue end,
						order = 8,
						width = "Half",
					},
				},
				},
			},
		},

		animationsPersonal = {
			type = 'group',
			name = L["Personal SCT Animations"],
			order = 60,
			inline = true,
			disabled = function() return not NameplateSCT.db.global.personal end,
			args = {
				normalPersonal = {
					type = 'select',
					name = L["Default"],
					desc = "",
					get = function() return NameplateSCT.db.global.animationsPersonal.normal end,
					set = function(_, newValue) NameplateSCT.db.global.animationsPersonal.normal = newValue end,
					values = animationValues,
					order = 5,
				},
				critPersonal = {
					type = 'select',
					name = L["Criticals"],
					desc = "",
					get = function() return NameplateSCT.db.global.animationsPersonal.crit end,
					set = function(_, newValue) NameplateSCT.db.global.animationsPersonal.crit = newValue end,
					values = animationValues,
					order = 10,
				},
				missPersonal = {
					type = 'select',
					name = L["Miss/Parry/Dodge/etc"],
					desc = "",
					get = function() return NameplateSCT.db.global.animationsPersonal.miss end,
					set = function(_, newValue) NameplateSCT.db.global.animationsPersonal.miss = newValue end,
					values = animationValues,
					order = 15,
				},
				damageColorPersonal = {
					type = 'toggle',
					name = L["Use Damage Type Color"],
					desc = "",
					get = function() return NameplateSCT.db.global.damageColorPersonal end,
					set = function(_, newValue) NameplateSCT.db.global.damageColorPersonal = newValue end,
					order = 40,
				},
				defaultColorPersonal = {
					type = 'color',
					name = L["Default Color"],
					desc = "",
					disabled = function() return NameplateSCT.db.global.damageColorPersonal end,
					hasAlpha = false,
					set = function(_, r, g, b) NameplateSCT.db.global.defaultColorPersonal = rgbToHex(r, g, b) end,
					get = function() return hexToRGB(NameplateSCT.db.global.defaultColorPersonal) end,
					order = 45,
				},
				xOffsetPersonal = {
					type = 'range',
					name = L["X Offset Personal SCT"],
					desc = L["Only used if Personal Nameplate is Disabled"],
					softMin = -400,
					softMax = 400,
					step = 1,
					get = function() return NameplateSCT.db.global.xOffsetPersonal end,
					set = function(_, newValue) NameplateSCT.db.global.xOffsetPersonal = newValue end,
					order = 50,
					width = "full",
				},
				yOffsetPersonal = {
					type = 'range',
					name = L["Y Offset Personal SCT"],
					desc = L["Only used if Personal Nameplate is Disabled"],
					softMin = -400,
					softMax = 400,
					step = 1,
					get = function() return NameplateSCT.db.global.yOffsetPersonal end,
					set = function(_, newValue) NameplateSCT.db.global.yOffsetPersonal = newValue end,
					order = 60,
					width = "full",
				},
			},
		},
		formatting = {
			type = 'group',
			name = L["Text Formatting"],
			order = 90,
			inline = true,
			disabled = function() return not NameplateSCT.db.global.enabled end,
			args = {
				truncateMethod = {
					type = 'select',
					name = L["Truncate Number"],
					desc = L["Truncate Method:\n\nWestern:\n  1000=>1K,\n  1000K=>1M\nAsia East:\n  10000=>1w"],
					get = function() return NameplateSCT.db.global.truncateMethod end,
					set = function(_, newValue) NameplateSCT.db.global.truncateMethod = newValue end,
					values = truncateMethod,
					order = 1,
				},
				truncateLetter = {
					type = 'toggle',
					name = L["Show Truncated Letter"],
					desc = "",
					hidden = function () return NameplateSCT.db.global.truncateMethod == 'NONE' end,
					-- disabled = function() return not NameplateSCT.db.global.enabled or NameplateSCT.db.global.truncateMethod == 'NONE' end,
					get = function() return NameplateSCT.db.global.truncateLetter end,
					set = function(_, newValue) NameplateSCT.db.global.truncateLetter = newValue end,
					order = 2,
				},
				commaSeperate = {
					type = 'toggle',
					name = L["Comma Seperate"],
					desc = "100000 -> 100,000",
					hidden = function() return NameplateSCT.db.global.truncateMethod ~= 'NONE' end,
					-- disabled = function() return not NameplateSCT.db.global.enabled or NameplateSCT.db.global.truncateMethod ~= 'WESTERN' end,
					get = function() return NameplateSCT.db.global.commaSeperate end,
					set = function(_, newValue) NameplateSCT.db.global.commaSeperate = newValue end,
					order = 3,
				},
				divider = {
					type = 'description',
					name = "",
					order = 50,
					width = "full",
				},
				size = {
					type = 'range',
					name = L["Size"],
					desc = "",
					min = 5,
					max = 72,
					step = 1,
					get = function() return NameplateSCT.db.global.formatting.size end,
					set = function(_, newValue) NameplateSCT.db.global.formatting.size = newValue end,
					order = 52,
				},
				alpha = {
					type = 'range',
					name = L["Alpha"],
					desc = "",
					min = 0.1,
					max = 1,
					step = .01,
					get = function() return NameplateSCT.db.global.formatting.alpha end,
					set = function(_, newValue) NameplateSCT.db.global.formatting.alpha = newValue end,
					order = 53,
				},

				displayOffTargetText = {
					type = 'toggle',
					name = L['Display Off-Target Text'],
					desc = "",
					get = function() return NameplateSCT.db.global.displayOffTargetText end,
					set = function(_, newValue) NameplateSCT.db.global.displayOffTargetText = newValue end,
					order = 99,
					width = "full",
				},

				useOffTargetAppearance = {
					type = 'toggle',
					name = L["Use Seperate Off-Target Text Appearance"],
					desc = "",
					disabled = function() return not NameplateSCT.db.global.displayOffTargetText end,
					get = function() return NameplateSCT.db.global.useOffTargetAppearance end,
					set = function(_, newValue) NameplateSCT.db.global.useOffTargetAppearance = newValue end,
					order = 100,
					width = "full",
				},
				offTarget = {
					type = 'group',
					name = L["Off-Target Text Appearance"],
					disabled = function() return not NameplateSCT.db.global.useOffTargetAppearance or not NameplateSCT.db.global.displayOffTargetText end,
					order = 101,
					inline = true,
					args = {
						size = {
							type = 'range',
							name = L["Size"],
							desc = "",
							min = 5,
							max = 72,
							step = 1,
							get = function() return NameplateSCT.db.global.offTargetFormatting.size end,
							set = function(_, newValue) NameplateSCT.db.global.offTargetFormatting.size = newValue end,
							order = 2,
						},
						alpha = {
							type = 'range',
							name = L["Alpha"],
							desc = "",
							min = 0.1,
							max = 1,
							step = .01,
							get = function() return NameplateSCT.db.global.offTargetFormatting.alpha end,
							set = function(_, newValue) NameplateSCT.db.global.offTargetFormatting.alpha = newValue end,
							order = 3,
						},
					},
				},
			},
		},
		sizing = {
			type = 'group',
			name = L["Sizing Modifiers"],
			order = 100,
			inline = true,
			disabled = function() return not NameplateSCT.db.global.enabled end,
			args = {
				crits = {
					type = 'toggle',
					name = L["Embiggen Crits"],
					desc = "",
					get = function() return NameplateSCT.db.global.sizing.crits end,
					set = function(_, newValue) NameplateSCT.db.global.sizing.crits = newValue end,
					order = 1,
				},
				critsScale = {
					type = 'range',
					name = L["Embiggen Crits Scale"],
					desc = "",
					disabled = function() return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.sizing.crits end,
					min = 1,
					max = 3,
					step = .01,
					get = function() return NameplateSCT.db.global.sizing.critsScale end,
					set = function(_, newValue) NameplateSCT.db.global.sizing.critsScale = newValue end,
					order = 2,
					width = "double",
				},

				miss = {
					type = 'toggle',
					name = L["Embiggen Miss/Parry/Dodge/etc"],
					desc = "",
					get = function() return NameplateSCT.db.global.sizing.miss end,
					set = function(_, newValue) NameplateSCT.db.global.sizing.miss = newValue end,
					order = 10,
				},
				missScale = {
					type = 'range',
					name = L["Embiggen Miss/Parry/Dodge/etc Scale"],
					desc = "",
					disabled = function() return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.sizing.miss end,
					min = 1,
					max = 3,
					step = .01,
					get = function() return NameplateSCT.db.global.sizing.missScale end,
					set = function(_, newValue) NameplateSCT.db.global.sizing.missScale = newValue end,
					order = 11,
					width = "double",
				},

				smallHits = {
					type = 'toggle',
					name = L["Scale Down Small Hits"],
					desc = L["Scale down hits that are below a running average of your recent damage output"],
					disabled = function() return not NameplateSCT.db.global.enabled or NameplateSCT.db.global.sizing.smallHitsHide end,
					get = function() return NameplateSCT.db.global.sizing.smallHits end,
					set = function(_, newValue) NameplateSCT.db.global.sizing.smallHits = newValue end,
					order = 20,
				},
				smallHitsScale = {
					type = 'range',
					name = L["Small Hits Scale"],
					desc = "",
					disabled = function() return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.sizing.smallHits or NameplateSCT.db.global.sizing.smallHitsHide end,
					min = 0.33,
					max = 1,
					step = .01,
					get = function() return NameplateSCT.db.global.sizing.smallHitsScale end,
					set = function(_, newValue) NameplateSCT.db.global.sizing.smallHitsScale = newValue end,
					order = 21,
					width = "double",
				},
				smallHitsHide = {
					type = 'toggle',
					name = L["Hide Small Hits"],
					desc = L["Hide hits that are below a running average of your recent damage output"],
					get = function() return NameplateSCT.db.global.sizing.smallHitsHide end,
					set = function(_, newValue) NameplateSCT.db.global.sizing.smallHitsHide = newValue end,
					order = 22,
				},
				hideSmallHitsThreshold = {
					type = 'range',
					name = L["Hide Hits Threshold"],
					desc = L["Hide hits that are below this threshold."],
					min = 0,
					max = 10000000,
					softMax = 10000,
					step = 1,
					get = function() return NameplateSCT.db.global.sizing.hideSmallHitsThreshold end,
					set = function(_, newValue) NameplateSCT.db.global.sizing.hideSmallHitsThreshold = newValue end,
					order = 23,
					width = "full",
				},
			},
		},
	},
}

local filters = {
	name = L["Filters"],
	handler = NameplateSCT,
	type = 'group',
	args = {
		enable = {
			type = "toggle",
			name = L["Enable"],
			desc = "",
			get = function() return NameplateSCT.db.global.filterEnabled end,
			set = function(_, newValue) NameplateSCT.db.global.filterEnabled = newValue end,
			order = 1,
			width = 1,
		},
		inverseSpellFilter = {
			type = "toggle",
			name = L["Inverse Spell Filter"],
			desc = L["Inverse the logic and only show the spells in the list instead of filtering them away."],
			get = function() return NameplateSCT.db.global.inverseSpellFilter end,
			set = function(_, newValue) NameplateSCT.db.global.inverseSpellFilter = newValue end,
			order = 1.5,
			width = 1,
		},
		inverseFilter = {
			type = "toggle",
			name = L["Inverse NPC Filter"],
			desc = L["Inverse the logic and only show npc's in the list instead of filtering them away."],
			get = function() return NameplateSCT.db.global.inverseNPCFilter end,
			set = function(_, newValue) NameplateSCT.db.global.inverseNPCFilter = newValue end,
			order = 1.5,
			width = 1,
		},
		header = {
			type = "header",
			name = "",
			order = 2,
		},
		spellList = {
			type = "input",
			name = L["Spells"],
			multiline = 20,
			desc = L["Spellid/Spellname seperated by line\n\nWhite hits/melee = melee"],
			order = 3,
			width = 1,
			get = function() return NameplateSCT.db.global.filter end,
			set = function(_, newValue) NameplateSCT:updateFilterTable(newValue) end,
		},
		npcList = {
			type = "input",
			name = L["NPCs"],
			multiline = 20,
			desc = L["NPC id (eg: 23682) seperated by line\n\n The example is the Headless Horseman."],
			order = 4,
			width = 1,
			get = function() return NameplateSCT.db.global.npcFilter end,
			set = function(_, newValue) NameplateSCT:updateNPCFilterTable(newValue) end,
		}
	},
}

function NameplateSCT:OpenMenu()
	Settings.OpenToCategory(optionsMenuName)
end

function NameplateSCT:RegisterMenu()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("NameplateSCT", menu)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("Filters", filters)
	_, optionsMenuName = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateSCT", "NameplateSCT")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Filters", "Filters", "NameplateSCT")
end
