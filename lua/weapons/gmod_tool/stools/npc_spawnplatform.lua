--[[
	NPC Spawn Platforms V2
	Copyright (c) 2011-2016 Lex Robinson
	This code is freely available under the MIT License
--]]


local ClassName = 'npc_spawnplatform';

MsgN( ClassName, ' reloaded');

TOOL.Category     = "Lexical Tools"             -- Name of the category
TOOL.Name         = "NPC Spawn Platforms v2"   -- Name to display
--- Default Values
local cvars = {
	npc           = "npc_combine_s";
	weapon        = "weapon_smg1";
	spawnheight   = "16";
	spawnradius   = "16";
	maximum       = "5";
	delay         = "4";
	onkey         = "2";
	offkey        = "1";
	nocollide     = "1";
	healthmul     = "1";
	toggleable    = "1";
	autoremove    = "1";
	squadoverride = "1";
	customsquads  = "0";
	totallimit    = "0";
	decrease      = "0";
	active        = "0";
	skill         = WEAPON_PROFICIENCY_AVERAGE;
	frozen        = "1";
}

cleanup.Register("Spawnplatforms");
table.Merge( TOOL.ClientConVar, cvars );

function TOOL:LeftClick(trace)
	local owner = self:GetOwner()
	if (npcspawner.config.adminonly == 1 and not owner:IsAdmin()) then
		if (CLIENT) then
			GAMEMODE:AddNotify("The server admin has disabled this STool for non-admins!",NOTIFY_ERROR,5);
		end
		npcspawner.debug2(owner,"has tried to use the STool in admin mode and isn't an admin!");
		return false;
	end
	npcspawner.debug2(owner,"has left clicked the STool.");
	if (CLIENT) then
		return true;
	elseif (not owner:CheckLimit( "spawnplatforms" )) then
		return false;
	elseif (trace.Entity:GetClass() == "sent_spawnplatform") then
		self:SetKVs(trace.Entity);
		npcspawner.debug(owner,"has applied his settings to an existing platform:",trace.Entity);
		return true;
	end
	local ent = ents.Create("sent_spawnplatform");
	self:SetKVs(ent);
	ent:SetKeyValue("ply", owner:EntIndex());
	ent:SetPos(trace.HitPos);
	local ang = trace.HitNormal:Angle();
	ang.Roll = ang.Roll - 90;
	ang.Pitch = ang.Pitch - 90;
	ent:SetAngles( ang );
	ent:Spawn();
	ent:Activate();
	ent:SetPlayer(owner)
	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.y );
	owner:AddCount("sent_spawnplatform", ent);
	undo.Create("NPC Spawn Platform");
		undo.SetPlayer(self:GetOwner());
		undo.AddEntity(ent);
		undo.SetCustomUndoText("Undone a " .. self:GetClientInfo("npc") .. " spawn platform" .. (tonumber(self:GetClientInfo("autoremove")) > 0 and " and all its NPCs." or "."));
	undo.Finish();
	cleanup.Add(self:GetOwner(), "Spawnplatforms", ent);
	return true;
end

function TOOL:RightClick(trace)
	local owner = self:GetOwner();
	local ent = trace.Entity;
	npcspawner.debug2(owner,"has right-clicked the STool on", ent);
	if (IsValid(ent) and ent:GetClass() == "sent_spawnplatform") then
		if (CLIENT) then return true end
		for key in pairs(self.ClientConVar) do
			local res = ent:GetNetworkKeyValue(key)
			npcspawner.debug2("Got value", res, "for key", key);
			if (res) then
				owner:ConCommand("npc_spawnplatform_"..key.." "..tostring(res).."\n");
			end
		end
	end
end

function TOOL:SetKVs(ent)
	for key in pairs(cvars) do
		-- Things that've been
		ent:SetKeyValue(key, self:GetClientInfo(key));
	end
end

if ( SERVER ) then return; end

local function AddToolLanguage( id, lang )
	language.Add( 'tool.' .. ClassName .. '.' .. id, lang );
