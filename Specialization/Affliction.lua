local _, addonTable = ...
local Warlock = addonTable.Warlock
local MaxDps = _G.MaxDps
if not MaxDps then return end
local LibStub = LibStub
local setSpell

local ceil = ceil
local floor = floor
local fmod = fmod
local format = format
local max = max
local min = min
local pairs = pairs
local select = select
local strsplit = strsplit
local GetTime = GetTime

local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitSpellHaste = UnitSpellHaste
local UnitThreatSituation = UnitThreatSituation
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
local GetSpellCastCount = C_Spell.GetSpellCastCount
local GetUnitSpeed = GetUnitSpeed
local GetCritChance = GetCritChance
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = C_Item.GetItemInfo
local GetItemSpell = C_Item.GetItemSpell
local GetNamePlates = C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates or GetNamePlates
local GetPowerRegenForPowerType = GetPowerRegenForPowerType
local GetSpellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName or GetSpellInfo
local GetTotemInfo = GetTotemInfo
local IsStealthed = IsStealthed
local IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

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

local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local ManaRegen
local ManaRegenCombined
local ManaTimeToMax
local SoulShards
local SoulShardsMax
local SoulShardsDeficit
local SoulShardsPerc
local SoulShardsRegen
local SoulShardsRegenCombined
local SoulShardsTimeToMax
local DemonicFury
local BurningEmber

local Affliction = {}

local cleave_apl = false
local trinket_1_buffs = false
local trinket_2_buffs = false
local trinket_1_sync = false
local trinket_2_sync = false
local trinket_1_manual = false
local trinket_2_manual = false
local trinket_1_exclude = false
local trinket_2_exclude = false
local trinket_1_buff_duration = 0
local trinket_2_buff_duration = 0
local trinket_priority = false
local min_agony = 0
local min_vt = 10
local min_ps = 16
local min_ps1 = false
local ps_up = false
local vt_up = false
local vt_ps_up = false
local sr_up = false
local cd_dots_up = false
local has_cds = false
local cds_active = false


local function GetTotemInfoByName(name)
    local info = {
        duration = 0,
        remains = 0,
        up = false,
    }
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local remains = math.floor(startTime+duration-GetTime())
        if (totemName == name ) then
            info.duration = duration
            info.up = true
            info.remains = remains
            break
        end
    end
    return info
end

local function GetTotemInfoById(sSpellID)
    local info = {
        duration = 0,
        remains = 0,
        up = false,
    }
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon, modRate, spellID = GetTotemInfo(index)
        local sName = sSpellID and GetSpellInfo(sSpellID).name or ''
        local remains = math.floor(startTime+duration-GetTime())
        if (spellID == sSpellID) or (totemName == sName ) then
            info.duration = duration
            info.up = true
            info.remains = remains
            break
        end
    end
    return info
end

local function GetTotemTypeActive(i)
   local arg1, totemName, startTime, duration, icon = GetTotemInfo(i)
   return duration > 0
end


function Affliction:precombat()
    if (MaxDps:CheckSpellUsable(classtable.FelDomination, 'FelDomination')) and (timeInCombat >0 and not UnitExists('pet')) and cooldown[classtable.FelDomination].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FelDomination end
    end
    cleave_apl = false
    trinket_1_buffs = MaxDps:HasOnUseEffect('13')
    trinket_2_buffs = MaxDps:HasOnUseEffect('14')
    if trinket_1_buffs and (math.fmod(MaxDps:CheckTrinketCooldownDuration('13') , cooldown[classtable.SoulRot].duration) == 0 or math.fmod(cooldown[classtable.SoulRot].duration , MaxDps:CheckTrinketCooldownDuration('13')) == 0) then
        trinket_1_sync = 1
    else
        trinket_1_sync = 0.5
    end
    if trinket_2_buffs and (math.fmod(MaxDps:CheckTrinketCooldownDuration('14') , cooldown[classtable.SoulRot].duration) == 0 or math.fmod(cooldown[classtable.SoulRot].duration , MaxDps:CheckTrinketCooldownDuration('14')) == 0) then
        trinket_2_sync = 1
    else
        trinket_2_sync = 0.5
    end
    trinket_1_manual = MaxDps:CheckTrinketNames('SpymastersWeb') or MaxDps:CheckTrinketNames('AberrantSpellforge')
    trinket_2_manual = MaxDps:CheckTrinketNames('SpymastersWeb') or MaxDps:CheckTrinketNames('AberrantSpellforge')
    trinket_1_exclude = MaxDps:CheckTrinketNames('RubyWhelpShell')
    trinket_2_exclude = MaxDps:CheckTrinketNames('RubyWhelpShell')
    trinket_1_buff_duration = 1+((MaxDps:CheckTrinketNames('MirrorofFracturedTomorrows') and 1 or 0) * 20)
    trinket_2_buff_duration = 1+((MaxDps:CheckTrinketNames('MirrorofFracturedTomorrows') and 1 or 0) * 20)
    if not trinket_1_buffs and trinket_2_buffs or trinket_2_buffs and ((MaxDps:CheckTrinketCooldownDuration('14')%trinket_2_buff_duration)*(1 + 0.5*(MaxDps:HasBuffEffect('14', 'intellect') and 1 or 0))*(trinket_2_sync))>((MaxDps:CheckTrinketCooldownDuration('13')%trinket_1_buff_duration)*(1 + 0.5*(MaxDps:HasBuffEffect('13', 'intellect') and 1 or 0))*(trinket_1_sync)) then
        trinket_priority = 2
    else
        trinket_priority = true
    end
    if (MaxDps:CheckSpellUsable(classtable.GrimoireofSacrifice, 'GrimoireofSacrifice') and talents[classtable.GrimoireofSacrifice]) and ((talents[classtable.GrimoireofSacrifice] and true or false)) and cooldown[classtable.GrimoireofSacrifice].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.GrimoireofSacrifice end
    end
    if (MaxDps:CheckSpellUsable(classtable.SeedofCorruption, 'SeedofCorruption') and talents[classtable.SeedofCorruption]) and (targets >2 or targets >1 and talents[classtable.DemonicSoul]) and cooldown[classtable.SeedofCorruption].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SeedofCorruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and cooldown[classtable.Haunt].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Haunt end
    end
