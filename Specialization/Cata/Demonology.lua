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


function Demonology:precombat()
    if (MaxDps:CheckSpellUsable(classtable.SoulHarvest, 'SoulHarvest')) and (SoulShards <3) and cooldown[classtable.SoulHarvest].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SoulHarvest end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonFelguard, 'SummonFelguard')) and (not UnitExists('pet')) and cooldown[classtable.SummonFelguard].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SummonFelguard end
    end
    --if (MaxDps:CheckSpellUsable(classtable.SummonFelhunter, 'SummonFelhunter')) and (not false and not UnitExists('pet')) and cooldown[classtable.SummonFelhunter].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.SummonFelhunter end
    --end
    if (MaxDps:CheckSpellUsable(classtable.FelArmor, 'FelArmor')) and (not buff[classtable.FelArmorBuff].up) and cooldown[classtable.FelArmor].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FelArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulLink, 'SoulLink')) and (not buff[classtable.SoulLinkBuff].up) and cooldown[classtable.SoulLink].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SoulLink end
    end
    if (MaxDps:CheckSpellUsable(classtable.DemonSoul, 'DemonSoul')) and (UnitExists('pet') and false) and cooldown[classtable.DemonSoul].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DemonSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and cooldown[classtable.VolcanicPotion].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
end
function Demonology:spell_damage_rotation()
    if (MaxDps:CheckSpellUsable(classtable.DemonSoul, 'DemonSoul')) and (UnitExists('pet') and not buff[classtable.FelIntelligenceBuff].up) and cooldown[classtable.DemonSoul].ready then
        if not setSpell then setSpell = classtable.DemonSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ImmolationAura, 'ImmolationAura')) and (buff[classtable.MetamorphosisBuff].up and buff[classtable.MetamorphosisBuff].remains >2) and cooldown[classtable.ImmolationAura].ready then
        if not setSpell then setSpell = classtable.ImmolationAura end
    end
    if (MaxDps:CheckSpellUsable(classtable.Felstorm, 'Felstorm')) and (buff[classtable.DemonSoulFelguardBuff].up) and cooldown[classtable.Felstorm].ready then
        if not setSpell then setSpell = classtable.Felstorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.BaneofDoom, 'BaneofDoom')) and (not debuff[classtable.BaneofDoomDeBuff].up and ttd >15 and not debuff[classtable.BaneofAgonyDeBuff].up) and cooldown[classtable.BaneofDoom].ready then
        if not setSpell then setSpell = classtable.BaneofDoom end
    end
    if (MaxDps:CheckSpellUsable(classtable.BaneofAgony, 'BaneofAgony')) and (not debuff[classtable.BaneofAgonyDeBuff].up and ttd >25 and not debuff[classtable.BaneofDoomDeBuff].up) and cooldown[classtable.BaneofAgony].ready then
        if not setSpell then setSpell = classtable.BaneofAgony end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDoomguard, 'SummonDoomguard')) and (buff[classtable.DemonicPactBuff].up and buff[classtable.MoltenCoreBuff].count >= 1 and cooldown[classtable.HandofGuldan].remains <10) and cooldown[classtable.SummonDoomguard].ready then
        if not setSpell then setSpell = classtable.SummonDoomguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonInfernal, 'SummonInfernal')) and (false and ttd >45) and cooldown[classtable.SummonInfernal].ready then
        if not setSpell then setSpell = classtable.SummonInfernal end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowflame, 'Shadowflame')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) <7) and cooldown[classtable.Shadowflame].ready then
        if not setSpell then setSpell = classtable.Shadowflame end
    end
    if (targets >3) then
        Demonology:aoe()
    end
    if (targets <4) then
        Demonology:single_target_rotation()
    end
