--- @type MaxDps
if not MaxDps then
	return ;
end

local MaxDps = MaxDps;
local UnitPower = UnitPower;
local EnumPowerType = Enum.PowerType;
local UnitExists = UnitExists;

local Warlock = MaxDps:NewModule('Warlock', 'AceEvent-3.0');

-- Shared SPELLS
local WS = {
	BloodPact      = 6307,
	SingeMagic     = 89808,
	DemonicGateway = 111771,
	DemonicCircle  = 268358,
};

-- Affliction
local AF = {
	GrimoireOfSacrifice    = 108503,
	SeedOfCorruption       = 27243,
	Haunt                  = 48181,
	ShadowBolt             = 232670,
	SowTheSeeds            = 196226,
	SiphonLife             = 63106,
	DrainSoul              = 198590,
	Deathbolt              = 264106,
	WritheInAgony          = 196102,
	AbsoluteCorruption     = 196103,
	CreepingDeath          = 264000,
	SummonDarkglare        = 205180,
	Agony                  = 980,
	Corruption             = 172,
	CorruptionAura         = 146739,
	PhantomSingularity     = 205179,
	UnstableAffliction     = 30108,
	ShadowEmbrace          = 32388,
	VileTaint              = 278350,
	Nightfall              = 108558,
	DrainLife              = 234153,
	DarkSoulMisery         = 113860,
};

local UnstableAfflictionAuras = {
	[233490] = true,
	[233496] = true,
	[233497] = true,
	[233498] = true,
	[233499] = true,
}

local A = {
	CascadingCalamity = 275372,
	InevitableDemise  = 273521,
}
--[[
local WA = {
	Agony                  = 980,
	Corruption             = 172,
	CorruptionAura         = 146739,
	UnstableAffliction     = 30108,
	UnstableAfflictionAura = 233490,
	Deathbolt              = 264106,
	SummonDarkglare        = 205180,
	VileTaint              = 278350,
	ShadowBolt             = 232670,
	PhantomSingularity     = 205179,
	SeedofCorruption       = 27243,
	SiphonLife             = 63106,
	Nightfall              = 108558,
	-- Affliction talents
	AbsoluteCorruption     = 196103,
	DrainSoul              = 198590,
	Haunt                  = 48181,
	DarkSoulMisery         = 113860,
};
]]--
-- Destruction maybe some wrong talents just copied from Icy Veins
local WD = {
	Immolate            = 348,
	ImmolateAura        = 157736,
	ChaosBolt           = 116858,
	Conflagrate         = 17962,
	ChannelDemonfire    = 196447,
	Eradication         = 196412,
	Cataclysm           = 152108,
	Incinerate          = 29722,
	SummonInfernal      = 1122,
	DarkSoulInstability = 113858,
	RainOfFire          = 5740,
	Havoc               = 80240,
	Shadowburn          = 17877,
	Backdraft           = 117828,
	FireAndBrimstone    = 196408,
	SummonImp           = 688,
	SummonVoidwalker    = 697,
	SummonSuccubus      = 712,
	SummonFelhunter     = 691,
	Soulfire            = 6353,
};

--Demonology maybe some wrong talents just copied from Icy Veins
local WN = {
	DemonicCore          = 264178,
	DemonicCoreAura      = 264173,
	CallDreadstalkers    = 104316,
	GrimoireFelguard     = 111898,
	DemonicStrength      = 267171,
	SummonVilefiend      = 264119,
	SummonDemonicTyrant  = 265187,
	HandOfGuldan         = 105174,
	Demonbolt            = 264178,
	PowerSiphon          = 264130,
	ShadowBoltDemonology = 686,
	NetherPortal         = 267217,
	NetherPortalAura     = 267218,
	Implosion            = 196277,
	SoulStrike           = 264057,
	BilescourgeBombers   = 267211,
	CommandDemon         = 119898,
	AxeToss              = 89766,
	Felstorm             = 89751,
	LegionStrike         = 30213,
	ThreateningPresence  = 134477,
	SummonFelguard       = 30146,
};


local spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

setmetatable(A, spellMeta);
setmetatable(AF, spellMeta);

function Warlock:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Warlock [Affliction, Demonology, Destruction]');

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Warlock.Affliction;
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Warlock.Demonology;
		self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', 'CLEU');
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Warlock.Destruction;
	end ;
	return true;
end

function Warlock:Disable()
	self:UnregisterAllEvents();
end

