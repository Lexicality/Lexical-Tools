--[[
	Fading Doors
    Copyright 2012-2013 Lex Robinson

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

local IsValid, pairs, CurTime, print = IsValid, pairs, CurTime, print

local WireLib, numpad, duplicator, timer = WireLib, numpad, duplicator, timer

module("fadingdoors")

local config = {material = "sprites/heatwave", mintime = false}

local function IsFading(ent)
	return IsValid(ent) and ent.isFadingDoor
end

local function mintimeTimer(ent)
	if (IsFading(ent)) then
		ent._fade.mintimeTimer = false
		ent._fade.fadeTime = false
		Unfade(ent)
	end
end

local function wireTriggerInput(ent, name, value)
	if (not IsFading(ent) or name ~= "fade") then
		return false
	end
	if (value == 0) then
		InputOff(ent)
	else
		InputOn(ent)
	end
	return true
end

local function wirePreEntityCopy(ent)
	local info = WireLib.BuildDupeInfo(ent)
	if (info) then
		duplicator.StoreEntityModifier(ent, "WireDupeInfo", info)
	end
end

-- ~wow~ so much easier than using entity modifiers properly!
local function wirePostEntityPaste(ent, ply, _, ents)
	if (ent.EntityMods and ent.EntityMods["WireDupeInfo"]) then
		WireLib.ApplyDupeInfo(
			ply, ent, ent.EntityMods["WireDupeInfo"], function(id)
				return ents[id]
			end
		)
	end
end

local function onRemove(ent)
	if (not ent._fade) then
		return
	end
	numpad.Remove(ent._fade.numpadUp)
	numpad.Remove(ent._fade.numpadDn)
end

---------------
-- INTERFACE --
---------------
function Fade(ent)
	if (not IsFading(ent) or ent._fade.active) then
		return
	end
	ent._fade.active = true
	ent._fade.material = ent:GetMaterial()
	ent._fade.fadeTime = CurTime()

	ent:SetMaterial(config.material)
	ent:DrawShadow(false)
	ent:SetNotSolid(true)

	if (WireLib) then
		WireLib.TriggerOutput(ent, "FadeActive", 1)
	end

	local phys = ent:GetPhysicsObject()
	if (not IsValid(phys)) then
		return
	end
	ent._fade.unfrozen = phys:IsMoveable()
	ent._fade.velocity = phys:GetVelocity()
	ent._fade.angvel = phys:GetAngleVelocity()
	phys:EnableMotion(false)
end

function Unfade(ent)
	if (not IsFading(ent) or not ent._fade.active or ent._fade.mintimeTimer) then
		return
	end
	if (config.mintime and ent._fade.fadeTime) then
		local t = ent._fade.fadeTime + config.mintime
		local c = CurTime()
		if (t > c) then
			ent._fade.mintimeTimer = true
			timer.Simple(
				t - c, function()
					mintimeTimer(ent)
				end
			)
			return
		end
	end

	ent._fade.active = false
	ent:SetMaterial(ent._fade.material)
	ent:DrawShadow(true)
	ent:SetNotSolid(false)

	if (WireLib) then
		WireLib.TriggerOutput(ent, "FadeActive", 1)
	end

	local phys = ent:GetPhysicsObject()
	if (not IsValid(phys)) then
		return
	end
	phys:EnableMotion(ent._fade.unfrozen)
	if (not ent._fade.unfrozen) then
		return
	end
	phys:Wake()
	phys:SetVelocityInstantaneous(ent._fade.velocity or vector_origin)
	phys:AddAngleVelocity(ent._fade.angvel or vector_origin)
end

function Toggle(ent)
	if (not IsFading(ent)) then
		return
	end
	if (ent._fade.active) then
		print(ent, "Toggle! Setting to off")
		Unfade(ent)
	else
		print(ent, "Toggle! Setting to on")
		Fade(ent)
	end
end

function InputOn(ent)
	print("InputOn", ent, IsFading(ent), ent._fade and ent._fade.debounce)
	if (not IsFading(ent) or ent._fade.debounce) then
		return
	end
	ent._fade.debounce = true
	Toggle(ent)
end

function InputOff(ent)
	print("InputOff", ent, IsFading(ent), ent._fade and ent._fade.debounce)
	if (not IsFading(ent) or not ent._fade.debounce) then
		return
	end
	ent._fade.debounce = false
	if (not ent._fade.toggle) then -- Toggle fires on the On event, not Off.
		Toggle(ent)
	end
end

function SetConfig(key, value)
	if (value == nil) then
		return
	end
	if (key == "mintime" and value <= 0) then
		value = false
	end
	if (config[key] ~= nil) then
		config[key] = value
	end
end

function GetConfig(key)
	return config[key]
end

function SetupDoor(owner, ent, data)
	if (not (IsValid(owner) and IsValid(ent))) then
		return
	end
	if (IsFading(ent)) then
		Unfade(ent)
		onRemove(ent) -- Kill the old numpad func
	else
		CreateDoorFunctions(ent)
	end
	ent._fade.numpadUp = numpad.OnUp(owner, data.key, "Fading Doors onUp", ent)
	ent._fade.numpadDn = numpad.OnDown(owner, data.key, "Fading Doors onDown", ent)
	ent._fade.toggle = data.toggle
	if (data.reversed) then
		Fade(ent)
	end
	duplicator.StoreEntityModifier(ent, "Fading Door", data)
end

function CreateDoorFunctions(ent)
	if (not IsValid(ent)) then
		return
	end
	-- Legacy
	ent.isFadingDoor = true
	ent.fadeActivate = Fade
	ent.fadeDeactivate = Unfade
	ent.fadeToggleActive = Toggle
	ent.fadeInputOn = InputOn
	ent.fadeInputOff = InputOff
	-- Unlegacy
	ent._fade = {}
	ent:CallOnRemove("Fading Doors", onRemove)
	if (not WireLib) then
		return
	end
	local pfuncs = {}
	ent._fade.pfuncs = pfuncs
	WireLib.AddInputs(ent, {"Fade"})
	WireLib.AddOutputs(ent, {"FadeActive"})
	do
		local TriggerInput = ent.TriggerInput
		pfuncs.TriggerInput = TriggerInput or false -- For cleanup
		function ent.TriggerInput(...)
			if (not wireTriggerInput(...) and TriggerInput) then
				TriggerInput(...)
			end
		end
	end
	-- Make the entity support being duped by wire
	if (ent.IsWire or ent.addedWireSupport) then
		return
	end
	ent.addedWireSupport = true
	-- Add WireLib's dupe stuff
	do
		local PreEntityCopy = ent.PreEntityCopy
		pfuncs.PreEntityCopy = PreEntityCopy or false
		function ent.PreEntityCopy(ent)
			wirePreEntityCopy(ent)
			if (PreEntityCopy) then
				PreEntityCopy(ent)
			end
		end
	end
	do
		local PostEntityPaste = ent.PostEntityPaste
		pfuncs.PostEntityPaste = PostEntityPaste or false
		function ent.PostEntityPaste(...)
			wirePostEntityPaste(...)
			if (PostEntityPaste) then
				PostEntityPaste(...)
			end
		end
	end
end

function RemoveDoor(ent)
	print("RemoveDoor", ent, IsValid(ent), IsFading(ent))
	if (not IsFading(ent)) then
		return
	end
	onRemove(ent)
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
	ent._fade = nil
	duplicator.ClearEntityModifier(ent, "Fading Door")
	if (WireLib) then
		WireLib.RemoveInputs(ent, {"Fade"})
		WireLib.RemoveOutputs(ent, {"FadeActive"})
	end
	return true
end

numpad.Register(
	"Fading Doors onUp", function(_, ent)
		InputOff(ent)
	end
)
numpad.Register(
	"Fading Doors onDown", function(_, ent)
		InputOn(ent)
	end
)

local function entMod(ply, ent, data)
	-- Ensure the duplicator hasn't copied any fields that are going to confuse us
	ent.isFadingDoor = nil
	ent._fade = nil
	SetupDoor(ply, ent, data)
end
duplicator.RegisterEntityModifier("Fading Door", entMod)

-- I wish I had a way to gather metrics, I'm pretty sure this hasn't been necessary for a decade
local function legacyEntMod(ply, ent, data)
	if not ent.EntityMods["Fading Door"] then
		SetupDoor(
			ply, ent, {key = data.Key, toggle = data.Toggle, reversed = data.Inverse}
		)
	end
	duplicator.ClearEntityModifier("FadingDoor")
end
duplicator.RegisterEntityModifier("FadingDoor", legacyEntMod)
