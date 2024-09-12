﻿local addonName, addonTable = ...
_G[addonName] = addonTable

--- @type MaxDps
if not MaxDps then return end

local Warlock = MaxDps:NewModule('Warlock', 'AceEvent-3.0')
addonTable.Warlock = Warlock

local MaxDps = MaxDps

Warlock.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!')
	end
}

function Warlock:Enable()
	if MaxDps.Spec == 1 then
		MaxDps:Print(MaxDps.Colors.Info .. 'Warlock Affliction', "info")
		MaxDps.NextSpell = Warlock.Affliction
	elseif MaxDps.Spec == 2 then
		MaxDps:Print(MaxDps.Colors.Info .. 'Warlock Demonology', "info")
		MaxDps.NextSpell = Warlock.Demonology
		--self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', 'CLEU')
	elseif MaxDps.Spec == 3 then
		MaxDps:Print(MaxDps.Colors.Info .. 'Warlock Destruction', "info")
		MaxDps.NextSpell = Warlock.Destruction
	end

	Warlock.playerLevel = UnitLevel('player')
	return true
end

function Warlock:Disable()
	self:UnregisterAllEvents()
end