function Warlock:Affliction()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local azerite = fd.azerite;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local timeToDie = fd.timeToDie;
	local targets = MaxDps:SmartAoe();
	fd.targets = targets;
	local gcd = fd.gcd;

	local soulShards = UnitPower('player', Enum.PowerType.SoulShards);

	if currentSpell == AF.UnstableAffliction or currentSpell == AF.SeedOfCorruption then
		soulShards = soulShards - 1;
	end
	fd.soulShards = soulShards;

	local spellHaste = MaxDps:AttackHaste();

	local contagion, uaCount = Warlock:Contagion(timeShift);
	local activeAgonies, totalAgonyTime, totalAgonyCount  = MaxDps:DebuffCounter(AF.Agony, timeShift);
	local timeToShard = Warlock:TimeToShard(fd, activeAgonies, totalAgonyTime);

	-- variable,name=use_seed,value=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up|talent.siphon_life.enabled&spell_targets.seed_of_corruption>=5+raid_event.invulnerable.up|spell_targets.seed_of_corruption>=8+raid_event.invulnerable.up;
	local useSeed = talents[AF.SowTheSeeds] and targets >= 3 or (talents[AF.SiphonLife] and targets >= 5) or targets >= 8;

	-- variable,name=padding,op=set,value=action.shadow_bolt.execute_time*azerite.cascading_calamity.enabled;
	local padding = gcd * (azerite[A.CascadingCalamity] > 0 and 1 or 0);

	-- variable,name=padding,op=reset,value=gcd,if=azerite.cascading_calamity.enabled&(talent.drain_soul.enabled|talent.deathbolt.enabled&cooldown.deathbolt.remains<=gcd);
	if azerite[A.CascadingCalamity] > 0 and (talents[AF.DrainSoul] or talents[AF.Deathbolt] and cooldown[AF.Deathbolt].remains <= gcd) then
		padding = gcd;
	end

	-- variable,name=maintain_se,value=spell_targets.seed_of_corruption_aoe<=1+talent.writhe_in_agony.enabled+talent.absolute_corruption.enabled*2+(talent.writhe_in_agony.enabled&talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>2)+(talent.siphon_life.enabled&!talent.creeping_death.enabled&!talent.drain_soul.enabled)+raid_event.invulnerable.up;
	local maintainSe = targets <=
		1 +
			(talents[AF.WritheInAgony] and 1 or 0) +
			(talents[AF.AbsoluteCorruption] and 2 or 0) +
			(talents[AF.WritheInAgony] and talents[AF.SowTheSeeds] and targets > 2 and 1 or 0) +
			(talents[AF.SiphonLife] and not talents[AF.CreepingDeath] and not talents[AF.DrainSoul] and 1 or 0);

	fd.maintainSe = maintainSe;
	fd.useSeed = useSeed;
	fd.padding = padding;
	fd.contagion = contagion;
	fd.timeToShard = timeToShard;
	fd.activeAgonies = activeAgonies;

	MaxDps:GlowCooldown(
		AF.SummonDarkglare,
		cooldown[AF.SummonDarkglare].ready and
		debuff[AF.Agony].up and
		debuff[AF.CorruptionAura].up and
		(uaCount == 5 or soulShards == 0) and
		(not talents[AF.PhantomSingularity] or cooldown[AF.PhantomSingularity].remains > 0) and
		(
			not talents[AF.Deathbolt] or
			cooldown[AF.Deathbolt].remains <= gcd or
			targets > 1
		)
	);

	if talents[AF.DarkSoulMisery] then
		MaxDps:GlowCooldown(AF.DarkSoulMisery, cooldown[AF.DarkSoulMisery].ready);
	end

	-- drain_soul,interrupt_global=1,chain=1,cycle_targets=1,if=target.time_to_die<=gcd&soul_shard<5;
	if talents[AF.DrainSoul] and (timeToDie <= gcd and soulShards < 5) then
		return AF.DrainSoul;
	end

	-- haunt,if=spell_targets.seed_of_corruption_aoe<=2+raid_event.invulnerable.up;
	if cooldown[AF.Haunt].ready and currentSpell ~= AF.Haunt and (targets <= 2) then
		return AF.Haunt;
	end

	-- summon_darkglare,if=dot.agony.ticking&dot.corruption.ticking&(buff.active_uas.stack=5|soul_shard=0)&(!talent.phantom_singularity.enabled|cooldown.phantom_singularity.remains)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=gcd|!cooldown.deathbolt.remains|spell_targets.seed_of_corruption_aoe>1+raid_event.invulnerable.up);
	--if cooldown[AF.SummonDarkglare].ready and (
	--	debuff[AF.Agony].up and
	--	debuff[AF.CorruptionAura].up and
	--	(buff[AF.ActiveUas].count == 5 or soulShards == 0) and
	--	(not talents[AF.PhantomSingularity] or cooldown[AF.PhantomSingularity].remains) and
	--	(
	--		not talents[AF.Deathbolt] or
	--		cooldown[AF.Deathbolt].remains <= gcd or
	--		not cooldown[AF.Deathbolt].remains or
	--		targets > 1
	--	)
	--) then
	--	return AF.SummonDarkglare;
	--end

	-- deathbolt,if=cooldown.summon_darkglare.remains&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up;
	if cooldown[AF.Deathbolt].ready and (cooldown[AF.SummonDarkglare].remains > 0 and targets == 1) then
		return AF.Deathbolt;
	end

	-- agony,target_if=min:dot.agony.remains,if=remains<=gcd+action.shadow_bolt.execute_time&target.time_to_die>8;
	if (debuff[AF.Agony].remains <= gcd + timeShift and timeToDie > 8) then
		return AF.Agony;
	end

	-- unstable_affliction,target_if=!contagion&target.time_to_die<=8;
	if soulShards >= 1 and currentSpell ~= AF.UnstableAffliction and contagion <= 0 and timeToDie <= 8 then
		return AF.UnstableAffliction;
	end

	-- drain_soul,target_if=min:debuff.shadow_embrace.remains,cancel_if=ticks_remain<5,if=talent.shadow_embrace.enabled&variable.maintain_se&debuff.shadow_embrace.remains&debuff.shadow_embrace.remains<=gcd*2;
	if talents[AF.DrainSoul] and (
		talents[AF.ShadowEmbrace] and
		maintainSe and
		debuff[AF.ShadowEmbrace].remains > 0 and
		debuff[AF.ShadowEmbrace].remains <= gcd * 2
	) then
		return AF.DrainSoul;
	end

	-- shadow_bolt,target_if=min:debuff.shadow_embrace.remains,if=talent.shadow_embrace.enabled&variable.maintain_se&debuff.shadow_embrace.remains&debuff.shadow_embrace.remains<=execute_time*2+travel_time&!action.shadow_bolt.in_flight;
	if currentSpell ~= AF.ShadowBolt and (
		talents[AF.ShadowEmbrace] and
		maintainSe and
		debuff[AF.ShadowEmbrace].remains > 0 and
		debuff[AF.ShadowEmbrace].remains <= gcd * 2
	) then
		return AF.ShadowBolt;
	end

	-- phantom_singularity,target_if=max:target.time_to_die,if=time>35&(cooldown.summon_darkglare.remains>=45|cooldown.summon_darkglare.remains<8)&target.time_to_die>16*spell_haste;
	if cooldown[AF.PhantomSingularity].ready and (
		(cooldown[AF.SummonDarkglare].remains >= 45 or cooldown[AF.SummonDarkglare].remains < 8) and
		timeToDie > 16 * spellHaste
	) then
		return AF.PhantomSingularity;
	end

	-- vile_taint,target_if=max:target.time_to_die,if=time>15&target.time_to_die>=10;
	if talents[AF.VileTaint] and
		cooldown[AF.VileTaint].ready and
		soulShards >= 1 and
		currentSpell ~= AF.VileTaint and
		timeToDie >= 10
	then
		return AF.VileTaint;
	end

	-- unstable_affliction,target_if=min:contagion,if=!variable.use_seed&soul_shard=5;
	if currentSpell ~= AF.UnstableAffliction and not useSeed and soulShards == 5 then
		return AF.UnstableAffliction;
	end

	-- seed_of_corruption,if=variable.use_seed&soul_shard=5;
	if currentSpell ~= AF.SeedOfCorruption and useSeed and soulShards == 5 then
		return AF.SeedOfCorruption;
	end

	-- call_action_list,name=dots;
	local result = Warlock:AfflictionDots();
	if result then return result; end

	-- phantom_singularity,if=time<=35;
	if cooldown[AF.PhantomSingularity].ready then
		return AF.PhantomSingularity;
	end

	-- vile_taint,if=time<15;
	if talents[AF.VileTaint] and cooldown[AF.VileTaint].ready and soulShards >= 1 and currentSpell ~= AF.VileTaint then
		return AF.VileTaint;
	end

	-- dark_soul,if=cooldown.summon_darkglare.remains<10&dot.phantom_singularity.remains|target.time_to_die<20+gcd|spell_targets.seed_of_corruption_aoe>1+raid_event.invulnerable.up;
	--if cooldown[AF.DarkSoulMisery].ready and (cooldown[AF.SummonDarkglare].remains < 10 and
	--	debuff[AF.PhantomSingularity].remains > 0 or
	--	timeToDie < 20 + gcd or
	--	targets > 1)
	--then
	--	return AF.DarkSoulMisery;
	--end

	-- call_action_list,name=spenders;
	result = Warlock:AfflictionSpenders();
	if result then return result; end

	-- call_action_list,name=fillers;
	result = Warlock:AfflictionFillers();
	return result;
