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

local Affliction = {}

local cleave_apl
local trinket_1_buffs
local trinket_2_buffs
local trinket_1_sync
local trinket_2_sync
local trinket_1_manual
local trinket_2_manual
local trinket_1_exclude
local trinket_2_exclude
local trinket_1_buff_duration
local trinket_2_buff_duration
local trinket_priority
local min_agony
local min_vt
local min_ps
local min_ps1
local ps_up
local vt_up
local vt_ps_up
local sr_up
local cd_dots_up
local has_cds
local cds_active
local min_vt
local min_ps


local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end


function Affliction:precombat()
    if (MaxDps:CheckSpellUsable(classtable.FelDomination, 'FelDomination')) and (timeInCombat >0 and not UnitExists('pet')) and cooldown[classtable.FelDomination].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FelDomination end
    end
    cleave_apl = false
    if (MaxDps:CheckSpellUsable(classtable.GrimoireofSacrifice, 'GrimoireofSacrifice')) and (talents[classtable.GrimoireofSacrifice]) and cooldown[classtable.GrimoireofSacrifice].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.GrimoireofSacrifice end
    end
    if (MaxDps:CheckSpellUsable(classtable.SeedofCorruption, 'SeedofCorruption')) and (targets >2 or targets >1 and talents[classtable.DemonicSoul]) and cooldown[classtable.SeedofCorruption].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SeedofCorruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and cooldown[classtable.Haunt].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Haunt end
    end
end
function Affliction:aoe()
    min_agony = debuff[classtable.AgonyDeBuff].remains
    min_vt = debuff[classtable.VileTaintDeBuff].remains
    min_ps = debuff[classtable.PhantomSingularityDeBuff].remains
    min_ps1 = ( min_vt * (talents[classtable.VileTaint] and talents[classtable.VileTaint] or 0) ) <( min_ps * (talents[classtable.PhantomSingularity] and talents[classtable.PhantomSingularity] or 0) )
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (debuff[classtable.HauntDeBuff].remains <3) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.VileTaint, 'VileTaint')) and (( cooldown[classtable.SoulRot].remains <= timeShift or cooldown[classtable.SoulRot].remains >= 25 )) and cooldown[classtable.VileTaint].ready then
        if not setSpell then setSpell = classtable.VileTaint end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhantomSingularity, 'PhantomSingularity')) and (( cooldown[classtable.SoulRot].remains <= timeShift or cooldown[classtable.SoulRot].remains >= 25 ) and debuff[classtable.AgonyDeBuff].remains) and cooldown[classtable.PhantomSingularity].ready then
        if not setSpell then setSpell = classtable.PhantomSingularity end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (( debuff[classtable.UnstableAfflictionDeBuff].count  == 0 or debuff[classtable.UnstableAfflictionDeBuff].up ) and debuff[classtable.UnstableAfflictionDeBuff].remains <5) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.Agony, 'Agony')) and (debuff[classtable.AgonyDeBuff].count  <8 and ( debuff[classtable.AgonyDeBuff].remains <cooldown[classtable.VileTaint].remains + ( classtable and classtable.VileTaint and GetSpellInfo(classtable.VileTaint).castTime / 1000 ) or not talents[classtable.VileTaint] ) and gcd + ( classtable and classtable.SoulRot and GetSpellInfo(classtable.SoulRot).castTime / 1000 ) + gcd <( ( min_vt * (talents[classtable.VileTaint] and talents[classtable.VileTaint] or 0) ) <( min_ps * (talents[classtable.PhantomSingularity] and talents[classtable.PhantomSingularity] or 0) ) ) and debuff[classtable.AgonyDeBuff].remains <10) and cooldown[classtable.Agony].ready then
        if not setSpell then setSpell = classtable.Agony end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulRot, 'SoulRot')) and (vt_up and ( ps_up or vt_up ) and debuff[classtable.AgonyDeBuff].remains) and cooldown[classtable.SoulRot].ready then
        if not setSpell then setSpell = classtable.SoulRot end
    end
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence')) and (ps_up and vt_up and sr_up) and cooldown[classtable.Malevolence].ready then
        if not setSpell then setSpell = classtable.Malevolence end
    end
    if (MaxDps:CheckSpellUsable(classtable.SeedofCorruption, 'SeedofCorruption')) and (( ( not talents[classtable.Wither] and debuff[classtable.CorruptionDeBuff].remains <5 ) or ( talents[classtable.Wither] and debuff[classtable.WitherDeBuff].remains <5 ) ) and not ( (classtable and classtable.SeedofCorruption and cooldown[classtable.SeedofCorruption].duration - cooldown[classtable.SeedofCorruption].remains <=2 ) or debuff[classtable.SeedofCorruptionDeBuff].count  >0 )) and cooldown[classtable.SeedofCorruption].ready then
        if not setSpell then setSpell = classtable.SeedofCorruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (debuff[classtable.CorruptionDeBuff].remains <5 and not talents[classtable.SeedofCorruption]) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither')) and (debuff[classtable.WitherDeBuff].remains <5 and not talents[classtable.SeedofCorruption]) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDarkglare, 'SummonDarkglare')) and (ps_up and vt_up and sr_up) and cooldown[classtable.SummonDarkglare].ready then
        if not setSpell then setSpell = classtable.SummonDarkglare end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (( cooldown[classtable.SummonDarkglare].remains >15 or SoulShards >3 or ( talents[classtable.DemonicSoul] and SoulShards >2 ) ) and buff[classtable.TormentedCrescendoBuff].up) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (SoulShards >4 or ( talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].count == 1 and SoulShards >3 )) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.DemonicSoul] and ( SoulShards >2 or ( talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].count == 1 and SoulShards ) )) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].up) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].count == 2) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (( cd_dots_up or vt_ps_up ) and ( SoulShards >2 or cooldown[classtable.Oblivion].remains >10 or not talents[classtable.Oblivion] )) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and talents[classtable.Nightfall] and buff[classtable.TormentedCrescendoBuff].up and buff[classtable.NightfallBuff].up) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (talents[classtable.DrainSoul] and buff[classtable.NightfallBuff].up and talents[classtable.ShadowEmbrace] and ( debuff[classtable.ShadowEmbraceDeBuff].count <4 or debuff[classtable.ShadowEmbraceDeBuff].remains <3 )) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (talents[classtable.DrainSoul] and ( talents[classtable.ShadowEmbrace] and ( debuff[classtable.ShadowEmbraceDeBuff].count <4 or debuff[classtable.ShadowEmbraceDeBuff].remains <3 ) ) or not talents[classtable.ShadowEmbrace]) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (buff[classtable.NightfallBuff].up and talents[classtable.ShadowEmbrace] and ( debuff[classtable.ShadowEmbraceDeBuff].count <2 or debuff[classtable.ShadowEmbraceDeBuff].remains <3 )) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end
