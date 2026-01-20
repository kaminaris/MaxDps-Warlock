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

local Demonology = {}

local first_tyrant_time = 0
local in_opener = false
local trinket_1_buffs = false
local trinket_2_buffs = false
local trinket_1_exclude = false
local trinket_2_exclude = false
local trinket_1_manual = false
local trinket_2_manual = false
local trinket_1_buff_duration = 0
local trinket_2_buff_duration = 0
local trinket_1_sync = false
local trinket_2_sync = false
local damage_trinket_priority = false
local trinket_priority = false
local check_racials = false
local next_tyrant_cd = 0
local impl = true
local pool_cores_for_tyrant = false
local diabolic_ritual_remains = 0
local imp_despawn = 0


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




--local function imp_despawn()
--    if buff[classtable.TyrantBuff].up then return 0 end
--    local val = 0
--    local TTSHoD = (GetTime() - (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.HandofGuldan] and MaxDps.spellHistoryTime[classtable.HandofGuldan].last_used or 0))
--    if TTSHoD < (2 * UnitSpellHaste('player') * 6 + 0.58) and buff[classtable.DreadStalkers].up and cooldown[classtable.SummonDemonicTyrant].remains < 13 then
--        val = max( 0, GetTime() - TTSHoD + 2 * UnitSpellHaste('player') * 6 + 0.58 )
--    end
--    if val > 0 then
--        val = max( val, buff[classtable.DreadStalkers].remains + GetTime() )
--    end
--    if val > 0 and buff[classtable.GrimoireFelguard].up then
--        val = max( val, buff[classtable.GrimoireFelguard].remains + GetTime() )
--    end
--    return val
--end

local function last_cast_imps()
    if MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.Implosion] then
        return GetTime() - MaxDps.spellHistoryTime[classtable.Implosion].last_used
    else
        return math.huge
    end
end


function Demonology:precombat()
    if (MaxDps:CheckSpellUsable(classtable.FelDomination, 'FelDomination')) and (timeInCombat >0 and not UnitExists('pet') and not buff[classtable.GrimoireofSacrificeBuff].up) and cooldown[classtable.FelDomination].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FelDomination end
    end
    first_tyrant_time = 12
    if (talents[classtable.GrimoireFelguard] and true or false) then
        first_tyrant_time = first_tyrant_time+2
    end
    if (talents[classtable.SummonVilefiend] and true or false) then
        first_tyrant_time = first_tyrant_time+2
    end
    if (talents[classtable.GrimoireFelguard] and true or false) or (talents[classtable.SummonVilefiend] and true or false) then
        first_tyrant_time = first_tyrant_time+gcd
    end
    first_tyrant_time = first_tyrant_time-2 + 2
    first_tyrant_time = min(10)
    in_opener = 1
    trinket_1_buffs = MaxDps:HasOnUseEffect('13')
    trinket_2_buffs = MaxDps:HasOnUseEffect('14')
    trinket_1_exclude = MaxDps:CheckTrinketNames('RubyWhelpShell')
    trinket_2_exclude = MaxDps:CheckTrinketNames('RubyWhelpShell')
    trinket_1_manual = MaxDps:CheckTrinketNames('SpymastersWeb') or MaxDps:CheckTrinketNames('ImperfectAscendancySerum')
    trinket_2_manual = MaxDps:CheckTrinketNames('SpymastersWeb') or MaxDps:CheckTrinketNames('ImperfectAscendancySerum')
    trinket_1_buff_duration = 1+((MaxDps:CheckTrinketNames('MirrorofFracturedTomorrows') and 1 or 0) * 20)
    trinket_2_buff_duration = 1+((MaxDps:CheckTrinketNames('MirrorofFracturedTomorrows') and 1 or 0) * 20)
    if trinket_1_buffs and (math.fmod(MaxDps:CheckTrinketCooldownDuration('13') , cooldown[classtable.SummonDemonicTyrant].duration) == 0 or math.fmod(cooldown[classtable.SummonDemonicTyrant].duration , MaxDps:CheckTrinketCooldownDuration('13')) == 0) then
        trinket_1_sync = 1
    else
        trinket_1_sync = 0.5
    end
    if trinket_2_buffs and (math.fmod(MaxDps:CheckTrinketCooldownDuration('14') , cooldown[classtable.SummonDemonicTyrant].duration) == 0 or math.fmod(cooldown[classtable.SummonDemonicTyrant].duration , MaxDps:CheckTrinketCooldownDuration('14')) == 0) then
        trinket_2_sync = 1
    else
        trinket_2_sync = 0.5
    end
    if not trinket_1_buffs and not trinket_2_buffs and MaxDps:CheckTrinketItemLevel('14') >MaxDps:CheckTrinketItemLevel('13') then
        damage_trinket_priority = 2
    else
        damage_trinket_priority = true
    end
    if not trinket_1_buffs and trinket_2_buffs or trinket_2_buffs and ((MaxDps:CheckTrinketCooldownDuration('14')%trinket_2_buff_duration)*(1.5 + (MaxDps:HasBuffEffect('14', 'intellect') and 1 or 0))*(trinket_2_sync))>(((MaxDps:CheckTrinketCooldownDuration('13')%trinket_1_buff_duration)*(1.5 + (MaxDps:HasBuffEffect('13', 'intellect') and 1 or 0))*(trinket_1_sync))*(1+((MaxDps:CheckTrinketItemLevel('13') - MaxDps:CheckTrinketItemLevel('14'))%100))) then
        trinket_priority = 2
    else
        trinket_priority = true
    end
    if (MaxDps:CheckSpellUsable(classtable.PowerSiphon, 'PowerSiphon')) and cooldown[classtable.PowerSiphon].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.PowerSiphon end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (not buff[classtable.PowerSiphonBuff].up or SoulShardsDeficit >1) and cooldown[classtable.Demonbolt].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end
