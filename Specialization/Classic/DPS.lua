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
local className, classFilename, classId = UnitClass('player')
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local SoulShards
local SoulShardsMax
local SoulShardsDeficit
local Mana
local ManaMax
local ManaDeficit
local ManaPerc

local DPS = {}

function DPS:precombat()
    if (MaxDps:CheckSpellUsable(classtable.DemonSkin, 'DemonSkin')) and (UnitLevel('player') < 20 and not MaxDps:FindBuffAuraData ( 687 ) .up) and cooldown[classtable.DemonSkin].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DemonSkin end
    end
    if (MaxDps:CheckSpellUsable(classtable.DemonArmor, 'DemonArmor')) and (UnitLevel('player') >= 20 and not MaxDps:FindBuffAuraData ( 706 ) .up) and cooldown[classtable.DemonArmor].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DemonArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.DemonicSacrifice, 'DemonicSacrifice')) and cooldown[classtable.DemonicSacrifice].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DemonicSacrifice end
    end
    if (MaxDps:CheckSpellUsable(classtable.AmplifyCurse, 'AmplifyCurse')) and cooldown[classtable.AmplifyCurse].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.AmplifyCurse end
    end
end
function DPS:priorityList()
    if (MaxDps:CheckSpellUsable(classtable.DemonicRune, 'DemonicRune')) and (ttd >= 15 and ManaPerc <= 60 and targethealthPerc == 35) and cooldown[classtable.DemonicRune].ready then
        if not setSpell then setSpell = classtable.DemonicRune end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn')) and (ttd <= 1.5) and cooldown[classtable.Shadowburn].ready then
        if not setSpell then setSpell = classtable.Shadowburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.SearingPain, 'SearingPain')) and (ttd <= 3.5) and cooldown[classtable.SearingPain].ready then
        if not setSpell then setSpell = classtable.SearingPain end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <10) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.CurseofAgony, 'CurseofAgony')) and (not MaxDps:FindDeBuffAuraData ( 11713 ) .up and MaxDps:NumGroupFriends() > 5) and cooldown[classtable.CurseofAgony].ready then
        if not setSpell then setSpell = classtable.CurseofAgony end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (not MaxDps:FindDeBuffAuraData ( 25311 ) .up) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (not MaxDps:FindDeBuffAuraData ( 25309 ) .up) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end


local function ClearCDs()
end

function Warlock:DPS()
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
    classtable.DemonSkin = 687
    classtable.DemonArmor = 706
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    classtable.DemonicSacrifice=18788
    classtable.AmplifyCurse=18288
    classtable.DemonicRune=12662
    classtable.Shadowburn=18871
    classtable.SearingPain=17923
    classtable.LifeTap=11689
    classtable.CurseofAgony=11713
    classtable.Corruption=25311
    classtable.Immolate=25309
    classtable.ShadowBolt=11661

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    DPS:precombat()
    DPS:priorityList()
    if setSpell then return setSpell end
end
