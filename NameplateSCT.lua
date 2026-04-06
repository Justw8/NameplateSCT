---------------------------------------------------------------
-- NameplateSCT  –  Midnight rewrite (zero deps)
-- Patterns borrowed from MidnightBattleText (proven working)
---------------------------------------------------------------
local ADDON = "NameplateSCT"

-- Suppress "addon action forbidden" popup for us
do
    local orig = StaticPopup_Show
    StaticPopup_Show = function(which, a1, ...)
        if which == "ADDON_ACTION_FORBIDDEN" and type(a1) == "string" and a1:find(ADDON, 1, true) then return end
        return orig(which, a1, ...)
    end
end

-- ========================
--  COMPAT
-- ========================
local _, _, _, clientBuild = GetBuildInfo()
local isMidnight = clientBuild >= 120000
local blizzCvar  = isMidnight and "floatingCombatTextCombatDamage_v2" or "floatingCombatTextCombatDamage"

local RawSpellTex = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
local function SpellTex(id)
    if not id or id=="" or id=="melee" or id=="pet" then return nil end
    if issecretvalue and issecretvalue(id) then return nil end
    local ok,t = pcall(RawSpellTex, id); if ok and t then return t end
    if type(id)=="number" and C_Spell and C_Spell.GetSpellInfo then
        local ok2,info = pcall(C_Spell.GetSpellInfo, id)
        if ok2 and info and info.iconID then return info.iconID end
    end
end

local function IsSecret(v) return issecretvalue and issecretvalue(v) or false end
local function IsRestricted()
    if not C_RestrictedActions or not C_RestrictedActions.IsAddOnRestrictionActive then return false end
    local ok,r = pcall(C_RestrictedActions.IsAddOnRestrictionActive, 0)
    return ok and r or false
end

-- ========================
--  LOCALS
-- ========================
local addonReady, debugMode = false, false
local playerGUID
local unitToGuid, guidToUnit = {}, {}
local animating, rndX, rndY = {}, {}, {}
local arcDir = 1
local restricted = false

-- small hit average
local shCount, shTime, shAvg = 0, nil, 0

-- ========================
--  DATABASE
-- ========================
local db
local D = {
    enabled=true, font="Fonts\\FRIZQT__.TTF", fontFlag="OUTLINE", textShadow=false,
    fontSize=20, alpha=1,
    damageColor=true, defaultColor="ffff00", defaultColorPersonal="ff0000",
    useCritColor=false, critColor="ffff00",
    useMissColor=false, missColor="ffffff",
    useMissColorPersonal=false, missColorPersonal="ffffff",
    damageColorPersonal=false,
    showIcon=true, iconScale=1, iconPosition="RIGHT", xOffsetIcon=0, yOffsetIcon=0,
    xOffset=0, yOffset=0, xOffsetPersonal=0, yOffsetPersonal=-100,
    xVariance=0, yVariance=0,
    personal=false, personalOnly=false,
    displayOffTargetText=true, useOffTargetAppearance=true,
    offTargetSize=15, offTargetAlpha=0.5,
    shouldDisplayOverkill=false, showAbsorbDamage=true,
    truncate=true,
    animAbility="fountain", animCrit="verticalUp", animMiss="verticalUp",
    animAA="fountain", animAACrit="verticalUp", animSpeed=1,
    animPNorm="rainfall", animPCrit="verticalUp", animPMiss="verticalUp",
    sizeCrits=true, critsScale=1.5, sizeMiss=false, missScale=1.5,
    smallHits=true, smallHitsScale=0.66, smallHitsHide=false, hideThreshold=0,
    aaCritSizing=true, strata="HIGH",
}

local function InitDB()
    NameplateSCTDB = NameplateSCTDB or {}
    local old = NameplateSCTDB.global
    if old then
        for k in pairs(D) do if old[k]~=nil then NameplateSCTDB[k]=old[k] end end
        if old.formatting then NameplateSCTDB.fontSize=old.formatting.size; NameplateSCTDB.alpha=old.formatting.alpha end
        if old.animations then
            NameplateSCTDB.animAbility=old.animations.ability; NameplateSCTDB.animCrit=old.animations.crit
            NameplateSCTDB.animMiss=old.animations.miss; NameplateSCTDB.animAA=old.animations.autoattack
            NameplateSCTDB.animAACrit=old.animations.autoattackcrit; NameplateSCTDB.animSpeed=old.animations.animationspeed
        end
        if old.sizing then
            NameplateSCTDB.sizeCrits=old.sizing.crits; NameplateSCTDB.critsScale=old.sizing.critsScale
            NameplateSCTDB.smallHits=old.sizing.smallHits; NameplateSCTDB.smallHitsScale=old.sizing.smallHitsScale
        end
        if old.font and type(old.font)=="string" and not old.font:find("\\") then NameplateSCTDB.font=D.font end
        NameplateSCTDB.global=nil
    end
    for k,v in pairs(D) do if NameplateSCTDB[k]==nil then NameplateSCTDB[k]=v end end
    db = NameplateSCTDB
end

-- ========================
--  SCHOOL COLORS
-- ========================
if not SCHOOL_MASK_PHYSICAL then
    SCHOOL_MASK_PHYSICAL=Enum.Damageclass.MaskPhysical; SCHOOL_MASK_HOLY=Enum.Damageclass.MaskHoly
    SCHOOL_MASK_FIRE=Enum.Damageclass.MaskFire; SCHOOL_MASK_NATURE=Enum.Damageclass.MaskNature
    SCHOOL_MASK_FROST=Enum.Damageclass.MaskFrost; SCHOOL_MASK_SHADOW=Enum.Damageclass.MaskShadow
    SCHOOL_MASK_ARCANE=Enum.Damageclass.MaskArcane
end
local SCOL={[SCHOOL_MASK_PHYSICAL]="FFFF00",[SCHOOL_MASK_HOLY]="FFE680",[SCHOOL_MASK_FIRE]="FF8000",
    [SCHOOL_MASK_NATURE]="4DFF4D",[SCHOOL_MASK_FROST]="80FFFF",[SCHOOL_MASK_SHADOW]="8080FF",
    [SCHOOL_MASK_ARCANE]="FF80FF",melee="FFFFFF",pet="CC8400"}