function Affliction:cleave()
    if (MaxDps:boss()) then
        Affliction:end_of_fight()
    end
    if (MaxDps:CheckSpellUsable(classtable.Agony, 'Agony')) and (debuff[classtable.AgonyDeBuff].refreshable and ( debuff[classtable.AgonyDeBuff].remains <cooldown[classtable.VileTaint].remains + ( classtable and classtable.VileTaint and GetSpellInfo(classtable.VileTaint).castTime / 1000 ) or not talents[classtable.VileTaint] ) and ( debuff[classtable.AgonyDeBuff].remains <gcd * 2 or talents[classtable.DemonicSoul] and debuff[classtable.AgonyDeBuff].remains <cooldown[classtable.SoulRot].remains + 8 and cooldown[classtable.SoulRot].remains <5 ) and ttd >debuff[classtable.AgonyDeBuff].remains + 5) and cooldown[classtable.Agony].ready then
        if not setSpell then setSpell = classtable.Agony end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither')) and (debuff[classtable.WitherDeBuff].refreshable and debuff[classtable.WitherDeBuff].remains <5 and not ( (classtable and classtable.SeedofCorruption and cooldown[classtable.SeedofCorruption].duration - cooldown[classtable.SeedofCorruption].remains <=2 ) or debuff[classtable.SeedofCorruptionDeBuff].remains >0 ) and ttd >debuff[classtable.WitherDeBuff].remains + 5) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].count <2 - (MaxDps.spellHistory[1] == classtable.DrainSoul and 1 or 0) and ( not talents[classtable.VileTaint] or cooldown[classtable.VileTaint].ready==false ) or debuff[classtable.HauntDeBuff].remains <3) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (( debuff[classtable.UnstableAfflictionDeBuff].remains <5 or talents[classtable.DemonicSoul] and debuff[classtable.UnstableAfflictionDeBuff].remains <cooldown[classtable.SoulRot].remains + 8 and cooldown[classtable.SoulRot].remains <5 ) and ttd >debuff[classtable.UnstableAfflictionDeBuff].remains + 5) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (debuff[classtable.CorruptionDeBuff].refreshable and debuff[classtable.CorruptionDeBuff].remains <5 and not ( (classtable and classtable.SeedofCorruption and cooldown[classtable.SeedofCorruption].duration - cooldown[classtable.SeedofCorruption].remains <=2 ) or debuff[classtable.SeedofCorruptionDeBuff].remains >0 ) and ttd >debuff[classtable.CorruptionDeBuff].remains + 5) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (talents[classtable.Wither]) then
        Affliction:cleave_se_maintenance()
    end
    if (MaxDps:CheckSpellUsable(classtable.VileTaint, 'VileTaint')) and (not talents[classtable.SoulRot] or ( min_agony <1.5 or cooldown[classtable.SoulRot].remains <= timeShift + gcd ) or cooldown[classtable.SoulRot].remains >= 20) and cooldown[classtable.VileTaint].ready then
        if not setSpell then setSpell = classtable.VileTaint end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhantomSingularity, 'PhantomSingularity')) and (( not talents[classtable.SoulRot] or cooldown[classtable.SoulRot].remains <4 or ttd <cooldown[classtable.SoulRot].remains ) and debuff[classtable.AgonyDeBuff].count  == 2) and cooldown[classtable.PhantomSingularity].ready then
        if not setSpell then setSpell = classtable.PhantomSingularity end
    end
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence')) and (vt_ps_up) and cooldown[classtable.Malevolence].ready then
        if not setSpell then setSpell = classtable.Malevolence end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulRot, 'SoulRot')) and (( vt_ps_up ) and debuff[classtable.AgonyDeBuff].count  == 2) and cooldown[classtable.SoulRot].ready then
        if not setSpell then setSpell = classtable.SoulRot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDarkglare, 'SummonDarkglare')) and (cd_dots_up) and cooldown[classtable.SummonDarkglare].ready then
        if not setSpell then setSpell = classtable.SummonDarkglare end
    end
    if (talents[classtable.DemonicSoul]) then
        Affliction:opener_cleave_se()
    end
    if (talents[classtable.DemonicSoul]) then
        Affliction:cleave_se_maintenance()
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (SoulShards >4 and ( talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].count <2 or not talents[classtable.DemonicSoul] ) or buff[classtable.TormentedCrescendoBuff].count >1) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].up and buff[classtable.TormentedCrescendoBuff].count <2 and targetHP <20) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.DemonicSoul] and ( SoulShards >1 or buff[classtable.TormentedCrescendoBuff].up and cooldown[classtable.SoulRot].remains >buff[classtable.TormentedCrescendoBuff].remains * gcd ) and ( not talents[classtable.VileTaint] or SoulShards >1 and cooldown[classtable.VileTaint].remains >10 ) and ( not talents[classtable.Oblivion] or cooldown[classtable.Oblivion].remains >10 or SoulShards >2 and cooldown[classtable.Oblivion].remains <10 )) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].up and ( buff[classtable.TormentedCrescendoBuff].remains <gcd * 2 or buff[classtable.TormentedCrescendoBuff].count == 2 )) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (( cd_dots_up or ( talents[classtable.DemonicSoul] or talents[classtable.PhantomSingularity] ) and vt_ps_up or talents[classtable.Wither] and vt_ps_up and not debuff[classtable.SoulRotDeBuff].duration and SoulShards >1 ) and ( not talents[classtable.Oblivion] or cooldown[classtable.Oblivion].remains >10 or SoulShards >2 and cooldown[classtable.Oblivion].remains <10 )) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and talents[classtable.Nightfall] and buff[classtable.TormentedCrescendoBuff].up and buff[classtable.NightfallBuff].up or talents[classtable.DemonicSoul] and not buff[classtable.NightfallBuff].up and ( not talents[classtable.VileTaint] or cooldown[classtable.VileTaint].remains >10 or SoulShards >1 and cooldown[classtable.VileTaint].remains <10 )) and cooldown[classtable.MaleficRapture].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (buff[classtable.NightfallBuff].up) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (buff[classtable.NightfallBuff].up) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither')) and (debuff[classtable.WitherDeBuff].refreshable) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (debuff[classtable.CorruptionDeBuff].refreshable) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end
function Affliction:end_of_fight()
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (talents[classtable.DemonicSoul] and ( MaxDps:boss() and ttd <5 and buff[classtable.NightfallBuff].up or (MaxDps.spellHistory[1] == classtable.Haunt) and buff[classtable.NightfallBuff].count == 2 and not buff[classtable.TormentedCrescendoBuff].up )) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Oblivion, 'Oblivion')) and (SoulShards >1 and MaxDps:boss() and ttd <( SoulShards + buff[classtable.TormentedCrescendoBuff].duration ) * gcd + timeShift) and cooldown[classtable.Oblivion].ready then
        if not setSpell then setSpell = classtable.Oblivion end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (MaxDps:boss() and ttd <4 and ( not talents[classtable.DemonicSoul] or talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].count <1 )) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