function Demonology:fight_end()
    if (MaxDps:CheckSpellUsable(classtable.GrimoireFelguard, 'GrimoireFelguard') and talents[classtable.GrimoireFelguard]) and (ttd <20) and cooldown[classtable.GrimoireFelguard].ready then
        if not setSpell then setSpell = classtable.GrimoireFelguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
    if (MaxDps:CheckSpellUsable(classtable.Implosion, 'Implosion')) and (ttd <2*gcd and not (MaxDps.spellHistory[1] == classtable.Implosion)) and cooldown[classtable.Implosion].ready then
        if not setSpell then setSpell = classtable.Implosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (ttd <gcd*2 * buff[classtable.DemonicCoreBuff].count+9 and buff[classtable.DemonicCoreBuff].up and (SoulShards <4 or ttd <buff[classtable.DemonicCoreBuff].count*gcd)) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.CallDreadstalkers, 'CallDreadstalkers') and talents[classtable.CallDreadstalkers]) and (ttd <20) and cooldown[classtable.CallDreadstalkers].ready then
        if not setSpell then setSpell = classtable.CallDreadstalkers end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonVilefiend, 'SummonVilefiend') and talents[classtable.SummonVilefiend]) and (ttd <20) and cooldown[classtable.SummonVilefiend].ready then
        if not setSpell then setSpell = classtable.SummonVilefiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDemonicTyrant, 'SummonDemonicTyrant') and talents[classtable.SummonDemonicTyrant]) and (ttd <20) and cooldown[classtable.SummonDemonicTyrant].ready then
        MaxDps:GlowCooldown(classtable.SummonDemonicTyrant, cooldown[classtable.SummonDemonicTyrant].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DemonicStrength, 'DemonicStrength') and talents[classtable.DemonicStrength]) and (ttd <10) and cooldown[classtable.DemonicStrength].ready then
        if not setSpell then setSpell = classtable.DemonicStrength end
    end
    if (MaxDps:CheckSpellUsable(classtable.PowerSiphon, 'PowerSiphon')) and (buff[classtable.DemonicCoreBuff].count <3 and ttd <20) and cooldown[classtable.PowerSiphon].ready then
        if not setSpell then setSpell = classtable.PowerSiphon end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (ttd <gcd*2 * buff[classtable.DemonicCoreBuff].count+9 and buff[classtable.DemonicCoreBuff].up and (SoulShards <4 or ttd <buff[classtable.DemonicCoreBuff].count*gcd)) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (SoulShards >2 and ttd <gcd*2 * buff[classtable.DemonicCoreBuff].count+9) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
