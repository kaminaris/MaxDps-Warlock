-- Author      : Kaminari
-- Create Date : 10/27/2014 6:47:46 PM

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

local wasEra = false;
local willBeEra = false;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Warlock_CheckTalents = function()
	isCataclysm = TD_TalentEnabled('Cataclysm');
	isDemonbolt = TD_TalentEnabled('Demonbolt');
	isGrimoireOfService = TD_TalentEnabled('Grimoire of Service');
	isSoulburnHaunt = TD_TalentEnabled('Soulburn: Haunt');
	isCharredRemains = TD_TalentEnabled('Charred Remains');
	isSummonDarkglare = TD_TalentEnabled('Summon Darkglare');
	isSupremacy = TD_TalentEnabled('Grimoire of Supremacy');
	isShadowburn = TD_TalentEnabled('Shadowburn');
	isEradication = TD_TalentEnabled('Eradication');
	isSoulHarvest = TD_TalentEnabled('Soul Harvest');
end

----------------------------------------------
-- Enabling Addon
----------------------------------------------
function TDDps_Warlock_EnableAddon(mode)
	mode = mode or 1;
	_TD['DPS_Description'] = 'TD Warlock DPS supports: Affliction, Demonology, Destruction';
	_TD['DPS_OnEnable'] = TDDps_Warlock_CheckTalents;
	if mode == 1 then
		_TD['DPS_NextSpell'] = TDDps_Warlock_Affliction
	end;
	if mode == 2 then
		_TD['DPS_NextSpell'] = TDDps_Warlock_Demonology
	end;
	if mode == 3 then
		_TD['DPS_NextSpell'] = TDDps_Warlock_Destruction
	end;
	TDDps_EnableAddon();
end

----------------------------------------------
-- Main rotation: Affliction
----------------------------------------------
TDDps_Warlock_Affliction = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	return _DrainSoul;
end

----------------------------------------------
-- Main rotation: Demonology
----------------------------------------------
TDDps_Warlock_Demonology = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	local ss = UnitPower('player', SPELL_POWER_SOUL_SHARDS);
	local mana = TD_Mana(0, timeShift)

	local doom = TD_TargetAura(_Doom, timeShift + 5);
	local demoEmp = TD_UnitAura(_DemonicEmpowerment, timeShift + 5, 'pet');

	local sdk = TD_SpellAvailable(_SummonDarkglare, timeShift);
	local callD = TD_SpellAvailable(_CallDreadstalkers, timeShift);
	local felg = TD_SpellAvailable(_GrimoireFelguard, timeShift);
	local harv = TD_SpellAvailable(_SoulHarvest, timeShift);
	local doomguard = TD_SpellAvailable(_SummonDoomguard, timeShift);
	local tk = TD_SpellAvailable(_ThalkielsConsumption, timeShift);
	local felstorm = TD_SpellAvailable(_Felstorm, timeShift);

	if currentSpell == 'Call Dreadstalkers' then
		ss = ss - 2;
	elseif currentSpell == 'Hand of Gul\'dan' then
		ss = ss - 4;
		if ss < 0 then
			ss = 0;
		end
	end

	if not isSupremacy then
		TDButton_GlowCooldown(_SummonDoomguard, doomguard);
	end

	if mana < 0.2 then
		return _LifeTap;
	end

	if not doom then
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
TDDps_Warlock_Destruction = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	local ss = UnitPower('player', SPELL_POWER_SOUL_SHARDS);

	local drCD, drCharges, drMax = TD_SpellCharges(_DimensionalRift, timeShift);
	local conCD, conCharges, conMax = TD_SpellCharges(_Conflagrate, timeShift);

	local immo = TD_TargetAura(_Immolate, timeShift + 5);
	local immo1 = TD_TargetAura(_Immolate, timeShift + 1);
	local health = UnitHealth('target');

	local era = TD_TargetAura(_Eradication, timeShift + 2);
	if wasEra and not era then
		-- eradication went off
		willBeEra = false;
	end
	wasEra = era;

	local mana = TD_Mana(0, timeShift);

	local gd = TD_SpellAvailable(_GrimoireDoomguard, timeShift);
	local doomguard = TD_SpellAvailable(_SummonDoomguard, timeShift);
	local havoc = TD_SpellAvailable(_Havoc, timeShift);

	local targetPh = TD_TargetPercentHealth();
	local cata = TD_SpellAvailable(_Cataclysm, timeShift);

	if not isSupremacy then
		TDButton_GlowCooldown(_SummonDoomguard, doomguard);
	end

	if currentSpell == 'Chaos Bolt' then
		willBeEra = true;
		ss = ss - 2;
	end

	TDButton_GlowCooldown(_GrimoireDoomguard, gd);
	TDButton_GlowCooldown(_Havoc, havoc);

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

	if drCharges > 2 then
		return _DimensionalRift
	end

	if ss >= 4 then
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

----------------------------------------------
-- Molten Core stacks
----------------------------------------------
function TDDps_Warlock_MoltenCore()
	local _, _, _, count, _, _, expirationTime = UnitAura('player', 'Molten Core'); 
	if expirationTime ~= nil and (expirationTime - GetTime()) > 0.2 then
		return count;
	end
	return 0;
end

----------------------------------------------
-- Is in Metamorphosis
----------------------------------------------
function TDDps_Warlock_Metamorphosis()
	local is = UnitAura('player', 'Metamorphosis');
	return is == 'Metamorphosis';
end