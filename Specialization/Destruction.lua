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
local havoc_active
local havoc_remains

local Destruction = {}

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
local allow_rof_2t_spender = 2
local do_rof_2t = false
local disable_cb_2t = 0
local pool_soul_shards = false
local havoc_immo_time = 0
local pooling_condition = 1
local pooling_condition_cb = 1
local infernal_active = false
local trinket_1_will_lose_cast = false
local trinket_2_will_lose_cast = false


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
    if (MaxDps:CheckSpellUsable(classtable.FelDomination, 'FelDomination')) and (timeInCombat >0 and not UnitExists('pet')) and cooldown[classtable.FelDomination].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FelDomination end
    end
    cleave_apl = false
    trinket_1_buffs = MaxDps:HasOnUseEffect('13')
    trinket_2_buffs = MaxDps:HasOnUseEffect('14')
    if trinket_1_buffs and (math.fmod(MaxDps:CheckTrinketCooldownDuration('13') , cooldown[classtable.SummonInfernal].duration) == 0 or math.fmod(cooldown[classtable.SummonInfernal].duration , MaxDps:CheckTrinketCooldownDuration('13')) == 0) then
        trinket_1_sync = 1
    else
        trinket_1_sync = 0.5
    end
    if trinket_2_buffs and (math.fmod(MaxDps:CheckTrinketCooldownDuration('14') , cooldown[classtable.SummonInfernal].duration) == 0 or math.fmod(cooldown[classtable.SummonInfernal].duration , MaxDps:CheckTrinketCooldownDuration('14')) == 0) then
        trinket_2_sync = 1
    else
        trinket_2_sync = 0.5
    end
    trinket_1_manual = MaxDps:CheckTrinketNames('SpymastersWeb')
    trinket_2_manual = MaxDps:CheckTrinketNames('SpymastersWeb')
    trinket_1_exclude = MaxDps:CheckTrinketNames('WhisperingIncarnateIcon')
    trinket_2_exclude = MaxDps:CheckTrinketNames('WhisperingIncarnateIcon')
    trinket_1_buff_duration = 1
    trinket_2_buff_duration = 1
    if not trinket_1_buffs and trinket_2_buffs or trinket_2_buffs and ((MaxDps:CheckTrinketCooldownDuration('14')%trinket_2_buff_duration)*(1 + 0.5*(MaxDps:HasBuffEffect('14', 'intellect') and 1 or 0))*(trinket_2_sync))>((MaxDps:CheckTrinketCooldownDuration('13')%trinket_1_buff_duration)*(1 + 0.5*(MaxDps:HasBuffEffect('13', 'intellect') and 1 or 0))*(trinket_1_sync)) then
        trinket_priority = 2
    else
        trinket_priority = true
    end
    allow_rof_2t_spender = 2
    do_rof_2t = allow_rof_2t_spender >1.99 and not (talents[classtable.Cataclysm] and talents[classtable.ImprovedChaosBolt])
    disable_cb_2t = do_rof_2t or allow_rof_2t_spender >0.01 and allow_rof_2t_spender <0.99
    if (MaxDps:CheckSpellUsable(classtable.GrimoireofSacrifice, 'GrimoireofSacrifice') and talents[classtable.GrimoireofSacrifice]) and ((talents[classtable.GrimoireofSacrifice] and true or false)) and cooldown[classtable.GrimoireofSacrifice].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.GrimoireofSacrifice end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cataclysm, 'Cataclysm') and talents[classtable.Cataclysm]) and (targets >= 2) and cooldown[classtable.Cataclysm].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Cataclysm end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire') and talents[classtable.SoulFire]) and cooldown[classtable.SoulFire].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Incinerate end
    end