end
function Demonology:items()
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (trinket_1_buffs and not trinket_1_manual and (not ( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) and MaxDps:CheckTrinketCastTime('13') >0 or not (MaxDps:CheckTrinketCastTime('13') >0)) and (( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) or not talents[classtable.SummonDemonicTyrant] or trinket_priority == 2 and cooldown[classtable.SummonDemonicTyrant].remains >20 and not ( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) and MaxDps:CheckTrinketCooldown('14') <cooldown[classtable.SummonDemonicTyrant].remains+5) and (trinket_2_exclude or not MaxDps:HasOnUseEffect('14') or MaxDps:CheckTrinketCooldown('14') or trinket_priority == 1 and not trinket_2_manual) or trinket_1_buff_duration >= ttd) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (trinket_2_buffs and not trinket_2_manual and (not ( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) and MaxDps:CheckTrinketCastTime('14') >0 or not (MaxDps:CheckTrinketCastTime('14') >0)) and (( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) or not talents[classtable.SummonDemonicTyrant] or trinket_priority == 1 and cooldown[classtable.SummonDemonicTyrant].remains >20 and not ( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) and MaxDps:CheckTrinketCooldown('13') <cooldown[classtable.SummonDemonicTyrant].remains+5) and (trinket_1_exclude or not MaxDps:HasOnUseEffect('13') or MaxDps:CheckTrinketCooldown('13') or trinket_priority == 2 and not trinket_1_manual) or trinket_2_buff_duration >= ttd) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not trinket_1_buffs and not trinket_1_manual and ((damage_trinket_priority == 1 or MaxDps:CheckTrinketCooldown('14')) and (MaxDps:CheckTrinketCastTime('13') >0 and not ( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) or not (MaxDps:CheckTrinketCastTime('13') >0)) or (timeInCombat <20 and trinket_2_buffs) or cooldown[classtable.SummonDemonicTyrant].remains >20)) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not trinket_2_buffs and not trinket_2_manual and ((damage_trinket_priority == 2 or MaxDps:CheckTrinketCooldown('13')) and (MaxDps:CheckTrinketCastTime('14') >0 and not ( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) or not (MaxDps:CheckTrinketCastTime('14') >0)) or (timeInCombat <20 and trinket_1_buffs) or cooldown[classtable.SummonDemonicTyrant].remains >20)) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.spymasters_web, 'spymasters_web')) and (( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) and ttd <= 80 and buff[classtable.SpymastersReportBuff].count >= 30 and (not trinket_1_buffs and MaxDps:CheckTrinketNames('SpymastersWeb') or not trinket_2_buffs and MaxDps:CheckTrinketNames('SpymastersWeb')) or ttd <= 20 and (MaxDps:CheckTrinketCooldown('13') and MaxDps:CheckTrinketNames('SpymastersWeb') or MaxDps:CheckTrinketCooldown('14') and MaxDps:CheckTrinketNames('SpymastersWeb') or not trinket_1_buffs or not trinket_2_buffs)) and cooldown[classtable.spymasters_web].ready then
        MaxDps:GlowCooldown(classtable.spymasters_web, cooldown[classtable.spymasters_web].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.imperfect_ascendancy_serum, 'imperfect_ascendancy_serum')) and (( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) and gcd >0 or ttd <= 30) and cooldown[classtable.imperfect_ascendancy_serum].ready then
        MaxDps:GlowCooldown(classtable.imperfect_ascendancy_serum, cooldown[classtable.imperfect_ascendancy_serum].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.mirror_of_fractured_tomorrows, 'mirror_of_fractured_tomorrows')) and (MaxDps:CheckTrinketNames('MirrorofFracturedTomorrows') and trinket_priority == 2 or MaxDps:CheckTrinketNames('MirrorofFracturedTomorrows') and trinket_priority == 1) and cooldown[classtable.mirror_of_fractured_tomorrows].ready then
        MaxDps:GlowCooldown(classtable.mirror_of_fractured_tomorrows, cooldown[classtable.mirror_of_fractured_tomorrows].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not trinket_1_buffs and (damage_trinket_priority == 1 or MaxDps:CheckTrinketCooldown('14'))) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not trinket_2_buffs and (damage_trinket_priority == 2 or MaxDps:CheckTrinketCooldown('13'))) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.main_hand, 'main_hand')) and (not MaxDps:CheckEquipped('NeuralSynapseEnhancer')) and cooldown[classtable.main_hand].ready then
        if not setSpell then setSpell = classtable.main_hand end
    end
    if (MaxDps:CheckSpellUsable(classtable.neural_synapse_enhancer, 'neural_synapse_enhancer')) and ((( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) or ttd <= 15) and not trinket_1_buffs and not trinket_2_buffs) and cooldown[classtable.neural_synapse_enhancer].ready then
        MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, cooldown[classtable.neural_synapse_enhancer].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.neural_synapse_enhancer, 'neural_synapse_enhancer')) and ((( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) or ttd <= 15 or MaxDps:CheckTrinketCooldown('14') >cooldown[classtable.SummonDemonicTyrant].remains) and trinket_2_buffs) and cooldown[classtable.neural_synapse_enhancer].ready then
        MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, cooldown[classtable.neural_synapse_enhancer].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.neural_synapse_enhancer, 'neural_synapse_enhancer')) and ((( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) or ttd <= 15 or MaxDps:CheckTrinketCooldown('13') >cooldown[classtable.SummonDemonicTyrant].remains) and trinket_1_buffs) and cooldown[classtable.neural_synapse_enhancer].ready then
        MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, cooldown[classtable.neural_synapse_enhancer].ready)
    end
