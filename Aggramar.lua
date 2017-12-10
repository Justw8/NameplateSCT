--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Aggramar", nil, 1984, 1712)
if not mod then return end
mod:RegisterEnableMob(121975)
mod.engageId = 2063
mod.respawnTime = 25

--------------------------------------------------------------------------------
-- Locals
--

local stage = 1
local wakeOfFlameCount = 1
local techniqueStarted = 0
local comboTime = nil
local foeBreakerCount = 1
local flameRendCount = 1
local techniqueCount = 0
local lastAbilityUsed = nil

local wave = 0
local waveBloodCounter = 0
local mobCollector = {}
local waveCollector = {}
local bloodAddMarks = {}
local currentBloodWave = 1
local trackingBlood = nil
local waveTimeCollector = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.cast_text = "|cff00ff00%.1fs"
	L.wave_cleared = "Wave %d Cleared!"

	L.track_blood = "Blood Tracker"
	L.track_blood_desc = "Enables messages related to the amount of elementals leftover."
	L.track_blood_icon = 245911 -- Wrought in Flame icon
end

--------------------------------------------------------------------------------
-- Initialization
--

local bloodMarker = mod:AddMarkerOption(false, "npc", 1, -15903, 1, 2, 3, 4, 5) -- Ember of Taeshalach
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		bloodMarker,
		"track_blood",
		245911, -- Wrought in Flame

		--[[ Stage One: Wrath of Aggramar ]]--
		{245990, "TANK"}, -- Taeshalach's Reach
		{245994, "SAY", "FLASH"}, -- Scorching Blaze
		{244693, "SAY"}, -- Wake of Flame
		{244688, "INFOBOX"}, -- Taeshalach Technique
		245458, -- Foe Breaker
		245463, -- Flame Rend
		245301, -- Searing Tempest

		--[[ Stage Two: Champion of Sargeras ]]--
		245983, -- Flare

		--[[ Stage Three: The Avenger ]]--
		246037, -- Empowered Flare

		--[[ Mythic ]]--
		254452, -- Ravenous Blaze
		255058, -- Empowered Flame Rend
		255061 -- Empowered Searing Tempest
	},{
		["stages"] = "general",
		[245990] = -15794, -- Stage One: Wrath of Aggramar
		[245983] = -15858, -- Stage Two: Champion of Sargeras
		[246037] = -15860, -- Stage Three: The Avenger
		[254452] = "mythic",
	}
end

function mod:OnBossEnable()
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1")

	--[[ Stage One: Wrath of Aggramar ]]--
	self:Log("SPELL_AURA_APPLIED", "TaeshalachsReach", 245990)
	self:Log("SPELL_AURA_APPLIED_DOSE", "TaeshalachsReach", 245990)
	self:Log("SPELL_AURA_APPLIED", "ScorchingBlaze", 245994)
	self:Log("SPELL_CAST_START", "WakeofFlame", 244693)
	self:Log("SPELL_CAST_START", "FoeBreaker", 245458, 255059)
	self:Log("SPELL_CAST_SUCCESS", "FoeBreakerSuccess", 245458, 255059)
	self:Log("SPELL_CAST_START", "FlameRend", 245463, 255058) -- Normal, Empowered
	self:Log("SPELL_CAST_SUCCESS", "FlameRendSuccess", 245463, 255058)
	self:Log("SPELL_CAST_START", "SearingTempest", 245301, 255061) -- Normal, Empowered
	self:Log("SPELL_CAST_SUCCESS", "SearingTempestSuccess", 245301, 255061)

	--[[ Intermission: Fires of Taeshalach ]]--
	self:Log("SPELL_AURA_APPLIED", "CorruptAegis", 244894)
	self:Log("SPELL_AURA_REMOVED", "CorruptAegisRemoved", 244894)
	self:Log("SPELL_CAST_SUCCESS", "BlazingEruption", 244912) -- Add dying

	--[[ Mythic ]]--
	self:Log("SPELL_AURA_APPLIED", "RavenousBlaze", 254452)
end