end
function Affliction:aoe()
    min_agony = min(debuff[classtable.AgonyDeBuff].remains)
    min_vt = min(debuff[classtable.VileTaintDeBuff].remains)
    min_ps = min(debuff[classtable.PhantomSingularityDeBuff].remains)
    min_ps1 = math.min((min_vt * (talents[classtable.VileTaint] and talents[classtable.VileTaint] or 0)) , (min_ps * (talents[classtable.PhantomSingularity] and talents[classtable.PhantomSingularity] or 0)))
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (debuff[classtable.HauntDeBuff].remains <3) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.VileTaint, 'VileTaint') and talents[classtable.VileTaint]) and ((cooldown[classtable.SoulRot].remains <= timeShift or cooldown[classtable.SoulRot].remains >= 25)) and cooldown[classtable.VileTaint].ready then
        if not setSpell then setSpell = classtable.VileTaint end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhantomSingularity, 'PhantomSingularity') and talents[classtable.PhantomSingularity]) and ((cooldown[classtable.SoulRot].remains <= timeShift or cooldown[classtable.SoulRot].remains >= 25) and debuff[classtable.AgonyDeBuff].up) and cooldown[classtable.PhantomSingularity].ready then
        if not setSpell then setSpell = classtable.PhantomSingularity end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and ((MaxDps:DebuffCounter(classtable.UnstableAfflictionDeBuff) == 0 or debuff[classtable.UnstableAfflictionDeBuff].up) and debuff[classtable.UnstableAfflictionDeBuff].remains <5) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.Agony, 'Agony')) and (MaxDps:DebuffCounter(classtable.AgonyDeBuff) <8 and (debuff[classtable.AgonyDeBuff].remains <cooldown[classtable.VileTaint].remains+( classtable and classtable.VileTaint and GetSpellInfo(classtable.VileTaint).castTime / 1000 or 0) or not talents[classtable.VileTaint]) and gcd + ( classtable and classtable.SoulRot and GetSpellInfo(classtable.SoulRot).castTime / 1000 or 0)+gcd<(math.min((min_vt * (talents[classtable.VileTaint] and talents[classtable.VileTaint] or 0)) , (min_ps * (talents[classtable.PhantomSingularity] and talents[classtable.PhantomSingularity] or 0)))) and debuff[classtable.AgonyDeBuff].remains <10) and cooldown[classtable.Agony].ready then
        if not setSpell then setSpell = classtable.Agony end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulRot, 'SoulRot') and talents[classtable.SoulRot]) and (vt_up and (ps_up or vt_up) and debuff[classtable.AgonyDeBuff].up) and cooldown[classtable.SoulRot].ready then
        if not setSpell then setSpell = classtable.SoulRot end
    end
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence')) and (ps_up and vt_up and sr_up) and cooldown[classtable.Malevolence].ready then
        if not setSpell then setSpell = classtable.Malevolence end
    end
    if (MaxDps:CheckSpellUsable(classtable.SeedofCorruption, 'SeedofCorruption') and talents[classtable.SeedofCorruption]) and (((not talents[classtable.Wither] and debuff[classtable.CorruptionDeBuff].remains <5) or (talents[classtable.Wither] and debuff[classtable.WitherDeBuff].remains <5)) and not ((MaxDps.spellHistory[1] == classtable.SeedofCorruption) or MaxDps:DebuffCounter(classtable.SeedofCorruptionDeBuff) >0)) and cooldown[classtable.SeedofCorruption].ready then
        if not setSpell then setSpell = classtable.SeedofCorruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (not talents[classtable.Wither] and debuff[classtable.CorruptionDeBuff].remains <5 and not talents[classtable.SeedofCorruption]) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither') and talents[classtable.Wither]) and (debuff[classtable.WitherDeBuff].remains <5 and not talents[classtable.SeedofCorruption]) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDarkglare, 'SummonDarkglare') and talents[classtable.SummonDarkglare]) and (ps_up and vt_up and sr_up) and cooldown[classtable.SummonDarkglare].ready then
        MaxDps:GlowCooldown(classtable.SummonDarkglare, cooldown[classtable.SummonDarkglare].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and ((cooldown[classtable.SummonDarkglare].remains >15 or SoulShards >3 or (talents[classtable.DemonicSoul] and SoulShards >2)) and buff[classtable.TormentedCrescendoBuff].up) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (SoulShards >4 or (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].count == 1 and SoulShards >3)) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.DemonicSoul] and (SoulShards >2 or (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].count == 1 and SoulShards))) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].up) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].count == 2) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and ((cd_dots_up or vt_ps_up) and (SoulShards >2 or cooldown[classtable.Oblivion].remains >10 or not talents[classtable.Oblivion])) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and talents[classtable.Nightfall] and buff[classtable.TormentedCrescendoBuff].up and buff[classtable.NightfallBuff].up) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and (talents[classtable.DrainSoul] and buff[classtable.NightfallBuff].up and talents[classtable.ShadowEmbrace] and (debuff[classtable.ShadowEmbraceDeBuff].count <4 or debuff[classtable.ShadowEmbraceDeBuff].remains <3)) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and (talents[classtable.DrainSoul] and (talents[classtable.ShadowEmbrace] and (debuff[classtable.ShadowEmbraceDeBuff].count <4 or debuff[classtable.ShadowEmbraceDeBuff].remains <3)) or not talents[classtable.ShadowEmbrace]) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (buff[classtable.NightfallBuff].up and talents[classtable.ShadowEmbrace] and (debuff[classtable.ShadowEmbraceDeBuff].count <2 or debuff[classtable.ShadowEmbraceDeBuff].remains <3)) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end
