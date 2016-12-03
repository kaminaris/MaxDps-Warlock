-- NEW SPELLS
local _DimensionalRift = 196586;
local _Eradication = 196412;
local _LifeTap = 1454;
local _SummonDarkglare = 205180;
local _CallDreadstalkers = 104316;
local _GrimoireFelguard = 111898;
local _DemonicEmpowerment = 193396;
local _SoulHarvest = 196098;
local _ThalkielsConsumption = 211714;
local _Demonbolt = 157695;

-- SPELLS
local _Corruption			= 172;
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
local _Agony				= 980;
local _Conflagrate			= 17962;
local _Incinerate			= 29722;
local _Immolate				= 348;
local _ChaosBolt			= 116858;
local _Shadowburn			= 17877;
local _UnstableAffliction	= 30108;
local _Soulburn				= 74434;
local _Haunt				= 48181;
local _DrainSoul			= 103103;
local _SoulSwap				= 86121;
local _SummonDoomguard		= 18540;

-- AURAS
local _MoltenCore = 140074;
local _HauntingSpirits = 157698;

local isCataclysm = false;
local isGrimoireOfService = false;
local isDemonbolt = false;
local isSoulburnHaunt = false;
local isCharredRemains = false;
local isSupremacy = false;
local isShadowburn = false;
local isEradication = false;
local isSummonDarkglare = false;
local isSoulHarvest = false;
local isHandofDoom = false;

local wasEra = false;
local willBeEra = false;

MaxDps.Warlock = {};

function MaxDps.Warlock.CheckTalents()
	isCataclysm = MaxDps:TalentEnabled('Cataclysm');
	isDemonbolt = MaxDps:TalentEnabled('Demonbolt');
	isGrimoireOfService = MaxDps:TalentEnabled('Grimoire of Service');
	isSoulburnHaunt = MaxDps:TalentEnabled('Soulburn: Haunt');
	isCharredRemains = MaxDps:TalentEnabled('Charred Remains');
	isSummonDarkglare = MaxDps:TalentEnabled('Summon Darkglare');
	isSupremacy = MaxDps:TalentEnabled('Grimoire of Supremacy');
	isShadowburn = MaxDps:TalentEnabled('Shadowburn');
	isEradication = MaxDps:TalentEnabled('Eradication');
	isHandofDoom = MaxDps:TalentEnabled('Hand of Doom');
	isSoulHarvest = MaxDps:TalentEnabled('Soul Harvest');
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

	return _DrainSoul;
end

function MaxDps.Warlock.Demonology()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local ss = UnitPower('player', SPELL_POWER_SOUL_SHARDS);
	local mana = MaxDps:Mana(0, timeShift)

	local doom = MaxDps:TargetAura(_Doom, timeShift + 5);
	local demoEmp = MaxDps:UnitAura(_DemonicEmpowerment, timeShift + 5, 'pet');

	local sdk = MaxDps:SpellAvailable(_SummonDarkglare, timeShift);
	local callD = MaxDps:SpellAvailable(_CallDreadstalkers, timeShift);
	local felg = MaxDps:SpellAvailable(_GrimoireFelguard, timeShift);
	local harv = MaxDps:SpellAvailable(_SoulHarvest, timeShift);
	local doomguard = MaxDps:SpellAvailable(_SummonDoomguard, timeShift);
	local tk = MaxDps:SpellAvailable(_ThalkielsConsumption, timeShift);
	local felstorm = MaxDps:SpellAvailable(_Felstorm, timeShift);

	if currentSpell == 'Call Dreadstalkers' then
		ss = ss - 2;
	elseif currentSpell == 'Hand of Gul\'dan' then
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

	if callD and ss > 1 and currentSpell ~= 'Call Dreadstalkers' then
		return _CallDreadstalkers;
	end

	if isGrimoireOfService and felg and ss > 0 then
		return _GrimoireFelguard;
	end

	if ss > 3 and currentSpell ~= 'Hand of Gul\'dan' then
		return _HandOfGuldan;
	end

	if not demoEmp and currentSpell ~= 'Demonic Empowerment' then
		return _DemonicEmpowerment;
	end

	if isSoulHarvest and harv then
		return _SoulHarvest;
	end

	if tk and currentSpell ~= 'Thal\'kiel\'s Consumption' then
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

	if currentSpell == 'Chaos Bolt' then
		willBeEra = true;
		ss = ss - 2;
	end

	MaxDps:GlowCooldown(_GrimoireDoomguard, gd);
	MaxDps:GlowCooldown(_Havoc, havoc);

	if mana < 0.1 then
		return _LifeTap;
	end

	if not immo1 and currentSpell ~= 'Immolate' then
		return _Immolate;
	end

	if ss >= 5 then
		return _ChaosBolt;
	end

	if not immo and currentSpell ~= 'Immolate' then
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

	if conCharges > 1 or (conCharges > 0 and conCD < 2) then
		return _Conflagrate;
	end

	if isEradication and not era and not willBeEra and ss > 1 and currentSpell ~= 'Chaos Bolt' then
		return _ChaosBolt;
	end

	return _Incinerate;
end