end

function Warlock:AfflictionDbRefresh()
	local fd = MaxDps.FrameData;
	local debuff = fd.debuff;
	local talents = fd.talents;

	if talents[AF.SiphonLife] and debuff[AF.SiphonLife].refreshable then
		return AF.SiphonLife;
	end

	if debuff[AF.Agony].refreshable then
		return AF.Agony;
	end

	if debuff[AF.CorruptionAura].refreshable then
		return AF.Corruption;
	end

	---- siphon_life,line_cd=15,if=(dot.siphon_life.remains%dot.siphon_life.duration)<=(dot.agony.remains%dot.agony.duration)&(dot.siphon_life.remains%dot.siphon_life.duration)<=(dot.corruption.remains%dot.corruption.duration)&dot.siphon_life.remains<dot.siphon_life.duration*1.3;
	--if talents[AF.SiphonLife] and t - lineCd[AF.SiphonLife] >= 15 and (
	--	(debuff[AF.SiphonLife].remains % debuff[AF.SiphonLife].duration) <= (debuff[AF.Agony].remains % debuff[AF.Agony].duration) and
	--	(debuff[AF.SiphonLife].remains % debuff[AF.SiphonLife].duration) <= (debuff[AF.CorruptionAura].remains % debuff[AF.CorruptionAura].duration) and
	--	debuff[AF.SiphonLife].remains < debuff[AF.SiphonLife].duration * 1.3
	--) then
	--	print('sl', t - lineCd[AF.SiphonLife])
	--	lineCd[AF.SiphonLife] = t;
	--	return AF.SiphonLife;
	--end
	--
	---- agony,line_cd=15,if=(dot.agony.remains%dot.agony.duration)<=(dot.corruption.remains%dot.corruption.duration)&(dot.agony.remains%dot.agony.duration)<=(dot.siphon_life.remains%dot.siphon_life.duration)&dot.agony.remains<dot.agony.duration*1.3;
	--if t - lineCd[AF.Agony] >= 15 and (
	--	(debuff[AF.Agony].remains % debuff[AF.Agony].duration) <= (debuff[AF.CorruptionAura].remains % debuff[AF.CorruptionAura].duration) and
	--	(debuff[AF.Agony].remains % debuff[AF.Agony].duration) <= (debuff[AF.SiphonLife].remains % debuff[AF.SiphonLife].duration) and
	--	debuff[AF.Agony].remains < debuff[AF.Agony].duration * 1.3
	--) then
	--	print('ago', t - lineCd[AF.Agony])
	--	lineCd[AF.Agony] = t;
	--	return AF.Agony;
	--end
	--
	---- corruption,line_cd=15,if=(dot.corruption.remains%dot.corruption.duration)<=(dot.agony.remains%dot.agony.duration)&(dot.corruption.remains%dot.corruption.duration)<=(dot.siphon_life.remains%dot.siphon_life.duration)&dot.corruption.remains<dot.corruption.duration*1.3;
	--if t - lineCd[AF.Corruption] >= 15 and (
	--	(debuff[AF.CorruptionAura].remains % debuff[AF.CorruptionAura].duration) <= (debuff[AF.Agony].remains % debuff[AF.Agony].duration) and
	--	(debuff[AF.CorruptionAura].remains % debuff[AF.CorruptionAura].duration) <= (debuff[AF.SiphonLife].remains % debuff[AF.SiphonLife].duration) and
	--	debuff[AF.CorruptionAura].remains < debuff[AF.CorruptionAura].duration * 1.3
	--) then
	--	print('corr', t - lineCd[AF.Corruption])
	--	lineCd[AF.Corruption] = t;
	--	return AF.Corruption;
	--end
