--[[
	Weapon Spawn Platforms
	Copyright (c) 2016 Lex Robinson
	This code is freely available under the MIT License
]]
AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Weapon Spawner (simple)"
ENT.WireDebugName = "Weapon Spawner (simple)"
ENT.Author = "Lex Robinson"
ENT.Contact = "lexi@lexi.org.uk"
ENT.Purpose = "Spawn weapons for survival maps"
ENT.Category = "Fun + Games"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Editable = true

DEFINE_BASECLASS "base_lexentity"

duplicator.Allow("sent_weapons_store_simple")

ENT._NWVars = {
	{
		Name = "SpawnOnce",
		Type = "Bool",
		KeyName = "once",
		Edit = {title = "Only Spawn One", type = "Boolean", order = 2},
	},
	{
		Name = "Weapon",
		Type = "String",
		KeyName = "weapon",
		Edit = {
			title = "Weapon to spawn",
			type = "Generic",
			order = 1,
			waitforenter = true,
		},
	},
	{
		Name = "Delay",
		Type = "Float",
		KeyName = "spawndelay",
		Edit = {
			title = "Delay Between Spawns (seconds)",
			type = "Float",
			order = 3,
			min = 0,
			max = 60,
		},
	},
	-- Helpers for maps
	{Name = "Invisible", Type = "Bool", KeyName = "hidden"},
	{Name = "Unfrozen", Type = "Bool", KeyName = "movable"},
	-- Self help
	{Name = "NumSpawned", Type = "Int"},
}

if (CLIENT) then
	return
end

