local _, addonTable = ...
local Warlock = addonTable.Warlock
local MaxDps = _G.MaxDps
if not MaxDps then return end

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
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local SoulShards
local Mana
local ManaMax
local ManaDeficit
local havoc_active
local havoc_remains

local Destruction = {}

local cleave_apl
local trinket_one_buffs
local trinket_two_buffs
local trinket_one_sync
local trinket_two_sync
local trinket_one_manual
local trinket_two_manual
local trinket_one_exclude
local trinket_two_exclude
local trinket_one_buff_duration
local trinket_two_buff_duration
local trinket_priority
local allow_rof_twot_spender
local do_rof_twot
local disable_cb_twot
local pool_soul_shards
local havoc_immo_time
local pooling_condition
local pooling_condition_cb
local infernal_active
local trinket_one_will_lose_cast
local trinket_two_will_lose_cast
local min_wither
local min_immo
local diabolic_ritual
local demonic_art
local disable_cb_2t


local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end


function Destruction:precombat()
    --if (MaxDps:CheckSpellUsable(classtable.FelDomination, 'FelDomination')) and (timeInCombat >0 and not UnitExists('pet')) and cooldown[classtable.FelDomination].ready then
    --    return classtable.FelDomination
    --end
    --cleave_apl = toggle.funnel
    --allow_rof_twot_spender = 2
    --do_rof_twot = allow_rof_2t_spender >1.99 and not ( talents[classtable.Cataclysm] and talents[classtable.ImprovedChaosBolt] )
    --disable_cb_twot = do_rof_2t or allow_rof_2t_spender >0.01 and allow_rof_2t_spender <0.99
    --if (MaxDps:CheckSpellUsable(classtable.GrimoireofSacrifice, 'GrimoireofSacrifice')) and (talents[classtable.GrimoireofSacrifice]) and cooldown[classtable.GrimoireofSacrifice].ready then
    --    return classtable.GrimoireofSacrifice
    --end
    --if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and cooldown[classtable.SoulFire].ready then
    --    return classtable.SoulFire
    --end
    --if (MaxDps:CheckSpellUsable(classtable.Cataclysm, 'Cataclysm')) and (math.huge >15) and cooldown[classtable.Cataclysm].ready then
    --    return classtable.Cataclysm
    --end
    --if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
    --    return classtable.Incinerate
    --end
