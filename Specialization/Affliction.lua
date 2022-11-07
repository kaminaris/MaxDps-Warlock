local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then
	return
end

local Warlock = addonTable.Warlock;
local MaxDps = MaxDps;
local UnitPower = UnitPower;

local AF = {
	AbsoluteCorruption = 196103,
	Agony = 980,
	Corruption = 172,
	CorruptionDebuff = 146739,
	DarkSoulMisery = 113860,
	DrainLife = 234153,
	DrainSoul = 198590,
	GrimoireOfSacrifice = 108503,
	Haunt = 48181,
	InevitableDemiseBuff = 334320,
	InquisitorsGaze = 386344,
	InquisitorsGazeBuff = 388068,
	MaleficRapture = 324536,
	PhantomSingularity = 205179,
	SeedOfCorruption = 27243,
	ShadowBolt = 686,
	ShadowEmbrace = 32388,
	ShadowEmbraceDebuff = 32390,
	SiphonLife = 63106,
	SoulRot = 386997,
	SowTheSeeds = 196226,
	SummonDarkglare = 205180,
	UnstableAffliction = 316099,
	VileTaint = 278350
};
setmetatable(AF, Warlock.spellMeta);

function Warlock:Affliction()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local targets = MaxDps:SmartAoe();
	fd.targets = targets;
	local timeToDie = fd.timeToDie;
	local soulShards = UnitPower('player', Enum.PowerType.SoulShards);
	local mana = UnitPower('player', Enum.PowerType.Mana)
	fd.mana = mana
	local timeShift = fd.timeShift

	local filler = talents[AF.DrainSoul] and AF.DrainSoul or AF.ShadowBolt;
	fd.filler = filler

	if currentSpell == AF.SeedOfCorruption or
			currentSpell == AF.MaleficRapture or
			currentSpell == AF.VileTaint
	then
		soulShards = soulShards - 1;
	end
	if soulShards < 0 then soulShards = 0; end
	fd.soulShards = soulShards;

	MaxDps:GlowCooldown(DE.InquisitorsGaze, talents[AF.InquisitorsGaze] and cooldown[AF.InquisitorsGaze].ready and not buff[DE.InquisitorsGazeBuff].up)

	-- call_action_list,name=aoe,if=active_enemies>3
	if targets > 3 then
		local result = Warlock:AfflictionAoe()
		if result then
			return result
		end
	end

	-- malefic_rapture,if=time_to_die<execute_time*soul_shard&dot.unstable_affliction.ticking
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (timeToDie < timeShift * soulShards and debuff[AF.UnstableAffliction].up) then
		return AF.MaleficRapture
	end

	-- call_action_list,name=darkglare_prep,if=(covenant.necrolord|covenant.kyrian|covenant.none)&dot.phantom_singularity.ticking&dot.phantom_singularity.remains<2
	if talents[AF.SummonDarkglare] and debuff[AF.PhantomSingularity].up and debuff[AF.PhantomSingularity].remains < 2 then
		local result = Warlock:AfflictionDarkglarePrep()
		if result then
			return result
		end
	end

	-- call_action_list,name=dot_prep,if=(covenant.necrolord|covenant.kyrian|covenant.none)&talent.phantom_singularity&!dot.phantom_singularity.ticking&cooldown.phantom_singularity.remains<4
	local result = Warlock:AfflictionDotPrep()
	if result then
		return result
	end

	-- dark_soul,if=dot.phantom_singularity.ticking
	if talents[AF.DarkSoulMisery] and cooldown[AF.DarkSoulMisery].ready and mana >= 500 and (debuff[AF.PhantomSingularity].up) then
		return AF.DarkSoulMisery
	end

	-- dark_soul,if=!talent.phantom_singularity&(dot.soul_rot.ticking|dot.impending_catastrophe_dot.ticking)
	if talents[AF.DarkSoulMisery] and cooldown[AF.DarkSoulMisery].ready and mana >= 500 and (not talents[AF.PhantomSingularity] and debuff[AF.SoulRot].up) then
		return AF.DarkSoulMisery
	end

	-- phantom_singularity,if=(covenant.kyrian|covenant.none|(covenant.necrolord&!runeforge.malefic_wrath))&(trinket.empyreal_ordnance.cooldown.remains<162|!equipped.empyreal_ordnance)
	if talents[AF.PhantomSingularity] and cooldown[AF.PhantomSingularity].ready then
		return AF.PhantomSingularity
	end

	-- haunt
	if talents[AF.Haunt] and cooldown[AF.Haunt].ready and mana >= 1000 and currentSpell ~= AF.Haunt then
		return AF.Haunt
	end

	-- seed_of_corruption,if=active_enemies>2&talent.siphon_life&!dot.seed_of_corruption.ticking&!in_flight&dot.corruption.remains<4
	if soulShards >= 1 and currentSpell ~= AF.SeedOfCorruption and (targets > 2 and talents[AF.SiphonLife] and not debuff[AF.SeedOfCorruption].up and (talents[AF.AbsoluteCorruption] or not debuff[AF.CorruptionDebuff].remains < 4)) then
		return AF.SeedOfCorruption
	end

	-- vile_taint,if=(soul_shard>1|active_enemies>2)&cooldown.summon_darkglare.remains>12
	if talents[AF.VileTaint] and cooldown[AF.VileTaint].ready and soulShards >= 1 and currentSpell ~= AF.VileTaint and (( soulShards > 1 or targets > 2 ) and (not talents[AF.SummonDarkglare] or cooldown[AF.SummonDarkglare].remains) > 12) then
		return AF.VileTaint
	end

	-- unstable_affliction,if=dot.unstable_affliction.remains<4
	if talents[AF.UnstableAffliction] and mana >= 500 and currentSpell ~= AF.UnstableAffliction and (not debuff[AF.UnstableAffliction].up or debuff[AF.UnstableAffliction].remains < 4) then
		return AF.UnstableAffliction
	end

	-- soul_rot,if=talent.phantom_singularity&dot.phantom_singularity.ticking
	if talents[AF.SoulRot] and cooldown[AF.SoulRot].ready and mana >= 250 and currentSpell ~= AF.SoulRot and (not talents[AF.PhantomSingularity] or debuff[AF.PhantomSingularity].up) then
		return AF.SoulRot
	end

	-- malefic_rapture,if=soul_shard>4&time>21
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and soulShards > 4 then
		return AF.MaleficRapture
	end

	-- call_action_list,name=darkglare_prep,if=(covenant.necrolord|covenant.kyrian|covenant.none)&cooldown.summon_darkglare.ready
	if talents[AF.SummonDarkglare] and cooldown[AF.SummonDarkglare].ready then
		result = Warlock:AfflictionDarkglarePrep()
		if result then
			return result
		end
	end

	-- dark_soul,if=cooldown.summon_darkglare.remains>time_to_die&(!talent.phantom_singularity|cooldown.phantom_singularity.remains>time_to_die)
	if talents[AF.DarkSoulMisery] and cooldown[AF.DarkSoulMisery].ready and mana >= 500 and ((not talents[AF.SummonDarkglare] or cooldown[AF.SummonDarkglare].remains > timeToDie) and ( not talents[AF.PhantomSingularity] or cooldown[AF.PhantomSingularity].remains > timeToDie )) then
		return AF.DarkSoulMisery
	end

	-- dark_soul,if=!talent.phantom_singularity&cooldown.summon_darkglare.remains+cooldown.summon_darkglare.duration<time_to_die
	if talents[AF.DarkSoulMisery] and cooldown[AF.DarkSoulMisery].ready and mana >= 500 and (not talents[AF.PhantomSingularity] and (not talents[AF.SummonDarkglare] or cooldown[AF.SummonDarkglare].remains + 20 < timeToDie)) then
		return AF.DarkSoulMisery
	end

	-- call_action_list,name=se,if=talent.shadow_embrace&(debuff.shadow_embrace.stack<(2-action.shadow_bolt.in_flight)|debuff.shadow_embrace.remains<3)
	if talents[AF.ShadowEmbrace] and ( not debuff[AF.ShadowEmbraceDebuff].up or debuff[AF.ShadowEmbraceDebuff].count < 1 or debuff[AF.ShadowEmbraceDebuff].remains < 3 ) then
		result = Warlock:AfflictionSe()
		if result then
			return result
		end
	end

	-- malefic_rapture,if=(dot.vile_taint.ticking|dot.impending_catastrophe_dot.ticking|dot.soul_rot.ticking)&(!runeforge.malefic_wrath|buff.malefic_wrath.stack<3|soul_shard>1)
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (( debuff[AF.VileTaint].up or debuff[AF.SoulRot].up ) and soulShards > 1 ) then
		return AF.MaleficRapture
	end

	-- malefic_rapture,if=talent.sow_the_seeds
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (talents[AF.SowTheSeeds]) then
		return AF.MaleficRapture
	end

	-- drain_life,if=buff.inevitable_demise.stack>40|buff.inevitable_demise.up&time_to_die<4
	if buff[AF.InevitableDemiseBuff].count > 40 or buff[AF.InevitableDemiseBuff].up and timeToDie < 4 then
		return AF.DrainLife
	end

	-- soul_rot,if=talent.phantom_singularity&dot.phantom_singularity.ticking
	if talents[AF.SoulRot] and cooldown[AF.SoulRot].ready and mana >= 250 and currentSpell ~= AF.SoulRot and (not talents[AF.PhantomSingularity] or debuff[AF.PhantomSingularity].up) then
		return AF.SoulRot
	end

	-- unstable_affliction,if=refreshable
	if talents[AF.UnstableAffliction] and mana >= 500 and currentSpell ~= AF.UnstableAffliction and (debuff[AF.UnstableAffliction].refreshable) then
		return AF.UnstableAffliction
	end

	-- drain_soul,interrupt=1
	return fd.filler