-- Localized miss strings
local L_MISS = {
    enUS={ABSORB="Absorbed",BLOCK="Blocked",DEFLECT="Deflected",DODGE="Dodged",EVADE="Evaded",IMMUNE="Immune",MISS="Missed",PARRY="Parried",REFLECT="Reflected",RESIST="Resisted"},
    frFR={ABSORB="Absorb\195\169",BLOCK="Bloqu\195\169",DEFLECT="D\195\169vi\195\169",DODGE="Esquiv\195\169",EVADE="\195\137vit\195\169",IMMUNE="Immunis\195\169",MISS="Rat\195\169",PARRY="Par\195\169",REFLECT="Refl\195\169t\195\169",RESIST="R\195\169sist\195\169"},
    deDE={ABSORB="Absorbiert",BLOCK="Geblockt",DEFLECT="Abgelenkt",DODGE="Ausgewichen",EVADE="Entwischt",IMMUNE="Immun",MISS="Verfehlt",PARRY="Pariert",REFLECT="Reflektiert",RESIST="Widerstanden"},
    esES={ABSORB="Absorbido",BLOCK="Bloqueado",DEFLECT="Desviado",DODGE="Esquivado",EVADE="Evadido",IMMUNE="Inmune",MISS="Fallado",PARRY="Parado",REFLECT="Reflejado",RESIST="Resistido"},
    ptBR={ABSORB="Absorvido",BLOCK="Bloqueado",DEFLECT="Desviado",DODGE="Esquivado",EVADE="Evadido",IMMUNE="Imune",MISS="Errado",PARRY="Aparado",REFLECT="Refletido",RESIST="Resistido"},
    itIT={ABSORB="Assorbito",BLOCK="Bloccato",DEFLECT="Deviato",DODGE="Schivato",EVADE="Evaso",IMMUNE="Immune",MISS="Mancato",PARRY="Parato",REFLECT="Riflesso",RESIST="Resistito"},
    ruRU={ABSORB="\208\159\208\190\208\179\208\187\208\190\209\137\208\181\208\189\208\190",BLOCK="\208\145\208\187\208\190\208\186",DEFLECT="\208\158\209\130\208\186\208\187\208\190\208\189\208\181\208\189\208\190",DODGE="\208\163\208\186\208\187\208\190\208\189\208\181\208\189\208\184\208\181",EVADE="\208\163\208\178\208\181\209\128\209\130\208\186\208\176",IMMUNE="\208\152\208\188\208\188\209\131\208\189\208\184\209\130\208\181\209\130",MISS="\208\159\209\128\208\190\208\188\208\176\209\133",PARRY="\208\159\208\176\209\128\208\184\209\128\208\190\208\178\208\176\208\189\208\184\208\181",REFLECT="\208\158\209\130\209\128\208\176\208\182\208\181\208\189\208\184\208\181",RESIST="\208\161\208\190\208\191\209\128\208\190\209\130\208\184\208\178\208\187\208\181\208\189\208\184\208\181"},
    koKR={ABSORB="\237\157\161\236\136\152",BLOCK="\235\176\169\236\150\180",DEFLECT="\235\185\151\234\178\168",DODGE="\237\154\140\237\148\188",EVADE="\237\154\140\237\148\188",IMMUNE="\235\169\180\236\151\173",MISS="\235\185\151\235\130\152\234\176\144",PARRY="\235\172\180\235\166\172\235\167\137\236\157\140",REFLECT="\235\176\152\236\130\172",RESIST="\236\160\128\237\149\173"},
    zhCN={ABSORB="\229\144\184\230\148\182",BLOCK="\230\160\188\230\140\161",DEFLECT="\229\129\143\232\189\172",DODGE="\232\186\178\233\151\170",EVADE="\233\151\170\233\129\191",IMMUNE="\229\133\141\231\150\171",MISS="\230\156\170\228\184\173",PARRY="\230\139\155\230\140\161",REFLECT="\229\143\141\229\176\132",RESIST="\230\138\181\230\138\151"},
    zhTW={ABSORB="\229\144\184\230\148\182",BLOCK="\230\160\188\230\140\163",DEFLECT="\229\129\143\232\189\172",DODGE="\232\186\178\233\150\131",EVADE="\233\150\131\233\129\191",IMMUNE="\229\133\141\231\150\171",MISS="\230\156\170\228\184\173",PARRY="\230\139\155\230\140\163",REFLECT="\229\143\141\229\176\132",RESIST="\230\138\181\230\138\151"},
}
L_MISS.enGB=L_MISS.enUS; L_MISS.esMX=L_MISS.esES; L_MISS.ptPT=L_MISS.ptBR
local clientLocale = GetLocale()
local MISS = L_MISS[clientLocale] or L_MISS.enUS
local INV={TOP="BOTTOM",BOTTOM="TOP",LEFT="RIGHT",RIGHT="LEFT",TOPLEFT="BOTTOMRIGHT",
    TOPRIGHT="BOTTOMLEFT",BOTTOMLEFT="TOPRIGHT",BOTTOMRIGHT="TOPLEFT",CENTER="CENTER"}

-- ========================
--  EASING
-- ========================
local function eIQ(t,b,c,d) t=t/d; return c*t*t+b end
local function eIE(t,b,c,d) if t==0 then return b end; return c*2^(10*(t/d-1))+b end
local function eOQ(t,b,c,d) t=t/d-1; return c*(t^5+1)+b end
local function eIQn(t,b,c,d) t=t/d; return c*t^5+b end

-- ========================
--  FONTSTRING POOL
-- ========================
local fsPool, fsCnt = {}, 0
local animFrame = CreateFrame("Frame",nil,UIParent)

local function GetFS()
    if not db then return nil end
    local fs
    if #fsPool>0 then fs=table.remove(fsPool) else
        fsCnt=fsCnt+1; local f=CreateFrame("Frame",nil,UIParent)
        pcall(f.SetFrameStrata, f, db.strata or "HIGH"); f:SetFrameLevel(fsCnt)
        f:SetSize(1,1); f:Show()
        fs=f:CreateFontString(); fs:SetParent(f)
    end
    fs:SetFont(db.font,15,db.fontFlag)
    fs:SetShadowOffset(db.textShadow and 1 or 0, db.textShadow and -1 or 0)
    fs:SetAlpha(1); fs:SetDrawLayer("OVERLAY"); fs:SetText(""); fs:Show()
    if db.showIcon and not fs.icon then fs.icon=fs:GetParent():CreateTexture(nil,"OVERLAY") end
    if fs.icon then fs.icon:SetAlpha(1); fs.icon:Hide() end
    return fs
end

local function Recycle(fs)
    if not fs then return end
    fs:SetAlpha(0); fs:Hide(); fs:ClearAllPoints()
    animating[fs]=nil; rndX[fs]=nil; rndY[fs]=nil
    fs.dist=nil;fs.atop=nil;fs.abot=nil;fs.axd=nil;fs.anim=nil;fs.dur=nil;fs.t0=nil;fs.anch=nil
    fs.unit=nil;fs.guid=nil;fs.pow=nil;fs.sh=nil;fs.fsz=nil;fs.txt=nil;fs.rfx=nil;fs.rfy=nil
    if fs.icon then fs.icon:ClearAllPoints(); fs.icon:SetAlpha(0); fs.icon:Hide() end
    if db then pcall(fs.SetFont, fs, db.font, 15, db.fontFlag) end
    table.insert(fsPool, fs)
end

-- ========================
--  ANIMATION
-- ========================
local V=75; local AXn,AXx=50,150; local AYTn,AYTx=10,50; local AYBn,AYBx=10,50
local RXx=75; local RYn,RYx=50,100; local RSn,RSx=5,15

local function PowSz(el,dur,s,m,f)
    if el>=dur then return f end
    if el/dur<.5 then return eOQ(el,s,m-s,dur/2) else return eIQn(el-dur/2,m,f-m,dur/2) end
end

