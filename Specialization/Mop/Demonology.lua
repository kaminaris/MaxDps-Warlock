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

local Demonology = {}

function Demonology:precombat()
    if (MaxDps:CheckSpellUsable(classtable.DarkIntent, 'DarkIntent')) and (not buff[classtable.DarkIntentBuff].up) and cooldown[classtable.DarkIntent].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DarkIntent end
    end
    --if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and cooldown[classtable.VolcanicPotion].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.VolcanicPotion end
    --end
end
function Demonology:aoe()
    if (MaxDps:CheckSpellUsable(classtable.SummonDoomguard, 'SummonDoomguard')) and (targets <7) and cooldown[classtable.SummonDoomguard].ready then
        if not setSpell then setSpell = classtable.SummonDoomguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonInfernal, 'SummonInfernal')) and (targets >= 7) and cooldown[classtable.SummonInfernal].ready then
        MaxDps:GlowCooldown(classtable.SummonInfernal, cooldown[classtable.SummonInfernal].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (( not debuff[classtable.CorruptionDeBuff].up or debuff[classtable.CorruptionDeBuff].remains <1 ) and ttd >30 and true) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.Metamorphosis, 'Metamorphosis')) and (DemonicFury >= 1000 or DemonicFury >= 31 * ttd) and cooldown[classtable.Metamorphosis].ready then
        MaxDps:GlowCooldown(classtable.Metamorphosis, cooldown[classtable.Metamorphosis].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ImmolationAura, 'ImmolationAura')) and cooldown[classtable.ImmolationAura].ready then
        if not setSpell then setSpell = classtable.ImmolationAura end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidRay, 'VoidRay')) and (debuff[classtable.CorruptionDeBuff].remains <10) and cooldown[classtable.VoidRay].ready then
        if not setSpell then setSpell = classtable.VoidRay end
    end
    if (MaxDps:CheckSpellUsable(classtable.Doom, 'Doom')) and (( not debuff[classtable.DoomDeBuff].up or debuff[classtable.DoomDeBuff].remains <4 ) and ttd >30 and true) and cooldown[classtable.Doom].ready then
        if not setSpell then setSpell = classtable.Doom end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidRay, 'VoidRay')) and cooldown[classtable.VoidRay].ready then
        if not setSpell then setSpell = classtable.VoidRay end
    end
    if (MaxDps:CheckSpellUsable(classtable.HarvestLife, 'HarvestLife') and talents[classtable.HarvestLife]) and ((talents[classtable.HarvestLife] and true or false)) and cooldown[classtable.HarvestLife].ready then
        if not setSpell then setSpell = classtable.HarvestLife end
    end
    if (MaxDps:CheckSpellUsable(classtable.Hellfire, 'Hellfire')) and (not (talents[classtable.HarvestLife] and true or false)) and cooldown[classtable.Hellfire].ready then
        if not setSpell then setSpell = classtable.Hellfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Metamorphosis, false)
    MaxDps:GlowCooldown(classtable.SummonInfernal, false)
end