end
AddToolLanguage( "name", "NPC Spawn Platforms v2" );
AddToolLanguage( "desc", "Create a platform that will constantly make NPCs." );
AddToolLanguage( "0",    "Left-click: Spawn/Update Platform. Right-click: Copy Platform Data." );
-- Controls
AddToolLanguage( "npc",           "NPC" );
AddToolLanguage( "weapon",        "Weapon" );
AddToolLanguage( "skill",         "Weapon Skill" );
AddToolLanguage( "delay",         "Spawning Delay" );
AddToolLanguage( "decrease",      "Decrease Delay Amount" );
AddToolLanguage( "maximum",       "Maximum In Action" );
AddToolLanguage( "totallimit",    "Turn Off After" );
AddToolLanguage( "autoremove",    "Clean up on Remove" );
AddToolLanguage( "keys.on",       "Turn On" );
AddToolLanguage( "keys.off",      "Turn Off" );
AddToolLanguage( "toggleable",    "Use Key Toggles" );
AddToolLanguage( "active",        "Start Active" );
AddToolLanguage( "nocollide",     "Disable NPC Collisions" );
AddToolLanguage( "spawnheight",   "Spawn Height" );
AddToolLanguage( "spawnradius",   "Spawn Radius" );
AddToolLanguage( "healthmul",     "Health Multiplier" );
AddToolLanguage( "frozen",  "Spawn the platform frozen" );
AddToolLanguage( "customsquads",  "Use Global Squad" );
AddToolLanguage( "squadoverride", "Global Squad Number" );
-- Control Descs
AddToolLanguage( "skill.desc",         string.format( "Where %d is terrible and %d is perfect", WEAPON_PROFICIENCY_POOR, WEAPON_PROFICIENCY_PERFECT ) );
AddToolLanguage( "delay.desc",         "The delay between each NPC spawn." );
AddToolLanguage( "decrease.desc",      "How much to decrease the delay by every time you kill every NPC spawned." );
AddToolLanguage( "maximum.desc",       "The platform will pause spawning until you kill one of the spawned ones" );
AddToolLanguage( "totallimit.desc",    "Turn the platform off after this many NPC have been spawned" );
AddToolLanguage( "autoremove.desc",    "All NPCs spawned by a platform will be removed with the platform." );
AddToolLanguage( "spawnheight.desc",   "Spawn NPCs higher than the platform to avoid obsticles" );
AddToolLanguage( "spawnradius.desc",   "Spawn NPCs in a circle around the platform. 0 spawns them on the platform" );
AddToolLanguage( "healthmul.desc",     "Increase the health of spawned NPCs for more longer fights" );
-- Help!
AddToolLanguage( "positioning.help", "Prevent your NPCs getting stuck in each other by disabling collisions or spacing their spawns out." );
AddToolLanguage( "squads.help1", "NPCs in a squad talk to each other to improve tactics. By default, all NPCs spawned by a spawn platform are in the same squad." );
AddToolLanguage( "squads.help2", "If you want a squad to cover more than one platform, use a global squad. Be careful not to let your squads get to big or your game will lag!" );
-- Panels
AddToolLanguage( "panel_npc",          "NPC Selection" );
AddToolLanguage( "panel_spawning",     "NPC Spawn Rates" );
AddToolLanguage( "panel_activation",   "Platform Activation" );
AddToolLanguage( "panel_positioning",  "NPC Positioning" );
AddToolLanguage( "panel_other",        "Other" );
-- Inferior Tech
language.Add("Cleanup_Spawnplatforms", "NPC Spawn Platforms");
language.Add("Cleaned_Spawnplatforms", "Cleaned up all NPC Spawn Platforms");

local function lang( id )
	return '#Tool.' .. ClassName .. '.' .. id;
end
local function cvar( id )
	return ClassName .. '_' .. id;
end

-- Because when don't you need to define your own builtins?
local function AddControl( CPanel, control, name, data )
	data = data or {};
	data.Label = lang( name );
	if ( control ~= "ControlPanel" and control ~= "ListBox" ) then
		data.Command = cvar( name );
	end
	local ctrl = CPanel:AddControl( control, data );
	if ( data.Description ) then
		ctrl:SetToolTip( lang( name .. ".desc" ) );
	end
	return ctrl;