local function OnUpdate()
    if not next(animating) then animFrame:SetScript("OnUpdate",nil); return end
    for fs in pairs(animating) do
        local el=GetTime()-fs.t0
        if el>fs.dur then Recycle(fs) else
            local a0=db.alpha
            if db.useOffTargetAppearance and fs.unit and fs.unit~="player" then
                local ok,tgt=pcall(UnitIsUnit,fs.unit,"target"); if ok and not tgt then a0=db.offTargetAlpha end
            end
            fs:SetAlpha(math.max(0,math.min(1, eIE(el,a0,-a0,fs.dur))))
            if fs.pow and fs.anim~="elastic" then
                local h,ic=fs.sh,db.iconScale
                if el<fs.dur/6 then
                    local sz=PowSz(el,fs.dur/6,h/2,h*2,h); fs:SetText(fs.txt); fs:SetTextHeight(sz)
                    if fs.icon and fs.icon:IsShown() then fs.icon:SetSize(sz*ic,sz*ic) end
                else
                    fs.pow=nil; fs:SetTextHeight(h); fs:SetFont(db.font,fs.fsz,db.fontFlag); fs:SetText(fs.txt)
                    if fs.icon and fs.icon:IsShown() then fs.icon:SetSize(h*ic,h*ic) end
                end
            end
            local dx,dy=0,0
            if fs.anim=="verticalUp" then dy=eIQ(el,0,fs.dist,fs.dur)
            elseif fs.anim=="verticalDown" then dy=eIQ(el,0,-fs.dist,fs.dur)
            elseif fs.anim=="fountain" then
                local p=el/fs.dur; dx=p*fs.axd
                dy=-(4*fs.atop-2*fs.abot)*p*p+(4*fs.atop-fs.abot)*p
            elseif fs.anim=="rainfall" then dy=eIQ(el,0,-fs.dist,fs.dur)+fs.rfy; dx=fs.rfx
            elseif fs.anim=="elastic" then
                -- Blizzard-style: pop big, shrink with bounce, float up slowly, slight horizontal drift
                local p=el/fs.dur
                local h,ic=fs.sh or 5,db.iconScale
                -- Scale: 1.8x at start → bounce to 0.85 → settle at 1.0, during first 25% of duration
                local scale=1
                if p<0.08 then scale=1+0.8*(p/0.08)          -- grow to 1.8
                elseif p<0.16 then scale=1.8-0.95*((p-0.08)/0.08) -- shrink to 0.85
                elseif p<0.25 then scale=0.85+0.15*((p-0.16)/0.09) -- settle to 1.0
                end
                local sz=h*scale; if sz<1 then sz=1 end
                fs:SetTextHeight(sz)
                if fs.icon and fs.icon:IsShown() then fs.icon:SetSize(sz*ic,sz*ic) end
                -- Movement: slow float up + gentle horizontal drift
                dy = eOQ(el,0,fs.dist*0.6,fs.dur)
                dx = fs.axd * p
            end
            local alive=(fs.unit=="player")
            if not alive and fs.anch then local ok,s=pcall(fs.anch.IsShown,fs.anch); alive=ok and s end
            if alive and fs.anch then
                fs:ClearAllPoints()
                local ox=(fs.unit=="player") and db.xOffsetPersonal or db.xOffset
                local oy=(fs.unit=="player") and db.yOffsetPersonal or db.yOffset
                fs:SetPoint("CENTER",fs.anch,"CENTER",ox+dx+(rndX[fs]or 0),oy+dy+(rndY[fs]or 0))
            else Recycle(fs) end
        end
    end
end

local function Animate(fs,anchor,dur,anim)
    anim=anim or "verticalUp"; fs.anim=anim; fs.dur=dur; fs.t0=GetTime()
    fs.anch=(anchor=="player") and UIParent or anchor
    if anim=="verticalUp" or anim=="verticalDown" then fs.dist=V
    elseif anim=="fountain" then
        fs.atop=math.random(AYTn,AYTx); fs.abot=-math.random(AYBn,AYBx)
        fs.axd=arcDir*math.random(AXn,AXx); arcDir=-arcDir
    elseif anim=="rainfall" then
        fs.dist=math.random(RYn,RYx); fs.rfx=math.random(-RXx,RXx); fs.rfy=-math.random(RSn,RSx)
    elseif anim=="elastic" then
        fs.dist=V; fs.axd=arcDir*math.random(5,25); arcDir=-arcDir
    end
    animating[fs]=true
    rndX[fs]=db.xVariance>0 and math.random(-db.xVariance,db.xVariance) or 0
    rndY[fs]=db.yVariance>0 and math.random(-db.yVariance,db.yVariance) or 0
    if not animFrame:GetScript("OnUpdate") then animFrame:SetScript("OnUpdate",OnUpdate) end
end

-- ========================
--  SPELL TRACKING  (must be before DISPLAY for forward ref)
-- ========================
local lastCastId, lastCastTime, lastCastName
local SPELL_WIN = 1.5       -- window for "most recent cast" (direct hits)
local SPELL_DOT_WIN = 30    -- window for school-based fallback (DoTs/AoE ground)
-- Cache: schoolMask -> {spellId, spellName, time}
local spellBySchool = {}
local spellFrame = CreateFrame("Frame")
pcall(function() spellFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED","player","pet") end)
pcall(function() spellFrame:RegisterUnitEvent("UNIT_SPELLCAST_START","player") end)
pcall(function() spellFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START","player") end)
spellFrame:SetScript("OnEvent", function(_,_,unit,_,spellId)
    if unit~="player" or not spellId or spellId==0 then return end
    lastCastId=spellId; lastCastTime=GetTime()
    lastCastName=C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellId) or nil
    -- Cache by school for DoT/AoE fallback
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellId)
    -- GetSpellSchool may not exist; try to get school from spell info or just cache generically
    local school
    if C_Spell and C_Spell.GetSchoolString then
        -- No direct GetSpellSchool API, but we can cache by spellId for later lookup
    end
    -- Store by spellId so we can match later; also store as "last cast" per generic use
    spellBySchool[spellId] = {id=spellId, name=lastCastName, time=GetTime()}
end)
local function LastSpell()
    if lastCastId and lastCastTime and GetTime()-lastCastTime<SPELL_WIN then return lastCastId,lastCastName end
end
-- Fallback: find a recent spell that matches by checking all cached spells
local function LastSpellFallback()
    local now = GetTime()
    local best, bestTime
    for sid, info in pairs(spellBySchool) do
        if now - info.time < SPELL_DOT_WIN then
            if not bestTime or info.time > bestTime then
                best = info; bestTime = info.time
            end
        else
            spellBySchool[sid] = nil  -- cleanup expired
        end
    end
    if best then return best.id, best.name end
end

-- ========================
--  DISPLAY
-- ========================
local function Trunc(n) if n>=1e6 then return("%.1fM"):format(n/1e6) elseif n>=1e4 then return("%.0fk"):format(n/1e3) elseif n>=1e3 and db.truncate then return("%.1fk"):format(n/1e3) end; return tostring(n) end

local function Col(txt,guid,school,name,crit)
    local c; local me=(guid==playerGUID)
    if not me then
        if crit and db.useCritColor then c=db.critColor
        elseif db.damageColor and school and SCOL[school] then c=SCOL[school]
        elseif db.damageColor and name=="melee" then c=SCOL.melee
        else c=db.defaultColor end
    else
        if db.damageColorPersonal and school and SCOL[school] then c=SCOL[school]
        else c=db.defaultColorPersonal end
    end
    return"|Cff"..c..txt.."|r"
end

