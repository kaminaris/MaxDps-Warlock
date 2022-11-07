local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end

local Warlock = addonTable.Warlock
local MaxDps = MaxDps
local UnitPower = UnitPower
local GetTotemInfo = GetTotemInfo

local DS = {
	Backdraft = 196406,
	Cataclysm = 152108,
	ChannelDemonfire = 196447,
	ChaosBolt = 116858,
	Conflagrate = 17962,
	DarkSoulInstability = 113858,
	Eradication = 196412,
	FireAndBrimstone = 196408,
	Flashover = 267115,
	GrimoireOfSacrifice = 108503,
	Havoc = 80240,
	Immolate = 348,
	ImmolateDebuff = 157736,
	Incinerate = 29722,
	Inferno = 270545,
	InquisitorsGaze = 386344,
	InquisitorsGazeBuff = 388068,
	InternalCombustion = 266134,
	RainOfChaos = 266086,
	RainOfFire = 5740,
	RitualOfRuin = 387156,
	RoaringBlaze = 205184,
	Shadowburn = 17877,
	SoulFire = 6353,
	SummonInfernal = 1122,
}

function Warlock:Destruction()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local currentSpell = fd.currentSpell
	local talents = fd.talents
	local targets = MaxDps:SmartAoe()
	fd.targets = targets
	local timeToDie = fd.timeToDie
	local soulShards = UnitPower('player', Enum.PowerType.SoulShards, true) / 10
	
	local havocActive = cooldown[DS.Havoc].remains > 18
	local petInfernal = GetTotemInfo(1)
	local petBlasphemy = petInfernal
	local timeShift = fd.timeShift
	local gcd = fd.gcd

	if currentSpell == DS.ChaosBolt then
		soulShards = soulShards - 2
	elseif currentSpell == DS.Incinerate then
		soulShards = soulShards + 0.2
	end
	if soulShards < 0 then
		soulShards = 0
	end
	fd.soulShards = soulShards
	fd.petInfernal = petInfernal

	Warlock:DestructionCooldowns()
	
	-- call_action_list,name=havoc,if=havoc_active&active_enemies>1&active_enemies<5-talent.inferno.enabled+(talent.inferno.enabled&talent.internal_combustion.enabled)
	if havocActive and targets > 1 and targets < 5 - (talents[DS.Inferno] and 1 or 0) + ( (talents[DS.Inferno] and talents[DS.InternalCombustion]) and 1 or 0 ) then
		local result = Warlock:DestructionHavoc()
		if result then
			return result
		end
	end

	-- conflagrate,if=talent.roaring_blaze.enabled&debuff.roaring_blaze.remains<1.5
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and (talents[DS.RoaringBlaze] and debuff[DS.RoaringBlaze].remains < 1.5) then
		return DS.Conflagrate
	end

	-- cataclysm
	if talents[DS.Cataclysm] and cooldown[DS.Cataclysm].ready and currentSpell ~= DS.Cataclysm then
		return DS.Cataclysm
	end

	-- call_action_list,name=aoe,if=active_enemies>2-set_bonus.tier28_4pc
	if targets > 2 then
		local result = Warlock:DestructionAoe()
		if result then
			return result
		end
	end

	-- soul_fire,cycle_targets=1,if=refreshable&soul_shard<=4&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
	if talents[DS.SoulFire] and cooldown[DS.SoulFire].ready and currentSpell ~= DS.SoulFire and (debuff[DS.ImmolateDebuff].refreshable and soulShards <= 4 and ( not talents[DS.Cataclysm] or cooldown[DS.Cataclysm].remains > debuff[DS.ImmolateDebuff].remains )) then
		return DS.SoulFire
	end

	-- immolate,cycle_targets=1,if=remains<3&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
	if currentSpell ~= DS.Immolate and (debuff[DS.ImmolateDebuff].remains < 3 and ( not talents[DS.Cataclysm] or cooldown[DS.Cataclysm].remains > debuff[DS.ImmolateDebuff].remains )) then
		return DS.Immolate
	end

	-- immolate,if=talent.internal_combustion.enabled&action.chaos_bolt.in_flight&remains<duration*0.5
	if currentSpell ~= DS.Immolate and (talents[DS.InternalCombustion] and debuff[DS.ImmolateDebuff].remains < 9) then
		return DS.Immolate
	end

	-- chaos_bolt,if=(pet.infernal.active|pet.blasphemy.active)&soul_shard>=4
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (( petInfernal or petBlasphemy ) and soulShards >= 4) then
		return DS.ChaosBolt
	end

	-- channel_demonfire
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and currentSpell ~= DS.ChannelDemonfire then
		return DS.ChannelDemonfire
	end

	-- scouring_tithe
	--return DS.ScouringTithe

	-- decimating_bolt
	--return DS.DecimatingBolt

	-- havoc,cycle_targets=1,if=!(target=self.target)&(dot.immolate.remains>dot.immolate.duration*0.5|!talent.internal_combustion.enabled)
	--[[
	if talents[DS.Havoc] and cooldown[DS.Havoc].ready and (not ( target == ) and ( debuff[DS.ImmolateDebuff].remains > debuff[DS.ImmolateDebuff].duration * 0.5 or not talents[DS.InternalCombustion] )) then
		return DS.Havoc
	end
	--]]

	-- impending_catastrophe
	--return DS.ImpendingCatastrophe

	-- soul_rot
	--return DS.SoulRot

	-- havoc,if=runeforge.odr_shawl_of_the_ymirjar.equipped
	--[[if talents[DS.Havoc] and cooldown[DS.Havoc].ready and (runeforge[DS.OdrShawlOfTheYmirjar]) then
	return DS.Havoc
	end
	--]]

	-- variable,name=pool_soul_shards,value=active_enemies>1&cooldown.havoc.remains<=10|buff.ritual_of_ruin.up&talent.rain_of_chaos
	local poolSoulShards = targets > 1 and cooldown[DS.Havoc].remains <= 10 or buff[DS.RitualOfRuin].up and talents[DS.RainOfChaos]

	-- conflagrate,if=buff.backdraft.down&soul_shard>=1.5-0.3*talent.flashover.enabled&!variable.pool_soul_shards
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and (not buff[DS.Backdraft].up and soulShards >= 1.5 - 0.3 * (talents[DS.Flashover] and 1 or 0) and not poolSoulShards) then
		return DS.Conflagrate
	end

	-- chaos_bolt,if=pet.infernal.active|buff.rain_of_chaos.remains>cast_time
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (petInfernal or buff[DS.RainOfChaos].remains > timeShift) then
		return DS.ChaosBolt
	end

	-- chaos_bolt,if=buff.backdraft.up&!variable.pool_soul_shards
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (buff[DS.Backdraft].up and not poolSoulShards) then
		return DS.ChaosBolt
	end

	-- chaos_bolt,if=talent.eradication&!variable.pool_soul_shards&debuff.eradication.remains<cast_time
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (talents[DS.Eradication] and not poolSoulShards and debuff[DS.Eradication].remains < timeShift) then
		return DS.ChaosBolt
	end

	-- shadowburn,if=!variable.pool_soul_shards|soul_shard>=4.5
	if talents[DS.Shadowburn] and cooldown[DS.Shadowburn].ready and soulShards >= 1 and (not poolSoulShards or soulShards >= 4.5) then
		return DS.Shadowburn
	end

	-- chaos_bolt,if=soul_shard>3.5
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (soulShards > 3.5) then
		return DS.ChaosBolt
	end

	-- chaos_bolt,if=time_to_die<5&time_to_die>cast_time+travel_time
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (timeToDie < 5 and timeToDie > timeShift) then
		return DS.ChaosBolt
	end

	-- conflagrate,if=charges>1|time_to_die<gcd
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and (cooldown[DS.Conflagrate].charges > 1 or timeToDie < gcd) then
		return DS.Conflagrate
	end

	-- incinerate
	return DS.Incinerate
