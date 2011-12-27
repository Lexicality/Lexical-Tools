AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:SpawnFunction( ply, tr )
	local ClassName = ClassName or "gmod_wire_moneypot"
	if not tr.Hit then return end
	local ent = ents.Create(ClassName)
	ent:SetPos( tr.HitPos + tr.HitNormal * 52)
	ent:Spawn()
	ent:Activate()
	return ent
end 
	
function ENT:Initialize()
	self:SetModel("models/props_lab/powerbox02b.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:UpdateOverlay()
	WireLib.CreateSpecialInputs(self, {
		"SpawnAll",
		"SpawnAmount"
	});
	WireLib.CreateSpecialOutputs(self, {
		"StoredAmount",
		"LastAmount",
		"Updated"
	});
	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
	end
end

local function timr(self, amt)
	if (self:IsValid()) then
		self:SpawnAmount(amt);
		self.sparking = false;
	end
end

function ENT:Use(activator)
	if (self:GetDTInt(0) == 0) then
		return;
	end
	timer.Simple(1, timr, self, self:GetDTInt(0));
	self.sparking = true;
end

function ENT:StartTouch(ent)
	if (ent:GetClass() == "spawned_money" and (ent.MoneyPotPause or 0) < CurTime()) then
        ent.MoneyPotPause = CurTime() + 100 -- Fix a stupid glitch
		self:SetDTInt(0, self:GetDTInt(0) + ent.dt.amount);
		Wire_TriggerOutput(self, "StoredAmount", self:GetDTInt(0));
		Wire_TriggerOutput(self, "LastAmount", ent.dt.amount);
		Wire_TriggerOutput(self, "Updated", 1);
		Wire_TriggerOutput(self, "Updated", 0);
		self:UpdateOverlay();
		ent:Remove();
	end
end

local spos = Vector(0, 0, 17);
function ENT:SpawnAmount(amount)
	amount = math.Clamp(amount, 0, self:GetDTInt(0));
	if (amount == 0) then return; end
    -- Prevent people spawning too many
    if (#ents.FindByClass("spawned_money") >= 50) then return; end
	
	local cash = ents.Create("spawned_money");
	cash:SetPos(self:LocalToWorld(spos));
	cash.dt.amount = amount;
	cash:Spawn();
	cash:Activate();
	cash.MoneyPotPause = CurTime() + 5;
	self:SetDTInt(0, self:GetDTInt(0) - amount);
	Wire_TriggerOutput(self, "StoredAmount", self:GetDTInt(0));
	Wire_TriggerOutput(self, "LastAmount", -amount);
	Wire_TriggerOutput(self, "Updated", 1);
	Wire_TriggerOutput(self, "Updated", 0);
	self:UpdateOverlay()
end

function ENT:UpdateOverlay()
	self:SetOverlayText("- Money Pot -\nAmount: $" .. self:GetDTInt(0));
end

-- From Moneyprinter
function ENT:Think()
	self.BaseClass.Think(self);
	if (not self.sparking) then return; end

	local effectdata = EffectData();
	effectdata:SetOrigin(self:GetPos());
	effectdata:SetMagnitude(1);
	effectdata:SetScale(1);
	effectdata:SetRadius(2);
	util.Effect("Sparks", effectdata);
end

function ENT:OnRemove()
	self:SpawnAmount(self:GetDTInt(0))
	self.BaseClass.OnRemove(self);
end

function ENT:TriggerInput(key, value)
	if (key == "SpawnAll" and value ~= 0) then
		self:Use();
	elseif (key == "SpawnAmount"  and value ~= 0 and value <= self:GetDTInt(0)) then
		self.sparking = true;
		timer.Simple(1, timr, self, value);
	end
end