local function Show(guid,text,size,anim,spId,pow,spName)
    local unit=guidToUnit[guid]; local np
    if unit then np=C_NamePlate.GetNamePlateForUnit(unit) end
    if guid==playerGUID and not unit then np="player" elseif not np then
        if debugMode then print("|cFFFF8800[NSCT-Show]|r SKIP no np, unit:",unit,"guid:",guid and guid:sub(-8)) end
        return
    end
    local fs=GetFS()
    if not fs then if debugMode then print("|cFFFF0000[NSCT-Show] GetFS nil!|r") end; return end
    if debugMode then print("|cFF00FF00[NSCT-Show] OK np:",np,"fs:",fs and "yes","text:",text:sub(1,20)) end
    fs.txt=text; fs:SetText(text); fs.fsz=size
    fs:SetFont(db.font,size,db.fontFlag)
    fs:SetShadowOffset(db.textShadow and 1 or 0, db.textShadow and -1 or 0)
    fs.sh=fs:GetStringHeight(); if fs.sh<=0 then fs.sh=5 end
    fs.pow=pow; fs.unit=unit; fs.guid=guid
    local tex=SpellTex(spId)
    if not tex and spName then tex=SpellTex(spName) end
    local isIncoming = (guid == playerGUID)
    if not tex and not isIncoming then local cid=LastSpell(); if cid then tex=SpellTex(cid) end end
    if not tex and not isIncoming then local cid=LastSpellFallback(); if cid then tex=SpellTex(cid) end end
    if debugMode then
        local secId = issecretvalue and spId and issecretvalue(spId) or false
        local cid = LastSpell()
        print("|cFF00FFFF[NSCT-icon]|r spId:",spId,"secret:",secId,"lastCast:",cid,"tex:",tex)
    end
    if db.showIcon and tex and fs.icon then
        fs.icon:Show(); fs.icon:SetTexture(tex)
        fs.icon:SetSize(size*db.iconScale,size*db.iconScale); fs.icon:ClearAllPoints()
        fs.icon:SetPoint(INV[db.iconPosition]or"LEFT",fs,db.iconPosition or"RIGHT",db.xOffsetIcon,db.yOffsetIcon)
    elseif fs.icon then fs.icon:Hide() end
    Animate(fs,np,db.animSpeed,anim)
end

-- ========================
--  DAMAGE / MISS
-- ========================
local function DmgEvt(guid,spName,amt,okill,school,crit,spId,absorb)
    if not db or not db.enabled then return end
    amt=amt or 0; absorb=absorb or 0; okill=okill or 0
    local me=(guid==playerGUID)
    -- Never show spell icons on incoming damage (player receiving hits)
    if me then spId=nil; spName="melee" end
    if debugMode then
        local unit=guidToUnit[guid]
        local n=0; local guids=""; for g,u in pairs(guidToUnit) do n=n+1; if n<=3 then guids=guids..g:sub(-8).."="..u.." " end end
        print("|cFFFF00FF[NSCT]|r",spId,spName,"amt:",amt,"guid:",guid and guid:sub(-8) or "nil","unit:",unit,"np:",guids)
    end
    if db.hideThreshold>(amt+absorb) then return end
    local aa=(spName=="melee" or spName=="pet"); local anim,pow
    if aa and crit then anim=me and db.animPCrit or db.animAACrit; pow=true
    elseif aa then anim=me and db.animPNorm or db.animAA; pow=false
    elseif crit then anim=me and db.animPCrit or db.animCrit; pow=true
    else anim=me and db.animPNorm or db.animAbility; pow=false end
    if anim=="disabled" then return end
    local unit=guidToUnit[guid]; local tgt=unit and UnitIsUnit(unit,"target")
    if not tgt and not me and not db.displayOffTargetText then return end
    local sz=db.fontSize
    if db.useOffTargetAppearance and not tgt and not me then sz=db.offTargetSize end
    local txt=Trunc(amt); if me then txt="-"..txt end
    if db.showAbsorbDamage and absorb>0 then txt=txt.." (A:"..Trunc(absorb)..")" end
    txt=Col(txt,guid,school,spName,crit)
    if (db.smallHits or db.smallHitsHide) and not me then
        if not shTime or shTime+30<GetTime() then shCount=0;shAvg=0 end
        shAvg=(shAvg*shCount+amt)/(shCount+1); shCount=shCount+1; shTime=GetTime()
        local th=0.5*shAvg
        if (not crit and amt<th) or (crit and amt/2<th) then
            if db.smallHitsHide then return end; sz=sz*db.smallHitsScale end
    end
    if db.sizeCrits and crit and not me then
        if aa and not db.aaCritSizing then pow=false else sz=sz*db.critsScale end
    end
    if sz<5 then sz=5 end
    if okill>0 and (db.shouldDisplayOverkill or me) then
        txt=Col(Trunc(amt).." (O:"..Trunc(okill)..")",guid,school,spName,crit) end
    if debugMode then print("|cFF00FF00[NSCT-PRE-SHOW]|r guid:",guid and guid:sub(-8),"sz:",sz,"anim:",anim) end
    local showOk, showErr = pcall(Show,guid,txt,sz,anim,spId,pow,spName)
    if not showOk and debugMode then print("|cFFFF0000[NSCT-SHOW-ERR]|r",showErr) end
end

local function MissEvt(guid,spName,mtype,spId)
    if not db or not db.enabled then return end
    local me=(guid==playerGUID)
    local anim=me and db.animPMiss or db.animMiss
    local col=me and (db.useMissColorPersonal and db.missColorPersonal or "ffffff") or (db.useMissColor and db.missColor or "ffffff")
    if anim=="disabled" then return end
    local sz=db.fontSize
    if db.useOffTargetAppearance and not me then
        local u=guidToUnit[guid]; if u then local ok,tgt=pcall(UnitIsUnit,u,"target"); if ok and not tgt then sz=db.offTargetSize end end
    end
    if db.sizeMiss and not me then sz=sz*db.missScale end
    Show(guid,"|Cff"..col..(MISS[mtype]or"Missed").."|r",sz,anim,spId,true,spName)
end

-- ========================
--  CLEU/UNIT_COMBAT DEDUP  (MBT pattern)
-- ========================
local cleuMarks = {}
local DEDUP = 0.15
local cleuLastMark = 0
local CLEU_ACTIVE = 5

local function MarkCLEU(amt, spId, crit)
    cleuLastMark = GetTime()
    local ok,key = pcall(function() return tostring(amt) end)
    if not ok then return end
    cleuMarks[key] = { t=GetTime(), spId=spId, crit=crit }
end
local function ConsumeMark(amt)
    local ok,key = pcall(function() return tostring(amt) end)
    if not ok then return false end
    local m = cleuMarks[key]
    if m and GetTime()-m.t <= DEDUP then cleuMarks[key]=nil; return true,m.spId,m.crit end
    return false
end

-- ========================
--  CLEU HANDLER  (pcall-wrapped, uses FLAGS not GUIDs — MBT pattern)
-- ========================
local CLEU_DMG = { SWING_DAMAGE=true, RANGE_DAMAGE=true, SPELL_DAMAGE=true, SPELL_PERIODIC_DAMAGE=true, DAMAGE_SHIELD=true }
local CLEU_MISS = { SWING_MISSED=true, RANGE_MISSED=true, SPELL_MISSED=true }