end

function Warlock:AfflictionAoe()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local currentSpell = fd.currentSpell
	local talents = fd.talents
	local timeToDie = fd.timeToDie
	local mana = fd.mana
	local soulShards = fd.soulShards

	-- phantom_singularity
	if talents[AF.PhantomSingularity] and cooldown[AF.PhantomSingularity].ready then
		return AF.PhantomSingularity
	end

	-- haunt
	if talents[AF.Haunt] and cooldown[AF.Haunt].ready and mana >= 1000 and currentSpell ~= AF.Haunt then
		return AF.Haunt
	end

	-- call_action_list,name=darkglare_prep,if=(covenant.necrolord|covenant.kyrian|covenant.none)&dot.phantom_singularity.ticking&dot.phantom_singularity.remains<2
	if talents[AF.SummonDarkglare] and debuff[AF.PhantomSingularity].up and debuff[AF.PhantomSingularity].remains < 2 then
		local result = Warlock:AfflictionDarkglarePrep()
		if result then
			return result
		end
	end

	-- seed_of_corruption,if=!talent.sow_the_seeds&!dot.seed_of_corruption.ticking&!in_flight&dot.corruption.refreshable
	if soulShards >= 1 and currentSpell ~= AF.SeedOfCorruption and not debuff[AF.SeedOfCorruption].up and not debuff[AF.CorruptionDebuff].refreshable then
		return AF.SeedOfCorruption
	end

	-- unstable_affliction,if=dot.unstable_affliction.refreshable
	if talents[AF.UnstableAffliction] and mana >= 500 and currentSpell ~= AF.UnstableAffliction and (debuff[AF.UnstableAffliction].refreshable) then
		return AF.UnstableAffliction
	end

	-- vile_taint,if=soul_shard>1
	if talents[AF.VileTaint] and cooldown[AF.VileTaint].ready and soulShards >= 1 and currentSpell ~= AF.VileTaint then
		return AF.VileTaint
	end

	-- soul_rot,if=talent.phantom_singularity&dot.phantom_singularity.ticking
	if talents[AF.SoulRot] and cooldown[AF.SoulRot].ready and mana >= 250 and currentSpell ~= AF.SoulRot and (not talents[AF.PhantomSingularity] or debuff[AF.PhantomSingularity].up) then
		return AF.SoulRot
	end

	-- call_action_list,name=darkglare_prep,if=(covenant.necrolord|covenant.kyrian|covenant.none)&cooldown.summon_darkglare.remains<2&(dot.phantom_singularity.remains>2|!talent.phantom_singularity)
	if talents[AF.SummonDarkglare] and cooldown[AF.SummonDarkglare].remains < 2 and ( debuff[AF.PhantomSingularity].remains > 2 or not talents[AF.PhantomSingularity] ) then
		local result = Warlock:AfflictionDarkglarePrep()
		if result then
			return result
		end
	end

	-- dark_soul,if=cooldown.summon_darkglare.remains>time_to_die&(!talent.phantom_singularity|cooldown.phantom_singularity.remains>time_to_die)
	if talents[AF.DarkSoulMisery] and cooldown[AF.DarkSoulMisery].ready and mana >= 500 and (not talents[AF.SummonDarkglare] or (cooldown[AF.SummonDarkglare].remains > timeToDie and ( not talents[AF.PhantomSingularity] or cooldown[AF.PhantomSingularity].remains > timeToDie ))) then
		return AF.DarkSoulMisery
	end

	-- dark_soul,if=cooldown.summon_darkglare.remains+cooldown.summon_darkglare.duration<time_to_die
	if talents[AF.DarkSoulMisery] and cooldown[AF.DarkSoulMisery].ready and mana >= 500 and (not talents[AF.SummonDarkglare] or (cooldown[AF.SummonDarkglare].remains + 20 < timeToDie)) then
		return AF.DarkSoulMisery
	end

	-- malefic_rapture,if=dot.vile_taint.ticking
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (debuff[AF.VileTaint].up) then
		return AF.MaleficRapture
	end

	-- malefic_rapture,if=dot.soul_rot.ticking&!talent.sow_the_seeds
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (debuff[AF.SoulRot].up and not talents[AF.SowTheSeeds]) then
		return AF.MaleficRapture
	end

	-- malefic_rapture,if=!talent.vile_taint
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (not talents[AF.VileTaint]) then
		return AF.MaleficRapture
	end

	-- malefic_rapture,if=soul_shard>4
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (soulShards > 4) then
		return AF.MaleficRapture
	end

	-- soul_rot,if=talent.phantom_singularity&dot.phantom_singularity.ticking
	if talents[AF.SoulRot] and cooldown[AF.SoulRot].ready and mana >= 250 and currentSpell ~= AF.SoulRot and (not talents[AF.PhantomSingularity] or debuff[AF.PhantomSingularity].up) then
		return AF.SoulRot
	end

	-- drain_life,if=buff.inevitable_demise.stack>=50|buff.inevitable_demise.up&time_to_die<5|buff.inevitable_demise.stack>=35&dot.soul_rot.ticking
	if buff[AF.InevitableDemiseBuff].count >= 50 or buff[AF.InevitableDemiseBuff].up and timeToDie < 5 or buff[AF.InevitableDemiseBuff].count >= 35 and debuff[AF.SoulRot].up then
		return AF.DrainLife
	end

	-- drain_soul,interrupt=1
	return fd.filler
