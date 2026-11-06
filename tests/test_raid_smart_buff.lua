-- The smart buff key (Raid/SmartBuff.lua): a hidden secure button whose
-- spell and unit are set out of combat to the best next cast, clicked by
-- an override binding on the key while there is a cast; at the start of
-- combat it is emptied and the key let go until combat ends.
local M = H.M
local ns = H.LoadAddon()
local RC, Watch, Smart = ns.RaidConfig, ns.RaidBuffWatch, ns.SmartBuff
ns.Config.Use({})
ns.RaidProfiles.Attach({})

M.units.player = { name = "Tester", class = "PRIEST", className = "Priest", isPlayer = true, auras = {} }
M.known[1243] = true

-- Made out of combat at login (Core/Boot.lua).
H.check("not made at load", _G[Smart.BUTTON_NAME], nil)
Smart.Update()
local b = _G[Smart.BUTTON_NAME]
H.checkTrue("the button", b)
H.check("a secure action button", b._template, "SecureActionButtonTemplate")
H.check("key down and up", table.concat(b._clicks, ","), "AnyUp,AnyDown")
H.check("no mouse on it", b._mouse, false)

-- No key: nothing bound.
RC.Set("general", "buffKey", "SHIFT-B")
H.check("solo: the key keeps its binding", GetBindingAction("SHIFT-B", true), "")

-- A party with someone who needs Fortitude.
M.units.party1 = { name = "Ann", class = "MAGE", className = "Mage", isPlayer = true, auras = {}, distance = 10 }
M.units.player.auras = { { name = "Power Word: Fortitude", spellId = 1243, isHelpful = true,
    expirationTime = M.now + 1700 } }
M.SetGroup({ "party1" })
M.Tick(1)
H.check("bound in a group", GetBindingAction("SHIFT-B", true), "CLICK " .. Smart.BUTTON_NAME .. ":LeftButton")
H.check("casts a spell", b:GetAttribute("type"), "spell")
H.check("the rank's ID", b:GetAttribute("spell"), 1243)
H.check("on Ann", b:GetAttribute("unit"), "party1")
H.check("the key casts", M.PressBinding("SHIFT-B"), "spell")
H.check("once", #M.casts, 1)
H.check("Fortitude on Ann", M.casts[1][1] .. "@" .. M.casts[1][2], "1243@party1")
-- What the next press does, in words.
H.check("described", Smart.Describe(Watch.Next()), "Power Word: Fortitude: Ann")

-- Everyone buffed: nothing to cast, the key is free for what else it does.
M.units.party1.auras = { { name = "Power Word: Fortitude", spellId = 1243, isHelpful = true,
    expirationTime = M.now + 1700 } }
M.FireEvent("UNIT_AURA", "party1")
M.Tick(1)
H.check("nobody needs it: no type", b:GetAttribute("type"), nil)
H.check("no spell", b:GetAttribute("spell"), nil)
H.check("nobody needs it: the key is free", GetBindingAction("SHIFT-B", true), "")
H.check("still one cast", #M.casts, 1)

-- Combat: emptied as it starts (lockdown follows PLAYER_REGEN_DISABLED);
-- the key is free; after combat it casts again.
M.units.party1.auras = {}
M.FireEvent("UNIT_AURA", "party1")
M.Tick(1)
H.check("needed again", b:GetAttribute("unit"), "party1")
M.FireEvent("PLAYER_REGEN_DISABLED")
M.SetCombat(true)
H.check("combat: emptied", b:GetAttribute("type"), nil)
H.check("combat: the key is free", GetBindingAction("SHIFT-B", true), "")
M.FireEvent("UNIT_AURA", "party1")
M.Tick(1)
H.check("combat: nothing set", b:GetAttribute("type"), nil)
H.check("nothing blocked", #M.blocked, 0)
M.SetCombat(false)
M.Tick(1)
H.check("after combat: set again", b:GetAttribute("unit"), "party1")
H.check("after combat: bound again", GetBindingAction("SHIFT-B", true), "CLICK " .. Smart.BUTTON_NAME .. ":LeftButton")

-- Another key: bound anew, the old one free; no key: nothing bound.
RC.Set("general", "buffKey", "CTRL-B")
H.check("old key free", GetBindingAction("SHIFT-B", true), "")
H.check("new key", GetBindingAction("CTRL-B", true), "CLICK " .. Smart.BUTTON_NAME .. ":LeftButton")
RC.Set("general", "buffKey", "")
H.check("no key", GetBindingAction("CTRL-B", true), "")
RC.Set("general", "buffKey", "CTRL-B")
-- Nothing watched (fortitude off): no key taken.
RC.Set("general", "buffFortitude", false)
M.Tick(1)
H.check("nothing watched: free", GetBindingAction("CTRL-B", true), "")
RC.Set("general", "buffFortitude", true)
M.Tick(1)
H.check("watched again: bound", GetBindingAction("CTRL-B", true), "CLICK " .. Smart.BUTTON_NAME .. ":LeftButton")
-- Solo: free.
M.SetGroup({})
M.Tick(1)
H.check("solo: free", GetBindingAction("CTRL-B", true), "")
-- Raid frames off altogether: free.
M.SetGroup({ "party1" })
M.Tick(1)
RC.Set("general", "enabled", false)
M.Tick(1)
H.check("raid frames off: free", GetBindingAction("CTRL-B", true), "")

-- A stronger buff on someone: the client refuses, the key moves on to the
-- next member and tries the refused one again later.
RC.Set("general", "enabled", true)
_G.SPELL_FAILED_AURA_BOUNCED = "A more powerful spell is already active"
M.units.party2 = { name = "Bob", class = "MAGE", className = "Mage", isPlayer = true, auras = {}, distance = 10 }
M.SetGroup({ "party1", "party2" })
M.Tick(1)
H.check("first Ann", b:GetAttribute("unit"), "party1")
M.PressBinding("CTRL-B")
M.FireEvent("UI_ERROR_MESSAGE", 1, "Not this one")
M.Tick(1)
H.check("another error: still Ann", b:GetAttribute("unit"), "party1")
M.FireEvent("UI_ERROR_MESSAGE", 1, SPELL_FAILED_AURA_BOUNCED)
M.Tick(1)
H.check("refused: on to Bob", b:GetAttribute("unit"), "party2")
H.check("Ann still counts as needing it", #Watch.state.entries[1].needs, 2)
M.Tick(Watch.BOUNCE_WAIT)
H.check("later: Ann again", b:GetAttribute("unit"), "party1")
-- The same error long after a click is not about the cast.
M.PressBinding("CTRL-B")
M.Tick(Smart.ERROR_WINDOW + 1)
M.FireEvent("UI_ERROR_MESSAGE", 1, SPELL_FAILED_AURA_BOUNCED)
M.Tick(1)
H.check("too late: still Ann", b:GetAttribute("unit"), "party1")
-- Only Ann left, refused: nothing to cast, the key is free.
M.units.party2.auras = { { name = "Power Word: Fortitude", spellId = 1243, isHelpful = true,
    expirationTime = M.now + 5000 } }
M.FireEvent("UNIT_AURA", "party2")
M.Tick(1)
M.PressBinding("CTRL-B")
M.FireEvent("UI_ERROR_MESSAGE", 1, SPELL_FAILED_AURA_BOUNCED)
M.Tick(1)
H.check("nobody else: free", GetBindingAction("CTRL-B", true), "")
H.check("no error", #M.errors, 0)