local function ParseCLEU()
    if not db or not db.enabled then return end
    local ok,err = pcall(function()
        local _,subEvent,_,_,_,srcFlags,_,_,_,dstFlags = CombatLogGetCurrentEventInfo()
        local MINE = COMBATLOG_OBJECT_AFFILIATION_MINE or 0x1
        local PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x400
        local PET = COMBATLOG_OBJECT_TYPE_PET or 0x1000
        local GUARD = COMBATLOG_OBJECT_TYPE_GUARDIAN or 0x2000
        local mySource = bit.band(srcFlags, MINE)~=0
        if debugMode then
            local rawDest2 = select(8, CombatLogGetCurrentEventInfo())
            local s2 = rawDest2 and not IsSecret(rawDest2) and rawDest2:sub(-8) or "secret"
            local inGU = rawDest2 and not IsSecret(rawDest2) and guidToUnit[rawDest2] or "?"
            print("|cFFAAAAFF[CLEU]|r",subEvent,"mine:",mySource,"dest:",s2,"inMap:",inGU)
        end
        if not mySource then return end
        local isPlayer = bit.band(srcFlags, PLAYER)~=0
        local isPet = bit.band(srcFlags, PET)~=0 or bit.band(srcFlags, GUARD)~=0

        -- Find dest GUID: CLEU destGUID may be secret, so try multiple strategies
        local safeGUID
        local strat = 0
        local rawDest = select(8, CombatLogGetCurrentEventInfo())
        local rawSecret = rawDest and IsSecret(rawDest)
        -- Strategy 1: direct lookup (works if destGUID isn't secret)
        if rawDest and not rawSecret then
            if guidToUnit[rawDest] then safeGUID = rawDest; strat = 1
            elseif rawDest == playerGUID then safeGUID = playerGUID; strat = 1 end
        end
        -- Strategy 2: scan nameplates by name
        if not safeGUID then
            local rawDestName = select(9, CombatLogGetCurrentEventInfo())
            if rawDestName and not IsSecret(rawDestName) then
                for u, g in pairs(unitToGuid) do
                    local ok, uname = pcall(UnitName, u)
                    if ok and uname == rawDestName then
                        safeGUID = g; strat = 2
                        break
                    end
                end
            end
        end
        -- Strategy 3: scan nameplates by GUID comparison via UnitGUID
        if not safeGUID and rawDest then
            for u, g in pairs(unitToGuid) do
                local ok, uguid = pcall(UnitGUID, u)
                if ok and uguid then
                    -- Compare safe UnitGUID with stored guid
                    if uguid == g then
                        -- Now try to match rawDest: use pcall equality in case it's secret
                        local eqOk, eq = pcall(function() return rawDest == uguid end)
                        if eqOk and eq then safeGUID = g; strat = 3; break end
                    end
                end
            end
        end
        -- Strategy 4: fallback to target
        if not safeGUID then
            local gOk,gv = pcall(UnitGUID,"target"); if gOk and gv then safeGUID=gv; strat=4 end
        end
        if debugMode and strat > 0 then
            print("|cFF88FFFF[NSCT-GUID]|r strat:",strat,"secret:",rawSecret,"safe:",safeGUID and safeGUID:sub(-8) or "nil")
        end

        -- Never display incoming damage from CLEU (handled by UNIT_COMBAT player path)
        if safeGUID == playerGUID then return end

        if CLEU_DMG[subEvent] then
            local amt, spId, critical
            if subEvent=="SWING_DAMAGE" then
                amt=select(12,CombatLogGetCurrentEventInfo())
                critical=select(18,CombatLogGetCurrentEventInfo())
            else
                spId=select(12,CombatLogGetCurrentEventInfo())
                amt=select(15,CombatLogGetCurrentEventInfo())
                critical=select(21,CombatLogGetCurrentEventInfo())
            end
            local isCrit=false
            if critical~=nil then local cok,cv=pcall(function() return critical==true end); isCrit=cok and cv end
            local school = subEvent=="SWING_DAMAGE" and 1 or select(14,CombatLogGetCurrentEventInfo())
            local overkill = subEvent=="SWING_DAMAGE" and select(13,CombatLogGetCurrentEventInfo()) or select(16,CombatLogGetCurrentEventInfo())
            local absorbed = subEvent=="SWING_DAMAGE" and select(17,CombatLogGetCurrentEventInfo()) or select(20,CombatLogGetCurrentEventInfo())
            local spName = isPet and "pet" or (subEvent=="SWING_DAMAGE" and "melee" or select(13,CombatLogGetCurrentEventInfo()))

            MarkCLEU(amt, spId, isCrit)
            if safeGUID then
                DmgEvt(safeGUID, spName, amt, overkill, school, isCrit, spId, absorbed)
            end
        elseif CLEU_MISS[subEvent] then
            local missType
            if subEvent=="SWING_MISSED" then missType=select(12,CombatLogGetCurrentEventInfo())
            else missType=select(15,CombatLogGetCurrentEventInfo()) end
            if safeGUID then MissEvt(safeGUID, nil, missType, nil) end
        end
    end)
    if not ok and debugMode then print("|cFFFF0000[NSCT-CLEU]|r",err) end
end

-- ========================
--  UNIT_COMBAT HANDLER  (MBT dedup pattern)
-- ========================
local function OnUnitCombat(unit, action, flagText, amount, schoolMask)
    if not db or not db.enabled then return end
    if not unit then return end
    local isCrit = (flagText=="CRITICAL")

    -- Incoming on player (unit=="player" means the player is taking damage)
    if unit=="player" then
        if db.personal then
            if action=="WOUND" then
                DmgEvt(playerGUID,"melee",amount,0,schoolMask or 1,isCrit,nil,0)
            elseif MISS[action] then
                MissEvt(playerGUID,nil,action,nil)
            end
        end
        return  -- always return for player, even if personal is off (don't let it fall through to outgoing)
    end

    -- Outgoing on any unit with a nameplate (target, nameplate1, nameplate2, etc.)
    local destGUID
    local gok,gv = pcall(UnitGUID, unit)
    if gok and gv then destGUID = gv end
    if not destGUID then return end

    -- Only show for units we have nameplates for
    if not guidToUnit[destGUID] and destGUID ~= playerGUID then return end

    local spId, spName = LastSpell()
    if not spId then spId, spName = LastSpellFallback() end

    if action=="WOUND" then
        local marked, cleuSpId, cleuCrit = ConsumeMark(amount)
        if marked then
            -- CLEU already displayed, dedup
        else
            -- Show damage: use last spell for icon
            DmgEvt(destGUID, spName or "melee", amount, 0, schoolMask or 1, isCrit, spId, 0)
        end
    elseif MISS[action] then
        MissEvt(destGUID, nil, action, nil)
    end
end

-- =========================================================
--  EVENT FRAME  (MBT pattern: only safe events at load time)
-- =========================================================
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
pcall(function() ev:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED") end)

-- UNIT_COMBAT for ALL units (not filtered to player+target)
-- This catches damage on all nameplate mobs, not just the target
local hasUC = false
local ucOk = pcall(function() ev:RegisterEvent("UNIT_COMBAT") end)
if ucOk then hasUC=true end

-- COMBAT_TEXT_UPDATE fallback only if no UNIT_COMBAT
if not hasUC then pcall(function() ev:RegisterEvent("COMBAT_TEXT_UPDATE") end) end

-- CLEU registered in PLAYER_LOGIN (not at load) to avoid taint — MBT pattern
ev:SetScript("OnEvent", function(_,event,a1,a2,a3,a4,a5)
    if event=="PLAYER_LOGIN" then
        InitDB(); playerGUID=UnitGUID("player"); addonReady=true
        restricted=IsRestricted()
        -- CLEU disabled: causes duplicates/triples and wrong icons on incoming damage
        -- UNIT_COMBAT + LastSpellFallback handles everything reliably
        -- catch up nameplates
        if C_NamePlate and C_NamePlate.GetNamePlates then
            for _,np in ipairs(C_NamePlate.GetNamePlates()) do
                local u=np.namePlateUnitToken; if u then local g=UnitGUID(u); if g then unitToGuid[u]=g;guidToUnit[g]=u end end
            end
        end
        pcall(BuildOptionsPanel)
        print("|cFF00FF00NameplateSCT|r loaded.  /nsct = options")
        return
    end
    if event=="PLAYER_REGEN_ENABLED" then
        -- CLEU disabled; UNIT_COMBAT handles everything
        return
    end
    if not addonReady or not db then return end

    if event=="NAME_PLATE_UNIT_ADDED" then
        local u=a1; local g=UnitGUID(u); if g then unitToGuid[u]=g;guidToUnit[g]=u end
    elseif event=="NAME_PLATE_UNIT_REMOVED" then
        local u=a1; local g=unitToGuid[u]; unitToGuid[u]=nil; if g then guidToUnit[g]=nil end
        for fs in pairs(animating) do if fs.unit==u then Recycle(fs) end end
    elseif event=="ADDON_RESTRICTION_STATE_CHANGED" then
        restricted=IsRestricted()
    elseif event=="UNIT_COMBAT" then
        OnUnitCombat(a1,a2,a3,a4,a5)
    elseif event=="COMBAT_TEXT_UPDATE" then
        if not hasUC and db.personal then
            local mt=a1; if not GetCurrentCombatTextEventInfo then return end
            pcall(function()
                local i1=GetCurrentCombatTextEventInfo()
                if mt=="DAMAGE" or mt=="DAMAGE_CRIT" or mt=="SPELL_DAMAGE" or mt=="SPELL_DAMAGE_CRIT" then
                    if i1 and not IsSecret(i1) then DmgEvt(playerGUID,"melee",i1,0,1,mt:find("CRIT")~=nil,nil,0) end
                elseif MISS[mt] then MissEvt(playerGUID,nil,mt,nil) end
            end)
        end
    end
end)

-- ========================
--  OPTIONS PANEL
-- ========================
local optFrame, optCatId
local AN={verticalUp="Vertical Up",verticalDown="Vertical Down",fountain="Fountain",rainfall="Rainfall",elastic="Elastic (Blizzard)",disabled="Disabled"}
local AL={"verticalUp","verticalDown","fountain","rainfall","elastic","disabled"}

-- Theme
local T = {
    gold     = {1, .82, 0},
    accent   = {.85, .65, .13},
    bg       = {.10, .10, .10, .92},
    bgLight  = {.16, .16, .16, .90},
    border   = {.35, .35, .35, .80},
    text     = {.90, .90, .90},
    textDim  = {.55, .55, .55},
    hover    = {1, 1, 1, .07},
    selBg    = {.85, .65, .13, .15},
    check    = {.85, .65, .13},
    rowH     = 22,
    pad      = 16,
    W        = 340,
}

-- ── Helpers ──────────────────────────────────────────────
local function Sep(p,y)
    local t=p:CreateTexture(nil,"ARTWORK")
    t:SetPoint("TOPLEFT",T.pad-2,y); t:SetPoint("TOPRIGHT",-T.pad+2,y)
    t:SetHeight(1); t:SetColorTexture(T.accent[1],T.accent[2],T.accent[3],.25)
    return y-8
end

local function Header(p,y,txt)
    y=y-4
    local h=p:CreateFontString(nil,"OVERLAY","GameFontNormal")
    h:SetPoint("TOPLEFT",T.pad,y); h:SetText(txt)
    h:SetTextColor(T.accent[1],T.accent[2],T.accent[3])
    y=y-20; y=Sep(p,y)
    return y
end

-- ── Checkbox ─────────────────────────────────────────────
local function CB(p,y,lbl,key,tip)
    local row=CreateFrame("Button",nil,p); row:SetPoint("TOPLEFT",T.pad,y); row:SetSize(T.W,20)
    local hl=row:CreateTexture(nil,"HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(T.hover[1],T.hover[2],T.hover[3],T.hover[4])
    -- box
    local box=CreateFrame("CheckButton",nil,row); box:SetPoint("LEFT",0,0); box:SetSize(16,16)
    local bd=box:CreateTexture(nil,"BACKGROUND"); bd:SetPoint("TOPLEFT",-1,1); bd:SetPoint("BOTTOMRIGHT",1,-1)
    bd:SetColorTexture(T.border[1],T.border[2],T.border[3],T.border[4])
    local bg=box:CreateTexture(nil,"BORDER"); bg:SetAllPoints(); bg:SetColorTexture(T.bg[1],T.bg[2],T.bg[3],T.bg[4])
    local ck=box:CreateTexture(nil,"ARTWORK"); ck:SetPoint("TOPLEFT",3,-3); ck:SetPoint("BOTTOMRIGHT",-3,3)
    ck:SetColorTexture(T.check[1],T.check[2],T.check[3],1)
    box:SetCheckedTexture(ck); box:SetChecked(db[key] and true or false)
    -- label
    local t=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); t:SetPoint("LEFT",box,"RIGHT",6,0); t:SetText(lbl)
    t:SetTextColor(T.text[1],T.text[2],T.text[3])
    -- clicks
    local function toggle() box:SetChecked(not box:GetChecked()); db[key]=box:GetChecked() and true or false end
    row:SetScript("OnClick",toggle)
    box:SetScript("OnClick",function(s) db[key]=s:GetChecked() and true or false end)
    if tip then
        row:SetScript("OnEnter",function(s) GameTooltip:SetOwner(s,"ANCHOR_RIGHT")
            GameTooltip:SetText(lbl,T.gold[1],T.gold[2],T.gold[3]); GameTooltip:AddLine(tip,1,1,1,true); GameTooltip:Show() end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
    return y-22
end

-- ── Slider ───────────────────────────────────────────────
local function SL(p,y,lbl,key,lo,hi,st)
    local f=CreateFrame("Frame",nil,p); f:SetPoint("TOPLEFT",T.pad,y); f:SetSize(T.W,36)
    local t=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); t:SetPoint("TOPLEFT",0,0)
    t:SetText(lbl); t:SetTextColor(T.text[1],T.text[2],T.text[3])
    local vt=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); vt:SetPoint("TOPRIGHT",0,0)
    vt:SetTextColor(T.gold[1],T.gold[2],T.gold[3])
    -- min/max labels
    local mn=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); mn:SetPoint("BOTTOMLEFT",0,0); mn:SetText(lo)
    local mx=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); mx:SetPoint("BOTTOMRIGHT",0,0); mx:SetText(hi)
    local s=CreateFrame("Slider",nil,f,"MinimalSliderTemplate")
    s:SetPoint("TOPLEFT",0,-16); s:SetSize(T.W,14); s:SetMinMaxValues(lo,hi); s:SetValueStep(st); s:SetObeyStepOnDrag(true)
    s:SetValue(db[key] or lo); vt:SetText(string.format("%.4g",db[key] or lo))
    s:SetScript("OnValueChanged",function(_,v) v=math.floor(v/st+.5)*st; db[key]=v; vt:SetText(string.format("%.4g",v)) end)
    return y-40
