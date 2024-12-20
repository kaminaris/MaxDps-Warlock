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
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local SoulShards
local SoulShardsMax
local SoulShardsDeficit
local Mana
local ManaMax
local ManaDeficit

local Demonology = {}

local first_tyrant_time
local first_tyrant_time
local first_tyrant_time
local first_tyrant_time
local first_tyrant_time
local first_tyrant_time
local in_opener
local trinket_1_buffs
local trinket_2_buffs
local trinket_1_exclude
local trinket_2_exclude
local trinket_1_manual
local trinket_2_manual
local trinket_1_buff_duration
local trinket_2_buff_duration
local trinket_1_sync
local trinket_2_sync
local damage_trinket_priority
local trinket_priority
local check_racials
local next_tyrant_cd
local in_opener
local impl
local impl
local impl
local pool_cores_for_tyrant
local diabolic_ritual_remains
local diabolic_ritual_remains
local diabolic_ritual_remains


local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end




local function imp_despawn()
    if buff[classtable.TyrantBuff].up then return 0 end
    local val = 0
    local TTSHoD = (GetTime() - (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.HandofGuldan] and MaxDps.spellHistoryTime[classtable.HandofGuldan].last_used or 0))
    if TTSHoD < (2 * UnitSpellHaste('player') * 6 + 0.58) and buff[classtable.DreadStalkers].up and cooldown[classtable.SummonDemonicTyrant].remains < 13 then
        val = max( 0, GetTime() - TTSHoD + 2 * UnitSpellHaste('player') * 6 + 0.58 )
    end
    if val > 0 then
        val = max( val, buff[classtable.DreadStalkers].remains + GetTime() )
    end
    if val > 0 and buff[classtable.GrimoireFelguard].up then
        val = max( val, buff[classtable.GrimoireFelguard].remains + GetTime() )
    end
    return val
end

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
    if talents[classtable.GrimoireFelguard] then
        first_tyrant_time = 2
    end
    if talents[classtable.SummonVilefiend] then
        first_tyrant_time = 2
    end
    if talents[classtable.GrimoireFelguard] or talents[classtable.SummonVilefiend] then
        first_tyrant_time = gcd
    end
    first_tyrant_time = 2 + 2
    first_tyrant_time = 10
    in_opener = 1
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
    if (MaxDps:CheckSpellUsable(classtable.GrimoireFelguard, 'GrimoireFelguard')) and (ttd <20) and cooldown[classtable.GrimoireFelguard].ready then
        if not setSpell then setSpell = classtable.GrimoireFelguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
    if (MaxDps:CheckSpellUsable(classtable.Implosion, 'Implosion')) and (ttd <2 * gcd and not (MaxDps.spellHistory[1] == classtable.Implosion)) and cooldown[classtable.Implosion].ready then
        if not setSpell then setSpell = classtable.Implosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (ttd <gcd * 2 * buff[classtable.DemonicCoreBuff].count + 9 and buff[classtable.DemonicCoreBuff].up and ( SoulShards <4 or ttd <buff[classtable.DemonicCoreBuff].count * gcd )) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.CallDreadstalkers, 'CallDreadstalkers')) and (ttd <20) and cooldown[classtable.CallDreadstalkers].ready then
        if not setSpell then setSpell = classtable.CallDreadstalkers end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonVilefiend, 'SummonVilefiend')) and (ttd <20) and cooldown[classtable.SummonVilefiend].ready then
        if not setSpell then setSpell = classtable.SummonVilefiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDemonicTyrant, 'SummonDemonicTyrant')) and (ttd <20) and cooldown[classtable.SummonDemonicTyrant].ready then
        if not setSpell then setSpell = classtable.SummonDemonicTyrant end
    end
    if (MaxDps:CheckSpellUsable(classtable.DemonicStrength, 'DemonicStrength')) and (ttd <10) and cooldown[classtable.DemonicStrength].ready then
        if not setSpell then setSpell = classtable.DemonicStrength end
    end
    if (MaxDps:CheckSpellUsable(classtable.PowerSiphon, 'PowerSiphon')) and (buff[classtable.DemonicCoreBuff].count <3 and ttd <20) and cooldown[classtable.PowerSiphon].ready then
        if not setSpell then setSpell = classtable.PowerSiphon end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (ttd <gcd * 2 * buff[classtable.DemonicCoreBuff].count + 9 and buff[classtable.DemonicCoreBuff].up and ( SoulShards <4 or ttd <buff[classtable.DemonicCoreBuff].count * gcd )) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (SoulShards >2 and ttd <gcd * 2 * buff[classtable.DemonicCoreBuff].count + 9) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
