--[[
	~ Cannon Prop ~
	~ Lexi ~
--]]
AddCSLuaFile();
ENT.Type 			= "anim";
ENT.Base 			= "base_anim";
ENT.PrintName		= "Prop Cannon Shot";
ENT.Author			= "Lexi";
ENT.Contact			= "lexi@lexi.org.uk";
ENT.Spawnable		= false;
ENT.AdminSpawnable	= false;
if (CLIENT) then
	language.Add("cannon_prop", ENT.PrintName);
	return;
end 

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid	(SOLID_VPHYSICS);
	
	if (not IsValid(self.Owner)) then
		self.Owner = self;
		ErrorNoHalt("cannon_prop created without a valid owner.");
	end
	
	self:SetPhysicsAttacker(self.Owner);

    local phys = self:GetPhysicsObject();
	if (IsValid(phys)) then
		phys:Wake();
	end
end

hook.Add("EntityTakeDamage", "cannon_prop kill crediting", function(ent, info)
	local me = info:GetInflictor();
	if (IsValid(me) and me:GetClass() == "cannon_prop") then
		info:SetAttacker(me.Owner);
	end
end);

function ENT:Explode()
	if (self.exploded) then
		return;
	end
	local pos = self:GetPos();
	local effectData = EffectData();
	effectData:SetStart(pos);
	effectData:SetOrigin(pos);
	effectData:SetScale(1);
	util.Effect("Explosion", effectData);
	util.BlastDamage(self, self.Owner, pos, self.explosiveRadius, self.explosivePower);
	self.exploded = true;
	self:Remove();
end


function ENT:OnTakeDamage(damageInfo)
	if (self.explosive) then
		self:Explode()
	end 
	self:TakePhysicsDamage(damageInfo);
end

local function doBoom(self)
	if (self.explosive) then
		self:Explode()
	end
end
ENT.StartTouch = doBoom;
ENT.Touch = doBoom;
ENT.PhysicsCollide = doBoom;
ENT.Use = doBoom;


function ENT:Think()
	if (not self.dietime) then return; end
	if (self.die) then
		self:Remove();
	elseif (self.dietime <= CurTime()) then
		self:Fire("break");
		self.die = true;
	end
end