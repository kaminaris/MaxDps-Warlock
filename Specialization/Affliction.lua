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

local Affliction = {}

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
local ps_up
local vt_up
local vt_ps_up
local sr_up
local cd_dots_up
local has_cds
local cds_active
local min_vt
local min_ps
local min_agony
local min_psone
local ShadowEmbraceDeBuffmaxStacks

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
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



local function CheckEquipped(checkName)
    for i=1,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = itemID and C_Item.GetItemInfo(itemID) or ''
        if checkName == itemName then
            return true
        end
    end
    return false
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


function Affliction:precombat()
    --if (MaxDps:FindSpell(classtable.FelDomination) and CheckSpellCosts(classtable.FelDomination, 'FelDomination')) and (timeInCombat >0 and not UnitExists('pet')) and cooldown[classtable.FelDomination].ready then
    --    return classtable.FelDomination
    --end
    --if (MaxDps:FindSpell(classtable.GrimoireofSacrifice) and CheckSpellCosts(classtable.GrimoireofSacrifice, 'GrimoireofSacrifice')) and (talents[classtable.GrimoireofSacrifice]) and cooldown[classtable.GrimoireofSacrifice].ready then
    --    return classtable.GrimoireofSacrifice
    --end
    --if (MaxDps:FindSpell(classtable.SeedofCorruption) and CheckSpellCosts(classtable.SeedofCorruption, 'SeedofCorruption')) and (targets >2 or talents[classtable.SowtheSeeds] and targets >1) and cooldown[classtable.SeedofCorruption].ready then
    --    return classtable.SeedofCorruption
    --end
    --if (MaxDps:FindSpell(classtable.Haunt) and CheckSpellCosts(classtable.Haunt, 'Haunt')) and cooldown[classtable.Haunt].ready then
    --    return classtable.Haunt
    --end
    --if (MaxDps:FindSpell(classtable.UnstableAffliction) and CheckSpellCosts(classtable.UnstableAffliction, 'UnstableAffliction')) and (not talents[classtable.SoulSwap]) and cooldown[classtable.UnstableAffliction].ready then
    --    return classtable.UnstableAffliction
    --end
    --if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
    --    return classtable.ShadowBolt
    --end
