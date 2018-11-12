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
	local cooldown, buff, debuff, talents, azerite, currentSpell =
		fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell;

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

function Warlock:Demonology()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell =
		fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell;

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

	if SoulShards < 0 then SoulShards = 0; end

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
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
		fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell;

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
	if debuff[WD.ImmolateAura].refreshable and currentSpell ~= WD.Immolate and currentSpell ~= WD.Cataclysm	then
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

function Warlock:UACount(timeShift)
	local name = WA.UnstableAffliction;
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