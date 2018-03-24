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

-- Destruction
local _ShadowBolt = 686;
local _Metamorphosis = 103958;
local _HandOfGuldan = 105174;
local _SoulFire = 104027;
local _Doom = 603;
local _TouchOfChaos = 103964;
local _ChaosWave = 124916
local _DarkSoulKnowledge = 113861;
local _DarkSoulMisery = 113860;
local _DarkSoulInstability = 113858;
local _FireAndBrimstone = 108683;
local _GrimoireDoomguard = 157900;
local _Cataclysm = 152108;
local _Felstorm = 119914;
local _Havoc = 80240;
local _Conflagrate = 17962;
local _Incinerate = 29722;
local _Immolate = 348;
local _ChaosBolt = 116858;
local _Shadowburn = 17877;
local _Soulburn = 74434;
local _Haunt = 48181;
local _SoulSwap = 86121;
local _SummonDoomguard = 18540;
local _DemonicPower = 196099;

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

-- Demonology
local _LordofFlames = 224103;
local _GrimoireImp = 111859;
local _ChannelDemonfire = 196447;
local _Cataclysm = 152108;

-- AURAS
local _MoltenCore = 140074;
local _HauntingSpirits = 157698;

local wasEra = false;
local willBeEra = false;

MaxDps.Warlock = {};

function MaxDps.Warlock.CheckTalents()
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

function MaxDps.Warlock.Affliction(_, timeShift, currentSpell, gcd, talents)
	local ss = UnitPower('player', SPELL_POWER_SOUL_SHARDS);
	local mana = MaxDps:Mana(0, timeShift);
	local uaCount, uaCd = MaxDps.Warlock.UACount(timeShift);

	if talents[_PhantomSingularity] then
		MaxDps:GlowCooldown(_PhantomSingularity, MaxDps:SpellAvailable(_PhantomSingularity, timeShift));
	end

	if mana < 0.2 then
		return _LifeTap;
	end

	if not MaxDps:TargetAura(_Agony, timeShift + 5) then
		return _Agony;
	end

	if talents[_AbsoluteCorruption] then
		local spellName = GetSpellInfo(_Corruption);
		local aura = UnitAura('target', spellName, nil, 'PLAYER|HARMFUL');
		if not aura then
			return _Corruption;
		end
	else
		if not MaxDps:TargetAura(_Corruption, timeShift + 4) then
			return _Corruption;
		end
	end

	if talents[_SiphonLife] and not MaxDps:TargetAura(_SiphonLife, timeShift + 4) then
		return _SiphonLife;
	end

	if ss >= 3 then
		return _UnstableAffliction;
	end

	if MaxDps:PersistentAura(_TormentedSouls) and (not MaxDps:Aura(_DeadwindHarvester, timeShift + 1) and uaCount >= 2) then
		return _ReapSouls;
	end

	return _DrainSoul;
end

function MaxDps.Warlock.Demonology(_, timeShift, currentSpell, gcd, talents)
	local ss = UnitPower('player', SPELL_POWER_SOUL_SHARDS);
	local mana = MaxDps:Mana(0, timeShift);
	local doom = MaxDps:TargetAura(_Doom, timeShift + 5);
	local demoEmp = MaxDps:UnitAura(_DemonicEmpowerment, timeShift + 5, 'pet');
	local doomguard = MaxDps:SpellAvailable(_SummonDoomguard, timeShift);
	local tk = MaxDps:SpellAvailable(_ThalkielsConsumption, timeShift);

	if MaxDps:SameSpell(currentSpell, _CallDreadstalkers) then
		ss = ss - 2;
	elseif MaxDps:SameSpell(currentSpell, _HandOfGuldan) then
		ss = ss - 4;
		if ss < 0 then
			ss = 0;
		end
	end

	if not talents[_GrimoireofSupremacy] then
		MaxDps:GlowCooldown(_SummonDoomguard, doomguard);
	end

	if mana < 0.2 then
		return _LifeTap;
	end

	if not talents[_HandofDoom] and not doom then
		return _Doom;
	end

	if talents[_SummonDarkglare] and MaxDps:SpellAvailable(_SummonDarkglare, timeShift) and ss > 0 then
		return _SummonDarkglare;
	end

	if MaxDps:SpellAvailable(_CallDreadstalkers, timeShift) and ss > 1 and not MaxDps:SameSpell(currentSpell, _CallDreadstalkers) then
		return _CallDreadstalkers;
	end

	if talents[_GrimoireofService] and MaxDps:SpellAvailable(_GrimoireFelguard, timeShift) and ss > 0 then
		return _GrimoireFelguard;
	end

	if ss > 3 and not MaxDps:SameSpell(currentSpell, _HandOfGuldan) then
		return _HandOfGuldan;
	end

	if not demoEmp and not MaxDps:SameSpell(currentSpell, _DemonicEmpowerment) then
		return _DemonicEmpowerment;
	end

	if talents[_SoulHarvest] and MaxDps:SpellAvailable(_SoulHarvest, timeShift) then
		return _SoulHarvest;
	end

	if tk and not MaxDps:SameSpell(currentSpell, _ThalkielsConsumption) then
		return _ThalkielsConsumption;
	end

	if MaxDps:SpellAvailable(_Felstorm, timeShift) then
		return _Felstorm;
	end

	if talents[_Demonbolt] then
		return _Demonbolt;
	else
		return _ShadowBolt;
	end
