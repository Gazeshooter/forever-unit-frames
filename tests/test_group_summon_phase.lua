-- Incoming summon and another phase: icons on the player and party frames
-- and on raid cells (Elements/GroupIcons.lua), from Blizzard's raid art.
local M = H.M
local ns = H.LoadAddon()
local C = ns.Config
M.units.player = { name = "Me", class = "WARRIOR", className = "WARRIOR", isPlayer = true, health = 1, healthMax = 1 }
_G.ForeverUnitFramesDB = nil
M.FireEvent("PLAYER_LOGIN")
M.RunTimers()

local status, phase, distance = {}, {}, {}
Enum.SummonStatus = { None = 0, Pending = 1, Accepted = 2, Declined = 3 }
_G.C_IncomingSummon = { IncomingSummonStatus = function(unit) return status[unit] or 0 end }
_G.UnitPhaseReason = function(unit) return phase[unit] end
_G.UnitDistanceSquared = function(unit) return distance[unit] or 0, true end

local header = ns.Party.Create()
M.units.party1 = { name = "Ann", health = 1, healthMax = 1 }
M.SetGroup({ "party1" })
local frame = header:GetAttribute("child1")
local g = frame.groupIcons

H.checkTrue("summon on by default", C.Get("party", "groupSummon"))
H.checkTrue("phase on by default", C.Get("party", "groupPhase"))
H.check("nothing: no summon", g.summon:IsShown(), false)
H.check("nothing: no phase", g.phase:IsShown(), false)

for value, atlas in pairs({ [1] = "RaidFrame-Icon-SummonPending", [2] = "RaidFrame-Icon-SummonAccepted",
    [3] = "RaidFrame-Icon-SummonDeclined" }) do
    status.party1 = value
    M.FireEvent("INCOMING_SUMMON_CHANGED", "party1")
    H.check("summon shown " .. value, g.summon:IsShown(), true)
    H.check("summon art " .. value, g.summon._atlas, atlas)
end
status.party1 = M.Secret(1)
M.FireEvent("INCOMING_SUMMON_CHANGED", "party1")
H.check("secret summon: none", g.summon:IsShown(), false)
status.party1 = 1
M.FireEvent("INCOMING_SUMMON_CHANGED", "party1")
C.Set("party", "groupSummon", false)
H.check("summon switched off", g.summon:IsShown(), false)
C.Set("party", "groupSummon", true)
status.party1 = 0
M.FireEvent("INCOMING_SUMMON_CHANGED", "party1")
H.check("summon over", g.summon:IsShown(), false)

phase.party1 = 0   -- a real reason can be the number 0
M.FireEvent("UNIT_PHASE", "party1")
H.check("other phase shown", g.phase:IsShown(), true)
H.check("phase art", g.phase._atlas, "RaidFrame-Icon-Phasing")
distance.party1 = 250 * 250
M.FireEvent("UNIT_PHASE", "party1")
H.check("far away: none, as Blizzard's", g.phase:IsShown(), false)
distance.party1 = nil
M.FireEvent("UNIT_PHASE", "party1")
C.Set("party", "groupPhase", false)
H.check("phase switched off", g.phase:IsShown(), false)
C.Set("party", "groupPhase", true)
phase.party1 = nil
M.FireEvent("UNIT_PHASE", "party1")
H.check("back in phase", g.phase:IsShown(), false)

-- A client that answers with an error shows nothing and throws nothing.
_G.UnitPhaseReason = function() error("refused") end
M.FireEvent("UNIT_PHASE", "party1")
H.check("refused: none", g.phase:IsShown(), false)
