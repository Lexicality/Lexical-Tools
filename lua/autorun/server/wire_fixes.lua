--[[
    ~ Lexical Tools ~
    ~ Wire Fixes ~
--]]

if (not WireLib) then
    return;
end

---
-- Adds inputs to an already setup wire entity.
-- Functionally identical to WireLib.AdjustSpecialInputs with
--  the one difference that it doesn't delete everything you
--  don't specify (fucking stupid thing to do anyway)
-- This does not duplicate the functionality, allowing it to change freely,
--  but does require that the deletion method doesn't change.
function WireLib.AddSpecialInputs(ent, ...)
    -- If the ent's not wired up, wire it up.
    if (not ent.Inputs) then
        return WireLib.CreateSpecialInputs(ent, ...);
    end
    -- Prevent the deleter deleting anything
    for _, data in pairs(ent.Inputs) do
        data.Keep = true;
    end
    -- Boosh
    return WireLib.AdjustSpecialInputs(ent, ...);
end

---
-- See above
function WireLib.AddSpecialOutputs(ent, ...)
    -- If the ent's not wired up, wire it up.
    if (not ent.Outputs) then
        return WireLib.CreateSpecialInputs(ent, ...);
    end
    -- Prevent the deleter deleting anything
    for _, data in pairs(ent.Outputs) do
        data.Keep = true;
    end
    -- Boosh
    return WireLib.AdjustSpecialInputs(ent, ...);
end

-- Compat
function Wire_AddInputs(ent, names)
    return WireLib.AdjustSpecialInputs(ent, names);
end

function Wire_AddOutputs(ent, names, descs)
    return WireLib.AdjustSpecialOutputs(ent, names, {}, descs);
end

WireLib.AddInputs  = Wire_AddInputs;
WireLib.AddOutputs = Wire_AddOutputs;