end

function Warlock:DestructionAoe()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local debuff = fd.debuff
	local buff = fd.buff
	local currentSpell = fd.currentSpell
	local talents = fd.talents
	local timeShift = fd.timeShift
	local targets = fd.targets
	local soulShards = fd.soulShards
	local petInfernal = fd.petInfernal
	local targetHp = MaxDps:TargetPercentHealth()

	-- rain_of_fire,if=pet.infernal.active&(!cooldown.havoc.ready|active_enemies>3)
	if soulShards >= 3 and (petInfernal and ( not cooldown[DS.Havoc].ready or targets > 3 )) then
		return DS.RainOfFire
	end
	
	-- soul_rot
	--return DS.SoulRot

	-- impending_catastrophe
	--return DS.ImpendingCatastrophe

	-- channel_demonfire,if=dot.immolate.remains>cast_time
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and currentSpell ~= DS.ChannelDemonfire and (debuff[DS.ImmolateDebuff].remains > timeShift) then
		return DS.ChannelDemonfire
	end

	-- immolate,cycle_targets=1,if=active_enemies<5&remains<5&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
	if currentSpell ~= DS.Immolate and (targets < 5 and debuff[DS.ImmolateDebuff].remains < 5 and ( not talents[DS.Cataclysm] or cooldown[DS.Cataclysm].remains > debuff[DS.ImmolateDebuff].remains )) then
		return DS.Immolate
	end

	-- havoc,cycle_targets=1,if=!(target=self.target)&active_enemies<4
	--[[
	if talents[DS.Havoc] and cooldown[DS.Havoc].ready and (not ( target == ) and targets < 4) then
		return DS.Havoc
	end
	--]]

	-- rain_of_fire
	if soulShards >= 3 then
		return DS.RainOfFire
	end

	-- havoc,cycle_targets=1,if=!(self.target=target)
	--[[
	if talents[DS.Havoc] and cooldown[DS.Havoc].ready and (not ( == target )) then
	return DS.Havoc
	end
	--]]

	-- decimating_bolt
	--return DS.DecimatingBolt

	-- incinerate,if=talent.fire_and_brimstone.enabled&buff.backdraft.up&soul_shard<5-0.2*active_enemies
	if currentSpell ~= DS.Incinerate and (talents[DS.FireAndBrimstone] and buff[DS.Backdraft].up and soulShards < 5 - 0.2 * targets) then
		return DS.Incinerate
	end

	-- soul_fire
	if talents[DS.SoulFire] and cooldown[DS.SoulFire].ready and currentSpell ~= DS.SoulFire then
		return DS.SoulFire
	end

	-- conflagrate,if=buff.backdraft.down
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and (not buff[DS.Backdraft].up) then
		return DS.Conflagrate
	end

	-- shadowburn,if=target.health.pct<20
	if talents[DS.Shadowburn] and cooldown[DS.Shadowburn].ready and soulShards >= 1 and (targetHp < 20) then
		return DS.Shadowburn
	end

	-- immolate,if=refreshable
	if currentSpell ~= DS.Immolate and (debuff[DS.ImmolateDebuff].refreshable) then
		return DS.Immolate
	end

	-- scouring_tithe
	--return DS.ScouringTithe

	-- incinerate
	return DS.Incinerate