end
function Demonology:opener()
    if (MaxDps:CheckSpellUsable(classtable.GrimoireFelguard, 'GrimoireFelguard') and talents[classtable.GrimoireFelguard]) and (SoulShards >= 5-(talents[classtable.FelInvocation] and talents[classtable.FelInvocation] or 0)) and cooldown[classtable.GrimoireFelguard].ready then
        if not setSpell then setSpell = classtable.GrimoireFelguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonVilefiend, 'SummonVilefiend') and talents[classtable.SummonVilefiend]) and (SoulShards == 5) and cooldown[classtable.SummonVilefiend].ready then
        if not setSpell then setSpell = classtable.SummonVilefiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (SoulShards <5 and cooldown[classtable.CallDreadstalkers].ready) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.CallDreadstalkers, 'CallDreadstalkers') and talents[classtable.CallDreadstalkers]) and (SoulShards == 5) and cooldown[classtable.CallDreadstalkers].ready then
        if not setSpell then setSpell = classtable.CallDreadstalkers end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
end
function Demonology:racials()
end
function Demonology:tyrant()
    if (not check_racials and (imp_despawn and imp_despawn <timeInCombat+gcd * 2+( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) and ((MaxDps.spellHistory[1] == classtable.HandofGuldan) or (MaxDps.spellHistory[1] == classtable.Ruination)) and (imp_despawn and imp_despawn <timeInCombat+gcd + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) or SoulShards <2))) then
        Demonology:racials()
    end
    if (MaxDps:CheckSpellUsable(classtable.PowerSiphon, 'PowerSiphon')) and (cooldown[classtable.SummonDemonicTyrant].remains <15 and (timeInCombat <first_tyrant_time or cooldown[classtable.SummonDemonicTyrant].remains>(( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) + 2*gcd))) and cooldown[classtable.PowerSiphon].ready then
        if not setSpell then setSpell = classtable.PowerSiphon end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and (GetTotemInfoById(classtable.CallDreadstalkersTotem).remains >gcd+( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) and (SoulShards == 5 or imp_despawn)) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and ((buff[classtable.InfernalBoltBuff].remains >( classtable and classtable.InfernalBolt and GetSpellInfo(classtable.InfernalBolt).castTime /1000 or 0) and buff[classtable.InfernalBoltBuff].remains <2*gcd or not buff[classtable.DemonicCoreBuff].up) and imp_despawn >timeInCombat+gcd * 2+( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) and SoulShards <3) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and ((MaxDps.spellHistory[1] == classtable.CallDreadstalkers) and SoulShards <4 and buff[classtable.DemonicCoreBuff].count <4) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and ((MaxDps.spellHistory[1] == classtable.CallDreadstalkers) and (MaxDps.spellHistory[1] == classtable.ShadowBolt) and MaxDps:Bloodlust(1) and SoulShards <5) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and ((MaxDps.spellHistory[1] == classtable.SummonVilefiend) and (not buff[classtable.DemonicCallingBuff].up or (MaxDps.spellHistory[1] == classtable.GrimoireFelguard))) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and ((MaxDps.spellHistory[1] == classtable.GrimoireFelguard) and buff[classtable.DemonicCoreBuff].count <3 and buff[classtable.DemonicCallingBuff].remains >gcd*3) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (imp_despawn >timeInCombat+gcd * 2+( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) and not buff[classtable.DemonicCoreBuff].up and buff[classtable.DemonicArtPitLordBuff].up and imp_despawn <timeInCombat+gcd * 5+( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0)) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (imp_despawn >timeInCombat+gcd + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) and imp_despawn <timeInCombat+gcd * 2+( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) and buff.dreadstalkers.remains>gcd + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) and SoulShards >1) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (not buff[classtable.DemonicCoreBuff].up and imp_despawn >timeInCombat+gcd*2 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) and imp_despawn <timeInCombat+gcd * 4+( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) and SoulShards <3 and GetTotemInfoById(classtable.CallDreadstalkersTotem).remains >gcd*2 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0)) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.GrimoireFelguard, 'GrimoireFelguard') and talents[classtable.GrimoireFelguard]) and (cooldown[classtable.SummonDemonicTyrant].remains <17-2 * gcd and cooldown[classtable.SummonVilefiend].remains <15-2 * gcd and cooldown[classtable.CallDreadstalkers].remains <12-2 * gcd) and cooldown[classtable.GrimoireFelguard].ready then
        if not setSpell then setSpell = classtable.GrimoireFelguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonVilefiend, 'SummonVilefiend') and talents[classtable.SummonVilefiend]) and (cooldown[classtable.SummonDemonicTyrant].remains <15-2 * gcd and (buff[classtable.GrimoireFelguardBuff].up or cooldown[classtable.GrimoireFelguard].remains >15 or not talents[classtable.GrimoireFelguard]) and (GetTotemInfoById(classtable.CallDreadstalkersTotem).up or cooldown[classtable.CallDreadstalkers].remains <15-2 * gcd or not talents[classtable.CallDreadstalkers])) and cooldown[classtable.SummonVilefiend].ready then
        if not setSpell then setSpell = classtable.SummonVilefiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.CallDreadstalkers, 'CallDreadstalkers') and talents[classtable.CallDreadstalkers]) and (cooldown[classtable.SummonDemonicTyrant].remains <12-2 * gcd and (GetTotemInfoById(classtable.SummonVilefiend).up or cooldown[classtable.SummonVilefiend].remains <12-2 * gcd or not talents[classtable.SummonVilefiend])) and cooldown[classtable.CallDreadstalkers].ready then
        if not setSpell then setSpell = classtable.CallDreadstalkers end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDemonicTyrant, 'SummonDemonicTyrant') and talents[classtable.SummonDemonicTyrant]) and ((((imp_despawn and imp_despawn <timeInCombat+gcd * 2.5+( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime /1000 or 0)) or (C_Spell.GetSpellCastCount(196277) >9 and SoulShards <2)) and GetTotemInfoById(classtable.CallDreadstalkersTotem).up and (GetTotemInfoById(classtable.SummonVilefiend).up or not (talents[classtable.SummonVilefiend] and true or false))) or (GetTotemInfoById(classtable.CallDreadstalkersTotem).up and GetTotemInfoById(classtable.CallDreadstalkersTotem).remains <gcd*2 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime /1000 or 0) and ((GetTotemInfoById(classtable.SummonVilefiend).up and GetTotemInfoById(classtable.SummonVilefiend).remains >2*gcd) or not (talents[classtable.SummonVilefiend] and true or false)) and ((buff[classtable.GrimoireFelguardBuff].up and buff[classtable.GrimoireFelguardBuff].remains >2*gcd) or not (talents[classtable.GrimoireFelguard] and true or false) or cooldown[classtable.GrimoireFelguard].remains >20))) and cooldown[classtable.SummonDemonicTyrant].ready then
        MaxDps:GlowCooldown(classtable.SummonDemonicTyrant, cooldown[classtable.SummonDemonicTyrant].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and ((imp_despawn or GetTotemInfoById(classtable.CallDreadstalkersTotem).up) and SoulShards >= 3 or SoulShards == 5) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and (imp_despawn and SoulShards <3) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (imp_despawn and buff[classtable.DemonicCoreBuff].up and SoulShards <4 or (MaxDps.spellHistory[1] == classtable.CallDreadstalkers) and SoulShards <4 and buff[classtable.DemonicCoreBuff].count == 4 or buff[classtable.DemonicCoreBuff].count == 4 and SoulShards <4 or buff[classtable.DemonicCoreBuff].count >= 2 and cooldown[classtable.PowerSiphon].remains <5) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and (imp_despawn or SoulShards == 5 and cooldown[classtable.SummonVilefiend].remains >gcd*3) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
end
function Demonology:variables()
    next_tyrant_cd = cooldown[classtable.SummonDemonicTyrant].remains
    if ( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) then
        in_opener = 0
    end
    if targets >1+((talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0)) then
        impl = not buff[classtable.TyrantBuff].up
    end
    if targets >2+((talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0)) and targets <5+((talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0)) then
        impl = buff[classtable.TyrantBuff].remains <6
    end
    if targets >4+((talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0)) then
        impl = buff[classtable.TyrantBuff].remains <8
    end
    pool_cores_for_tyrant = cooldown[classtable.SummonDemonicTyrant].remains <20 and next_tyrant_cd <20 and (buff[classtable.DemonicCoreBuff].count <= 2 or not buff[classtable.DemonicCoreBuff].up) and cooldown[classtable.SummonVilefiend].remains <gcd*8 and cooldown[classtable.CallDreadstalkers].remains <gcd*8
    if buff[classtable.DiabolicRitualMotherofChaosBuff].up then
        diabolic_ritual_remains = buff[classtable.DiabolicRitualMotherofChaosBuff].remains
    end
    if buff[classtable.DiabolicRitualOverlordBuff].up then
        diabolic_ritual_remains = buff[classtable.DiabolicRitualOverlordBuff].remains
    end
    if buff[classtable.DiabolicRitualPitLordBuff].up then
        diabolic_ritual_remains = buff[classtable.DiabolicRitualPitLordBuff].remains
    end
    if (MaxDps.spellHistory[1] == classtable.HandofGuldan) and GetTotemInfoById(classtable.CallDreadstalkersTotem).up and cooldown[classtable.SummonDemonicTyrant].remains <13 and imp_despawn == 0 then
        imp_despawn = 2 * SpellHaste*6 + 0.58+timeInCombat
    end
    if (MaxDps:CheckSpellUsable(classtable.Felstorm, 'Felstorm')) and (targets >1 and (not cooldown[classtable.DemonicStrength].ready or not talents[classtable.DemonicStrength]) and talents[classtable.FelSunder]) and cooldown[classtable.Felstorm].ready then
        if not setSpell then setSpell = classtable.Felstorm end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.AxeToss, false)
    MaxDps:GlowCooldown(classtable.SummonDemonicTyrant, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
    MaxDps:GlowCooldown(classtable.spymasters_web, false)
    MaxDps:GlowCooldown(classtable.imperfect_ascendancy_serum, false)
    MaxDps:GlowCooldown(classtable.mirror_of_fractured_tomorrows, false)
    MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, false)
