-- NEW SPELLS
local _DimensionalRift = 196586;
local _Eradication = 196412;
local _LifeTap = 1454;
local _SummonDarkglare = 205180;
local _CallDreadstalkers = 104316;
local _GrimoireFelguard = 111898;
local _DemonicEmpowerment = 193396;
local _ThalkielsConsumption = 211714;
local _Demonbolt = 157695;
local _HandofDoom = 152107;

local _GrimoireofService = 108501;
local _GrimoireofSupremacy = 152107;
local _GrimoireofSacrifice = 108503;



-- SPELLS
local _ShadowBolt			= 686;
local _Metamorphosis		= 103958;
local _HandOfGuldan			= 105174;
local _SoulFire				= 104027;
local _Doom					= 603;
local _TouchOfChaos			= 103964;
local _ChaosWave			= 124916
local _DarkSoulKnowledge	= 113861;
local _DarkSoulMisery		= 113860;
local _DarkSoulInstability	= 113858;
local _FireAndBrimstone		= 108683;
local _GrimoireDoomguard	= 157900;
local _Cataclysm			= 152108;
local _Felstorm				= 119914;
local _Havoc				= 80240;
local _Conflagrate			= 17962;
local _Incinerate			= 29722;
local _Immolate				= 348;
local _ChaosBolt			= 116858;
local _Shadowburn			= 17877;
local _Soulburn				= 74434;
local _Haunt				= 48181;
local _SoulSwap				= 86121;
local _SummonDoomguard		= 18540;

-- Affliction
local _Agony = 980;
local _Corruption = 172;
local _SiphonLife = 63106;
local _UnstableAffliction = 30108;
local _SoulConduit = 215941;
local _ReapSouls = 216698;
local _DrainSoul = 198590;
local _SoulEffigy = 205178;
local _SeedofCorruption = 27243;
local _SoulHarvest = 196098;
local _WrathofConsumption = 199472;
local _CompoundingHorror = 199282;
local _Contagion = 196105;
local _AbsoluteCorruption = 196103;
local _EmpoweredLifeTap = 235157;
local _SummonFelhunter = 691;
local _DemonicCircle = 48018;
local _DarkPact = 108416;
local _UnendingResolve = 104773;
local _SummonInfernal = 1122;
local _PhantomSingularity = 205179;
local _DeadwindHarvester = 216708;
local _TormentedSouls = 216695;

-- AURAS
local _MoltenCore = 140074;
local _HauntingSpirits = 157698;

local isCataclysm = false;
local isGrimoireOfService = false;
local isDemonbolt = false;
local isSupremacy = false;
local isShadowburn = false;
local isEradication = false;
local isSummonDarkglare = false;
local isSoulHarvest = false;
local isHandofDoom = false;
local isSiphonLife = false;
local isPhantomSingularity = false;

local wasEra = false;
local willBeEra = false;

MaxDps.Warlock = {};

function MaxDps.Warlock.CheckTalents()
	MaxDps:CheckTalents();
	isCataclysm = MaxDps:HasTalent(_Cataclysm);
	isDemonbolt = MaxDps:HasTalent(_Demonbolt);
	isGrimoireOfService = MaxDps:HasTalent(_GrimoireofService);
	isSummonDarkglare = MaxDps:HasTalent(_SummonDarkglare);
	isSupremacy = MaxDps:HasTalent(_GrimoireofSupremacy);
	isShadowburn = MaxDps:HasTalent(_Shadowburn);
	isEradication = MaxDps:HasTalent(_Eradication);
	isHandofDoom = MaxDps:HasTalent(_HandofDoom);
	isSoulHarvest = MaxDps:HasTalent(_SoulHarvest);
	isSoulHarvest = MaxDps:HasTalent(_SoulHarvest);
	isSiphonLife = MaxDps:HasTalent(_SiphonLife);
	isPhantomSingularity = MaxDps:HasTalent(_PhantomSingularity);
end

function MaxDps:EnableRotationModule(mode)
	mode = mode or 1;
	MaxDps.Description = 'Warlock Module [Affliction, Demonology, Destruction]';
	MaxDps.ModuleOnEnable = MaxDps.Warlock.CheckTalents;
	if mode == 1 then
		MaxDps.NextSpell = MaxDps.Warlock.Affliction
	end;
	if mode == 2 then
		MaxDps.NextSpell = MaxDps.Warlock.Demonology
	end;
	if mode == 3 then
		MaxDps.NextSpell = MaxDps.Warlock.Destruction
	end;
end

function MaxDps.Warlock.Affliction()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local ss = UnitPower('player', SPELL_POWER_SOUL_SHARDS);
	local mana = MaxDps:Mana(0, timeShift);

	local uaCount, uaCd = MaxDps.Warlock.UACount(timeShift);

	MaxDps:GlowCooldown(_PhantomSingularity, isPhantomSingularity and MaxDps:SpellAvailable(_PhantomSingularity, timeShift));

	if mana < 0.2 then
		return _LifeTap;
	end

	if not MaxDps:TargetAura(_Agony, timeShift + 5) then
		return _Agony;
	end

	if not MaxDps:TargetAura(_Corruption, timeShift + 4) then
		return _Corruption;
	end

	if isSiphonLife and not MaxDps:TargetAura(_SiphonLife, timeShift + 4) then
		return _SiphonLife;
	end

	if ss >= 3 then
		return _UnstableAffliction;
	end

	if MaxDps:PersistentAura(_TormentedSouls) and (not MaxDps:Aura(_DeadwindHarvester,
		timeShift + 1) and uaCount >= 2) then
		return _ReapSouls;
	end

	return _DrainSoul;