end

function Warlock:DestructionCooldowns()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local talents = fd.talents
	local buff = fd.buff
	local timeToDie = fd.timeToDie
	local petInfernal = fd.petInfernal
	local targets = fd.targets

	MaxDps:GlowCooldown(DS.Havoc, targets > 1 and talents[DS.Havoc] and cooldown[DS.Havoc].ready);

	-- summon_infernal;
	MaxDps:GlowCooldown(DS.SummonInfernal, talents[DS.SummonInfernal] and cooldown[DS.SummonInfernal].ready);

	-- dark_soul_instability,if=pet.infernal.active|cooldown.summon_infernal.remains_expected>time_to_die
	MaxDps:GlowCooldown(DS.DarkSoulInstability, talents[DS.DarkSoulInstability] and cooldown[DS.DarkSoulInstability].ready and (petInfernal or not talents[DS.SummonInfernal] or cooldown[DS.SummonInfernal].remains > timeToDie));

	MaxDps:GlowCooldown(DS.InquisitorsGaze, talents[DS.InquisitorsGaze] and cooldown[DS.InquisitorsGaze].ready and not buff[DS.InquisitorsGazeBuff].up)
end

function Warlock:DestructionHavoc()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local currentSpell = fd.currentSpell
	local talents = fd.talents
	local timeShift = fd.timeShift
	local targets = fd.targets
	local soulShards = fd.soulShards

	local havocRemains = 10 + (cooldown[DS.Havoc].remains - 30);
	if havocRemains < 0 then havocRemains = 0; end

	-- conflagrate,if=buff.backdraft.down&soul_shard>=1&soul_shard<=4
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and (not buff[DS.Backdraft].up and soulShards >= 1 and soulShards <= 4) then
		return DS.Conflagrate
	end

	-- soul_fire,if=cast_time<havoc_remains
	if talents[DS.SoulFire] and cooldown[DS.SoulFire].ready and currentSpell ~= DS.SoulFire and (timeShift < havocRemains) then
		return DS.SoulFire
	end

	-- decimating_bolt,if=cast_time<havoc_remains&soulbind.lead_by_example.enabled
	--[[
	if timeShift < havocRemains and covenant.soulbindAbilities[DS.LeadByExample] then
		return DS.DecimatingBolt
	end
	--]]

	-- scouring_tithe,if=cast_time<havoc_remains
	--[[
	if timeShift < havocRemains then
		return DS.ScouringTithe
	end
	--]]

	-- immolate,if=talent.internal_combustion.enabled&remains<duration*0.5|!talent.internal_combustion.enabled&refreshable
	if currentSpell ~= DS.Immolate and (talents[DS.InternalCombustion] and debuff[DS.ImmolateDebuff].remains < 9 or not talents[DS.InternalCombustion] and debuff[DS.ImmolateDebuff].refreshable) then
		return DS.Immolate
	end

	-- chaos_bolt,if=cast_time<havoc_remains&!(set_bonus.tier28_4pc&active_enemies>1&talent.inferno.enabled)
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (timeShift < havocRemains and not (targets > 1 and talents[DS.Inferno] )) then
		return DS.ChaosBolt
	end

	-- rain_of_fire,if=set_bonus.tier28_4pc&active_enemies>1&talent.inferno.enabled
	--[[
	if soulShards >= 3 and (__SETBONUS_REMOVE__ and targets > 1 and talents[DS.Inferno]) then
		return DS.RainOfFire
	end
	--]]

	-- shadowburn
	if talents[DS.Shadowburn] and cooldown[DS.Shadowburn].ready and soulShards >= 1 then
		return DS.Shadowburn
	end

	-- incinerate,if=cast_time<havoc_remains
	if currentSpell ~= DS.Incinerate and (timeShift < havocRemains) then
		return DS.Incinerate
	end
end