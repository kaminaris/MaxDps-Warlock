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

-- AURAS
local _MoltenCore = 140074;

local isCataclysm = false;
local isGrimoireOfService = false;
local isDemonbolt = false;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Warlock_CheckTalents = function()
	isCataclysm = TDTalentEnabled('Cataclysm');
	isDemonbolt = TDTalentEnabled('Demonbolt');
	isGrimoireOfService = TDTalentEnabled('Grimoire of Service');
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

	local timeShift, casting = TDEndCast();

	local meta = TDDps_Warlock_Metamorphosis();
	local fury = UnitPower('player', 15);
	local corruption = TDTargetAura(_Corruption, timeShift + 4);
	local dsCD, dsCharges, dsMax = TDDps_SpellCharges(_DarkSoul);
	local moltenCore = TDDps_Warlock_MoltenCore();
	local targetPh = TD_TargetPercentHealth();
	local doom = TDTargetAura('Doom', timeShift + 18);
	local hogCD, hogCharges, hogMax = TDDps_SpellCharges(_HandOfGuldan);

	if casting == 'Soul Fire' and moltenCore > 0 then
		moltenCore = moltenCore - 1;
	end

	if meta then
	
		if fury <= 40 then
			return _Metamorphosis;
		end
		
		if fury < 100 and fury >= 60 then
			return _Corruption; -- same slot as Doom
		end
	
		if not TDTargetAura(_Corruption, timeShift + 8) then
			return _ShadowBolt; -- same slot as Touch of Chaos 
		end
		
		if isCataclysm and TDDps_SpellCooldown(_Cataclysm, timeShift) then
			return _Cataclysm;
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
		local hogDot = TDTargetAura(_HandOfGuldan, 3);
		
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



