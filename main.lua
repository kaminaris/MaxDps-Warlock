--- @type MaxDps
if not MaxDps then
	return ;
end

local Warlock = MaxDps:NewModule('Warlock', 'AceEvent-3.0');

-- Shared SPELLS
local _BloodPact = 6307;
local _SingeMagic = 89808;
local _DemonicGateway = 111771;
local _DemonicCircle = 268358;
-- Affliction
local _Agony = 980;
local _Corruption = 172;
local _CorruptionAura = 146739;
local _UnstableAffliction = 30108;
local _UnstableAfflictionAura = 233490;
local _Deathbolt = 264106;
local _SummonDarkglare = 205180;
local _VileTaint = 278350;
local _ShadowBolt = 232670;
local _PhantomSingularity = 205179;
local _SeedofCorruption = 27243;
local _SiphonLife = 63106;
local _Nightfall = 108558;
-- Affliction talents
local _AbsoluteCorruption = 196103;
local _DrainSoul = 198590;
local _Haunt = 48181;
local _DarkSoulMisery = 113860;



-- Destruction maybe some wrong talents just copied from Icy Veins
local _Immolate = 348;
local _ImmolateAura = 157736;
local _ChaosBolt = 116858;
local _Conflagrate = 17962;
local _ChannelDemonfire = 196447;
local _Eradication = 196412;
local _Cataclysm = 152108;
local _Incinerate = 29722;
local _SummonInfernal = 1122;
local _DarkSoulInstability = 113858;
local _RainofFire = 5740;
local _Havoc = 80240;
local _Shadowburn = 17877;
local _Backdraft = 117828;
local _FireandBrimstone = 196408;
local _SummonImp = 688;
local _SummonVoidwalker = 697;
local _SummonSuccubus = 712;
local _SummonFelhunter = 691;
local _Soulfire = 6353;

--Demonology maybe some wrong talents just copied from Icy Veins
local _DemonicCore = 264178;
local _DemonicCoreAura = 264173;
local _CallDreadstalkers = 104316;
local _GrimoireFelguard = 111898;
local _DemonicStrength = 267171;
local _SummonVilefiend = 264119;
local _SummonDemonicTyrant = 265187;
local _HandofGuldan = 105174;
local _Demonbolt = 264178;
local _PowerSiphon = 264130;
local _ShadowBoltDemonology = 686;
local _NetherPortal = 267217;
local _NetherPortalAura = 267218;
local _Implosion = 196277;
local _SoulStrike = 264057;
local _BilescourgeBombers = 267211;
local _CommandDemon = 119898;
local _AxeToss = 89766;
local _Felstorm = 89751;
local _LegionStrike = 30213;
local _ThreateningPresence = 134477;
local _SummonFelguard = 30146;


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

