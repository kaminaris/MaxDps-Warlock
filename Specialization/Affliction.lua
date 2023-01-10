local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then
    return
end

local Warlock = addonTable.Warlock;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local fd;
local cooldown;
local buff;
local debuff;
local currentSpell;
local talents;
local targets;
local timeToDie;
local soulShards;
local mana;
local timeShift;

local AF = {
    absolute_corruption = 196103,
    abyss_walker = 389609,
    accrued_vitality = 386613,
    agonizing_corruption = 386922,
    agony = 980,
    amplify_curse = 328774,
    banish = 710,
    burning_rush = 111400,
    corruption = 172,
    corruption_debuff = 146739,
    creeping_death = 264000,
    curses_of_enfeeblement = 386105,
    dark_accord = 386659,
    dark_harvest = 387016,
    dark_pact = 108416,
    darkfury = 264874,
    demon_skin = 219272,
    demonic_circle = 268358,
    demonic_embrace = 288843,
    demonic_fortitude = 386617,
    demonic_gateway = 111771,
    demonic_inspiration = 386858,
    demonic_resilience = 389590,
    desperate_pact = 386619,
    doom_blossom = 389764,
    drain_soul = 198590,
    dread_touch = 389775,
    dread_touch_debuff = 389868,
    fel_armor = 386124,
    fel_domination = 333889,
    fel_pact = 386113,
    fel_synergy = 389367,
    fiendish_stride = 386110,
    frequent_donor = 386686,
    gorefiends_resolve = 389623,
    grand_warlocks_design = 387084,
    greater_banish = 386651,
    grim_feast = 386689,
    grim_reach = 389992,
    grimoire_of_sacrifice = 108503,
    grimoire_of_synergy = 171975,
    harvester_of_souls = 201424,
    haunt = 48181,
    haunted_soul = 387301,
    howl_of_terror = 5484,
    ichor_of_devils = 386664,
    inevitable_demise = 334319,
    inquisitors_gaze = 386344,
    lifeblood = 386646,
    malefic_affliction = 389761,
    malefic_affliction_buff = 389845,
    malefic_rapture = 324536,
    malevolent_visionary = 387273,
    mortal_coil = 6789,
    nightfall = 108558,
    nightmare = 386648,
    pandemic_invocation = 386759,
    phantom_singularity = 205179,
    profane_bargain = 389576,
    resolute_barrier = 389359,
    sacrolashs_dark_strike = 386986,
    seed_of_corruption = 27243,
    seized_vitality = 387250,
    shadow_embrace = 32388,
    shadow_embrace_debuff = 32390,
    shadowflame = 384069,
    shadowfury = 30283,
    siphon_life = 63106,
    soul_conduit = 215941,
    soul_eaters_gluttony = 389630,
    soul_flame = 199471,
    soul_link = 108415,
    soul_rot = 386997,
    soul_swap = 386951,
    soul_tap = 387073,
    soulburn = 385899,
    sow_the_seeds = 196226,
    strength_of_will = 317138,
    summon_darkglare = 205180,
    summon_soulkeeper = 386256,
    sweet_souls = 386620,
    teachings_of_the_black_harvest = 385881,
    teachings_of_the_satyr = 387972,
    tormented_crescendo = 387075,
    unstable_affliction = 316099,
    vile_taint = 278350,
    withering_bolt = 386976,
    wrath_of_consumption = 387065,
    wrathful_minion = 386864,
    writhe_in_agony = 196102,
    xavian_teachings = 317031
};
setmetatable(AF, Warlock.spellMeta);

function Warlock:SpellReady(spellId, resource)
    local spellKnown = IsSpellKnownOrOverridesKnown(spellId);
    local coolDownReady = cooldown[spellId].ready;
    local hasResource = Warlock:HasResource(spellId, resource)

    if spellKnown and coolDownReady and hasResource then
        return true
    end

    return false
end

function Warlock:HasResource(spellId, resource)
    local spellTable = GetSpellPowerCost(spellId);
    local cost;
    if spellTable ~= nil then
        cost = spellTable[1].cost;
    else
        return false;
    end

    return cost <= resource
end

