--[[
	Fading Doors - lua\includes\modules\fading_doors.lua
    Copyright 2012-2020 Lex Robinson

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
if (CLIENT) then
	return
end

require("wirefixes")

local CurTime = CurTime
local IsValid = IsValid
local WireLib = WireLib
local duplicator = duplicator
local numpad = numpad
local pairs = pairs
local print = print
local timer = timer
local tobool = tobool
local tonumber = tonumber

module("fading_doors")

local WIRE_ENT_FUNCTIONS = {
	"ApplyDupeInfo",
	"BuildDupeInfo",
	"PostEntityPaste",
	"PreEntityCopy",
}

local config = {
	material = "sprites/heatwave",
	-- Some servers need fading doors to stay open for a certain number of
	-- seconds due to base rules
	mintime = false,
	-- If props should be awoken when unfaded
	physpersist = false,
}

---
--- Sets a config value to take immediate effect
--- Does not persist, ignores unknown keys.
--- @param key string
--- @param value any
function SetConfig(key, value)
	if value == nil or config[key] == nil then
		return
	end
	if key == "mintime" then
		value = tonumber(value)
		if not value or value <= 0 then
			value = false
		end
	elseif key == "physpersist" then
		value = tobool(value)
	end
	config[key] = value
end

---
--- Returns a single config value
--- @param key string
--- @return any
function GetConfig(key)
	return config[key]
end

---
--- Checks if an entity is a fading door
--- @param ent GEntity
--- @return boolean
function IsFading(ent)
	return IsValid(ent) and ent.isFadingDoor
end

--- @param ent GEntity
local function removeNumpadBindings(ent)
	if (not ent._fade) then
		return
	end
	numpad.Remove(ent._fade.numpadUp)
	numpad.Remove(ent._fade.numpadDn)
end

---------------
-- INTERFACE --
---------------

--- Triggers a fading door to fade
--- Does nothing if the entity is not a fading door, or is already faded
--- @param ent GEntity
function Fade(ent)
	if (not IsFading(ent) or ent._fade.active) then
		return
	end

	if (WireLib) then
		WireLib.TriggerOutput(ent, "FadeActive", 1)
	end

	ent._fade.active = true
	ent._fade.material = ent:GetMaterial()
	ent._fade.fadeTime = CurTime()

	ent:SetMaterial(config.material)
	ent:DrawShadow(false)

	local phys = ent:GetPhysicsObject()
	if not ent._fade.canDisableMotion or not IsValid(phys) then
		ent._fade.collisionGroup = ent:GetCollisionGroup()
		ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
		return
	end

	ent._fade.unfrozen = phys:IsMoveable()
	ent._fade.unfreezable = ent:GetUnFreezable()

	ent:SetNotSolid(true)
	phys:EnableMotion(false)
	ent:SetUnFreezable(true)
end

--- @param ent GEntity
local function unfadeTimer(ent)
	if (not IsFading(ent)) then
		return
	end

	ent._fade.mintimeTimer = false
	-- Make sure we don't accidentally re-run the timer
	ent._fade.fadeTime = false
	Unfade(ent)
end

--- Triggers a fading door to ufade
--- Does nothing if the entity is not a fading door, or is already unfaded.
--- If the server has a minimum fade time set, this will not take action immediately.
--- @param ent GEntity
function Unfade(ent)
	if (not IsFading(ent) or not ent._fade.active or ent._fade.mintimeTimer) then
		return
	end
	-- Check if we need to hold the door open for a while longer
	if (config.mintime and ent._fade.fadeTime) then
		local fadeEnd = ent._fade.fadeTime + config.mintime
		local curTime = CurTime()
		if (fadeEnd > curTime) then
			-- Prevent the timer happening multiple times
			ent._fade.mintimeTimer = true
			timer.Simple(
				fadeEnd - curTime, function()
					unfadeTimer(ent)
				end
			)
			return
		end
	end

	if (WireLib) then
		WireLib.TriggerOutput(ent, "FadeActive", 0)
	end

	ent._fade.active = false
	ent:SetMaterial(ent._fade.material)
	ent:DrawShadow(true)

	local phys = ent:GetPhysicsObject()
	if not ent._fade.canDisableMotion or not IsValid(phys) then
		ent:SetCollisionGroup(ent._fade.collisionGroup or COLLISION_GROUP_NONE)
		return
	end

	ent:SetNotSolid(false)
	ent:SetUnFreezable(ent._fade.unfreezable)

	-- Check if the server has decided not to let doors unfreeze themselves
	if not config.physpersist then
		return
	end

	phys:EnableMotion(ent._fade.unfrozen)
	if ent._fade.unfrozen then
		phys:Wake()
	end
end

--- Triggers a fading door to toggle its fade state
--- Does nothing if the entity is not a fading door
--- If the server has a minimum fade time set, this may not take action immediately.
--- @param ent GEntity
function Toggle(ent)
	if (not IsFading(ent)) then
		return
	end
	if (ent._fade.active) then
		Unfade(ent)
	else
		Fade(ent)
	end
end

--- Used for button etc inputs
--- Does nothing if the entity is not a fading door
--- @param ply nil @unused
--- @param ent GEntity
function InputOn(ply, ent)
	if (not IsFading(ent) or ent._fade.debounce) then
		return
	end
	ent._fade.debounce = true
	Toggle(ent)
end

--- Used for button etc inputs
--- Does nothing if the entity is not a fading door
--- @param ply nil @unused
--- @param ent GEntity
function InputOff(ply, ent)
	if (not IsFading(ent) or not ent._fade.debounce) then
		return
	end
	ent._fade.debounce = false
	if (not ent._fade.toggle) then -- Toggle fires on the On event, not Off.
		Toggle(ent)
	end
end

--- @param ent GEntity
--- @param name string
--- @param value any
local function wireTriggerInput(ent, name, value)
	if name ~= "fade" then
		return false
	end
	if value ~= 0 then
		InputOn(NULL, ent)
	else
		InputOff(NULL, ent)
	end
	return true
end

--- @param ent GEntity
local function setupWire(ent)
	if (not WireLib) then
		return
	end
	local pfuncs = {}
	ent._fade.pfuncs = pfuncs
	WireLib.AddInputs(ent, {"Fade"})
	WireLib.AddOutputs(ent, {"FadeActive"})
	do
		local original = ent.TriggerInput
		if original then
			pfuncs.TriggerInput = original
			function ent.TriggerInput(...)
				if (not wireTriggerInput(...)) then
					original(...)
				end
			end
		else
			pfuncs.TriggerInput = false
			ent.TriggerInput = wireTriggerInput
		end
	end
	-- Make the entity support being duped by wire
	if (ent.IsWire or ent.addedWireSupport) then
		return
	end
	ent.addedWireSupport = true
	-- Add WireLib's dupe stuff
	local base_wire_entity = scripted_ents.GetStored("base_wire_entity").t
	for _, name in pairs(WIRE_ENT_FUNCTIONS) do
		local original = ent[name]
		local wire = base_wire_entity[name]
		if original then
			pfuncs[name] = original
			ent[name] = function(...)
				wire(...)
				original(...)
			end
		else
			pfuncs[name] = false
			ent[name] = wire
		end
	end
end

--- @param ent GEntity
local function createDoorFunctions(ent)
	if (not IsValid(ent)) then
		return
	end
	-- Legacy
	ent.isFadingDoor = true
	ent.fadeActivate = Fade
	ent.fadeDeactivate = Unfade
	ent.fadeToggleActive = Toggle
	-- Unlegacy
	ent._fade = {}
	ent:CallOnRemove("Fading Door", removeNumpadBindings)
end

--- Configures an entity to be a fading door.
--- If it is already a fading door, all the settings will be updated.
--- @param ply GPlayer
--- @param ent GEntity
--- @param data table
function SetupDoor(ply, ent, data)
	if not IsValid(ent) then
		return
	end

	if (IsFading(ent)) then
		Unfade(ent)
		removeNumpadBindings(ent) -- Kill the old numpad func
	else
		createDoorFunctions(ent)
		setupWire(ent)
	end

	-- I got this from Panthera Tigris' version of the tool
	-- I'm not entirely sure when this could happen, but it looks like a bug fix
	-- so I'm going to keep it.
	if data.CanDisableMotion == nil then
		data.CanDisableMotion = false
		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			local motionEnabled = phys:IsMotionEnabled()
			phys:EnableMotion(not motionEnabled)
			data.CanDisableMotion = motionEnabled ~= phys:IsMotionEnabled()
			phys:EnableMotion(motionEnabled)
		end
	end
	ent._fade.canDisableMotion = data.CanDisableMotion

	if IsValid(ply) then
		ent._fade.numpadUp = numpad.OnUp(ply, data.key, "Fading Doors onUp", ent)
		ent._fade.numpadDn = numpad.OnDown(ply, data.key, "Fading Doors onDown", ent)
	end

	ent._fade.toggle = data.toggle
	if (data.reversed) then
		Fade(ent)
	end
	duplicator.StoreEntityModifier(ent, "Fading Door", data)
end

--- Removes all fading door features from an entity
--- Does nothing if the entity is not a fading door
--- @param ent GEntity
function RemoveDoor(ent)
	if (not IsFading(ent)) then
		return
	end
	removeNumpadBindings(ent)
	ent:RemoveCallOnRemove("Fading Door")
	Unfade(ent)
	ent.isFadingDoor = nil
	ent.fadeActivate = nil
	ent.fadeDeactivate = nil
	ent.fadeToggleActive = nil
	ent.fadeInputOn = nil
	ent.fadeInputOff = nil
	if (ent._fade.pfuncs) then
		for key, func in pairs(ent._fade.pfuncs) do
			if (not func) then
				func = nil
			end
			ent[key] = func
		end
	end
	ent.addedWireSupport = nil
	ent._fade = nil
	duplicator.ClearEntityModifier(ent, "Fading Door")
	if (WireLib) then
		WireLib.RemoveInputs(ent, {"Fade"})
		WireLib.RemoveOutputs(ent, {"FadeActive"})
	end
	return true
end

numpad.Register("Fading Doors onUp", InputOff)
numpad.Register("Fading Doors onDown", InputOn)

--- @param ply GPlayer
--- @param ent GEntity
--- @param data table
local function entMod(ply, ent, data)
	-- Ensure the duplicator hasn't copied any fields that are going to confuse us
	ent.isFadingDoor = nil
	ent._fade = nil
	SetupDoor(ply, ent, data)
end
duplicator.RegisterEntityModifier("Fading Door", entMod)

-- I wish I had a way to gather metrics, I'm pretty sure this hasn't been necessary for a decade
--- @param ply GPlayer
--- @param ent GEntity
--- @param data table
local function legacyEntMod(ply, ent, data)
	if not ent.EntityMods["Fading Door"] then
		SetupDoor(
			ply, ent, {key = data.Key, toggle = data.Toggle, reversed = data.Inverse}
		)
	end
	duplicator.ClearEntityModifier("FadingDoor")
end
duplicator.RegisterEntityModifier("FadingDoor", legacyEntMod)
