-- The target castbar's "interrupt ready" strip: on while your interrupt is
-- learned, usable and off cooldown and the cast can be interrupted.
local M = H.M
local ns = H.LoadAddon()
local S, C = ns.Settings, ns.Config

local def = S.Get("castbarInterrupt")
for scope, applies in pairs({ target = true, focus = true, player = false, party = false, pet = false }) do
    H.check("applies to " .. scope, S.AppliesTo(def, scope), applies)
end
C.Use({})
H.check("on by default", C.Get("target", "castbarInterrupt"), true)
H.check("label", ns.L.SETTING_castbarInterrupt, "Interrupt ready")

M.units.player = { name = "Me", health = 5, healthMax = 10, className = "Warrior", class = "WARRIOR" }
for _, id in ipairs({ 72, 1671, 1672, 6552 }) do M.spells[id] = { name = id == 6552 and "Pummel" or "Shield Bash" } end
ns.Single.CreateAll()
local bar = ns.Frames.target.castbar
local strip = bar.interrupt

local function cast(fields)
    local c = { name = "Fireball", texture = 1, startMs = 1000000, endMs = 1002500 }
    for k, v in pairs(fields or {}) do c[k] = v end
    return c
end
local function begin(fields)
    M.units.target = { name = "Foe", health = 1, healthMax = 1, cast = cast(fields) }
    M.FireEvent("PLAYER_TARGET_CHANGED")
end

-- Not learned: nothing to be ready.
begin()
H.checkTrue("cast is shown", bar:IsShown())
H.check("spell not learned: no strip", strip:IsShown(), false)

-- The spell book's highest learned rank counts.
M.known[1672] = true
M.FireEvent("SPELLS_CHANGED")
begin()
H.check("learned and ready: strip", strip:IsShown(), true)
H.check("fully visible", strip:GetAlpha(), 1)
H.check("along the bottom", select(1, strip:GetPoint(1)), "BOTTOMLEFT")

-- On cooldown, the global cooldown does not count; the frame loop notices.
M.spellCooldowns[1672] = { isActive = true, isOnGCD = false }
ns.Castbar.OnUpdate(bar)
H.check("on cooldown: gone", strip:IsShown(), false)
M.spellCooldowns[1672] = { isActive = true, isOnGCD = true }
ns.Castbar.OnUpdate(bar)
H.check("global cooldown only: stays", strip:IsShown(), true)
M.spellCooldowns[1672] = nil

-- Not usable: wrong stance or no rage. A second interrupt can still serve.
M.spellUnusable[1672] = true
ns.Castbar.OnUpdate(bar)
H.check("not usable: gone", strip:IsShown(), false)
M.known[6552] = true
M.FireEvent("SPELLS_CHANGED")
ns.Castbar.OnUpdate(bar)
H.check("the other interrupt serves", strip:IsShown(), true)
M.known[6552] = nil
M.spellUnusable[1672] = nil
M.FireEvent("SPELLS_CHANGED")

-- An uninterruptible cast, plain or secret: the client hides the strip.
begin({ notInterruptible = true })
H.check("plain uninterruptible: invisible", strip:GetAlpha(), 0)
begin({ notInterruptible = M.Secret(true) })
H.check("secret uninterruptible: invisible", strip:GetAlpha(), 0)
H.checkTrue("secret stays with the client", strip._alphaSecret)
begin({ notInterruptible = M.Secret(false) })
H.check("secret interruptible: visible", strip:GetAlpha(), 1)

-- The flag changing mid-cast.
M.units.target.cast.notInterruptible = true
M.FireEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "target")
H.check("became uninterruptible", strip:GetAlpha(), 0)

-- A channel has the flag one place earlier.
M.units.target = { name = "Foe", health = 1, healthMax = 1, channel = cast({ notInterruptible = true }) }
M.FireEvent("PLAYER_TARGET_CHANGED")
H.checkTrue("channel shown", bar.cast and bar.cast.channel)
H.check("uninterruptible channel: invisible", strip:GetAlpha(), 0)

-- Cast over; switched off; test mode.
M.units.target = { name = "Foe", health = 1, healthMax = 1 }
M.FireEvent("PLAYER_TARGET_CHANGED")
H.check("no cast: the bar and its strip are gone", bar:IsShown(), false)
begin()
C.Set("target", "castbarAlwaysShow", true)
M.units.target = { name = "Foe", health = 1, healthMax = 1 }
M.FireEvent("PLAYER_TARGET_CHANGED")
H.checkTrue("always show: empty bar stays", bar:IsShown())
H.check("always show: no strip without a cast", strip:IsShown(), false)
C.Set("target", "castbarAlwaysShow", false)
begin()
C.Set("target", "castbarInterrupt", false)
H.check("switched off: gone", strip:IsShown(), false)
ns.Castbar.OnUpdate(bar)
H.check("switched off: stays gone", strip:IsShown(), false)
C.Set("target", "castbarInterrupt", true)
M.known[1672] = nil
M.FireEvent("SPELLS_CHANGED")
ns.Castbar.Preview(ns.Frames.target, true)
H.check("test mode shows it", strip:IsShown(), true)
H.check("test mode: visible", strip:GetAlpha(), 1)
ns.Castbar.Preview(ns.Frames.target, false)

-- A frame the setting does not apply to never shows it.
C.Set("player", "castbarEnabled", true)
M.known[1672] = true
M.FireEvent("SPELLS_CHANGED")
M.units.player.cast = cast()
M.FireEvent("UNIT_SPELLCAST_START", "player")
H.check("player's own bar: no strip", ns.Frames.player.castbar.interrupt:IsShown(), false)