function Affliction:cleave()
    if (MaxDps:boss()) then
        Affliction:end_of_fight()
    end
    if (MaxDps:CheckSpellUsable(classtable.Agony, 'Agony')) and (debuff[classtable.AgonyDeBuff].refreshable and (debuff[classtable.AgonyDeBuff].remains <cooldown[classtable.VileTaint].remains+( classtable and classtable.VileTaint and GetSpellInfo(classtable.VileTaint).castTime / 1000 or 0) or not talents[classtable.VileTaint]) and (debuff[classtable.AgonyDeBuff].remains <gcd*2 or talents[classtable.DemonicSoul] and debuff[classtable.AgonyDeBuff].remains <cooldown[classtable.SoulRot].remains+8 and cooldown[classtable.SoulRot].remains <5) and ttd >debuff[classtable.AgonyDeBuff].remains+5) and cooldown[classtable.Agony].ready then
        if not setSpell then setSpell = classtable.Agony end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither') and talents[classtable.Wither]) and (debuff[classtable.WitherDeBuff].refreshable and debuff[classtable.WitherDeBuff].remains <5 and not ((MaxDps.spellHistory[1] == classtable.SeedofCorruption) or debuff[classtable.SeedofCorruptionDeBuff].remains >0) and ttd >debuff[classtable.WitherDeBuff].remains+5) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].count <2-(MaxDps.spellHistory[1] == classtable.DrainSoul and 1 or 0) and (not talents[classtable.VileTaint] or not cooldown[classtable.VileTaint].ready) or debuff[classtable.HauntDeBuff].remains <3) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and ((debuff[classtable.UnstableAfflictionDeBuff].remains <5 or talents[classtable.DemonicSoul] and debuff[classtable.UnstableAfflictionDeBuff].remains <cooldown[classtable.SoulRot].remains+8 and cooldown[classtable.SoulRot].remains <5) and ttd >debuff[classtable.UnstableAfflictionDeBuff].remains+5) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (not talents[classtable.Wither] and debuff[classtable.CorruptionDeBuff].refreshable and debuff[classtable.CorruptionDeBuff].remains <5 and not ((MaxDps.spellHistory[1] == classtable.SeedofCorruption) or debuff[classtable.SeedofCorruptionDeBuff].remains >0) and ttd >debuff[classtable.CorruptionDeBuff].remains+5) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (talents[classtable.Wither]) then
        Affliction:cleave_se_maintenance()
    end
    if (MaxDps:CheckSpellUsable(classtable.VileTaint, 'VileTaint') and talents[classtable.VileTaint]) and (not talents[classtable.SoulRot] or (min_agony <1.5 or cooldown[classtable.SoulRot].remains <= timeShift+gcd) or cooldown[classtable.SoulRot].remains >= 20) and cooldown[classtable.VileTaint].ready then
        if not setSpell then setSpell = classtable.VileTaint end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhantomSingularity, 'PhantomSingularity') and talents[classtable.PhantomSingularity]) and ((not talents[classtable.SoulRot] or cooldown[classtable.SoulRot].remains <4 or ttd <cooldown[classtable.SoulRot].remains) and MaxDps:DebuffCounter(classtable.AgonyDeBuff) == 2) and cooldown[classtable.PhantomSingularity].ready then
        if not setSpell then setSpell = classtable.PhantomSingularity end
    end
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence')) and (vt_ps_up) and cooldown[classtable.Malevolence].ready then
        if not setSpell then setSpell = classtable.Malevolence end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulRot, 'SoulRot') and talents[classtable.SoulRot]) and ((vt_ps_up) and MaxDps:DebuffCounter(classtable.AgonyDeBuff) == 2) and cooldown[classtable.SoulRot].ready then
        if not setSpell then setSpell = classtable.SoulRot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDarkglare, 'SummonDarkglare') and talents[classtable.SummonDarkglare]) and (cd_dots_up) and cooldown[classtable.SummonDarkglare].ready then
        MaxDps:GlowCooldown(classtable.SummonDarkglare, cooldown[classtable.SummonDarkglare].ready)
    end
    if (talents[classtable.DemonicSoul]) then
        Affliction:opener_cleave_se()
    end
    if (talents[classtable.DemonicSoul]) then
        Affliction:cleave_se_maintenance()
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (SoulShards >4 and (talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].count <2 or not talents[classtable.DemonicSoul]) or buff[classtable.TormentedCrescendoBuff].count >1) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and (talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].up and buff[classtable.TormentedCrescendoBuff].count <2 and targethealthPerc <20) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.DemonicSoul] and (SoulShards >1 or buff[classtable.TormentedCrescendoBuff].up and cooldown[classtable.SoulRot].remains >buff[classtable.TormentedCrescendoBuff].remains*gcd) and (not talents[classtable.VileTaint] or SoulShards >1 and cooldown[classtable.VileTaint].remains >10) and (not talents[classtable.Oblivion] or cooldown[classtable.Oblivion].remains >10 or SoulShards >2 and cooldown[classtable.Oblivion].remains <10)) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].up and (buff[classtable.TormentedCrescendoBuff].remains <gcd*2 or buff[classtable.TormentedCrescendoBuff].count == 2)) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and ((cd_dots_up or (talents[classtable.DemonicSoul] or talents[classtable.PhantomSingularity]) and vt_ps_up or talents[classtable.Wither] and vt_ps_up and not debuff[classtable.SoulRotDeBuff].up and SoulShards >1) and (not talents[classtable.Oblivion] or cooldown[classtable.Oblivion].remains >10 or SoulShards >2 and cooldown[classtable.Oblivion].remains <10)) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and talents[classtable.Nightfall] and buff[classtable.TormentedCrescendoBuff].up and buff[classtable.NightfallBuff].up or talents[classtable.DemonicSoul] and not buff[classtable.NightfallBuff].up and (not talents[classtable.VileTaint] or cooldown[classtable.VileTaint].remains >10 or SoulShards >1 and cooldown[classtable.VileTaint].remains <10)) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (not talents[classtable.DemonicSoul] and buff[classtable.TormentedCrescendoBuff].up) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Agony, 'Agony')) and (debuff[classtable.AgonyDeBuff].refreshable or cooldown[classtable.SoulRot].remains <5 and debuff[classtable.AgonyDeBuff].remains <8) and cooldown[classtable.Agony].ready then
        if not setSpell then setSpell = classtable.Agony end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (debuff[classtable.UnstableAfflictionDeBuff].refreshable or cooldown[classtable.SoulRot].remains <5 and debuff[classtable.UnstableAfflictionDeBuff].remains <8) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and (buff[classtable.NightfallBuff].up) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (buff[classtable.NightfallBuff].up) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither') and talents[classtable.Wither]) and (debuff[classtable.WitherDeBuff].refreshable) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (not talents[classtable.Wither] and debuff[classtable.CorruptionDeBuff].refreshable) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end