function Demonology:callaction()
    --if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and (MaxDps:Bloodlust(1) or targethealthPerc <= 20) and cooldown[classtable.VolcanicPotion].ready then
    --    if not setSpell then setSpell = classtable.VolcanicPotion end
    --end
    if (MaxDps:CheckSpellUsable(classtable.DarkSoul, 'DarkSoul')) and cooldown[classtable.DarkSoul].ready then
        if not setSpell then setSpell = classtable.DarkSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ServicePet, 'ServicePet')) and (not UnitExists("pet")) and ((talents[classtable.GrimoireofService] and true or false)) and cooldown[classtable.ServicePet].ready then
        if not setSpell then setSpell = classtable.ServicePet end
    end
    if (MaxDps:CheckSpellUsable(classtable.GrimoireofSacrifice, 'GrimoireofSacrifice') and talents[classtable.GrimoireofSacrifice]) and ((talents[classtable.GrimoireofSacrifice] and true or false)) and cooldown[classtable.GrimoireofSacrifice].ready then
        if not setSpell then setSpell = classtable.GrimoireofSacrifice end
    end
    --if (MaxDps:CheckSpellUsable(classtable.Melee, 'Melee')) and cooldown[classtable.Melee].ready then
    --    if not setSpell then setSpell = classtable.Melee end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Felguardfelstorm, 'Felguardfelstorm')) and cooldown[classtable.Felguardfelstorm].ready then
        if not setSpell then setSpell = classtable.Felguardfelstorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrathguardwrathstorm, 'Wrathguardwrathstorm')) and cooldown[classtable.Wrathguardwrathstorm].ready then
        if not setSpell then setSpell = classtable.Wrathguardwrathstorm end
    end
    if (targets >5) then
        Demonology:aoe()
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDoomguard, 'SummonDoomguard')) and cooldown[classtable.SummonDoomguard].ready then
        if not setSpell then setSpell = classtable.SummonDoomguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (( not debuff[classtable.CorruptionDeBuff].up or debuff[classtable.CorruptionDeBuff].remains <1 ) and ttd >= 6 and true) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Doom, 'Doom')) and (( not debuff[classtable.DoomDeBuff].up or debuff[classtable.DoomDeBuff].remains <1 or ( debuff[classtable.DoomDeBuff].remains + 1 <debuff[classtable.DoomDeBuff].duration and buff[classtable.DarkSoulBuff].up ) ) and ttd >= 30 and true) and cooldown[classtable.Doom].ready then
        if not setSpell then setSpell = classtable.Doom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Metamorphosis, 'Metamorphosis')) and (buff[classtable.DarkSoulBuff].up or debuff[classtable.CorruptionDeBuff].remains <5 or DemonicFury >= 900 or DemonicFury >= ttd * 30) and cooldown[classtable.Metamorphosis].ready then
        MaxDps:GlowCooldown(classtable.Metamorphosis, cooldown[classtable.Metamorphosis].ready)
    end
    --if (MaxDps:CheckSpellUsable(classtable.CancelMetamorphosis, 'CancelMetamorphosis')) and (debuff[classtable.CorruptionDeBuff].remains >20 and not buff[classtable.DarkSoulBuff].up and DemonicFury <= 750 and ttd >30) and cooldown[classtable.CancelMetamorphosis].ready then
    --    if not setSpell then setSpell = classtable.CancelMetamorphosis end
    --end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (not (MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.HandofGuldan) and debuff[classtable.ShadowflameDeBuff].remains <1 + ( classtable and classtable.ShadowBolt and GetSpellInfo(classtable.ShadowBolt).castTime / 1000 or 0)) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.TouchofChaos, 'TouchofChaos')) and (debuff[classtable.CorruptionDeBuff].remains <20) and cooldown[classtable.TouchofChaos].ready then
        if not setSpell then setSpell = classtable.TouchofChaos end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (buff[classtable.MoltenCoreBuff].up and ( not buff[classtable.MetamorphosisBuff].up or targethealthPerc <25 )) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.TouchofChaos, 'TouchofChaos')) and cooldown[classtable.TouchofChaos].ready then
        if not setSpell then setSpell = classtable.TouchofChaos end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <50) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.FelFlame, 'FelFlame')) and cooldown[classtable.FelFlame].ready then
        if not setSpell then setSpell = classtable.FelFlame end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
end
function Warlock:Demonology()
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
    DemonicFury = UnitPower('player', DemonicFuryPT)
    classtable.SpellLock = 19647
    classtable.AxeToss = 119914
    classtable.Demonbolt = 264178
    classtable.InfernalBolt = 434506
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
        talents[classtable.GrimoireofService] = 1
        talents[classtable.GrimoireofSacrifice] = 1
        talents[classtable.HarvestLife] = 1
    end

    classtable.TouchofChaos = 103964
    classtable.Doom = 603
    classtable.Felguardfelstorm = 89751
    classtable.DarkIntentBuff = 109773
    classtable.DarkSoulBuff = 113861
    classtable.MoltenCoreBuff = 122355
    classtable.MetamorphosisBuff = 103958
    classtable.CorruptionDeBuff = 146739
    classtable.DoomDeBuff = 603
    classtable.ShadowflameDeBuff = 47960

    classtable.ServicePet = 30146
    classtable.Wrathguardwrathstorm = 115831

    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Demonology:precombat()

    Demonology:callaction()
    if setSpell then return setSpell end
end