end

function Demonology:callaction()
    if (MaxDps:CheckSpellUsable(classtable.AxeToss, 'AxeToss')) and cooldown[classtable.AxeToss].ready then
        MaxDps:GlowCooldown(classtable.AxeToss, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    Demonology:variables()
    check_racials = ( UnitExists('pet') and UnitName('pet')  == 'DemonicTyrant' ) or MaxDps:boss() and ttd <22
    if (check_racials) then
        Demonology:racials()
    end
    Demonology:items()
    if (MaxDps:boss() and ttd <30) then
        Demonology:fight_end()
    end
    if (timeInCombat <first_tyrant_time) then
        Demonology:opener()
    end
    if (cooldown[classtable.SummonDemonicTyrant].remains <gcd*14) then
        Demonology:tyrant()
    end
    if (MaxDps:CheckSpellUsable(classtable.CallDreadstalkers, 'CallDreadstalkers') and talents[classtable.CallDreadstalkers]) and (cooldown[classtable.SummonDemonicTyrant].remains >25 or next_tyrant_cd >25) and cooldown[classtable.CallDreadstalkers].ready then
        if not setSpell then setSpell = classtable.CallDreadstalkers end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonVilefiend, 'SummonVilefiend') and talents[classtable.SummonVilefiend]) and (cooldown[classtable.SummonDemonicTyrant].remains >30) and cooldown[classtable.SummonVilefiend].ready then
        if not setSpell then setSpell = classtable.SummonVilefiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (buff[classtable.DemonicCoreBuff].up and (not talents[classtable.Doom] or buff[classtable.DemonicCoreBuff].count >1 or debuff[classtable.DoomDeBuff].remains >10 or not debuff[classtable.DoomDeBuff].up) and (((not talents[classtable.FelInvocation] or cooldown[classtable.SoulStrike].remains >gcd*2) and SoulShards <4)) and not (MaxDps.spellHistory[1] == classtable.Demonbolt) and not pool_cores_for_tyrant) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (buff[classtable.DemonicCoreBuff].count >= 3-(((talents[classtable.Doom] and talents[classtable.Doom] or 0) and not debuff[classtable.DoomDeBuff].up) and 1 or 0)*2 and SoulShards <= 3 and not pool_cores_for_tyrant) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.PowerSiphon, 'PowerSiphon')) and (buff[classtable.DemonicCoreBuff].count <3 and cooldown[classtable.SummonDemonicTyrant].remains >25 and not buff[classtable.DemonicPowerBuff].up) and cooldown[classtable.PowerSiphon].ready then
        if not setSpell then setSpell = classtable.PowerSiphon end
    end
    if (MaxDps:CheckSpellUsable(classtable.DemonicStrength, 'DemonicStrength') and talents[classtable.DemonicStrength]) and (targets >1) and cooldown[classtable.DemonicStrength].ready then
        if not setSpell then setSpell = classtable.DemonicStrength end
    end
    if (MaxDps:CheckSpellUsable(classtable.BilescourgeBombers, 'BilescourgeBombers')) and (targets >1) and cooldown[classtable.BilescourgeBombers].ready then
        if not setSpell then setSpell = classtable.BilescourgeBombers end
    end
    if (MaxDps:CheckSpellUsable(classtable.Guillotine, 'Guillotine')) and (targets >1 and (not cooldown[classtable.DemonicStrength].ready or not talents[classtable.DemonicStrength])) and cooldown[classtable.Guillotine].ready then
        if not setSpell then setSpell = classtable.Guillotine end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and (buff[classtable.InfernalBoltBuff].remains >( classtable and classtable.InfernalBolt and GetSpellInfo(classtable.InfernalBolt).castTime /1000 or 0) and buff[classtable.InfernalBoltBuff].remains <2*gcd or SoulShards <3 and cooldown[classtable.SummonDemonicTyrant].remains >20) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Implosion, 'Implosion')) and ((C_Spell.GetSpellCastCount(196277) >=2 and 1 or 0) >0 and impl and not (MaxDps.spellHistory[1] == classtable.Implosion) and (targets >3 or targets <= 3 and last_cast_imps() >0)) and cooldown[classtable.Implosion].ready then
        if not setSpell then setSpell = classtable.Implosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (diabolic_ritual_remains >gcd and diabolic_ritual_remains <gcd+gcd and buff[classtable.DemonicCoreBuff].up and SoulShards <= 3) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (diabolic_ritual_remains >gcd and diabolic_ritual_remains <SoulShardsDeficit*( classtable and classtable.ShadowBolt and GetSpellInfo(classtable.ShadowBolt).castTime /1000 or 0) + gcd and SoulShards <5) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (((SoulShards >2 and (cooldown[classtable.CallDreadstalkers].remains >gcd*4 or buff[classtable.DemonicCallingBuff].remains - gcd>cooldown[classtable.CallDreadstalkers].remains) and cooldown[classtable.SummonDemonicTyrant].remains >17) or SoulShards == 5 or SoulShards == 4 and talents[classtable.FelInvocation]) and (targets == 1)) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (SoulShards >2 and not (targets == 1)) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (targets <4 and buff[classtable.DemonicCoreBuff].count >1 and ((SoulShards <4 and not talents[classtable.SoulStrike] or cooldown[classtable.SoulStrike].remains >gcd*2 and talents[classtable.FelInvocation]) or SoulShards <3) and not pool_cores_for_tyrant) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (buff[classtable.DemonicCoreBuff].up and buff[classtable.TyrantBuff].up and SoulShards <3) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (buff[classtable.DemonicCoreBuff].count >1 and SoulShards <4) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Felstorm, 'Felstorm')) and (targets >1 and (not cooldown[classtable.DemonicStrength].ready or not talents[classtable.DemonicStrength]) and talents[classtable.FelSunder]) and cooldown[classtable.Felstorm].ready then
        if not setSpell then setSpell = classtable.Felstorm end
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
    classtable.AxeToss = 119914
    classtable.Guillotine = 386833
    classtable.Demonbolt = 264178
    classtable.InfernalBolt = 434506
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.GrimoireofSacrificeBuff = 0
    classtable.PowerSiphonBuff = 334581
    classtable.TyrantBuff = 265273
    classtable.DreadstalkersBuff = 104316
    classtable.DemonicCoreBuff = 264173
    classtable.DemonicPowerBuff = 265273
    classtable.InfernalBoltBuff = 433891
    classtable.DemonicCallingBuff = 205146
    classtable.SpymastersReportBuff = 451199
    classtable.BloodlustBuff = 2825
    classtable.DemonicArtPitLordBuff = 432795
    classtable.GrimoireFelguardBuff = 111898
    classtable.VilefiendBuff = 264119
    classtable.WildImpsBuff = 0
    classtable.DiabolicRitualMotherofChaosBuff = 432815
    classtable.DiabolicRitualOverlordBuff = 431944
    classtable.DiabolicRitualPitLordBuff = 432816
    classtable.DoomDeBuff = 460553
    classtable.InfernalBolt = 434506
    classtable.Felstorm = 89751
    classtable.AxeToss = 119914
    classtable.CallDreadstalkersTotem = 193332

    local function debugg()
        talents[classtable.GrimoireFelguard] = 1
        talents[classtable.SummonVilefiend] = 1
        talents[classtable.Doom] = 1
        talents[classtable.FelInvocation] = 1
        talents[classtable.DemonicStrength] = 1
        talents[classtable.SoulStrike] = 1
        talents[classtable.FelSunder] = 1
        talents[classtable.SummonDemonicTyrant] = 1
        talents[classtable.CallDreadstalkers] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Demonology:precombat()

    Demonology:callaction()
    if setSpell then return setSpell end
end
