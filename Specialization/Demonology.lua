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

local Demonology = {}

local shadow_timings
local trinket_one_buffs
local trinket_two_buffs
local trinket_one_exclude
local trinket_two_exclude
local trinket_one_manual
local trinket_two_manual
local trinket_one_buff_duration
local trinket_two_buff_duration
local trinket_one_sync
local trinket_two_sync
local damage_trinket_priority
local trinket_priority
local pet_expire
local np
local impl
local pool_cores_for_tyrant

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


function Demonology:precombat()
    --if (MaxDps:FindSpell(classtable.FelDomination) and CheckSpellCosts(classtable.FelDomination, 'FelDomination')) and (timeInCombat >0 and not UnitExists('pet') and not buff[classtable.GrimoireofSacrificeBuff].up) and cooldown[classtable.FelDomination].ready then
    --    return classtable.FelDomination
    --end
    --shadow_timings = 0
    --if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and (SoulShards <5) and cooldown[classtable.ShadowBolt].ready then
    --    return classtable.ShadowBolt
    --end
end
function Demonology:fight_end()
    if (MaxDps:FindSpell(classtable.GrimoireFelguard) and CheckSpellCosts(classtable.GrimoireFelguard, 'GrimoireFelguard')) and (ttd <20) and cooldown[classtable.GrimoireFelguard].ready then
        return classtable.GrimoireFelguard
    end
    if (MaxDps:FindSpell(classtable.CallDreadstalkers) and CheckSpellCosts(classtable.CallDreadstalkers, 'CallDreadstalkers')) and (ttd <20) and cooldown[classtable.CallDreadstalkers].ready then
        return classtable.CallDreadstalkers
    end
    if (MaxDps:FindSpell(classtable.SummonVilefiend) and CheckSpellCosts(classtable.SummonVilefiend, 'SummonVilefiend')) and (ttd <20) and cooldown[classtable.SummonVilefiend].ready then
        return classtable.SummonVilefiend
    end
    if (MaxDps:FindSpell(classtable.SummonDemonicTyrant) and CheckSpellCosts(classtable.SummonDemonicTyrant, 'SummonDemonicTyrant')) and (ttd <20) and cooldown[classtable.SummonDemonicTyrant].ready then
        return classtable.SummonDemonicTyrant
    end
    if (MaxDps:FindSpell(classtable.DemonicStrength) and CheckSpellCosts(classtable.DemonicStrength, 'DemonicStrength')) and (ttd <10) and cooldown[classtable.DemonicStrength].ready then
        return classtable.DemonicStrength
    end
    if (MaxDps:FindSpell(classtable.PowerSiphon) and CheckSpellCosts(classtable.PowerSiphon, 'PowerSiphon')) and (buff[classtable.DemonicCoreBuff].count <3 and ttd <20) and cooldown[classtable.PowerSiphon].ready then
        return classtable.PowerSiphon
    end
    if (MaxDps:FindSpell(classtable.Implosion) and CheckSpellCosts(classtable.Implosion, 'Implosion')) and (ttd <2 * gcd) and cooldown[classtable.Implosion].ready then
        return classtable.Implosion
    end
