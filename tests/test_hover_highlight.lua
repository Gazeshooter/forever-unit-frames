-- The frame under the mouse lights up: optional, off by default, on single
-- frames and party buttons alike.
local M = H.M
local ns = H.LoadAddon()
local C = ns.Config
M.FireEvent("PLAYER_LOGIN")
M.RunTimers()
C.Use({})

H.check("off by default", C.Get("target", "hoverHighlight"), false)
ns.Single.CreateAll()
local frame = ns.Frames.target
local layer = frame.hoverHighlight.layer

local function hover(f, on) f:GetScript(on and "OnEnter" or "OnLeave")(f) end

hover(frame, true)
H.check("off: stays dark", layer:IsShown(), false)
hover(frame, false)

C.Set("target", "hoverHighlight", true)
hover(frame, true)
H.check("on: lights up", layer:IsShown(), true)
H.checkTrue("in combat too (a plain holder)", not frame.hoverHighlight.holder:IsProtected())
hover(frame, false)
H.check("off when the mouse leaves", layer:IsShown(), false)

hover(frame, true)
C.Set("target", "hoverHighlight", false)
H.check("switched off under the mouse", layer:IsShown(), false)

local header = ns.Party.Create()
M.units.party1 = { name = "Ann", health = 1, healthMax = 1 }
M.SetGroup({ "party1" })
local member = header:GetAttribute("child1")
C.Set("party", "hoverHighlight", true)
hover(member, true)
H.check("party button lights up", member.hoverHighlight.layer:IsShown(), true)