end
function Demonology:single_target_rotation()
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (not debuff[classtable.ImmolateDeBuff].up and debuff[classtable.ImmolateDeBuff].remains <1) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
    if (MaxDps:CheckSpellUsable(classtable.HandofGuldan, 'HandofGuldan')) and cooldown[classtable.HandofGuldan].ready then
        if not setSpell then setSpell = classtable.HandofGuldan end
    end
    if (MaxDps:CheckSpellUsable(classtable.BaneofDoom, 'BaneofDoom')) and (not debuff[classtable.BaneofDoomDeBuff].up and ttd >15 and not debuff[classtable.BaneofAgonyDeBuff].up) and cooldown[classtable.BaneofDoom].ready then
        if not setSpell then setSpell = classtable.BaneofDoom end
    end
    if (MaxDps:CheckSpellUsable(classtable.BaneofAgony, 'BaneofAgony')) and (not debuff[classtable.BaneofAgonyDeBuff].up and ttd >25 and not debuff[classtable.BaneofDoomDeBuff].up) and cooldown[classtable.BaneofAgony].ready then
        if not setSpell then setSpell = classtable.BaneofAgony end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (not debuff[classtable.CorruptionDeBuff].up) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowflame, 'Shadowflame')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) <7) and cooldown[classtable.Shadowflame].ready then
        if not setSpell then setSpell = classtable.Shadowflame end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and (buff[classtable.MoltenCoreBuff].up) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulFire, 'SoulFire')) and (targethealthPerc <25 and buff[classtable.DecimationBuff].up) and cooldown[classtable.SoulFire].ready then
        if not setSpell then setSpell = classtable.SoulFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incinerate, 'Incinerate')) and (MaxDps:HasGlyphEnabled(classtable.IncinerateGlyph)) and cooldown[classtable.Incinerate].ready then
        if not setSpell then setSpell = classtable.Incinerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (MaxDps:HasGlyphEnabled(classtable.CorruptionGlyph)) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Soulburn, 'Soulburn')) and (SoulShards >1 and false and not buff[classtable.FelIntelligenceBuff].up and not buff[classtable.DemonSoulFelguardBuff].up) and cooldown[classtable.Soulburn].ready then
        if not setSpell then setSpell = classtable.Soulburn end
    end
    --if (MaxDps:CheckSpellUsable(classtable.SummonFelhunter, 'SummonFelhunter')) and (buff[classtable.SoulburnBuff].up and not buff[classtable.FelIntelligenceBuff].up and false and not buff[classtable.DemonSoulFelguardBuff].up) and cooldown[classtable.SummonFelhunter].ready then
    --    if not setSpell then setSpell = classtable.SummonFelhunter end
    --end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end
function Demonology:aoe()
    if (MaxDps:CheckSpellUsable(classtable.DemonSoul, 'DemonSoul')) and (UnitExists('pet') and not buff[classtable.FelIntelligenceBuff].up) and cooldown[classtable.DemonSoul].ready then
        if not setSpell then setSpell = classtable.DemonSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Felstorm, 'Felstorm')) and (UnitExists('pet')) and cooldown[classtable.Felstorm].ready then
        if not setSpell then setSpell = classtable.Felstorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Metamorphosis, 'Metamorphosis')) and cooldown[classtable.Metamorphosis].ready then
        if not setSpell then setSpell = classtable.Metamorphosis end
    end
    if (MaxDps:CheckSpellUsable(classtable.ImmolationAura, 'ImmolationAura')) and (buff[classtable.MetamorphosisBuff].up) and cooldown[classtable.ImmolationAura].ready then
        if not setSpell then setSpell = classtable.ImmolationAura end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowflame, 'Shadowflame')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) <7) and cooldown[classtable.Shadowflame].ready then
        if not setSpell then setSpell = classtable.Shadowflame end
    end
    if (MaxDps:CheckSpellUsable(classtable.Hellfire, 'Hellfire')) and (targets >5) and cooldown[classtable.Hellfire].ready then
        if not setSpell then setSpell = classtable.Hellfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (targets <6) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Immolate, 'Immolate')) and (targets <6) and cooldown[classtable.Immolate].ready then
        if not setSpell then setSpell = classtable.Immolate end
    end
end


local function ClearCDs()
end