end
function Destruction:aoe()
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence') and talents[classtable.Malevolence]) and (cooldown[classtable.SummonInfernal].remains >= 55 and SoulShards <4.7 and (targets <= 3+MaxDps:DebuffCounter(classtable.WitherDeBuff) or timeInCombat >30)) and cooldown[classtable.Malevolence].ready then
        MaxDps:GlowCooldown(classtable.Malevolence, cooldown[classtable.Malevolence].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire') and talents[classtable.RainofFire]) and (demonic_art()) and cooldown[classtable.RainofFire].ready then
        if not setSpell then setSpell = classtable.RainofFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and ((diabolic_ritual() and (buff[classtable.DiabolicRitualMotherofChaosBuff].remains + buff[classtable.DiabolicRitualOverlordBuff].remains+buff[classtable.DiabolicRitualPitLordBuff].remains)<=( classtable and classtable.Incinerate and GetSpellInfo(classtable.Incinerate).castTime / 1000 or 0) and (buff[classtable.DiabolicRitualMotherofChaosBuff].remains + buff[classtable.DiabolicRitualOverlordBuff].remains+buff[classtable.DiabolicRitualPitLordBuff].remains)>gcd * 0.25)) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (havoc_active and havoc_remains >gcd and targets<(5 + (talents[classtable.Wither] and 0 or 1)) and (not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal])) then
        Destruction:havoc()
    end
    if (MaxDps:CheckSpellUsable(classtable.DimensionalRift, 'DimensionalRift')) and (SoulShards <4.7 and (cooldown[classtable.DimensionalRift].charges >2 or MaxDps:boss() and ttd <cooldown[classtable.DimensionalRift].duration)) and cooldown[classtable.DimensionalRift].ready then
        if not setSpell then setSpell = classtable.DimensionalRift end
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire') and talents[classtable.RainofFire]) and (not talents[classtable.Inferno] and SoulShards>=(4.5 - 0.1*(MaxDps:DebuffCounter(classtable.ImmolateDeBuff) + MaxDps:DebuffCounter(classtable.WitherDeBuff))) or SoulShards>=(3.5 - 0.1*(MaxDps:DebuffCounter(classtable.ImmolateDeBuff) + MaxDps:DebuffCounter(classtable.WitherDeBuff))) or buff[classtable.RitualofRuinBuff].up) and cooldown[classtable.RainofFire].ready then
        if not setSpell then setSpell = classtable.RainofFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither') and talents[classtable.Wither]) and (debuff[classtable.WitherDeBuff].refreshable and (not (talents[classtable.Cataclysm] and true or false) or cooldown[classtable.Cataclysm].remains >debuff[classtable.WitherDeBuff].remains) and (not talents[classtable.RagingDemonfire] or cooldown[classtable.ChannelDemonfire].remains >debuff[classtable.WitherDeBuff].remains or timeInCombat <5) and (MaxDps:DebuffCounter(classtable.WitherDeBuff) <= 4 or timeInCombat >15) and ttd >18) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (debuff[classtable.ImmolateDeBuff].remains + debuff[classtable.WitherDeBuff].remains>( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 or 0) and talents[classtable.RagingDemonfire]) and cooldown[classtable.ChannelDemonfire].ready then
        if not setSpell then setSpell = classtable.ChannelDemonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn') and talents[classtable.Shadowburn]) and (((buff[classtable.MalevolenceBuff].up and ((talents[classtable.Cataclysm] and targets <= 10) or (talents[classtable.Inferno] and targets <= 6))) or (talents[classtable.Wither] and talents[classtable.Cataclysm] and targets <= 6) or (not talents[classtable.Wither] and talents[classtable.Cataclysm] and targets <= 4) or targets <= 3) and ((cooldown[classtable.Shadowburn].fullRecharge <= gcd*3 or debuff[classtable.EradicationDeBuff].remains <= gcd and talents[classtable.Eradication] and not (MaxDps.spellHistory[1] == classtable.ChaosBolt) and not talents[classtable.DiabolicRitual]) and (talents[classtable.ConflagrationofChaos] or talents[classtable.BlisteringAtrophy]) or ttd <= 8)) and cooldown[classtable.Shadowburn].ready then
        if not setSpell then setSpell = classtable.Shadowburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn') and talents[classtable.Shadowburn]) and (((buff[classtable.MalevolenceBuff].up and ((talents[classtable.Cataclysm] and targets <= 10) or (talents[classtable.Inferno] and targets <= 6))) or (talents[classtable.Wither] and talents[classtable.Cataclysm] and targets <= 6) or (not talents[classtable.Wither] and talents[classtable.Cataclysm] and targets <= 4) or targets <= 3) and ((cooldown[classtable.Shadowburn].fullRecharge <= gcd*3 or debuff[classtable.EradicationDeBuff].remains <= gcd and talents[classtable.Eradication] and not (MaxDps.spellHistory[1] == classtable.ChaosBolt) and not talents[classtable.DiabolicRitual]) and (talents[classtable.ConflagrationofChaos] or talents[classtable.BlisteringAtrophy]) and ttd <5 or MaxDps:boss() and ttd <= 8)) and cooldown[classtable.Shadowburn].ready then
        if not setSpell then setSpell = classtable.Shadowburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire') and talents[classtable.RainofFire]) and (( UnitExists('pet') and UnitName('pet')  == 'Infernal' ) and talents[classtable.RainofChaos]) and cooldown[classtable.RainofFire].ready then
        if not setSpell then setSpell = classtable.RainofFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire') and talents[classtable.SoulFire]) and ((buff[classtable.DecimationBuff].up) and not talents[classtable.RagingDemonfire] and havoc_active) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire') and talents[classtable.SoulFire]) and (buff[classtable.DecimationBuff].up and MaxDps:DebuffCounter(classtable.ImmolateDeBuff) <= 4) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and (SoulShards <2.5) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and ((SoulShards >3.5-(0.1 * targets) and not talents[classtable.RainofFire]) or (not talents[classtable.Wither] and talents[classtable.Cataclysm] and targets <= 3)) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cataclysm, 'Cataclysm') and talents[classtable.Cataclysm]) and (math.huge >15 or talents[classtable.Wither]) and cooldown[classtable.Cataclysm].ready then
        if not setSpell then setSpell = classtable.Cataclysm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Havoc, 'Havoc')) and ((not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal] or (talents[classtable.Inferno] and targets >4)) and ttd >8 and (cooldown[classtable.Malevolence].remains >15 or not talents[classtable.Malevolence]) or timeInCombat <5) and cooldown[classtable.Havoc].ready then
        if not setSpell then setSpell = classtable.Havoc end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither') and talents[classtable.Wither]) and (debuff[classtable.WitherDeBuff].refreshable and (not (talents[classtable.Cataclysm] and true or false) or cooldown[classtable.Cataclysm].remains >debuff[classtable.WitherDeBuff].remains) and (not talents[classtable.RagingDemonfire] or cooldown[classtable.ChannelDemonfire].remains >debuff[classtable.WitherDeBuff].remains or timeInCombat <5) and MaxDps:DebuffCounter(classtable.WitherDeBuff) <= 1 and ttd >18) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (debuff[classtable.ImmolateDeBuff].refreshable and (not (talents[classtable.Cataclysm] and true or false) or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains) and (not talents[classtable.RagingDemonfire] or cooldown[classtable.ChannelDemonfire].remains >debuff[classtable.ImmolateDeBuff].remains or timeInCombat <5) and (MaxDps:DebuffCounter(classtable.ImmolateDeBuff) <= 6 and not (talents[classtable.DiabolicRitual] and talents[classtable.Inferno]) or MaxDps:DebuffCounter(classtable.ImmolateDeBuff) <= 4) and ttd >18) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    Destruction:ogcd()
    if (MaxDps:CheckSpellUsable(classtable.SummonInfernal, 'SummonInfernal') and talents[classtable.SummonInfernal]) and cooldown[classtable.SummonInfernal].ready then
        MaxDps:GlowCooldown(classtable.SummonInfernal, cooldown[classtable.SummonInfernal].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire') and talents[classtable.RainofFire]) and (not debuff[classtable.PyrogenicsDeBuff].up and targets <= 4 and not talents[classtable.DiabolicRitual]) and cooldown[classtable.RainofFire].ready then
        if not setSpell then setSpell = classtable.RainofFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (debuff[classtable.ImmolateDeBuff].remains + debuff[classtable.WitherDeBuff].remains>( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 or 0)) and cooldown[classtable.ChannelDemonfire].ready then
        if not setSpell then setSpell = classtable.ChannelDemonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (debuff[classtable.ImmolateDeBuff].refreshable and ((((not (talents[classtable.Cataclysm] and true or false) or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains)) or 1 >MaxDps:DebuffCounter(classtable.ImmolateDeBuff)) and ttd >10 and not havoc_active and not (talents[classtable.DiabolicRitual] and talents[classtable.Inferno]))) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (debuff[classtable.ImmolateDeBuff].refreshable and ((havoc_immo_time <5.4 or (debuff[classtable.ImmolateDeBuff].remains <2 and debuff[classtable.ImmolateDeBuff].remains <havoc_remains) or not debuff[classtable.ImmolateDeBuff].up or (havoc_immo_time <2)*havoc_active) and (not (talents[classtable.Cataclysm] and true or false) or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains) and ttd >11 and not (talents[classtable.DiabolicRitual] and talents[classtable.Inferno]))) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.DimensionalRift, 'DimensionalRift')) and cooldown[classtable.DimensionalRift].ready then
        if not setSpell then setSpell = classtable.DimensionalRift end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire') and talents[classtable.SoulFire]) and (buff[classtable.DecimationBuff].up) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and ((talents[classtable.FireandBrimstone] and true or false) and buff[classtable.BackdraftBuff].up) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (buff[classtable.BackdraftBuff].count <2 or not talents[classtable.Backdraft]) and cooldown[classtable.Conflagrate].ready then
        if not setSpell then setSpell = classtable.Conflagrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