end
function Affliction:se_maintenance()
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (talents[classtable.ShadowEmbrace] and talents[classtable.DrainSoul] and ( debuff[classtable.ShadowEmbraceDeBuff].count <debuff[classtable.ShadowEmbraceDeBuff].maxStacks or debuff[classtable.ShadowEmbraceDeBuff].remains <3 ) and targets <= 4 and ttd >15) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (talents[classtable.ShadowEmbrace] and ( ( debuff[classtable.ShadowEmbraceDeBuff].count + ( (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.ShadowBolt] and GetTime() - MaxDps.spellHistoryTime[classtable.ShadowBolt].last_used or 0) <1 ) ) <debuff[classtable.ShadowEmbraceDeBuff].maxStacks or debuff[classtable.ShadowEmbraceDeBuff].remains <3 and not (classtable and classtable.ShadowBolt and cooldown[classtable.ShadowBolt].duration - cooldown[classtable.ShadowBolt].remains <=2 ) ) and targets <= 4 and ttd >15) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end
function Affliction:opener_cleave_se()
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (talents[classtable.ShadowEmbrace] and talents[classtable.DrainSoul] and buff[classtable.NightfallBuff].up and ( debuff[classtable.ShadowEmbraceDeBuff].count <debuff[classtable.ShadowEmbraceDeBuff].maxStacks or debuff[classtable.ShadowEmbraceDeBuff].remains <3 ) and ( ttd >15 or timeInCombat <20 )) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
end
function Affliction:cleave_se_maintenance()
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (talents[classtable.ShadowEmbrace] and talents[classtable.DrainSoul] and ( talents[classtable.Wither] or talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].up ) and ( debuff[classtable.ShadowEmbraceDeBuff].count <debuff[classtable.ShadowEmbraceDeBuff].maxStacks or debuff[classtable.ShadowEmbraceDeBuff].remains <3 ) and ttd >15) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (talents[classtable.ShadowEmbrace] and not talents[classtable.DrainSoul] and ( ( debuff[classtable.ShadowEmbraceDeBuff].count + (classtable and classtable.ShadowBolt and MaxDps.spellHistory[1] == classtable.ShadowBolt and 1 or 0) ) <debuff[classtable.ShadowEmbraceDeBuff].maxStacks or debuff[classtable.ShadowEmbraceDeBuff].remains <3 and not (classtable and classtable.ShadowBolt and cooldown[classtable.ShadowBolt].duration - cooldown[classtable.ShadowBolt].remains <=2 ) ) and ttd >15) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
end
function Affliction:items()
end
function Affliction:ogcd()
end
function Affliction:variables()
    ps_up = not talents[classtable.PhantomSingularity] or debuff[classtable.PhantomSingularityDeBuff].up
    vt_up = not talents[classtable.VileTaint] or debuff[classtable.VileTaintDebuffDeBuff].up
    vt_ps_up = ( not talents[classtable.VileTaint] and not talents[classtable.PhantomSingularity] ) or debuff[classtable.VileTaintDebuffDeBuff].up or debuff[classtable.PhantomSingularityDeBuff].up
    sr_up = not talents[classtable.SoulRot] or debuff[classtable.SoulRotDeBuff].up
    cd_dots_up = ps_up and vt_up and sr_up
    has_cds = talents[classtable.PhantomSingularity] or talents[classtable.VileTaint] or talents[classtable.SoulRot] or talents[classtable.SummonDarkglare]
    cds_active = not has_cds or ( cd_dots_up and ( not talents[classtable.SummonDarkglare] or cooldown[classtable.SummonDarkglare].remains >20 or GetTotemDuration('darkglare') ) )
    if min_vt then
        min_vt = min_vt
    end
    if min_ps then
        min_ps = min_ps
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.SpellLock, false)
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
    if (MaxDps:CheckSpellUsable(classtable.Agony, 'Agony')) and (( not talents[classtable.VileTaint] or debuff[classtable.AgonyDeBuff].remains <cooldown[classtable.VileTaint].remains + ( classtable and classtable.VileTaint and GetSpellInfo(classtable.VileTaint).castTime / 1000 ) ) and ( talents[classtable.AbsoluteCorruption] and debuff[classtable.AgonyDeBuff].remains <3 or not talents[classtable.AbsoluteCorruption] and debuff[classtable.AgonyDeBuff].remains <5 or cooldown[classtable.SoulRot].remains <5 and debuff[classtable.AgonyDeBuff].remains <8 ) and ttd >debuff[classtable.AgonyDeBuff].remains + 5) and cooldown[classtable.Agony].ready then
        if not setSpell then setSpell = classtable.Agony end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].count <2 - (MaxDps.spellHistory[1] == classtable.DrainSoul and 1 or 0) and ( not talents[classtable.VileTaint] or cooldown[classtable.VileTaint].ready==false )) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (( debuff[classtable.UnstableAfflictionDeBuff].count  == 0 or debuff[classtable.UnstableAfflictionDeBuff].up ) and ( talents[classtable.AbsoluteCorruption] and debuff[classtable.UnstableAfflictionDeBuff].remains <3 or not talents[classtable.AbsoluteCorruption] and debuff[classtable.UnstableAfflictionDeBuff].remains <5 or cooldown[classtable.SoulRot].remains <5 and debuff[classtable.UnstableAfflictionDeBuff].remains <8 ) and ( not talents[classtable.DemonicSoul] or buff[classtable.NightfallBuff].count <2 or (MaxDps.spellHistory[1] == classtable.Haunt) and buff[classtable.NightfallBuff].count <2 ) and ttd >debuff[classtable.UnstableAfflictionDeBuff].remains + 5) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.Haunt, 'Haunt')) and (( talents[classtable.AbsoluteCorruption] and debuff[classtable.HauntDeBuff].remains <3 or not talents[classtable.AbsoluteCorruption] and debuff[classtable.HauntDeBuff].remains <5 or cooldown[classtable.SoulRot].remains <5 and debuff[classtable.HauntDeBuff].remains <8 ) and ( not talents[classtable.VileTaint] or cooldown[classtable.VileTaint].ready==false ) and ttd >debuff[classtable.HauntDeBuff].remains + 5) and cooldown[classtable.Haunt].ready then
        if not setSpell then setSpell = classtable.Haunt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wither, 'Wither')) and (talents[classtable.Wither] and not ( (classtable and classtable.SeedofCorruption and cooldown[classtable.SeedofCorruption].duration - cooldown[classtable.SeedofCorruption].remains <=2 ) or debuff[classtable.SeedofCorruptionDeBuff].count  >0 ) and ( talents[classtable.AbsoluteCorruption] and debuff[classtable.WitherDeBuff].remains <3 or not talents[classtable.AbsoluteCorruption] and debuff[classtable.WitherDeBuff].remains <5 ) and ttd >debuff[classtable.WitherDeBuff].remains + 5) and cooldown[classtable.Wither].ready then
        if not setSpell then setSpell = classtable.Wither end
    end
    if (MaxDps:CheckSpellUsable(classtable.Corruption, 'Corruption')) and (not ( (classtable and classtable.SeedofCorruption and cooldown[classtable.SeedofCorruption].duration - cooldown[classtable.SeedofCorruption].remains <=2 ) or debuff[classtable.SeedofCorruptionDeBuff].count  >0 ) and debuff[classtable.CorruptionDeBuff].refreshable and ttd >debuff[classtable.CorruptionDeBuff].remains + 5) and cooldown[classtable.Corruption].ready then
        if not setSpell then setSpell = classtable.Corruption end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (buff[classtable.NightfallBuff].up and ( buff[classtable.NightfallBuff].count >1 or buff[classtable.NightfallBuff].remains <timeShift * 2 ) and not buff[classtable.TormentedCrescendoBuff].up and cooldown[classtable.SoulRot].ready==false and SoulShards <5 - buff[classtable.TormentedCrescendoBuff].duration and ( not talents[classtable.VileTaint] or cooldown[classtable.VileTaint].ready==false )) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (buff[classtable.NightfallBuff].up and ( buff[classtable.NightfallBuff].count >1 or buff[classtable.NightfallBuff].remains <timeShift * 2 ) and buff[classtable.TormentedCrescendoBuff].count <2 and cooldown[classtable.SoulRot].ready==false and SoulShards <5 - buff[classtable.TormentedCrescendoBuff].duration and ( not talents[classtable.VileTaint] or cooldown[classtable.VileTaint].ready==false )) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (talents[classtable.Wither]) then
        Affliction:se_maintenance()
    end
    if (MaxDps:CheckSpellUsable(classtable.VileTaint, 'VileTaint')) and (( not talents[classtable.SoulRot] or cooldown[classtable.SoulRot].remains >20 or cooldown[classtable.SoulRot].remains <= timeShift + gcd or MaxDps:boss() and ttd <cooldown[classtable.SoulRot].remains ) and debuff[classtable.AgonyDeBuff].remains and ( debuff[classtable.CorruptionDeBuff].remains or debuff[classtable.WitherDeBuff].remains ) and debuff[classtable.UnstableAfflictionDeBuff].remains) and cooldown[classtable.VileTaint].ready then
        if not setSpell then setSpell = classtable.VileTaint end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhantomSingularity, 'PhantomSingularity')) and (( not talents[classtable.SoulRot] or cooldown[classtable.SoulRot].remains <4 or MaxDps:boss() and ttd <cooldown[classtable.SoulRot].remains ) and debuff[classtable.AgonyDeBuff].remains and ( debuff[classtable.CorruptionDeBuff].remains or debuff[classtable.WitherDeBuff].remains ) and debuff[classtable.UnstableAfflictionDeBuff].remains) and cooldown[classtable.PhantomSingularity].ready then
        if not setSpell then setSpell = classtable.PhantomSingularity end
    end
    if (MaxDps:CheckSpellUsable(classtable.Malevolence, 'Malevolence')) and (vt_ps_up) and cooldown[classtable.Malevolence].ready then
        if not setSpell then setSpell = classtable.Malevolence end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulRot, 'SoulRot')) and (vt_ps_up) and cooldown[classtable.SoulRot].ready then
        if not setSpell then setSpell = classtable.SoulRot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonDarkglare, 'SummonDarkglare')) and (cd_dots_up and ( debuff[classtable.ShadowEmbraceDeBuff].count == debuff[classtable.ShadowEmbraceDeBuff].maxStacks )) and cooldown[classtable.SummonDarkglare].ready then
        if not setSpell then setSpell = classtable.SummonDarkglare end
    end
    if (talents[classtable.DemonicSoul]) then
        Affliction:se_maintenance()
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (SoulShards >4 and ( talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].count <2 or not talents[classtable.DemonicSoul] ) or buff[classtable.TormentedCrescendoBuff].count >1) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (talents[classtable.DemonicSoul] and buff[classtable.NightfallBuff].up and buff[classtable.TormentedCrescendoBuff].count <2 and targetHP <20) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.DemonicSoul] and ( SoulShards >1 or buff[classtable.TormentedCrescendoBuff].up and cooldown[classtable.SoulRot].remains >buff[classtable.TormentedCrescendoBuff].remains * gcd ) and ( not talents[classtable.VileTaint] or SoulShards >1 and cooldown[classtable.VileTaint].remains >10 ) and ( not talents[classtable.Oblivion] or cooldown[classtable.Oblivion].remains >10 or SoulShards >2 and cooldown[classtable.Oblivion].remains <10 )) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Oblivion, 'Oblivion')) and (debuff[classtable.AgonyDeBuff].remains and ( debuff[classtable.CorruptionDeBuff].remains or debuff[classtable.WitherDeBuff].remains ) and debuff[classtable.UnstableAfflictionDeBuff].remains and debuff[classtable.HauntDeBuff].remains >5) and cooldown[classtable.Oblivion].ready then
        if not setSpell then setSpell = classtable.Oblivion end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and buff[classtable.TormentedCrescendoBuff].up and ( buff[classtable.TormentedCrescendoBuff].remains <gcd * 2 or buff[classtable.TormentedCrescendoBuff].count == 2 )) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (( cd_dots_up or ( talents[classtable.DemonicSoul] or talents[classtable.PhantomSingularity] ) and vt_ps_up or talents[classtable.Wither] and vt_ps_up and not debuff[classtable.SoulRotDeBuff].duration and SoulShards >2 ) and ( not talents[classtable.Oblivion] or cooldown[classtable.Oblivion].remains >10 or SoulShards >2 and cooldown[classtable.Oblivion].remains <10 )) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (talents[classtable.TormentedCrescendo] and talents[classtable.Nightfall] and buff[classtable.TormentedCrescendoBuff].up and buff[classtable.NightfallBuff].up or talents[classtable.DemonicSoul] and not buff[classtable.NightfallBuff].up and ( not talents[classtable.VileTaint] or cooldown[classtable.VileTaint].remains >10 or SoulShards >1 and cooldown[classtable.VileTaint].remains <10 )) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.MaleficRapture, 'MaleficRapture')) and (not talents[classtable.DemonicSoul] and buff[classtable.TormentedCrescendoBuff].up) and cooldown[classtable.MaleficRapture].ready then
        if not setSpell then setSpell = classtable.MaleficRapture end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and (buff[classtable.NightfallBuff].up) and cooldown[classtable.DrainSoul].ready then
        if not setSpell then setSpell = classtable.DrainSoul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBolt, 'ShadowBolt')) and (buff[classtable.NightfallBuff].up) and cooldown[classtable.ShadowBolt].ready then
        if not setSpell then setSpell = classtable.ShadowBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Agony, 'Agony')) and (debuff[classtable.AgonyDeBuff].refreshable) and cooldown[classtable.Agony].ready then
        if not setSpell then setSpell = classtable.Agony end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnstableAffliction, 'UnstableAffliction')) and (( debuff[classtable.UnstableAfflictionDeBuff].count  == 0 or debuff[classtable.UnstableAfflictionDeBuff].up ) and debuff[classtable.UnstableAfflictionDeBuff].refreshable) and cooldown[classtable.UnstableAffliction].ready then
        if not setSpell then setSpell = classtable.UnstableAffliction end
    end
    if (MaxDps:CheckSpellUsable(classtable.DrainSoul, 'DrainSoul')) and cooldown[classtable.DrainSoul].ready then
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
    classtable.Wither = 445468
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.AgonyDeBuff = 980
    classtable.VileTaintDeBuff = 386931
    classtable.PhantomSingularityDeBuff = 205197
    classtable.HauntDeBuff = 48181
    classtable.UnstableAfflictionDeBuff = 316099
    classtable.CorruptionDeBuff = 146739
    classtable.WitherDeBuff = 445474
    classtable.SeedofCorruptionDeBuff = 27243
    classtable.TormentedCrescendoBuff = 387079
    classtable.NightfallBuff = 264571
    classtable.ShadowEmbraceDeBuff = 453206
    classtable.SoulRotDeBuff = 386997
    classtable.VileTaintDebuffDeBuff = 386931
    setSpell = nil
    ClearCDs()

    Affliction:precombat()

    Affliction:callaction()
    if setSpell then return setSpell end
end
