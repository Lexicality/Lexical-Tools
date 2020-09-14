--[[
	NPC Spawn Platforms V2 - lua/autorun/client/npcspawner2_cl.lua
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
local cvarstr = "npcspawner_config_"

local function cvar(id)
	return cvarstr .. id
end

local function callback(cvar, old, new)
	local lpl = LocalPlayer()
	if (IsValid(lpl) and not lpl:IsAdmin()) then
		return
	end

	local name = cvar:gsub(cvarstr, "")
	local value = tonumber(new)

	if (not value or value == npcspawner.config[name]) then
		return
	end

	RunConsoleCommand("npcspawner_config", name, value)
end

for name, default in pairs(npcspawner.config) do
	name = cvar(name)
	CreateConVar(name, tostring(default))
	cvars.AddChangeCallback(name, callback)
end

npcspawner.recieve(
	"NPCSpawner Config", function(data)
		npcspawner.config = data
		npcspawner.debug("Just got new config vars.")
		for name, value in pairs(npcspawner.config) do
			RunConsoleCommand(cvar(name), tostring(value))
		end
	end
)

-----------------------------------
-- Lexical Patented Corpse Eater --
-----------------------------------
CreateConVar("cleanupcorpses", 1)
timer.Create(
	"Dead Body Deleter", 60, 0, function()
		if (GetConVarNumber("cleanupcorpses") < 1) then
			return
		end
		for _, ent in pairs(ents.FindByClass("class C_ClientRagdoll")) do
			ent:Remove()
		end
	end
)

local function lang(id)
	return "#utilities.spawnplatform." .. id
end

local function clientOptions(panel)
	panel:AddControl(
		"CheckBox",
		{Label = lang("cleanupcorpses"), Help = true, Command = "cleanupcorpses"}
	)
end

local function adminOptions(panel)
	panel:AddControl(
		"CheckBox",
		{Label = lang("adminonly"), Command = cvar("adminonly"), Help = true}
	)

	panel:AddControl(
		"CheckBox",
		{Label = lang("callhooks"), Command = cvar("callhooks"), Help = true}
	)

	panel:AddControl(
		"Slider", {
			Label = lang("maxinplay"),
			Command = cvar("maxinplay"),
			Help = true,
			Type = "Float",
			Min = "1",
			Max = "50",
		}
	)

	panel:AddControl(
		"Slider", {
			Label = lang("mindelay"),
			Command = cvar("mindelay"),
			Help = true,
			Type = "Float",
			Min = "0.1",
			Max = "10",
		}
	)

	local dzpanel = panel:AddControl(
		"ControlPanel", {Label = lang("dangerzone"), Closed = true}
	)

	dzpanel:AddControl(
		"CheckBox", {Label = lang("sanity"), Command = cvar("sanity"), Help = true}
	)

	dzpanel:AddControl(
		"CheckBox",
		{Label = lang("rehydrate"), Command = cvar("rehydrate"), Help = true}
	)

	--[[
	dzpanel:AddControl("CheckBox", {
		Label   = lang("debug"),
		Command = cvar("debug"),
		Help    = true,
	})
	]] --
end

hook.Add(
	"PopulateToolMenu", "NPCSpawner Options", function()
		spawnmenu.AddToolMenuOption(
			"Utilities", "User", "NPC Spawn Platforms User",
			"#spawnmenu.utilities.spawnplatform", "", "", clientOptions
		)
		spawnmenu.AddToolMenuOption(
			"Utilities", "Admin", "NPC Spawn Platforms Admin",
			"#spawnmenu.utilities.spawnplatform", "", "", adminOptions
		)
	end
)
