-- Party > Group > Sort by role: the header groups by assigned role; off,
-- it keeps the group's order.
local M = H.M
local ns = H.LoadAddon()
_G.ForeverUnitFramesDB = nil
M.FireEvent("PLAYER_LOGIN")
M.RunTimers()
local C, P, Pets = ns.Config, ns.Party, ns.PartyPets
M.units.player = { name = "Me", level = 60, health = 5, healthMax = 10, role = "HEALER" }
for i, role in ipairs({ "DAMAGER", "NONE", "TANK", "HEALER" }) do
    M.units["party" .. i] = { name = "P" .. i, level = 60, health = 5, healthMax = 10, role = role }
    M.units["partypet" .. i] = { name = "Pet" .. i, level = 60, health = 5, healthMax = 10 }
end
M.SetGroup({ "party1", "party2", "party3", "party4" })

-- The shown members, top to bottom.
local function order()
    local list = {}
    for _, button in ipairs(P.buttons) do
        if button:IsShown() and button.unit then list[#list + 1] = button.unit end
    end
    return table.concat(list, ",")
end

H.check("the setting's code", ns.Settings.Get("partySortRole").code, "SR")
H.check("off by default", C.Get("party", "partySortRole"), false)
H.check("off: the group's order", order(), "party1,party2,party3,party4")

C.Set("party", "partySortRole", true)
H.check("on: by role, no role last", order(), "party3,party4,party1,party2")

-- Same role: the header's order, the player first.
C.Set("party", "partyShowPlayer", true)
H.check("with the player", order(), "party3,player,party4,party1,party2")
C.Set("party", "partyShowPlayer", false)

-- A role handed out later moves the member with the next roster update.
M.units.party2.role = "TANK"
M.FireEvent("GROUP_ROSTER_UPDATE")
H.check("a new role", order(), "party2,party3,party4,party1")

-- Pets beside their member go with it; the slot's button keeps the pair.
C.Set("party", "partyPetLayout", "BESIDE")
for _, button in ipairs(P.buttons) do
    if button:IsShown() and button.unit then
        H.check("the pet beside " .. button.unit, button.petButton.unit, Pets.PetUnit(button.unit))
    end
end
C.Set("party", "partyPetLayout", "LIST")

C.Set("party", "partySortRole", false)
H.check("off again: the group's order", order(), "party1,party2,party3,party4")
H.check("no error", #M.errors, 0)
