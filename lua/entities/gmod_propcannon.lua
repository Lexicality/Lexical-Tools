--[[
	Lexical Tools - lua/entities/gmod_propcannon.lua
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
]]
AddCSLuaFile()
ENT.Type = "anim"
if WireLib then
	ENT.Base = "base_wire_entity"
else
	ENT.Base = "base_gmodentity"
end
ENT.PrintName = "Prop Cannonv2"
ENT.Author = "Lexi" -- Duncan Stead
ENT.Contact = "lexi@lexi.org.uk" -- whohooo@yahoo.co.uk
ENT.Spawnable = false
ENT.AdminSpawnable = false

if CLIENT then
	return
end

function ENT:Initialize()
	self.fireForce = 20000
	self.cannonModel = "models/props_trainstation/trashcan_indoor001b.mdl"
	self.fireModel = "models/props_junk/cinderblock01a.mdl"
	self.recoilAmount = 1
	self.fireDelay = 5
	self.killDelay = 5
	self.explosivePower = 10
	self.explosiveRadius = 200
	self.fireEffect = "Explosion"
	self.fireExplosives = true

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.nextFire = CurTime()

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end
	if WireLib then
		WireLib.CreateSpecialInputs(
			self,
			{ "FireOnce", "AutoFire" },
			{ "NORMAL", "NORMAL" },
			{
				"Fire a single prop",
				"Fire repeatedly until released.",
			}
		)
		WireLib.CreateSpecialOutputs(self, {
			"ReadyToFire",
			"Fired",
			"AutoFiring",
			"LastBullet",
		}, { "NORMAL", "NORMAL", "NORMAL", "ENTITY" }, {
			"Is the cannon ready to fire again?",
			"Triggered every time the cannon fires.",
			"Is the cannon currently autofiring?",
			"The last prop fired",
		})
	end
end

function ENT:Setup(
	fireForce,
	cannonModel,
	fireModel,
	recoilAmount,
	fireDelay,
	killDelay,
	explosivePower,
	explosiveRadius,
	fireEffect,
	fireExplosives
)
	self:SetModel(cannonModel)
	self.fireForce = fireForce
	self.cannonModel = cannonModel
	self.fireModel = fireModel
	self.recoilAmount = recoilAmount
	self.fireDelay = fireDelay
	self.killDelay = killDelay
	self.explosivePower = explosivePower
	self.explosiveRadius = explosiveRadius
	self.fireEffect = fireEffect
	self.fireExplosives = fireExplosives

	self:SetOverlayText(
		"- Prop Cannon -\nFiring Force: "
			.. math.floor(fireForce)
			.. ", Fire Delay: "
			.. math.floor(fireDelay)
			.. (fireExplosives and ("\nExplosive Power:" .. math.floor(explosivePower) .. ", Explosive Radius:" .. math.floor(
				explosiveRadius
			)) or "")
			.. "\nBullet Model: "
			.. fireModel
	)
end

function ENT:OnTakeDamage(dmginfo)
	self:TakePhysicsDamage(dmginfo)
end

function ENT:FireEnable()
	self.enabled = true
	self.nextFire = CurTime()
	if WireLib then
		Wire_TriggerOutput(self, "AutoFiring", 1)
	end
end

function ENT:FireDisable()
	self.enabled = false
	if WireLib then
		Wire_TriggerOutput(self, "AutoFiring", 0)
	end
end

function ENT:CanFire()
	return self.nextFire <= CurTime()
end

function ENT:Think()
	if self:CanFire() then
		if WireLib then
			Wire_TriggerOutput(self, "ReadyToFire", 1)
		end
		if self.enabled then
			self:FireOne()
		end
	elseif WireLib then
		Wire_TriggerOutput(self, "ReadyToFire", 0)
	end
end

function ENT:FireOne()
	self.nextFire = CurTime() + self.fireDelay

	local pos = self:GetPos()
	if self.fireEffect ~= "" and self.fireEffect ~= "none" then
		local effectData = EffectData()
		effectData:SetOrigin(pos)
		effectData:SetStart(pos)
		effectData:SetScale(1)
		util.Effect(self.fireEffect, effectData)
	end
	local ent = ents.Create("cannon_prop")
	if not IsValid(ent) then
		error("Could not create cannon_prop for firing!")
	end
	ent:SetPos(pos)
	ent:SetModel(self.fireModel)
	ent:SetAngles(self:GetAngles())
	ent:SetOwner(self) -- For collision and such.
	ent.Owner = self:GetPlayer() -- For kill crediting
	if self.fireExplosives then
		ent.explosive = true
		ent.explosiveRadius = self.explosiveRadius
		ent.explosivePower = self.explosivePower
	end
	if self.killDelay > 0 then
		ent.dietime = CurTime() + self.killDelay
	end
	ent:Spawn()
	self:DeleteOnRemove(ent)

	local iPhys = self:GetPhysicsObject()
	local uPhys = ent:GetPhysicsObject()
	local up = self:GetUp()
	if IsValid(iPhys) then -- The cannon could conceivably work without a valid physics model.
		iPhys:ApplyForceCenter(up * -self.fireForce * self.recoilAmount) -- Recoil
	end
	if not IsValid(uPhys) then -- The bullets can't though
		error("Invalid physics for model '" .. self.fireModel .. "' !!")
	end
	uPhys:SetVelocityInstantaneous(self:GetVelocity()) -- Start the bullet off going like we be.
	uPhys:ApplyForceCenter(up * self.fireForce) -- Fire it off infront of us
	if WireLib then
		Wire_TriggerOutput(self, "Fired", 1)
		Wire_TriggerOutput(self, "LastBullet", ent)
		Wire_TriggerOutput(self, "Fired", 0)
	end
end

function ENT:TriggerInput(key, value)
	if key == "FireOnce" and value ~= 0 then
		self:FireOne()
	elseif key == "AutoFire" then
		if value == 0 then
			self:FireDisable()
		else
			self:FireEnable()
		end
	end
end

local function On(ply, ent)
	if not IsValid(ent) then
		return
	end
	ent:FireEnable()
end

local function Off(pl, ent)
	if not IsValid(ent) then
		return
	end
	ent:FireDisable()
end

numpad.Register("propcannon_On", On)
numpad.Register("propcannon_Off", Off)