function Demonology:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Metamorphosis, 'Metamorphosis')) and cooldown[classtable.Metamorphosis].ready then
        if not setSpell then setSpell = classtable.Metamorphosis end
    end
    if (MaxDps:CheckSpellUsable(classtable.FelFlame, 'FelFlame')) and (buff[classtable.FelSparkBuff].up) and cooldown[classtable.FelFlame].ready then
        if not setSpell then setSpell = classtable.FelFlame end
    end
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and (buff[classtable.MetamorphosisBuff].up) and cooldown[classtable.VolcanicPotion].ready then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
    if (MaxDps:CheckSpellUsable(classtable.LifeTap, 'LifeTap')) and (ManaPerc <25) and cooldown[classtable.LifeTap].ready then
        if not setSpell then setSpell = classtable.LifeTap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Soulburn, 'Soulburn')) and (SoulShards >1 and buff[classtable.FelIntelligenceBuff].up and cooldown[classtable.DemonSoul].remains <6 and false) and cooldown[classtable.Soulburn].ready then
        if not setSpell then setSpell = classtable.Soulburn end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonFelguard, 'SummonFelguard')) and (buff[classtable.FelIntelligenceBuff].up and cooldown[classtable.DemonSoul].remains <6 and false) and cooldown[classtable.SummonFelguard].ready then
        if not setSpell then setSpell = classtable.SummonFelguard end
    end
    if (MaxDps:CheckSpellUsable(classtable.GroupCurse, 'GroupCurse')) and (not debuff[classtable.MyCurseDeBuff].up and MaxDps:NumGroupFriends() >1) and cooldown[classtable.GroupCurse].ready then
        if not setSpell then setSpell = classtable.GroupCurse end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoloCurse, 'SoloCurse')) and (not debuff[classtable.MyCurseDeBuff].up) and cooldown[classtable.SoloCurse].ready then
        if not setSpell then setSpell = classtable.SoloCurse end
    end
    if (buff[classtable.MetamorphosisBuff].up and buff[classtable.MetamorphosisBuff].remains >2) then
        Demonology:spell_damage_rotation()
    end
    if (targets >= 4 and cooldown[classtable.Metamorphosis].remains >1) then
        Demonology:aoe()
    end
    if (targets <4 and cooldown[classtable.Metamorphosis].remains >1) then
        Demonology:single_target_rotation()
    end
    if (targets >= 4 and not talents[59672]) then
        Demonology:aoe()
    end
    if (targets <4 and not talents[59672]) then
        Demonology:single_target_rotation()
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
    classtable.SoloCurse = 980
    classtable.GroupCurse = 1490
    classtable.MyCurseDeBuff = (MaxDps:NumGroupFriends() <= 1 and classtable.SoloCurse or MaxDps:NumGroupFriends() > 1 and classtable.GroupCurse) or classtable.SoloCurse
    classtable.AxeToss = 119914
    classtable.Demonbolt = 264178
    classtable.InfernalBolt = 434506
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.FelArmorBuff = 28176
    classtable.SoulLinkBuff = 25228
    classtable.FelSparkBuff = 89937
    classtable.MetamorphosisBuff = 47241
    classtable.FelIntelligenceBuff = 54424
    classtable.DemonSoulFelguardBuff = 79462
    classtable.DemonicPactBuff = 53646
    classtable.MoltenCoreBuff = 71165
    classtable.DecimationBuff = 63167
    classtable.SoulburnBuff = 74434
    classtable.ShadowandFlameDeBuff = 17800
    classtable.BaneofAgonyDeBuff = 980
    classtable.BaneofDoomDeBuff = 603
    classtable.ImmolateDeBuff = 348
    classtable.CorruptionDeBuff = 172
    classtable.SoulHarvest = 79268
    classtable.SummonFelguard = 30146
    classtable.SummonFelhunter = 691
    classtable.FelArmor = 28176
    classtable.SoulLink = 19028
    classtable.DemonSoul = 77801
    classtable.VolcanicPotion = 58091
    classtable.ImmolationAura = 50589
    classtable.Felstorm = 89751
    classtable.BaneofDoom = 603
    classtable.BaneofAgony = 980
    classtable.SummonDoomguard = 18540
    classtable.HandofGuldan = 71521
    classtable.SummonInfernal = 1122
    classtable.Shadowflame = 47897
    classtable.Immolate = 348
    classtable.Corruption = 172
    classtable.Incinerate = 29722
    classtable.SoulFire = 6353
    classtable.ShadowBolt = 686
    classtable.Soulburn = 74434
    classtable.Metamorphosis = 47241
    classtable.Hellfire = 1949
    classtable.FelFlame = 77799
    classtable.LifeTap = 1454
    classtable.GroupCurse = 1490
    classtable.CurseoftheElements = 1490
    classtable.SoloCurse = 980
    classtable.BaneofAgony = 980
    classtable.IncinerateGlyph = 56242
    classtable.CorruptionGlyph = 56218

    local function debugg()
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
