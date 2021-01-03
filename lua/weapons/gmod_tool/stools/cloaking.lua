--[[
	Lexical Tools - lua\weapons\gmod_tool\stools\cloaking.lua
	Copyright 2010-2013 Lex Robinson
	It's fading doors but you can't walk through it

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
TOOL.Name = "Cloaking"
TOOL.Author = "Lexi"
TOOL.Category = "Lexical Tools"

TOOL.ClientConVar["key"] = "5"
TOOL.ClientConVar["flicker"] = "0"
TOOL.ClientConVar["toggle"] = "1"
TOOL.ClientConVar["reversed"] = "0"
TOOL.ClientConVar["all"] = "1"
TOOL.ClientConVar["material"] = "sprites/heatwave"

local function checkTrace(tr)
	return IsValid(tr.Entity) and not (tr.Entity:IsPlayer() or tr.Entity:IsNPC())
end

if (CLIENT) then
	usermessage.Hook("CloakingHurrah!", function()
		GAMEMODE:AddNotify("Entity is now cloakable!", NOTIFY_GENERIC, 10)
		surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
	end)
	language.Add("Tool_cloaking_name", "Cloaking")
	language.Add("Tool_cloaking_desc",
             	"Allows you to turn things invisible at the touch of a button")
	language.Add("Tool_cloaking_0",
             	"Click on something to make it a cloakable. Reload to remove cloaking from something.")
	language.Add("Undone_cloaking", "Undone Cloaking")

	list.Set("CloakingMaterials", "Heatwave", "sprites/heatwave")
	list.Set("CloakingMaterials", "Light", "models/effects/vol_light001")

	function TOOL.BuildCPanel(panel)
		-- Header
		panel:CheckBox("Inverted Controls", "cloaking_reversed")
		panel:CheckBox("Flicker on damage", "cloaking_flicker")
		panel:CheckBox("Toggle Controls", "cloaking_toggle")
		panel:CheckBox("Cloak constrained entities", "cloaking_all")

		panel:AddControl("Numpad", {Label = "Button", Command = "cloaking_key"})
		local options = {}
		for name, material in pairs(list.Get("CloakingMaterials")) do
			options[name] = {cloaking_material = material}
		end
		panel:AddControl("Listbox",
                 		{Label = "Material:", Height = 120, Options = options})
	end

	TOOL.LeftClick = checkTrace

	return
end

require("wirefixes")

local function cloakActivate(self)
	if (self.cloakActive) then
		return
	end
	self.cloakActive = true
	self.cloakPreviousMaterial = self:GetMaterial()
	self:SetMaterial(self.cloakMaterial)
	self:DrawShadow(false)
	if (WireLib) then
		Wire_TriggerOutput(self, "CloakActive", 1)
	end
end

local function cloakDeactivate(self)
	if (not self.cloakActive) then
		return
	end
	self.cloakActive = false
	self:SetMaterial(self.cloakPreviousMaterial or "")
	self:DrawShadow(true)
end

local function cloakToggleActive(self)
	if (self.cloakActive) then
		self:cloakDeactivate()
	else
		self:cloakActivate()
	end
end

local function onDown(ply, ent)
	if (not (ent:IsValid() and ent.cloakToggleActive)) then
		return
	end
	ent:cloakToggleActive()
end
numpad.Register("Cloaking onDown", onDown)

local function onUp(ply, ent)
	if (not (ent:IsValid() and ent.cloakToggleActive and not ent.cloakToggle)) then
		return
	end
	ent:cloakToggleActive()
end
numpad.Register("Cloaking onUp", onUp)

local function TriggerInput(self, name, value, ...)
	if (name == "Cloak") then
		if (value == 0) then
			if (self.cloakPrevWireOn) then
				self.cloakPrevWireOn = false
				if (not self.cloakToggle) then
					self:cloakToggleActive()
				end
			end
		else
			if (not self.cloakPrevWireOn) then
				self.cloakPrevWireOn = true
				self:cloakToggleActive()
			end
		end
	elseif (self.cloakTriggerInput) then
		return self:cloakTriggerInput(name, value, ...)
	end
end

local function PreEntityCopy(self)
	local info = WireLib.BuildDupeInfo(self)
	if (info) then
		duplicator.StoreEntityModifier(self, "WireDupeInfo", info)
	end
	if (self.wireSupportPreEntityCopy) then
		self:wireSupportEntityCopy()
	end
end

local function PostEntityPaste(self, ply, ent, ents)
	if (self.EntityMods and self.EntityMods.WireDupeInfo) then
		WireLib.ApplyDupeInfo(ply, self, self.EntityMods.WireDupeInfo, function(id)
			return ents[id]
		end)
	end
	if (self.wireSupportPostEntityPaste) then
		self:wireSupportPostEntityPaste(ply, ent, ents)
	end
end

local function onRemove(self)
	numpad.Remove(self.cloakUpNum)
	numpad.Remove(self.cloakDownNum)
end

-- Fer Duplicator
local function dooEet(ply, ent, stuff)
	if (ent.isCloakable) then
		ent:cloakDeactivate()
		onRemove(ent)
	else
		ent.isCloakable = true
		ent.cloakActivate = cloakActivate
		ent.cloakDeactivate = cloakDeactivate
		ent.cloakToggleActive = cloakToggleActive
		ent:CallOnRemove("Cloaking", onRemove)
		if (WireLib) then
			WireLib.AddInputs(ent, {"Cloak"})
			WireLib.AddOutputs(ent, {"CloakActive"},
                   			{"If this entity is currently cloaked"})
			ent.cloakTriggerInput = ent.cloakTriggerInput or ent.TriggerInput
			ent.TriggerInput = TriggerInput
			if (not (ent.IsWire or ent.addedWireSupport)) then -- Dupe Support
				ent.wireSupportPreEntityCopy = ent.PreEntityCopy
				ent.PreEntityCopy = PreEntityCopy
				ent.wireSupportPostEntityPaste = ent.PostEntityPaste
				ent.PostEntityPaste = PostEntityPaste
				ent.addedWireSupport = true
			end
		end
	end
	ent.cloakUpNum = numpad.OnUp(ply, stuff.key, "Cloaking onUp", ent)
	ent.cloakDownNum = numpad.OnDown(ply, stuff.key, "Cloaking onDown", ent)
	ent.cloakToggle = stuff.toggle
	ent.cloakMaterial = stuff.material
	ent.cloakFlicker = stuff.flicker
	if (stuff.reversed) then
		ent:cloakActivate()
	end
	duplicator.StoreEntityModifier(ent, "Lexical Cloaking", stuff)
	return true
end

duplicator.RegisterEntityModifier("Lexical Cloaking", dooEet)

-- Legacy
duplicator.RegisterEntityModifier("Cloaking", function(ply, ent, Data)
	return dooEet(ply, ent, {
		key = Data.Key,
		flicker = Data.Flicker,
		reversed = Data.Inversed,
		material = Data.Material,
		toggle = true,
	})
end)

local function doUndo(undoData, ent)
	if (IsValid(ent) and ent.isCloakable) then
		onRemove(ent)
		ent:cloakDeactivate()
		ent.isCloakable = false
		if (WireLib) then
			ent.TriggerInput = ent.cloakTriggerInput
			WireLib.RemoveInputs(ent, {"Cloak"})
			WireLib.RemoveOutputs(ent, {"CloakActive"})
		end
		return true
	end
	return false
end

hook.Add("EntityTakeDamage", "Cloaking Flicker Hook", function(ent)
	if (ent.isCloakable and ent.cloakFlicker and ent.cloakActive) then
		ent:cloakDeactivate()
		timer.Simple(0.05, function()
			ent:cloakActivate()
		end)
	end
end)

local function massUndo(undoData)
	for i, ent in pairs(undoData.Entities) do
		doUndo(undoData, ent)
		undoData.Entities[i] = nil
	end
end

function TOOL:LeftClick(tr)
	if (not checkTrace(tr)) then
		return false
	end
	local ent = tr.Entity
	local ply = self:GetOwner()
	local tab = {
		key = self:GetClientNumber("key"),
		toggle = self:GetClientNumber("toggle") == 1,
		flicker = self:GetClientNumber("flicker") == 1,
		reversed = self:GetClientNumber("reversed") == 1,
		material = self:GetClientInfo("material"),
	}
	undo.Create("cloaking")
	undo.SetPlayer(ply)
	undo.AddFunction(massUndo)
	if (self:GetClientNumber("all") == 0) then
		dooEet(ply, ent, tab)
		undo.AddEntity(ent)
	else
		for ent in pairs(constraint.GetAllConstrainedEntities(ent)) do
			dooEet(ply, ent, tab)
			undo.AddEntity(ent)
		end
	end
	undo.Finish()

	SendUserMessage("CloakingHurrah!", ply)
	return true
end

function TOOL:Reload(tr)
	return doUndo(nil, tr.Entity)
end
