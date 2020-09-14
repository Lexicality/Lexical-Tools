--[[
	Lexical Tools - lua/entities/base_moneypot.lua
	Copyright 2010-2016 Lex Robinson
	This is the main code for Moneypot style entities

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]] --
AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Money Pot"
ENT.Author = "Lexi"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.IsMoneyPot = true

local BaseClass
if (WireLib) then
	BaseClass = "base_wire_entity"
else
	BaseClass = "base_gmodentity"
end
DEFINE_BASECLASS(BaseClass)

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Money")
end

if (CLIENT) then
	if not WireLib then
		-- Slightly improved performance for sandbox tooltips
		function ENT:Think()
			if (self:BeingLookedAtByLocalPlayer()) then
				local text = self:GetOverlayText()

				AddWorldTip(self:EntIndex(), text, 0.5, self:GetPos(), self)

				halo.Add({self}, color_white, 1, 1, 1, true, true)
			end
		end
	end

	-- Sandbox
	function ENT:GetOverlayText()
		local txt = string.format(
			language.GetPhrase("tool.moneypot.overlay"),
			self:FormatMoney(self:GetMoney())
		)

		if (game.SinglePlayer()) then
			return txt
		end

		local PlayerName = self:GetPlayerName()

		return txt .. "\n(" .. PlayerName .. ")"
	end

	-- Wiremod
	function ENT:GetOverlayData()
		return {
			txt = string.format(
				language.GetPhrase("tool.moneypot.overlay"),
				self:FormatMoney(self:GetMoney())
			),
		}
	end

	function ENT:FormatMoney(amount)
		return string.format("$%d", amount)
	end

	return
end

--------------------------------------
--                                  --
--   Overridables for customisation --
--                                  --
--------------------------------------

function ENT:IsMoneyEntity(ent)
	return false
end

function ENT:SpawnMoneyEntity(amount)
	return NULL
end

function ENT:GetNumMoneyEntities()
	return math.huge
end

function ENT:InvalidateMoneyEntity(ent)
	ent._InvalidMoney = true
end

function ENT:IsMoneyEntityInvalid(ent)
	return ent._InvalidMoney == true
end

function ENT:GetMoneyAmount(ent)
	return 0
end

--------------------------------------
--                                  --
--              / END               --
--                                  --
--------------------------------------

function ENT:Initialize()
	self:SetModel("models/props_lab/powerbox02b.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	if (WireLib) then
		WireLib.CreateSpecialInputs(self, {"SpawnAll", "SpawnAmount"})
		WireLib.CreateSpecialOutputs(self, {"StoredAmount", "LastAmount", "Updated"})
	end
	local phys = self:GetPhysicsObject()
	if (not phys:IsValid()) then
		local mdl = self:GetModel()
		self:Remove()
		error(


				"Entity of type " .. self.ClassName ..
					" created without a physobj! (Model: " .. mdl .. ")"
		)
	end
	phys:Wake()
end

function ENT:SpawnAll(immediate)
	local amount = self:GetMoney()
	if (immediate) then
		self:SpawnAmount(amount)
	else
		self:DelayedSpawn(amount)
	end
end

function ENT:Use(activator)
	self:SpawnAll(false)
end

function ENT:UpdateWireOutputs(amount)
	if (not Wire_TriggerOutput) then
		return
	end
	Wire_TriggerOutput(self, "StoredAmount", self:GetMoney())
	Wire_TriggerOutput(self, "LastAmount", amount)
	Wire_TriggerOutput(self, "Updated", 1)
	timer.Simple(
		0.1, function()
			if (IsValid(self)) then
				Wire_TriggerOutput(self, "Updated", 0)
			end
		end
	)
end

function ENT:IsGoodMoneyEntity(ent)
	return IsValid(ent) and self:IsMoneyEntity(ent) and
       		not self:IsMoneyEntityInvalid(ent) and (ent.MoneyPotPause or 0) <
       		CurTime()
end

function ENT:StartTouch(ent)
	if (not self:IsGoodMoneyEntity(ent)) then
		return
	end

	local amt = self:GetMoneyAmount(ent)
	if (amt <= 0) then
		return
	end

	self:InvalidateMoneyEntity(ent)
	ent.MoneyPotPause = CurTime() + 100
	ent:Remove()

	self:AddMoney(amt)
end

local spos = Vector(0, 0, 17)
function ENT:SpawnAmount(amount)
	amount = math.Clamp(math.floor(amount), 0, self:GetMoney())
	if (amount == 0) then
		return
	end
	-- Prevent people spawning too many
	if (self:GetNumMoneyEntities() >= 50) then
		return
	end

	local cash = self:SpawnMoneyEntity(amount)
	if (cash == NULL) then
		error("Moneypot (" .. self.ClassName .. ") unable to create cash entity!")
	end
	-- Remove our money before the new money exists
	self:AddMoney(-amount)

	cash:SetPos(self:LocalToWorld(spos))
	cash:Spawn()
	cash:Activate()
	cash.MoneyPotPause = CurTime() + 5
end

-- For calling from lua (ie so /givemoney can give direct to it)
function ENT:AddMoney(amount)
	self:SetMoney(self:GetMoney() + amount)
	self:UpdateWireOutputs(amount)
end

local cvar_delay = CreateConVar(
	"moneypot_spawn_delay", 1, FCVAR_ARCHIVE,
	"How long in seconds to wait before spawning money"
)
function ENT:DelayedSpawn(amount)
	amount = math.Clamp(amount, 0, self:GetMoney())
	if (amount == 0) then
		return
	end
	if (self.DoSpawn) then
		self.DoSpawn = self.DoSpawn + amount
	else
		self.DoSpawn = amount
	end
	self.SpawnTime = CurTime() + cvar_delay:GetFloat()
end

-- From Moneyprinter
ENT.DoSpawn = false
ENT.SpawnTime = 0
function ENT:Think()
	BaseClass.Think(self)
	if (not self.DoSpawn) then
		return
	end
	local ctime = CurTime()
	if (self.SpawnTime < ctime) then
		self:SpawnAmount(self.DoSpawn)
		self.DoSpawn = false
		return
	end

	local effectdata = EffectData()
	effectdata:SetOrigin(self:GetPos())
	effectdata:SetMagnitude(1)
	effectdata:SetScale(1)
	effectdata:SetRadius(2)
	util.Effect("Sparks", effectdata)
end

function ENT:OnRemove()
	self:SpawnAll(true)
	BaseClass.OnRemove(self)
end

function ENT:TriggerInput(key, value)
	if (key == "SpawnAll" and value ~= 0) then
		self:SpawnAll(false)
	elseif (key == "SpawnAmount" and value > 0) then
		self:DelayedSpawn(value)
	end
end

function ENT:OnEntityCopyTableFinish(data)
	if (data.DT) then
		data.DT.Money = 0
	end
end

function ENT:OnDuplicated(data)
	self:SetMoney(0)
	-- AdvDupe restores DTVars *AFTER* calling this function 😒
	if (data.DT) then
		data.DT.Money = 0
	end
end

function ENT:PostEntityPaste()
	self:SetMoney(0)
end