function Affliction:end_of_fight()
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and (talents[classtable.DemonicSoul] and (MaxDps:boss() and ttd <5 and buff[classtable.NightfallBuff].up or (MaxDps.spellHistory[1] == classtable.Haunt) and buff[classtable.NightfallBuff].count == 2 and not buff[classtable.TormentedCrescendoBuff].up)) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Oblivion, 'Oblivion') and talents[classtable.Oblivion]) and (SoulShards >1 and MaxDps:boss() and ttd<(SoulShards + buff[classtable.TormentedCrescendoBuff].duration)*gcd + timeShift) and cooldown[classtable.Oblivion].ready then
        if not setSpell then setSpell = classtable.Oblivion end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (MaxDps:boss() and ttd <4 and (not talents[classtable.DemonicSoul] or talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].count <1)) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
end
function Affliction:se_maintenance()
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and (talents[classtable.ShadowEmbrace] and talents[classtable.DrainSoul] and (debuff[classtable.ShadowEmbraceDeBuff].count <debuff[classtable.ShadowEmbraceDeBuff].maxStacks or debuff[classtable.ShadowEmbraceDeBuff].remains <3) and targets <= 4 and ttd >15) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (talents[classtable.ShadowEmbrace] and ((debuff[classtable.ShadowEmbraceDeBuff].count+(((MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.ShadowBolt] and GetTime() - MaxDps.spellHistoryTime[classtable.ShadowBolt].last_used or 0) <1) and 1 or 0))<debuff[classtable.ShadowEmbraceDeBuff].maxStacks or debuff[classtable.ShadowEmbraceDeBuff].remains <3 and not (cooldown[classtable.ShadowBolt].duration - cooldown[classtable.ShadowBolt].remains <1)) and targets <= 4 and ttd >15) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end
function Affliction:opener_cleave_se()
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and (talents[classtable.ShadowEmbrace] and talents[classtable.DrainSoul] and buff[classtable.NightfallBuff].up and (debuff[classtable.ShadowEmbraceDeBuff].count <debuff[classtable.ShadowEmbraceDeBuff].maxStacks or debuff[classtable.ShadowEmbraceDeBuff].remains <3) and (ttd >15 or timeInCombat <20)) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
end
function Affliction:cleave_se_maintenance()
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and (talents[classtable.ShadowEmbrace] and talents[classtable.DrainSoul] and (talents[classtable.Wither] or talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].up) and (debuff[classtable.ShadowEmbraceDeBuff].count <debuff[classtable.ShadowEmbraceDeBuff].maxStacks or debuff[classtable.ShadowEmbraceDeBuff].remains <3) and ttd >15) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (talents[classtable.ShadowEmbrace] and not talents[classtable.DrainSoul] and ((debuff[classtable.ShadowEmbraceDeBuff].count + (MaxDps.spellHistory[1] == classtable.ShadowBolt and 1 or 0))<debuff[classtable.ShadowEmbraceDeBuff].maxStacks or debuff[classtable.ShadowEmbraceDeBuff].remains <3 and not (cooldown[classtable.ShadowBolt].duration - cooldown[classtable.ShadowBolt].remains <1)) and ttd >15) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end
function Affliction:items()
    if (MaxDps:CheckSpellUsable(classtable.aberrant_spellforge, 'aberrant_spellforge')) and (gcd >gcd*0.8) and cooldown[classtable.aberrant_spellforge].ready then
        MaxDps:GlowCooldown(classtable.aberrant_spellforge, cooldown[classtable.aberrant_spellforge].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.spymasters_web, 'spymasters_web')) and (cd_dots_up and (buff[classtable.SpymastersReportBuff].count >= 38 or MaxDps:boss() and ttd <= 80 or talents[classtable.DrainSoul] and targethealthPerc <20) or MaxDps:boss() and ttd <20) and cooldown[classtable.spymasters_web].ready then
        MaxDps:GlowCooldown(classtable.spymasters_web, cooldown[classtable.spymasters_web].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and ((cds_active) and (trinket_priority == 1 or trinket_2_exclude or not MaxDps:HasOnUseEffect('14') or (MaxDps:CheckTrinketCooldown('14') or trinket_priority == 2 and cooldown[classtable.SummonDarkglare].remains >20 and not ( UnitExists('pet') and UnitName('pet')  == 'Darkglare' ) and MaxDps:CheckTrinketCooldown('14') <cooldown[classtable.SummonDarkglare].remains)) and trinket_1_buffs and not trinket_1_manual or (trinket_1_buff_duration + 1>=ttd)) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and ((cds_active) and (trinket_priority == 2 or trinket_1_exclude or not MaxDps:HasOnUseEffect('13') or (MaxDps:CheckTrinketCooldown('13') or trinket_priority == 1 and cooldown[classtable.SummonDarkglare].remains >20 and not ( UnitExists('pet') and UnitName('pet')  == 'Darkglare' ) and MaxDps:CheckTrinketCooldown('13') <cooldown[classtable.SummonDarkglare].remains)) and trinket_2_buffs and not trinket_2_manual or (trinket_2_buff_duration + 1>=ttd)) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.time_thiefs_gambit, 'time_thiefs_gambit')) and (cds_active or MaxDps:boss() and ttd <15 or ((MaxDps:CheckTrinketCooldownDuration('13') <cooldown[classtable.SummonDarkglare].remains+5) and targets == 1) or (targets >1 and havoc_active)) and cooldown[classtable.time_thiefs_gambit].ready then
        MaxDps:GlowCooldown(classtable.time_thiefs_gambit, cooldown[classtable.time_thiefs_gambit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not trinket_1_buffs and not trinket_1_manual and (not trinket_1_buffs and (MaxDps:CheckTrinketCooldown('14') or not trinket_2_buffs) or talents[classtable.SummonDarkglare] and cooldown[classtable.SummonDarkglare].remains >20 or not talents[classtable.SummonDarkglare])) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not trinket_2_buffs and not trinket_2_manual and (not trinket_2_buffs and (MaxDps:CheckTrinketCooldown('13') or not trinket_1_buffs) or talents[classtable.SummonDarkglare] and cooldown[classtable.SummonDarkglare].remains >20 or not talents[classtable.SummonDarkglare])) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.main_hand, 'main_hand')) and (not MaxDps:CheckEquipped('NeuralSynapseEnhancer')) and cooldown[classtable.main_hand].ready then
        if not setSpell then setSpell = classtable.main_hand end
    end
    if (MaxDps:CheckSpellUsable(classtable.neural_synapse_enhancer, 'neural_synapse_enhancer')) and (((MaxDps.spellHistory[1] == classtable.SoulRot) or MaxDps:boss() and ttd <= 15) and not trinket_1_buffs and not trinket_2_buffs) and cooldown[classtable.neural_synapse_enhancer].ready then
        MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, cooldown[classtable.neural_synapse_enhancer].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.neural_synapse_enhancer, 'neural_synapse_enhancer')) and (((MaxDps.spellHistory[1] == classtable.SoulRot) or MaxDps:boss() and ttd <= 15 or cooldown[classtable.SoulRot].remains >= 45) and MaxDps:CheckTrinketCooldown('14') and trinket_2_buffs) and cooldown[classtable.neural_synapse_enhancer].ready then
        MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, cooldown[classtable.neural_synapse_enhancer].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.neural_synapse_enhancer, 'neural_synapse_enhancer')) and (((MaxDps.spellHistory[1] == classtable.SoulRot) or MaxDps:boss() and ttd <= 15 or cooldown[classtable.SoulRot].remains >= 45) and MaxDps:CheckTrinketCooldown('13') and trinket_1_buffs) and cooldown[classtable.neural_synapse_enhancer].ready then
        MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, cooldown[classtable.neural_synapse_enhancer].ready)
    end