end

function Warlock:AfflictionDots()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local targets = fd.targets;
	local timeToDie = fd.timeToDie;
	local activeDot = fd.activeDot;
	local timeToShard = fd.timeToShard;
	local spellHistory = fd.spellHistory;
	local activeAgonies = fd.activeAgonies;
	local gcd = fd.gcd;
	local soulShards = fd.soulShards;


	-- seed_of_corruption,if=dot.corruption.remains<=action.seed_of_corruption.cast_time+time_to_shard+4.2*(1-talent.creeping_death.enabled*0.15)&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up+talent.writhe_in_agony.enabled&!dot.seed_of_corruption.remains&!action.seed_of_corruption.in_flight;
	if soulShards >= 1 and currentSpell ~= AF.SeedOfCorruption and (
		debuff[AF.CorruptionAura].remains <= timeShift + 4.2 * (1 - (talents[AF.CreepingDeath] and 0.15 or 0)) and
		targets >= 3 + (talents[AF.WritheInAgony] and 1 or 0) and
		not debuff[AF.SeedOfCorruption].up and
		spellHistory[1] ~= AF.SeedOfCorruption
	) then
		return AF.SeedOfCorruption;
	end

	-- agony,target_if=min:remains,if=talent.creeping_death.enabled&active_dot.agony<6&target.time_to_die>10&(remains<=gcd|cooldown.summon_darkglare.remains>10&refreshable);
	if (talents[AF.CreepingDeath] and
		activeAgonies < 6 and
		timeToDie > 10 and
		(debuff[AF.Agony].remains <= gcd or cooldown[AF.SummonDarkglare].remains > 10 and debuff[AF.Agony].refreshable)
	) then
		return AF.Agony;
	end

	-- agony,target_if=min:remains,if=!talent.creeping_death.enabled&active_dot.agony<8&target.time_to_die>10&(remains<=gcd|cooldown.summon_darkglare.remains>10&refreshable);
	if (not talents[AF.CreepingDeath] and
		activeAgonies < 8 and
		timeToDie > 10 and
		(debuff[AF.Agony].remains <= gcd or cooldown[AF.SummonDarkglare].remains > 10 and debuff[AF.Agony].refreshable)
	) then
		return AF.Agony;
	end

	-- siphon_life,target_if=min:remains,if=(active_dot.siphon_life<8-talent.creeping_death.enabled-spell_targets.sow_the_seeds_aoe)&target.time_to_die>10&refreshable&(!remains&spell_targets.seed_of_corruption_aoe=1|cooldown.summon_darkglare.remains>soul_shard*action.unstable_affliction.execute_time);
	if talents[AF.SiphonLife] and (
		(activeDot[AF.SiphonLife] < 8 - (talents[AF.CreepingDeath] and 1 or 0) - targets) and
		timeToDie > 10 and
		debuff[AF.SiphonLife].refreshable and
		(not debuff[AF.SiphonLife].remains and targets == 1 or cooldown[AF.SummonDarkglare].remains > soulShards * timeShift)
	) then
		return AF.SiphonLife;
	end

	-- corruption,cycle_targets=1,if=spell_targets.seed_of_corruption_aoe<3+raid_event.invulnerable.up+talent.writhe_in_agony.enabled&(remains<=gcd|cooldown.summon_darkglare.remains>10&refreshable)&target.time_to_die>10;
	if (
		targets < 3 + (talents[AF.WritheInAgony] and 1 or 0) and timeToDie > 10 and (
			debuff[AF.CorruptionAura].remains <= gcd or
			cooldown[AF.SummonDarkglare].remains > 10 and debuff[AF.CorruptionAura].refreshable
		)
	) then
		return AF.Corruption;
	end
