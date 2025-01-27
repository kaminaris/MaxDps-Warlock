local _, addonTable = ...
local Warlock = addonTable.Warlock
local MaxDps = _G.MaxDps
if not MaxDps then return end
local setSpell

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCount = C_Spell.GetSpellCastCount

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local LunarPowerPT = Enum.PowerType.LunarPower
local HolyPowerPT = Enum.PowerType.HolyPower
local MaelstromPT = Enum.PowerType.Maelstrom
local ChiPT = Enum.PowerType.Chi
local InsanityPT = Enum.PowerType.Insanity
local ArcaneChargesPT = Enum.PowerType.ArcaneCharges
local FuryPT = Enum.PowerType.Fury
local PainPT = Enum.PowerType.Pain
local EssencePT = Enum.PowerType.Essence
local RuneBloodPT = Enum.PowerType.RuneBlood
local RuneFrostPT = Enum.PowerType.RuneFrost
local RuneUnholyPT = Enum.PowerType.RuneUnholy

local fd
local ttd
local timeShift
local gcd
local cooldown
local buff
local debuff
local talents
local targets
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local timeInCombat
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local SoulShards
local SoulShardsMax
local SoulShardsDeficit
local Mana
local ManaMax
local ManaDeficit
local ManaPerc

local Affliction = {}



local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end


function Affliction:precombat()
    if (MaxDps:CheckSpellUsable(classtable.SoulHarvest, 'SoulHarvest')) and (SoulShards <3) and cooldown[classtable.SoulHarvest].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SoulHarvest end
    end
    if (MaxDps:CheckSpellUsable(classtable.FelArmor, 'FelArmor')) and (not buff[classtable.FelArmorBuff].up) and cooldown[classtable.FelArmor].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FelArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and cooldown[classtable.VolcanicPotion].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonFelhunter, 'SummonFelhunter')) and (not UnitExists('pet')) and cooldown[classtable.SummonFelhunter].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SummonFelhunter end
    end
end
function Affliction:single_target()
    if (MaxDps:CheckSpellUsable(classtable.SummonFelhunter, 'SummonFelhunter')) and (not UnitExists('pet')) and cooldown[classtable.SummonFelhunter].ready then
        if not setSpell then setSpell = classtable.SummonFelhunter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (not debuff[classtable.HauntDeBuff].up or debuff[classtable.HauntDeBuff].remains <( ( classtable and classtable.Haunt and GetSpellInfo(classtable.Haunt).castTime /1000 or 0) + 1 + 2 )) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (debuff[classtable.CorruptionDeBuff].remains <1) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (debuff[classtable.UnstableAfflictionDeBuff].remains <1 and targethealthPerc >25) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.BaneofAgony, 'BaneofAgony')) and (not debuff[classtable.BaneofAgonyDeBuff].up) and cooldown[classtable.BaneofAgony].ready then
        if not setSpell then setSpell = classtable.BaneofAgony end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (targethealthPerc <= 25) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowflame, 'Shadowflame')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) <7) and cooldown[classtable.Shadowflame].ready then
        if not setSpell then setSpell = classtable.Shadowflame end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (targethealthPerc >25 and (LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) >7 or not debuff[classtable.ShadowEmbraceDeBuff].up and targethealthPerc >25 or (LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) <7 and cooldown[classtable.Shadowflame].remains >3) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Soulburn, 'Soulburn')) and ((GetUnitSpeed('player') >0)) and cooldown[classtable.Soulburn].ready then
        if not setSpell then setSpell = classtable.Soulburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (buff[classtable.SoulburnBuff].up) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <30 or ManaPerc <70 and (GetUnitSpeed('player') >0)) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
end
function Affliction:aoe()
    if (MaxDps:CheckSpellUsable(classtable.CurseoftheElements, 'CurseoftheElements')) and ((talents[classtable.Jinx] and talents[classtable.Jinx] or 0) and ( not debuff[classtable.JinxCurseElementsDeBuff].up and debuff[classtable.CurseoftheElementsDeBuff].remains <3 )) and cooldown[classtable.CurseoftheElements].ready then
        if not setSpell then setSpell = classtable.CurseoftheElements end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (debuff[classtable.CorruptionDeBuff].remains <2 and targets <6) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (debuff[classtable.UnstableAfflictionDeBuff].remains <( classtable and classtable.UnstableAffliction and GetSpellInfo(classtable.UnstableAffliction).castTime /1000 or 0)) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.BaneofAgony, 'BaneofAgony')) and (debuff[classtable.BaneofAgonyDeBuff].remains <1 and not debuff[classtable.BaneofDoomDeBuff].up and not debuff[classtable.BaneofHavocDeBuff].up) and cooldown[classtable.BaneofAgony].ready then
        if not setSpell then setSpell = classtable.BaneofAgony end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (not debuff[classtable.HauntDeBuff].up or debuff[classtable.HauntDeBuff].remains <( ( classtable and classtable.Haunt and GetSpellInfo(classtable.Haunt).castTime /1000 or 0) + 1 + 2 )) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulSwap, 'SoulSwap')) and (debuff[classtable.BaneofAgonyDeBuff].up and targets == 2) and cooldown[classtable.SoulSwap].ready then
        if not setSpell then setSpell = classtable.SoulSwap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Soulburn, 'Soulburn')) and (cooldown[classtable.SeedofCorruption].remains <gcd and targets >2) and cooldown[classtable.Soulburn].ready then
        if not setSpell then setSpell = classtable.Soulburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.SeedofCorruption, 'SeedofCorruption')) and (targets >= 6 or buff[classtable.SoulburnBuff].up and targets >2) and cooldown[classtable.SeedofCorruption].ready then
        if not setSpell then setSpell = classtable.SeedofCorruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowflame, 'Shadowflame')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) <7) and cooldown[classtable.Shadowflame].ready then
        if not setSpell then setSpell = classtable.Shadowflame end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end


