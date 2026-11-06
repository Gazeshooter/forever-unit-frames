-- The buff watch alone (buffSolo, off by default): the key is bound, the
-- next cast and the window look at you and nobody else.
local M = H.M
local ns = H.LoadAddon()
local RC, Watch, Smart, Win = ns.RaidConfig, ns.RaidBuffWatch, ns.SmartBuff, ns.RaidBuffWindow
ns.Config.Use({})
ns.RaidProfiles.Attach({})

M.units.player = { name = "Tester", class = "PRIEST", className = "Priest", isPlayer = true, auras = {} }
M.known[1243] = true
Smart.Update()
RC.Set("general", "buffKey", "SHIFT-B")
M.Tick(1)

H.check("off by default", RC.Get("general", "buffSolo"), false)
H.check("off: not active", Watch.Active(), false)
H.check("off: nobody watched", #Watch.Members(), 0)
H.check("off: the key keeps its binding", GetBindingAction("SHIFT-B", true), "")
H.check("off: no window", Win.Shown(), false)

RC.Set("general", "buffSolo", true)
M.Tick(1)
H.check("on: active", Watch.Active(), true)
H.check("on: only you", #Watch.Members(), 1)
H.check("on: the key is bound", GetBindingAction("SHIFT-B", true), "CLICK " .. Smart.BUTTON_NAME .. ":LeftButton")
H.check("on: the window shows", Win.Shown(), true)
H.check("the key casts", M.PressBinding("SHIFT-B"), "spell")
H.check("Fortitude on you", M.casts[1][1] .. "@" .. M.casts[1][2], "1243@player")

-- A buff that runs out alone is noticed by the rescan, without an event.
M.units.player.auras = { { name = "Power Word: Fortitude", spellId = 1243, isHelpful = true,
    expirationTime = M.now + 1700 } }
M.FireEvent("UNIT_AURA", "player")
M.Tick(1)
H.check("buffed: nothing to cast", M.PressBinding("SHIFT-B"), nil)
H.check("buffed: no window", Win.Shown(), false)
M.units.player.auras = {}
M.Tick(Watch.RESCAN + 1)
H.check("the rescan: casts again", M.PressBinding("SHIFT-B"), "spell")

-- In combat the key rests, as in a group.
M.FireEvent("PLAYER_REGEN_DISABLED")
H.check("combat: nothing", M.PressBinding("SHIFT-B"), nil)
M.FireEvent("PLAYER_REGEN_ENABLED")
M.Tick(1)

-- Switched off again: all of it goes.
RC.Set("general", "buffSolo", false)
M.Tick(1)
H.check("off again: the key is free", GetBindingAction("SHIFT-B", true), "")
H.check("off again: no state", #Watch.state.entries, 0)

-- The key's binding has priority: Bartender4 sets a plain override on the
-- same key at every UPDATE_BINDINGS, and between equals either could win.
RC.Set("general", "buffSolo", true)
M.Tick(1)
local setBinding, priority = SetOverrideBindingClick, nil
_G.SetOverrideBindingClick = function(owner, isPriority, ...)
    priority = isPriority
    return setBinding(owner, isPriority, ...)
end
RC.Set("general", "buffKey", "F9")
M.Tick(1)
_G.SetOverrideBindingClick = setBinding
H.check("the key is bound with priority", priority, true)