end
function Destruction:cleave()
    if (havoc_active and havoc_remains >gcd) then
        Destruction:havoc()
    end
    pool_soul_shards = cooldown[classtable.Havoc].remains <= 5 or talents[classtable.Mayhem]
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence') and talents[classtable.Malevolence]) and ((not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal])) and cooldown[classtable.Malevolence].ready then
        MaxDps:GlowCooldown(classtable.Malevolence, cooldown[classtable.Malevolence].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Havoc, 'Havoc')) and ((not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal]) and ttd >8) and cooldown[classtable.Havoc].ready then
        if not setSpell then setSpell = classtable.Havoc end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (demonic_art()) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire') and talents[classtable.SoulFire]) and (buff[classtable.DecimationBuff].up and (SoulShards <= 4 or buff[classtable.DecimationBuff].remains <= gcd*2) and debuff[classtable.ConflagrateDeBuff].remains >= timeShift and not cooldown[classtable.Havoc].ready) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither') and talents[classtable.Wither]) and (talents[classtable.InternalCombustion] and (((debuff[classtable.WitherDeBuff].remains - 5*(cooldown[classtable.ChaosBolt].duration - cooldown[classtable.ChaosBolt].remains <1 and 1 or 0))<debuff[classtable.WitherDeBuff].duration * 0.4) or debuff[classtable.WitherDeBuff].remains <3 or (debuff[classtable.WitherDeBuff].remains - 2)<5 and cooldown[classtable.ChaosBolt].ready) and (not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 or 0)>(debuff[classtable.WitherDeBuff].remains - 5)) and ttd >8 and not (cooldown[classtable.SoulFire].duration - cooldown[classtable.SoulFire].remains <1)) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither') and talents[classtable.Wither]) and (not talents[classtable.InternalCombustion] and (((debuff[classtable.WitherDeBuff].remains - 5*(cooldown[classtable.ChaosBolt].duration - cooldown[classtable.ChaosBolt].remains <1 and 1 or 0))<debuff[classtable.WitherDeBuff].duration * 0.3) or debuff[classtable.WitherDeBuff].remains <3) and (not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 or 0)>(debuff[classtable.WitherDeBuff].remains)) and ttd >8 and not (cooldown[classtable.SoulFire].duration - cooldown[classtable.SoulFire].remains <1)) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (((talents[classtable.RoaringBlaze] and true or false) and cooldown[classtable.Conflagrate].fullRecharge <= gcd*2) or cooldown[classtable.Conflagrate].partialRecharge <= 8 and (diabolic_ritual() and (buff[classtable.DiabolicRitualMotherofChaosBuff].remains + buff[classtable.DiabolicRitualOverlordBuff].remains+buff[classtable.DiabolicRitualPitLordBuff].remains)<gcd) and not pool_soul_shards) and cooldown[classtable.Conflagrate].ready then
        if not setSpell then setSpell = classtable.Conflagrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn') and talents[classtable.Shadowburn]) and ((cooldown[classtable.Shadowburn].fullRecharge <= gcd*3 or debuff[classtable.EradicationDeBuff].remains <= gcd and talents[classtable.Eradication] and not (MaxDps.spellHistory[1] == classtable.ChaosBolt) and not talents[classtable.DiabolicRitual]) and (talents[classtable.ConflagrationofChaos] or talents[classtable.BlisteringAtrophy]) or MaxDps:boss() and ttd <= 8) and cooldown[classtable.Shadowburn].ready then
        if not setSpell then setSpell = classtable.Shadowburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (buff[classtable.RitualofRuinBuff].up) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire') and talents[classtable.RainofFire]) and (cooldown[classtable.SummonInfernal].remains >= 90 and talents[classtable.RainofChaos]) and cooldown[classtable.RainofFire].ready then
        if not setSpell then setSpell = classtable.RainofFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn') and talents[classtable.Shadowburn]) and (cooldown[classtable.SummonInfernal].remains >= 90 and talents[classtable.RainofChaos]) and cooldown[classtable.Shadowburn].ready then
        if not setSpell then setSpell = classtable.Shadowburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (cooldown[classtable.SummonInfernal].remains >= 90 and talents[classtable.RainofChaos]) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and ((debuff[classtable.EradicationDeBuff].remains >= timeShift or not talents[classtable.Eradication] or not talents[classtable.Shadowburn])) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cataclysm, 'Cataclysm') and talents[classtable.Cataclysm]) and (math.huge >15) and cooldown[classtable.Cataclysm].ready then
        if not setSpell then setSpell = classtable.Cataclysm end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (talents[classtable.RagingDemonfire] and (debuff[classtable.ImmolateDeBuff].remains + debuff[classtable.WitherDeBuff].remains-5*(((MaxDps.spellHistory[1] == classtable.ChaosBolt) and talents[classtable.InternalCombustion]) and 1 or 0))>( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 or 0)) and cooldown[classtable.ChannelDemonfire].ready then
        if not setSpell then setSpell = classtable.ChannelDemonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire') and talents[classtable.SoulFire]) and (SoulShards <= 3.5 and (debuff[classtable.ConflagrateDeBuff].remains >( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime /1000 or 0)+1 or not talents[classtable.RoaringBlaze] and buff[classtable.BackdraftBuff].up) and not pool_soul_shards) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and ((debuff[classtable.ImmolateDeBuff].refreshable and (debuff[classtable.ImmolateDeBuff].remains <cooldown[classtable.Havoc].remains or not debuff[classtable.ImmolateDeBuff].up)) and (not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains) and (not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains+((talents[classtable.Mayhem] and 0 or 1) * ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 or 0))>debuff[classtable.ImmolateDeBuff].remains) and ttd >15) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonInfernal, 'SummonInfernal') and talents[classtable.SummonInfernal]) and cooldown[classtable.SummonInfernal].ready then
        MaxDps:GlowCooldown(classtable.SummonInfernal, cooldown[classtable.SummonInfernal].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and (talents[classtable.DiabolicRitual] and (diabolic_ritual() and (buff[classtable.DiabolicRitualMotherofChaosBuff].remains + buff[classtable.DiabolicRitualOverlordBuff].remains+buff[classtable.DiabolicRitualPitLordBuff].remains - 2-(disable_cb_2t and 0 or 1) * ( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime / 1000 or 0)-disable_cb_2t * gcd)<=0)) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire') and talents[classtable.RainofFire]) and (pooling_condition and not talents[classtable.Wither] and buff[classtable.RainofChaosBuff].up) and cooldown[classtable.RainofFire].ready then
        if not setSpell then setSpell = classtable.RainofFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire') and talents[classtable.RainofFire]) and (allow_rof_2t_spender >= 1 and not talents[classtable.Wither] and talents[classtable.Pyrogenics] and debuff[classtable.PyrogenicsDeBuff].remains <= gcd and (not talents[classtable.RainofChaos] or cooldown[classtable.SummonInfernal].remains >= gcd*3) and pooling_condition) and cooldown[classtable.RainofFire].ready then
        if not setSpell then setSpell = classtable.RainofFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire') and talents[classtable.RainofFire]) and (do_rof_2t and pooling_condition and (cooldown[classtable.SummonInfernal].remains >= gcd*3 or not talents[classtable.RainofChaos])) and cooldown[classtable.RainofFire].ready then
        if not setSpell then setSpell = classtable.RainofFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire') and talents[classtable.SoulFire]) and (SoulShards <= 4 and talents[classtable.Mayhem]) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (not disable_cb_2t and pooling_condition_cb and (cooldown[classtable.SummonInfernal].remains >= gcd*3 or SoulShards >4 or not talents[classtable.RainofChaos])) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (debuff[classtable.ImmolateDeBuff].remains + debuff[classtable.WitherDeBuff].remains>( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 or 0)) and cooldown[classtable.ChannelDemonfire].ready then
        if not setSpell then setSpell = classtable.ChannelDemonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.DimensionalRift, 'DimensionalRift')) and cooldown[classtable.DimensionalRift].ready then
        if not setSpell then setSpell = classtable.DimensionalRift end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (cooldown[classtable.Conflagrate].fullRecharge <2*gcd or MaxDps:boss() and ttd <gcd*cooldown[classtable.Conflagrate].charges) and cooldown[classtable.Conflagrate].ready then
        if not setSpell then setSpell = classtable.Conflagrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