end
function Demonology:tyrant()
    if (MaxDps:FindSpell(classtable.HandofGuldan) and CheckSpellCosts(classtable.HandofGuldan, 'HandofGuldan')) and (pet_expire >gcd + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 or 0) and (pet_expire <gcd * 4 and 1 or 0)) and cooldown[classtable.HandofGuldan].ready then
        return classtable.HandofGuldan
    end
    if (MaxDps:FindSpell(classtable.SummonDemonicTyrant) and CheckSpellCosts(classtable.SummonDemonicTyrant, 'SummonDemonicTyrant')) and (pet_expire >0 and pet_expire <2 + ( not buff[classtable.DemonicCoreBuff].up * 2 + buff[classtable.DemonicCoreBuff].duration * gcd ) + gcd) and cooldown[classtable.SummonDemonicTyrant].ready then
        return classtable.SummonDemonicTyrant
    end
    if (MaxDps:FindSpell(classtable.Implosion) and CheckSpellCosts(classtable.Implosion, 'Implosion')) and (C_Spell.GetSpellCastCount(classtable.Implosion) >2 and ( not buff[classtable.DreadstalkersBuff].up and not buff[classtable.GrimoireFelguardBuff].up and not buff[classtable.VilefiendBuff].up ) and ( targets >3 or targets >2 and talents[classtable.GrandWarlocksDesign] ) and not (MaxDps.spellHistory[1] == classtable.Implosion)) and cooldown[classtable.Implosion].ready then
        return classtable.Implosion
    end
    if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and ((MaxDps.spellHistory[1] == classtable.GrimoireFelguard) and timeInCombat >30 and not buff[classtable.DemonicCoreBuff].up) and cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
    end
    if (MaxDps:FindSpell(classtable.PowerSiphon) and CheckSpellCosts(classtable.PowerSiphon, 'PowerSiphon')) and (buff[classtable.DemonicCoreBuff].count <4 and ( not buff[classtable.VilefiendBuff].up or not talents[classtable.SummonVilefiend] and ( not buff[classtable.DreadstalkersBuff].up ) )) and cooldown[classtable.PowerSiphon].ready then
        return classtable.PowerSiphon
    end
    if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and (not buff[classtable.VilefiendBuff].up and not buff[classtable.DreadstalkersBuff].up and SoulShards <5 - buff[classtable.DemonicCoreBuff].count) and cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
    end
    if (MaxDps:FindSpell(classtable.SummonVilefiend) and CheckSpellCosts(classtable.SummonVilefiend, 'SummonVilefiend')) and (( SoulShards == 5 ) and cooldown[classtable.SummonDemonicTyrant].remains <13 and np) and cooldown[classtable.SummonVilefiend].ready then
        return classtable.SummonVilefiend
    end
    if (MaxDps:FindSpell(classtable.CallDreadstalkers) and CheckSpellCosts(classtable.CallDreadstalkers, 'CallDreadstalkers')) and (( buff[classtable.VilefiendBuff].up or not talents[classtable.SummonVilefiend] and ( not talents[classtable.NetherPortal] ) and ( buff[classtable.GrimoireFelguardBuff].up or SoulShards == 5 ) ) and cooldown[classtable.SummonDemonicTyrant].remains <11 and np) and cooldown[classtable.CallDreadstalkers].ready then
        return classtable.CallDreadstalkers
    end
    if (MaxDps:FindSpell(classtable.GrimoireFelguard) and CheckSpellCosts(classtable.GrimoireFelguard, 'GrimoireFelguard')) and (buff[classtable.VilefiendBuff].up or not talents[classtable.SummonVilefiend] and ( not talents[classtable.NetherPortal] ) and ( buff[classtable.DreadstalkersBuff].up or SoulShards == 5 ) and np) and cooldown[classtable.GrimoireFelguard].ready then
        return classtable.GrimoireFelguard
    end
    if (MaxDps:FindSpell(classtable.HandofGuldan) and CheckSpellCosts(classtable.HandofGuldan, 'HandofGuldan')) and (SoulShards >2 and ( buff[classtable.VilefiendBuff].up or not talents[classtable.SummonVilefiend] and buff[classtable.DreadstalkersBuff].up ) and ( SoulShards >2 or buff[classtable.VilefiendBuff].remains <gcd * 2 + 2 % SpellHaste ) or ( not buff[classtable.DreadstalkersBuff].up and SoulShards == 5 )) and cooldown[classtable.HandofGuldan].ready then
        return classtable.HandofGuldan
    end
    if (MaxDps:FindSpell(classtable.Demonbolt) and CheckSpellCosts(classtable.Demonbolt, 'Demonbolt')) and (SoulShards <4 and ( buff[classtable.DemonicCoreBuff].up ) and ( buff[classtable.VilefiendBuff].up or not talents[classtable.SummonVilefiend] and buff[classtable.DreadstalkersBuff].up )) and cooldown[classtable.Demonbolt].ready then
        return classtable.Demonbolt
    end
    if (MaxDps:FindSpell(classtable.PowerSiphon) and CheckSpellCosts(classtable.PowerSiphon, 'PowerSiphon')) and (buff[classtable.DemonicCoreBuff].count <3 and pet_expire >2 + gcd * 3 or pet_expire == 0) and cooldown[classtable.PowerSiphon].ready then
        return classtable.PowerSiphon
    end
    if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
    end
