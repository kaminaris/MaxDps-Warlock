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
    if (MaxDps:CheckSpellUsable(classtable.FelArmor, 'FelArmor')) and (not buff[classtable.ArmorBuff].up) and cooldown[classtable.FelArmor].ready and not UnitAffectingCombat('player') then
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
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (not debuff[classtable.Haunt].up or debuff[classtable.Haunt].remains <( ( classtable and classtable.Haunt and GetSpellInfo(classtable.Haunt).castTime /1000 or 0) + 1 + 2 )) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (debuff[classtable.Corruption].remains <buff[classtable.CorruptionBuff].duration) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (debuff[classtable.UnstableAffliction].remains <buff[classtable.UnstableAfflictionBuff].duration and targetHP >25) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bane, 'Bane')) and (not not debuff[classtable.MyBane].up) and cooldown[classtable.Bane].ready then
        if not setSpell then setSpell = classtable.Bane end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (targetHP <= 25) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowflame, 'Shadowflame')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) <7) and cooldown[classtable.Shadowflame].ready then
        if not setSpell then setSpell = classtable.Shadowflame end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (targetHP >25 and (LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) >7 or not debuff[classtable.ShadowEmbraceDeBuff].up and targetHP >25 or (LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) <7 and cooldown[classtable.Shadowflame].remains >3) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Soulburn, 'Soulburn')) and ((GetUnitSpeed('player') >0)) and cooldown[classtable.Soulburn].ready then
        if not setSpell then setSpell = classtable.Soulburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (buff[classtable.SoulburnBuff].up) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <30 or ManaPerc <70 and (GetUnitSpeed('player') >0) and IsSpellKnownOrOverridesKnown(63320)) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
end
function Affliction:aoe()
    if (MaxDps:CheckSpellUsable(classtable.CurseoftheElements, 'CurseoftheElements')) and ((talents[classtable.Jinx] and talents[classtable.Jinx] or 0) and ( not debuff[classtable.JinxCurseElements].up and debuff[classtable.CurseoftheElementsDeBuff].remains <3 )) and cooldown[classtable.CurseoftheElements].ready then
        if not setSpell then setSpell = classtable.CurseoftheElements end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (debuff[classtable.Corruption].remains <2 and targets <6) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (debuff[classtable.UnstableAffliction].remains <( classtable and classtable.UnstableAffliction and GetSpellInfo(classtable.UnstableAffliction).castTime /1000 or 0)) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.BaneofAgony, 'BaneofAgony')) and (debuff[classtable.BaneofAgony].remains <buff[classtable.BaneofAgonyBuff].duration and not not debuff[classtable.BaneofDoom].up and not not debuff[classtable.BaneofHavoc].up) and cooldown[classtable.BaneofAgony].ready then
        if not setSpell then setSpell = classtable.BaneofAgony end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (not debuff[classtable.Haunt].up or debuff[classtable.Haunt].remains <( ( classtable and classtable.Haunt and GetSpellInfo(classtable.Haunt).castTime /1000 or 0) + 1 + 2 )) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulSwap, 'SoulSwap')) and (debuff[classtable.BaneofAgony].up and targets == 2) and cooldown[classtable.SoulSwap].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.SynapseSprings, 'SynapseSprings')) and cooldown[classtable.SynapseSprings].ready then
        if not setSpell then setSpell = classtable.SynapseSprings end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (not debuff[classtable.ShadowEmbraceDeBuff].up and targetHP >25) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (not debuff[classtable.Haunt].up or debuff[classtable.Haunt].remains <( ( classtable and classtable.Haunt and GetSpellInfo(classtable.Haunt).castTime /1000 or 0) + 1 + 2 )) and cooldown[classtable.Haunt].ready then
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
    classtable.Wither = 445468
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ArmorBuff = 0
    classtable.ShadowEmbraceDeBuff = 32389
    classtable.SoulburnBuff = 74434
    classtable.CurseoftheElementsDeBuff = 0
    classtable.FelSparkBuff = 89937
    classtable.UnstableAfflictionDeBuff = 30108
    classtable.SoulHarvest = 79268
    classtable.FelArmor = 28176
    classtable.SummonFelhunter = 691
    classtable.Haunt = 48181
    classtable.Corruption = 172
    classtable.UnstableAffliction = 30108
    classtable.DrainSoul = 1120
    classtable.Shadowflame = 47897
    classtable.ShadowBolt = 686
    classtable.Soulburn = 74434
    classtable.SoulFire = 6353
    classtable.LifeTap = 1454
    classtable.SoulSwap = 86121
    classtable.FelFlame = 77799
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
