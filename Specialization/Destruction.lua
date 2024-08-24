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
local infernal_active
local trinket_one_will_lose_cast
local trinket_two_will_lose_cast
local aoe_condition
local cleave_condition
local pool_soul_shards

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnown(spell) then return false end
    if not C_Spell.IsSpellUsable(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) or (classtable.HuntersPreyBuff and not buff[classtable.HuntersPreyBuff].up) and targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and not buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and not buff[classtable.FinalVerdictBuff].up) ) and targethealthPerc > 20 then
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and not buff[classtable.SuddenDeathBuff].up) and targethealthPerc > 35 then
            return false
        end
    end
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
end



local function CheckTrinketNames(checkName)
    --if slot == 1 then
    --    slot = 13
    --end
    --if slot == 2 then
    --    slot = 14
    --end
    for i=13,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = C_Item.GetItemInfo(itemID)
        if checkName == itemName then
            return true
        end
    end
    return false
end


local function CheckTrinketCooldown(slot)
    if slot == 1 then
        slot = 13
    end
    if slot == 2 then
        slot = 14
    end
    if slot == 13 or slot == 14 then
        local itemID = GetInventoryItemID('player', slot)
        local _, duration, _ = C_Item.GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = C_Item.GetItemInfo(tOneitemID)
        local tTwoitemName = C_Item.GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tTwoitemID)
            if duration == 0 then return true else return false end
        end
    end
end




local function CheckPrevSpell(spell)
    if MaxDps and MaxDps.spellHistory then
        if MaxDps.spellHistory[1] then
            if MaxDps.spellHistory[1] == spell then
                return true
            end
            if MaxDps.spellHistory[1] ~= spell then
                return false
            end
        end
    end
    return true
end


local function boss()
    if UnitExists('boss1')
    or UnitExists('boss2')
    or UnitExists('boss3')
    or UnitExists('boss4')
    or UnitExists('boss5')
    or UnitExists('boss6')
    or UnitExists('boss7')
    or UnitExists('boss8')
    or UnitExists('boss9')
    or UnitExists('boss10') then
        return true
    end
    return false
end