function mod:OnEngage()
	stage = 1
	wakeOfFlameCount = 1
	techniqueStarted = 0
	comboTime = GetTime() + 35
	foeBreakerCount = 1
	flameRendCount = 1

	techniqueCount = 0
	lastAbilityUsed = nil
	wipe(mobCollector)
	wipe(waveCollector)
	wipe(waveTimeCollector)
	wave = 0
	currentBloodWave = 1
	trackingBlood = nil

	if self:Mythic() then
		self:Bar(254452, 4.8) -- Ravenous Blaze
		self:Berserk(540)
	else
		self:Bar(245994, 8) -- Scorching Blaze
	end
	self:Bar(244693, self:Mythic() and 10.5 or 5.5) -- Wake of Flame
	self:Bar(244688, self:Mythic() and 14.5 or 35) -- Taeshalach Technique
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BlazingEruption(args) -- Add Death/Raid Explosion
	if (self:GetOption("track_blood") or self:GetOption(bloodMarker)) and trackingBlood then
		-- Remove the blood from marks list and wave List
		if self:GetOption(bloodMarker) then
			for key,guid in pairs(bloodAddMarks) do
				if guid == args.sourceGUID then
					bloodAddMarks[key] = nil
				end
			end
		end

		if mobCollector[args.sourceGUID] then
			waveCollector[mobCollector[args.sourceGUID]][args.sourceGUID] = nil -- Check which wave the add was from, incase its from an earlier wave
		end

		waveBloodCounter = 0
		if waveCollector[currentBloodWave] then
			for key,guid in pairs(waveCollector[currentBloodWave]) do -- Count how many bloods are left in this wave
				waveBloodCounter = waveBloodCounter + 1
			end
		end
		if waveBloodCounter > 0 then
			self:Message("track_blood", "Neutral", "Info", CL.mob_remaining:format(self:SpellName(-16686), waveBloodCounter), false)
		elseif currentBloodWave then -- Next wave time!
			self:Message("track_blood", "Neutral", "Info", L.wave_cleared:format(currentBloodWave), false)
			self:StopBar(CL.count:format(self:SpellName(245911), currentBloodWave))
			if not self:Mythic() or not waveTimeCollector[currentBloodWave+1] then -- Always 1 wave in heroic, or we are out of current waves.
				self:UnregisterTargetEvents()
				trackingBlood = nil
			else -- Start the new wave timer
				local bloodTimer = floor(waveTimeCollector[currentBloodWave+1] - GetTime())
				self:CDBar(245911, waveTimeCollector[currentBloodWave+1], CL.count:format(self:SpellName(245911), currentBloodWave)) -- Wrought in Flame (x)
			end
			currentBloodWave = currentBloodWave + 1
		end
	end
end

