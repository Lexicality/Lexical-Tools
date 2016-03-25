--[[
	Dark-RP specific Moneypot
	Copyright (c) 2010-2016 Lex Robinson
	This code is freely available under the MIT License
--]]

AddCSLuaFile();

ENT.Type            = "anim"
ENT.PrintName       = "DarkRP Money Pot"
ENT.Information     = "Allows you to collect DarkRP money into a pot"
ENT.Author          = "Lexi"
ENT.Spawnable       = true
ENT.AdminSpawnable  = true
ENT.Category        = "DarkRP"

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
	if (amount <= 0) then
		error("Attempt to spawn invalid money!");
	end
	local cash = ents.Create("spawned_money");
	cash.dt.amount = amount;
	return cash;
end

function ENT:GetNumMoneyEntities()
	return #ents.FindByClass("spawned_money");
end

function ENT:InvalidateMoneyEntity(ent)
	ent.hasMerged = true;
	ent.USED = true;
end

function ENT:IsMoneyEntityInvalid(ent)
	return ent.hasMerged or ent.USED;
end
--------------------------------------
--                                  --
--         Duplicator support       --
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
	if (not box) then
		-- uh oh
		-- Run the various duplicator tests to see what's wrong
		local isa = duplicator.IsAllowed(data.Class)        and "yes" or "no";
		local isv = IsValid(ents.Create(data.Class))        and "yes" or "no";
		-- uh, do we exist?
		local drp = scripted_ents.Get("darkrp_moneypot")    and "yes" or "no";
		local bas = scripted_ents.Get("base_moneypot")      and "yes" or "no";
		local old = scripted_ents.Get("gmod_wire_moneypot") and "yes" or "no";
		error("Something's gone wrong! Debug: Allowed: " .. isa .. " Valid: " .. isv .. " Exist Derived: " .. drp .. " Exist Base: " .. bas .. " Exist Old: " .. old);
	end

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

duplicator.RegisterEntityClass("darkrp_moneypot",	MakeMoneyPot, "Pos", "Angle", "Model", "Data");
duplicator.RegisterEntityClass("gmod_wire_moneypot", MakeMoneyPot, "Pos", "Angle", "Model", "Data");