end
function Affliction:ogcd()
end
function Affliction:variables()
    ps_up = not talents[classtable.PhantomSingularity] or debuff[classtable.PhantomSingularityDeBuff].up
    vt_up = not talents[classtable.VileTaint] or debuff[classtable.VileTaintDeBuff].up
    vt_ps_up = (not talents[classtable.VileTaint] and not talents[classtable.PhantomSingularity]) or debuff[classtable.VileTaintDeBuff].up or debuff[classtable.PhantomSingularityDeBuff].up
    sr_up = not talents[classtable.SoulRot] or debuff[classtable.SoulRotDeBuff].up
    cd_dots_up = ps_up and vt_up and sr_up
    has_cds = talents[classtable.PhantomSingularity] or talents[classtable.VileTaint] or talents[classtable.SoulRot] or talents[classtable.SummonDarkglare]
    cds_active = not has_cds or (cd_dots_up and (not talents[classtable.SummonDarkglare] or cooldown[classtable.SummonDarkglare].remains >20 or GetTotemInfoById(classtable.Darkglare).remains))
    if min_vt then
        min_vt = 10
    end
    if min_ps then
        min_ps = 16
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.SpellLock, false)
    MaxDps:GlowCooldown(classtable.SummonDarkglare, false)
    MaxDps:GlowCooldown(classtable.aberrant_spellforge, false)
    MaxDps:GlowCooldown(classtable.spymasters_web, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
    MaxDps:GlowCooldown(classtable.time_thiefs_gambit, false)
    MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, false)
