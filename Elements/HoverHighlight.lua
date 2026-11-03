local _, ns = ...

-- Hover highlight (optional, off by default): the unit frame or raid cell
-- under the mouse lights up, so you see who a click-cast will hit. A soft
-- layer over the bars and below the texts, on a plain holder: it changes in
-- combat too. Hooked like the tooltip (Units/Units.lua): the secure
-- template's own scripts stay as they are.
local HoverHighlight = { name = "HoverHighlight", unitEvents = {} }
ns.HoverHighlight = HoverHighlight

local Config = ns.Config

HoverHighlight.COLOR = { 1, 1, 1, 0.15 }
-- Above the bars, below the text overlay (+10).
HoverHighlight.LEVELS = 9

function HoverHighlight.Build(frame)
    local holder = CreateFrame("Frame", nil, frame)
    local layer = holder:CreateTexture(nil, "ARTWORK")
    local c = HoverHighlight.COLOR
    layer:SetColorTexture(c[1], c[2], c[3], c[4])
    layer:SetBlendMode("ADD")
    layer:SetAllPoints(frame)
    layer:Hide()
    ns.Corners.Add(holder, layer)
    holder.clip = ns.Corners.Clipper(holder)
    frame.hoverHighlight = { holder = holder, layer = layer }
    frame:HookScript("OnEnter", function() layer:SetShown(Config.Get(frame.key, "hoverHighlight") == true) end)
    frame:HookScript("OnLeave", function() layer:Hide() end)
end

function HoverHighlight.Style(frame)
    local h = frame.hoverHighlight
    h.holder:SetFrameLevel(frame:GetFrameLevel() + HoverHighlight.LEVELS)
    h.holder:SetAllPoints(frame)
    ns.Corners.Fit(h.holder.clip, frame.unitBox, ns.Shape.Radius(frame))
    -- Switched off while the mouse is on the frame.
    if not Config.Get(frame.key, "hoverHighlight") then h.layer:Hide() end
end

function HoverHighlight.Update() end

ns.RegisterElement(HoverHighlight)
