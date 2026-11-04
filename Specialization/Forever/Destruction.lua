local _, addonTable = ...
local Warlock = addonTable.Warlock
local MaxDps = _G.MaxDps
if not MaxDps then return end

local GetItemCooldown = C_Item.GetItemCooldown
local usedTrinkets = {}
local aurasSetup = true

local Destruction = {}

function Warlock:Destruction()
    if MaxDps:SmartAoe() <= 1 then
        if (MaxDps.Power("mana") < 10 or MaxDps.Starved()) then MaxDps:GlowDefensiveHPMidnight(1454, true) end --  Life Tap
        if not MaxDps.IsTrackedAuraActive(440892) then return 440892 end --  Curse of the Elements
        if not MaxDps.IsSpellOnCooldown(603, true) then return 603 end --  Bane of Doom
        if not MaxDps.Spells[603] and not MaxDps.IsTrackedAuraActive(980) then return 980 end --  Bane of Agony
        if not MaxDps.IsTrackedAuraActive(172) then return 172 end --  Corruption
        if not MaxDps.IsTrackedAuraActive(348) then return 348 end --  Immolate
        if not MaxDps.IsSpellOnCooldown(1293817, true) then return 1293817 end --  Conflagrate
        if not MaxDps.IsSpellOnCooldown(17877, true) then return 17877 end --  Shadowburn
        if not MaxDps.IsSpellOnCooldown(686, true) then return 686 end --  Shadow Bolt
    end

    if MaxDps:SmartAoe() == 2 then
        if (MaxDps.Power("mana") < 10 or MaxDps.Starved()) then MaxDps:GlowDefensiveHPMidnight(1454, true) end -- Life Tap
        if not MaxDps.IsTrackedAuraActive(440892) then return 440892 end -- Curse of the Elements
        if not MaxDps.IsSpellOnCooldown(603, true) then return 603 end -- Bane of Doom
        if not MaxDps.Spells[603] and not MaxDps.IsTrackedAuraActive(980) then return 980 end -- Bane of Agony
        if not MaxDps.IsTrackedAuraActive(172) then return 172 end -- Corruption
        if not MaxDps.IsTrackedAuraActive(348) then return 348 end -- Immolate
        if not MaxDps.IsSpellOnCooldown(1293817, true) then return 1293817 end -- Conflagrate
        if not MaxDps.IsSpellOnCooldown(17877, true) then return 17877 end -- Shadowburn
        if not MaxDps.IsSpellOnCooldown(686, true) then return 686 end -- Shadow Bolt
    end

    if MaxDps:SmartAoe() > 2 then
        if (MaxDps.Power("mana") < 10 or MaxDps.Starved()) then MaxDps:GlowDefensiveHPMidnight(1454, true) end --  Life Tap
        if MaxDps.Near(10) then MaxDps:GlowDefensiveHPMidnight(1949, true) end --  Hellfire
        if not MaxDps.IsTrackedAuraActive(440892) then return 440892 end --  Curse of the Elements
        if not MaxDps.IsSpellOnCooldown(603, true) then return 603 end --  Bane of Doom
        if not MaxDps.Spells[603] and not MaxDps.IsTrackedAuraActive(980) then return 980 end --  Bane of Agony
        if not MaxDps.IsTrackedAuraActive(172) then return 172 end --  Corruption
        if not MaxDps.IsTrackedAuraActive(348) then return 348 end --  Immolate
        if not MaxDps.IsSpellOnCooldown(1293817, true) then return 1293817 end --  Conflagrate
        if not MaxDps.IsSpellOnCooldown(5740, true) then return 5740 end --  Rain of Fire
        if not MaxDps.IsSpellOnCooldown(17877, true) then return 17877 end --  Shadowburn
        if not MaxDps.IsSpellOnCooldown(686, true) then return 686 end --  Shadow Bolt
    end
end