function ENT:Initialize()
	if (BaseClass.Initialize) then
		BaseClass.Initialize(self)
	end

	self.NextSpawn = 0
	self.CurrentWeapon = NULL

	self:SetModel("models/props_c17/streetsign004e.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if (not IsValid(phys)) then
		ErrorNoHalt("No physics object for ", tostring(self), " using model ",
			self:GetModel(), "?\n")
	else
		phys:Wake()
		phys:EnableMotion(self:GetUnfrozen())
	end

	-- Deal with stupid permaprop style libraries
	self:SetNumSpawned(0)

	self:CreateWireInputs({
		{Name = "SpawnOne", Desc = "Spawn a weapon immediately"},
		{Name = "RemoveCurrentWeapon", Desc = "Deletes the currently spawned weapon"},
		{
			Name = "SetWeaponClass",
			Desc = "Picks the class of weapon to spawn",
			Type = "String",
		},
		{Name = "SetDelay", Desc = "Sets the delay between spawns"},
	})

	self:CreateWireOutputs({
		{
			Name = "CurrentWeapon",
			Type = "Entity",
			Desc = "The currently spawned weapon",
		},
		{Name = "NumSpawned", Desc = "Lifetime number of weapons spawned"},
		{Name = "OnWeaponSpawned", Desc = "Triggered when a new weapon is spawned"},
	})
end

function ENT:RegisterListeners()
	self:NetworkVarNotify("Invisible", function(self, _, _, shouldNotDraw)
		self:SetNoDraw(shouldNotDraw)
	end)

	self:NetworkVarNotify("Unfrozen", function(self, _, _, shouldMove)
		local phys = self:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableMotion(shouldMove)
		end
	end)

	self:NetworkVarNotify("Weapon", function(self, _, old, new)
		if (new ~= old) then
			self:RemoveWeapon(true)
		end
	end)

	if (WireLib) then
		self:NetworkVarNotify("NumSpawned", function(self, _, _, num)
			self:TriggerWireOutput("NumSpawned", num)
		end)
	end
end

function ENT:Think()
	if (BaseClass.Think) then
		BaseClass.Think(self)
	end

	-- Crude pickup detection
	if (IsValid(self.CurrentWeapon)) then
		if (not IsValid(self.CurrentWeapon:GetOwner())) then
			return
		end

		self:RemoveWeapon(false)
	end
	-- one-shot platforms
	if (self:GetSpawnOnce() and self:GetNumSpawned() > 0) then
		return
	end
	-- Delays
	if (self.NextSpawn > CurTime()) then
		return
	end

	self:SpawnWeapon()
end

local onremovekey = "weapon platform sanity"
local function onWepRemoved(wep, platform)
	if (IsValid(platform) and platform.CurrentWeapon == wep) then
		platform:RemoveWeapon(false)
	end
end

---
-- Spawn a new weapon into the world
function ENT:SpawnWeapon()
	-- Validation
	local weapon = self:GetWeapon()
	if (not weapon or weapon == "") then
		return
	end

	local ent = ents.Create(weapon)
	if (not IsValid(ent)) then
		ErrorNoHalt("Attempted to create weapon of unknown class '", weapon, "'!")
		self.NextSpawn = CurTime() + 10
		return
	end
	ent:SetPos(self:GetPos() + self:GetRight() * -20)
	ent:SetAngles(self:GetAngles())
	ent:SetParent(self)
	self:DeleteOnRemove(ent)
	ent:CallOnRemove(onremovekey, onWepRemoved, self)
	ent:Spawn()
	ent:Activate()

	self.CurrentWeapon = ent

	self:SetNumSpawned(self:GetNumSpawned() + 1)

	self:TriggerOutput("spawned", self)
	self:TriggerWireOutput("CurrentWeapon", ent)
	self:TriggerWireOutput("OnWeaponSpawned", 1)
	self:TriggerWireOutput("OnWeaponSpawned", 0)
end

---
-- Kills the current spawned weapon and delays the spawn of the netxt one
-- @param {bool} dontUpdateDelay Don't delay the spawn. This will probably spawn a new weapon immediately, unless there's already a delay.=
function ENT:RemoveWeapon(dontUpdateDelay)
	if (IsValid(self.CurrentWeapon)) then
		if (not IsValid(self.CurrentWeapon:GetOwner())) then
			self.CurrentWeapon:Remove()
		else
			self:DontDeleteOnRemove(self.CurrentWeapon)
			self.CurrentWeapon:RemoveCallOnRemove(onremovekey)
			self.CurrentWeapon = NULL
		end
	end

	if (not dontUpdateDelay) then
		self.NextSpawn = CurTime() + self:GetDelay()
	end
end

function ENT:TriggerInput(name, val)
	if (BaseClass.TriggerInput) then
		BaseClass.TriggerInput(self, name, val)
	end

	if (name == "SpawnOne" and val ~= 0) then
		self:RemoveWeapon()
		self:SpawnWeapon()
	elseif (name == "RemoveCurrentWeapon" and val ~= 0) then
		self:RemoveWeapon()
	elseif (name == "SetWeaponClass" and val ~= "") then
		self:SetWeapon(val)
	elseif (name == "SetDelay" and val >= 0) then
		self:SetDelay(val)
	end
end

function ENT:AcceptInput(input, activator, called, data)
	if (BaseClass.AcceptInput) then
		BaseClass.AcceptInput(self, input, activator, called, data)
	end
	input = input:lower()

	if (input == "spawn") then
		self:RemoveWeapon()
		self:SpawnWeapon()
	elseif (input == "killweapon") then
		self:RemoveWeapon()
	end
end

function ENT:OnDuplicated(entTable)
	if (BaseClass.OnDuplicated) then
		BaseClass.OnDuplicated(self, entTable)
	end
	-- Reset lifetime vars
	self:SetNumSpawned(0)
	self.NextSpawn = 0
	self.CurrentWeapon = NULL
end

function ENT:SpawnFunction(ply, tr)
	if (not tr.Hit) then
		return
	end
	local ent = ents.Create(self.ClassName)
	ent:SetPos(tr.HitPos)
	local a = tr.HitNormal:Angle()
	a.roll = a.roll + 90
	a.pitch = a.pitch + 90
	ent:SetAngles(a)
	ent:Spawn()
	ent:Activate()
	-- Attempt to move the object so it sits flush
	local vFlushPoint = tr.HitPos - (tr.HitNormal * 512) -- Find a point that is definitely out of the object in the direction of the floor
	vFlushPoint = ent:NearestPoint(vFlushPoint) -- Find the nearest point inside the object to that point
	vFlushPoint = ent:GetPos() - vFlushPoint -- Get the difference
	vFlushPoint = tr.HitPos + vFlushPoint -- Add it to our target pos
	ent:SetPos(vFlushPoint)
	return ent
end