function Warlock:Affliction()
    fd = MaxDps.FrameData;
    cooldown = fd.cooldown;
    buff = fd.buff;
    debuff = fd.debuff;
    currentSpell = fd.currentSpell;
    talents = fd.talents;
    targets = MaxDps:SmartAoe();
    fd.targets = targets;
    timeToDie = fd.timeToDie;
    soulShards = UnitPower('player', Enum.PowerType.SoulShards);
    mana = UnitPower('player', Enum.PowerType.Mana)
    fd.mana = mana
    timeShift = fd.timeShift

    if targets > 3 then
        local result = Warlock:AfflictionMultiTarget()
        if result then
            return result
        end
    else
        return Warlock:AfflictionSingleTarget()
    end
end

function Warlock:AfflictionSingleTarget()
    local inCombat = UnitAffectingCombat("player")
    if Warlock:SpellReady(AF.haunt, mana) and debuff[AF.haunt].refreshable and not inCombat then
        return AF.haunt
    end

    if Warlock:SpellReady(AF.unstable_affliction, mana) and debuff[AF.unstable_affliction].refreshable then
        return AF.unstable_affliction
    end

    if Warlock:SpellReady(AF.agony, mana) and debuff[AF.agony].refreshable then
        return AF.agony
    end

    if Warlock:SpellReady(AF.corruption, mana) and debuff[AF.corruption_debuff].refreshable then
        return AF.corruption
    end

    if Warlock:SpellReady(AF.siphon_life, mana) and debuff[AF.siphon_life].refreshable then
        return AF.siphon_life
    end

    if Warlock:SpellReady(AF.haunt, mana) and debuff[AF.haunt].refreshable then
        return AF.haunt
    end

    if Warlock:SpellReady(AF.malefic_rapture) and buff[AF.malefic_affliction_buff].count < 3 then
        return AF.malefic_rapture
    end

    if Warlock:SpellReady(AF.drain_soul) and debuff[AF.shadow_embrace_debuff].count < 3 then
        return AF.drain_soul
    end

    if Warlock:SpellReady(AF.malefic_rapture, soulShards) and buff[AF.malefic_affliction_buff].count >= 3 and debuff[AF.dread_touch_debuff].refreshable then
        return AF.malefic_rapture
    end

    if Warlock:SpellReady(AF.phantom_singularity, mana) then
        return AF.phantom_singularity
    end

    if Warlock:SpellReady(AF.vile_taint, soulShards) then
        return AF.vile_taint
    end

    if Warlock:SpellReady(AF.malefic_rapture, soulShards) and (debuff[AF.phantom_singularity].up or debuff[AF.vile_taint].up) then
        return AF.malefic_rapture
    end

    if Warlock:SpellReady(AF.malefic_rapture, soulShards) and soulShards > 4 then
        return AF.malefic_rapture
    end

    if Warlock:SpellReady(AF.drain_soul, mana) then
        return AF.drain_soul
    end
end

function Warlock:AfflictionMultiTarget()

    if Warlock:SpellReady(AF.vile_taint, soulShards) then
        return AF.vile_taint
    end

    if Warlock:SpellReady(AF.agony, mana) and debuff[AF.agony].refreshable then
        return AF.agony
    end

    if debuff[AF.corruption_debuff].refreshable then
        if Warlock:SpellReady(AF.seed_of_corruption, soulShards) then
            return AF.seed_of_corruption
        elseif Warlock:SpellReady(AF.corruption, mana) then
            return AF.corruption
        end
    end

    if Warlock:SpellReady(AF.unstable_affliction, mana) and debuff[AF.unstable_affliction].refreshable then
        return AF.unstable_affliction
    end

    if Warlock:SpellReady(AF.malefic_rapture, soulShards) and talents[AF.doom_blossom] and buff[AF.malefic_affliction_buff].count < 1 then
        return AF.malefic_rapture
    end

    if Warlock:SpellReady(AF.malefic_rapture, soulShards) and soulShards > 4 then
        return AF.malefic_rapture
    end

    if Warlock:SpellReady(AF.phantom_singularity, mana) then
        return AF.phantom_singularity
    end

    if Warlock:SpellReady(AF.malefic_rapture, soulShards) and (debuff[AF.phantom_singularity].up or debuff[AF.vile_taint].up) then
        return AF.malefic_rapture
    end

    if Warlock:SpellReady(AF.drain_soul, mana) then
        return AF.drain_soul
    end
end
