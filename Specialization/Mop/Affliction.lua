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

local Affliction = {}

function Affliction:precombat()
    if (MaxDps:CheckSpellUsable(classtable.DarkIntent, 'DarkIntent')) and (not aura.spell_power_multiplier.up) and cooldown[classtable.DarkIntent].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DarkIntent end
    end
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and cooldown[classtable.VolcanicPotion].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
end
function Affliction:aoe()
    if (MaxDps:CheckSpellUsable(classtable.SummonDoomguard, 'SummonDoomguard')) and (targets <7) and cooldown[classtable.SummonDoomguard].ready then
        if not setSpell then setSpell = classtable.SummonDoomguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonInfernal, 'SummonInfernal')) and (targets >= 7) and cooldown[classtable.SummonInfernal].ready then
        MaxDps:GlowCooldown(classtable.SummonInfernal, cooldown[classtable.SummonInfernal].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Soulburn, 'Soulburn')) and (not buff[classtable.SoulburnBuff].up and not debuff[classtable.SoulburnSeedofCorruptionDeBuff].up and not (cooldown[classtable.SoulburnSeedofCorruption].duration - cooldown[classtable.SoulburnSeedofCorruption].remains <1) and SoulShards >0) and cooldown[classtable.Soulburn].ready then
        if not setSpell then setSpell = classtable.Soulburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.SeedofCorruption, 'SeedofCorruption')) and (( not buff[classtable.SoulburnBuff].up and not (MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] == classtable.SeedofCorruption) and not debuff[classtable.SeedofCorruptionDeBuff].up ) or ( buff[classtable.SoulburnBuff].up and not debuff[classtable.SoulburnSeedofCorruptionDeBuff].up and not (cooldown[classtable.SoulburnSeedofCorruption].duration - cooldown[classtable.SoulburnSeedofCorruption].remains <1) )) and cooldown[classtable.SeedofCorruption].ready then
        if not setSpell then setSpell = classtable.SeedofCorruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (not (MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] == classtable.Haunt) and debuff[classtable.HauntDeBuff].remains <( classtable and classtable.Haunt and GetSpellInfo(classtable.Haunt).castTime /1000 or 0) + 1 and SoulShards >0) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <70) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.FelFlame, 'FelFlame')) and (not (MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] == classtable.FelFlame)) and cooldown[classtable.FelFlame].ready then
        if not setSpell then setSpell = classtable.FelFlame end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.SummonInfernal, false)
end

function Affliction:callaction()
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and (MaxDps:Bloodlust(1) or targethealthPerc <= 20) and cooldown[classtable.VolcanicPotion].ready then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
    if (MaxDps:CheckSpellUsable(classtable.DarkSoul, 'DarkSoul')) and cooldown[classtable.DarkSoul].ready then
        if not setSpell then setSpell = classtable.DarkSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ServicePet, 'ServicePet')) and ((talents[classtable.GrimoireofService] and true or false)) and cooldown[classtable.ServicePet].ready then
        if not setSpell then setSpell = classtable.ServicePet end
    end
    if (MaxDps:CheckSpellUsable(classtable.GrimoireofSacrifice, 'GrimoireofSacrifice') and talents[classtable.GrimoireofSacrifice]) and ((talents[classtable.GrimoireofSacrifice] and true or false)) and cooldown[classtable.GrimoireofSacrifice].ready then
        if not setSpell then setSpell = classtable.GrimoireofSacrifice end
    end
    if (targets >3) then
        Affliction:aoe()
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDoomguard, 'SummonDoomguard')) and cooldown[classtable.SummonDoomguard].ready then
        if not setSpell then setSpell = classtable.SummonDoomguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulSwap, 'SoulSwap')) and (buff[classtable.SoulburnBuff].up) and cooldown[classtable.SoulSwap].ready then
        if not setSpell then setSpell = classtable.SoulSwap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (not (MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] == classtable.Haunt) and debuff[classtable.HauntDeBuff].remains <1 + 1 + ( classtable and classtable.Haunt and GetSpellInfo(classtable.Haunt).castTime /1000 or 0) and SoulShards >0) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulSwap, 'SoulSwap')) and (targets >1 and timeInCombat <10 and MaxDps:HasGlyphEnabled(classtable.SoulSwapGlyph)) and cooldown[classtable.SoulSwap].ready then
        if not setSpell then setSpell = classtable.SoulSwap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (not (MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] == classtable.Haunt) and debuff[classtable.HauntDeBuff].remains <1 + 1 + ( classtable and classtable.Haunt and GetSpellInfo(classtable.Haunt).castTime /1000 or 0) and SoulShards >1) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Soulburn, 'Soulburn')) and (buff[classtable.DarkSoulBuff].up and SoulShards >0) and cooldown[classtable.Soulburn].ready then
        if not setSpell then setSpell = classtable.Soulburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.Agony, 'Agony')) and (( not debuff[classtable.AgonyDeBuff].up or debuff[classtable.AgonyDeBuff].remains <= action.drain_soul.new_tick_time * 2 ) and ttd >= 8 and true) and cooldown[classtable.Agony].ready then
        if not setSpell then setSpell = classtable.Agony end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (( not debuff[classtable.CorruptionDeBuff].up or debuff[classtable.CorruptionDeBuff].remains <1 ) and ttd >= 6 and true) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (( not debuff[classtable.UnstableAfflictionDeBuff].up or debuff[classtable.UnstableAfflictionDeBuff].remains <( ( classtable and classtable.UnstableAffliction and GetSpellInfo(classtable.UnstableAffliction).castTime /1000 or 0) + 1 ) ) and ttd >= 5 and true) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (targethealthPerc <= 20) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <35) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficGrasp, 'MaleficGrasp')) and cooldown[classtable.MaleficGrasp].ready then
        if not setSpell then setSpell = classtable.MaleficGrasp end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <80 and ManaPerc <targethealthPerc) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.FelFlame, 'FelFlame')) and cooldown[classtable.FelFlame].ready then
        if not setSpell then setSpell = classtable.FelFlame end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
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
    classtable.Wither = 445468
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
        talents[classtable.GrimoireofService] = 1
        talents[classtable.GrimoireofSacrifice] = 1
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
