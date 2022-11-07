local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end

local Warlock = addonTable.Warlock
local MaxDps = MaxDps
local UnitPower = UnitPower
local GetTime = GetTime
local GetTotemInfo = GetTotemInfo

local DE = {
	BilescourgeBombers = 267211,
	CallDreadstalkers = 104316,
	Demonbolt = 264178,
	DemonicCalling = 205145,
	DemonicConsumption = 267215,
	DemonicCoreAura = 264173,
	DemonicStrength = 267171,
	DemonicPower = 265273,
	Doom = 603,
	FromTheShadows = 267170,
	GrimoireFelguard = 111898,
	HandOfGuldan = 105174,
	Implosion = 196277,
	InquisitorsGaze = 386344,
	InquisitorsGazeBuff = 388068,
	NetherPortal = 267217,
	PowerSiphon = 264130,
	SacrificedSouls = 267214,
	ShadowBolt = 686,
	SoulboundTyrant = 334585,
	SoulStrike = 264057,
	SummonDemonicTyrant = 265187,
	SummonVilefiend = 264119
}

local TotemIcons = {
	[1616211] = 'Vilefiend',
	[136216]  = 'Felguard',
	[1378282] = 'Dreadstalker'
}

setmetatable(DE, Warlock.spellMeta)

---@param spellId number
local function GetCastTime(spellId)
	local _, _, _, castTime = GetSpellInfo(spellId)
	return (castTime or 0) / 1000
end

local firstTyrantTime
local nextTyrantCd