end

-- ── Dropdown popup ───────────────────────────────────────
local ddPopup, ddCloser
local function CloseDD()
    if ddCloser then ddCloser:Hide(); ddCloser=nil end
    if ddPopup then ddPopup:Hide(); ddPopup=nil end
end
local function ShowDD(anchor, vals, names, cur, onSelect, isFont)
    CloseDD()
    local RH = isFont and 24 or T.rowH
    local maxR = 12
    local visH = math.min(#vals,maxR)*RH+8
    local needScroll = #vals>maxR
    local popW = needScroll and 270 or 250

    -- Click-outside catcher (BELOW popup)
    ddCloser=CreateFrame("Button","NSCTDDCloser",UIParent)
    ddCloser:SetAllPoints(); ddCloser:SetFrameStrata("TOOLTIP"); ddCloser:SetFrameLevel(900)
    ddCloser:SetScript("OnClick",CloseDD)
    ddCloser:EnableMouse(true); ddCloser:Show()

    -- Popup (ABOVE closer)
    ddPopup=CreateFrame("Frame","NSCTDDPopup",UIParent,"BackdropTemplate")
    ddPopup:SetFrameStrata("TOOLTIP"); ddPopup:SetFrameLevel(910)
    ddPopup:SetClampedToScreen(true)
    ddPopup:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    ddPopup:SetBackdropColor(T.bg[1],T.bg[2],T.bg[3],.97); ddPopup:SetBackdropBorderColor(T.border[1],T.border[2],T.border[3],1)
    ddPopup:SetSize(popW, visH)
    ddPopup:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-2)
    ddPopup:EnableMouse(true)

    -- Content container
    local parent = ddPopup
    local contentW = popW - 8
    if needScroll then
        local sc=CreateFrame("ScrollFrame",nil,ddPopup,"UIPanelScrollFrameTemplate")
        sc:SetPoint("TOPLEFT",3,-3); sc:SetPoint("BOTTOMRIGHT",-22,3)
        sc:SetFrameLevel(912)
        local cnt=CreateFrame("Frame",nil,sc); cnt:SetSize(contentW-18,#vals*RH); sc:SetScrollChild(cnt)
        parent=cnt; contentW=contentW-18
    end

    for i,val in ipairs(vals) do
        local row=CreateFrame("Button",nil,parent)
        row:SetSize(contentW, RH)
        row:SetPoint("TOPLEFT",2,-(i-1)*RH-2)
        if not needScroll then row:SetFrameLevel(912) end
        -- Hover highlight
        local hl=row:CreateTexture(nil,"HIGHLIGHT"); hl:SetAllPoints()
        hl:SetColorTexture(T.accent[1],T.accent[2],T.accent[3],.22)
        -- Selected bg
        if val==cur then
            local sel=row:CreateTexture(nil,"BACKGROUND"); sel:SetAllPoints()
            sel:SetColorTexture(T.selBg[1],T.selBg[2],T.selBg[3],T.selBg[4])
        end
        -- Check mark
        if val==cur then
            local chk=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            chk:SetPoint("RIGHT",-6,0); chk:SetText("\226\156\148")
            chk:SetTextColor(T.gold[1],T.gold[2],T.gold[3])
        end
        -- Label
        local label=row:CreateFontString(nil,"OVERLAY")
        if isFont then
            local ok=pcall(label.SetFont, label, val, 13, "OUTLINE")
            if not ok or not label:GetFont() then label:SetFontObject(GameFontHighlightSmall) end
        else
            label:SetFontObject(GameFontHighlightSmall)
        end
        label:SetPoint("LEFT",8,0); label:SetPoint("RIGHT",-24,0); label:SetJustifyH("LEFT")
        label:SetText(names[val] or val or "?")
        if val==cur then label:SetTextColor(T.gold[1],T.gold[2],T.gold[3])
        else label:SetTextColor(T.text[1],T.text[2],T.text[3]) end
        row:SetScript("OnClick",function() onSelect(val); CloseDD() end)
    end
    ddPopup:Show()
end

-- ── Dropdown widget ──────────────────────────────────────
local function MakeDropBtn(p,y,w)
    local b=CreateFrame("Button",nil,p); b:SetPoint("TOPLEFT",0,y); b:SetSize(w or 220,22)
    local bg=b:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(T.bgLight[1],T.bgLight[2],T.bgLight[3],T.bgLight[4])
    local bd=b:CreateTexture(nil,"BORDER"); bd:SetPoint("TOPLEFT",-1,1); bd:SetPoint("BOTTOMRIGHT",1,-1)
    bd:SetColorTexture(T.border[1],T.border[2],T.border[3],T.border[4])
    local hl=b:CreateTexture(nil,"HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(T.hover[1],T.hover[2],T.hover[3],.12)
    b:SetNormalFontObject("GameFontHighlightSmall")
    local arr=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); arr:SetPoint("RIGHT",-8,0)
    arr:SetTextColor(T.accent[1],T.accent[2],T.accent[3]); arr:SetText("\226\150\188") -- ▼
    return b
end

local function DD(p,y,lbl,key,vals,names)
    local f=CreateFrame("Frame",nil,p); f:SetPoint("TOPLEFT",T.pad,y); f:SetSize(T.W,38)
    local t=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); t:SetPoint("TOPLEFT"); t:SetText(lbl)
    t:SetTextColor(T.text[1],T.text[2],T.text[3])
    local b=MakeDropBtn(f,-15)
    local function U()
        b:SetText(names[db[key]] or db[key] or "?")
        b:GetFontString():SetPoint("LEFT",8,0); b:GetFontString():SetJustifyH("LEFT")
    end; U()
    b:SetScript("OnClick",function() ShowDD(b,vals,names,db[key],function(v) db[key]=v; U() end) end)
    return y-40
