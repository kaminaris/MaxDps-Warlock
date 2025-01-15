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



local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end




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


function Destruction:precombat()
    if (MaxDps:CheckSpellUsable(classtable.FelArmor, 'FelArmor')) and (not buff[classtable.ArmorBuff].up or buff[classtable.ArmorBuff].remains <180) and cooldown[classtable.FelArmor].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FelArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonImp, 'SummonImp')) and (not UnitExists('pet')) and cooldown[classtable.SummonImp].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SummonImp end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (IsSpellKnownOrOverridesKnown(63320) and not buff[classtable.LifeTapBuff].up) and cooldown[classtable.LifeTap].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and cooldown[classtable.VolcanicPotion].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
end
function Destruction:st()
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (not debuff[classtable.ImmolateDeBuff].up and debuff[classtable.ImmolateDeBuff].remains <buff[classtable.ImmolateBuff].duration) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and cooldown[classtable.Conflagrate].ready then
        if not setSpell then setSpell = classtable.Conflagrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (IsSpellKnownOrOverridesKnown(63320) and not buff[classtable.LifeTapBuff].up) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (not debuff[classtable.CorruptionDeBuff].up and debuff[classtable.CorruptionDeBuff].remains <buff[classtable.CorruptionBuff].duration) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Inferno, 'Inferno')) and (ttd <= 60 and ManaPerc >20 and true or targetHP <40 and true) and cooldown[classtable.Inferno].ready then
        if not setSpell then setSpell = classtable.Inferno end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and ((GetUnitSpeed('player') >0) and ManaPerc <80 or ManaPerc <10) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.CurseofDoom, 'CurseofDoom')) and (ttd >60 and not debuff[classtable.MyCurseDeBuff].up) and cooldown[classtable.CurseofDoom].ready then
        if not setSpell then setSpell = classtable.CurseofDoom end
    end
    if (MaxDps:CheckSpellUsable(classtable.CurseofAgony, 'CurseofAgony')) and (ttd <60 and not debuff[classtable.CurseofDoomDeBuff].duration >buff[classtable.CurseofAgonyBuff].duration) and cooldown[classtable.CurseofAgony].ready then
        if not setSpell then setSpell = classtable.CurseofAgony end
    end
end
function Destruction:aoe()
    if (MaxDps:CheckSpellUsable(classtable.Shadowflame, 'Shadowflame')) and (targets >3 and (LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) <10) and cooldown[classtable.Shadowflame].ready then
        if not setSpell then setSpell = classtable.Shadowflame end
    end
    if (MaxDps:CheckSpellUsable(classtable.SeedofCorruption, 'SeedofCorruption')) and (targets >3 and not debuff[classtable.SeedofCorruptionDeBuff].up) and cooldown[classtable.SeedofCorruption].ready then
        if not setSpell then setSpell = classtable.SeedofCorruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (not debuff[classtable.ImmolateDeBuff].up) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and ((GetUnitSpeed('player') >0)) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
end
function Destruction:life()
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainLife, 'DrainLife')) and cooldown[classtable.DrainLife].ready then
        if not setSpell then setSpell = classtable.DrainLife end
    end
end


local function ClearCDs()
end

function Destruction:callaction()
    if (targets <2) then
        Destruction:st()
    end
    if (targets >1) then
        Destruction:aoe()
    end
    if (curentHP <25) then
        Destruction:life()
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
    classtable.ArmorBuff = 0
    classtable.LifeTapBuff = 63321
    classtable.MyCurseDeBuff = 0
    classtable.ImmolateDeBuff = 348
    classtable.CorruptionDeBuff = 172
    classtable.CurseofDoomDeBuff = 0
    classtable.SeedofCorruptionDeBuff = 0
    classtable.FelArmor = 28176
    classtable.SummonImp = 688
    classtable.LifeTap = 1454
    classtable.Immolate = 348
    classtable.Conflagrate = 17962
    classtable.ChaosBolt = 50796
    classtable.Corruption = 172
    classtable.Incinerate = 29722
    classtable.Shadowflame = 47897
    classtable.DeathCoil = 6789
    classtable.DrainLife = 689

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Destruction:precombat()

    Destruction:callaction()
    if setSpell then return setSpell end
end
