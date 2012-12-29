--[[
    Dark-RP specific Moneypot
    Copyright (c) 2010-2012 Lex Robinson
    This code is freely available under the MIT License
--]]

AddCSLuaFile();

ENT.Type            = "anim"
ENT.PrintName       = "Money Pot"
ENT.Author          = "Lexi"
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

DEFINE_BASECLASS("base_moneypot");

if (CLIENT) then return; end

--------------------------------------
--                                  --
--  Overridables for customisation  --
--                                  --
--------------------------------------

function ENT:IsMoneyEntity(ent)
    return ent:GetClass() == "spawned_money";
end

function ENT:SpawnMoneyEntity(amount)
	local cash = ents.Create("spawned_money");
	cash.dt.amount = amount;
    return cash;
end

function ENT:GetNumMoneyEntities()
    return #ents.FindByClass("spawned_money");
end

--------------------------------------
--                                  --
--        Duplicator support        --
--                                  --
--------------------------------------

function MakeMoneyPot(ply, pos, angles, model, data)
    ply = IsValid(ply) and ply or nil;
	if (ply and not ply:CheckLimit("moneypots")) then
		return false;
	end
    data = data or {
        Pos   = pos,
        Angle = angles,
    };
    data.Class = "darkrp_moneypot";
	local box  = duplicator.GenericDuplicatorFunction(ply, data);
    -- This sets it's own model by default, but if someone wants to override ..?
    --[[
    if (model) then
        box:SetModel(model);
    end
    --]]
    if (ply) then
        box:SetPlayer(ply);
        ply:AddCount("moneypots", box);
    end
	return box;
end

duplicator.RegisterEntityClass("darkrp_moneypot",    MakeMoneyPot, "Pos", "Angle", "Model", "Data");
duplicator.RegisterEntityClass("gmod_wire_moneypot", MakeMoneyPot, "Pos", "Angle", "Model", "Data");