end

function Demonology:callaction()
    if (MaxDps:FindSpell(classtable.AxeToss) and CheckSpellCosts(classtable.AxeToss, 'AxeToss')) and cooldown[classtable.AxeToss].ready then
        return classtable.AxeToss
    end
    if (MaxDps:FindSpell(classtable.SpellLock) and CheckSpellCosts(classtable.SpellLock, 'SpellLock')) and cooldown[classtable.SpellLock].ready then
        MaxDps:GlowCooldown(classtable.SpellLock, select(8,UnitCastingInfo('target') == false) and cooldown[classtable.SpellLock].ready)
    end
    --if (MaxDps:FindSpell(classtable.DevourMagic) and CheckSpellCosts(classtable.DevourMagic, 'DevourMagic')) and cooldown[classtable.DevourMagic].ready then
    --    return classtable.DevourMagic
    --end
    pet_expire = 0
    if buff[classtable.VilefiendBuff].up and buff[classtable.DreadstalkersBuff].up then
        pet_expire = ( buff[classtable.DreadstalkersBuff].remains >buff[classtable.VilefiendBuff].remains and 1 or 0) - gcd * 0.5
    end
    if not talents[classtable.SummonVilefiend] and talents[classtable.GrimoireFelguard] and buff[classtable.GrimoireFelguardBuff].up and buff[classtable.DreadstalkersBuff].up then
        pet_expire = ( buff[classtable.DreadstalkersBuff].remains >buff[classtable.GrimoireFelguardBuff].remains and 1 or 0) - gcd * 0.5
    end
    if not talents[classtable.SummonVilefiend] and not talents[classtable.GrimoireFelguard] and buff[classtable.DreadstalkersBuff].up then
        pet_expire = ( buff[classtable.DreadstalkersBuff].remains ) - gcd
    end
    if not buff[classtable.VilefiendBuff].up and talents[classtable.SummonVilefiend] or not buff[classtable.DreadstalkersBuff].up then
        pet_expire = 0
    end
    np = ( not talents[classtable.NetherPortal] )
    if targets >1 + ( talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0 ) then
        impl = not buff[classtable.TyrantBuff].up
    end
    if targets >2 + ( talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0 ) and targets <5 + ( talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0 ) then
        impl = buff[classtable.TyrantBuff].remains <6
    end
    if targets >4 + ( talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0 ) then
        impl = buff[classtable.TyrantBuff].remains <8
    end
    pool_cores_for_tyrant = cooldown[classtable.SummonDemonicTyrant].remains <20 and cooldown[classtable.SummonDemonicTyrant].remains <20 and ( buff[classtable.DemonicCoreBuff].count <= 2 or not buff[classtable.DemonicCoreBuff].up ) and cooldown[classtable.SummonVilefiend].remains <gcd * 5 and cooldown[classtable.CallDreadstalkers].remains <gcd * 5
    if (ttd <30) then
        local fight_endCheck = Demonology:fight_end()
        if fight_endCheck then
            return Demonology:fight_end()
        end
    end
    if (MaxDps:FindSpell(classtable.HandofGuldan) and CheckSpellCosts(classtable.HandofGuldan, 'HandofGuldan')) and (timeInCombat <0.5 and ( ttd % 95 >40 or ttd % 95 <15 ) and ( talents[classtable.ReignofTyranny] or targets >2 )) and cooldown[classtable.HandofGuldan].ready then
        return classtable.HandofGuldan
    end
    if (( cooldown[classtable.SummonDemonicTyrant].remains <15 and cooldown[classtable.SummonVilefiend].remains <gcd * 5 and cooldown[classtable.CallDreadstalkers].remains <gcd * 5 and ( cooldown[classtable.GrimoireFelguard].remains <10 or cooldown[classtable.GrimoireFelguard].remains >cooldown[classtable.SummonDemonicTyrant].remains + 60 or not talents[classtable.GrimoireFelguard] or not (MaxDps.tier and MaxDps.tier[30].count >= 2) ) and ( cooldown[classtable.SummonDemonicTyrant].remains <15 or ttd <40 or buff[classtable.PowerInfusionBuff].up ) and ( (targets <2) or (targets >1) and targets >20 ) or talents[classtable.SummonVilefiend] and cooldown[classtable.SummonDemonicTyrant].remains <15 and cooldown[classtable.SummonVilefiend].remains <gcd * 5 and cooldown[classtable.CallDreadstalkers].remains <gcd * 5 and ( cooldown[classtable.GrimoireFelguard].remains <10 or cooldown[classtable.GrimoireFelguard].remains >cooldown[classtable.SummonDemonicTyrant].remains + 60 or not talents[classtable.GrimoireFelguard] or not (MaxDps.tier and MaxDps.tier[30].count >= 2) ) and ( cooldown[classtable.SummonDemonicTyrant].remains <15 or ttd <40 or buff[classtable.PowerInfusionBuff].up ) and ( (targets <2) or (targets >1) and targets >20 ) ) or ( cooldown[classtable.SummonDemonicTyrant].remains <15 and ( buff[classtable.VilefiendBuff].up or not talents[classtable.SummonVilefiend] and ( buff[classtable.GrimoireFelguardBuff].up or cooldown[classtable.GrimoireFelguard].ready or not (MaxDps.tier and MaxDps.tier[30].count >= 2) ) ) and ( cooldown[classtable.SummonDemonicTyrant].remains <15 or buff[classtable.GrimoireFelguardBuff].up or ttd <40 or buff[classtable.PowerInfusionBuff].up ) and ( (targets <2) or (targets >1) and targets >20 ) )) then
        local tyrantCheck = Demonology:tyrant()
        if tyrantCheck then
            return Demonology:tyrant()
        end
    end
    if (MaxDps:FindSpell(classtable.SummonDemonicTyrant) and CheckSpellCosts(classtable.SummonDemonicTyrant, 'SummonDemonicTyrant')) and (buff[classtable.VilefiendBuff].up or buff[classtable.GrimoireFelguardBuff].up or cooldown[classtable.GrimoireFelguard].remains >cooldown[classtable.SummonDemonicTyrant].remains) and cooldown[classtable.SummonDemonicTyrant].ready then
        return classtable.SummonDemonicTyrant
    end
    if (MaxDps:FindSpell(classtable.SummonVilefiend) and CheckSpellCosts(classtable.SummonVilefiend, 'SummonVilefiend')) and (cooldown[classtable.SummonDemonicTyrant].remains >cooldown[classtable.SummonVilefiend].remains) and cooldown[classtable.SummonVilefiend].ready then
        return classtable.SummonVilefiend
    end
    if (MaxDps:FindSpell(classtable.Demonbolt) and CheckSpellCosts(classtable.Demonbolt, 'Demonbolt')) and (( not debuff[classtable.DoomBrandDeBuff].up or (classtable and classtable.HandofGuldan and GetSpellCooldown(classtable.HandofGuldan).duration >=5 ) and debuff[classtable.DoomBrandDeBuff].remains <= 3 ) and buff[classtable.DemonicCoreBuff].up and ( ( ( not talents[classtable.SoulStrike] or cooldown[classtable.SoulStrike].remains >gcd * 2 ) and SoulShards <4 ) or SoulShards <( 4 - ( targets >2 and 1 or 0) ) or buff[classtable.DemonicCoreBuff].remains <1 + buff[classtable.DemonicCoreBuff].count * gcd ) and not (MaxDps.spellHistory[1] == classtable.Demonbolt) and (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.Demonbolt].ready then
        return classtable.Demonbolt
    end
    if (MaxDps:FindSpell(classtable.PowerSiphon) and CheckSpellCosts(classtable.PowerSiphon, 'PowerSiphon')) and (not buff[classtable.DemonicCoreBuff].up and ( not debuff[classtable.DoomBrandDeBuff].up or ( not (classtable and classtable.HandofGuldan and GetSpellCooldown(classtable.HandofGuldan).duration >=5 ) and debuff[classtable.DoomBrandDeBuff].remains <gcd + 1 ) or ( (classtable and classtable.HandofGuldan and GetSpellCooldown(classtable.HandofGuldan).duration >=5 ) and debuff[classtable.DoomBrandDeBuff].remains <gcd + 1 + 3 ) ) and (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.PowerSiphon].ready then
        return classtable.PowerSiphon
    end
    if (MaxDps:FindSpell(classtable.DemonicStrength) and CheckSpellCosts(classtable.DemonicStrength, 'DemonicStrength')) and cooldown[classtable.DemonicStrength].ready then
        return classtable.DemonicStrength
    end
    if (MaxDps:FindSpell(classtable.BilescourgeBombers) and CheckSpellCosts(classtable.BilescourgeBombers, 'BilescourgeBombers')) and cooldown[classtable.BilescourgeBombers].ready then
        return classtable.BilescourgeBombers
    end
    if (MaxDps:FindSpell(classtable.Guillotine) and CheckSpellCosts(classtable.Guillotine, 'Guillotine')) and (( cooldown[classtable.DemonicStrength].ready==false or not talents[classtable.DemonicStrength] ) and ( (targets <2) or (targets >1) and targets >6 )) and cooldown[classtable.Guillotine].ready then
        return classtable.Guillotine
    end
    if (MaxDps:FindSpell(classtable.CallDreadstalkers) and CheckSpellCosts(classtable.CallDreadstalkers, 'CallDreadstalkers')) and (cooldown[classtable.SummonDemonicTyrant].remains >25) and cooldown[classtable.CallDreadstalkers].ready then
        return classtable.CallDreadstalkers
    end
    if (MaxDps:FindSpell(classtable.Implosion) and CheckSpellCosts(classtable.Implosion, 'Implosion')) and ((C_Spell.GetSpellCastCount(classtable.Implosion) >=2 and 1 or 0) >0 and impl and not (MaxDps.spellHistory[1] == classtable.Implosion) and (targets <2) or (C_Spell.GetSpellCastCount(classtable.Implosion) >=2 and 1 or 0) >0 and impl and not (MaxDps.spellHistory[1] == classtable.Implosion) and (targets >1) and ( targets >3 or targets <= 3 and not (MaxDps.spellHistory[1] == classtable.Implosion) )) and cooldown[classtable.Implosion].ready then
        return classtable.Implosion
    end
    if (MaxDps:FindSpell(classtable.DemonicStrength) and CheckSpellCosts(classtable.DemonicStrength, 'DemonicStrength')) and (( ttd >63 and not ( ttd >cooldown[classtable.SummonDemonicTyrant].remains + 69 ) or cooldown[classtable.SummonDemonicTyrant].remains >30 or buff[classtable.RiteofRuvaraadBuff].up or 1 or not talents[classtable.SummonDemonicTyrant] or not talents[classtable.GrimoireFelguard] )) and cooldown[classtable.DemonicStrength].ready then
        return classtable.DemonicStrength
    end
    if (MaxDps:FindSpell(classtable.HandofGuldan) and CheckSpellCosts(classtable.HandofGuldan, 'HandofGuldan')) and (( ( SoulShards >2 and cooldown[classtable.CallDreadstalkers].remains >gcd * 4 and cooldown[classtable.SummonDemonicTyrant].remains >17 ) or SoulShards == 5 or SoulShards == 4 and talents[classtable.SoulStrike] and cooldown[classtable.SoulStrike].remains <gcd * 2 ) and ( targets == 1 and talents[classtable.GrandWarlocksDesign] )) and cooldown[classtable.HandofGuldan].ready then
        return classtable.HandofGuldan
    end
    if (MaxDps:FindSpell(classtable.HandofGuldan) and CheckSpellCosts(classtable.HandofGuldan, 'HandofGuldan')) and (SoulShards >2 and not ( targets == 1 and talents[classtable.GrandWarlocksDesign] )) and cooldown[classtable.HandofGuldan].ready then
        return classtable.HandofGuldan
    end
    if (MaxDps:FindSpell(classtable.Demonbolt) and CheckSpellCosts(classtable.Demonbolt, 'Demonbolt')) and (( ( not debuff[classtable.DoomBrandDeBuff].up ) or targets <4 ) and buff[classtable.DemonicCoreBuff].count >1 and ( ( SoulShards <4 and not talents[classtable.SoulStrike] or cooldown[classtable.SoulStrike].remains >gcd * 2 ) or SoulShards <3 ) and not pool_cores_for_tyrant) and cooldown[classtable.Demonbolt].ready then
        return classtable.Demonbolt
    end
    if (MaxDps:FindSpell(classtable.Demonbolt) and CheckSpellCosts(classtable.Demonbolt, 'Demonbolt')) and (( ( not debuff[classtable.DoomBrandDeBuff].up ) or targets <4 ) and (MaxDps.tier and MaxDps.tier[31].count >= 2) and ( debuff[classtable.DoomBrandDeBuff].remains >10 and buff[classtable.DemonicCoreBuff].up and SoulShards <4 ) and not pool_cores_for_tyrant) and cooldown[classtable.Demonbolt].ready then
        return classtable.Demonbolt
    end
    if (MaxDps:FindSpell(classtable.Demonbolt) and CheckSpellCosts(classtable.Demonbolt, 'Demonbolt')) and (ttd <buff[classtable.DemonicCoreBuff].count * gcd or buff[classtable.DemonicCoreBuff].up and buff[classtable.DemonicCoreBuff].remains <1 + buff[classtable.DemonicCoreBuff].count * gcd) and cooldown[classtable.Demonbolt].ready then
        return classtable.Demonbolt
    end
    if (MaxDps:FindSpell(classtable.Demonbolt) and CheckSpellCosts(classtable.Demonbolt, 'Demonbolt')) and (( ( not debuff[classtable.DoomBrandDeBuff].up ) or targets <4 ) and buff[classtable.DemonicCoreBuff].up and ( cooldown[classtable.PowerSiphon].remains <4 ) and ( SoulShards <4 ) and not pool_cores_for_tyrant) and cooldown[classtable.Demonbolt].ready then
        return classtable.Demonbolt
    end
    if (MaxDps:FindSpell(classtable.PowerSiphon) and CheckSpellCosts(classtable.PowerSiphon, 'PowerSiphon')) and (not buff[classtable.DemonicCoreBuff].up) and cooldown[classtable.PowerSiphon].ready then
        return classtable.PowerSiphon
    end
    if (MaxDps:FindSpell(classtable.PowerSiphon) and CheckSpellCosts(classtable.PowerSiphon, 'PowerSiphon')) and (not buff[classtable.DemonicCoreBuff].up) and cooldown[classtable.PowerSiphon].ready then
        return classtable.PowerSiphon
    end
    if (MaxDps:FindSpell(classtable.SummonVilefiend) and CheckSpellCosts(classtable.SummonVilefiend, 'SummonVilefiend')) and (ttd <cooldown[classtable.SummonDemonicTyrant].remains + 5) and cooldown[classtable.SummonVilefiend].ready then
        return classtable.SummonVilefiend
    end
    if (MaxDps:FindSpell(classtable.ShadowBolt) and CheckSpellCosts(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
    end
    --if (use_off_gcd == 1) then
    --    local itemsCheck = Demonology:items()
    --    if itemsCheck then
    --        return Demonology:items()
    --    end
    --end
    --if (use_off_gcd == 1) then
    --    local racialsCheck = Demonology:racials()
    --    if racialsCheck then
    --        return Demonology:racials()
    --    end
    --end
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
    classtable.GrimoireofSacrificeBuff = 0
    classtable.DemonicCoreBuff = 264173
    classtable.DreadstalkersBuff = 387393
    classtable.GrimoireFelguardBuff = 0
    classtable.VilefiendBuff = 0
    classtable.TyrantBuff = 0
    classtable.PowerInfusionBuff = 10060
    classtable.DoomBrandDeBuff = 423583
    classtable.RiteofRuvaraadBuff = 0
    classtable.Demonbolt = 264178

    local precombatCheck = Demonology:precombat()
    if precombatCheck then
        return Demonology:precombat()
    end

    local callactionCheck = Demonology:callaction()
    if callactionCheck then
        return Demonology:callaction()
    end
end
