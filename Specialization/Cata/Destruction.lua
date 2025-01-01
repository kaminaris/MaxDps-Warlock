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
local havoc_active
local havoc_remains

local Destruction = {}



local function demonic_art()
    if buff[classtable.demonic_art_mother_of_chaos].up or buff[classtable.demonic_art_overlord].up or buff[classtable.demonic_art_pit_lord].up then
        return true
    end
    return false
end

local function diabolic_ritual()
    if buff[classtable.diabolic_ritual_overlord].up or buff[classtable.diabolic_ritual_mother_of_chaos].up or buff[classtable.diabolic_ritual_pit_lord].up then
        return true
    end
    return false
end




local function ClearCDs()
end

function Destruction:callaction()
    if (MaxDps:CheckSpellUsable(classtable.FelArmor, 'FelArmor')) and cooldown[classtable.FelArmor].ready then
        if not setSpell then setSpell = classtable.FelArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonImp, 'SummonImp')) and cooldown[classtable.SummonImp].ready then
        if not setSpell then setSpell = classtable.SummonImp end
    end
    if (MaxDps:CheckSpellUsable(classtable.DarkIntent, 'DarkIntent')) and cooldown[classtable.DarkIntent].ready then
        if not setSpell then setSpell = classtable.DarkIntent end
    end
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and (MaxDps:Bloodlust() or not UnitAffectingCombat('player') or targetHP <= 20) and cooldown[classtable.VolcanicPotion].ready then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
    if (MaxDps:CheckSpellUsable(classtable.DemonSoul, 'DemonSoul')) and cooldown[classtable.DemonSoul].ready then
        if not setSpell then setSpell = classtable.DemonSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Soulburn, 'Soulburn')) and cooldown[classtable.Soulburn].ready then
        if not setSpell then setSpell = classtable.Soulburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (buff[classtable.SoulburnBuff].up and not UnitAffectingCombat('player')) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (( debuff[classtable.ImmolateDeBuff].remains <( classtable and classtable.Immolate and GetSpellInfo(classtable.Immolate).castTime /1000 or 0) + gcd or not debuff[classtable.ImmolateDeBuff].up ) and ttd >= 4) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and cooldown[classtable.Conflagrate].ready then
        if not setSpell then setSpell = classtable.Conflagrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (MaxDps:Bloodlust() and MaxDps:Bloodlust() >32 and cooldown[classtable.Conflagrate].remains <= 3 and debuff[classtable.ImmolateDeBuff].remains <12) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.BaneofDoom, 'BaneofDoom')) and (not debuff[classtable.BaneofDoomDeBuff].up and ttd >= 15) and cooldown[classtable.BaneofDoom].ready then
        if not setSpell then setSpell = classtable.BaneofDoom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (( not debuff[classtable.CorruptionDeBuff].up or debuff[classtable.CorruptionDeBuff].remains <buff[classtable.CorruptionBuff].duration )) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowflame, 'Shadowflame')) and cooldown[classtable.Shadowflame].ready then
        if not setSpell then setSpell = classtable.Shadowflame end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime /1000 or 0) >0.9) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDoomguard, 'SummonDoomguard')) and (timeInCombat >10) and cooldown[classtable.SummonDoomguard].ready then
        if not setSpell then setSpell = classtable.SummonDoomguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (buff[classtable.SoulburnBuff].up) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (( ( buff[classtable.EmpoweredImpBuff].up and buff[classtable.EmpoweredImpBuff].remains <( buff[classtable.ImprovedSoulFireBuff].remains + 1 ) ) or buff[classtable.ImprovedSoulFireBuff].remains <( ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime /1000 or 0) + 1 + ( classtable and classtable.Incinerate and GetSpellInfo(classtable.Incinerate).castTime / 1000 or 0) + gcd ) ) and not (MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.SoulFire)) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn')) and cooldown[classtable.Shadowburn].ready then
        if not setSpell then setSpell = classtable.Shadowburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <80 and ManaPerc <targetHP) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.FelFlame, 'FelFlame')) and cooldown[classtable.FelFlame].ready then
        if not setSpell then setSpell = classtable.FelFlame end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <100) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
end
function Warlock:Destruction()
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
    local havoc_count, havoc_totalRemains = MaxDps:DebuffCounter(classtable.Havoc,1)
    havoc_active = havoc_count >= 1
    havoc_remains = havoc_totalRemains or 0
    classtable.Wither = 445468
    classtable.InfernalBolt = 434506
    classtable.demonic_art_mother_of_chaos = 432794
    classtable.demonic_art_overlord = 428524
    classtable.demonic_art_pit_lord = 432795
    classtable.diabolic_ritual_overlord = 431944
    classtable.diabolic_ritual_mother_of_chaos = 432815
    classtable.diabolic_ritual_pit_lord = 432816
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.bloodlust = 0
    classtable.SoulburnBuff = 0
    classtable.ImmolateDeBuff = 157736
    classtable.BaneofDoomDeBuff = 0
    classtable.CorruptionDeBuff = 0
    classtable.EmpoweredImpBuff = 0
    classtable.ImprovedSoulFireBuff = 0

    local function debugg()
    end


    if MaxDps.db.global.debugMode then
        debugg()
    end

    setSpell = nil
    ClearCDs()

    Destruction:callaction()
    if setSpell then return setSpell end
end