function Warlock:Demonology()
	local fd = MaxDps.FrameData

	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local currentSpell = fd.currentSpell
	local talents = fd.talents
	local targets = MaxDps:SmartAoe()
	local gcd = fd.gcd
	local timeToDie = fd.timeToDie
	local wildImps = GetSpellCount(DE.Implosion) --Warlock:ImpsCount()

	local time = GetTime()

	local soulShards = UnitPower('player', Enum.PowerType.SoulShards)
	local tyrantUp = buff[DE.DemonicPower].up
	local tyrantRemains = buff[DE.DemonicPower].remains

	if not firstTyrantTime or not talents[DE.SummonDemonicTyrant] or (cooldown[DE.SummonDemonicTyrant].ready and not UnitAffectingCombat("player")) then
		firstTyrantTime = time + 12 GetCastTime(DE.ShadowBolt)

		if talents[DE.GrimoireFelguard] then firstTyrantTime = firstTyrantTime + GetCastTime(DE.GrimoireFelguard) end
		if talents[DE.SummonVilefiend] then firstTyrantTime = firstTyrantTime + GetCastTime(DE.SummonVilefiend) end
		if talents[DE.GrimoireFelguard] then firstTyrantTime = firstTyrantTime + GetCastTime(DE.GrimoireFelguard) end

		if talents[DE.GrimoireFelguard] or talents[DE.SummonVilefiend] then
			firstTyrantTime = firstTyrantTime + gcd
		end

		if talents[DE.SummonDemonicTyrant] then
			firstTyrantTime = firstTyrantTime - GetCastTime(DE.SummonDemonicTyrant)
		end

		if firstTyrantTime - time < 10 then firstTyrantTime = time + 10 end
	end

	MaxDps:GlowCooldown(DE.InquisitorsGaze, talents[DE.InquisitorsGaze] and cooldown[DE.InquisitorsGaze].ready and not buff[DE.InquisitorsGazeBuff].up)

	if currentSpell == DE.CallDreadstalkers then
		soulShards = soulShards - 2
	elseif currentSpell == DE.HandOfGuldan then
		soulShards = soulShards - 3
	elseif currentSpell == DE.SummonVilefiend then
		soulShards = soulShards - 1
	elseif currentSpell == DE.NetherPortal then
		soulShards = soulShards - 1
	elseif currentSpell == DE.ShadowBolt then
		soulShards = soulShards + 1
	elseif currentSpell == DE.Demonbolt then
		soulShards = soulShards + 2
	elseif currentSpell == DE.SummonDemonicTyrant and talents[DE.SoulboundTyrant] then
		soulShards = soulShards + 3
	end

	if soulShards < 0 then
		soulShards = 0
	elseif soulShards > 5 then
		soulShards = 5
	end

	fd.wildImps = wildImps
	fd.soulShards = soulShards
	fd.targets = targets

	local pets = Warlock:DemonologyPets()
	fd.pets = pets

	nextTyrantCd = cooldown[DE.SummonDemonicTyrant].remains

	-- implosion,if=time_to_die<2*gcd
	if talents[DE.Implosion] and timeToDie < 2 * gcd then
		return DE.Implosion
	end

	if time < firstTyrantTime then
		local result = Warlock:DemonologyOpener()
		if result then
			return result
		end
	end

	-- call_action_list,name=tyrant_setup
	local result = Warlock:DemonologyTyrantSetup()
	if result then
		return result
	end

	-- demonic_strength,if=(!runeforge.wilfreds_sigil_of_superior_summoning&variable.next_tyrant_cd>9)|(pet.demonic_tyrant.active&pet.demonic_tyrant.remains<6*gcd.max)
	if talents[DE.DemonicStrength]
			and cooldown[DE.DemonicStrength].ready
			and (nextTyrantCd > 9 or tyrantUp and tyrantRemains < 6 * gcd )
	then
		return DE.DemonicStrength
	end

	-- call_dreadstalkers,if=!variable.use_bolt_timings&(variable.next_tyrant_cd>20-5*!runeforge.wilfreds_sigil_of_superior_summoning)
	if talents[DE.CallDreadstalkers]
			and cooldown[DE.CallDreadstalkers].ready
			and soulShards >= 2
			and currentSpell ~= DE.CallDreadstalkers
			and nextTyrantCd > 15
	then
		return DE.CallDreadstalkers
	end

	-- bilescourge_bombers,if=buff.tyrant.down&variable.next_tyrant_cd>5
	if talents[DE.BilescourgeBombers]
			and cooldown[DE.BilescourgeBombers].ready
			and soulShards >= 2
			and not tyrantUp
			and nextTyrantCd > 5
	then
		return DE.BilescourgeBombers
	end

	-- implosion,if=active_enemies>1+(1*talent.sacrificed_souls.enabled)&buff.wild_imps.stack>=6&buff.tyrant.down&variable.next_tyrant_cd>5
	if talents[DE.Implosion] and targets > 1 + ( 1 * (talents[DE.SacrificedSouls] and 1 or 0) )
			and wildImps >= 6
			and not tyrantUp
			and nextTyrantCd > 5
	then
		return DE.Implosion
	end

	-- implosion,if=active_enemies>2&buff.wild_imps.stack>=6&buff.tyrant.down&variable.next_tyrant_cd>5&!runeforge.implosive_potential&(!talent.from_the_shadows.enabled|debuff.from_the_shadows.up)
	if talents[DE.Implosion] and targets > 2
			and wildImps >= 6
			and not tyrantUp
			and nextTyrantCd > 5
			and ( not talents[DE.FromTheShadows] or debuff[DE.FromTheShadows].up ) then
		return DE.Implosion
	end

	-- grimoire_felguard,if=time_to_die<30
	if talents[DE.GrimoireFelguard]
			and cooldown[DE.GrimoireFelguard].ready
			and soulShards >= 1
			and timeToDie < 30
	then
		return DE.GrimoireFelguard
	end

	-- summon_vilefiend,if=time_to_die<28
	if talents[DE.SummonVilefiend]
			and cooldown[DE.SummonVilefiend].ready
			and soulShards >= 1
			and currentSpell ~= DE.SummonVilefiend
			and timeToDie < 28
	then
		return DE.SummonVilefiend
	end

	-- summon_demonic_tyrant,if=time_to_die<15
	if talents[DE.SummonDemonicTyrant]
			and cooldown[DE.SummonDemonicTyrant].ready
			and currentSpell ~= DE.SummonDemonicTyrant
			and timeToDie < 15
	then
		return DE.SummonDemonicTyrant
	end

	-- hand_of_guldan,if=soul_shard=5
	if soulShards == 5 and currentSpell ~= DE.HandOfGuldan then
		return DE.HandOfGuldan
	end

	-- doom,if=refreshable
	if talents[DE.Doom] and debuff[DE.Doom].refreshable then
		return DE.Doom
	end

	-- If Dreadstalkers are already active, no need to save shards
	-- hand_of_guldan,if=soul_shard>=3&(pet.dreadstalker.active|pet.demonic_tyrant.active)
	if currentSpell ~= DE.HandOfGuldan
			and soulShards >= 3
			and ( pets.Dreadstalker > 0 or tyrantUp )
	then
		return DE.HandOfGuldan
	end

	-- hand_of_guldan,if=soul_shard>=1&buff.nether_portal.up&cooldown.call_dreadstalkers.remains>2*gcd.max
	if currentSpell ~= DE.HandOfGuldan
			and soulShards >= 1
			and buff[DE.NetherPortal].up
			and (not talents[DE.CallDreadstalkers] or cooldown[DE.CallDreadstalkers].remains > 2 * gcd)
	then
		return DE.HandOfGuldan
	end

	-- hand_of_guldan,if=soul_shard>=1&variable.next_tyrant_cd<gcd.max&time>variable.first_tyrant_time-gcd.max
	if currentSpell ~= DE.HandOfGuldan
			and soulShards >= 1
			and time > firstTyrantTime-gcd
	then
		return DE.HandOfGuldan
	end

	-- Without Sacrificed Souls, Soul Strike is stronger than Demonbolt, so it has a higher priority
	-- soul_strike,if=!talent.sacrificed_souls.enabled
	if talents[DE.SoulStrike]
			and cooldown[DE.SoulStrike].ready
			and not talents[DE.SacrificedSouls]
	then
		return DE.SoulStrike
	end

	-- power_siphon,if=!variable.use_bolt_timings&buff.wild_imps.stack>1&buff.demonic_core.stack<3
	if talents[DE.PowerSiphon]
			and cooldown[DE.PowerSiphon].ready
			and wildImps > 1
			and buff[DE.DemonicCoreAura].count < 3
	then
		return DE.PowerSiphon
	end

	-- Spend Demonic Cores for Soul Shards until Tyrant cooldown is close to ready
	-- demonbolt,if=buff.demonic_core.react&soul_shard<4&variable.next_tyrant_cd>20
	if currentSpell ~= DE.Demonbolt
			and buff[DE.DemonicCoreAura].up
			and soulShards < 4
			and nextTyrantCd > 20
	then
		return DE.Demonbolt
	end

	-- During Tyrant setup, spend Demonic Cores for Soul Shards
	-- demonbolt,if=buff.demonic_core.react&soul_shard<4&variable.next_tyrant_cd<12
	if currentSpell ~= DE.Demonbolt
			and buff[DE.DemonicCoreAura].up
			and soulShards < 4
			and nextTyrantCd < 12
	then
		return DE.Demonbolt
	end

	-- demonbolt,if=buff.demonic_core.react&soul_shard<4&(buff.demonic_core.stack>2|talent.sacrificed_souls.enabled)
	if currentSpell ~= DE.Demonbolt
			and buff[DE.DemonicCoreAura].up
			and soulShards < 4
			and ( buff[DE.DemonicCoreAura].count > 2 or talents[DE.SacrificedSouls] )
	then
		return DE.Demonbolt
	end

	-- demonbolt,if=buff.demonic_core.react&soul_shard<4&active_enemies>1
	if currentSpell ~= DE.Demonbolt
			and buff[DE.DemonicCoreAura].up
			and soulShards < 4
			and targets > 1
	then
		return DE.Demonbolt
	end

	-- soul_strike
	if talents[DE.SoulStrike] and cooldown[DE.SoulStrike].ready then
		return DE.SoulStrike
	end

	local castTimeShadowBolt = GetCastTime(DE.ShadowBolt)
	local castTimeHandOfGuldan = GetCastTime(DE.HandOfGuldan)

	-- If you can get back to 5 Soul Shards before Dreadstalkers cooldown is ready, it's okay to spend them now
	-- hand_of_guldan,if=soul_shard>=3&variable.next_tyrant_cd>25&(talent.demonic_calling.enabled|cooldown.call_dreadstalkers.remains>((5-soul_shard)*action.shadow_bolt.execute_time)+action.hand_of_guldan.execute_time)
	if soulShards >= 3
			and currentSpell ~= DE.HandOfGuldan
			and (
				nextTyrantCd > 25
				and ( talents[DE.DemonicCalling] or not talents[DE.CallDreadstalkers] or cooldown[DE.CallDreadstalkers].remains > ( ( 5 - soulShards ) * castTimeShadowBolt ) + castTimeHandOfGuldan )
			)
	then
		return DE.HandOfGuldan
	end

	return DE.ShadowBolt