do
	function mod:bloodAddScanner(event, unit)
		local guid = UnitGUID(unit)
		local mobID = self:MobId(guid)
		if mobID == 122532 and not mobCollector[guid] then
			mobCollector[guid] = wave -- store which wave the add is from incase it dies early
			waveCollector[wave][guid] = true
			waveBloodCounter = 0
			for key,guid in pairs(waveCollector[wave]) do -- Count how many bloods are left in this wave
				waveBloodCounter = waveBloodCounter + 1
			end
		end
		if self:GetOption(bloodMarker) then
			if mobID == 122532 and waveCollector[currentBloodWave] and UnitPower(unit, 3) > 45 then -- Mark all above 30
				if waveCollector[currentBloodWave][guid] then
					for i = 1, 5 do -- Use only 5 marks, leaving 6, 7, 8 for raid use purposes
						if not bloodAddMarks[i] and not GetRaidTargetIndex(unit) then -- Don't re-mark the same add and re-use marks
							SetRaidTarget(unit, i)
							bloodAddMarks[i] = guid
							break
						end
					end
				end
			end
		end
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, _, _, spellId)
	if spellId == 244688 then -- Taeshalach Technique
		techniqueStarted = 1
		techniqueCount = 0
		foeBreakerCount = 1
		flameRendCount = 1
		lastAbilityUsed = nil
		comboTime = GetTime() + 60.8

		self:Bar(spellId, 60.8)
		if not self:Mythic() then -- Random Combo in Mythic
			self:Bar(245463, 4, CL.count:format(self:SpellName(244033), flameRendCount)) -- Flame Rend
			self:Bar(245301, 15.7) -- Searing Tempest

			-- Combo List in infobox
			self:OpenInfo(244688, self:SpellName(244688)) -- Taeshalach Technique
			self:SetInfo(244688, 1, "|cff00ff00>>")
			self:SetInfo(244688, 2, "|cff00fff9"..self:SpellName(245458)) -- Foe Breaker
			self:SetInfo(244688, 4, "|cffffff00"..self:SpellName(245463)) -- Flame Rend
			self:SetInfo(244688, 6, "|cff00fff9"..self:SpellName(245458)) -- Foe Breaker
			self:SetInfo(244688, 8, "|cffffff00"..self:SpellName(245463)) -- Flame Rend
			self:SetInfo(244688, 10, "|cffffff00"..self:SpellName(245301)) -- Searing Tempest

		else -- Use infobox to display the technique in mythic
			self:OpenInfo(244688, self:SpellName(244688)) -- Taeshalach Technique
		end
	elseif spellId == 244792 then -- Burning Will of Taeshalach, end of Taeshalach Technique but also casted in intermission
		if techniqueStarted == 1 then -- Check if he actually ends the combo, instead of being in intermission
			techniqueStarted = 0

			if self:Mythic() then
				self:Bar(254452, stage == 1 and 4 or 21.3) -- Ravenous Blaze
			else
				self:CDBar(245994, 4) -- Scorching Blaze
			end
			if stage == 1 then
				self:Bar(244693, 5) -- Wake of Flame
			elseif stage == 2 then
				self:Bar(245983, self:Mythic() and 6.6 or 9) -- Flare
			elseif stage == 3 then
				self:Bar(246037, self:Mythic() and 7.7 or 9) -- Empowered Flare
			end
			self:CloseInfo(244688)
			--[[
			mod:ScheduleTimer("UNIT_SPELLCAST_SUCCEEDED", 3, nil, nil, nil, nil, 244688)

			local fake = {spellId = 245458, spellName = "Foe Breaker"}
			mod:ScheduleTimer("FoeBreaker", 4, fake)
			mod:ScheduleTimer("FoeBreakerSuccess", 6.75, fake)

			fake = {spellId = 255058, spellName = "Flame Rend"}
			mod:ScheduleTimer("FlameRend", 8, fake)
			mod:ScheduleTimer("FlameRendSuccess", 10.75, fake)

			fake = {spellId = 245458, spellName = "Foe Breaker"}
			mod:ScheduleTimer("FoeBreaker", 12, fake)
			mod:ScheduleTimer("FoeBreakerSuccess", 13.75, fake)

			fake = {spellId = 255058, spellName = "Flame Rend"}
			mod:ScheduleTimer("FlameRend", 15, fake)
			mod:ScheduleTimer("FlameRendSuccess", 17.75, fake)


			fake = {spellId = 245301, spellName = "Searing Tempest"}
			mod:ScheduleTimer("SearingTempest", 19, fake)
			mod:ScheduleTimer("SearingTempestSuccess", 25, fake)

			mod:ScheduleTimer("UNIT_SPELLCAST_SUCCEEDED", 27, nil, nil, nil, nil, 244792)
			]]--
		end
	elseif spellId == 245983 then -- Flare
		self:Message(spellId, "Important", "Warning")
		if comboTime > GetTime() + 15.8 and not self:Mythic() then
			self:Bar(spellId, 15.8)
		end
	elseif spellId == 246037 then -- Empowered Flare
		self:Message(spellId, "Important", "Warning")
		-- Start tracking new blood wave (mythic)
		if self:Mythic() then
			wave = wave + 1
			waveCollector[wave] = {}
			waveTimeCollector[wave] = (GetTime() + (self:Mythic() and 165 or 180))
			if not trackingBlood and (self:GetOption("track_blood") or self:GetOption(bloodMarker)) then
				self:RegisterTargetEvents("bloodAddScanner") -- Adds spawning
				trackingBlood = true
				local bloodTimer = floor(waveTimeCollector[wave] - GetTime())
				self:CDBar(245911, bloodTimer, CL.count:format(self:SpellName(245911), currentBloodWave)) -- Wrought in Flame (x)
			end
		end
		if comboTime > GetTime() + 16.2 and not self:Mythic() then
			self:Bar(spellId, 16.2) -- Assume mythic CD
		end
	end
end

--[[ Stage One: Wrath of Aggramar ]]--
function mod:TaeshalachsReach(args)
	local amount = args.amount or 1
	if amount % 3 == 0 or amount > 7 then
		self:StackMessage(args.spellId, args.destName, amount, "Important", amount > 7 and "Alarm") -- Swap on 8+
	end
end

