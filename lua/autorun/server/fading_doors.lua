--[[
	Fading Doors - lua\autorun\server\fading_doors.lua
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
require("wirefixes")

_G.fading_doors = _G.fading_doors or {}

local WIRE_ENT_FUNCTIONS = {
	"ApplyDupeInfo",
	"BuildDupeInfo",
	"PostEntityPaste",
	"PreEntityCopy",
}

if not fading_doors._config then
	fading_doors._config = {
		material = "sprites/heatwave",
		-- Some servers need fading doors to stay open for a certain number of
		-- seconds due to base rules
		mintime = false,
		-- If props should be awoken when unfaded
		physpersist = false,
	}
end

---
--- Sets a config value to take immediate effect
--- Does not persist, ignores unknown keys.
--- @param key string
--- @param value any
function fading_doors.SetConfig(key, value)
	if value == nil or fading_doors._config[key] == nil then
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
	fading_doors._config[key] = value
end

---
--- Returns a single config value
--- @param key string
--- @return any
function fading_doors.GetConfig(key)
	return fading_doors._config[key]
end

---
--- Checks if an entity is a fading door
--- @param ent GEntity
--- @return boolean
function fading_doors.IsFading(ent)
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
function fading_doors.Fade(ent)
	if (not fading_doors.IsFading(ent) or ent._fade.active) then
		return
	end

	if (WireLib) then
		WireLib.TriggerOutput(ent, "FadeActive", 1)
	end

	ent._fade.active = true
	ent._fade.material = ent:GetMaterial()
	ent._fade.fadeTime = CurTime()

	ent:SetMaterial(fading_doors._config.material)
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
	if not (fading_doors.IsFading(ent) and ent._fade.mintimeTimer) then
		return
	end

	ent._fade.mintimeTimer = false
	fading_doors.Unfade(ent, true)
end

--- Triggers a fading door to ufade
--- Does nothing if the entity is not a fading door, or is already unfaded.
--- If the server has a minimum fade time set, this will not take action immediately.
--- @param ent GEntity
--- @param force boolean
function fading_doors.Unfade(ent, force)
	if not fading_doors.IsFading(ent) or not ent._fade.active then
		return
	end

	-- If we're already going to unfade soon, don't do anything
	if not force and ent._fade.mintimeTimer then
		return
	end

	-- Check if we need to hold the door open for a while longer
	if not force and fading_doors._config.mintime and ent._fade.fadeTime then
		local fadeEnd = ent._fade.fadeTime + fading_doors._config.mintime
		local curTime = CurTime()
		if (fadeEnd > curTime) then
			-- Prevent the timer happening multiple times
			ent._fade.mintimeTimer = true
			timer.Simple(fadeEnd - curTime, function()
				unfadeTimer(ent)
			end)
			return
		end
	end

	ent._fade.mintimeTimer = false

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
	if not fading_doors._config.physpersist then
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
function fading_doors.Toggle(ent)
	if (not fading_doors.IsFading(ent)) then
		return
	end
	if (ent._fade.active) then
		fading_doors.Unfade(ent)
	else
		fading_doors.Fade(ent)
	end
end

--- Used for button etc inputs
--- Does nothing if the entity is not a fading door
--- @param ply nil @unused
--- @param ent GEntity
function fading_doors.InputOn(ply, ent)
	if not fading_doors.IsFading(ent) or ent._fade.debounce then
		return
	end

	ent._fade.debounce = true

	if ent._fade.toggle then
		fading_doors.Toggle(ent)
	elseif ent._fade.reversed then
		fading_doors.Unfade(ent)
	else
		fading_doors.Fade(ent)
	end
end

--- Used for button etc inputs
--- Does nothing if the entity is not a fading door
--- @param ply nil @unused
--- @param ent GEntity
function fading_doors.InputOff(ply, ent)
	if not fading_doors.IsFading(ent) or not ent._fade.debounce then
		return
	end

	ent._fade.debounce = false

	if ent._fade.toggle then
		-- Toggle fires on the On event, not Off.
	elseif ent._fade.reversed then
		fading_doors.Fade(ent)
	else
		fading_doors.Unfade(ent)
	end
end

--- @param ent GEntity
--- @param name string
--- @param value any
local function wireTriggerInput(ent, name, value)
	if string.lower(name) ~= "fade" then
		return false
	end
	if value ~= 0 then
		fading_doors.InputOn(NULL, ent)
	else
		fading_doors.InputOff(NULL, ent)
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
	-- I don't like it, but this is the API I published and you can't break APIs
	-- or people won't update their addons, so I guess we're stuck with these
	-- functions forever.
	ent.isFadingDoor = true
	ent.fadeActivate = fading_doors.Fade
	ent.fadeDeactivate = fading_doors.Unfade
	ent.fadeToggleActive = fading_doors.Toggle
	-- I'm going to put all the data in here and hope no one was expecting it to
	-- be on the entity directly.
	ent._fade = {}
	ent:CallOnRemove("Fading Door", removeNumpadBindings)
end

--- Configures an entity to be a fading door.
--- If it is already a fading door, all the settings will be updated.
--- @param ply GPlayer
--- @param ent GEntity
--- @param data table
function fading_doors.SetupDoor(ply, ent, data)
	if not IsValid(ent) then
		return
	end

	if (fading_doors.IsFading(ent)) then
		fading_doors.Unfade(ent, true)
		removeNumpadBindings(ent) -- Kill the old numpad func
	else
		createDoorFunctions(ent)
		setupWire(ent)
	end

	ent._fade.reversed = data.reversed
	ent._fade.toggle = data.toggle

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

	-- It's possible that we could spawn a dupe of an active fading door.
	-- It could be active because
	-- - The user was holding down a button when they duped it
	-- - A wire signal was holding it open
	-- - It was a toggle door
	-- We're going to reset it to not open because
	-- - There's no way to know if they're still holding down the button
	-- - Wire will re-trigger the input immediately after this function returns
	-- - I can't think of a clean way of handling toggles
	-- I'm sure the user won't mind.
	if data._fade and data._fade.active then
		local newFade = ent._fade
		ent._fade = data._fade
		fading_doors.Unfade(ent, true)
		ent._fade = newFade
	end

	if (data.reversed) then
		fading_doors.Fade(ent)
	end

	data._fade = ent._fade
	duplicator.StoreEntityModifier(ent, "Fading Door", data)
end

--- Removes all fading door features from an entity
--- Does nothing if the entity is not a fading door
--- @param ent GEntity
function fading_doors.RemoveDoor(ent)
	if (not fading_doors.IsFading(ent)) then
		return
	end
	removeNumpadBindings(ent)
	ent:RemoveCallOnRemove("Fading Door")
	fading_doors.Unfade(ent)
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

numpad.Register("Fading Doors onUp", fading_doors.InputOff)
numpad.Register("Fading Doors onDown", fading_doors.InputOn)

--- @param ply GPlayer
--- @param ent GEntity
--- @param data table
local function entMod(ply, ent, data)
	-- Depending on what we've added a fading door to, we may or may not have
	-- our members preserved.
	-- To enforce consistency, preserve nothing
	ent.isFadingDoor = nil
	ent._fade = nil

	-- Exciting hack to make materials work
	local matmod = ent.EntityMods["material"]
	if matmod then
		duplicator.EntityModifiers["material"](ply, ent, matmod)
		ent.EntityMods["material"] = nil
		timer.Simple(0.1, function()
			if IsValid(ent) then
				ent.EntityMods["material"] = matmod
			end
		end)
	end

	fading_doors.SetupDoor(ply, ent, data)
end
duplicator.RegisterEntityModifier("Fading Door", entMod)

-- I wish I had a way to gather metrics, I'm pretty sure this hasn't been necessary for a decade
--- @param ply GPlayer
--- @param ent GEntity
--- @param data table
local function legacyEntMod(ply, ent, data)
	if not ent.EntityMods["Fading Door"] then
		fading_doors.SetupDoor(ply, ent, {
			key = data.Key,
			toggle = data.Toggle,
			reversed = data.Inverse,
		})
	end
	duplicator.ClearEntityModifier("FadingDoor")
end
duplicator.RegisterEntityModifier("FadingDoor", legacyEntMod)