end
function Affliction:aoe()
    if (MaxDps:FindSpell(classtable.Haunt) and CheckSpellCosts(classtable.Haunt, 'Haunt')) and (debuff[classtable.HauntDeBuff].remains <3) and cooldown[classtable.Haunt].ready then
        return classtable.Haunt
    end
    if (MaxDps:FindSpell(classtable.VileTaint) and CheckSpellCosts(classtable.VileTaint, 'VileTaint')) and (( (talents[classtable.SouleatersGluttony] and talents[classtable.SouleatersGluttony] or 0) == 2 and ( min_agony <1.5 or cooldown[classtable.SoulRot].remains <= timeShift ) ) or ( ( (talents[classtable.SouleatersGluttony] and talents[classtable.SouleatersGluttony] or 0) == 1 and cooldown[classtable.SoulRot].remains <= timeShift ) ) or ( (talents[classtable.SouleatersGluttony] and talents[classtable.SouleatersGluttony] or 0) == 0 and ( cooldown[classtable.SoulRot].remains <= timeShift or cooldown[classtable.VileTaint].remains >25 ) )) and cooldown[classtable.VileTaint].ready then
        return classtable.VileTaint
    end
    if (MaxDps:FindSpell(classtable.PhantomSingularity) and CheckSpellCosts(classtable.PhantomSingularity, 'PhantomSingularity')) and (( cooldown[classtable.SoulRot].remains <= timeShift or (talents[classtable.SouleatersGluttony] and talents[classtable.SouleatersGluttony] or 0) <1 and ( not talents[classtable.SoulRot] or cooldown[classtable.SoulRot].remains <= timeShift or cooldown[classtable.SoulRot].remains >= 25 ) ) and debuff[classtable.AgonyDeBuff].up) and cooldown[classtable.PhantomSingularity].ready then
        return classtable.PhantomSingularity
    end
    if (MaxDps:FindSpell(classtable.UnstableAffliction) and CheckSpellCosts(classtable.UnstableAffliction, 'UnstableAffliction')) and (debuff[classtable.UnstableAfflictionDeBuff].refreshable) and cooldown[classtable.UnstableAffliction].ready then
        return classtable.UnstableAffliction
    end
    if (MaxDps:FindSpell(classtable.Agony) and CheckSpellCosts(classtable.Agony, 'Agony')) and (debuff[classtable.AgonyDebuff].count <8 and ( (debuff[classtable.AgonyDeBuff].remains <cooldown[classtable.VileTaint].remains and 1 or 0) + ( classtable and classtable.VileTaint and GetSpellInfo(classtable.VileTaint).castTime / 1000 and 1 or 0 ) or not talents[classtable.VileTaint] ) and ( gcd + ( classtable and classtable.SoulRot and GetSpellInfo(classtable.SoulRot).castTime / 1000 or 0) + gcd ) <( ( min_vt * (talents[classtable.VileTaint] and talents[classtable.VileTaint] or 0) ) <( min_ps * (talents[classtable.PhantomSingularity] and talents[classtable.PhantomSingularity] or 0) ) and 1 or 0) and debuff[classtable.AgonyDeBuff].remains <5) and cooldown[classtable.Agony].ready then
        return classtable.Agony
    end
    if (MaxDps:FindSpell(classtable.SiphonLife) and CheckSpellCosts(classtable.SiphonLife, 'SiphonLife')) and (debuff[classtable.SiphonLifeDeBuff].count  <6 and cooldown[classtable.SummonDarkglare].ready and timeInCombat <20 and ( gcd + ( classtable and classtable.SoulRot and GetSpellInfo(classtable.SoulRot).castTime / 1000 ) + gcd ) <( ( min_vt * (talents[classtable.VileTaint] and talents[classtable.VileTaint] or 0) ) <( min_ps * (talents[classtable.PhantomSingularity] and talents[classtable.PhantomSingularity] or 0) ) ) and debuff[classtable.AgonyDeBuff].up) and cooldown[classtable.SiphonLife].ready then
        return classtable.SiphonLife
    end
    if (MaxDps:FindSpell(classtable.SoulRot) and CheckSpellCosts(classtable.SoulRot, 'SoulRot')) and (vt_up and ( ps_up or talents[classtable.SouleatersGluttony] ~= 1 ) and debuff[classtable.AgonyDeBuff].up) and cooldown[classtable.SoulRot].ready then
        return classtable.SoulRot
    end
    if (MaxDps:FindSpell(classtable.SeedofCorruption) and CheckSpellCosts(classtable.SeedofCorruption, 'SeedofCorruption')) and (debuff[classtable.CorruptionDeBuff].remains <5 and not ( (classtable and classtable.SeedofCorruption and GetSpellCooldown(classtable.SeedofCorruption).duration >=5 ) or debuff[classtable.SeedofCorruptionDeBuff].remains >0 )) and cooldown[classtable.SeedofCorruption].ready then
        return classtable.SeedofCorruption
    end
    if (MaxDps:FindSpell(classtable.Corruption) and CheckSpellCosts(classtable.Corruption, 'Corruption')) and (debuff[classtable.CorruptionDeBuff].remains <5 and not talents[classtable.SeedofCorruption]) and cooldown[classtable.Corruption].ready then
        return classtable.Corruption
    end
    if (MaxDps:FindSpell(classtable.SummonDarkglare) and CheckSpellCosts(classtable.SummonDarkglare, 'SummonDarkglare')) and (ps_up and vt_up and sr_up) and cooldown[classtable.SummonDarkglare].ready then
        return classtable.SummonDarkglare
    end
    if (MaxDps:FindSpell(classtable.DrainLife) and CheckSpellCosts(classtable.DrainLife, 'DrainLife')) and (buff[classtable.InevitableDemiseBuff].count >30 and buff[classtable.SoulRotBuff].up and buff[classtable.SoulRotBuff].remains <= gcd and targets >3) and cooldown[classtable.DrainLife].ready then
        return classtable.DrainLife
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (buff[classtable.UmbrafireKindlingBuff].up and ( ( ( targets <6 or timeInCombat <30 ) and ( UnitExists('pet') and UnitName('pet')  == 'darkglare' ) ) or not talents[classtable.DoomBlossom] )) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.SeedofCorruption) and CheckSpellCosts(classtable.SeedofCorruption, 'SeedofCorruption')) and (talents[classtable.SowtheSeeds]) and cooldown[classtable.SeedofCorruption].ready then
        return classtable.SeedofCorruption
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (( ( cooldown[classtable.SummonDarkglare].remains >15 or SoulShards >3 ) and not talents[classtable.SowtheSeeds] ) or buff[classtable.TormentedCrescendoBuff].up) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.DrainLife) and CheckSpellCosts(classtable.DrainLife, 'DrainLife')) and (( buff[classtable.SoulRotBuff].up or not talents[classtable.SoulRot] ) and buff[classtable.InevitableDemiseBuff].count >30) and cooldown[classtable.DrainLife].ready then
        return classtable.DrainLife
    end
    if (MaxDps:FindSpell(classtable.DrainSoul) and CheckSpellCosts(classtable.DrainSoul, 'DrainSoul')) and (buff[classtable.NightfallBuff].up and talents[classtable.ShadowEmbrace] and ( ShadowEmbraceDeBuffmaxStacks / debuff[classtable.ShadowEmbraceDeBuff].count * 100 <100 or debuff[classtable.ShadowEmbraceDeBuff].remains <3 )) and cooldown[classtable.DrainSoul].ready then
        return classtable.DrainSoul
    end
    if (MaxDps:FindSpell(classtable.SiphonLife) and CheckSpellCosts(classtable.SiphonLife, 'SiphonLife')) and (debuff[classtable.SiphonLifeDeBuff].remains <5 and debuff[classtable.SiphonLifeDeBuff].count  <5 and ( targets <8 or not talents[classtable.DoomBlossom] )) and cooldown[classtable.SiphonLife].ready then
        return classtable.SiphonLife
    end
    if (MaxDps:FindSpell(classtable.DrainSoul) and CheckSpellCosts(classtable.DrainSoul, 'DrainSoul')) and (( talents[classtable.ShadowEmbrace] and ( ShadowEmbraceDeBuffmaxStacks / debuff[classtable.ShadowEmbraceDeBuff].count * 100 <100 or debuff[classtable.ShadowEmbraceDeBuff].remains <3 ) ) or not talents[classtable.ShadowEmbrace]) and cooldown[classtable.DrainSoul].ready then
        return classtable.DrainSoul
    end
    if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
    end