end
function Destruction:aoe()
    if ((havoc_active and 1 or 0) and havoc_remains >gcd and targets <5 and ( not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal] )) then
        local havocCheck = Destruction:havoc()
        if havocCheck then
            return Destruction:havoc()
        end
    end
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence')) and (cooldown[classtable.SummonInfernal].remains >= 55 and SoulShards <4.7 and ( targets <= 3 + debuff[classtable.WitherDeBuff].count  or timeInCombat >30 )) and cooldown[classtable.Malevolence].ready then
        return classtable.Malevolence
    end
    if (MaxDps:CheckSpellUsable(classtable.DimensionalRift, 'DimensionalRift')) and (SoulShards <4.7 and ( cooldown[classtable.DimensionalRift].charges >2 or ttd <cooldown[classtable.DimensionalRift].duration )) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire')) and (SoulShards >= ( 4.5 - 0.1 * debuff[classtable.ImmolateDeBuff].count  )) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither')) and (debuff[classtable.WitherDeBuff].refreshable and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.WitherDeBuff].remains ) and ( not talents[classtable.RagingDemonfire] or cooldown[classtable.ChannelDemonfire].remains >debuff[classtable.WitherDeBuff].remains or timeInCombat <5 ) and ( debuff[classtable.WitherDeBuff].count  <= 4 or timeInCombat >15 ) and ttd >18) and cooldown[classtable.Wither].ready then
        return classtable.Wither
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (debuff[classtable.ImmolateDeBuff].remains + debuff[classtable.WitherDeBuff].remains >( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 ) and talents[classtable.RagingDemonfire]) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn')) and (( targets <4 + ( (talents[classtable.Cataclysm] and talents[classtable.Cataclysm] or 0) + 4 * (talents[classtable.Cataclysm] and talents[classtable.Cataclysm] or 0) ) * (talents[classtable.Wither] and talents[classtable.Wither] or 0) ) and ( ( cooldown[classtable.Shadowburn].fullRecharge <= gcd * 3 or debuff[classtable.EradicationDeBuff].remains <= gcd and talents[classtable.Eradication] and not (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 ) and not talents[classtable.DiabolicRitual] ) and ( talents[classtable.ConflagrationofChaos] or talents[classtable.BlisteringAtrophy] ) and ( targets <5 + ( talents[classtable.Wither] and talents[classtable.Cataclysm] and 1 or 0) + (havoc_active and 1 or 0) ) or ttd <= 8 )) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and cooldown[classtable.Ruination].ready then
        return classtable.Ruination
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire')) and (( UnitExists('pet') and UnitName('pet')  == 'infernal' ) or ( UnitExists('pet') and UnitName('pet')  == 'overfiend' )) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire')) and (ttd <12 or timeInCombat >5) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and (SoulShards <2.5) and cooldown[classtable.InfernalBolt].ready then
        return classtable.InfernalBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (SoulShards >3.5 - ( 0.1 * targets ) and not talents[classtable.RainofFire]) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.Cataclysm, 'Cataclysm')) and (math.huge >15 or talents[classtable.Wither]) and cooldown[classtable.Cataclysm].ready then
        return classtable.Cataclysm
    end
    if (MaxDps:CheckSpellUsable(classtable.Havoc, 'Havoc')) and (( not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal] or ( talents[classtable.Inferno] and targets >4 ) ) and ttd >8 and cooldown[classtable.Malevolence].remains >15 or timeInCombat <5) and cooldown[classtable.Havoc].ready then
        return classtable.Havoc
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither')) and (debuff[classtable.WitherDeBuff].refreshable and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.WitherDeBuff].remains ) and ( not talents[classtable.RagingDemonfire] or cooldown[classtable.ChannelDemonfire].remains >debuff[classtable.WitherDeBuff].remains or timeInCombat <5 ) and debuff[classtable.WitherDeBuff].count  <= targets and ttd >18) and cooldown[classtable.Wither].ready then
        return classtable.Wither
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (debuff[classtable.ImmolateDeBuff].refreshable and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains ) and ( not talents[classtable.RagingDemonfire] or cooldown[classtable.ChannelDemonfire].remains >debuff[classtable.ImmolateDeBuff].remains or timeInCombat <5 ) and debuff[classtable.ImmolateDeBuff].count  <= 4 and ttd >18) and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    local ogcdCheck = Destruction:ogcd()
    if ogcdCheck then
        return ogcdCheck
    end
    MaxDps:GlowCooldown(classtable.SummonInfernal,MaxDps:CheckSpellUsable(classtable.SummonInfernal, 'SummonInfernal') and cooldown[classtable.SummonInfernal].ready)
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire')) and (not debuff[classtable.PyrogenicsDeBuff].up and targets <= 4) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (debuff[classtable.ImmolateDeBuff].remains + debuff[classtable.WitherDeBuff].remains >( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 )) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (( ( debuff[classtable.ImmolateDeBuff].refreshable and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains ) ) or targets >debuff[classtable.ImmolateDeBuff].count  ) and ttd >10 and not (havoc_active and 1 or 0)) and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (( ( debuff[classtable.ImmolateDeBuff].refreshable and (havoc_immo_time and 1 or 0) <5.4 ) or ( debuff[classtable.ImmolateDeBuff].remains <2 and debuff[classtable.ImmolateDeBuff].remains <havoc_remains ) or not debuff[classtable.ImmolateDeBuff].up or ( (havoc_immo_time and 1 or 0) <2 and 1 or 0) * (havoc_active and 1 or 0) ) and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains ) and ttd >11) and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    if (MaxDps:CheckSpellUsable(classtable.DimensionalRift, 'DimensionalRift')) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (buff[classtable.BackdraftBuff].up) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and (talents[classtable.FireandBrimstone] and buff[classtable.BackdraftBuff].up) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (buff[classtable.BackdraftBuff].count <2 or not talents[classtable.Backdraft]) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
end
function Destruction:cleave()
    if ((havoc_active and 1 or 0) and havoc_remains >gcd) then
        local havocCheck = Destruction:havoc()
        if havocCheck then
            return Destruction:havoc()
        end
    end
    pool_soul_shards = cooldown[classtable.Havoc].remains <= 5 or talents[classtable.Mayhem]
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence')) and (( not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal] )) and cooldown[classtable.Malevolence].ready then
        return classtable.Malevolence
    end
    if (MaxDps:CheckSpellUsable(classtable.Havoc, 'Havoc')) and (( not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal] ) and ttd >8) and cooldown[classtable.Havoc].ready then
        return classtable.Havoc
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (demonic_art) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (buff[classtable.DecimationBuff].up and ( SoulShards <= 4 or buff[classtable.DecimationBuff].remains <= gcd * 2 ) and debuff[classtable.ConflagrateDeBuff].remains >= timeShift and cooldown[classtable.Havoc].remains) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither')) and (talents[classtable.InternalCombustion] and ( ( ( debuff[classtable.WitherDeBuff].remains - 5 * (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 ) ) <debuff[classtable.WitherDeBuff].duration * 0.4 ) or debuff[classtable.WitherDeBuff].remains <3 or ( debuff[classtable.WitherDeBuff].remains - 2 ) <5 and cooldown[classtable.ChaosBolt].ready ) and ( not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 ) >( debuff[classtable.WitherDeBuff].remains - 5 ) ) and ttd >8 and not MaxDps.spellHistory[1] == classtable.SoulFire) and cooldown[classtable.Wither].ready then
        return classtable.Wither
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither')) and (not talents[classtable.InternalCombustion] and ( ( ( debuff[classtable.WitherDeBuff].remains - 5 * ( (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 ) and 1 or 0) and 1 or 0) <debuff[classtable.WitherDeBuff].duration * 0.3 ) or debuff[classtable.WitherDeBuff].remains <3 ) and ( not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 or 0) >( debuff[classtable.WitherDeBuff].remains ) ) and ttd >8 and not MaxDps.spellHistory[1] == classtable.SoulFire) and cooldown[classtable.Wither].ready then
        return classtable.Wither
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (( talents[classtable.RoaringBlaze] and cooldown[classtable.Conflagrate].fullRecharge <= gcd * 2 ) or cooldown[classtable.Conflagrate].duration <= 8 and ( diabolic_ritual and ( buff[classtable.DiabolicRitualMotherofChaosBuff].remains + buff[classtable.DiabolicRitualOverlordBuff].remains + buff[classtable.DiabolicRitualPitLordBuff].remains ) <gcd ) and not pool_soul_shards) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn')) and (( cooldown[classtable.Shadowburn].fullRecharge <= gcd * 3 or debuff[classtable.EradicationDeBuff].remains <= gcd and talents[classtable.Eradication] and not (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 ) and not talents[classtable.DiabolicRitual] ) and ( talents[classtable.ConflagrationofChaos] or talents[classtable.BlisteringAtrophy] ) or ttd <= 8) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (buff[classtable.RitualofRuinBuff].up) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire')) and (cooldown[classtable.SummonInfernal].remains >= 90 and talents[classtable.RainofChaos]) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn')) and (cooldown[classtable.SummonInfernal].remains >= 90 and talents[classtable.RainofChaos]) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (cooldown[classtable.SummonInfernal].remains >= 90 and talents[classtable.RainofChaos]) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and (( debuff[classtable.EradicationDeBuff].remains >= timeShift or not talents[classtable.Eradication] or not talents[classtable.Shadowburn] )) and cooldown[classtable.Ruination].ready then
        return classtable.Ruination
    end
    if (MaxDps:CheckSpellUsable(classtable.Cataclysm, 'Cataclysm')) and (math.huge >15) and cooldown[classtable.Cataclysm].ready then
        return classtable.Cataclysm
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (talents[classtable.RagingDemonfire] and ( debuff[classtable.ImmolateDeBuff].remains + debuff[classtable.WitherDeBuff].remains - 5 * ( (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 or 0) and talents[classtable.InternalCombustion] and talents[classtable.InternalCombustion] or 0) ) >( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 or 0)) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (SoulShards <= 3.5 and ( debuff[classtable.ConflagrateDeBuff].remains >( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime /1000 ) + 1 or not talents[classtable.RoaringBlaze] and buff[classtable.BackdraftBuff].up ) and not pool_soul_shards) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (( debuff[classtable.ImmolateDeBuff].refreshable and ( debuff[classtable.ImmolateDeBuff].remains <cooldown[classtable.Havoc].remains or not debuff[classtable.ImmolateDeBuff].up ) ) and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains ) and ( not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( (talents[classtable.Mayhem] and talents[classtable.Mayhem] or 0) * ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 ) and 1 or 0) >debuff[classtable.ImmolateDeBuff].remains ) and ttd >15) and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    MaxDps:GlowCooldown(classtable.SummonInfernal,MaxDps:CheckSpellUsable(classtable.SummonInfernal, 'SummonInfernal') and cooldown[classtable.SummonInfernal].ready)
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and (talents[classtable.DiabolicRitual] and ( diabolic_ritual and ( buff[classtable.DiabolicRitualMotherofChaosBuff].remains + buff[classtable.DiabolicRitualOverlordBuff].remains + buff[classtable.DiabolicRitualPitLordBuff].remains - 2 - (disable_cb_2t and 0 or 1) * ( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime / 1000 ) - (disable_cb_2t and 1 or 0) * gcd ) <= 0 )) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire')) and (pooling_condition and not talents[classtable.Wither] and buff[classtable.RainofChaosBuff].up) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire')) and (not talents[classtable.Wither] and talents[classtable.Pyrogenics] and debuff[classtable.PyrogenicsDeBuff].remains <= gcd and ( not talents[classtable.RainofChaos] or cooldown[classtable.SummonInfernal].remains >= gcd * 3 ) and pooling_condition) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire')) and (pooling_condition and ( cooldown[classtable.SummonInfernal].remains >= gcd * 3 or not talents[classtable.RainofChaos] )) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (SoulShards <= 4 and talents[classtable.Mayhem]) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (not disable_cb_2t and pooling_condition_cb and ( cooldown[classtable.SummonInfernal].remains >= gcd * 3 or SoulShards >4 or not talents[classtable.RainofChaos] )) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (MaxDps:CheckSpellUsable(classtable.DimensionalRift, 'DimensionalRift')) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and cooldown[classtable.InfernalBolt].ready then
        return classtable.InfernalBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (cooldown[classtable.Conflagrate].charges >( cooldown[classtable.Conflagrate].maxCharges - 1 ) or ttd <gcd * cooldown[classtable.Conflagrate].charges) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