end

function Warlock:DemonologyOpener()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local currentSpell = fd.currentSpell
	local talents = fd.talents
	local soulShards = UnitPower('player', Enum.PowerType.SoulShards)

	-- nether_portal
	if talents[DE.NetherPortal] and cooldown[DE.NetherPortal].ready and soulShards >= 1 and currentSpell ~= DE.NetherPortal then
		return DE.NetherPortal
	end

	-- grimoire_felguard
	if talents[DE.GrimoireFelguard] and cooldown[DE.GrimoireFelguard].ready and soulShards >= 1 then
		return DE.GrimoireFelguard
	end

	-- summon_vilefiend
	if talents[DE.SummonVilefiend] and cooldown[DE.SummonVilefiend].ready and soulShards >= 1 and currentSpell ~= DE.SummonVilefiend then
		return DE.SummonVilefiend
	end

	-- shadow_bolt,if=soul_shard<5&cooldown.call_dreadstalkers.up
	if currentSpell ~= DE.ShadowBolt and soulShards < 5 and (not talents[DE.CallDreadstalkers] or cooldown[DE.CallDreadstalkers].ready) then
		return DE.ShadowBolt
	end

	-- call_dreadstalkers
	if talents[DE.CallDreadstalkers] and cooldown[DE.CallDreadstalkers].ready and soulShards >= 2 and currentSpell ~= DE.CallDreadstalkers then
		return DE.CallDreadstalkers
	end