end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl( "Header", {
		Text        = lang 'name';
		Description = lang 'desc';
	} );
	local combo, options
	-- Presets
	local CVars = {};
	local defaults = {};
	for key, default in pairs(cvars) do
		key = cvar( key );
		table.insert(CVars, key);
		defaults[key] = default;
	end

	CPanel:AddControl( "ComboBox", {
		Label   = "#Presets";
		Folder  = "spawnplatform";
		CVars   = CVars;
		Options = {
			default = defaults;
			-- TODO: Maybe some other nice defaults?
		};
		MenuButton = 1;
	} );

	do -- NPC Selector

		local CPanel = AddControl( CPanel, "ControlPanel", "panel_npc" );

		--Type select
		--[[
		combo = {
			Height  = 150,
			Options = {},
		};
		for k,v in pairs(npcspawner.npcs) do
			combo.Options[v] = {npc_spawnplatform_npc = k};
		end
		local npcs = AddControl( CPanel, "ListBox", "npc", combo );
		--]]
		AddControl( CPanel, "NPCSpawnSelecter", "npc" );

		local weapons = AddControl( CPanel, "ListBox", "weapon" );
		do
			local key = cvar"weapon";
			function option( title, class )
				weapons:AddOption( title, { [ key ] = class } );
			end

			option( "  Default Weapon",       "weapon_default" );
			option( "  None",                 "weapon_none"    );
			option( " Random Rebel Weapon",   "weapon_rebel"   );
			option( " Random Combine Weapon", "weapon_combine" );
			option( " Random Citizen Weapon", "weapon_citizen" );

			for _, tab in pairs( list.Get( "NPCUsableWeapons" ) ) do
				option( tab.title, tab.class );
			end

		end
		-- Skill select
		AddControl( CPanel, "Slider", "skill", {
			-- Rely on the fact that the WEAPON_PROFICIENCY enums are from 0 to 5
			Min     = WEAPON_PROFICIENCY_POOR;
			Max     = WEAPON_PROFICIENCY_PERFECT;
			Description = true;
		} );

	end

	do
		local CPanel = AddControl( CPanel, "ControlPanel", "panel_spawning" );

		-- Timer select
		AddControl( CPanel, "Slider", "delay", {
			Type        = "Float";
			Min         = npcspawner.config.mindelay;
			Max         = 60;
			Description = true;
		});
		-- Timer Reduction
		AddControl( CPanel, "Slider", "decrease", {
			Type        = "Float";
			Min         = 0;
			Max         = 2;
			Description = true;
		} );
		-- Maximum select
		AddControl( CPanel, "Slider", "maximum", {
			Type        = "Integer";
			Min         = 1;
			Max         = npcspawner.config.maxinplay;
			Description = true;
		} );
		-- Maximum Ever
		AddControl( CPanel, "Slider", "totallimit", {
			Type        = "Integer";
			Min         = 0;
			Max         = 100;
			Description = true;
		} );
		-- Autoremove select
		AddControl( CPanel, "Checkbox", "autoremove", {
			Description = true;
		} );
	end

	do
		local CPanel = AddControl( CPanel, "ControlPanel", "panel_activation" );
		--Numpad on/off select
		CPanel:AddControl("Numpad", { -- Someone always has to be special
			Label       = lang "keys.on";
			Label2      = lang "keys.off";
			Command     = cvar "onkey";
			Command2    = cvar "offkey";
		} );
		--Toggleable select
		AddControl( CPanel, "Checkbox", "toggleable", {
		} );
		--Active select
		AddControl( CPanel, "Checkbox", "active" );
	end

	do -- Positions

		local CPanel = AddControl( CPanel, "ControlPanel", "panel_positioning", {
			Closed = true;
		});
		CPanel:Help( lang "positioning.help" );
		-- Nocollide
		AddControl( CPanel, "Checkbox", "nocollide" );
		--Spawnheight select
		AddControl( CPanel, "Slider", "spawnheight", {
			Type        = "Float";
			Min         = 8;
			Max         = 128;
			Description = true;
		} );
		--Spawnradius select
		AddControl( CPanel, "Slider", "spawnradius", {
			Type        = "Float";
			Min         = 0;
			Max         = 128;
			Description = true;
		} );

	end
	do -- Other
		local CPanel = AddControl( CPanel, "ControlPanel", "panel_other", {
			Closed = true;
		});
		--Healthmul select
		AddControl( CPanel, "Slider", "healthmul", {
			Type        = "Float";
			Min         = 0.5;
			Max         = 5;
			Description = true;
		} );
		-- Global Squad On/Off
		AddControl( CPanel, "Checkbox", "frozen" );
		-- Global Squads
		CPanel:Help( lang "squads.help1" );
		CPanel:Help( lang "squads.help2" );
		-- Global Squad On/Off
		AddControl( CPanel, "Checkbox", "customsquads" );
		-- Custom Squad Picker
		AddControl( CPanel, "Slider", "squadoverride", {
			Type        = "Integer";
			Min         = 1;
			Max         = 50;
		} );
	end
end