do
	local isOnMe, scheduled = nil, nil

	local function warn(self, spellId)
		if not isOnMe then
			self:Message(spellId, "Important")
		end
		isOnMe = nil
		scheduled = nil
	end

	function mod:ScorchingBlaze(args)
		if self:Me(args.destGUID) then
			isOnMe = true
			self:TargetMessage(args.spellId, args.destName, "Important", "Warning")
			self:Flash(args.spellId)
			self:Say(args.spellId)
		end
		if not scheduled then
			scheduled = self:ScheduleTimer(warn, 0.3, self, args.spellId)
			if comboTime > GetTime() + 7.3 then
				self:CDBar(args.spellId, 7.3)
			end
		end
	end
end

do
	local function printTarget(self, name, guid)
		self:TargetMessage(244693, name, "Attention", "Alert", nil, nil, true)
		if self:Me(guid) then
			self:Say(244693)
		end
	end
	function mod:WakeofFlame(args)
		self:GetBossTarget(printTarget, 0.7, args.sourceGUID)
		wakeOfFlameCount = wakeOfFlameCount + 1
		local cooldown = self:Mythic() and 12.1 or 24
		if comboTime > GetTime() + cooldown then
			self:Bar(args.spellId, cooldown)
		end
	end
end

do
	local timer, castOver = nil, 0

	local function updateInfoBox(self)
		local castTimeLeft = castOver - GetTime()
		if castTimeLeft > 0 then
			self:SetInfo(244688, techniqueCount == 1 and 1 or (techniqueCount*2)-1, L.cast_text:format(castTimeLeft))
		end
	end

	function mod:FoeBreaker(args)
		self:Message(245458, "Attention", "Alert", CL.count:format(args.spellName, foeBreakerCount))
		foeBreakerCount = foeBreakerCount + 1
		techniqueCount = techniqueCount + 1
		castOver = GetTime() + 2.75
		timer = self:ScheduleRepeatingTimer(updateInfoBox, 0.1, self)
		if foeBreakerCount == 2 and not self:Mythic() then -- Random Combo in Mythic
			self:Bar(args.spellId, 7.5, CL.count:format(args.spellName, foeBreakerCount))
		else -- Mythic
			if techniqueCount == 2 then -- Build remaining list
				self:SetInfo(244688, 1, "")
				self:SetInfo(244688, 2, "|cffff0000"..self:SpellName(245463)) -- Flame Rend
				self:SetInfo(244688, 3, "|cff00ff00>>")
				self:SetInfo(244688, 4, "|cff00fff9"..self:SpellName(245458)) -- Foe Breaker
				self:SetInfo(244688, 6, "|cff00fff9"..self:SpellName(245458)) -- Foe Breaker
				self:SetInfo(244688, 8, "|cffffff00"..self:SpellName(245301)) -- Searing Tempest
				self:SetInfo(244688, 10, "|cffffff00"..self:SpellName(245463)) -- Flame Rend
			end
		end

		if lastAbilityUsed then
			self:SetInfo(244688, (techniqueCount*2)-3, "")
			self:SetInfo(244688, (techniqueCount*2)-2, "|cffff0000"..lastAbilityUsed)
		end
		self:SetInfo(244688, techniqueCount*2, "|cff00ff00"..self:SpellName(245458).."") -- Foe Breaker
		lastAbilityUsed = self:SpellName(245458)
	end

	function mod:FoeBreakerSuccess(args)
		self:SetInfo(244688, (techniqueCount*2)-1, "")
		self:SetInfo(244688, (techniqueCount*2), "|cffff0000"..self:SpellName(245458))
		self:SetInfo(244688, (techniqueCount*2)+1, "|cff00ff00>>")
		self:CancelTimer(timer)
		timer = nil
	end

	function mod:FlameRend(args)
		self:Message(args.spellId, "Important", "Alarm", CL.count:format(args.spellName, flameRendCount))
		flameRendCount = flameRendCount + 1
		techniqueCount = techniqueCount + 1
		castOver = GetTime() + 2.75
		timer = self:ScheduleRepeatingTimer(updateInfoBox, 0.1, self)
		if flameRendCount == 2 and not self:Mythic() then -- Random Combo in Mythic
			self:Bar(args.spellId, 7.5, CL.count:format(args.spellName, flameRendCount))
		else -- Mythic
			if techniqueCount == 2 then -- Build remaining list
				self:SetInfo(244688, 1, "")
				self:SetInfo(244688, 2, "|cffff0000"..self:SpellName(245458)) -- Foe Breaker
				self:SetInfo(244688, 3, "|cff00ff00>>")
				self:SetInfo(244688, 4, "|cff00ff00"..self:SpellName(245463)) -- Flame Rend
				self:SetInfo(244688, 6, "|cffffff00"..self:SpellName(245301)) -- Searing Tempest
				self:SetInfo(244688, 8, "|cff00fff9"..self:SpellName(245458)) -- Foe Breaker
				self:SetInfo(244688, 10, "|cffffff00"..self:SpellName(245463)) -- Flame Rend
			end
		end
		if lastAbilityUsed then
			self:SetInfo(244688, (techniqueCount*2)-3, "")
			self:SetInfo(244688, (techniqueCount*2)-2, "|cffff0000"..lastAbilityUsed)
		end
		self:SetInfo(244688, (techniqueCount*2)-1, "|cff00ff00>>")
		self:SetInfo(244688, techniqueCount*2, "|cff00ff00"..self:SpellName(245463)) -- Flame Rend
		lastAbilityUsed = self:SpellName(245463)
	end

	function mod:FlameRendSuccess(args)
		self:SetInfo(244688, (techniqueCount*2)-1, "")
		self:SetInfo(244688, (techniqueCount*2), "|cffff0000"..self:SpellName(245463))
		if techniqueCount < 5 then -- otherwise there is no more
			self:SetInfo(244688, (techniqueCount*2)+1, "|cff00ff00>>")
		end
		self:CancelTimer(timer)
		timer = nil
	end

	function mod:SearingTempest(args)
		self:Message(args.spellId, "Urgent", "Warning")
		self:CastBar(args.spellId, 6)
		techniqueCount = techniqueCount + 1
		castOver = GetTime() + 6
		timer = self:ScheduleRepeatingTimer(updateInfoBox, 0.1, self)

		if self:Mythic() then
			if techniqueCount == 2 and flameRendCount == 2 then -- Build remaining list
				self:SetInfo(244688, 1, "")
				self:SetInfo(244688, 2, "|cffff0000"..self:SpellName(245463)) -- Flame Rend
				self:SetInfo(244688, 3, "|cff00ff00>>")
				self:SetInfo(244688, 4, "|cff00ff00"..self:SpellName(245301)) -- Searing Tempest
				self:SetInfo(244688, 6, "|cff00fff9"..self:SpellName(245458)) -- Foe Breaker
				self:SetInfo(244688, 8, "|cff00fff9"..self:SpellName(245458)) -- Foe Breaker
				self:SetInfo(244688, 10, "|cffffff00"..self:SpellName(245463)) -- Flame Rend
			elseif techniqueCount == 2 and foeBreakerCount == 2 then
				self:SetInfo(244688, 1, "")
				self:SetInfo(244688, 2, "|cffff0000"..self:SpellName(245458)) -- Foe Breaker
				self:SetInfo(244688, 3, "|cff00ff00>>")
				self:SetInfo(244688, 4, "|cff00ff00"..self:SpellName(245301)) -- Searing Tempest
				self:SetInfo(244688, 6, "|cffffff00"..self:SpellName(245463)) -- Flame Rend
				self:SetInfo(244688, 8, "|cff00fff9"..self:SpellName(245458)) -- Foe Breaker
				self:SetInfo(244688, 10, "|cffffff00"..self:SpellName(245463)) -- Flame Rend
			end
		end
		if lastAbilityUsed then
			self:SetInfo(244688, (techniqueCount*2)-3, "")
			self:SetInfo(244688, (techniqueCount*2)-2, "|cffff0000"..lastAbilityUsed)
		end
		self:SetInfo(244688, (techniqueCount*2)-1, "|cff00ff00>>")
		self:SetInfo(244688, techniqueCount*2, "|cff00ff00"..self:SpellName(245301)) -- Searing Tempest
		lastAbilityUsed = self:SpellName(245301)
	end

	function mod:SearingTempestSuccess(args)
		self:SetInfo(244688, (techniqueCount*2)-1, "")
		self:SetInfo(244688, (techniqueCount*2), "|cffff0000"..args.spellName)
		if techniqueCount < 5 then -- otherwise there is no more
			self:SetInfo(244688, (techniqueCount*2)+1, "|cff00ff00>>")
		end
		self:CancelTimer(timer)
		timer = nil
	end