end
function Destruction:havoc()
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (talents[classtable.Backdraft] and not buff[classtable.BackdraftBuff].up and SoulShards >= 1 and SoulShards <= 4) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime /1000 ) <havoc_remains and SoulShards <2.5) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (SoulShards <4.5 and (talents[classtable.RagingDemonfire] and talents[classtable.RagingDemonfire] or 0) == 2) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Cataclysm, 'Cataclysm')) and (math.huge >15 or ( talents[classtable.Wither] and min_wither <debuff[classtable.WitherDeBuff].duration * 0.3 )) and cooldown[classtable.Cataclysm].ready then
        return classtable.Cataclysm
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (( ( ( debuff[classtable.ImmolateDeBuff].refreshable and (havoc_immo_time and 1 or 0) <5.4 ) and ttd >5 ) or ( ( debuff[classtable.ImmolateDeBuff].remains <2 and debuff[classtable.ImmolateDeBuff].remains <havoc_remains ) or not debuff[classtable.ImmolateDeBuff].up or (havoc_immo_time and 1 or 0) <2 ) and ttd >11 ) and SoulShards <4.5) and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither')) and (( ( ( debuff[classtable.WitherDeBuff].refreshable and (havoc_immo_time and 1 or 0) <5.4 ) and ttd >5 ) or ( ( debuff[classtable.WitherDeBuff].remains <2 and debuff[classtable.WitherDeBuff].remains <havoc_remains ) or not debuff[classtable.WitherDeBuff].up or (havoc_immo_time and 1 or 0) <2 ) and ttd >11 ) and SoulShards <4.5) and cooldown[classtable.Wither].ready then
        return classtable.Wither
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn')) and (( cooldown[classtable.Shadowburn].fullRecharge <= gcd * 3 or debuff[classtable.EradicationDeBuff].remains <= gcd and talents[classtable.Eradication] and not (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 ) and not talents[classtable.DiabolicRitual] ) and ( talents[classtable.ConflagrationofChaos] or talents[classtable.BlisteringAtrophy] )) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn')) and (havoc_remains <= gcd * 3) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime /1000 ) <havoc_remains and ( targets <= 2 - ( (talents[classtable.Inferno] and talents[classtable.Inferno] or 0) - (talents[classtable.ImprovedChaosBolt] and talents[classtable.ImprovedChaosBolt] or 0) - (talents[classtable.Cataclysm] and talents[classtable.Cataclysm] or 0) ) * (talents[classtable.Wither] and talents[classtable.Wither] or 0) + ( (talents[classtable.Cataclysm] and talents[classtable.Cataclysm] or 0) + (talents[classtable.ImprovedChaosBolt] and talents[classtable.ImprovedChaosBolt] or 0 ) ) * (not talents[classtable.Wither] and 2 or 1) )) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.RainofFire, 'RainofFire')) and (targets >= 3 - (talents[classtable.Wither] and talents[classtable.Wither] or 0 )) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (SoulShards <4.5) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (not talents[classtable.Backdraft]) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (MaxDps:CheckSpellUsable(classtable.DimensionalRift, 'DimensionalRift')) and (SoulShards <4.7 and ( cooldown[classtable.DimensionalRift].charges >2 or ttd <cooldown[classtable.DimensionalRift].duration )) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and (( classtable and classtable.Incinerate and GetSpellInfo(classtable.Incinerate).castTime /1000 ) <havoc_remains) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
end
function Destruction:items()
end
function Destruction:ogcd()
end
function Destruction:variables()
    if (havoc_active) then
        havoc_immo_time = debuff[classtable.ImmolateDeBuff].remains <debuff[classtable.WitherDeBuff].remains
    end
    pooling_condition = 1
    pooling_condition_cb = 1
    infernal_active = ( UnitExists('pet') and UnitName('pet')  == 'infernal' ) or ( cooldown[classtable.SummonInfernal].duration - cooldown[classtable.SummonInfernal].remains ) <20
    min_wither = 21
    min_immo = debuff[classtable.ImmolateDeBuff].remains
    min_wither = debuff[classtable.WitherDeBuff].remains