end
function Affliction:cleave()
    if (MaxDps:FindSpell(classtable.VileTaint) and CheckSpellCosts(classtable.VileTaint, 'VileTaint')) and (not talents[classtable.SoulRot] or ( min_agony <1.5 or cooldown[classtable.SoulRot].remains <= timeShift + gcd ) or (talents[classtable.SouleatersGluttony] and talents[classtable.SouleatersGluttony] or 0) <1 and cooldown[classtable.SoulRot].remains >= 12) and cooldown[classtable.VileTaint].ready then
        return classtable.VileTaint
    end
    if (MaxDps:FindSpell(classtable.PhantomSingularity) and CheckSpellCosts(classtable.PhantomSingularity, 'PhantomSingularity')) and (( cooldown[classtable.SoulRot].remains <= timeShift or (talents[classtable.SouleatersGluttony] and talents[classtable.SouleatersGluttony] or 0) <1 and ( not talents[classtable.SoulRot] or cooldown[classtable.SoulRot].remains <= timeShift or cooldown[classtable.SoulRot].remains >= 25 ) ) and debuff[classtable.AgonyDeBuff].count  == 2) and cooldown[classtable.PhantomSingularity].ready then
        return classtable.PhantomSingularity
    end
    if (MaxDps:FindSpell(classtable.SoulRot) and CheckSpellCosts(classtable.SoulRot, 'SoulRot')) and (( vt_up and ( ps_up or talents[classtable.SouleatersGluttony] ~= 1 ) ) and debuff[classtable.AgonyDeBuff].count  == 2) and cooldown[classtable.SoulRot].ready then
        return classtable.SoulRot
    end
    if (MaxDps:FindSpell(classtable.Agony) and CheckSpellCosts(classtable.Agony, 'Agony')) and (( debuff[classtable.AgonyDeBuff].remains <cooldown[classtable.VileTaint].remains + ( classtable and classtable.VileTaint and GetSpellInfo(classtable.VileTaint).castTime / 1000 ) or not talents[classtable.VileTaint] ) and debuff[classtable.AgonyDeBuff].remains <5 and ttd >5) and cooldown[classtable.Agony].ready then
        return classtable.Agony
    end
    if (MaxDps:FindSpell(classtable.UnstableAffliction) and CheckSpellCosts(classtable.UnstableAffliction, 'UnstableAffliction')) and (( debuff[classtable.UnstableAfflictionDeBuff].refreshable ) and ttd >3) and cooldown[classtable.UnstableAffliction].ready then
        return classtable.UnstableAffliction
    end
    if (MaxDps:FindSpell(classtable.SeedofCorruption) and CheckSpellCosts(classtable.SeedofCorruption, 'SeedofCorruption')) and (not talents[classtable.AbsoluteCorruption] and debuff[classtable.CorruptionDeBuff].remains <5 and talents[classtable.SowtheSeeds] ) and cooldown[classtable.SeedofCorruption].ready then
        return classtable.SeedofCorruption
    end
    if (MaxDps:FindSpell(classtable.Haunt) and CheckSpellCosts(classtable.Haunt, 'Haunt')) and (debuff[classtable.HauntDeBuff].remains <3) and cooldown[classtable.Haunt].ready then
        return classtable.Haunt
    end
    if (MaxDps:FindSpell(classtable.Corruption) and CheckSpellCosts(classtable.Corruption, 'Corruption')) and (debuff[classtable.CorruptionDeBuff].remains <5 and not ( (classtable and classtable.SeedofCorruption and GetSpellCooldown(classtable.SeedofCorruption).duration >=5 ) or debuff[classtable.SeedofCorruptionDeBuff].remains >0 ) and ttd >5) and cooldown[classtable.Corruption].ready then
        return classtable.Corruption
    end
    if (MaxDps:FindSpell(classtable.SiphonLife) and CheckSpellCosts(classtable.SiphonLife, 'SiphonLife')) and (debuff[classtable.SiphonLifeDeBuff].refreshable and ttd >5) and cooldown[classtable.SiphonLife].ready then
        return classtable.SiphonLife
    end
    if (MaxDps:FindSpell(classtable.SummonDarkglare) and CheckSpellCosts(classtable.SummonDarkglare, 'SummonDarkglare')) and (( not talents[classtable.ShadowEmbrace] or ShadowEmbraceDeBuffmaxStacks / debuff[classtable.ShadowEmbraceDeBuff].count * 100 == 100 ) and ps_up and vt_up and sr_up) and cooldown[classtable.SummonDarkglare].ready then
        return classtable.SummonDarkglare
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].count == 1 and SoulShards >3) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.DrainSoul) and CheckSpellCosts(classtable.DrainSoul, 'DrainSoul')) and (talents[classtable.ShadowEmbrace] and ( ShadowEmbraceDeBuffmaxStacks / debuff[classtable.ShadowEmbraceDeBuff].count * 100 <100 or debuff[classtable.ShadowEmbraceDeBuff].remains <3 )) and cooldown[classtable.DrainSoul].ready then
        return classtable.DrainSoul
    end
    if (MaxDps:FindSpell(classtable.DrainSoul) and CheckSpellCosts(classtable.DrainSoul, 'DrainSoul')) and (buff[classtable.NightfallBuff].up and ( talents[classtable.ShadowEmbrace] and ( ShadowEmbraceDeBuffmaxStacks / debuff[classtable.ShadowEmbraceDeBuff].count * 100 <100 or debuff[classtable.ShadowEmbraceDeBuff].remains <3 ) or not talents[classtable.ShadowEmbrace] )) and cooldown[classtable.DrainSoul].ready then
        return classtable.DrainSoul
    end
    if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and (buff[classtable.NightfallBuff].up and ( talents[classtable.ShadowEmbrace] and ( ShadowEmbraceDeBuffmaxStacks / debuff[classtable.ShadowEmbraceDeBuff].count * 100 <100 or debuff[classtable.ShadowEmbraceDeBuff].remains <3 ) or not talents[classtable.ShadowEmbrace] )) and cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (buff[classtable.TormentedCrescendoBuff].up) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (cd_dots_up or vt_ps_up) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (SoulShards >3) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.DrainLife) and CheckSpellCosts(classtable.DrainLife, 'DrainLife')) and (buff[classtable.InevitableDemiseBuff].count >48 or buff[classtable.InevitableDemiseBuff].count >20 and boss and ttd <4) and cooldown[classtable.DrainLife].ready then
        return classtable.DrainLife
    end
    if (MaxDps:FindSpell(classtable.DrainLife) and CheckSpellCosts(classtable.DrainLife, 'DrainLife')) and (buff[classtable.SoulRotBuff].up and buff[classtable.InevitableDemiseBuff].count >30) and cooldown[classtable.DrainLife].ready then
        return classtable.DrainLife
    end
    if (MaxDps:FindSpell(classtable.Agony) and CheckSpellCosts(classtable.Agony, 'Agony')) and (debuff[classtable.AgonyDeBuff].refreshable) and cooldown[classtable.Agony].ready then
        return classtable.Agony
    end
    if (MaxDps:FindSpell(classtable.Corruption) and CheckSpellCosts(classtable.Corruption, 'Corruption')) and (debuff[classtable.CorruptionDeBuff].refreshable) and cooldown[classtable.Corruption].ready then
        return classtable.Corruption
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (SoulShards >1) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.DrainSoul) and CheckSpellCosts(classtable.DrainSoul, 'DrainSoul')) and cooldown[classtable.DrainSoul].ready then
        return classtable.DrainSoul
    end
    if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
    end
