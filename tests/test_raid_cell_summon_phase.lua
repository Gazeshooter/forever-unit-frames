-- Raid cells show an incoming summon and another phase at points of their
-- own (Raid/Cell.lua), and can light up under the mouse.
local M = H.M
local ns = H.LoadAddon()
local RC, Header, Cell = ns.RaidConfig, ns.RaidHeader, ns.RaidCell
M.units.player = { name = "Me", class = "MAGE", className = "Mage", isPlayer = true, level = 60,
    health = 100, healthMax = 100 }
M.FireEvent("ADDON_LOADED", "ForeverUnitFrames")
M.FireEvent("PLAYER_LOGIN")
M.RunTimers()

Enum.SummonStatus = { None = 0, Pending = 1, Accepted = 2, Declined = 3 }
local status, phase = {}, {}
_G.C_IncomingSummon = { IncomingSummonStatus = function(unit) return status[unit] or 0 end }
_G.UnitPhaseReason = function(unit) return phase[unit] end
_G.UnitDistanceSquared = function() return 0, true end

M.SetRaidRoster({ { name = "Ann", class = "PRIEST", subgroup = 1 }, { name = "Bob", class = "MAGE", subgroup = 1 } })
M.RunTimers()
local cell = Header.headers[1]:GetAttribute("child1")
local g = cell.groupIcons
local unit = cell.unit

H.check("summon's default place", table.concat({ Cell.IconPoint(cell, "summon") }, ","), "CENTER,0,0")
H.check("phase's default place", table.concat({ Cell.IconPoint(cell, "phase") }, ","), "BOTTOM,0,1")

status[unit] = 1
M.FireEvent("INCOMING_SUMMON_CHANGED", unit)
H.check("summon shown", g.summon:IsShown(), true)
H.check("placed on the cell", (g.summon:GetPoint(1)), "CENTER")
phase[unit] = 1
M.FireEvent("UNIT_PHASE", unit)
H.check("phase shown", g.phase:IsShown(), true)
H.check("phase placed on the cell", (g.phase:GetPoint(1)), "BOTTOM")

local scope = ns.Raid.Scope(Cell.Size())
RC.Set(scope, "summonIcon", false)
H.check("summon off: no place", Cell.IconPoint(cell, "summon"), nil)
M.FireEvent("INCOMING_SUMMON_CHANGED", unit)
H.check("summon off", g.summon:IsShown(), false)

-- Hover: from the raid profile, off by default.
H.check("hover off by default", ns.Config.Get(Cell.KEY, "hoverHighlight"), false)
cell:GetScript("OnEnter")(cell)
H.check("stays dark", cell.hoverHighlight.layer:IsShown(), false)
cell:GetScript("OnLeave")(cell)
RC.Set(scope, "hoverHighlight", true)
cell:GetScript("OnEnter")(cell)
H.check("lights up", cell.hoverHighlight.layer:IsShown(), true)
cell:GetScript("OnLeave")(cell)
H.check("dark again", cell.hoverHighlight.layer:IsShown(), false)