function Warlock:Affliction(timeShift, currentSpell, gcd, talents)
	local SoulShards = UnitPower('player', Enum.PowerType.SoulShards);
	local THP = MaxDps:TargetPercentHealth();

	if currentSpell == _UnstableAffliction then
		SoulShards = SoulShards - 1;
	end

	-- Cooldowns
	MaxDps:GlowCooldown(_SummonDarkglare, MaxDps:SpellAvailable(_SummonDarkglare, timeShift));

	if talents[_DarkSoulMisery] then
		MaxDps:GlowCooldown(_DarkSoulMisery, MaxDps:SpellAvailable(_DarkSoulMisery, timeShift));
	end

	--Rotation
	--1. Cast Agony if not Applied or is about to run out
	if not MaxDps:TargetAura(_Agony, timeShift + 5) then
		return _Agony;
	end

	--2. Cast Corruption if not Applied or is about to run out
	if not MaxDps:TargetAura(_CorruptionAura, timeShift + 4) then
		return _Corruption;
	end


	--3. Apply SiphonLife if not Applied or is about to run out
	if talents[_SiphonLife] and not MaxDps:TargetAura(_SiphonLife, timeShift + 4) then
		return _SiphonLife;
	end

	--4. Cast Drain Soul if Talented and Target Health <= 20%
	if talents[_DrainSoul] and THP <= 0.2 then
		return _DrainSoul;
	end

	--5. Keep Haunted on Target if Talented
	if talents[_Haunt] and MaxDps:SpellAvailable(_Haunt, timeShift) and currentSpell ~= _Haunt then
		return _Haunt;
	end

	--6. Cast Unstable Affliction with 4 - 5 Shards
	if SoulShards >= 4 and currentSpell ~= _UnstableAffliction then
		return _UnstableAffliction;
	end

	--7. Cast Deathbolt if all three debuffs are fresh aplied
	if Warlock:TargetAuraLeft(_Agony) > 11 and
		Warlock:TargetAuraLeft(_CorruptionAura) > 9 and
		Warlock:TargetAuraLeft(_UnstableAfflictionAura) > 3 and
		MaxDps:SpellAvailable(_Deathbolt, timeShift) then
		return _Deathbolt;
	end

	--8 Cast Vile Taint or Phantom Singularity if talented
	if talents[_VileTaint] and MaxDps:SpellAvailable(_VileTaint, timeShift)
		and SoulShards >= 1 and currentSpell ~= _VileTaint then
		return _VileTaint;
	end

	if talents[_PhantomSingularity] and MaxDps:SpellAvailable(_PhantomSingularity, timeShift) then
		return _PhantomSingularity;
	end

	-- 9. Remain 1 Unstable Afflicton on target
	if SoulShards >= 1 and not MaxDps:TargetAura(_UnstableAfflictionAura, timeShift + 2)
		and currentSpell ~= _UnstableAffliction then
		return _UnstableAffliction;
	end

	if talents[_DrainSoul] then
		return _DrainSoul;
	else
		return _ShadowBolt;
	end
end

function Warlock:TargetAuraLeft(Aura, timeShift)
	local hasAura, Stacks, TimeLeft = MaxDps:TargetAura(Aura, timeShift);
	return TimeLeft;
end

function Warlock:Demonology(timeShift, currentSpell, gcd, talents)

	local SoulShards = UnitPower('player', Enum.PowerType.SoulShards);

	if currentSpell == _CallDreadstalkers then
		SoulShards = SoulShards - 2;
	elseif currentSpell == _HandofGuldan then
		SoulShards = SoulShards - 3;
	elseif currentSpell == _SummonVilefiend then
		SoulShards = SoulShards - 1;
	elseif currentSpell == _ShadowBoltDemonology then
		SoulShards = SoulShards + 1;
	elseif currentSpell == _Demonbolt then
		SoulShards = SoulShards + 2;
	end

	if SoulShards < 0 then SoulShards = 0; end

	if not UnitExists('pet') then
		return _SummonFelguard;
	end

	--Cooldowns
	MaxDps:GlowCooldown(_SummonDemonicTyrant, MaxDps:SpellAvailable(_SummonDemonicTyrant, timeShift));
	MaxDps:GlowCooldown(_GrimoireFelguard, SoulShards >= 1 and MaxDps:SpellAvailable(_GrimoireFelguard, timeShift));

	if talents[_NetherPortal] then
		MaxDps:GlowCooldown(_NetherPortal, SoulShards >= 3 and MaxDps:SpellAvailable(_NetherPortal, timeShift));
	end


	if MaxDps:SpellAvailable(_CallDreadstalkers, timeShift) and SoulShards >= 3
		and currentSpell ~= _CallDreadstalkers then
		return _CallDreadstalkers;
	end

	if talents[_DemonicStrength] and MaxDps:SpellAvailable(_DemonicStrength, timeShift) then
		return _DemonicStrength;
	end

	if talents[_SummonVilefiend] and MaxDps:SpellAvailable(_SummonVilefiend, timeShift) and SoulShards >= 1
		and currentSpell ~= _SummonVilefiend then
		return _SummonVilefiend;
	end

	if SoulShards >= 4 and currentSpell ~= _HandofGuldan then
		return _HandofGuldan;
	end

	local dc, dcCount = MaxDps:Aura(_DemonicCoreAura, timeShift);
	if dcCount >= 2 then
		return _Demonbolt;
	end

	local ic = Warlock:ImpsCount()
	if talents[_PowerSiphon] and MaxDps:SpellAvailable(_PowerSiphon, timeShift) and ic > 2 then
		return _PowerSiphon;
	end

	if SoulShards >= 3 and currentSpell ~= _HandofGuldan then
		return _HandofGuldan;
	end

	return _ShadowBoltDemonology;
