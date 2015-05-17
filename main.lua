-- Author      : Kaminari
-- Create Date : 10/27/2014 6:47:46 PM

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
local _GrimoireDoomguard	= 157900;
local _Cataclysm			= 152108;
local _DarkSoul				= 113861;
local _Felstorm				= 119914;

-- AURAS
local _MoltenCore = 140074;

local isCataclysm = false;
local isGrimoireOfService = false;
local isDemonbolt = false;

-- Flags

local _FlagCata = false;
local _FlagDs = false;
local _FlagGd = false;
local _FlagFelstorm = false;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Warlock_CheckTalents = function()
	isCataclysm = TD_TalentEnabled('Cataclysm');
	isDemonbolt = TD_TalentEnabled('Demonbolt');
	isGrimoireOfService = TD_TalentEnabled('Grimoire of Service');
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
-- Main rotation: Demonology
----------------------------------------------
TDDps_Warlock_Demonology = function()

	local lcd, casting, gcd = TD_EndCast();
	local timeShift = gcd + lcd;
	
	local meta = TDDps_Warlock_Metamorphosis();
	local fury = UnitPower('player', 15);
	local corruption = TD_TargetAura(_Corruption, timeShift + 4);
	local dsCD, dsCharges, dsMax = TD_SpellCharges(_DarkSoul);
	local gd = TD_SpellAvailable(_GrimoireDoomguard, timeShift);
	local felstorm = TD_SpellAvailable(_Felstorm);
	local moltenCore = TDDps_Warlock_MoltenCore();
	local targetPh = TD_TargetPercentHealth();
	local doom = TD_TargetAura('Doom', timeShift + 18);
	local hogCD, hogCharges, hogMax = TD_SpellCharges(_HandOfGuldan);
	local cata = TD_SpellAvailable(_Cataclysm, timeShift);
	if casting == 'Soul Fire' and moltenCore > 0 then
		moltenCore = moltenCore - 1;
	end

	if isCataclysm then
		if cata and not _FlagCata then
			_FlagCata = true;
			TDButton_GlowIndependent(_Cataclysm, 'cata', 0, 1, 0);
		end
		if not cata and _FlagCata then
			_FlagCata = false;
			TDButton_ClearGlowIndependent(_Cataclysm, 'cata');
		end
	end

	if gd and not _FlagGd then
		_FlagGd = true;
		TDButton_GlowIndependent(_GrimoireDoomguard, 'gd', 0, 1, 0);
	end
	if not gd and _FlagGd then
		_FlagGd = false;
		TDButton_ClearGlowIndependent(_GrimoireDoomguard, 'gd');
	end

	if felstorm and not _FlagFelstorm then
		_FlagFelstorm = true;
		TDButton_GlowIndependent(_Felstorm, 'fs', 0, 1, 0);
	end
	if not felstorm and _FlagFelstorm then
		_FlagFelstorm = false;
		TDButton_ClearGlowIndependent(_Felstorm, 'fs');
	end

	if dsCharges > 0 and not _FlagDs then
		_FlagDs = true;
		TDButton_GlowIndependent(_DarkSoulKnowledge, 'ds', 0, 1, 0);
	end
	if dsCharges <= 0 and _FlagDs then
		_FlagDs = false;
		TDButton_ClearGlowIndependent(_DarkSoulKnowledge, 'ds');
	end

	if meta then
	
		if fury <= 40 then
			return _Metamorphosis;
		end
		
		if fury < 100 and fury >= 60 then
			return _Corruption; -- same slot as Doom
		end
	
		if not TD_TargetAura(_Corruption, timeShift + 8) then
			return _ShadowBolt; -- same slot as Touch of Chaos 
		end
		
		if not doom then
			return _Corruption; -- same slot as Doom
		end
		
		if hogCharges >= hogMax then
			return _HandOfGuldan;
		end
		
		if hogCharges >= (hogMax - 1) and hogCD < 6 + timeShift then
			return _HandOfGuldan;
		end
		
		if moltenCore > 0 then
			return _SoulFire;
		end
	else
		-- Not in metamorphosis
		local hogDot = TD_TargetAura(_HandOfGuldan, 3);
		
		if not corruption then
			return _Corruption;
		end
		
		if hogCharges >= hogMax then
			return _HandOfGuldan;
		end
		
		if hogCharges >= (hogMax - 1) and hogCD < 6 + timeShift then
			return _HandOfGuldan;
		end
		
		if fury >= 200 and not doom then
			return _Metamorphosis;
		end
		
		if moltenCore > 8 then
			return _SoulFire;
		end
		
		if moltenCore > 0 and targetPh < 0.25 then
			return _SoulFire;
		end
		
		if fury > 850 then
			return _Metamorphosis;
		end
		
	end
	
	return _ShadowBolt;
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