end
function Destruction:havoc()
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (talents[classtable.Backdraft] and not buff[classtable.BackdraftBuff].up and SoulShards >= 1 and SoulShards <= 4) and cooldown[classtable.Conflagrate].ready then
        if not setSpell then setSpell = classtable.Conflagrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire') and talents[classtable.SoulFire]) and (( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime /1000 or 0) <havoc_remains and SoulShards <2.5) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cataclysm, 'Cataclysm') and talents[classtable.Cataclysm]) and (math.huge >15 or (talents[classtable.Wither] and debuff[classtable.WitherDeBuff].remains <( classtable and classtable.Wither and GetSpellInfo(classtable.Wither).castTime / 1000 or 0)*0.3)) and cooldown[classtable.Cataclysm].ready then
        if not setSpell then setSpell = classtable.Cataclysm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and ((((debuff[classtable.ImmolateDeBuff].refreshable and havoc_immo_time <5.4) and ttd >5) or ((debuff[classtable.ImmolateDeBuff].remains <2 and debuff[classtable.ImmolateDeBuff].remains <havoc_remains) or not debuff[classtable.ImmolateDeBuff].up or havoc_immo_time <2) and ttd >11) and SoulShards <4.5) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither') and talents[classtable.Wither]) and ((((debuff[classtable.WitherDeBuff].refreshable and havoc_immo_time <5.4) and ttd >5) or ((debuff[classtable.WitherDeBuff].remains <2 and debuff[classtable.WitherDeBuff].remains <havoc_remains) or not debuff[classtable.WitherDeBuff].up or havoc_immo_time <2) and ttd >11) and SoulShards <4.5) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn') and talents[classtable.Shadowburn]) and (targets <= 4 and (cooldown[classtable.Shadowburn].fullRecharge <= gcd*3 or debuff[classtable.EradicationDeBuff].remains <= gcd and talents[classtable.Eradication] and not (MaxDps.spellHistory[1] == classtable.ChaosBolt) and not talents[classtable.DiabolicRitual]) and (talents[classtable.ConflagrationofChaos] or talents[classtable.BlisteringAtrophy])) and cooldown[classtable.Shadowburn].ready then
        if not setSpell then setSpell = classtable.Shadowburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn') and talents[classtable.Shadowburn]) and (targets <= 4 and havoc_remains <= gcd*3) and cooldown[classtable.Shadowburn].ready then
        if not setSpell then setSpell = classtable.Shadowburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime /1000 or 0) <havoc_remains and ((not talents[classtable.ImprovedChaosBolt] and targets <= 2) or (talents[classtable.ImprovedChaosBolt] and ((talents[classtable.Wither] and talents[classtable.Inferno] and targets <= 2) or (talents[classtable.Wither] and talents[classtable.Cataclysm] and targets <= 4) or (not talents[classtable.Wither] and talents[classtable.Inferno] and targets <= 3) or (not talents[classtable.Wither] and talents[classtable.Cataclysm] and targets <= 5))))) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire') and talents[classtable.RainofFire]) and (targets >= 3) and cooldown[classtable.RainofFire].ready then
        if not setSpell then setSpell = classtable.RainofFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (debuff[classtable.ImmolateDeBuff].remains + debuff[classtable.WitherDeBuff].remains>( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 or 0) and SoulShards <4.5) and cooldown[classtable.ChannelDemonfire].ready then
        if not setSpell then setSpell = classtable.ChannelDemonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (not talents[classtable.Backdraft]) and cooldown[classtable.Conflagrate].ready then
        if not setSpell then setSpell = classtable.Conflagrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.DimensionalRift, 'DimensionalRift')) and (SoulShards <4.7 and (cooldown[classtable.DimensionalRift].charges >2 or MaxDps:boss() and ttd <cooldown[classtable.DimensionalRift].duration)) and cooldown[classtable.DimensionalRift].ready then
        if not setSpell then setSpell = classtable.DimensionalRift end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and (( classtable and classtable.Incinerate and GetSpellInfo(classtable.Incinerate).castTime /1000 or 0) <havoc_remains) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