end
function Demonology:items()
end
function Demonology:opener()
    if (MaxDps:CheckSpellUsable(classtable.GrimoireFelguard, 'GrimoireFelguard')) and (SoulShards >= 5 - talents[classtable.FelInvocation]) and cooldown[classtable.GrimoireFelguard].ready then
        if not setSpell then setSpell = classtable.GrimoireFelguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonVilefiend, 'SummonVilefiend')) and (SoulShards == 5) and cooldown[classtable.SummonVilefiend].ready then
        if not setSpell then setSpell = classtable.SummonVilefiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (SoulShards <5 and cooldown[classtable.CallDreadstalkers].ready) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.CallDreadstalkers, 'CallDreadstalkers')) and (SoulShards == 5) and cooldown[classtable.CallDreadstalkers].ready then
        if not setSpell then setSpell = classtable.CallDreadstalkers end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
end
function Demonology:racials()
end
function Demonology:tyrant()
    if (not check_racials and ( imp_despawn() and imp_despawn() <timeInCombat + gcd * 2 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 ) and ( (MaxDps.spellHistory[1] == classtable.HandofGuldan) or (MaxDps.spellHistory[1] == classtable.Ruination) ) and ( imp_despawn() and imp_despawn() <timeInCombat + gcd + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 ) or SoulShards <2 ) )) then
        Demonology:racials()
    end
    if (MaxDps:CheckSpellUsable(classtable.PowerSiphon, 'PowerSiphon')) and (cooldown[classtable.SummonDemonicTyrant].remains <15 and ( timeInCombat <first_tyrant_time or cooldown[classtable.SummonDemonicTyrant].remains >( ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 ) + 2 * gcd ) )) and cooldown[classtable.PowerSiphon].ready then
        if not setSpell then setSpell = classtable.PowerSiphon end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and (buff[classtable.DreadstalkersBuff].remains >gcd + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 ) and ( SoulShards == 5 or imp_despawn() )) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and (( buff[classtable.InfernalBoltBuff].remains >( classtable and classtable.InfernalBolt and GetSpellInfo(classtable.InfernalBolt).castTime /1000 ) and buff[classtable.InfernalBoltBuff].remains <2 * gcd or not buff[classtable.DemonicCoreBuff].up ) and imp_despawn() >timeInCombat + gcd * 2 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 ) and SoulShards <3) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and ((MaxDps.spellHistory[1] == classtable.CallDreadstalkers) and SoulShards <4 and buff[classtable.DemonicCoreBuff].count <4) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and ((MaxDps.spellHistory[2] == classtable.CallDreadstalkers) and (MaxDps.spellHistory[1] == classtable.ShadowBolt) and MaxDps:Bloodlust() and SoulShards <5) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and ((MaxDps.spellHistory[1] == classtable.SummonVilefiend) and ( not buff[classtable.DemonicCallingBuff].up or (MaxDps.spellHistory[2] == classtable.GrimoireFelguard) )) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and ((MaxDps.spellHistory[1] == classtable.GrimoireFelguard) and buff[classtable.DemonicCoreBuff].count <3 and buff[classtable.DemonicCallingBuff].remains >gcd * 3) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (imp_despawn() >timeInCombat + gcd * 2 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 ) and not buff[classtable.DemonicCoreBuff].up and buff[classtable.DemonicArtPitLordBuff].up and imp_despawn() <timeInCombat + gcd * 5 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 )) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (imp_despawn() >timeInCombat + gcd + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 ) and imp_despawn() <timeInCombat + gcd * 2 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 ) and buff[classtable.DreadstalkersBuff].remains >gcd + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 ) and SoulShards >1) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (not buff[classtable.DemonicCoreBuff].up and imp_despawn() >timeInCombat + gcd * 2 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 ) and imp_despawn() <timeInCombat + gcd * 4 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 ) and SoulShards <3 and buff[classtable.DreadstalkersBuff].remains >gcd * 2 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime / 1000 )) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.GrimoireFelguard, 'GrimoireFelguard')) and (cooldown[classtable.SummonDemonicTyrant].remains <17 - 2 * gcd and cooldown[classtable.SummonVilefiend].remains <15 - 2 * gcd and cooldown[classtable.CallDreadstalkers].remains <12 - 2 * gcd) and cooldown[classtable.GrimoireFelguard].ready then
        if not setSpell then setSpell = classtable.GrimoireFelguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonVilefiend, 'SummonVilefiend')) and (cooldown[classtable.SummonDemonicTyrant].remains <15 - 2 * gcd and ( buff[classtable.GrimoireFelguardBuff].up or cooldown[classtable.GrimoireFelguard].remains >15 or not talents[classtable.GrimoireFelguard] ) and ( buff[classtable.DreadstalkersBuff].up or cooldown[classtable.CallDreadstalkers].remains <15 - 2 * gcd or not talents[classtable.CallDreadstalkers] )) and cooldown[classtable.SummonVilefiend].ready then
        if not setSpell then setSpell = classtable.SummonVilefiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.CallDreadstalkers, 'CallDreadstalkers')) and (cooldown[classtable.SummonDemonicTyrant].remains <12 - 2 * gcd and ( buff[classtable.VilefiendBuff].up or cooldown[classtable.SummonVilefiend].remains <12 - 2 * gcd or not talents[classtable.SummonVilefiend] )) and cooldown[classtable.CallDreadstalkers].ready then
        if not setSpell then setSpell = classtable.CallDreadstalkers end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDemonicTyrant, 'SummonDemonicTyrant')) and (( ( ( imp_despawn() and imp_despawn() <timeInCombat + gcd * 2 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime /1000 ) ) or ( buff[classtable.WildImpsBuff].count >9 and SoulShards <2 ) ) and buff[classtable.DreadstalkersBuff].up and ( buff[classtable.VilefiendBuff].up or not talents[classtable.SummonVilefiend] ) ) or ( buff[classtable.DreadstalkersBuff].up and buff[classtable.DreadstalkersBuff].remains <gcd * 2 + ( classtable and classtable.SummonDemonicTyrant and GetSpellInfo(classtable.SummonDemonicTyrant).castTime /1000 ) and ( ( buff[classtable.VilefiendBuff].up and buff[classtable.VilefiendBuff].remains >2 * gcd ) or not talents[classtable.SummonVilefiend] ) and ( ( buff[classtable.GrimoireFelguardBuff].up and buff[classtable.GrimoireFelguardBuff].remains >2 * gcd ) or not talents[classtable.GrimoireFelguard] or cooldown[classtable.GrimoireFelguard].remains >20 ) )) and cooldown[classtable.SummonDemonicTyrant].ready then
        if not setSpell then setSpell = classtable.SummonDemonicTyrant end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (( imp_despawn() or buff[classtable.DreadstalkersBuff].remains ) and SoulShards >= 3 or SoulShards == 5) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and (imp_despawn() and SoulShards <3) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (imp_despawn() and buff[classtable.DemonicCoreBuff].up and SoulShards <4 or (MaxDps.spellHistory[1] == classtable.CallDreadstalkers) and SoulShards <4 and buff[classtable.DemonicCoreBuff].count == 4 or buff[classtable.DemonicCoreBuff].count == 4 and SoulShards <4 or buff[classtable.DemonicCoreBuff].count >= 2 and cooldown[classtable.PowerSiphon].remains <5) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and (imp_despawn() or SoulShards == 5 and cooldown[classtable.SummonVilefiend].remains >gcd * 3) and cooldown[classtable.Ruination].ready then
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
    diabolic_ritual_remains = 0
    if ( UnitExists('pet') and UnitName('pet')  == 'demonic_tyrant' ) then
        in_opener = 0
    end
    if targets >1 + ( talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0 ) then
        impl = not buff[classtable.TyrantBuff].up
    end
    if targets >2 + ( talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0 ) and targets <5 + ( talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0 ) then
        impl = buff[classtable.TyrantBuff].remains <6
    end
    if targets >4 + ( talents[classtable.SacrificedSouls] and talents[classtable.SacrificedSouls] or 0 ) then
        impl = buff[classtable.TyrantBuff].remains <8
    end
    pool_cores_for_tyrant = cooldown[classtable.SummonDemonicTyrant].remains <20 and next_tyrant_cd <20 and ( buff[classtable.DemonicCoreBuff].count <= 2 or not buff[classtable.DemonicCoreBuff].up ) and cooldown[classtable.SummonVilefiend].remains <gcd * 8 and cooldown[classtable.CallDreadstalkers].remains <gcd * 8
    if buff[classtable.DiabolicRitualMotherofChaosBuff].up then
        diabolic_ritual_remains = buff[classtable.DiabolicRitualMotherofChaosBuff].remains
    end
    if buff[classtable.DiabolicRitualOverlordBuff].up then
        diabolic_ritual_remains = buff[classtable.DiabolicRitualOverlordBuff].remains
    end
    if buff[classtable.DiabolicRitualPitLordBuff].up then
        diabolic_ritual_remains = buff[classtable.DiabolicRitualPitLordBuff].remains
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.AxeToss, false)
end