end
function Affliction:items()
end
function Affliction:ogcd()
end

function Affliction:callaction()
    if (MaxDps:FindSpell(classtable.SpellLock) and CheckSpellCosts(classtable.SpellLock, 'SpellLock')) and cooldown[classtable.SpellLock].ready then
        MaxDps:GlowCooldown(classtable.SpellLock, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    ps_up = debuff[classtable.PhantomSingularityDeBuff].count  >0 or cooldown[classtable.PhantomSingularity].remains >35 or not talents[classtable.PhantomSingularity]
    vt_up = debuff[classtable.VileTaintDotDeBuff].count  >0 or cooldown[classtable.VileTaint].remains >20 or not talents[classtable.VileTaint]
    vt_ps_up = debuff[classtable.VileTaintDotDeBuff].count  >0 or cooldown[classtable.VileTaint].remains >20 or debuff[classtable.PhantomSingularityDeBuff].count  >0 or cooldown[classtable.PhantomSingularity].remains >35 or ( not talents[classtable.VileTaint] and not talents[classtable.PhantomSingularity] )
    sr_up = debuff[classtable.SoulRotDeBuff].up or cooldown[classtable.SoulRot].remains >48 or not talents[classtable.SoulRot]
    cd_dots_up = ps_up and vt_up and sr_up
    has_cds = talents[classtable.PhantomSingularity] or talents[classtable.VileTaint] or talents[classtable.SoulRot] or talents[classtable.SummonDarkglare]
    cds_active = not has_cds or ( cd_dots_up and ( cooldown[classtable.SummonDarkglare].remains >20 or not talents[classtable.SummonDarkglare] ) )
    if min_vt then
        min_vt = 10
    end
    if min_ps then
        min_ps = 16
    end
    min_agony = debuff[classtable.AgonyDeBuff].remains + ( 99 * (not debuff[classtable.AgonyDeBuff].up and 0 or 1) )
    if targets >2 then
        min_vt = debuff[classtable.VileTaintDeBuff].remains + ( 99 * (not debuff[classtable.VileTaintDeBuff].up and 0 or 1))
    end
    if targets >2 then
        min_ps = debuff[classtable.PhantomSingularityDeBuff].remains + ( 99 * (not debuff[classtable.PhantomSingularityDeBuff].up and 0 or 1))
    end
    if targets >2 then
        min_psone = ( min_vt * (talents[classtable.VileTaint] and talents[classtable.VileTaint] or 0) <min_ps * (talents[classtable.PhantomSingularity] and talents[classtable.PhantomSingularity] or 0) )
    end
    local ogcdCheck = Affliction:ogcd()
    if ogcdCheck then
        return ogcdCheck
    end
    local itemsCheck = Affliction:items()
    if itemsCheck then
        return itemsCheck
    end
    if (targets == 2) then
        local cleaveCheck = Affliction:cleave()
        if cleaveCheck then
            return Affliction:cleave()
        end
    end
    if (targets >2) then
        local aoeCheck = Affliction:aoe()
        if aoeCheck then
            return Affliction:aoe()
        end
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (boss and ttd <4) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.VileTaint) and CheckSpellCosts(classtable.VileTaint, 'VileTaint')) and (not talents[classtable.SoulRot] or ( min_agony <1.5 or cooldown[classtable.SoulRot].remains <= timeShift + gcd ) or (talents[classtable.SouleatersGluttony] and talents[classtable.SouleatersGluttony] or 0) <1 and cooldown[classtable.SoulRot].remains >= 12) and cooldown[classtable.VileTaint].ready then
        return classtable.VileTaint
    end
    if (MaxDps:FindSpell(classtable.PhantomSingularity) and CheckSpellCosts(classtable.PhantomSingularity, 'PhantomSingularity')) and (( cooldown[classtable.SoulRot].remains <= timeShift or (talents[classtable.SouleatersGluttony] and talents[classtable.SouleatersGluttony] or 0) <1 and ( not talents[classtable.SoulRot] or cooldown[classtable.SoulRot].remains <= timeShift or cooldown[classtable.SoulRot].remains >= 25 ) ) and debuff[classtable.AgonyDeBuff].up) and cooldown[classtable.PhantomSingularity].ready then
        return classtable.PhantomSingularity
    end
    if (MaxDps:FindSpell(classtable.SoulRot) and CheckSpellCosts(classtable.SoulRot, 'SoulRot')) and (( vt_up and ( ps_up or talents[classtable.SouleatersGluttony] ~= 1 ) ) and debuff[classtable.AgonyDeBuff].up) and cooldown[classtable.SoulRot].ready then
        return classtable.SoulRot
    end
    if (MaxDps:FindSpell(classtable.Agony) and CheckSpellCosts(classtable.Agony, 'Agony')) and (( debuff[classtable.AgonyDeBuff].remains <cooldown[classtable.VileTaint].remains + ( classtable and classtable.VileTaint and GetSpellInfo(classtable.VileTaint).castTime / 1000 ) or not talents[classtable.VileTaint] ) and debuff[classtable.AgonyDeBuff].remains <5 and ttd >5) and cooldown[classtable.Agony].ready then
        return classtable.Agony
    end
    if (MaxDps:FindSpell(classtable.UnstableAffliction) and CheckSpellCosts(classtable.UnstableAffliction, 'UnstableAffliction')) and (( debuff[classtable.UnstableAfflictionDeBuff].refreshable ) and ttd >3) and cooldown[classtable.UnstableAffliction].ready then
        return classtable.UnstableAffliction
    end
    if (MaxDps:FindSpell(classtable.Haunt) and CheckSpellCosts(classtable.Haunt, 'Haunt')) and (debuff[classtable.HauntDeBuff].remains <5) and cooldown[classtable.Haunt].ready then
        return classtable.Haunt
    end
    if (MaxDps:FindSpell(classtable.Corruption) and CheckSpellCosts(classtable.Corruption, 'Corruption')) and (debuff[classtable.CorruptionDeBuff].refreshable and ttd >5) and cooldown[classtable.Corruption].ready then
        return classtable.Corruption
    end
    if (MaxDps:FindSpell(classtable.SiphonLife) and CheckSpellCosts(classtable.SiphonLife, 'SiphonLife')) and (debuff[classtable.SiphonLifeDeBuff].refreshable and ttd >5) and cooldown[classtable.SiphonLife].ready then
        return classtable.SiphonLife
    end
    if (MaxDps:FindSpell(classtable.SummonDarkglare) and CheckSpellCosts(classtable.SummonDarkglare, 'SummonDarkglare')) and (( not talents[classtable.ShadowEmbrace] or ShadowEmbraceDeBuffmaxStacks / debuff[classtable.ShadowEmbraceDeBuff].count * 100 == 100 ) and ps_up and vt_up and sr_up or cooldown[classtable.InvokePowerInfusion0].duration >0 and cooldown[classtable.InvokePowerInfusion0].ready and not talents[classtable.SoulRot]) and cooldown[classtable.SummonDarkglare].ready then
        return classtable.SummonDarkglare
    end
    if (MaxDps:FindSpell(classtable.DrainSoul) and CheckSpellCosts(classtable.DrainSoul, 'DrainSoul')) and (talents[classtable.ShadowEmbrace] and ( ShadowEmbraceDeBuffmaxStacks / debuff[classtable.ShadowEmbraceDeBuff].count * 100 <100 or debuff[classtable.ShadowEmbraceDeBuff].remains <3 )) and cooldown[classtable.DrainSoul].ready then
        return classtable.DrainSoul
    end
    if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and (talents[classtable.ShadowEmbrace] and ( ShadowEmbraceDeBuffmaxStacks / debuff[classtable.ShadowEmbraceDeBuff].count * 100 <100 or debuff[classtable.ShadowEmbraceDeBuff].remains <3 )) and cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
    end
    if (MaxDps:FindSpell(classtable.Oblivion) and CheckSpellCosts(classtable.Oblivion, 'Oblivion')) and (SoulShards == 2 and ( sr_up or cooldown[classtable.SoulRot].remains >cooldown[classtable.Oblivion].remains ) and ( ps_up or cooldown[classtable.PhantomSingularity].remains >cooldown[classtable.Oblivion].remains )) and cooldown[classtable.Oblivion].ready then
        return classtable.Oblivion
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (SoulShards >4 or ( talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].count == 1 and SoulShards >3 )) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].up) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].count == 2) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (cd_dots_up or vt_ps_up and SoulShards >1) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.MaleficRapture) and CheckSpellCosts(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and talents[classtable.Nightfall] and buff[classtable.TormentedCrescendoBuff].up and buff[classtable.NightfallBuff].up) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    if (MaxDps:FindSpell(classtable.DrainLife) and CheckSpellCosts(classtable.DrainLife, 'DrainLife')) and (buff[classtable.InevitableDemiseBuff].count >48 or buff[classtable.InevitableDemiseBuff].count >20 and boss and ttd <4) and cooldown[classtable.DrainLife].ready then
        return classtable.DrainLife
    end
    if (MaxDps:FindSpell(classtable.DrainSoul) and CheckSpellCosts(classtable.DrainSoul, 'DrainSoul')) and (buff[classtable.NightfallBuff].up) and cooldown[classtable.DrainSoul].ready then
        return classtable.DrainSoul
    end
    if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and (buff[classtable.NightfallBuff].up) and cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
    end
    if (MaxDps:FindSpell(classtable.DrainSoul) and CheckSpellCosts(classtable.DrainSoul, 'DrainSoul')) and cooldown[classtable.DrainSoul].ready then
        return classtable.DrainSoul
    end
    if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
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
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    SoulShards = UnitPower('player', SoulShardsPT)
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.HauntDeBuff = 48181
    classtable.AgonyDeBuff = 980
    classtable.UnstableAfflictionDeBuff = 316099
    classtable.SiphonLifeDeBuff = 0
    classtable.CorruptionDeBuff = 146739
    classtable.SeedofCorruptionDeBuff = 27243
    classtable.InevitableDemiseBuff = 0
    classtable.SoulRotBuff = 386998
    classtable.UmbrafireKindlingBuff = 0
    classtable.TormentedCrescendoBuff = 387079
    classtable.NightfallBuff = 264571
    classtable.ShadowEmbraceDeBuff = 453206
    classtable.PhantomSingularityDeBuff = 205197
    classtable.VileTaintDotDeBuff = 386931
    classtable.SoulRotDeBuff = 386997
    classtable.VileTaintDeBuff = 386931

    if talents[classtable.DrainSoul] then
        ShadowEmbraceDeBuffmaxStacks = 4
    else
        ShadowEmbraceDeBuffmaxStacks = 2
    end

    local precombatCheck = Affliction:precombat()
    if precombatCheck then
        return Affliction:precombat()
    end

    local callactionCheck = Affliction:callaction()
    if callactionCheck then
        return Affliction:callaction()
    end
end
