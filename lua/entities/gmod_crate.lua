--[[
	~ Resizable Crate Entity ~
	~ Lexi ~
--]]
AddCSLuaFile();
ENT.Type 			= "anim";
ENT.Base 			= "base_anim";
ENT.PrintName		= "Resizable Crate";
ENT.Author			= "Lexi";
ENT.Contact			= "lexi@lexi.org.uk";
ENT.Spawnable		= false;
ENT.AdminSpawnable	= false;

local radius = 32;
function ENT:SetScale(scale)
	self:SetDTInt(0, scale)
	self.Scale = scale;
end

function ENT:GetScale(scale)
	return self:GetDTInt(0);
end

function ENT:Think()
	local scale = self:GetScale();
	if (scale == self.prevScale) then
		return;
	end
	self.prevScale = scale;
	scale = (scale > 0) and scale or 1;
	local num = scale * radius;
	local vec = Vector(num, num, num);
	self:PhysicsInitBox(-vec, vec);
	self:SetCollisionBounds(-vec, vec);
	if (SERVER) then
		local phys = self:GetPhysicsObject();
		if (IsValid(phys)) then
			phys:SetMass(phys:GetMass() * scale);
		end
	else
		local mat = Matrix()
		mat:Scale(Vector(scale, scale, scale))
		self:EnableMatrix("RenderMultiply", mat)
		-- self:SetModelWorldScale(Vector(scale, scale, scale));
		vec = vec * 2;
		self:SetRenderBounds(-vec, vec);
		self:SetupBones();
	end
end

function ENT:Initialize()
	self:PhysicsInit(SOLID_BBOX);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid(SOLID_BBOX);
end

function MakeCrate(ply, pos, angles, scale, data)
	if (not ply:CheckLimit("props")) then
		return false;
	end
	if (data) then
		ent = duplicator.GenericDuplicatorFunction(ply, data); -- This is actually better than doing it manually
	else
		ent = ents.Create("gmod_crate");
		ent:SetModel("models/props/de_dust/du_crate_64x64.mdl");
		ent:SetPos(pos);
		ent:SetAngles(angles);
		ent:Spawn();
	end
	ent:SetScale(scale);
	ent:Think(); -- Update the boundries NOW

	ply:AddCount("props",   ent);
	ply:AddCleanup("props", ent);
	return ent;
end
duplicator.RegisterEntityClass("gmod_crate", MakeCrate, "Pos", "Ang", "Scale", "Data")
