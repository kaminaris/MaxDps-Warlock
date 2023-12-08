
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

function Warlock:Demonology()
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
    classtable.SoulStrike = 267964
    setmetatable(classtable, Warlock.spellMeta)

    MaxDps:GlowCooldown(classtable.SummonDemonicTyrant, (cooldown[classtable.CallDreadstalkers].duration >= 12 or cooldown[classtable.SummonVilefiend].duration >= 30 or cooldown[classtable.GrimoireFelguard].duration >= 12) and cooldown[classtable.SummonDemonicTyrant].ready)

    if targets > 1  then
        return Warlock:DemonologyMultiTarget()
    end
    return Warlock:DemonologySingleTarget()
end

--optional abilities list


--Single-Target Rotation
function Warlock:DemonologySingleTarget()
    --Cast  Grimoire: Felguard
    if soulShards >= 1 and talents[classtable.GrimoireFelguard] and cooldown[classtable.GrimoireFelguard].ready then
        return classtable.GrimoireFelguard
    end
    --Cast  Summon Vilefiend whenever
    if soulShards >= 1 and talents[classtable.SummonVilefiend] and cooldown[classtable.SummonVilefiend].ready then
        return classtable.SummonVilefiend
    end
    --Cast  Demonic Strength
    if talents[classtable.DemonicStrength] and cooldown[classtable.DemonicStrength].ready then
        return classtable.DemonicStrength
    end
    --Cast  Guillotine whenever
    if talents[classtable.Guillotine] and cooldown[classtable.Guillotine].ready then
        return classtable.Guillotine
    end
    --Cast  Bilescourge Bombers
    if talents[classtable.BilescourgeBombers] and cooldown[classtable.BilescourgeBombers].ready then
        return classtable.BilescourgeBombers
    end
    --Cast  Call Dreadstalkers whenever available.
    if soulShards >= 2 and cooldown[classtable.CallDreadstalkers].ready then
        return classtable.CallDreadstalkers
    end
    --Cast  Hand of Gul'dan if you have 4-5 Soul Shards.
    if soulShards >= 4 and cooldown[classtable.HandofGuldan].ready then
        return classtable.HandofGuldan
    end
    --Maintain  Doom, paying attention to not be at 5 Soul Shards when it expires.
    if talents[classtable.Doom] and cooldown[classtable.Doom].ready then
        return classtable.Doom
    end
    --Cast  Demonbolt if you have 2+ stacks of Demonic Core Icon Demonic Core.
    if cooldown[classtable.Demonbolt].ready then
        return classtable.Demonbolt
    end
    --Cast Power Siphon with 2 or less Demonic Core Icon Demonic Core.
    if talents[classtable.PowerSiphon] and cooldown[classtable.PowerSiphon].ready then
        return classtable.PowerSiphon
    end
    --Cast  Hand of Gul'dan with 3 Soul Shards.
    if soulShards == 3 and cooldown[classtable.HandofGuldan].ready then
        return classtable.HandofGuldan
    end
    --Cast  Soul Strike whenever available when at 4 or less Soul Shards.
    if talents[classtable.SoulStrike] and cooldown[classtable.SoulStrike].ready then
        return classtable.SoulStrike
    end
    --Cast  Shadow Bolt to generate Soul Shards.
    if cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
    end
end

--Multiple-Target Rotation
function Warlock:DemonologyMultiTarget()
    --Cast  Grimoire: Felguard.
    if soulShards >= 1 and talents[classtable.GrimoireFelguard] and cooldown[classtable.GrimoireFelguard].ready then
        return classtable.GrimoireFelguard
    end
    --Cast  Summon Vilefiend.
    if soulShards >= 1 and talents[classtable.SummonVilefiend] and cooldown[classtable.SummonVilefiend].ready then
        return classtable.SummonVilefiend
    end
    --Cast  Call Dreadstalkers whenever available.
    if soulShards >= 2 and cooldown[classtable.CallDreadstalkers].ready then
        return classtable.CallDreadstalkers
    end
    --Cast  Guillotine whenever available.
    if talents[classtable.Guillotine] and cooldown[classtable.Guillotine].ready then
        return classtable.Guillotine
    end
    --Cast  Demonic Strength whenever available.
    if cooldown[classtable.DemonicStrength].ready then
        return classtable.DemonicStrength
    end
    --Cast  Bilescourge Bombers whenever available.
    if talents[classtable.BilescourgeBombers] and cooldown[classtable.BilescourgeBombers].ready then
        return classtable.BilescourgeBombers
    end
    --Cast  Soul Strike whenever possible.
    if talents[classtable.SoulStrike] and cooldown[classtable.SoulStrike].ready then
        return classtable.SoulStrike
    end
    --Cast  Hand of Gul'dan if you have 4-5 Soul Shards.
    if soulShards >= 4 and cooldown[classtable.HandofGuldan].ready then
        return classtable.HandofGuldan
    end
    --Cast  Implosion to detonate Wild Imps on 2+ targets.
    if talents[classtable.Implosion] and cooldown[classtable.Implosion].ready then
        return classtable.Implosion
    end
    --Cast  Demonbolt if you have 3+ stacks of  Demonic Core.
    if cooldown[classtable.Demonbolt].ready then
        return classtable.Demonbolt
    end
    --Cast  Power Siphon to generate  Demonic Core.
    if talents[classtable.PowerSiphon] and cooldown[classtable.PowerSiphon].ready then
        return classtable.PowerSiphon
    end
    --Cast  Shadow Bolt to generate Soul Shards.
    if cooldown[classtable.ShadowBolt].ready then
        return classtable.ShadowBolt
    end
end
