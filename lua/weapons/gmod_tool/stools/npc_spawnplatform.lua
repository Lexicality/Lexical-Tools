--[[
    NPC Spawn Platforms V2.1
    Copyright (c) 2011-2012 Lex Robinson
    This code is freely available under the MIT License
--]]


local ClassName = 'npc_spawnplatform';

MsgN( ClassName, ' reloaded');

TOOL.Category     = "Lexical Tools"             -- Name of the category
TOOL.Name         = "NPC Spawn Platforms 2.2"   -- Name to display
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
    autotarget    = "1";
    toggleable    = "1";
    autoremove    = "1";
    squadoverride = "1";
    customsquads  = "0";
    totallimit    = "0";
    decrease      = "0";
    active        = "0";
    skill         = WEAPON_PROFICIENCY_AVERAGE;
}

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
    undo.Create("spawnplatform");
        undo.SetPlayer(self:GetOwner());
        undo.AddEntity(ent);
        undo.SetCustomUndoText("Undone a " .. self:GetClientInfo("npc") .. " spawn platform" .. (tonumber(self:GetClientInfo("autoremove")) > 0 and " and all its NPCs." or "."));
    undo.Finish();
    return true;
end

function TOOL:RightClick(trace)
    npcspawner.debug2(owner,"has right-clicked the STool.");
    local ent = trace.Entity;
    if (IsValid(ent) and ent:GetClass() == "sent_npcspawner") then
        if (CLIENT) then return true end
        local owner = self:GetOwner();
        for key in pairs(self.ClientConVar) do
            owner:ConCommand("npc_spawnplatform_"..key.." "..tostring(ent["k_"..key]).."\n");
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
AddToolLanguage( "name", "NPC Spawn Platforms 2.1" );
AddToolLanguage( "desc", "Create a platform that will constantly make NPCs." );
AddToolLanguage( "0",    "Left-click: Spawn/Update Platform. Right-click: Copy Platform Data." );
-- Controls 
AddToolLanguage( "npc",          "NPC" );
AddToolLanguage( "weapon",       "Weapon" );
AddToolLanguage( "weapon_skill", "Weapon Skill" );
-- Control Descs
AddToolLanguage( "weapon_skill_desc", string.format( "Where %d is terrible and %d is perfect", WEAPON_PROFICIENCY_POOR, WEAPON_PROFICIENCY_PERFECT ) );
-- Panels
AddToolLanguage( "panel_npc",         "NPC Selection" );
AddToolLanguage( "panel_spawning",    "NPC Spawn Rates" );
AddToolLanguage( "panel_activation",  "Platform Activation" );
AddToolLanguage( "panel_positioning", "NPC Positioning" );
AddToolLanguage( "panel_other",       "Other" );

local function lang( id )
    return '#Tool.' .. ClassName .. '.' .. id;
end
local function cvar( id )
    return ClassName .. '_' .. id;
end