end

function Affliction:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SpellLock, 'SpellLock')) and cooldown[classtable.SpellLock].ready then
        MaxDps:GlowCooldown(classtable.SpellLock, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    Affliction:variables()
    Affliction:ogcd()
    Affliction:items()
    if (targets == 2 or targets >2 and cleave_apl) then
        Affliction:cleave()
    end
    if (targets >2) then
        Affliction:aoe()
    end
    Affliction:end_of_fight()
    if (MaxDps:CheckSpellUsable(classtable.Agony, 'Agony')) and ((not talents[classtable.VileTaint] or debuff[classtable.AgonyDeBuff].remains <cooldown[classtable.VileTaint].remains+( classtable and classtable.VileTaint and GetSpellInfo(classtable.VileTaint).castTime / 1000 or 0)) and (talents[classtable.AbsoluteCorruption] and debuff[classtable.AgonyDeBuff].remains <3 or not talents[classtable.AbsoluteCorruption] and debuff[classtable.AgonyDeBuff].remains <5 or cooldown[classtable.SoulRot].remains <5 and debuff[classtable.AgonyDeBuff].remains <8) and ttd >debuff[classtable.AgonyDeBuff].remains+5) and cooldown[classtable.Agony].ready then
        if not setSpell then setSpell = classtable.Agony end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].count <2-(MaxDps.spellHistory[1] == classtable.DrainSoul and 1 or 0) and (not talents[classtable.VileTaint] or not cooldown[classtable.VileTaint].ready)) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and ((MaxDps:DebuffCounter(classtable.UnstableAfflictionDeBuff) == 0 or debuff[classtable.UnstableAfflictionDeBuff].up) and (talents[classtable.AbsoluteCorruption] and debuff[classtable.UnstableAfflictionDeBuff].remains <3 or not talents[classtable.AbsoluteCorruption] and debuff[classtable.UnstableAfflictionDeBuff].remains <5 or cooldown[classtable.SoulRot].remains <5 and debuff[classtable.UnstableAfflictionDeBuff].remains <8) and (not talents[classtable.DemonicSoul] or buff[classtable.NightfallBuff].count <2 or (MaxDps.spellHistory[1] == classtable.Haunt) and buff[classtable.NightfallBuff].count <2) and ttd >debuff[classtable.UnstableAfflictionDeBuff].remains+5) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and ((talents[classtable.AbsoluteCorruption] and debuff[classtable.HauntDeBuff].remains <3 or not talents[classtable.AbsoluteCorruption] and debuff[classtable.HauntDeBuff].remains <5 or cooldown[classtable.SoulRot].remains <5 and debuff[classtable.HauntDeBuff].remains <8) and (not talents[classtable.VileTaint] or not cooldown[classtable.VileTaint].ready) and ttd >debuff[classtable.HauntDeBuff].remains+5) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither') and talents[classtable.Wither]) and (talents[classtable.Wither] and not ((MaxDps.spellHistory[1] == classtable.SeedofCorruption) or MaxDps:DebuffCounter(classtable.SeedofCorruptionDeBuff) >0) and (talents[classtable.AbsoluteCorruption] and debuff[classtable.WitherDeBuff].remains <3 or not talents[classtable.AbsoluteCorruption] and debuff[classtable.WitherDeBuff].remains <5) and ttd >debuff[classtable.WitherDeBuff].remains+5) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (not talents[classtable.Wither] and not ((MaxDps.spellHistory[1] == classtable.SeedofCorruption) or MaxDps:DebuffCounter(classtable.SeedofCorruptionDeBuff) >0) and debuff[classtable.CorruptionDeBuff].refreshable and ttd >debuff[classtable.CorruptionDeBuff].remains+5) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and (buff[classtable.NightfallBuff].up and (buff[classtable.NightfallBuff].count >1 or buff[classtable.NightfallBuff].remains <timeShift*2) and not buff[classtable.TormentedCrescendoBuff].up and not cooldown[classtable.SoulRot].ready and SoulShards <5-buff[classtable.TormentedCrescendoBuff].upMath and (not talents[classtable.VileTaint] or not cooldown[classtable.VileTaint].ready)) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (buff[classtable.NightfallBuff].up and (buff[classtable.NightfallBuff].count >1 or buff[classtable.NightfallBuff].remains <timeShift*2) and buff[classtable.TormentedCrescendoBuff].count <2 and not cooldown[classtable.SoulRot].ready and SoulShards <5-buff[classtable.TormentedCrescendoBuff].upMath and (not talents[classtable.VileTaint] or not cooldown[classtable.VileTaint].ready)) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (talents[classtable.Wither]) then
        Affliction:se_maintenance()
    end
    if (MaxDps:CheckSpellUsable(classtable.VileTaint, 'VileTaint') and talents[classtable.VileTaint]) and ((not talents[classtable.SoulRot] or cooldown[classtable.SoulRot].remains >20 or cooldown[classtable.SoulRot].remains <= timeShift+gcd or MaxDps:boss() and ttd <cooldown[classtable.SoulRot].remains) and debuff[classtable.AgonyDeBuff].up and (debuff[classtable.CorruptionDeBuff].up or debuff[classtable.WitherDeBuff].up) and debuff[classtable.UnstableAfflictionDeBuff].up) and cooldown[classtable.VileTaint].ready then
        if not setSpell then setSpell = classtable.VileTaint end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhantomSingularity, 'PhantomSingularity') and talents[classtable.PhantomSingularity]) and ((not talents[classtable.SoulRot] or cooldown[classtable.SoulRot].remains <4 or MaxDps:boss() and ttd <cooldown[classtable.SoulRot].remains) and debuff[classtable.AgonyDeBuff].up and (debuff[classtable.CorruptionDeBuff].up or debuff[classtable.WitherDeBuff].up) and debuff[classtable.UnstableAfflictionDeBuff].up) and cooldown[classtable.PhantomSingularity].ready then
        if not setSpell then setSpell = classtable.PhantomSingularity end
    end
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence')) and (vt_ps_up) and cooldown[classtable.Malevolence].ready then
        if not setSpell then setSpell = classtable.Malevolence end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulRot, 'SoulRot') and talents[classtable.SoulRot]) and (vt_ps_up) and cooldown[classtable.SoulRot].ready then
        if not setSpell then setSpell = classtable.SoulRot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDarkglare, 'SummonDarkglare') and talents[classtable.SummonDarkglare]) and (cd_dots_up and (debuff[classtable.ShadowEmbraceDeBuff].count == debuff[classtable.ShadowEmbraceDeBuff].maxStacks)) and cooldown[classtable.SummonDarkglare].ready then
        MaxDps:GlowCooldown(classtable.SummonDarkglare, cooldown[classtable.SummonDarkglare].ready)
    end
    if (talents[classtable.DemonicSoul]) then
        Affliction:se_maintenance()
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (SoulShards >4 and (talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].count <2 or not talents[classtable.DemonicSoul]) or buff[classtable.TormentedCrescendoBuff].count >1) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and (talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].up and buff[classtable.TormentedCrescendoBuff].count <2 and targethealthPerc <20) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.DemonicSoul] and (SoulShards >1 or buff[classtable.TormentedCrescendoBuff].up and cooldown[classtable.SoulRot].remains >buff[classtable.TormentedCrescendoBuff].remains*gcd) and (not talents[classtable.VileTaint] or SoulShards >1 and cooldown[classtable.VileTaint].remains >10) and (not talents[classtable.Oblivion] or cooldown[classtable.Oblivion].remains >10 or SoulShards >2 and cooldown[classtable.Oblivion].remains <10)) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Oblivion, 'Oblivion') and talents[classtable.Oblivion]) and (debuff[classtable.AgonyDeBuff].remains and (debuff[classtable.CorruptionDeBuff].up or debuff[classtable.WitherDeBuff].up) and debuff[classtable.UnstableAfflictionDeBuff].up and debuff[classtable.HauntDeBuff].remains >5) and cooldown[classtable.Oblivion].ready then
        if not setSpell then setSpell = classtable.Oblivion end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].up and (buff[classtable.TormentedCrescendoBuff].remains <gcd*2 or buff[classtable.TormentedCrescendoBuff].count == 2)) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and ((cd_dots_up or (talents[classtable.DemonicSoul] or talents[classtable.PhantomSingularity]) and vt_ps_up or talents[classtable.Wither] and vt_ps_up and not debuff[classtable.SoulRotDeBuff].up and SoulShards >2) and (not talents[classtable.Oblivion] or cooldown[classtable.Oblivion].remains >10 or SoulShards >2 and cooldown[classtable.Oblivion].remains <10)) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and talents[classtable.Nightfall] and buff[classtable.TormentedCrescendoBuff].up and buff[classtable.NightfallBuff].up or talents[classtable.DemonicSoul] and not buff[classtable.NightfallBuff].up and (not talents[classtable.VileTaint] or cooldown[classtable.VileTaint].remains >10 or SoulShards >1 and cooldown[classtable.VileTaint].remains <10)) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (not talents[classtable.DemonicSoul] and buff[classtable.TormentedCrescendoBuff].up) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and (buff[classtable.NightfallBuff].up) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (buff[classtable.NightfallBuff].up) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Agony, 'Agony')) and (debuff[classtable.AgonyDeBuff].refreshable) and cooldown[classtable.Agony].ready then
        if not setSpell then setSpell = classtable.Agony end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and ((MaxDps:DebuffCounter(classtable.UnstableAfflictionDeBuff) == 0 or debuff[classtable.UnstableAfflictionDeBuff].up) and debuff[classtable.UnstableAfflictionDeBuff].refreshable) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul') and talents[classtable.DrainSoul]) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
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
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    local trinket1ID = GetInventoryItemID('player', 13)
    local trinket2ID = GetInventoryItemID('player', 14)
    local MHID = GetInventoryItemID('player', 16)
    classtable.trinket1 = (trinket1ID and select(2,GetItemSpell(trinket1ID)) ) or 0
    classtable.trinket2 = (trinket2ID and select(2,GetItemSpell(trinket2ID)) ) or 0
    classtable.main_hand = (MHID and select(2,GetItemSpell(MHID)) ) or 0
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    ManaPerc = (Mana / ManaMax) * 100
    ManaRegen = GetPowerRegenForPowerType(ManaPT)
    ManaTimeToMax = ManaDeficit / ManaRegen
    SoulShards = UnitPower('player', SoulShardsPT)
    SoulShardsMax = UnitPowerMax('player', SoulShardsPT)
    SoulShardsDeficit = SoulShardsMax - SoulShards
    SoulShardsPerc = (SoulShards / SoulShardsMax) * 100
    SoulShardsRegen = GetPowerRegenForPowerType(SoulShardsPT)
    SoulShardsTimeToMax = SoulShardsDeficit / SoulShardsRegen
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    classtable.SpellLock = 19647
    classtable.Wither = 445468
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.NightfallBuff = 264571
    classtable.TormentedCrescendoBuff = 387079
    classtable.SpymastersReportBuff = 451199
    classtable.AgonyDeBuff = 980
    classtable.UnstableAfflictionDeBuff = 316099
    classtable.HauntDeBuff = 48181
    classtable.WitherDeBuff = 445474
    classtable.CorruptionDeBuff = 146739
    classtable.ShadowEmbraceDeBuff = 32390
    classtable.SoulRotDeBuff = 386997
    classtable.VileTaintDeBuff = 286931
    classtable.PhantomSingularityDeBuff = 205179
    classtable.SeedofCorruptionDeBuff = 27243
    classtable.VileTaintDotDeBuff = 286931
    classtable.Corruption = 172

    local function debugg()
        talents[classtable.GrimoireofSacrifice] = 1
        talents[classtable.DemonicSoul] = 1
        talents[classtable.VileTaint] = 1
        talents[classtable.AbsoluteCorruption] = 1
        talents[classtable.Wither] = 1
        talents[classtable.SoulRot] = 1
        talents[classtable.Oblivion] = 1
        talents[classtable.TormentedCrescendo] = 1
        talents[classtable.PhantomSingularity] = 1
        talents[classtable.Nightfall] = 1
        talents[classtable.SeedofCorruption] = 1
        talents[classtable.DrainSoul] = 1
        talents[classtable.ShadowEmbrace] = 1
        talents[classtable.SummonDarkglare] = 1
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
