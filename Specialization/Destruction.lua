
local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end

local Warlock = addonTable.Warlock
local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local GetSpellDescription = GetSpellDescription
local GetSpellPowerCost = C_Spell.GetSpellPowerCost
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
local timeToDie

local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
local classtable

function Warlock:Destruction()
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
    timeToDie = fd.timeToDie
    classtable = MaxDps.SpellTable
    classtable.ImmolateDot = 157736
    classtable.RitualofRuinBuff = 387157
    --setmetatable(classtable, Warlock.spellMeta)

    MaxDps:GlowCooldown(classtable.SummonInfernal, cooldown[classtable.SummonInfernal].ready)

    if targets > 1  then
        return Warlock:DestructionMultiTarget()
    end
    return Warlock:DestructionSingleTarget()
end

--optional abilities list


--Single-Target Rotation
function Warlock:DestructionSingleTarget()
    --Maintain  Immolate at all times.
    if not debuff[classtable.ImmolateDot].up and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    --Cast  Chaos Bolt if you are about to cap Soul Shards.
    if (soulShards >= 4 or (talents[classtable.RitualofRuin] and buff[classtable.RitualofRuinBuff].up)) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    --Cast  Soul Fire during Roaring Blaze debuff on the target, when available, if below 4 shards
    if talents[classtable.SoulFire] and debuff[classtable.RoaringBlaze].up and soulShards < 4 and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    --Cast  Cataclysm when available.
    if talents[classtable.Cataclysm] and cooldown[classtable.Cataclysm].ready then
        return classtable.Cataclysm
    end
    --Cast  Channel Demonfire during Roaring Blaze debuff on the target whenever available.
    if talents[classtable.ChannelDemonfire] and debuff[classtable.RoaringBlaze].up and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    --Cast  Conflagrate if you have 2 charges, possibly to hasten a long cast such as Chaos Bolt Icon Chaos Bolt.
    if cooldown[classtable.Conflagrate].charges == 2 and cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    --Cast  Chaos Bolt to keep the Eradication debuff applied.
    if ((soulShards >= 2 or (talents[classtable.RitualofRuin] and buff[classtable.RitualofRuinBuff].up)) and (not debuff[classtable.Eradication].up or debuff[classtable.Eradication].duration < 2)) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    --Cast  Dimensional Rift at 3 charges to avoid overcapping.
    if talents[classtable.DimensionalRift] and cooldown[classtable.Conflagrate].charges == 3 and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    --Cast  Conflagrate to generate Soul Shards.
    if cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    --Cast  Incinerate to generate Soul Shards.
    if cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
end

--Multiple-Target Rotation
function Warlock:DestructionMultiTarget()
    --Maintain  Immolate on the main target.
    if not debuff[classtable.ImmolateDot].up and cooldown[classtable.Immolate].ready then
        return classtable.Immolate
    end
    --Apply  Immolate on any secondary target that will last a minimum of 10 seconds.
    --if cooldown[classtable.Immolate].ready then
    --    return classtable.Immolate
    --end
    --Cast  Soul Fire on cooldown.
    if talents[classtable.SoulFire] and cooldown[classtable.SoulFire].ready then
        return classtable.SoulFire
    end
    --Cast  Cataclysm on cooldown unless it can be delayed a few seconds to hit additional targets.
    if talents[classtable.Cataclysm] and cooldown[classtable.Cataclysm].ready then
        return classtable.Cataclysm
    end
    --Cast  Rain of Fire if there are 5+ targets with  Havoc  up, or 3+ if on cooldown.
    if (soulShards >= 3 or (talents[classtable.RitualofRuin] and buff[classtable.RitualofRuinBuff].up)) and cooldown[classtable.RainofFire].ready then
        return classtable.RainofFire
    end
    --Cast  Chaos Bolt if you have 5 Soul Shards.
    if (soulShards == 5 or (talents[classtable.RitualofRuin] and buff[classtable.RitualofRuinBuff].up)) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    --Cast  Cataclysm.
    if talents[classtable.Cataclysm] and cooldown[classtable.Cataclysm].ready then
        return classtable.Cataclysm
    end
    --Apply  Havoc if a secondary target is present.
    if talents[classtable.Havoc] and cooldown[classtable.Havoc].ready then
        return classtable.Havoc
    end
    --Cast  Shadowburn if the target will die within 5 seconds.
    if talents[classtable.Shadowburn] and cooldown[classtable.Shadowburn].ready and timeToDie <=5 then
        return classtable.Shadowburn
    end
    --Cast  Channel Demonfire
    if talents[classtable.ChannelDemonfire] and cooldown[classtable.ChannelDemonfire].ready then
        return classtable.ChannelDemonfire
    end
    --Cast  Chaos Bolt to spend Soul Shards.
    if (soulShards >= 3 or (talents[classtable.RitualofRuin] and buff[classtable.RitualofRuinBuff].up)) and cooldown[classtable.ChaosBolt].ready then
        return classtable.ChaosBolt
    end
    --Cast  Conflagrate to generate Soul Shards and Backdraft stacks.
    if cooldown[classtable.Conflagrate].ready then
        return classtable.Conflagrate
    end
    --Cast  Dimensional Rift at 3 charges to avoid overcapping.
    if talents[classtable.DimensionalRift] and cooldown[classtable.Conflagrate].charges == 3 and cooldown[classtable.DimensionalRift].ready then
        return classtable.DimensionalRift
    end
    --Cast  Incinerate to generate Soul Shards.
    if cooldown[classtable.Incinerate].ready then
        return classtable.Incinerate
    end
end