-- Because when don't you need to define your own builtins?
local function AddControl( CPanel, control, name, data )
    --[[ FIXME ]] if ( type( name ) == "table" ) then -- FIXME
    --[[ FIXME ]]     data = name;                    -- FIXME
    --[[ FIXME ]]     name = name.Label               -- FIXME
    --[[ FIXME ]] end                                 -- FIXME
    data = data or {};
    data.Label = lang( name );
    local ctrl = CPanel:AddControl( control, data );
    if ( data.Description ) then
        ctrl:SetToolTip( lang( name .. "_desc" ) );
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

        local CPanel = AddControl( CPanel, "CPanel", "panel_npc" );
        --Type select
        combo = {
            Height  = 150,
            Options = {},
        };
        for k,v in pairs(npcspawner.npcs) do
            combo.Options[v] = {npc_spawnplatform_npc = k};
        end
        AddControl( CPanel, "ListBox", "npc", combo );
        -- Weapon select
        options = {};
        for id, label in pairs( npcspawner.weps ) do
            options[ label ] = { npc_spawnplatform_weapon = id };
        end
        AddControl( CPanel, "ListBox", "weapon", {
            Options = options;
        } );
        -- Skill select
        AddControl( CPanel, "Slider", "weapon_skill", {
            -- Rely on the fact that the WEAPON_PROFICIENCY enums are from 0 to 5
            Min     = WEAPON_PROFICIENCY_POOR;
            Max     = WEAPON_PROFICIENCY_PERFECT;
            Command = cvar "skill";
            Description = true;
        } );

    end

    do
        local CPanel = AddControl( CPanel, "CPanel", "panel_spawning" );

        --Timer select
        AddControl( CPanel, "Slider", {
            Label       = "Spawn Delay",
            Type        = "Float",
            Min         = npcspawner.config.mindelay,
            Max         = 60,
            Command     = "npc_spawnplatform_delay",
            Description = "The delay between each NPC spawn."
        });
        --Timer Reduction
        AddControl( CPanel, "Slider", {
            Label       = "Decrease Delay Amount",
            Type        = "Float",
            Min         = 0,
            Max         = 2,
            Command     = "npc_spawnplatform_decrease",
            Description = "How much to decrease the delay by every time you kill every NPC spawned."
        } );
        --Maximum select
        AddControl( CPanel, "Slider", {
            Label       = "Maximum In Action Simultaneously",
            Type        = "Integer",
            Min         = 1,
            Max         = npcspawner.config.maxinplay,
            Command     = "npc_spawnplatform_maximum",
            Description = "The maximum NPCs allowed from the spawnpoint at one time."
        } );
        --Maximum Ever
        AddControl( CPanel, "Slider", {
            Label       = "Maximum To Spawn",
            Type        = "Integer",
            Min         = 0,
            Max         = 100,
            Command     = "npc_spawnplatform_totallimit",
            Description = "The maximum NPCs allowed from the spawnpoint in one lifetime. The spawnpoint will turn off when this number is reached."
        } );
        --Autoremove select
        AddControl( CPanel, "Checkbox", {
            Label       = "Remove All Spawned NPCs on Platform Remove",
            Command     = "npc_spawnplatform_autoremove",
            Description = "If this is checked, all NPCs spawned by a platform will be removed with the platform."
        } );
    end

    do
        local CPanel = AddControl( CPanel, "CPanel", "panel_activation" );
        --Numpad on/off select
        AddControl( CPanel, "Numpad", {
            Label       = "#Turn On",
            Label2      = "#Turn Off",
            Command     = "npc_spawnplatform_onkey",
            Command2    = "npc_spawnplatform_offkey",
            ButtonSize  = 22
        } );
        --Toggleable select
        AddControl( CPanel, "Checkbox", {
            Label       = "Toggle On/Off With Use",
            Command     = "npc_spawnplatform_toggleable",
            Description = "If this is checked, pressing Use on the spawn platform toggles the spawner on and off."
        } );
        --Active select
        AddControl( CPanel, "Checkbox", {
            Label       = "Start Active",
            Command     = "npc_spawnplatform_active",
            Description = "If this is checked, spawned or updated platforms will be live."
        } );
    end

    do -- Positions

        local CPanel = AddControl( CPanel, "CPanel", "panel_positioning", {
            Closed = true;
        });
        -- Nocollide
        AddControl( CPanel, "Checkbox", {
            Label       = "No Collision Between Spawned NPCs",
            Command     = "npc_spawnplatform_nocollide",
            Description = "If this is checked, NPCs will not collide with any other NPCs spawned with this option on. This helps prevent stacking in the spawn area"
        } );
        --Spawnheight select
        AddControl( CPanel, "Slider", {
            Label       = "Spawn Height Offset",
            Type        = "Float",
            Min         = 8,
            Max         = 128,
            Command     = "npc_spawnplatform_spawnheight",
            Description = "(Only change if needed) Height above spawn platform NPCs originate from."
        } );
        --Spawnradius select
        AddControl( CPanel, "Slider", {
            Label       = "Spawn X/Y Radius",
            Type        = "Float",
            Min         = 0,
            Max         = 128,
            Command     = "npc_spawnplatform_spawnradius",
            Description = "(Use 0 if confused) Radius in which NPCs spawn (use small radius unless on flat open area)."
        } );

    end
    do -- Other
        local CPanel = AddControl( CPanel, "CPanel", "panel_other", {
            Closed = true;
        });
        --Healthmul select
        AddControl( CPanel, "Slider", {
            Label       = "Health Multiplier",
            Type        = "Float",
            Min         = 0.5,
            Max         = 5,
            Command     = "npc_spawnplatform_healthmul",
            Description = "The multiplier applied to the health of all NPCs on spawn."
        } );
        -- Custom Squad Picker
        AddControl( CPanel, "Slider", {
            Label       = "Squad Override",
            Type        = "Integer",
            Min         = 1,
            Max         = 10,
            Command     = "npc_spawnplatform_squadoverride",
            Description = "Squad number override (if custom squads is checked)"
        } );
        -- Custom Squad On/Off
        AddControl( CPanel, "Checkbox", {
            Label       = "Use Custom Squad Indexes",
            Command     = "npc_spawnplatform_customsquads",
            Description = "If this is checked, NPCs spawn under the squad defined by the override. Otherwise NPCs will be put in a squad with their spawnmates."
        } );
    end
end
