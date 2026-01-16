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

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.CurseoftheElements, false)
    MaxDps:GlowCooldown(classtable.CurseofDoom, false)
end

function Affliction:AoE()
end

function Affliction:Single()
    if (MaxDps:CheckSpellUsable(classtable.SummonImp, 'SummonImp')) and (not UnitExists('pet')) and cooldown[classtable.SummonImp].ready then
        if not setSpell then setSpell = classtable.SummonImp end
    end
    if (MaxDps:CheckSpellUsable(classtable.CurseoftheElements, 'CurseoftheElements')) and (MaxDps:FindADAuraData(classtable.CurseoftheElements).refreshable) and cooldown[classtable.CurseoftheElements].ready then
        --if not setSpell then setSpell = classtable.CurseoftheElements end
        MaxDps:GlowCooldown(classtable.CurseoftheElements, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.CurseofDoom, 'CurseofDoom')) and (MaxDps:FindADAuraData(classtable.CurseofDoom).refreshable) and cooldown[classtable.CurseofDoom].ready then
        --if not setSpell then setSpell = classtable.CurseofDoom end
        MaxDps:GlowCooldown(classtable.CurseofDoom, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (MaxDps:FindADAuraData(classtable.UnstableAffliction).refreshable) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (MaxDps:FindADAuraData(classtable.Corruption).refreshable) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.SiphonLife, 'SiphonLife')) and (MaxDps:FindADAuraData(classtable.SiphonLife).refreshable) and cooldown[classtable.SiphonLife].ready then
        if not setSpell then setSpell = classtable.SiphonLife end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (MaxDps:FindADAuraData(classtable.Immolate).refreshable and MaxDps:FindADAuraData(classtable.ImprovedScorch).up) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end

function Affliction:callaction()
    Affliction:Single()
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

    classtable.SummonImp = 688
    classtable.CurseoftheElements = 1490
    classtable.CurseofDoom = 603
    classtable.UnstableAffliction = 30108
    classtable.Corruption = 172
    classtable.SiphonLife = 63106
    classtable.Immolate = 348
    classtable.ImprovedScorch = 12873
    classtable.ShadowBolt = 686

    setSpell = nil
    ClearCDs()

    Affliction:callaction()
    if setSpell then return setSpell end
end