end
function Destruction:items()
    if (MaxDps:CheckSpellUsable(classtable.spymasters_web, 'spymasters_web')) and (GetTotemInfoById(classtable.Infernal).remains >= 10 and GetTotemInfoById(classtable.Infernal).remains <= 20 and buff[classtable.SpymastersReportBuff].count >= 38 and (ttd >240 or ttd <= 140) or MaxDps:boss() and ttd <= 30) and cooldown[classtable.spymasters_web].ready then
        MaxDps:GlowCooldown(classtable.spymasters_web, cooldown[classtable.spymasters_web].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and ((infernal_active or not talents[classtable.SummonInfernal] or trinket_1_will_lose_cast) and (trinket_priority == 1 or trinket_2_exclude or not MaxDps:HasOnUseEffect('14') or (MaxDps:CheckTrinketCooldown('14') or trinket_priority == 2 and cooldown[classtable.SummonInfernal].remains >20 and not infernal_active and MaxDps:CheckTrinketCooldown('14') <cooldown[classtable.SummonInfernal].remains)) and trinket_1_buffs and not trinket_1_manual or (trinket_1_buff_duration + 1>=ttd)) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and ((infernal_active or not talents[classtable.SummonInfernal] or trinket_2_will_lose_cast) and (trinket_priority == 2 or trinket_1_exclude or not MaxDps:HasOnUseEffect('13') or (MaxDps:CheckTrinketCooldown('13') or trinket_priority == 1 and cooldown[classtable.SummonInfernal].remains >20 and not infernal_active and MaxDps:CheckTrinketCooldown('13') <cooldown[classtable.SummonInfernal].remains)) and trinket_2_buffs and not trinket_2_manual or (trinket_2_buff_duration + 1>=ttd)) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not trinket_1_buffs and not trinket_1_manual and (not trinket_1_buffs and (MaxDps:CheckTrinketCooldown('14') or not trinket_2_buffs) or talents[classtable.SummonInfernal] and cooldown[classtable.SummonInfernal].remains >20 and not (MaxDps.spellHistory[1] == classtable.SummonInfernal) or not talents[classtable.SummonInfernal])) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not trinket_2_buffs and not trinket_2_manual and (not trinket_2_buffs and (MaxDps:CheckTrinketCooldown('13') or not trinket_1_buffs) or talents[classtable.SummonInfernal] and cooldown[classtable.SummonInfernal].remains >20 and not (MaxDps.spellHistory[1] == classtable.SummonInfernal) or not talents[classtable.SummonInfernal])) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.main_hand, 'main_hand')) and cooldown[classtable.main_hand].ready then
        if not setSpell then setSpell = classtable.main_hand end
    end
