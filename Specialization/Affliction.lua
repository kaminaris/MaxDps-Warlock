
local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end

local Warlock = addonTable.Warlock
local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = UnitAura
local GetSpellDescription = GetSpellDescription
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local PowerTypeRage = Enum.PowerType.Rage

local fd
local cooldown
local buff
local debuff
local talents
local targets
local soulShards
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc

local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
local classtable

function Warlock:Affliction()
    fd = MaxDps.FrameData
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    soulShards = UnitPower('player', Enum.PowerType.SoulShards)
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    classtable = MaxDps.SpellTable
    classtable.CorruptioneDot = 146739
    classtable.ShadowEmbraceDebuff = 32390
    --setmetatable(classtable, Warlock.spellMeta)

    MaxDps:GlowCooldown(classtable.SummonDarkglare, cooldown[classtable.SummonDarkglare].ready)

    if targets > 1  then
        return Warlock:AfflictionMultiTarget()
    end
    return Warlock:AfflictionSingleTarget()
end

--optional abilities list


--Single-Target Rotation
function Warlock:AfflictionSingleTarget()
    --Maintain your  Agony,  Unstable Affliction and Corruption
    if not debuff[classtable.Agony].up and cooldown[classtable.Agony].ready then
        return classtable.Agony
    end
    if not debuff[classtable.UnstableAffliction].up and cooldown[classtable.UnstableAffliction].ready then
        return classtable.UnstableAffliction
    end
    if not debuff[classtable.CorruptioneDot].up and cooldown[classtable.Corruption].ready then
        return classtable.Corruption
    end
    --Maintain your Siphon Life
    if talents[classtable.SiphonLife] and not debuff[classtable.SiphonLife].up and cooldown[classtable.SiphonLife].ready then
        return classtable.SiphonLife
    end
    --Maintain 3 stacks of Shadow Embrace.
    if talents[classtable.ShadowEmbrace] and not debuff[classtable.ShadowEmbraceDebuff].count == 3 or debuff[classtable.ShadowEmbraceDebuff].duration < 2 and cooldown[classtable.DrainSoul].ready then
        return (talents[classtable.DrainSoul] and classtable.DrainSoul or classtable.ShadowBolt)
    end
    --Apply  Malefic Rapture if you are at maximum Soul Shards.
    if soulShards == 5 and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    --Cast  Haunt
    if talents[classtable.Haunt] and cooldown[classtable.Haunt].ready then
        return classtable.Haunt
    end
    --Cast Malefic Rapture to maintain Dread Touch uptime as high as possible.
    if soulShards >= 1 and (not debuff[classtable.DreadTouch].up or debuff[classtable.DreadTouch].duration < 2) and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    --Cast Vile Taint whenever available.
    if talents[classtable.VileTaint] and soulShards >= 1 and cooldown[classtable.VileTaint].ready then
        return classtable.VileTaint
    end
    --Cast Phantom Singularity whenever available.
    if talents[classtable.PhantomSingularity] and cooldown[classtable.PhantomSingularity].ready then
        return classtable.PhantomSingularity
    end
    --Cast Soul Rot whenever available with either Phantom Singularity or Vile Taint active on target.
    if talents[classtable.SoulRot] and debuff[classtable.PhantomSingularity].up or debuff[classtable.VileTaint].up and cooldown[classtable.SoulRot].ready then
        return classtable.SoulRot
    end
    --Cast Malefic Rapture during Phantom Singularity window.
    if soulShards >= 1 and debuff[classtable.PhantomSingularity].up and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    --Cast Malefic Rapture during Vile Taint window.
    if soulShards >= 1 and debuff[classtable.VileTaint].up and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    --Cast  Malefic Rapture to avoid capping shards.
    if soulShards >= 3 and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    --Cast  Drain Soul as a filler.
    if talents[classtable.DrainSoul] and cooldown[classtable.DrainSoul].ready then
        return classtable.DrainSoul
    end
end

--Multiple-Target Rotation
function Warlock:AfflictionMultiTarget()
    --Cast Vile Taint.
    if talents[classtable.VileTaint] and soulShards >= 1 and cooldown[classtable.VileTaint].ready then
        return classtable.VileTaint
    end
    --Maintain  Agony and  Corruption. If there are 3+ targets  stacked together, use Seed of Corruption to apply and maintain Corruption.
    if not debuff[classtable.Agony].up and cooldown[classtable.Agony].ready then
        return classtable.Agony
    end
    if not debuff[classtable.CorruptioneDot].up and cooldown[classtable.Corruption].ready then
        return classtable.Corruption
    end
    --Maintain  Unstable Affliction on the primary target.
    if not debuff[classtable.UnstableAffliction].up and cooldown[classtable.UnstableAffliction].ready then
        return classtable.UnstableAffliction
    end
    --Cast Seed of Corruption over Malefic Rapture to spend shards.
    if soulShards >= 1 and cooldown[classtable.SeedofCorruption].ready then
        return classtable.SeedofCorruption
    end
    --Cast  Malefic Rapture if already at 5 Soul Shards to avoid capping.
    if soulShards == 5 and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    --Cast Phantom Singularity.
    if talents[classtable.PhantomSingularity] and cooldown[classtable.PhantomSingularity].ready then
        return classtable.PhantomSingularity
    end
    --Cast Soul Rot.
    if talents[classtable.SoulRot] and cooldown[classtable.SoulRot].ready then
        return classtable.SoulRot
    end
    --Cast Malefic Rapture during Phantom Singularity window.
    if soulShards >= 1 and debuff[classtable.PhantomSingularity].up and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    --Cast Malefic Rapture during Vile Taint window.
    if soulShards >= 1 and debuff[classtable.VileTaint].up and cooldown[classtable.MaleficRapture].ready then
        return classtable.MaleficRapture
    end
    --Cast Drain Soul as a filler.
    if talents[classtable.DrainSoul] and cooldown[classtable.DrainSoul].ready then
        return classtable.DrainSoul
    end
end