end

-- ── Font dropdown with preview ───────────────────────────
local function GetAllFonts()
    local fonts,seen = {},{}
    local BUILTIN = {
        {"Friz Quadrata","Fonts\\FRIZQT__.TTF"},{"Arial Narrow","Fonts\\ARIALN.TTF"},
        {"Morpheus","Fonts\\MORPHEUS.TTF"},{"Skurri","Fonts\\skurri.TTF"},
        {"2002","Fonts\\2002.TTF"},{"2002 Bold","Fonts\\2002B.TTF"},
    }
    for _,fv in ipairs(BUILTIN) do
        local ok=pcall(function() local fs=UIParent:CreateFontString(); fs:SetFont(fv[2],12); fs:Hide() end)
        if ok then fonts[#fonts+1]={name=fv[1],path=fv[2]}; seen[fv[2]:lower()]=true end
    end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0",true)
    if LSM then
        local sm=LSM:HashTable("font")
        if sm then for n,p in pairs(sm) do
            if not seen[p:lower()] then
                local ok=pcall(function() local fs=UIParent:CreateFontString(); fs:SetFont(p,12); fs:Hide() end)
                if ok then fonts[#fonts+1]={name=n,path=p}; seen[p:lower()]=true end
            end
        end end
    end
    table.sort(fonts,function(a,b) return a.name:lower()<b.name:lower() end)
    return fonts
end

local function FontDD(p,y,key)
    local f=CreateFrame("Frame",nil,p); f:SetPoint("TOPLEFT",T.pad,y); f:SetSize(T.W,54)
    local t=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); t:SetPoint("TOPLEFT"); t:SetText("Font")
    t:SetTextColor(T.text[1],T.text[2],T.text[3])
    -- Preview
    local prev=f:CreateFontString(nil,"OVERLAY"); prev:SetPoint("TOPRIGHT",0,0)
    prev:SetTextColor(T.gold[1],T.gold[2],T.gold[3])
    local b=MakeDropBtn(f,-16,T.W)
    local function SetPrev()
        local ok=pcall(prev.SetFont,prev,db[key],15,db.fontFlag)
        prev:SetText(ok and "123 AaBb" or "?")
    end
    local function U()
        local fonts=GetAllFonts()
        local name=db[key]:match("([^\\]+)%.") or db[key]
        for _,fv in ipairs(fonts) do if fv.path==db[key] then name=fv.name; break end end
        b:SetText(name); b:GetFontString():SetPoint("LEFT",8,0); b:GetFontString():SetJustifyH("LEFT"); SetPrev()
    end; U()
    b:SetScript("OnClick",function()
        local fonts=GetAllFonts(); local v,n={},{}
        for _,fv in ipairs(fonts) do v[#v+1]=fv.path; n[fv.path]=fv.name end
        ShowDD(b,v,n,db[key],function(val) db[key]=val; U() end,true)
    end)
    return y-46
end

-- ── Build panel ──────────────────────────────────────────
function BuildOptionsPanel()
    if optFrame then return end
    optFrame=CreateFrame("Frame","NSCTOpts",UIParent); optFrame:SetSize(420,640)
    local sc=CreateFrame("ScrollFrame",nil,optFrame,"UIPanelScrollFrameTemplate")
    sc:SetPoint("TOPLEFT",6,-6); sc:SetPoint("BOTTOMRIGHT",-26,6)
    local c=CreateFrame("Frame",nil,sc); c:SetSize(380,2200); sc:SetScrollChild(c)
    local y=-12

    -- Title bar
    local title=c:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",T.pad,y); title:SetText("NameplateSCT")
    title:SetTextColor(T.gold[1],T.gold[2],T.gold[3])
    local ver=c:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    ver:SetPoint("LEFT",title,"RIGHT",8,-1); ver:SetText("v2.0-midnight")
    y=y-24; y=Sep(c,y)

    -- General
    y=Header(c,y,"General")
    y=CB(c,y,"Enable NameplateSCT","enabled","Toggle the addon on/off")
    y=CB(c,y,"Personal SCT (incoming)","personal","Show damage you receive on your nameplate")
    y=CB(c,y,"Off-target text","displayOffTargetText","Show text on nameplates other than target")
    y=CB(c,y,"Show Overkill","shouldDisplayOverkill","Include overkill amount in damage numbers")
    y=CB(c,y,"Show Absorbed","showAbsorbDamage","Include absorbed damage amount")
    y=y-6

    -- Appearance
    y=Header(c,y,"Appearance")
    y=FontDD(c,y,"font")
    y=DD(c,y,"Font Style","fontFlag",
        {"OUTLINE","THICKOUTLINE","MONOCHROME","","OUTLINE,MONOCHROME"},
        {OUTLINE="Outline",THICKOUTLINE="Thick Outline",MONOCHROME="Monochrome",[""]="None (smooth)",["OUTLINE,MONOCHROME"]="Outline + Mono"})
    y=SL(c,y,"Font Size","fontSize",8,60,1)
    y=SL(c,y,"Opacity","alpha",0.1,1,0.05)
    y=SL(c,y,"Animation Speed","animSpeed",0.5,3,0.1)
    y=SL(c,y,"X Offset","xOffset",-100,100,1)
    y=SL(c,y,"Y Offset","yOffset",-100,100,1)
    y=CB(c,y,"Text Shadow","textShadow","Add shadow behind text for readability")
    y=CB(c,y,"Color by Damage School","damageColor","Color by spell school (fire, frost, etc.)")
    y=CB(c,y,"Use Crit Color","useCritColor","Override color for critical hits")
    y=y-6

    -- Icons
    y=Header(c,y,"Spell Icons")
    y=CB(c,y,"Show Spell Icons","showIcon","Display spell icon next to damage number")
    y=SL(c,y,"Icon Scale","iconScale",0.3,3,0.1)
    y=SL(c,y,"Icon X Offset","xOffsetIcon",-30,30,1)
    y=SL(c,y,"Icon Y Offset","yOffsetIcon",-30,30,1)
    y=DD(c,y,"Icon Position","iconPosition",{"LEFT","RIGHT","TOP","BOTTOM"},{LEFT="Left",RIGHT="Right",TOP="Top",BOTTOM="Bottom"})
    y=y-6

    -- Animations
    y=Header(c,y,"Animations")
    y=DD(c,y,"Ability Hits","animAbility",AL,AN)
    y=DD(c,y,"Critical Hits","animCrit",AL,AN)
    y=DD(c,y,"Miss / Dodge / Parry","animMiss",AL,AN)
    y=DD(c,y,"Auto-Attack","animAA",AL,AN)
    y=DD(c,y,"Auto-Attack Crit","animAACrit",AL,AN)
    y=y-6

    -- Scaling
    y=Header(c,y,"Scaling")
    y=CB(c,y,"Enlarge Crits","sizeCrits","Make critical hits larger than normal")
    y=SL(c,y,"Crit Scale","critsScale",1,3,0.1)
    y=CB(c,y,"Shrink Small Hits","smallHits","Reduce size of small damage numbers")
    y=CB(c,y,"Hide Small Hits","smallHitsHide","Completely hide very small damage")
    y=CB(c,y,"Truncate Large Numbers","truncate","Show 1.5k instead of 1500")
    y=y-6

    -- Personal
    y=Header(c,y,"Personal Nameplate")
    y=SL(c,y,"Personal X Offset","xOffsetPersonal",-400,400,1)
    y=SL(c,y,"Personal Y Offset","yOffsetPersonal",-400,400,1)
    y=y-10

    -- Reset
    local rb=CreateFrame("Button",nil,c,"UIPanelButtonTemplate"); rb:SetPoint("TOPLEFT",T.pad,y); rb:SetSize(160,26)
    rb:SetText("Reset to Defaults")
    rb:SetScript("OnClick",function() for k,v in pairs(D) do NameplateSCTDB[k]=v end; ReloadUI() end)

    c:SetHeight(math.abs(y)+60)
    local cat=Settings.RegisterCanvasLayoutCategory(optFrame,"NameplateSCT")
    Settings.RegisterAddOnCategory(cat); optCatId=cat:GetID()
end

local function OpenOpts()
    if not optFrame then pcall(BuildOptionsPanel) end
    if optCatId then Settings.OpenToCategory(optCatId) end
end

-- ========================
--  SLASH COMMANDS  (top-level)
-- ========================
SLASH_NSCT1="/nsct"
SlashCmdList["NSCT"]=function(msg)
    if not db then print("[NSCT] Not ready"); return end
    local cmd=(msg or ""):lower():match("^(%S*)")
    if cmd=="reset" then for k,v in pairs(D) do NameplateSCTDB[k]=v end; ReloadUI()
    else OpenOpts() end
end
SLASH_NSCTDBG1="/nsctdebug"
SlashCmdList["NSCTDBG"]=function()
    print("|cFF00FF00[NSCT]|r midnight:",isMidnight," restricted:",restricted," ready:",addonReady)
    if db then print(" enabled:",db.enabled," icon:",db.showIcon," font:",db.font) end
    local ok,t=pcall(RawSpellTex,585); print(" SpellTex(585):",ok,t)
    print(" lastCast:",lastCastId," guid:",playerGUID," hasUC:",hasUC)
    local n=0; for _ in pairs(guidToUnit) do n=n+1 end; print(" units:",n)
end
SLASH_NSCTDON1="/nsctdebugon"; SlashCmdList["NSCTDON"]=function() debugMode=true; print("|cFF00FF00[NSCT] Debug ON|r") end
SLASH_NSCTDOFF1="/nsctdebugoff"; SlashCmdList["NSCTDOFF"]=function() debugMode=false; print("[NSCT] Debug OFF") end

-- Visual test: shows a big visible text at screen center for 3 seconds
SLASH_NSCTTEST1="/nscttest"
SlashCmdList["NSCTTEST"]=function()
    if not db then print("[NSCT] not ready"); return end
    -- Test 1: static text at screen center
    local tf = CreateFrame("Frame",nil,UIParent)
    tf:SetSize(1,1); tf:Show(); tf:SetFrameStrata("TOOLTIP"); tf:SetPoint("CENTER")
    local tfs = tf:CreateFontString(nil,"OVERLAY")
    tfs:SetFont(db.font, 40, db.fontFlag)
    tfs:SetText("|cFF00FF00NSCT TEST OK!|r")
    tfs:SetPoint("CENTER",tf,"CENTER",0,100)
    tfs:Show()
    C_Timer.After(3, function() tf:Hide() end)
    print("[NSCT] Test text at screen center for 3s")
    -- Test 2: trigger a fake damage on target nameplate
    local tguid = UnitGUID("target")
    if tguid and guidToUnit[tguid] then
        print("[NSCT] Fake damage on target nameplate...")
        Show(tguid, "|cFFFF0000TEST 99999|r", 30, "fountain", nil, true, nil)
    else
        print("[NSCT] No target with nameplate. Target a mob first.")
    end
end