end

function Warlock:DemonologyTyrantSetup()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local currentSpell = fd.currentSpell
	local talents = fd.talents
	local soulShards = fd.soulShards
	local pets = fd.pets

	local dreadstalkerActive = pets.Dreadstalker > 0
	local dreadstalkerRemains = pets.Dreadstalker
	if dreadstalkerRemains < 0 then dreadstalkerRemains = 0 end

	local vilefiendActive = pets.Vilefiend > 0
	local vilefiendRemains = pets.Vilefiend
	if vilefiendRemains < 0 then vilefiendRemains = 0 end

	-- nether_portal,if=variable.next_tyrant_cd<15
	if talents[DE.NetherPortal]
			and cooldown[DE.NetherPortal].ready
			and soulShards >= 1
			and currentSpell ~= DE.NetherPortal
			and (nextTyrantCd < 15)
	then
		return DE.NetherPortal
	end

	local castTimeTyrant = (talents[DE.SummonDemonicTyrant] and 1 or 0) * GetCastTime(DE.SummonDemonicTyrant)
	local castTimeShadowBolt = GetCastTime(DE.ShadowBolt)
	local castTimeVilefiend = (talents[DE.SummonVilefiend] and 1 or 0) * GetCastTime(DE.SummonVilefiend)

	-- grimoire_felguard,if=variable.next_tyrant_cd<17-(action.summon_demonic_tyrant.execute_time+action.shadow_bolt.execute_time)&(cooldown.call_dreadstalkers.remains<17-(action.summon_demonic_tyrant.execute_time+action.summon_vilefiend.execute_time+action.shadow_bolt.execute_time)|pet.dreadstalker.remains>variable.next_tyrant_cd+action.summon_demonic_tyrant.execute_time)
	if talents[DE.GrimoireFelguard]
			and cooldown[DE.GrimoireFelguard].ready
			and soulShards >= 1
			and nextTyrantCd < 17 - ( castTimeTyrant + castTimeShadowBolt )
			and ( cooldown[DE.CallDreadstalkers].remains < 17 - ( castTimeTyrant + castTimeVilefiend + castTimeShadowBolt ) or dreadstalkerRemains > nextTyrantCd + castTimeTyrant ) then
		return DE.GrimoireFelguard
	end

	-- summon_vilefiend,if=(variable.next_tyrant_cd<15-(action.summon_demonic_tyrant.execute_time)&(cooldown.call_dreadstalkers.remains<15-(action.summon_demonic_tyrant.execute_time+action.summon_vilefiend.execute_time)|pet.dreadstalker.remains>variable.next_tyrant_cd+action.summon_demonic_tyrant.execute_time))|(!runeforge.wilfreds_sigil_of_superior_summoning&variable.next_tyrant_cd>40)
	if talents[DE.SummonVilefiend]
			and cooldown[DE.SummonVilefiend].ready
			and soulShards >= 1
			and currentSpell ~= DE.SummonVilefiend
			and (( nextTyrantCd < 15 - castTimeTyrant and ( cooldown[DE.CallDreadstalkers].remains < 15 - ( castTimeTyrant + castTimeVilefiend ) or dreadstalkerRemains > nextTyrantCd + castTimeTyrant ) ) or nextTyrantCd > 40) then
		return DE.SummonVilefiend
	end

	-- call_dreadstalkers,if=variable.next_tyrant_cd<12-(action.summon_demonic_tyrant.execute_time+action.shadow_bolt.execute_time)
	if talents[DE.CallDreadstalkers]
			and cooldown[DE.CallDreadstalkers].ready
			and soulShards >= 2
			and currentSpell ~= DE.CallDreadstalkers
			and (nextTyrantCd < 12 - ( castTimeTyrant + castTimeShadowBolt )) then
		return DE.CallDreadstalkers
	end

	local grimoireFelguardRemains = cooldown[DE.GrimoireFelguard].remains - 103
	if grimoireFelguardRemains < 0 then grimoireFelguardRemains = 0 end

	-- summon_demonic_tyrant,if=time>variable.first_tyrant_time&(pet.dreadstalker.active&pet.dreadstalker.remains>action.summon_demonic_tyrant.execute_time)&(!talent.summon_vilefiend.enabled|pet.vilefiend.active)&(soul_shard=0|(pet.dreadstalker.active&pet.dreadstalker.remains<action.summon_demonic_tyrant.execute_time+action.shadow_bolt.execute_time)|(pet.vilefiend.active&pet.vilefiend.remains<action.summon_demonic_tyrant.execute_time+action.shadow_bolt.execute_time)|(buff.grimoire_felguard.up&buff.grimoire_felguard.remains<action.summon_demonic_tyrant.execute_time+action.shadow_bolt.execute_time))
	if talents[DE.SummonDemonicTyrant]
			and cooldown[DE.SummonDemonicTyrant].ready
			and currentSpell ~= DE.SummonDemonicTyrant
			and ( not talents[DE.CallDreadstalkers] or (dreadstalkerActive and dreadstalkerRemains > castTimeTyrant ))
			and ( not talents[DE.SummonVilefiend] or pets.Vilefiend > 0 )
			and (
				soulShards == 0
				or not talents[DE.CallDreadstalkers] or (dreadstalkerActive and dreadstalkerRemains < castTimeTyrant + castTimeShadowBolt)
				or not talents[DE.SummonVilefiend] or (vilefiendActive and vilefiendRemains < castTimeTyrant + castTimeShadowBolt)
				or not talents[DE.GrimoireFelguard] or ((not cooldown[DE.GrimoireFelguard].ready and cooldown[DE.GrimoireFelguard].remains < castTimeTyrant + castTimeShadowBolt))
			)
	then
		return DE.SummonDemonicTyrant
	end
end

function Warlock:DemonologyPets()
	local pets = {
		Vilefiend = 0,
		Felguard = 0,
		Dreadstalker = 0
	}

	for index = 1, MAX_TOTEMS do
		local hasTotem, _, startTime, duration, icon = GetTotemInfo(index)
		if hasTotem then
			local totemUnifiedName = TotemIcons[icon]
			if totemUnifiedName then
				local remains = startTime + duration - GetTime()
				pets[totemUnifiedName] = remains
			end
		end
	end

	return pets
end