end
function Destruction:ogcd()
end
function Destruction:variables()
    if havoc_active then
        havoc_immo_time = math.min(debuff[classtable.ImmolateDeBuff].remains , debuff[classtable.WitherDeBuff].remains)
    end
    pooling_condition = (SoulShards >= 3 or (talents[classtable.SecretsoftheCoven] and buff[classtable.InfernalBoltBuff].up or buff[classtable.DecimationBuff].up) and SoulShards >= 3)
    pooling_condition_cb = pooling_condition or ( UnitExists('pet') and UnitName('pet')  == 'Infernal' ) and SoulShards >= 3
    infernal_active = ( UnitExists('pet') and UnitName('pet')  == 'Infernal' ) or (cooldown[classtable.SummonInfernal].duration - cooldown[classtable.SummonInfernal].remains)<20
    trinket_1_will_lose_cast = ((floor((ttd%MaxDps:CheckTrinketCooldownDuration('13'))+1)~= floor((ttd+(cooldown[classtable.SummonInfernal].duration - cooldown[classtable.SummonInfernal].remains))%cooldown[classtable.SummonInfernal].duration)) and (floor((ttd%MaxDps:CheckTrinketCooldownDuration('13'))+1))~=(floor(((ttd - cooldown[classtable.SummonInfernal].remains)%MaxDps:CheckTrinketCooldownDuration('13'))+1)) or ((floor((ttd%MaxDps:CheckTrinketCooldownDuration('13'))+1) == floor((ttd+(cooldown[classtable.SummonInfernal].duration - cooldown[classtable.SummonInfernal].remains))%cooldown[classtable.SummonInfernal].duration)) and (((ttd - math.fmod(cooldown[classtable.SummonInfernal].remains , MaxDps:CheckTrinketCooldownDuration('13')))-cooldown[classtable.SummonInfernal].remains - trinket_1_buff_duration)>0))) and cooldown[classtable.SummonInfernal].remains >20
    trinket_2_will_lose_cast = ((floor((ttd%MaxDps:CheckTrinketCooldownDuration('14'))+1)~= floor((ttd+(cooldown[classtable.SummonInfernal].duration - cooldown[classtable.SummonInfernal].remains))%cooldown[classtable.SummonInfernal].duration)) and (floor((ttd%MaxDps:CheckTrinketCooldownDuration('14'))+1))~=(floor(((ttd - cooldown[classtable.SummonInfernal].remains)%MaxDps:CheckTrinketCooldownDuration('14'))+1)) or ((floor((ttd%MaxDps:CheckTrinketCooldownDuration('14'))+1) == floor((ttd+(cooldown[classtable.SummonInfernal].duration - cooldown[classtable.SummonInfernal].remains))%cooldown[classtable.SummonInfernal].duration)) and (((ttd - math.fmod(cooldown[classtable.SummonInfernal].remains , MaxDps:CheckTrinketCooldownDuration('14')))-cooldown[classtable.SummonInfernal].remains - trinket_2_buff_duration)>0))) and cooldown[classtable.SummonInfernal].remains >20
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.SpellLock, false)
    MaxDps:GlowCooldown(classtable.Malevolence, false)
    MaxDps:GlowCooldown(classtable.SummonInfernal, false)
    MaxDps:GlowCooldown(classtable.spymasters_web, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
end

function Destruction:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SpellLock, 'SpellLock')) and cooldown[classtable.SpellLock].ready then
        MaxDps:GlowCooldown(classtable.SpellLock, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    Destruction:variables()
    Destruction:ogcd()
    Destruction:items()
    if ((targets >= 3) and not cleave_apl) then
        Destruction:aoe()
    end
    if (targets >1) then
        Destruction:cleave()
    end
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence') and talents[classtable.Malevolence]) and (cooldown[classtable.SummonInfernal].remains >= 55) and cooldown[classtable.Malevolence].ready then
        MaxDps:GlowCooldown(classtable.Malevolence, cooldown[classtable.Malevolence].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (demonic_art()) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire') and talents[classtable.SoulFire]) and (buff[classtable.DecimationBuff].up and (SoulShards <= 4 or buff[classtable.DecimationBuff].remains <= gcd*2) and debuff[classtable.ConflagrateDeBuff].remains >= timeShift) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither') and talents[classtable.Wither]) and (talents[classtable.InternalCombustion] and (((debuff[classtable.WitherDeBuff].remains - 5*(cooldown[classtable.ChaosBolt].duration - cooldown[classtable.ChaosBolt].remains <1 and 1 or 0))<debuff[classtable.WitherDeBuff].duration * 0.4) or debuff[classtable.WitherDeBuff].remains <3 or (debuff[classtable.WitherDeBuff].remains - 2)<5 and cooldown[classtable.ChaosBolt].ready) and (not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 or 0)>(debuff[classtable.WitherDeBuff].remains - 5)) and ttd >8 and not (cooldown[classtable.SoulFire].duration - cooldown[classtable.SoulFire].remains <1)) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (talents[classtable.RoaringBlaze] and debuff[classtable.ConflagrateDeBuff].remains <1.5 or cooldown[classtable.Conflagrate].fullRecharge <= gcd*2 or cooldown[classtable.Conflagrate].partialRecharge <= 8 and (diabolic_ritual() and (buff[classtable.DiabolicRitualMotherofChaosBuff].remains + buff[classtable.DiabolicRitualOverlordBuff].remains+buff[classtable.DiabolicRitualPitLordBuff].remains)<gcd) and SoulShards >= 1.5) and cooldown[classtable.Conflagrate].ready then
        if not setSpell then setSpell = classtable.Conflagrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn') and talents[classtable.Shadowburn]) and ((cooldown[classtable.Shadowburn].fullRecharge <= gcd*3 or debuff[classtable.EradicationDeBuff].remains <= gcd and talents[classtable.Eradication] and not (MaxDps.spellHistory[1] == classtable.ChaosBolt) and not talents[classtable.DiabolicRitual]) and (talents[classtable.ConflagrationofChaos] or talents[classtable.BlisteringAtrophy]) and not demonic_art() or MaxDps:boss() and ttd <= 8) and cooldown[classtable.Shadowburn].ready then
        if not setSpell then setSpell = classtable.Shadowburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (buff[classtable.RitualofRuinBuff].up) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn') and talents[classtable.Shadowburn]) and ((cooldown[classtable.SummonInfernal].remains >= 90 and talents[classtable.RainofChaos]) or buff[classtable.MalevolenceBuff].up) and cooldown[classtable.Shadowburn].ready then
        if not setSpell then setSpell = classtable.Shadowburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and ((cooldown[classtable.SummonInfernal].remains >= 90 and talents[classtable.RainofChaos]) or buff[classtable.MalevolenceBuff].up) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and ((debuff[classtable.EradicationDeBuff].remains >= timeShift or not talents[classtable.Eradication] or not talents[classtable.Shadowburn])) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cataclysm, 'Cataclysm') and talents[classtable.Cataclysm]) and (math.huge >15 and (debuff[classtable.ImmolateDeBuff].refreshable and not talents[classtable.Wither] or talents[classtable.Wither] and debuff[classtable.WitherDeBuff].refreshable)) and cooldown[classtable.Cataclysm].ready then
        if not setSpell then setSpell = classtable.Cataclysm end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (talents[classtable.RagingDemonfire] and (debuff[classtable.ImmolateDeBuff].remains + debuff[classtable.WitherDeBuff].remains-5*(((MaxDps.spellHistory[1] == classtable.ChaosBolt) and talents[classtable.InternalCombustion]) and 1 or 0))>( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 or 0)) and cooldown[classtable.ChannelDemonfire].ready then
        if not setSpell then setSpell = classtable.ChannelDemonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither') and talents[classtable.Wither]) and (not talents[classtable.InternalCombustion] and (((debuff[classtable.WitherDeBuff].remains - 5*(cooldown[classtable.ChaosBolt].duration - cooldown[classtable.ChaosBolt].remains <1 and 1 or 0))<debuff[classtable.WitherDeBuff].duration * 0.3) or debuff[classtable.WitherDeBuff].remains <3) and (not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.WitherDeBuff].remains) and (not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 or 0)>(debuff[classtable.WitherDeBuff].remains)) and ttd >8 and not (cooldown[classtable.SoulFire].duration - cooldown[classtable.SoulFire].remains <1)) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and ((((debuff[classtable.ImmolateDeBuff].remains - 5*(((MaxDps.spellHistory[1] == classtable.ChaosBolt) and talents[classtable.InternalCombustion]) and 1 or 0))<debuff[classtable.ImmolateDeBuff].duration * 0.3) or debuff[classtable.ImmolateDeBuff].remains <3 or (debuff[classtable.ImmolateDeBuff].remains - 2)<5 and talents[classtable.InternalCombustion] and cooldown[classtable.ChaosBolt].ready) and (not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains) and (not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 or 0)>(debuff[classtable.ImmolateDeBuff].remains - 5*(talents[classtable.InternalCombustion] and talents[classtable.InternalCombustion] or 0))) and ttd >8 and not (cooldown[classtable.SoulFire].duration - cooldown[classtable.SoulFire].remains <1)) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonInfernal, 'SummonInfernal') and talents[classtable.SummonInfernal]) and cooldown[classtable.SummonInfernal].ready then
        MaxDps:GlowCooldown(classtable.SummonInfernal, cooldown[classtable.SummonInfernal].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and (talents[classtable.DiabolicRitual] and (diabolic_ritual() and (buff[classtable.DiabolicRitualMotherofChaosBuff].remains + buff[classtable.DiabolicRitualOverlordBuff].remains+buff[classtable.DiabolicRitualPitLordBuff].remains - 2-(disable_cb_2t and 0 or 1) * ( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime / 1000 or 0)-disable_cb_2t * gcd)<=0)) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (pooling_condition_cb and (cooldown[classtable.SummonInfernal].remains >= gcd*3 or SoulShards >4 or not talents[classtable.RainofChaos])) and cooldown[classtable.ChaosBolt].ready then
        if not setSpell then setSpell = classtable.ChaosBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (debuff[classtable.ImmolateDeBuff].remains + debuff[classtable.WitherDeBuff].remains>( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 or 0)) and cooldown[classtable.ChannelDemonfire].ready then
        if not setSpell then setSpell = classtable.ChannelDemonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.DimensionalRift, 'DimensionalRift')) and cooldown[classtable.DimensionalRift].ready then
        if not setSpell then setSpell = classtable.DimensionalRift end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (cooldown[classtable.Conflagrate].fullRecharge <2*gcd or MaxDps:boss() and ttd <gcd*cooldown[classtable.Conflagrate].charges) and cooldown[classtable.Conflagrate].ready then
        if not setSpell then setSpell = classtable.Conflagrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire') and talents[classtable.SoulFire]) and (buff[classtable.BackdraftBuff].up) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
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
    classtable.DiabolicRitualMotherofChaosBuff = 432815
    classtable.DiabolicRitualOverlordBuff = 431944
    classtable.DiabolicRitualPitLordBuff = 432816
    classtable.DecimationBuff = 457555
    classtable.RitualofRuinBuff = 387157
    classtable.MalevolenceBuff = 442726
    classtable.BackdraftBuff = 117828
    classtable.RainofChaosBuff = 266087
    classtable.SpymastersReportBuff = 451199
    classtable.InfernalBoltBuff = 433891
    classtable.ConflagrateDeBuff = 265931
    classtable.WitherDeBuff = 445474
    classtable.EradicationDeBuff = 196414
    classtable.ImmolateDeBuff = 157736
    classtable.PyrogenicsDeBuff = 387096
    classtable.HavocDeBuff = 80240
    classtable.InfernalBolt = 434506
    classtable.SpellLock = 19647

    local function debugg()
        talents[classtable.GrimoireofSacrifice] = 1
        talents[classtable.InternalCombustion] = 1
        talents[classtable.SoulFire] = 1
        talents[classtable.RoaringBlaze] = 1
        talents[classtable.Eradication] = 1
        talents[classtable.DiabolicRitual] = 1
        talents[classtable.ConflagrationofChaos] = 1
        talents[classtable.BlisteringAtrophy] = 1
        talents[classtable.RainofChaos] = 1
        talents[classtable.Shadowburn] = 1
        talents[classtable.Wither] = 1
        talents[classtable.RagingDemonfire] = 1
        talents[classtable.Cataclysm] = 1
        talents[classtable.SummonInfernal] = 1
        talents[classtable.Inferno] = 1
        talents[classtable.RainofFire] = 1
        talents[classtable.Malevolence] = 1
        talents[classtable.FireandBrimstone] = 1
        talents[classtable.Backdraft] = 1
        talents[classtable.Pyrogenics] = 1
        talents[classtable.Mayhem] = 1
        talents[classtable.ImprovedChaosBolt] = 1
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