local function ClearCDs()
end

function Affliction:callaction()
    if (MaxDps:CheckSpellUsable(classtable.FelFlame, 'FelFlame')) and (buff[classtable.FelSparkBuff].up) and cooldown[classtable.FelFlame].ready then
        if not setSpell then setSpell = classtable.FelFlame end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (not debuff[classtable.ShadowEmbraceDeBuff].up and targethealthPerc >25) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.GroupCurse, 'GroupCurse')) and (not debuff[classtable.MyCurseDeBuff].up and MaxDps:NumGroupFriends() >1 and ( classtable.MyCurseDeBuff ~= classtable.CurseoftheElementsDeBuff or (talents[classtable.Jinx] and talents[classtable.Jinx] or 0) and not debuff[classtable.JinxCurseElementsDeBuff].up )) and cooldown[classtable.GroupCurse].ready then
        if not setSpell then setSpell = classtable.GroupCurse end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoloCurse, 'SoloCurse')) and (not debuff[classtable.MyCurseDeBuff].up and ( classtable.MyCurseDeBuff ~= classtable.CurseoftheElementsDeBuff or (talents[classtable.Jinx] and talents[classtable.Jinx] or 0) and not debuff[classtable.JinxCurseElementsDeBuff].up )) and cooldown[classtable.SoloCurse].ready then
        if not setSpell then setSpell = classtable.SoloCurse end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (not debuff[classtable.HauntDeBuff].up or debuff[classtable.HauntDeBuff].remains <( ( classtable and classtable.Haunt and GetSpellInfo(classtable.Haunt).castTime /1000 or 0) + 1 + 2 )) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.DemonSoul, 'DemonSoul')) and (UnitExists('pet')) and cooldown[classtable.DemonSoul].ready then
        if not setSpell then setSpell = classtable.DemonSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (not debuff[classtable.UnstableAfflictionDeBuff].up) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (targets >= 2) then
        Affliction:aoe()
    end
    if (targets <2) then
        Affliction:single_target()
    end
    if (MaxDps:CheckSpellUsable(classtable.FelFlame, 'FelFlame')) and ((GetUnitSpeed('player') >0)) and cooldown[classtable.FelFlame].ready then
        if not setSpell then setSpell = classtable.FelFlame end
    end
end
function Warlock:Affliction()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    ManaPerc = (Mana / ManaMax) * 100
    SoulShards = UnitPower('player', SoulShardsPT)
    SoulShardsMax = UnitPowerMax('player', MaelstromPT)
    SoulShardsDeficit = SoulShardsMax - SoulShards
    classtable.SpellLock = 19647
    classtable.MyCurseDeBuff = MaxDps:NumGroupFriends() <= 1 and classtable.SoloCurse or MaxDps:NumGroupFriends() > 1 and classtable.GroupCurse
    classtable.Wither = 445468
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.FelArmorBuff = 28176
    classtable.FelSparkBuff = 89937
    classtable.ShadowEmbraceBuff = 32389
    classtable.CurseoftheElementsBuff = 1490
    classtable.SoulburnBuff = 74434
    classtable.ShadowEmbraceDeBuff = 32389
    classtable.JinxCurseElementsDeBuff = 86105
    classtable.CurseoftheElementsDeBuff = 1490
    classtable.HauntDeBuff = 48181
    classtable.UnstableAfflictionDeBuff = 30108
    classtable.CorruptionDeBuff = 172
    classtable.BaneofAgonyDeBuff = 980
    classtable.BaneofDoomDeBuff = 603
    classtable.BaneofHavocDeBuff = 80240
    classtable.SoulHarvest = 79268
    classtable.FelArmor = 28176
    classtable.VolcanicPotion = 58091
    classtable.SummonFelhunter = 691
    classtable.Haunt = 48181
    classtable.Corruption = 172
    classtable.UnstableAffliction = 30108
    classtable.BaneofAgony = 980
    classtable.DrainSoul = 1120
    classtable.Shadowflame = 47897
    classtable.ShadowBolt = 686
    classtable.Soulburn = 74434
    classtable.SoulFire = 6353
    classtable.LifeTap = 1454
    classtable.CurseoftheElements = 1490
    classtable.SoulSwap = 86121
    classtable.SeedofCorruption = 27243
    classtable.FelFlame = 77799
    classtable.GroupCurse = 1490
    classtable.CurseoftheElements = 1490
    classtable.SoloCurse = 980
    classtable.BaneofAgony = 980
    classtable.DemonSoul = 77801

    local function debugg()
        talents[classtable.Jinx] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Affliction:precombat()

    Affliction:callaction()
    if setSpell then return setSpell end
end