end

--[[ Intermission: Fires of Taeshalach ]]--
function mod:CorruptAegis()
	techniqueStarted = 0 -- End current technique
	self:CloseInfo(244688)
	self:Message("stages", "Neutral", "Long", CL.intermission, false)
	self:StopBar(245994) -- Scorching Blaze
	self:StopBar(244693) -- Wake of Flame
	self:StopBar(244688) -- Taeshalach Technique
	self:StopBar(245458, CL.count:format(self:SpellName(245458), foeBreakerCount)) -- Foe Breaker
	self:StopBar(245463, CL.count:format(self:SpellName(245463), flameRendCount)) -- Flame Rend
	self:StopBar(245301) -- Searing Tempest
	self:StopBar(245983) -- Flare


	-- Reset all saved variables
	wipe(mobCollector)
	wipe(waveCollector)
	wipe(waveTimeCollector)
	wipe(bloodAddMarks)
	currentBloodWave = 1
	wave = 1
	waveCollector[wave] = {}

	if not trackingBlood and (self:GetOption("track_blood") or self:GetOption(bloodMarker)) then
		self:RegisterTargetEvents("bloodAddScanner") -- Adds spawning
		trackingBlood = true
	end
	waveTimeCollector[wave] = GetTime() + (self:Mythic() and 165 or 180)
	self:CDBar(245911, self:Mythic() and 165 or 180, CL.count:format(self:SpellName(245911), wave)) -- Wrought in Flame (x)
