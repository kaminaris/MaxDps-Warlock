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

local Demonology = {}



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




local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Metamorphosis, false)
end

function Demonology:callaction()
    if (MaxDps:CheckSpellUsable(classtable.FelArmor, 'FelArmor')) and cooldown[classtable.FelArmor].ready then
        if not setSpell then setSpell = classtable.FelArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonFelguard, 'SummonFelguard')) and (not UnitAffectingCombat('player')) and cooldown[classtable.SummonFelguard].ready then
        if not setSpell then setSpell = classtable.SummonFelguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.DarkIntent, 'DarkIntent')) and cooldown[classtable.DarkIntent].ready then
        if not setSpell then setSpell = classtable.DarkIntent end
    end
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and (buff[classtable.MetamorphosisBuff].up or not UnitAffectingCombat('player')) and cooldown[classtable.VolcanicPotion].ready then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Metamorphosis, 'Metamorphosis')) and cooldown[classtable.Metamorphosis].ready then
        MaxDps:GlowCooldown(classtable.Metamorphosis, cooldown[classtable.Metamorphosis].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DemonSoul, 'DemonSoul')) and cooldown[classtable.DemonSoul].ready then
        if not setSpell then setSpell = classtable.DemonSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.BaneofDoom, 'BaneofDoom')) and (not debuff[classtable.BaneofDoomDeBuff].up and timeInCombat <10) and cooldown[classtable.BaneofDoom].ready then
        if not setSpell then setSpell = classtable.BaneofDoom end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDoomguard, 'SummonDoomguard')) and (timeInCombat >10) and cooldown[classtable.SummonDoomguard].ready then
        if not setSpell then setSpell = classtable.SummonDoomguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.Felguardfelstorm, 'Felguardfelstorm')) and cooldown[classtable.Felguardfelstorm].ready then
        if not setSpell then setSpell = classtable.Felguardfelstorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Soulburn, 'Soulburn')) and (( UnitExists('pet') and UnitName('pet')  == 'felguard' )) and cooldown[classtable.Soulburn].ready then
        if not setSpell then setSpell = classtable.Soulburn end
    end
    --if (MaxDps:CheckSpellUsable(classtable.SummonFelhunter, 'SummonFelhunter')) and (not pet.felguard.debuff.felstorm.ticking and ( UnitExists('pet') and UnitName('pet')  == 'felguard' )) and cooldown[classtable.SummonFelhunter].ready then
    --    if not setSpell then setSpell = classtable.SummonFelhunter end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Soulburn, 'Soulburn')) and (( UnitExists('pet') and UnitName('pet')  == 'felhunter' )) and cooldown[classtable.Soulburn].ready then
        if not setSpell then setSpell = classtable.Soulburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (( UnitExists('pet') and UnitName('pet')  == 'felhunter' ) and buff[classtable.SoulburnBuff].up) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (not debuff[classtable.ImmolateDeBuff].up and ttd >= 4) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.BaneofDoom, 'BaneofDoom')) and (( not debuff[classtable.BaneofDoomDeBuff].up or ( buff[classtable.MetamorphosisBuff].up and debuff[classtable.BaneofDoomDeBuff].remains <45 ) ) and ttd >= 15) and cooldown[classtable.BaneofDoom].ready then
        if not setSpell then setSpell = classtable.BaneofDoom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (( debuff[classtable.CorruptionDeBuff].remains <buff[classtable.CorruptionBuff].duration or not debuff[classtable.CorruptionDeBuff].up ) and ttd >= 6) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowflame, 'Shadowflame')) and cooldown[classtable.Shadowflame].ready then
        if not setSpell then setSpell = classtable.Shadowflame end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.ImmolationAura, 'ImmolationAura')) and (buff[classtable.MetamorphosisBuff].remains >10) and cooldown[classtable.ImmolationAura].ready then
        if not setSpell then setSpell = classtable.ImmolationAura end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and (buff[classtable.MoltenCoreBuff].up) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (buff[classtable.DecimationBuff].up) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <= 30 and MaxDps:Bloodlust() and not buff[classtable.MetamorphosisBuff].up and not buff[classtable.DemonSoulFelguardBuff].up) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <80 and ManaPerc <targetHP) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.FelFlame, 'FelFlame')) and cooldown[classtable.FelFlame].ready then
        if not setSpell then setSpell = classtable.FelFlame end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <100) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
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
    ManaPerc = (Mana / ManaMax) * 100
    SoulShards = UnitPower('player', SoulShardsPT)
    SoulShardsMax = UnitPowerMax('player', MaelstromPT)
    SoulShardsDeficit = SoulShardsMax - SoulShards
    classtable.SpellLock = 19647
    classtable.AxeToss = 119914
    classtable.Demonbolt = 264178
    classtable.InfernalBolt = 434506
    classtable.ImmolationAura = 50589
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.MetamorphosisBuff = 0
    classtable.BaneofDoomDeBuff = 0
    classtable.SoulburnBuff = 0
    classtable.ImmolateDeBuff = 157736
    classtable.CorruptionDeBuff = 0
    classtable.MoltenCoreBuff = 0
    classtable.DecimationBuff = 0
    classtable.bloodlust = 0
    classtable.DemonSoulFelguardBuff = 0

    local function debugg()
    end


    if MaxDps.db.global.debugMode then
        debugg()
    end

    setSpell = nil
    ClearCDs()

    Demonology:callaction()
    if setSpell then return setSpell end
end