end

----------------------------------------------
-- Main rotation: Destruction
----------------------------------------------
function MaxDps.Warlock.Destruction(_, timeShift, currentSpell, gcd, talents)
	local ss = UnitPower('player', SPELL_POWER_SOUL_SHARDS);
	local immo = MaxDps:TargetAura(_Immolate, timeShift + 5);
	local health = UnitHealth('target');
	local era = MaxDps:TargetAura(_Eradication, timeShift + 2);
	local mana = MaxDps:Mana(0, timeShift);
	local doomguard = MaxDps:SpellAvailable(_SummonDoomguard, timeShift);
	local targetPh = MaxDps:TargetPercentHealth();

	if wasEra and not era then
		-- eradication went off
		willBeEra = false;
	end
	wasEra = era;

	if MaxDps:SameSpell(currentSpell, _ChaosBolt) then
		willBeEra = true;
		ss = ss - 2;
	end

	MaxDps:GlowCooldown(_GrimoireDoomguard, MaxDps:SpellAvailable(_GrimoireDoomguard, timeShift));
	MaxDps:GlowCooldown(_Havoc, MaxDps:SpellAvailable(_Havoc, timeShift));

	if not talents[_GrimoireofSupremacy] then
		MaxDps:GlowCooldown(_SummonDoomguard, doomguard);
	end

	if talents[_SoulHarvest] then
		MaxDps:GlowCooldown(_SoulHarvest, MaxDps:SpellAvailable(_SoulHarvest, timeShift));
	end

	if talents[_Cataclysm] and cata then
		MaxDps:GlowCooldown(_Cataclysm, MaxDps:SpellAvailable(_Cataclysm, timeShift));
	end

	if mana < 0.1 then
		return _LifeTap;
	end

	local immo1 = MaxDps:TargetAura(_Immolate, timeShift + 1);
	if not immo1 and not MaxDps:SameSpell(currentSpell, _Immolate) then
		return _Immolate;
	end

	if talents[_EmpoweredLifeTap] and not MaxDps:Aura(_EmpoweredLifeTap, timeShift) then
		return _LifeTap;
	end

	if talents[_GrimoireofSacrifice] and MaxDps:SpellAvailable(_GrimoireofSacrifice, timeShift) and
		not MaxDps:Aura(_DemonicPower, timeShift)
	then
		return _GrimoireofSacrifice
	end

	if ss >= 5 then
		return _ChaosBolt;
	end

	if talents[_Eradication] and not era and not willBeEra and ss > 1 and not MaxDps:SameSpell(currentSpell, _ChaosBolt) then
		return _ChaosBolt;
	end

	local drCD, drCharges, drMax = MaxDps:SpellCharges(_DimensionalRift, timeShift);
	if drCharges >= 2 then
		return _DimensionalRift
	end

	if talents[_GrimoireofService] and MaxDps:SpellAvailable(_GrimoireImp, timeShift) then
		return _GrimoireImp;
	end

	if talents[_ChannelDemonfire] and MaxDps:SpellAvailable(_ChannelDemonfire, timeShift) then
		return _ChannelDemonfire;
	end

	if talents[_Shadowburn] then
		local sbCD, sbCharges = MaxDps:SpellCharges(_Shadowburn, timeShift);
		if sbCharges > 1.5 then
			return _Shadowburn;
		end
	else
		local conCD, conCharges, conMax = MaxDps:SpellCharges(_Conflagrate, timeShift);
		if conCharges > 1.5 then
			return _Conflagrate;
		end
	end

	if ss >= 2 then
		return _ChaosBolt;
	end

	if not immo and not MaxDps:SameSpell(currentSpell, _Immolate) then
		return _Immolate;
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