function Destruction:precombat()
    --if (CheckSpellCosts(classtable.FelDomination, 'FelDomination')) and (timeInCombat >0 and not UnitExists('pet')) and cooldown[classtable.FelDomination].ready then
    --    return classtable.FelDomination
    --end
    cleave_apl = 0
    --if (CheckSpellCosts(classtable.GrimoireofSacrifice, 'GrimoireofSacrifice')) and (talents[classtable.GrimoireofSacrifice]) and cooldown[classtable.GrimoireofSacrifice].ready then
    --    return classtable.GrimoireofSacrifice
    --end
    --if (CheckSpellCosts(classtable.SoulFire, 'SoulFire')) and cooldown[classtable.SoulFire].ready then
    --    return classtable.SoulFire
    --end
    --if (CheckSpellCosts(classtable.Cataclysm, 'Cataclysm')) and (math.huge >15) and cooldown[classtable.Cataclysm].ready then
    --    return classtable.Cataclysm
    --end
    --if (CheckSpellCosts(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
    --    return classtable.Incinerate
    --end
end
function Destruction:aoe()
    local ogcdCheck = Destruction:ogcd()
    if ogcdCheck then
        return ogcdCheck
    end
    local itemsCheck = Destruction:items()
    if itemsCheck then
        return itemsCheck
    end
    if (havoc_active and havoc_remains >gcd and targets <5 + ( talents[classtable.CryHavoc] and not talents[classtable.Inferno] ) and ( not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal] )) then
        local havocCheck = Destruction:havoc()
        if havocCheck then
            return Destruction:havoc()
        end
    end
    if (CheckSpellCosts(classtable.DimensionalRift, 'DimensionalRift')) and (SoulShards <4.7 and ( cooldown[classtable.DimensionalRift].charges >2 or boss and ttd <cooldown[classtable.DimensionalRift].duration )) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (CheckSpellCosts(classtable.Shadowburn, 'Shadowburn')) and (ttd <5 and targetHP <20 and havoc_active) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (CheckSpellCosts(classtable.RainofFire, 'RainofFire')) and (( UnitExists('pet') and UnitName('pet')  == 'infernal' ) or ( UnitExists('pet') and UnitName('pet')  == 'blasphemy' )) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (CheckSpellCosts(classtable.RainofFire, 'RainofFire')) and (boss and ttd <12) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (CheckSpellCosts(classtable.RainofFire, 'RainofFire')) and (SoulShards >= ( 4.5 - 0.1 * debuff[classtable.ImmolateDeBuff].count  ) and timeInCombat >5) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (CheckSpellCosts(classtable.Shadowburn, 'Shadowburn')) and (ttd <5 and targetHP <20) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (SoulShards >3.5 - ( 0.1 * targets ) and not talents[classtable.RainofFire]) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.Cataclysm, 'Cataclysm')) and (math.huge >15) and cooldown[classtable.Cataclysm].ready then
        return classtable.Cataclysm
    end
    if (CheckSpellCosts(classtable.Havoc, 'Havoc')) and (( not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal] or ( talents[classtable.Inferno] and targets >4 ) ) and ttd >8) and cooldown[classtable.Havoc].ready then
        return classtable.Havoc
    end
    if (CheckSpellCosts(classtable.Immolate, 'Immolate')) and (debuff[classtable.ImmolateDeBuff].refreshable and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains ) and ( not talents[classtable.RagingDemonfire] or cooldown[classtable.ChannelDemonfire].remains >debuff[classtable.ImmolateDeBuff].remains or timeInCombat <5 ) and debuff[classtable.ImmolateDeBuff].count  <= 4 and ttd >18) and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    if (CheckSpellCosts(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (debuff[classtable.ImmolateDeBuff].remains >( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 ) and talents[classtable.RagingDemonfire]) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    local ogcdCheck = Destruction:ogcd()
    if ogcdCheck then
        return ogcdCheck
    end
    if (CheckSpellCosts(classtable.SummonInfernal, 'SummonInfernal')) and (cooldown[classtable.InvokePowerInfusion0].ready or cooldown[classtable.InvokePowerInfusion0].duration == 0 or ttd >= 190 and not talents[classtable.GrandWarlocksDesign]) and cooldown[classtable.SummonInfernal].ready then
        MaxDps:GlowCooldown(classtable.SummonInfernal, cooldown[classtable.SummonInfernal].ready)
    end
    if (CheckSpellCosts(classtable.RainofFire, 'RainofFire')) and (not debuff[classtable.PyrogenicsDeBuff].up and targets <= 4) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (CheckSpellCosts(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (debuff[classtable.ImmolateDeBuff].remains >( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 )) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (CheckSpellCosts(classtable.Immolate, 'Immolate')) and (( ( debuff[classtable.ImmolateDeBuff].refreshable and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains ) )  ) and ttd >10 and not havoc_active) and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    if (CheckSpellCosts(classtable.DimensionalRift, 'DimensionalRift')) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (CheckSpellCosts(classtable.SoulFire, 'SoulFire')) and (buff[classtable.BackdraftBuff].up) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (CheckSpellCosts(classtable.Incinerate, 'Incinerate')) and (talents[classtable.FireandBrimstone] and buff[classtable.BackdraftBuff].up) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
    if (CheckSpellCosts(classtable.Conflagrate, 'Conflagrate')) and (buff[classtable.BackdraftBuff].count <2 or not talents[classtable.Backdraft]) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (CheckSpellCosts(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
end
function Destruction:cleave()
    local itemsCheck = Destruction:items()
    if itemsCheck then
        return itemsCheck
    end
    local ogcdCheck = Destruction:ogcd()
    if ogcdCheck then
        return ogcdCheck
    end
    if (havoc_active and havoc_remains >gcd) then
        local havocCheck = Destruction:havoc()
        if havocCheck then
            return Destruction:havoc()
        end
    end
    pool_soul_shards = cooldown[classtable.Havoc].remains <= 10 or talents[classtable.Mayhem]
    if (CheckSpellCosts(classtable.Conflagrate, 'Conflagrate')) and (( talents[classtable.RoaringBlaze] and debuff[classtable.ConflagrateDeBuff].remains <1.5 ) or cooldown[classtable.Conflagrate].charges == cooldown[classtable.Conflagrate].maxCharges and not pool_soul_shards) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (CheckSpellCosts(classtable.DimensionalRift, 'DimensionalRift')) and (SoulShards <4.7 and ( cooldown[classtable.DimensionalRift].charges >2 or boss and ttd <cooldown[classtable.DimensionalRift].duration )) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (CheckSpellCosts(classtable.Cataclysm, 'Cataclysm')) and (math.huge >15) and cooldown[classtable.Cataclysm].ready then
        return classtable.Cataclysm
    end
    if (CheckSpellCosts(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (talents[classtable.RagingDemonfire] and debuff[classtable.ImmolateDeBuff].count  == 2) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (CheckSpellCosts(classtable.SoulFire, 'SoulFire')) and (SoulShards <= 3.5 and ( debuff[classtable.ConflagrateDeBuff].remains >( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime /1000 ) + 1 or not talents[classtable.RoaringBlaze] and buff[classtable.BackdraftBuff].up ) and not pool_soul_shards) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (CheckSpellCosts(classtable.Immolate, 'Immolate')) and (( debuff[classtable.ImmolateDeBuff].refreshable and ( debuff[classtable.ImmolateDeBuff].remains <cooldown[classtable.Havoc].remains or not debuff[classtable.ImmolateDeBuff].up ) ) and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains ) and ( not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( (not (talents[classtable.Mayhem] and talents[classtable.Mayhem]) and 1 or 0) * ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 )) >debuff[classtable.ImmolateDeBuff].remains ) and ttd >15) and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    if (CheckSpellCosts(classtable.Havoc, 'Havoc')) and (( not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal] ) and ttd >8) and cooldown[classtable.Havoc].ready then
        return classtable.Havoc
    end
    if (CheckSpellCosts(classtable.DimensionalRift, 'DimensionalRift')) and (SoulShards <4.5 and pool_soul_shards) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (( UnitExists('pet') and UnitName('pet')  == 'infernal' ) or ( UnitExists('pet') and UnitName('pet')  == 'blasphemy' ) or SoulShards >= 4) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.SummonInfernal, 'SummonInfernal')) and cooldown[classtable.SummonInfernal].ready then
        MaxDps:GlowCooldown(classtable.SummonInfernal, cooldown[classtable.SummonInfernal].ready)
    end
    if (CheckSpellCosts(classtable.ChannelDemonfire, 'ChannelDemonfire')) and ((talents[classtable.Ruin] and talents[classtable.Ruin] or 0) >1 and not ( talents[classtable.DiabolicEmbers] and talents[classtable.AvatarofDestruction] and ( talents[classtable.BurnToAshes] or talents[classtable.ChaosIncarnate] ) )) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (CheckSpellCosts(classtable.Shadowburn, 'Shadowburn')) and (ttd <5 and targetHP <20) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (SoulShards >3.5) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (buff[classtable.RainofChaosBuff].remains >( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime /1000 )) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (buff[classtable.BackdraftBuff].up) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.SoulFire, 'SoulFire')) and (SoulShards <= 4 and talents[classtable.Mayhem]) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (talents[classtable.Eradication] and debuff[classtable.EradicationDeBuff].remains <( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime /1000 ) + 1 + 1 and not (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 )) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (not ( talents[classtable.DiabolicEmbers] and talents[classtable.AvatarofDestruction] and ( talents[classtable.BurnToAshes] or talents[classtable.ChaosIncarnate] ) )) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (CheckSpellCosts(classtable.DimensionalRift, 'DimensionalRift')) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (SoulShards >3.5 and not pool_soul_shards) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (boss and ttd <5 and ttd >( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime /1000 ) + 1) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.Conflagrate, 'Conflagrate')) and (cooldown[classtable.Conflagrate].charges >( cooldown[classtable.Conflagrate].maxCharges - 1 ) or boss and ttd <gcd * cooldown[classtable.Conflagrate].charges) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (CheckSpellCosts(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
end
function Destruction:havoc()
    if (CheckSpellCosts(classtable.Conflagrate, 'Conflagrate')) and (talents[classtable.Backdraft] and not buff[classtable.BackdraftBuff].up and SoulShards >= 1 and SoulShards <= 4) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (CheckSpellCosts(classtable.SoulFire, 'SoulFire')) and (( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime /1000 ) <havoc_remains and SoulShards <2.5) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (CheckSpellCosts(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (SoulShards <4.5 and (talents[classtable.RagingDemonfire] and talents[classtable.RagingDemonfire] or 0) == 2) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (CheckSpellCosts(classtable.Immolate, 'Immolate')) and (debuff[classtable.ImmolateDeBuff].remains <2 and debuff[classtable.ImmolateDeBuff].remains <havoc_remains and ttd >11 and SoulShards <4.5) and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    if (CheckSpellCosts(classtable.Shadowburn, 'Shadowburn')) and (ttd <5 and targetHP <20) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (( ( talents[classtable.CryHavoc] and not talents[classtable.Inferno] ) or not talents[classtable.RainofFire] ) and ( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime /1000 ) <havoc_remains) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime /1000 ) <havoc_remains and ( targets <= 3 - (talents[classtable.Inferno] and talents[classtable.Inferno] or 0) + ( talents[classtable.Chaosbringer] and not talents[classtable.Inferno] and 1 or 0) )) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.RainofFire, 'RainofFire')) and (targets >= 3 and talents[classtable.Inferno]) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (CheckSpellCosts(classtable.RainofFire, 'RainofFire')) and (( targets >= 4 - (talents[classtable.Inferno] and talents[classtable.Inferno] or 0) + (talents[classtable.Chaosbringer] and talents[classtable.Chaosbringer] or 0) )) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (CheckSpellCosts(classtable.RainofFire, 'RainofFire')) and (targets >2 and ( talents[classtable.AvatarofDestruction] or ( talents[classtable.RainofChaos] and buff[classtable.RainofChaosBuff].up ) ) and talents[classtable.Inferno]) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    if (CheckSpellCosts(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (SoulShards <4.5) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (CheckSpellCosts(classtable.Conflagrate, 'Conflagrate')) and (not talents[classtable.Backdraft]) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (CheckSpellCosts(classtable.DimensionalRift, 'DimensionalRift')) and (SoulShards <4.7 and ( cooldown[classtable.DimensionalRift].charges >2 or boss and ttd <cooldown[classtable.DimensionalRift].duration )) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (CheckSpellCosts(classtable.Incinerate, 'Incinerate')) and (( classtable and classtable.Incinerate and GetSpellInfo(classtable.Incinerate).castTime /1000 ) <havoc_remains) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
end
function Destruction:items()
end
function Destruction:ogcd()
end

function Destruction:callaction()
    if (CheckSpellCosts(classtable.SpellLock, 'SpellLock')) and cooldown[classtable.SpellLock].ready then
        MaxDps:GlowCooldown(classtable.SpellLock, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    infernal_active = ( UnitExists('pet') and UnitName('pet')  == 'infernal' ) or ( cooldown[classtable.SummonInfernal].duration - cooldown[classtable.SummonInfernal].remains ) <20
    aoe_condition = ( targets >= 3 - ( talents[classtable.Inferno] and not talents[classtable.Chaosbringer] and 1 or 0) ) and not ( not talents[classtable.Inferno] and talents[classtable.Chaosbringer] and talents[classtable.ChaosIncarnate] and targets <4 ) and not cleave_apl
    cleave_condition = targets >1 or cleave_apl
    if (aoe_condition) then
        local aoeCheck = Destruction:aoe()
        if aoeCheck then
            return Destruction:aoe()
        end
    end
    if (cleave_condition) then
        local cleaveCheck = Destruction:cleave()
        if cleaveCheck then
            return Destruction:cleave()
        end
    end
    if (not aoe_condition and not cleave_condition) then
        local ogcdCheck = Destruction:ogcd()
        if ogcdCheck then
            return Destruction:ogcd()
        end
    end
    if (not aoe_condition and not cleave_condition) then
        local itemsCheck = Destruction:items()
        if itemsCheck then
            return Destruction:items()
        end
    end
    if (CheckSpellCosts(classtable.Conflagrate, 'Conflagrate')) and (( talents[classtable.RoaringBlaze] and debuff[classtable.ConflagrateDeBuff].remains <1.5 ) and SoulShards >1.5 or cooldown[classtable.Conflagrate].charges == cooldown[classtable.Conflagrate].maxCharges) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (CheckSpellCosts(classtable.DimensionalRift, 'DimensionalRift')) and (SoulShards <4.7 and ( cooldown[classtable.DimensionalRift].charges >2 or boss and ttd <cooldown[classtable.DimensionalRift].duration )) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (CheckSpellCosts(classtable.Cataclysm, 'Cataclysm')) and (math.huge >15) and cooldown[classtable.Cataclysm].ready then
        return classtable.Cataclysm
    end
    if (CheckSpellCosts(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (talents[classtable.RagingDemonfire] and ( debuff[classtable.ImmolateDeBuff].remains - 5 * ( (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 ) and talents[classtable.InternalCombustion] ) ) >( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 ) and ( debuff[classtable.ConflagrateDeBuff].remains >timeShift or not talents[classtable.RoaringBlaze] )) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (CheckSpellCosts(classtable.SoulFire, 'SoulFire')) and (SoulShards <= 3.5 and ( debuff[classtable.ConflagrateDeBuff].remains >( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime /1000 ) + 1 or not talents[classtable.RoaringBlaze] and buff[classtable.BackdraftBuff].up )) and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    if (CheckSpellCosts(classtable.Immolate, 'Immolate')) and (( ( ( debuff[classtable.ImmolateDeBuff].remains - 5 * ( (classtable and classtable.ChaosBolt and GetSpellCooldown(classtable.ChaosBolt).duration >=5 ) and talents[classtable.InternalCombustion] ) ) <debuff[classtable.ImmolateDeBuff].duration * 0.3 ) or debuff[classtable.ImmolateDeBuff].remains <3 or ( debuff[classtable.ImmolateDeBuff].remains - 2 ) <5 and talents[classtable.InternalCombustion] and cooldown[classtable.ChaosBolt].ready ) and ( not talents[classtable.Cataclysm] or cooldown[classtable.Cataclysm].remains >debuff[classtable.ImmolateDeBuff].remains ) and ( not talents[classtable.SoulFire] or cooldown[classtable.SoulFire].remains + ( classtable and classtable.SoulFire and GetSpellInfo(classtable.SoulFire).castTime / 1000 ) >( debuff[classtable.ImmolateDeBuff].remains - 5 * (talents[classtable.InternalCombustion] and talents[classtable.InternalCombustion] or 0) ) ) and ttd >8) and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    if (CheckSpellCosts(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (debuff[classtable.ImmolateDeBuff].remains >( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 ) and (MaxDps.tier and MaxDps.tier[30].count >= 4)) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (cooldown[classtable.SummonInfernal].remains == 0 and SoulShards >4 and talents[classtable.CrashingChaos]) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.SummonInfernal, 'SummonInfernal')) and cooldown[classtable.SummonInfernal].ready then
        MaxDps:GlowCooldown(classtable.SummonInfernal, cooldown[classtable.SummonInfernal].ready)
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (( UnitExists('pet') and UnitName('pet')  == 'infernal' ) or ( UnitExists('pet') and UnitName('pet')  == 'blasphemy' ) or SoulShards >= 4) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.ChannelDemonfire, 'ChannelDemonfire')) and ((talents[classtable.Ruin] and talents[classtable.Ruin] or 0) >1 and not ( talents[classtable.DiabolicEmbers] and talents[classtable.AvatarofDestruction] and ( talents[classtable.BurnToAshes] or talents[classtable.ChaosIncarnate] ) ) and debuff[classtable.ImmolateDeBuff].remains >( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 )) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (CheckSpellCosts(classtable.Shadowburn, 'Shadowburn')) and (ttd <5 and targetHP <20) and cooldown[classtable.Shadowburn].ready then
        return classtable.Shadowburn
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (buff[classtable.RainofChaosBuff].remains >( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime /1000 )) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (buff[classtable.BackdraftBuff].up) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.ChannelDemonfire, 'ChannelDemonfire')) and (not ( talents[classtable.DiabolicEmbers] and talents[classtable.AvatarofDestruction] and ( talents[classtable.BurnToAshes] or talents[classtable.ChaosIncarnate] ) ) and debuff[classtable.ImmolateDeBuff].remains >( classtable and classtable.ChannelDemonfire and GetSpellInfo(classtable.ChannelDemonfire).castTime /1000 )) and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    if (CheckSpellCosts(classtable.DimensionalRift, 'DimensionalRift')) and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    if (CheckSpellCosts(classtable.ChaosBolt, 'ChaosBolt')) and (boss and ttd <5 and ttd >( classtable and classtable.ChaosBolt and GetSpellInfo(classtable.ChaosBolt).castTime /1000 ) + 1) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    if (CheckSpellCosts(classtable.Conflagrate, 'Conflagrate')) and (cooldown[classtable.Conflagrate].charges >( cooldown[classtable.Conflagrate].maxCharges - 1 ) or boss and ttd <gcd * cooldown[classtable.Conflagrate].charges) and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    if (CheckSpellCosts(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
    local ogcdCheck = Destruction:ogcd()
    if ogcdCheck then
        return ogcdCheck
    end
    local itemsCheck = Destruction:items()
    if itemsCheck then
        return itemsCheck
    end
    if (havoc_active and havoc_remains >gcd and targets <5 + ( talents[classtable.CryHavoc] and not talents[classtable.Inferno] ) and ( not cooldown[classtable.SummonInfernal].ready or not talents[classtable.SummonInfernal] )) then
        local havocCheck = Destruction:havoc()
        if havocCheck then
            return Destruction:havoc()
        end
    end
    local ogcdCheck = Destruction:ogcd()
    if ogcdCheck then
        return ogcdCheck
    end
    local itemsCheck = Destruction:items()
    if itemsCheck then
        return itemsCheck
    end
    local ogcdCheck = Destruction:ogcd()
    if ogcdCheck then
        return ogcdCheck
    end
    if (havoc_active and havoc_remains >gcd) then
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
    local havoc_count, havoc_totalRemains = MaxDps:DebuffCounter(classtable.Havoc,1)
    havoc_active = havoc_count >= 1
    havoc_remains = havoc_totalRemains or 0
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.ImmolateDeBuff = 157736
    classtable.PyrogenicsDeBuff = 387096
    classtable.BackdraftBuff = 117828
    classtable.ConflagrateDeBuff = 0
    classtable.RainofChaosBuff = 266087
    classtable.EradicationDeBuff = 196414

    local precombatCheck = Destruction:precombat()
    if precombatCheck then
        return Destruction:precombat()
    end

    local callactionCheck = Destruction:callaction()
    if callactionCheck then
        return Destruction:callaction()
    end
end
