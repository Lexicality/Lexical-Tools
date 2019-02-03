--[[
	Lexical Tools - lua/entities/gmod_crate.lua
	Copyright 2010-2013 Lex Robinson

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
--]]
AddCSLuaFile();
ENT.Type      = "anim";
ENT.Base      = "base_lexentity";
ENT.PrintName = "Resizable Crate";
ENT.Author    = "Lexi";
ENT.Contact   = "lexi@lexi.org.uk";
ENT.Spawnable = true;
ENT.Editable  = true;

ENT._NWVars = {
	{
		Name = "Scale";
		Type = "Int";
		Default = 1;
		KeyName = "scale";
		Edit = {
			type = "Int";
			min = 1;
			max = 10;
		}
	}
}

local radius = 32;
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

if (CLIENT) then return; end

function ENT:Initialize()
	self:PhysicsInit(SOLID_BBOX);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid(SOLID_BBOX);
	self:SetModel("models/props/de_dust/du_crate_64x64.mdl");
	self:Think();
end

function MakeCrate(ply, pos, angles, scale, data)
	if (not ply:CheckLimit("props")) then
		return false;
	end
	if (data) then
		ent = duplicator.GenericDuplicatorFunction(ply, data); -- This is actually better than doing it manually
	else
		ent = ents.Create("gmod_crate");
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