end

function mod:CorruptAegisRemoved()
	stage = stage + 1
	self:Message("stages", "Neutral", "Long", CL.stage:format(stage), false)

	if self:Mythic() then
		self:Bar(254452, 23) -- Ravenous Blaze
	else
		self:CDBar(245994, 6) -- Scorching Blaze
	end
	self:Bar(244688, 37.5) -- Taeshalach Technique
	if stage == 2 then
		self:Bar(245983, self:Mythic() and 8.4 or 10.5) -- Flare
	elseif stage == 3 then
		self:Bar(246037, self:Mythic() and 8.4 or 10) -- Empowered Flare
	end
end

--[[ Mythic ]]--
do
	local playerList = mod:NewTargetList()
	function mod:RavenousBlaze(args)
		if self:Me(args.destGUID) then
			self:Flash(args.spellId)
			self:Say(args.spellId)
		end
		playerList[#playerList+1] = args.destName
		if #playerList == 1 then
			local cooldown = stage == 1 and 23.1 or 60.1 -- this cooldown should only trigger in stage 1+
			if comboTime > GetTime() + cooldown then
				self:CDBar(args.spellId, cooldown)
			end
			self:ScheduleTimer("TargetMessage", 0.3, args.spellId, playerList, "Important", "Warning")
		end
	end
end

--[[
mod:ScheduleTimer("OnEngage", 2)
mod:ScheduleTimer("UNIT_SPELLCAST_SUCCEEDED", 3, nil, nil, nil, nil, 244688)

local fake2 = {spellId = 245458, spellName = "Foe Breaker"}
mod:ScheduleTimer("FoeBreaker", 4, fake2)
mod:ScheduleTimer("FoeBreakerSuccess", 6.75, fake2)

fake2 = {spellId = 255058, spellName = "Flame Rend"}
mod:ScheduleTimer("FlameRend", 8, fake2)
mod:ScheduleTimer("FlameRendSuccess", 10.75, fake2)

fake2 = {spellId = 245458, spellName = "Foe Breaker"}
mod:ScheduleTimer("FoeBreaker", 12, fake2)
mod:ScheduleTimer("FoeBreakerSuccess", 13.75, fake2)

fake2 = {spellId = 255058, spellName = "Flame Rend"}
mod:ScheduleTimer("FlameRend", 15, fake2)
mod:ScheduleTimer("FlameRendSuccess", 17.75, fake2)


fake2 = {spellId = 245301, spellName = "Searing Tempest"}
mod:ScheduleTimer("SearingTempest", 19, fake2)
mod:ScheduleTimer("SearingTempestSuccess", 25, fake2)

mod:ScheduleTimer("UNIT_SPELLCAST_SUCCEEDED", 27, nil, nil, nil, nil, 244792)

mod:Enable()
]]--
