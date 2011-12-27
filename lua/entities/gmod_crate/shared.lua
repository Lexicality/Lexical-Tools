--[[
	~ Resizable Crate Entity ~
	~ Lexi ~
--]]
AddCSLuaFile("shared.lua");
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
		self:SetModelWorldScale(Vector(scale, scale, scale));
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