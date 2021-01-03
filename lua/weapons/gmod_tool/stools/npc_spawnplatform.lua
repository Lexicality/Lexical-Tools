--[[
	NPC Spawn Platforms - lua/weapons/gmod_tool/stools/npc_spawnplatform.lua
    Copyright 2009-2017 Lex Robinson

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
local ClassName = "npc_spawnplatform"

local function lang(id)
	return "#tool." .. ClassName .. "." .. id
end
local function cvar(id)
	return ClassName .. "_" .. id
end

MsgN(ClassName, " reloaded")

TOOL.Category = "Lexical Tools"
TOOL.Name = lang("name")
TOOL.Information = {
	-- Fancy new style infoboxes
	{name = "left"},
	{name = "right"},
}
--- Default Values
local cvars = {
	npc = "npc_combine_s",
	weapon = "weapon_smg1",
	spawnheight = "16",
	spawnradius = "16",
	maximum = "5",
	delay = "4",
	onkey = "2",
	offkey = "1",
	nocollide = "1",
	healthmul = "1",
	toggleable = "1",
	autoremove = "1",
	squadoverride = "1",
	customsquads = "0",
	totallimit = "0",
	decrease = "0",
	active = "0",
	oldspawning = "0",
	skill = WEAPON_PROFICIENCY_AVERAGE,
	frozen = "1",
	killvalue = "-1",
}

local CLEANUP_KEY = "Spawnplatforms"
cleanup.Register(CLEANUP_KEY)
table.Merge(TOOL.ClientConVar, cvars)

function TOOL:LeftClick(trace)
	local owner = self:GetOwner()
	if (npcspawner.config.adminonly == 1 and not owner:IsAdmin()) then
		if (CLIENT) then
			GAMEMODE:AddNotify(
				"The server admin has disabled this STool for non-admins!", NOTIFY_ERROR, 5)
		end
		npcspawner.debug2(owner,
                  		"has tried to use the STool in admin mode and isn't an admin!")
		return false
	end
	npcspawner.debug2(owner, "has left clicked the STool.")
	if (CLIENT) then
		return true
	elseif (not owner:CheckLimit(CLEANUP_KEY)) then
		return false
	elseif (trace.Entity:GetClass() == "sent_spawnplatform") then
		self:SetKVs(trace.Entity)
		npcspawner.debug(owner, "has applied his settings to an existing platform:",
                 		trace.Entity)
		return true
	end
	local ent = ents.Create("sent_spawnplatform")
	self:SetKVs(ent)
	ent:SetKeyValue("ply", owner:EntIndex())
	ent:SetPos(trace.HitPos)
	local ang = trace.HitNormal:Angle()
	ang.Roll = ang.Roll - 90
	ang.Pitch = ang.Pitch - 90
	ent:SetAngles(ang)
	ent:Spawn()
	ent:Activate()
	ent:SetPlayer(owner)
	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.y)

	owner:AddCount(CLEANUP_KEY, ent)
	local name = "#sent_spawnplatform"
	if (tonumber(self:GetClientInfo("autoremove")) > 0) then
		name = "#sent_spawnplatform_and_npcs"
	end
	undo.Create(name)
	undo.SetPlayer(self:GetOwner())
	undo.AddEntity(ent)
	undo.Finish()

	cleanup.Add(self:GetOwner(), CLEANUP_KEY, ent)
	return true
end

function TOOL:RightClick(trace)
	local owner = self:GetOwner()
	local ent = trace.Entity
	npcspawner.debug2(owner, "has right-clicked the STool on", ent)
	if (IsValid(ent) and ent:GetClass() == "sent_spawnplatform") then
		if (CLIENT) then
			return true
		end
		for key in pairs(self.ClientConVar) do
			local res = ent:GetNetworkKeyValue(key)
			npcspawner.debug2("Got value", res, "for key", key)
			if (res) then
				owner:ConCommand(cvar(key) .. " " .. tostring(res) .. "\n")
			end
		end
	end
end

function TOOL:SetKVs(ent)
	for key in pairs(cvars) do
		-- Things that've been
		ent:SetKeyValue(key, self:GetClientInfo(key))
	end
end

if (SERVER) then
	return
end

-- Because when don't you need to define your own builtins?
local function AddControl(CPanel, control, name, data)
	data = data or {}
	data.Label = lang(name)
	if (control ~= "ControlPanel" and control ~= "ListBox") then
		data.Command = cvar(name)
	end
	local ctrl = CPanel:AddControl(control, data)
	if (data.Tooltip) then
		ctrl:SetToolTip(lang(name .. ".tooltip"))
	end
	return ctrl
end

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Text = lang "name", Description = lang "desc"})
	local combo, options
	-- Presets
	local CVars = {}
	local defaults = {}
	for key, default in pairs(cvars) do
		key = cvar(key)
		table.insert(CVars, key)
		defaults[key] = default
	end

	CPanel:AddControl("ComboBox", {
		Label = "#Presets",
		Folder = "spawnplatform",
		CVars = CVars,
		Options = {
			default = defaults,
			-- TODO: Maybe some other nice defaults?
		},
		MenuButton = 1,
	})

	do -- NPC Selector

		local CPanel = AddControl(CPanel, "ControlPanel", "panel_npc")

		-- Type select
		AddControl(CPanel, "NPCSpawnSelecter", "npc")

		-- Weapon select
		AddControl(CPanel, "NPCWeaponSelecter", "weapon")

		-- Skill select
		AddControl(CPanel, "Slider", "skill", {
			-- Rely on the fact that the WEAPON_PROFICIENCY enums are from 0 to 5
			Min = WEAPON_PROFICIENCY_POOR,
			Max = WEAPON_PROFICIENCY_PERFECT,
			Help = true,
		})

	end

	do
		local CPanel = AddControl(CPanel, "ControlPanel", "panel_spawning")

		-- Timer select
		AddControl(CPanel, "Slider", "delay",
           		{Type = "Float", Min = npcspawner.config.mindelay, Max = 60})
		-- Maximum select
		AddControl(CPanel, "Slider", "maximum",
           		{Type = "Integer", Min = 1, Max = npcspawner.config.maxinplay})
		-- Timer Reduction
		AddControl(CPanel, "Slider", "decrease",
           		{Type = "Float", Min = 0, Max = 2, Help = true})
		-- Maximum Ever
		AddControl(CPanel, "Slider", "totallimit",
           		{Type = "Integer", Min = 0, Max = 100, Tooltip = true})
		-- Autoremove select
		AddControl(CPanel, "Checkbox", "autoremove", {Tooltip = true})
	end

	do
		local CPanel = AddControl(CPanel, "ControlPanel", "panel_activation")
		-- Numpad on/off select
		CPanel:AddControl("Numpad", { -- Someone always has to be special
			Label = lang "keys.on",
			Label2 = lang "keys.off",
			Command = cvar "onkey",
			Command2 = cvar "offkey",
		})
		-- Toggleable select
		AddControl(CPanel, "Checkbox", "toggleable", {})
		-- Active select
		AddControl(CPanel, "Checkbox", "active")
	end

	do -- Positions

		local CPanel = AddControl(CPanel, "ControlPanel", "panel_positioning",
                          		{Closed = true})
		CPanel:Help(lang "positioning.help")
		-- Nocollide
		AddControl(CPanel, "Checkbox", "nocollide")
		-- Spawnheight select
		AddControl(CPanel, "Slider", "spawnheight",
           		{Type = "Float", Min = 8, Max = 128})
		-- Spawnradius select
		AddControl(CPanel, "Slider", "spawnradius",
           		{Type = "Float", Min = 0, Max = 128})

	end
	do -- Other
		local CPanel = AddControl(CPanel, "ControlPanel", "panel_other",
                          		{Closed = true})

		-- Healthmul select
		AddControl(CPanel, "Slider", "healthmul", {Type = "Float", Min = 0.5, Max = 5})

		-- Global Squad On/Off
		AddControl(CPanel, "Checkbox", "frozen")

		-- Global Squads
		CPanel:Help(lang "squads.help1")
		CPanel:Help(lang "squads.help2")
		-- Global Squad On/Off
		AddControl(CPanel, "Checkbox", "customsquads")
		-- Custom Squad Picker
		AddControl(CPanel, "Slider", "squadoverride",
           		{Type = "Integer", Min = 1, Max = 50})

		-- Legacy spawning system
		AddControl(CPanel, "Checkbox", "oldspawning", {Help = true})

		-- NPC Kill Value
		AddControl(CPanel, "Slider", "killvalue",
           		{Type = "Integer", Min = -1, Max = 1000, Help = true})
	end
end
