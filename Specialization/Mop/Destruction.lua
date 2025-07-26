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
local DemonicFuryPT = Enum.PowerType.DemonicFury
local BurningEmbersPT = Enum.PowerType.BurningEmbers
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
local className, classFilename, classId = UnitClass('player')
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local SoulShards
local SoulShardsMax
local SoulShardsDeficit
local DemonicFury
local BurningEmber
local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local havoc_active
local havoc_remains

local Destruction = {}

function Destruction:precombat()
    if (MaxDps:CheckSpellUsable(classtable.DarkIntent, 'DarkIntent')) and (not buff[classtable.DarkIntentBuff].up) and cooldown[classtable.DarkIntent].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DarkIntent end
    end
    --if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and cooldown[classtable.VolcanicPotion].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.VolcanicPotion end
    --end
end
function Destruction:aoe()
    if (MaxDps:CheckSpellUsable(classtable.SummonDoomguard, 'SummonDoomguard')) and (targets <7) and cooldown[classtable.SummonDoomguard].ready then
        --if not setSpell then setSpell = classtable.SummonDoomguard end
        MaxDps:GlowCooldown(classtable.SummonDoomguard, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonInfernal, 'SummonInfernal')) and (targets >= 7) and cooldown[classtable.SummonInfernal].ready then
        MaxDps:GlowCooldown(classtable.SummonInfernal, cooldown[classtable.SummonInfernal].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire')) and (not debuff[classtable.RainofFireDeBuff].up and not (MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.RainofFire)) and cooldown[classtable.RainofFire].ready then
        if not setSpell then setSpell = classtable.RainofFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireandBrimstone, 'FireandBrimstone')) and (BurningEmber >=1 and not buff[classtable.FireandBrimstoneBuff].up) and cooldown[classtable.FireandBrimstone].ready then
        if not setSpell then setSpell = classtable.FireandBrimstone end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (buff[classtable.FireandBrimstoneBuff].up and not debuff[classtable.ImmolateDeBuff].up) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (BurningEmber >=1 and buff[classtable.FireandBrimstoneBuff].up) and cooldown[classtable.Conflagrate].ready then
        if not setSpell then setSpell = classtable.Conflagrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and (buff[classtable.FireandBrimstoneBuff].up) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (not debuff[classtable.ImmolateDeBuff].up) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.SummonInfernal, false)
    MaxDps:GlowCooldown(classtable.DarkSoul, false)
    MaxDps:GlowCooldown(classtable.SummonDoomguard, false)
end

function Destruction:callaction()
    --if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and (MaxDps:Bloodlust(1) or targethealthPerc <= 20) and cooldown[classtable.VolcanicPotion].ready then
    --    if not setSpell then setSpell = classtable.VolcanicPotion end
    --end
    if (MaxDps:CheckSpellUsable(classtable.DarkSoul, 'DarkSoul')) and cooldown[classtable.DarkSoul].ready then
        --if not setSpell then setSpell = classtable.DarkSoul end
        MaxDps:GlowCooldown(classtable.DarkSoul, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.ServicePet, 'ServicePet')) and ((talents[classtable.GrimoireofService] and true or false)) and cooldown[classtable.ServicePet].ready then
        if not setSpell then setSpell = classtable.ServicePet end
    end
    if (MaxDps:CheckSpellUsable(classtable.GrimoireofSacrifice, 'GrimoireofSacrifice') and talents[classtable.GrimoireofSacrifice]) and ((talents[classtable.GrimoireofSacrifice] and true or false) and not buff[classtable.GrimoireofSacrificeBuff].up or buff[classtable.GrimoireofSacrificeBuff].refreshable) and cooldown[classtable.GrimoireofSacrifice].ready then
        if not setSpell then setSpell = classtable.GrimoireofSacrifice end
    end
    if (targets >2) then
        Destruction:aoe()
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDoomguard, 'SummonDoomguard')) and cooldown[classtable.SummonDoomguard].ready then
        --if not setSpell then setSpell = classtable.SummonDoomguard end
        MaxDps:GlowCooldown(classtable.SummonDoomguard, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.Havoc, 'Havoc')) and (targets >1) and cooldown[classtable.Havoc].ready then
        if not setSpell then setSpell = classtable.Havoc end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn')) and (BurningEmber >=1) and cooldown[classtable.Shadowburn].ready then
        if not setSpell then setSpell = classtable.Shadowburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (( not debuff[classtable.ImmolateDeBuff].up or debuff[classtable.ImmolateDeBuff].remains <( ( classtable and classtable.Incinerate and GetSpellInfo(classtable.Incinerate).castTime / 1000 or 0) + ( classtable and classtable.Immolate and GetSpellInfo(classtable.Immolate).castTime /1000 or 0) ) ) and ttd >= 5 and true) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (BurningEmber >=1 and ( buff[classtable.BackdraftBuff].count <3 or UnitLevel('player') <86 ) and ( BurningEmber >3.5 or buff[classtable.DarkSoulBuff].remains >( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime /1000 or 0) ) and ManaPerc <= 80) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and cooldown[classtable.Conflagrate].ready then
        if not setSpell then setSpell = classtable.Conflagrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (BurningEmber >2 and ManaPerc <10) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
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
    BurningEmber = UnitPower('player', BurningEmbersPT)
    classtable.SpellLock = 19647
    local havoc_count, havoc_totalRemains = MaxDps:DebuffCounter(classtable.Havoc,1)
    havoc_active = havoc_count >= 1
    havoc_remains = havoc_totalRemains or 0

    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    classtable.ServicePet = 691
    classtable.SummonDoomguard = talents[108499] and 112927 or 18540

    classtable.DarkIntentBuff = 109773
    --classtable.FireandBrimstoneBuff
    classtable.BackdraftBuff = 117828
    classtable.DarkSoulBuff = 113858
    classtable.GrimoireofSacrificeBuff = 108503
    classtable.RainofFireDeBuff = 104232
    classtable.ImmolateDeBuff = 348

    local function debugg()
        talents[classtable.GrimoireofService] = 1
        talents[classtable.GrimoireofSacrifice] = 1
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
