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
--]]

local cvarstr = "npcspawner_config_";
local function callback(cvar, old, new)
	cvar = cvar:gsub(cvarstr, "");
	new = tonumber(new) or npcspawner.config[cvar];
	if (npcspawner.config[cvar] ~= new) then
		npcspawner.config[cvar] = new;
		local lpl = LocalPlayer();
		if (lpl and type(lpl) == 'Player' and IsValid(lpl) and lpl:IsAdmin()) then
			RunConsoleCommand("npcspawner_config", cvar, new);
		end
	end
end
for k, v in pairs(npcspawner.config) do
	CreateConVar(cvarstr .. k, tostring(v));
	cvars.AddChangeCallback(cvarstr .. k, callback);
end
usermessage.Hook("npcspawner_config", function(msg)
	local cvar, value = msg:ReadString(), msg:ReadFloat()
	npcspawner.config[cvar] = value;
	RunConsoleCommand(cvarstr .. cvar, tostring(value));
end);
npcspawner.recieve("NPCSpawner Config", function(data)
	npcspawner.config = data;
	npcspawner.debug("Just got new config vars.");
	for k, v in pairs(npcspawner.config) do
		RunConsoleCommand(cvarstr .. k, tostring(v))
	end
end);

-----------------------------------
-- Lexical Patented Corpse Eater --
-----------------------------------
CreateConVar("cleanupcorpses", 1);
timer.Create("Dead Body Deleter", 60, 0, function()
	if (GetConVarNumber("cleanupcorpses") < 1) then return; end
	for _, ent in pairs(ents.FindByClass("class C_ClientRagdoll")) do
		ent:Remove()
	end
end);

local function OnPopulateToolPanel(panel)
	panel:AddControl("Label", {
		Text = "Cleanup Corpses: This will clean up all the clientside corpses every minute if enabled."
	});
	panel:AddControl("CheckBox", {
		Label = "Cleanup Corpses",
		Command = "cleanupcorpses",
	});
	if (not LocalPlayer():IsAdmin()) then
		return;
	end
	panel:AddControl("Label", {
		Text = "Admins only: This will stop non-admins from being able to use the spawnplatforms STool."
	});
	panel:AddControl("CheckBox", {
		Label = "Admins Only",
		Command = "npcspawner_config_adminonly",
	});
	panel:AddControl("Label", {
		Text = "Call Hooks: This will cause the platforms to call all the sandbox hooks, as if the player was using the Spawn Menu to make NPCs."
	});
	panel:AddControl("CheckBox", {
		Label = "Call Hooks",
		Command = "npcspawner_config_callhooks",
	});
	panel:AddControl("Label", {
		Text = "Sanity Check: This will limit what platforms can spawn to the registered \"NPC\" list."
	});
	panel:AddControl("CheckBox", {
		Label = "Santiy Check",
		Command = "npcspawner_config_sanity",
	})
	panel:AddControl("Label", {
		Text = "Max In Play: The maximum number of NPCs a single spawnplatform can have out at once."
	});
	panel:AddControl("Slider", {
		Label = "Max In Play",
		Command = "npcspawner_config_maxinplay",
		Type = "Float",
		Min = "1",
		Max = "50",
	})
	panel:AddControl("Label", {
		Text = "Minimum Delay: The minimum delay between each npc spawn."
	});
	panel:AddControl("Slider", {
		Label = "Minimum Delay",
		Command = "npcspawner_config_mindelay",
		Type = "Float",
		Min = "0.1",
		Max = "10",
	})
	--[[
	panel:AddControl("Label", {
		Text = "Debug Mode: Enable printing debug info if the developer convar is greater than 0."
	});
	panel:AddControl("CheckBox", {
		Label = "Debug Mode",
		Command = "npcspawner_config_debug",
	})
	--]]
end
hook.Add("PopulateToolMenu", "NPCSpawner Options", function()
	spawnmenu.AddToolMenuOption("Options", "Addons", "NPC Spawn Platforms", "NPC Spawn Platforms", "", "", OnPopulateToolPanel)
end)