end

function Warlock:AfflictionFillers()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local targets = fd.targets;
	local spellHistory = fd.spellHistory;
	local timeToDie = fd.timeToDie;
	local maintainSe = fd.maintainSe;
	local gcd = fd.gcd;
	local soulShards = fd.soulShards;

	-- unstable_affliction,line_cd=15,if=cooldown.deathbolt.remains<=gcd*2&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains>20;
	if soulShards >= 1 and
		--currentSpell ~= AF.UnstableAffliction and
		cooldown[AF.Deathbolt].remains <= gcd * 2 and
		targets <= 1 and
		cooldown[AF.SummonDarkglare].remains > 20
	then
		return AF.UnstableAffliction;
	end

	-- call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20;
	local result;
	if talents[AF.Deathbolt] and targets <= 1 and
		(
			debuff[AF.Agony].remains < debuff[AF.Agony].duration * 0.75 or
			debuff[AF.CorruptionAura].remains < debuff[AF.CorruptionAura].duration * 0.75 or
			debuff[AF.SiphonLife].remains < debuff[AF.SiphonLife].duration * 0.75
		) and cooldown[AF.Deathbolt].remains <= gcd * 4 and cooldown[AF.SummonDarkglare].remains > 20
	then
		result = Warlock:AfflictionDbRefresh();
		if result then return result; end
	end

	-- call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1);
	if talents[AF.Deathbolt] and targets <= 1 and
		cooldown[AF.SummonDarkglare].remains <= soulShards * gcd + gcd * 3 and (
			debuff[AF.Agony].remains < debuff[AF.Agony].duration or
			debuff[AF.CorruptionAura].remains < debuff[AF.CorruptionAura].duration or
			debuff[AF.SiphonLife].remains < debuff[AF.SiphonLife].duration
	) then
		result = Warlock:AfflictionDbRefresh();
		if result then return result; end
	end

	-- deathbolt,if=cooldown.summon_darkglare.remains>=30+gcd|cooldown.summon_darkglare.remains>140;
	if cooldown[AF.Deathbolt].ready and (
		cooldown[AF.SummonDarkglare].remains >= 30 + gcd or cooldown[AF.SummonDarkglare].remains > 140
	) then
		return AF.Deathbolt;
	end

	local playerMoving = GetUnitSpeed('player') > 0;
	-- shadow_bolt,if=buff.movement.up&buff.nightfall.remains;
	if playerMoving and buff[AF.Nightfall].up then
		return AF.ShadowBolt;
	end

	-- agony,if=buff.movement.up&!(talent.siphon_life.enabled&(prev_gcd.1.agony&prev_gcd.2.agony&prev_gcd.3.agony)|prev_gcd.1.agony);
	if (playerMoving and
		not (
			talents[AF.SiphonLife] and
			(spellHistory[1] == AF.Agony and spellHistory[2] == AF.Agony and spellHistory[3] == AF.Agony) or spellHistory[1] == AF.Agony
		)
	) then
		return AF.Agony;
	end

	-- siphon_life,if=buff.movement.up&!(prev_gcd.1.siphon_life&prev_gcd.2.siphon_life&prev_gcd.3.siphon_life);
	if talents[AF.SiphonLife] and (
		playerMoving and
		not (spellHistory[1] == AF.SiphonLife and spellHistory[2] == AF.SiphonLife and spellHistory[3] == AF.SiphonLife)
	) then
		return AF.SiphonLife;
	end

	-- corruption,if=buff.movement.up&!prev_gcd.1.corruption&!talent.absolute_corruption.enabled;
	if playerMoving and spellHistory[1] ~= AF.Corruption and not talents[AF.AbsoluteCorruption] then
		return AF.Corruption;
	end

	-- drain_life,if=(buff.inevitable_demise.stack>=85-(spell_targets.seed_of_corruption_aoe-raid_event.invulnerable.up>2)*20&(cooldown.deathbolt.remains>execute_time|!talent.deathbolt.enabled)&(cooldown.phantom_singularity.remains>execute_time|!talent.phantom_singularity.enabled)&(cooldown.dark_soul.remains>execute_time|!talent.dark_soul_misery.enabled)&(cooldown.vile_taint.remains>execute_time|!talent.vile_taint.enabled)&cooldown.summon_darkglare.remains>execute_time+10|buff.inevitable_demise.stack>30&target.time_to_die<=10);
	if (
		(buff[A.InevitableDemise].count >= 85 - (targets > 2 and 20 or 0) and
		(cooldown[AF.Deathbolt].remains > timeShift or not talents[AF.Deathbolt]) and
		(cooldown[AF.PhantomSingularity].remains > timeShift or not talents[AF.PhantomSingularity]) and
		(cooldown[AF.DarkSoulMisery].remains > timeShift or not talents[AF.DarkSoulMisery]) and
		(cooldown[AF.VileTaint].remains > timeShift or not talents[AF.VileTaint]) and
		cooldown[AF.SummonDarkglare].remains > timeShift + 10 or
		buff[A.InevitableDemise].count > 30 and
		timeToDie <= 10)
	) then
		return AF.DrainLife;
	end

	-- haunt;
	if cooldown[AF.Haunt].ready and currentSpell ~= AF.Haunt then
		return AF.Haunt;
	end

	-- drain_soul,interrupt_global=1,chain=1,interrupt=1,cycle_targets=1,if=target.time_to_die<=gcd;
	if talents[AF.DrainSoul] and (timeToDie <= gcd) then
		return AF.DrainSoul;
	end

	-- drain_soul,target_if=min:debuff.shadow_embrace.remains,chain=1,interrupt_if=ticks_remain<5,interrupt_global=1,if=talent.shadow_embrace.enabled&variable.maintain_se&!debuff.shadow_embrace.remains;
	if talents[AF.DrainSoul] and currentSpell ~= AF.DrainSoul and
		talents[AF.ShadowEmbrace] and
		maintainSe and
		not debuff[AF.ShadowEmbrace].remains
	then
		return AF.DrainSoul;
	end

	-- drain_soul,target_if=min:debuff.shadow_embrace.remains,chain=1,interrupt_if=ticks_remain<5,interrupt_global=1,if=talent.shadow_embrace.enabled&variable.maintain_se;
	if talents[AF.DrainSoul] and currentSpell ~= AF.DrainSoul and talents[AF.ShadowEmbrace] and maintainSe then
		return AF.DrainSoul;
	end

	-- drain_soul,interrupt_global=1,chain=1,interrupt=1;
	if talents[AF.DrainSoul] and currentSpell ~= AF.DrainSoul then
		return AF.DrainSoul;
	end

	-- Not needed
	-- shadow_bolt,cycle_targets=1,if=talent.shadow_embrace.enabled&variable.maintain_se&!debuff.shadow_embrace.remains&!action.shadow_bolt.in_flight;
	--if currentSpell ~= AF.ShadowBolt and (talents[AF.ShadowEmbrace] and maintainSe and not debuff[AF.ShadowEmbrace].remains and not inFlight) then
	--	return AF.ShadowBolt;
	--end

	-- shadow_bolt,target_if=min:debuff.shadow_embrace.remains,if=talent.shadow_embrace.enabled&variable.maintain_se;
	--if currentSpell ~= AF.ShadowBolt and talents[AF.ShadowEmbrace] and maintainSe then
	--	return AF.ShadowBolt;
	--end

	-- shadow_bolt;
	return AF.ShadowBolt;
