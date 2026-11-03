-- The player castbar's latency zone: optional and off by default, its side
-- and offset chosen in the options, as wide as your latency is of the cast.
local M = H.M
local ns = H.LoadAddon()
local S, C = ns.Settings, ns.Config

for _, key in ipairs({ "castbarLatency", "castbarLatencyPoint", "castbarLatencyX" }) do
    H.checkTrue(key .. " on the player", S.AppliesTo(S.Get(key), "player"))
    H.check(key .. " not on the target", S.AppliesTo(S.Get(key), "target"), false)
end
C.Use({})
H.check("off by default", C.Get("player", "castbarLatency"), false)
H.check("at the bar's end by default", C.Get("player", "castbarLatencyPoint"), "END")
C.Set("player", "castbarEnabled", true)

_G.GetNetStats = function() return 1, 1, 80, 100 end
ns.Single.CreateAll()
local bar = ns.Frames.player.castbar
local lag = bar.lag
bar:SetWidth(200)

local function cast(unitField)
    M.units.player = { name = "Me", health = 1, healthMax = 1,
        [unitField] = { name = "Spell", texture = 1, startMs = 1000000, endMs = 1002000 } }
end

cast("cast")
M.FireEvent("UNIT_SPELLCAST_START", "player", "cast-1", 1)
H.check("off: no zone", lag:IsShown(), false)

C.Set("player", "castbarLatency", true)
M.FireEvent("UNIT_SPELLCAST_START", "player", "cast-2", 1)
H.check("on: zone shown", lag:IsShown(), true)
H.check("100 ms of a 2 s cast on 200 px: 10 px", lag:GetWidth(), 10)
H.check("a cast ends right", (lag:GetPoint(1)), "TOPRIGHT")

C.Set("player", "castbarLatencyPoint", "LEFT")
M.FireEvent("UNIT_SPELLCAST_START", "player", "cast-3", 1)
H.check("placed left", (lag:GetPoint(1)), "TOPLEFT")
C.Set("player", "castbarLatencyPoint", "RIGHT")
C.Set("player", "castbarLatencyX", -12)
M.FireEvent("UNIT_SPELLCAST_START", "player", "cast-4", 1)
H.check("placed right", (lag:GetPoint(1)), "TOPRIGHT")
H.check("with its offset", select(4, lag:GetPoint(1)), -12)
C.Set("player", "castbarLatencyX", 0)

C.Set("player", "castbarLatencyPoint", "END")
M.units.player.cast = nil
cast("channel")
M.FireEvent("UNIT_SPELLCAST_CHANNEL_START", "player", "cast-5", 1)
H.check("a channel ends left", (lag:GetPoint(1)), "TOPLEFT")

-- Latency longer than the cast: the whole bar, not more.
_G.GetNetStats = function() return 1, 1, 80, 5000 end
M.FireEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player", "cast-6", 1)
H.check("at most the bar", lag:GetWidth(), 200)

-- Secret times cannot be measured: no zone, no error.
M.units.player = { name = "Me", health = 1, healthMax = 1,
    cast = { name = "Spell", texture = 1, startMs = M.Secret(1000000), endMs = M.Secret(1002000) } }
M.FireEvent("UNIT_SPELLCAST_START", "player", "cast-7", 1)
H.check("secret times: no zone", lag:IsShown(), false)

-- A target's castbar never has one.
H.checkTrue("the target's bar stays without", not ns.Frames.target.castbar.lag:IsShown())

-- Test mode shows the zone where it is set, to place it without casting.
M.units.player = { name = "Me", health = 1, healthMax = 1 }
M.FireEvent("UNIT_SPELLCAST_STOP", "player", "cast-7", 1)
ns.Castbar.Preview(ns.Frames.player, true)
H.check("preview: zone shown", lag:IsShown(), true)
H.check("preview: its share", lag:GetWidth(), 200 * ns.Castbar.PREVIEW_LATENCY)
C.Set("player", "castbarLatency", false)
ns.Castbar.Preview(ns.Frames.player, true)
H.check("preview: off stays off", lag:IsShown(), false)
ns.Castbar.Preview(ns.Frames.player, false)