end

function Destruction:callaction()
    local variablesCheck = Destruction:variables()
    if variablesCheck then
        return variablesCheck
    end
    local ogcdCheck = Destruction:ogcd()
    if ogcdCheck then
        return ogcdCheck
    end
    local itemsCheck = Destruction:items()
    if itemsCheck then
        return itemsCheck
    end
    if (( targets >= 3 ) and not cleave_apl) then
        local aoeCheck = Destruction:aoe()
        if aoeCheck then
            return Destruction:aoe()
        end
    end
    if (targets ~= 1 or cleave_apl) then
        local cleaveCheck = Destruction:cleave()
        if cleaveCheck then
            return Destruction:cleave()
        end
    end
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence')) and (cooldown[classtable.SummonInfernal].remains >= 55) and cooldown[classtable.Malevolence].ready then
        return classtable.Malevolence
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (demonic_art) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (buff[classtable.DecimationBuff].up and ( SoulShards <= 4 or buff[classtable.DecimationBuff].remains <= gcd * 2 ) and debuff[classtable.ConflagrateDeBuff].remains >= timeShift) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither')) and (talents[classtable.InternalCombustion] and ( ( ( debuff[classtable.WitherDeBuff].remains - 5 * (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 or 0) ) <debuff[classtable.WitherDeBuff].duration * 0.4 ) or debuff[classtable.WitherDeBuff].remains <3 or ( debuff[classtable.WitherDeBuff].remains - 2 ) <5 and cooldown[classtable.ChaosBolt].ready ) and ( not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 or 0) >( debuff[classtable.WitherDeBuff].remains - 5 ) ) and ttd >8 and not MaxDps.spellHistory[1] == classtable.SoulFire) and cooldown[classtable.Wither].ready then
        return classtable.Wither
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (talents[classtable.RoaringBlaze] and debuff[classtable.ConflagrateDeBuff].remains <1.5 or cooldown[classtable.Conflagrate].fullRecharge <= gcd * 2 or cooldown[classtable.Conflagrate].duration <= 8 and ( diabolic_ritual and ( buff[classtable.DiabolicRitualMotherofChaosBuff].remains + buff[classtable.DiabolicRitualOverlordBuff].remains + buff[classtable.DiabolicRitualPitLordBuff].remains ) <gcd ) and SoulShards >= 1.5) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn')) and (( cooldown[classtable.Shadowburn].fullRecharge <= gcd * 3 or debuff[classtable.EradicationDeBuff].remains <= gcd and talents[classtable.Eradication] and not (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 ) and not talents[classtable.DiabolicRitual] ) and ( talents[classtable.ConflagrationofChaos] or talents[classtable.BlisteringAtrophy] ) or ttd <= 8) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (buff[classtable.RitualofRuinBuff].up) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowburn, 'Shadowburn')) and (cooldown[classtable.SummonInfernal].remains >= 90 and talents[classtable.RainofChaos]) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (cooldown[classtable.SummonInfernal].remains >= 90 and talents[classtable.RainofChaos]) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and (( debuff[classtable.EradicationDeBuff].remains >= timeShift or not talents[classtable.Eradication] or not talents[classtable.Shadowburn] )) and cooldown[classtable.Ruination].ready then
        return classtable.Ruination
    end
    if (MaxDps:CheckSpellUsable(classtable.Cataclysm, 'Cataclysm')) and (math.huge >15 and ( debuff[classtable.ImmolateDeBuff].refreshable and not talents[classtable.Wither] or talents[classtable.Wither] and debuff[classtable.WitherDeBuff].refreshable )) and cooldown[classtable.Cataclysm].ready then
        return classtable.Cataclysm
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (talents[classtable.RagingDemonfire] and ( debuff[classtable.ImmolateDeBuff].remains + debuff[classtable.WitherDeBuff].remains - 5 * ( (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 and 1 or 0) and talents[classtable.InternalCombustion] and 1 or 0)) >( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 and 1 or 0) and 1 or 0) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither')) and (not talents[classtable.InternalCombustion] and ( ( ( debuff[classtable.WitherDeBuff].remains - 5 * ( (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 and 1 or 0) ) ) <debuff[classtable.WitherDeBuff].duration * 0.3 ) or debuff[classtable.WitherDeBuff].remains <3 ) and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.WitherDeBuff].remains ) and ( not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 or 0 ) >( debuff[classtable.WitherDeBuff].remains ) ) and ttd >8 and not MaxDps.spellHistory[1] == classtable.SoulFire) and cooldown[classtable.Wither].ready then
        return classtable.Wither
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (( ( ( debuff[classtable.ImmolateDeBuff].remains - 5 * ( (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 ) and talents[classtable.InternalCombustion] and 1 or 0 ) ) <debuff[classtable.ImmolateDeBuff].duration * 0.3 ) or debuff[classtable.ImmolateDeBuff].remains <3 or ( debuff[classtable.ImmolateDeBuff].remains - 2 ) <5 and talents[classtable.InternalCombustion] and cooldown[classtable.ChaosBolt].ready ) and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains ) and ( not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 ) >( debuff[classtable.ImmolateDeBuff].remains - 5 * (talents[classtable.InternalCombustion] and talents[classtable.InternalCombustion] or 0) ) ) and ttd >8 and not MaxDps.spellHistory[1] == classtable.SoulFire) and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    MaxDps:GlowCooldown(classtable.SummonInfernal,MaxDps:CheckSpellUsable(classtable.SummonInfernal, 'SummonInfernal') and cooldown[classtable.SummonInfernal].ready)
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and (talents[classtable.DiabolicRitual] and ( diabolic_ritual and ( buff[classtable.DiabolicRitualMotherofChaosBuff].remains + buff[classtable.DiabolicRitualOverlordBuff].remains + buff[classtable.DiabolicRitualPitLordBuff].remains - 2 - (disable_cb_2t and 0 or 1) * ( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime / 1000 ) - (disable_cb_2t and 1 or 0) * gcd ) <= 0 )) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
    if (MaxDps:CheckSpellUsable(classtable.ChaosBolt, 'ChaosBolt')) and (pooling_condition_cb and ( cooldown[classtable.SummonInfernal].remains >= gcd * 3 or SoulShards >4 or not talents[classtable.RainofChaos] )) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.ChannelDemonfire, 'ChannelDemonfire')) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (MaxDps:CheckSpellUsable(classtable.DimensionalRift, 'DimensionalRift')) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and cooldown[classtable.InfernalBolt].ready then
        return classtable.InfernalBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.Conflagrate, 'Conflagrate')) and (cooldown[classtable.Conflagrate].charges >( cooldown[classtable.Conflagrate].maxCharges - 1 ) or ttd <gcd * cooldown[classtable.Conflagrate].charges) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (buff[classtable.BackdraftBuff].up) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
    if ((havoc_active) and havoc_remains >gcd and targets <5 and ( not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal] )) then
        local havocCheck = Destruction:havoc()
        if havocCheck then
            return Destruction:havoc()
        end
    end
    local ogcdCheck = Destruction:ogcd()
    if ogcdCheck then
        return ogcdCheck
    end
    if ((havoc_active) and havoc_remains >gcd) then
        local havocCheck = Destruction:havoc()
        if havocCheck then
            return Destruction:havoc()
        end
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
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    SoulShards = UnitPower('player', SoulShardsPT)
    classtable.SpellLock = 19647
    local havoc_count, havoc_totalRemains = MaxDps:DebuffCounter(classtable.Havoc,1)
    havoc_active = havoc_count >= 1
    havoc_remains = havoc_totalRemains or 0
    classtable.Wither = 445468
    classtable.InfernalBolt = 434506
    diabolic_ritual = buff[classtable.DiabolicRitualMotherofChaosBuff].up or buff[classtable.DiabolicRitualOverlordBuff].up or buff[classtable.DiabolicRitualPitLordBuff].up
    demonic_art = buff[classtable.DemonicArtOverlordBuff].up or buff[classtable.DemonicArtPitLordBuff].up
    disable_cb_2t = false
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.WitherDeBuff = 445474
    classtable.ImmolateDeBuff = 157736
    classtable.EradicationDeBuff = 196414
    classtable.PyrogenicsDeBuff = 387096
    classtable.BackdraftBuff = 117828
    classtable.DecimationBuff = 457555
    classtable.ConflagrateDeBuff = 0
    classtable.DiabolicRitualMotherofChaosBuff = 432815
    classtable.DiabolicRitualOverlordBuff = 431944
    classtable.DiabolicRitualPitLordBuff = 432816
    classtable.RitualofRuinBuff = 387157
    classtable.RainofChaosBuff = 266087

    local precombatCheck = Destruction:precombat()
    if precombatCheck then
        return Destruction:precombat()
    end

    local callactionCheck = Destruction:callaction()
    if callactionCheck then
        return Destruction:callaction()
    end
end