end

function MaxDps.Warlock.Demonology()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local ss = UnitPower('player', SPELL_POWER_SOUL_SHARDS);
	local mana = MaxDps:Mana(0, timeShift);

	local doom = MaxDps:TargetAura(_Doom, timeShift + 5);
	local demoEmp = MaxDps:UnitAura(_DemonicEmpowerment, timeShift + 5, 'pet');

	local sdk = MaxDps:SpellAvailable(_SummonDarkglare, timeShift);
	local callD = MaxDps:SpellAvailable(_CallDreadstalkers, timeShift);
	local felg = MaxDps:SpellAvailable(_GrimoireFelguard, timeShift);
	local harv = MaxDps:SpellAvailable(_SoulHarvest, timeShift);
	local doomguard = MaxDps:SpellAvailable(_SummonDoomguard, timeShift);
	local tk = MaxDps:SpellAvailable(_ThalkielsConsumption, timeShift);
	local felstorm = MaxDps:SpellAvailable(_Felstorm, timeShift);

	if MaxDps:SameSpell(currentSpell, _CallDreadstalkers) then
		ss = ss - 2;
	elseif MaxDps:SameSpell(currentSpell, _HandOfGuldan) then
		ss = ss - 4;
		if ss < 0 then
			ss = 0;
		end
	end

	if not isSupremacy then
		MaxDps:GlowCooldown(_SummonDoomguard, doomguard);
	end

	if mana < 0.2 then
		return _LifeTap;
	end

	if not isHandofDoom and not doom then
		return _Doom;
	end

	if isSummonDarkglare and sdk and ss > 0 then
		return _SummonDarkglare;
	end

	if callD and ss > 1 and not MaxDps:SameSpell(currentSpell, _CallDreadstalkers) then
		return _CallDreadstalkers;
	end

	if isGrimoireOfService and felg and ss > 0 then
		return _GrimoireFelguard;
	end

	if ss > 3 and not MaxDps:SameSpell(currentSpell, _HandOfGuldan) then
		return _HandOfGuldan;
	end

	if not demoEmp and not MaxDps:SameSpell(currentSpell, _DemonicEmpowerment) then
		return _DemonicEmpowerment;
	end

	if isSoulHarvest and harv then
		return _SoulHarvest;
	end

	if tk and not MaxDps:SameSpell(currentSpell, _ThalkielsConsumption) then
		return _ThalkielsConsumption;
	end

	if felstorm then
		return _Felstorm;
	end

	if isDemonbolt then
		return _Demonbolt;
	else
		return _ShadowBolt;
	end
end

----------------------------------------------
-- Main rotation: Destruction
----------------------------------------------
function MaxDps.Warlock.Destruction()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local ss = UnitPower('player', SPELL_POWER_SOUL_SHARDS);

	local drCD, drCharges, drMax = MaxDps:SpellCharges(_DimensionalRift, timeShift);
	local conCD, conCharges, conMax = MaxDps:SpellCharges(_Conflagrate, timeShift);

	local immo = MaxDps:TargetAura(_Immolate, timeShift + 5);
	local immo1 = MaxDps:TargetAura(_Immolate, timeShift + 1);
	local health = UnitHealth('target');

	local era = MaxDps:TargetAura(_Eradication, timeShift + 2);
	if wasEra and not era then
		-- eradication went off
		willBeEra = false;
	end
	wasEra = era;

	local mana = MaxDps:Mana(0, timeShift);

	local gd = MaxDps:SpellAvailable(_GrimoireDoomguard, timeShift);
	local doomguard = MaxDps:SpellAvailable(_SummonDoomguard, timeShift);
	local havoc = MaxDps:SpellAvailable(_Havoc, timeShift);

	local targetPh = MaxDps:TargetPercentHealth();
	local cata = MaxDps:SpellAvailable(_Cataclysm, timeShift);

	if not isSupremacy then
		MaxDps:GlowCooldown(_SummonDoomguard, doomguard);
	end

	if MaxDps:SameSpell(currentSpell, _ChaosBolt) then
		willBeEra = true;
		ss = ss - 2;
	end

	MaxDps:GlowCooldown(_GrimoireDoomguard, gd);
	MaxDps:GlowCooldown(_Havoc, havoc);

	if mana < 0.1 then
		return _LifeTap;
	end

	if not immo1 and not MaxDps:SameSpell(currentSpell, _Immolate) then
		return _Immolate;
	end

	if ss >= 5 then
		return _ChaosBolt;
	end

	if not immo and not MaxDps:SameSpell(currentSpell, _Immolate) then
		return _Immolate;
	end

	if drCharges >= 2 then
		return _DimensionalRift
	end

	if ss >= 3 then
		return _ChaosBolt;
	end

	if isShadowburn and health < 500000 and ss > 0 then
		return _Shadowburn;
	end

	if conCharges > 1 or (conCharges >= 1 and conCD < 2) then
		return _Conflagrate;
	end

	if isEradication and not era and not willBeEra and ss > 1 and not MaxDps:SameSpell(currentSpell, _ChaosBolt) then
		return _ChaosBolt;
	end

	return _Incinerate;
end

function MaxDps.Warlock.UACount(timeShift)
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