end

function Warlock:AfflictionDarkglarePrep()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local currentSpell = fd.currentSpell
	local talents = fd.talents
	local soulShards = fd.soulShards
	local debuff = fd.debuff
	local mana = fd.mana

	-- vile_taint
	if talents[AF.VileTaint] and cooldown[AF.VileTaint].ready and soulShards >= 1 and currentSpell ~= AF.VileTaint then
		return AF.VileTaint
	end

	-- dark_soul
	if talents[AF.DarkSoulMisery] and cooldown[AF.DarkSoulMisery].ready and mana >= 500 then
		return AF.DarkSoulMisery
	end

	-- soul_rot,if=talent.phantom_singularity&dot.phantom_singularity.ticking
	if talents[AF.SoulRot] and cooldown[AF.SoulRot].ready and mana >= 250 and currentSpell ~= AF.SoulRot and (not talents[AF.PhantomSingularity] or debuff[AF.PhantomSingularity].up) then
		return AF.SoulRot
	end

	-- summon_darkglare
	if talents[AF.SummonDarkglare] and cooldown[AF.SummonDarkglare].ready and mana >= 1000 then
		return AF.SummonDarkglare
	end
end

function Warlock:AfflictionDotPrep()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local debuff = fd.debuff
	local currentSpell = fd.currentSpell
	local talents = fd.talents
	local mana = fd.mana

	-- agony,if=dot.agony.remains<8&cooldown.summon_darkglare.remains>dot.agony.remains
	if mana >= 500 and (not debuff[AF.Agony].up or (debuff[AF.Agony].remains < 8 and (not talents[AF.SummonDarkglare] or cooldown[AF.SummonDarkglare].remains > debuff[AF.Agony].remains))) then
		return AF.Agony
	end

	-- siphon_life,if=dot.siphon_life.remains<8&cooldown.summon_darkglare.remains>dot.siphon_life.remains
	if talents[AF.SiphonLife] and mana >= 500 and (not debuff[AF.SiphonLife].up or (debuff[AF.SiphonLife].remains < 8 and (not talents[AF.SummonDarkglare] or cooldown[AF.SummonDarkglare].remains > debuff[AF.SiphonLife].remains))) then
		return AF.SiphonLife
	end

	-- unstable_affliction,if=dot.unstable_affliction.remains<8&cooldown.summon_darkglare.remains>dot.unstable_affliction.remains
	if talents[AF.UnstableAffliction] and mana >= 500 and currentSpell ~= AF.UnstableAffliction and (not debuff[AF.UnstableAffliction].up or (debuff[AF.UnstableAffliction].remains < 8 and (not talents[AF.SummonDarkglare] or cooldown[AF.SummonDarkglare].remains > debuff[AF.UnstableAffliction].remains))) then
		return AF.UnstableAffliction
	end

	-- corruption,if=dot.corruption.remains<8&cooldown.summon_darkglare.remains>dot.corruption.remains
	if debuff[AF.CorruptionDebuff].up and talents[AF.AbsoluteCorruption] then
		return
	end

	if mana >= 500 and (not debuff[AF.CorruptionDebuff].up or (debuff[AF.CorruptionDebuff].remains < 8 and (not talents[AF.SummonDarkglare] or cooldown[AF.SummonDarkglare].remains > debuff[AF.CorruptionDebuff].remains))) then
		return AF.Corruption
	end
end

function Warlock:AfflictionSe()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local currentSpell = fd.currentSpell
	local talents = fd.talents
	local mana = fd.mana

	-- haunt
	if talents[AF.Haunt] and cooldown[AF.Haunt].ready and mana >= 1000 and currentSpell ~= AF.Haunt then
		return AF.Haunt
	end

	-- drain_soul,interrupt=1
	return fd.filler
end
