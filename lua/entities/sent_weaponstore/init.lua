--[[
	~ Weapon Store ~ Serverside ~
	~ Lexi ~
--]]
function ENT:SpawnFunction(ply,  tr)
	print(self, self.IsValid, self:IsValid(), self.GetClass, self:GetClass())
	if (not tr.Hit) then return end
	local ent = ents.Create ("sent_weaponstore");
	ent:SetPos (tr.HitPos + tr.HitNormal * 16);
	ent:Spawn();
	ent:Activate();
	return ent;
end

ENT.Weapons = {
	{
		ent			= NULL;
		class		= "weapon_rpg";
		multiplier	= 1;
		nextspawn	= 0;
	};
	{
		ent			= NULL;
		class		= "";
		multiplier	= 0;
		nextspawn	= 0;
	};
	{
		ent			= NULL;
		class		= "";
		multiplier	= 0;
		nextspawn	= 0;
	};
	{
		ent			= NULL;
		class		= "";
		multiplier	= 0;
		nextspawn	= 0;
	};
	{
		ent			= NULL;
		class		= "";
		multiplier	= 0;
		nextspawn	= 0;
	};
	{
		ent			= NULL;
		class		= "";
		multiplier	= 0;
		nextspawn	= 0;
	};
	{
		ent			= NULL;
		class		= "";
		multiplier	= 0;
		nextspawn	= 0;
	};
	{
		ent			= NULL;
		class		= "";
		multiplier	= 0;
		nextspawn	= 0;
	};
};
-- keyvals
ENT.k_number		= 1;
ENT.k_weapon1_class	= "weapon_rpg";
ENT.k_weapon1_mul	= 1;
	
	
local model = Model("models/props_c17/streetsign004f.mdl")
function ENT:Initialize ()
	self:SetModel(model);
	self:SetMaterial("models/debug/white");
	self:SetColor(122, 204, 71, 200);
	self:PhysicsInit(SOLID_BBOX);
	self:SetMoveType(MOVETYPE_NONE);
	self:SetSolid	(SOLID_NONE);
	local phys = self:GetPhysicsObject();
	if (IsValid(phys)) then
		phys:EnableMotion(false);
	else
		ErrorNoHalt("No physics object for ", tostring(self), " using model ", model, "?\n");
	end
end

local time,offset;
ENT.PrevTime = 0;
function ENT:Think()
	time = CurTime(); -- Rather than RealTime, so if the server slows down, so does the spinning~
	offset = time - self.prevtime;
	self.prevtime = time;
--	for i = 1, self.k_number do
--		if (
end

-- Using keyvalues allows us to have a callback for each value,  should it be needed.
function ENT:KeyValue (key,  value)
	self["k_"..key] = tonumber(value) or value;
end

function ENT:OnRemove()
	-- Remove floating weapons
end

--[[ Make theese dupable ]]--
duplicator.RegisterEntityClass("sent_weaponcache",  function(ply,  pos,  angles,  data)
	local ent = ents.Create("sent_weaponcache");
	ent:SetAngles(angles);
	ent:SetPos(angles);
	for key, value in pairs(data) do
		if (key:sub(1, 2) == "k_") then
			ent:SetKeyValue(key:sub(3), value);
		end
	end
	ent:Spawn();
	ent:Activate();
end,  "Pos",  "Angles",  "Data");