end

----------------------------------------------
-- Main rotation: Destruction
----------------------------------------------
function Warlock:Destruction(timeShift, currentSpell, gcd, talents)
	local SoulShards = UnitPower('player', Enum.PowerType.SoulShards, true) / 10;

	local immo = MaxDps:TargetAura(_Immolate, timeShift + 5);
	local health = UnitHealth('target');
	--local era = MaxDps:TargetAura(_Eradication, timeShift + 2);

	if currentSpell == _ChaosBolt then
		SoulShards = SoulShards - 2;
	end

	--Cooldowns
	MaxDps:GlowCooldown(_Havoc, MaxDps:SpellAvailable(_Havoc, timeShift));
	MaxDps:GlowCooldown(_SummonInfernal, MaxDps:SpellAvailable(_SummonInfernal, timeShift));

	if talents[_DarkSoulInstability] then
		MaxDps:GlowCooldown(_DarkSoulInstability, MaxDps:SpellAvailable(_DarkSoulInstability, timeShift));
	end

	if talents[_Cataclysm] and cata then
		MaxDps:GlowCooldown(_Cataclysm, MaxDps:SpellAvailable(_Cataclysm, timeShift));
	end

	--Rotation Start

	--1. Cast Chaosbolt if Backdraft is active and at least 2 seconds left
	if MaxDps:Aura(_Backdraft, timeShift + 2) and SoulShards >= 2 and currentSpell ~= _ChaosBolt then
		return _ChaosBolt;
	end

	--2. Cast Soulfire on cd if Talented
	if talents[_Soulfire] and MaxDps:SpellAvailable(_Soulfire, timeShift) and currentSpell ~= _Soulfire then
		return _Soulfire;
	end

	--3. Apply or Reapply Immolate
	if not MaxDps:TargetAura(_ImmolateAura, timeShift + 4) and currentSpell ~= _Immolate then
		return _Immolate;
	end

	--4. Cast Chaosbolt if Capped
	if SoulShards >= 4 then
		return _ChaosBolt;
	end

	--5. Cast Conflagrate on CD but keep almost 1 Charge for Burst
	local conCD, conCharges, conMax = MaxDps:SpellCharges(_Conflagrate, timeShift);
	if conCharges > 1.5 then
		return _Conflagrate;
	end

	--6. Cast Demonfire Whenever Possible and Target has Immolate applied for at least 3 seconds
	if talents[_ChannelDemonfire] and MaxDps:SpellAvailable(_ChannelDemonfire, timeShift) and
		MaxDps:TargetAura(_ImmolateAura, timeShift + 3) and currentSpell ~= _ChannelDemonfire then
		return _ChannelDemonfire;
	end

	--7. Cast Shadowburn dont know why cause Talent seems to bee quiet shit...
	if talents[_Shadowburn] and MaxDps:SpellAvailable(_Shadowburn, timeShift) then
		return _Shadowburn;
	end

	return _Incinerate;
end

function Warlock:UACount(timeShift)
	local name = _UnstableAffliction;
	timeShift = timeShift or 0;
	local spellName = GetSpellInfo(name) or name;

	local totalCd = nil;
	local c = 0;
	for i = 1, 40 do
		local uname, _, _, _, _, _, expirationTime = UnitAura('target', i, 'PLAYER|HARMFUL');

		if uname == spellName and expirationTime ~= nil and (expirationTime - GetTime()) > timeShift then
			c = c + 1;
			local cd = expirationTime - GetTime() - (timeShift or 0);
			if (totalCd == nil) or cd < totalCd then
				totalCd = cd;
			end
		end
	end

	return c, totalCd;
end

Warlock.WildImps = {};
function Warlock:CLEU()
	local compTime = GetTime();

	local _, event, _, sourceGuid, sourceName, _, _, destGuid, destName, _, _, spellId, spellName =
	CombatLogGetCurrentEventInfo();


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
		if self.WildImps[index] + 11 > compTime then -- 11 seconds just to be sure they wont die soon
			c = c + 1;
		else
			self.WildImps[index] = nil;
		end
	end

	return c;
end