end

function Warlock:AfflictionSpenders()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local azerite = fd.azerite;
	local buff = fd.buff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local targets = fd.targets;
	local timeToDie = fd.timeToDie;
	local gcd = fd.gcd;
	local useSeed = fd.useSeed;
	local padding = fd.padding;
	local contagion = fd.contagion;
	local spellHistory = fd.spellHistory;
	local soulShards = fd.soulShards;
	local timeToShard = fd.timeToShard;

	-- unstable_affliction,if=cooldown.summon_darkglare.remains<=soul_shard*execute_time&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=soul_shard*execute_time);
	if soulShards >= 1  and ( --and currentSpell ~= AF.UnstableAffliction
		cooldown[AF.SummonDarkglare].remains <= soulShards * gcd and
		(not talents[AF.Deathbolt] or cooldown[AF.Deathbolt].remains <= soulShards * gcd)
	) then
		return AF.UnstableAffliction;
	end

	-- call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(6-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains;
	if (cooldown[AF.SummonDarkglare].remains < timeToShard * (6 - soulShards) or cooldown[AF.SummonDarkglare].ready) and
		timeToDie > cooldown[AF.SummonDarkglare].remains
	then
		return Warlock:AfflictionFillers();
	end

	-- seed_of_corruption,if=variable.use_seed;
	if soulShards >= 1 and useSeed then --currentSpell ~= AF.SeedOfCorruption and
		return AF.SeedOfCorruption;
	end

	-- unstable_affliction,if=!variable.use_seed&!prev_gcd.1.summon_darkglare&(talent.deathbolt.enabled&cooldown.deathbolt.remains<=execute_time&!azerite.cascading_calamity.enabled|(soul_shard>=5&spell_targets.seed_of_corruption_aoe<2|soul_shard>=2&spell_targets.seed_of_corruption_aoe>=2)&target.time_to_die>4+execute_time&spell_targets.seed_of_corruption_aoe=1|target.time_to_die<=8+execute_time*soul_shard);
	if soulShards >= 1  and ( --and currentSpell ~= AF.UnstableAffliction
		not useSeed and
		not spellHistory[1] == AF.SummonDarkglare and
		(
			talents[AF.Deathbolt] and
			cooldown[AF.Deathbolt].remains <= timeShift and
			not azerite[A.CascadingCalamity] > 0 or (soulShards >= 5 and targets < 2 or soulShards >= 2 and targets >= 2)
			and timeToDie > 4 + timeShift and
			targets == 1 or timeToDie <= 8 + timeShift * soulShards
		)
	) then
		return AF.UnstableAffliction;
	end

	-- unstable_affliction,if=!variable.use_seed&contagion<=cast_time+variable.padding;
	if soulShards >= 1  and --and currentSpell ~= AF.UnstableAffliction
		not useSeed and contagion <= timeShift + padding
	then
		return AF.UnstableAffliction;
	end

	-- unstable_affliction,cycle_targets=1,if=!variable.use_seed&(!talent.deathbolt.enabled|cooldown.deathbolt.remains>time_to_shard|soul_shard>1)&(!talent.vile_taint.enabled|soul_shard>1)&contagion<=cast_time+variable.padding&(!azerite.cascading_calamity.enabled|buff.cascading_calamity.remains>time_to_shard);
	if soulShards >= 1 and ( --currentSpell ~= AF.UnstableAffliction
		not useSeed and
		(not talents[AF.Deathbolt] or cooldown[AF.Deathbolt].remains > timeToShard or soulShards > 1) and
		(not talents[AF.VileTaint] or soulShards > 1) and
		contagion <= timeShift + padding and
		(not azerite[A.CascadingCalamity] > 0 or buff[A.CascadingCalamity].remains > timeToShard)
	) then
		return AF.UnstableAffliction;
	end
end

--[[
function Warlock:Affliction()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell = fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell;

	local SoulShards = UnitPower('player', EnumPowerType.SoulShards);
	local THP = MaxDps:TargetPercentHealth();

	if currentSpell == WA.UnstableAffliction then
		SoulShards = SoulShards - 1;
	end

	-- Cooldowns
	MaxDps:GlowCooldown(WA.SummonDarkglare, cooldown[WA.SummonDarkglare].ready);

	if talents[WA.DarkSoulMisery] then
		MaxDps:GlowCooldown(WA.DarkSoulMisery, cooldown[WA.DarkSoulMisery].ready);
	end

	--Rotation
	--1. Cast Agony if not Applied or is about to run out
	if debuff[WA.Agony].remains < 5 then
		return WA.Agony;
	end

	--2. Cast Corruption if not Applied or is about to run out
	if debuff[WA.CorruptionAura].remains < 4 then
		return WA.Corruption;
	end


	--3. Apply SiphonLife if not Applied or is about to run out
	if talents[WA.SiphonLife] and debuff[WA.SiphonLife].remains < 4 then
		return WA.SiphonLife;
	end

	--4. Cast Drain Soul if Talented and Target Health <= 20%
	if talents[WA.DrainSoul] and THP <= 0.2 then
		return WA.DrainSoul;
	end

	--5. Keep Haunted on Target if Talented
	if talents[WA.Haunt] and cooldown[WA.Haunt].ready and currentSpell ~= WA.Haunt then
		return WA.Haunt;
	end

	--6. Cast Unstable Affliction with 4 - 5 Shards
	if SoulShards >= 4 and currentSpell ~= WA.UnstableAffliction then
		return WA.UnstableAffliction;
	end

	--7. Cast Deathbolt if all three debuffs are fresh aplied
	if debuff[WA.Agony].remains > 11 and
		debuff[WA.CorruptionAura].remains > 9 and
		debuff[WA.UnstableAfflictionAura].remains > 3 and
		cooldown[WA.Deathbolt].ready then
		return WA.Deathbolt;
	end

	--8 Cast Vile Taint or Phantom Singularity if talented
	if talents[WA.VileTaint] and cooldown[WA.VileTaint].ready
		and SoulShards >= 1 and currentSpell ~= WA.VileTaint then
		return WA.VileTaint;
	end

	if talents[WA.PhantomSingularity] and cooldown[WA.PhantomSingularity].ready then
		return WA.PhantomSingularity;
	end

	-- 9. Remain 1 Unstable Afflicton on target
	if SoulShards >= 1 and debuff[WA.UnstableAfflictionAura].remains < 2
		and currentSpell ~= WA.UnstableAffliction then
		return WA.UnstableAffliction;
	end

	if talents[WA.DrainSoul] then
		return WA.DrainSoul;
	else
		return WA.ShadowBolt;
	end
end
]]--
function Warlock:Demonology()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell = fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell;

	local SoulShards = UnitPower('player', EnumPowerType.SoulShards);

	if currentSpell == WN.CallDreadstalkers then
		SoulShards = SoulShards - 2;
	elseif currentSpell == WN.HandOfGuldan then
		SoulShards = SoulShards - 3;
	elseif currentSpell == WN.SummonVilefiend then
		SoulShards = SoulShards - 1;
	elseif currentSpell == WN.ShadowBoltDemonology then
		SoulShards = SoulShards + 1;
	elseif currentSpell == WN.Demonbolt then
		SoulShards = SoulShards + 2;
	end

	if SoulShards < 0 then
		SoulShards = 0;
	end

	if not UnitExists('pet') then
		return WN.SummonFelguard;
	end

	--Cooldowns
	MaxDps:GlowCooldown(WN.SummonDemonicTyrant, cooldown[WN.SummonDemonicTyrant].ready);
	MaxDps:GlowCooldown(WN.GrimoireFelguard, SoulShards >= 1 and cooldown[WN.GrimoireFelguard].ready);

	if talents[WN.NetherPortal] then
		MaxDps:GlowCooldown(WN.NetherPortal, SoulShards >= 3 and cooldown[WN.NetherPortal].ready);
	end

	if cooldown[WN.CallDreadstalkers].ready and SoulShards >= 3
		and currentSpell ~= WN.CallDreadstalkers then
		return WN.CallDreadstalkers;
	end

	if talents[WN.DemonicStrength] and cooldown[WN.DemonicStrength].ready then
		return WN.DemonicStrength;
	end

	if talents[WN.SummonVilefiend] and cooldown[WN.SummonVilefiend].ready and SoulShards >= 1
		and currentSpell ~= WN.SummonVilefiend then
		return WN.SummonVilefiend;
	end

	if SoulShards >= 4 and currentSpell ~= WN.HandOfGuldan then
		return WN.HandOfGuldan;
	end

	if buff[WN.DemonicCoreAura].count >= 2 then
		return WN.Demonbolt;
	end

	local ic = Warlock:ImpsCount()
	if talents[WN.PowerSiphon] and cooldown[WN.PowerSiphon].ready and ic > 2 then
		return WN.PowerSiphon;
	end

	if SoulShards >= 3 and currentSpell ~= WN.HandOfGuldan then
		return WN.HandOfGuldan;
	end

	return WN.ShadowBoltDemonology;
end

----------------------------------------------
-- Main rotation: Destruction
----------------------------------------------
function Warlock:Destruction()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell;

	local SoulShards = UnitPower('player', EnumPowerType.SoulShards, true) / 10;

	if currentSpell == WD.ChaosBolt then
		SoulShards = SoulShards - 2;
	end

	--Cooldowns
	MaxDps:GlowCooldown(WD.Havoc, cooldown[WD.Havoc].ready);
	MaxDps:GlowCooldown(WD.SummonInfernal, cooldown[WD.SummonInfernal].ready);

	if talents[WD.DarkSoulInstability] then
		MaxDps:GlowCooldown(WD.DarkSoulInstability, cooldown[WD.DarkSoulInstability].ready);
	end

	--Rotation Start

	if talents[WD.Cataclysm] and cooldown[WD.Cataclysm].ready and currentSpell ~= WD.Cataclysm then
		return WD.Cataclysm;
	end

	--1. Cast ChaosBolt if Backdraft is active and at least 2 seconds left
	if buff[WD.Backdraft].remains >= 2 and SoulShards >= 2 and currentSpell ~= WD.ChaosBolt then
		return WD.ChaosBolt;
	end

	--2. Cast Soulfire on cd if Talented
	if talents[WD.Soulfire] and cooldown[WD.Soulfire].ready and currentSpell ~= WD.Soulfire then
		return WD.Soulfire;
	end

	--3. Apply or Reapply Immolate
	if debuff[WD.ImmolateAura].refreshable and currentSpell ~= WD.Immolate and currentSpell ~= WD.Cataclysm then
		return WD.Immolate;
	end

	--4. Cast ChaosBolt if Capped
	if SoulShards >= 4 then
		return WD.ChaosBolt;
	end

	--5. Cast Conflagrate on CD but keep almost 1 Charge for Burst
	if cooldown[WD.Conflagrate].charges > 1.5 then
		return WD.Conflagrate;
	end

	--6. Cast Demonfire Whenever Possible and Target has Immolate applied for at least 3 seconds
	if talents[WD.ChannelDemonfire] and cooldown[WD.ChannelDemonfire].ready and
		debuff[WD.ImmolateAura].remains >= 3 and currentSpell ~= WD.ChannelDemonfire then
		return WD.ChannelDemonfire;
	end

	--7. Cast Shadowburn dont know why cause Talent seems to bee quiet shit...
	if talents[WD.Shadowburn] and cooldown[WD.Shadowburn].ready then
		return WD.Shadowburn;
	end

	return WD.Incinerate;
end

function Warlock:TimeToShard(fd, activeAgonies)
	local talents = fd.talents;
	local tickTime = 2 * MaxDps:AttackHaste();
	local average = 1 / (0.184 * math.pow(activeAgonies, -2 / 3)) * (tickTime / activeAgonies);

	if talents[AF.CreepingDeath] then
		average = average / 1.15;
	end

	return average;
end

function Warlock:Contagion(timeShift)
	timeShift = timeShift or 0;
	local longestRemains, count = 0, 0;
	local t = GetTime();
	local i = 1;

	while true do
		local name, _, _, _, _, expirationTime, _, _, _, spellId = UnitAura('target', i, 'PLAYER|HARMFUL');

		if not name then break; end
		i = i + 1;

		if UnstableAfflictionAuras[spellId] then
			local remains = expirationTime - t - timeShift;
			if remains > 0 then

				if longestRemains < remains then
					longestRemains = remains;
				end

				count = count + 1;
			end
		end
	end

	return longestRemains, count;
end

Warlock.WildImps = {};
function Warlock:CLEU()
	local compTime = GetTime();

	local _, event, _, sourceGuid, sourceName, _, _, destGuid, destName, _, _, spellId, spellName = CombatLogGetCurrentEventInfo();

	if event == 'SPELL_SUMMON' and sourceGuid == UnitGUID('player') then
		if destName == 'Wild Imp' then
			self.WildImps[destGuid] = compTime;
		end
	end
end

function Warlock:ImpsCount()
	local c = 0;
	local compTime = GetTime();

	for index, value in pairs(self.WildImps) do
		if self.WildImps[index] + 11 > compTime then
			-- 11 seconds just to be sure they wont die soon
			c = c + 1;
		else
			self.WildImps[index] = nil;
		end
	end

	return c;
end