function Demonology:callaction()
    if (MaxDps:CheckSpellUsable(classtable.AxeToss, 'AxeToss')) and cooldown[classtable.AxeToss].ready then
        MaxDps:GlowCooldown(classtable.AxeToss, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    Demonology:variables()
    check_racials = ( UnitExists('pet') and UnitName('pet')  == 'demonic_tyrant' ) or MaxDps:boss() and ttd <22
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
    if (cooldown[classtable.SummonDemonicTyrant].remains <gcd * 14) then
        Demonology:tyrant()
    end
    if (MaxDps:CheckSpellUsable(classtable.CallDreadstalkers, 'CallDreadstalkers')) and (cooldown[classtable.SummonDemonicTyrant].remains >25 or next_tyrant_cd >25) and cooldown[classtable.CallDreadstalkers].ready then
        if not setSpell then setSpell = classtable.CallDreadstalkers end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonVilefiend, 'SummonVilefiend')) and (cooldown[classtable.SummonDemonicTyrant].remains >30) and cooldown[classtable.SummonVilefiend].ready then
        if not setSpell then setSpell = classtable.SummonVilefiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (( not debuff[classtable.DoomDeBuff].up or not (classtable and classtable.Demonbolt and cooldown[classtable.Demonbolt].duration - cooldown[classtable.Demonbolt].remains <=2 ) and debuff[classtable.DoomDeBuff].remains <= 2 ) and buff[classtable.DemonicCoreBuff].up and ( ( ( not talents[classtable.SoulStrike] or cooldown[classtable.SoulStrike].remains >gcd * 2 and talents[classtable.FelInvocation] ) and SoulShards <4 ) or SoulShards <( 4 - ( targets >2 ) ) ) and not (MaxDps.spellHistory[1] == classtable.Demonbolt) and talents[classtable.Doom] and cooldown[classtable.SummonDemonicTyrant].remains >15) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (buff[classtable.DemonicCoreBuff].count >= 3 and SoulShards <= 3 and not pool_cores_for_tyrant) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.PowerSiphon, 'PowerSiphon')) and (buff[classtable.DemonicCoreBuff].count <3 and cooldown[classtable.SummonDemonicTyrant].remains >25) and cooldown[classtable.PowerSiphon].ready then
        if not setSpell then setSpell = classtable.PowerSiphon end
    end
    if (MaxDps:CheckSpellUsable(classtable.DemonicStrength, 'DemonicStrength')) and (targets >1) and cooldown[classtable.DemonicStrength].ready then
        if not setSpell then setSpell = classtable.DemonicStrength end
    end
    if (MaxDps:CheckSpellUsable(classtable.BilescourgeBombers, 'BilescourgeBombers')) and (targets >1) and cooldown[classtable.BilescourgeBombers].ready then
        if not setSpell then setSpell = classtable.BilescourgeBombers end
    end
    if (MaxDps:CheckSpellUsable(classtable.Guillotine, 'Guillotine')) and (targets >1 and ( cooldown[classtable.DemonicStrength].ready==false or not talents[classtable.DemonicStrength] )) and cooldown[classtable.Guillotine].ready then
        if not setSpell then setSpell = classtable.Guillotine end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ruination, 'Ruination')) and cooldown[classtable.Ruination].ready then
        if not setSpell then setSpell = classtable.Ruination end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and (buff[classtable.InfernalBoltBuff].remains >( classtable and classtable.InfernalBolt and GetSpellInfo(classtable.InfernalBolt).castTime /1000 ) and buff[classtable.InfernalBoltBuff].remains <2 * gcd or SoulShards <3 and cooldown[classtable.SummonDemonicTyrant].remains >20) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Implosion, 'Implosion')) and ((cooldown[classtable.Implosion].charges >=2 and 1 or 0) >0 and impl and not (MaxDps.spellHistory[1] == classtable.Implosion) and ( targets >3 or targets <= 3 and last_cast_imps() >0 )) and cooldown[classtable.Implosion].ready then
        if not setSpell then setSpell = classtable.Implosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (diabolic_ritual_remains >gcd and diabolic_ritual_remains <gcd + gcd and buff[classtable.DemonicCoreBuff].up and SoulShards <= 3) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (diabolic_ritual_remains >gcd and diabolic_ritual_remains <SoulShardsDeficit * ( classtable and classtable.ShadowBolt and GetSpellInfo(classtable.ShadowBolt).castTime /1000 ) + gcd and SoulShards <5) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (( ( SoulShards >2 and ( cooldown[classtable.CallDreadstalkers].remains >gcd * 4 or buff[classtable.DemonicCallingBuff].remains - gcd >cooldown[classtable.CallDreadstalkers].remains ) and cooldown[classtable.SummonDemonicTyrant].remains >17 ) or SoulShards == 5 or SoulShards == 4 and talents[classtable.FelInvocation] ) and ( targets == 1 )) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and (SoulShards >2 and not ( targets == 1 )) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (( ( not debuff[classtable.DoomDeBuff].up ) or targets <4 ) and buff[classtable.DemonicCoreBuff].count >1 and ( ( SoulShards <4 and not talents[classtable.SoulStrike] or cooldown[classtable.SoulStrike].remains >gcd * 2 and talents[classtable.FelInvocation] ) or SoulShards <3 ) and not pool_cores_for_tyrant) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (buff[classtable.DemonicCoreBuff].up and buff[classtable.TyrantBuff].up and SoulShards <3 - talents[classtable.Quietus]) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (buff[classtable.DemonicCoreBuff].count >1 and SoulShards <4 - talents[classtable.Quietus]) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (( ( not debuff[classtable.DoomDeBuff].up ) or targets <4 ) and talents[classtable.Doom] and ( debuff[classtable.DoomDeBuff].remains >10 and buff[classtable.DemonicCoreBuff].up and SoulShards <4 - (talents[classtable.Quietus] and talents[classtable.Quietus] or 0) ) and not pool_cores_for_tyrant) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (ttd <buff[classtable.DemonicCoreBuff].count * gcd) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demonbolt, 'Demonbolt')) and (( ( not debuff[classtable.DoomDeBuff].up ) or targets <4 ) and buff[classtable.DemonicCoreBuff].up and ( cooldown[classtable.PowerSiphon].remains <4 ) and ( SoulShards <4 - (talents[classtable.Quietus] and talents[classtable.Quietus] or 0) ) and not pool_cores_for_tyrant) and cooldown[classtable.Demonbolt].ready then
        if not setSpell then setSpell = classtable.Demonbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.PowerSiphon, 'PowerSiphon')) and (not buff[classtable.DemonicCoreBuff].up and cooldown[classtable.SummonDemonicTyrant].remains >25) and cooldown[classtable.PowerSiphon].ready then
        if not setSpell then setSpell = classtable.PowerSiphon end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonVilefiend, 'SummonVilefiend')) and (MaxDps:boss() and ttd <cooldown[classtable.SummonDemonicTyrant].remains + 5) and cooldown[classtable.SummonVilefiend].ready then
        if not setSpell then setSpell = classtable.SummonVilefiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernalBolt, 'InfernalBolt')) and cooldown[classtable.InfernalBolt].ready then
        if not setSpell then setSpell = classtable.InfernalBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
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
    SoulShards = UnitPower('player', SoulShardsPT)
    SoulShardsMax = UnitPowerMax('player', MaelstromPT)
    SoulShardsDeficit = SoulShardsMax - SoulShards
    classtable.SpellLock = 19647
    classtable.AxeToss = 119914
    classtable.Demonbolt = 264178
    classtable.InfernalBolt = 434506
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.GrimoireofSacrificeBuff = 0
    classtable.PowerSiphonBuff = 264130
    classtable.DemonicCoreBuff = 0
    classtable.DreadstalkersBuff = 0
    classtable.InfernalBoltBuff = 0
    classtable.bloodlust = 0
    classtable.DemonicCallingBuff = 205145
    classtable.DemonicArtPitLordBuff = 0
    classtable.GrimoireFelguardBuff = 111898
    classtable.VilefiendBuff = 0
    classtable.WildImpsBuff = 0
    classtable.TyrantBuff = 0
    classtable.DiabolicRitualMotherofChaosBuff = 432815
    classtable.DiabolicRitualOverlordBuff = 431944
    classtable.DiabolicRitualPitLordBuff = 432816
    classtable.DoomDeBuff = 460551
    setSpell = nil
    ClearCDs()

    Demonology:precombat()

    Demonology:callaction()
    if setSpell then return setSpell end
end
