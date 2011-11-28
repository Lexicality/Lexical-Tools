TOOL.Category						= "Lexical Tools"		-- Name of the category
TOOL.Name							= "#NPC Spawn Platforms2"	-- Name to display
--- Default Values
TOOL.ClientConVar ["npc"]			= "npc_combine_s";
TOOL.ClientConVar ["weapon"]		= "weapon_smg1";
TOOL.ClientConVar ["spawnheight"]	= "16";
TOOL.ClientConVar ["spawnradius"]	= "16";
TOOL.ClientConVar ["maximum"]		= "5";
TOOL.ClientConVar ["delay"]			= "4";
TOOL.ClientConVar ["onkey"]			= "2";
TOOL.ClientConVar ["offkey"]		= "1";
TOOL.ClientConVar ["nocollide"]		= "1";
TOOL.ClientConVar ["healthmul"]		= "1";
TOOL.ClientConVar ["autotarget"]	= "1";
TOOL.ClientConVar ["toggleable"]	= "1";
TOOL.ClientConVar ["autoremove"]	= "1";
TOOL.ClientConVar ["squadoverride"]	= "1";
TOOL.ClientConVar ["customsquads"]	= "0";
TOOL.ClientConVar ["totallimit"]	= "0";
TOOL.ClientConVar ["decrease"]		= "0";
TOOL.ClientConVar ["active"]		= "0";
TOOL.ClientConVar ["skill"]			= WEAPON_PROFICIENCY_AVERAGE;

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
    ent:SetAngles(Angle(0,0,90));
	ent:Spawn();
	ent:Activate();
	ent:SetPlayer(owner);
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
	for key in pairs(self.ClientConVar) do
		ent:SetKeyValue(key, self:GetClientInfo(key));
	end
end

--TODO: Make my own header panels and include them so I can have hedrz;
function TOOL:BuildCPanel()
		self:AddControl( "Header", {
			Text 		= "#Tool_npc_spawnplatformname",
			Description	= "#Tool_npc_spawnplatformdesc"}
		);
	local combo
	-- Presets 
		self:AddControl( "ComboBox", {
			Label = "#Presets",
			MenuButton = 1,
			Folder = "spawnplatform",
			CVars = {
				"npc_spawnplatform_npc",
				"npc_spawnplatform_weapon",
				"npc_spawnplatform_spawnheight",
				"npc_spawnplatform_spawnradius",
				"npc_spawnplatform_maximum",
				"npc_spawnplatform_delay",
				"npc_spawnplatform_nocollide",
				"npc_spawnplatform_healthmul",
				"npc_spawnplatform_autotarget",
				"npc_spawnplatform_toggleable",
				"npc_spawnplatform_autoremove",
				"npc_spawnplatform_squadoverride",
				"npc_spawnplatform_customsquads",
				"npc_spawnplatform_totallimit",
				"npc_spawnplatform_decrease",
				"npc_spawnplatform_active",
				"npc_spawnplatform_skill"
				},
			Options = {
				default = {
					npc_spawnplatform_npc			= "npc_combine_s",
					npc_spawnplatform_weapon		= "weapon_combine",
					npc_spawnplatform_spawnheight	= 16,
					npc_spawnplatform_spawnradius	= 16,
					npc_spawnplatform_maximum		= 5,
					npc_spawnplatform_delay			= 4,
					npc_spawnplatform_nocollide		= 1,
					npc_spawnplatform_healthmul		= 1,
					npc_spawnplatform_toggleable	= 1,
					npc_spawnplatform_autoremove	= 1,
					npc_spawnplatform_squadoverride	= 1,
					npc_spawnplatform_customsquads	= 0,
					npc_spawnplatform_autotarget	= 0,
					npc_spawnplatform_totallimit	= 0,
					npc_spawnplatform_decrease		= 0,
					npc_spawnplatform_active		= 0,
					npc_spawnplatform_skill 		= WEAPON_PROFICIENCY_AVERAGE
				}		
			},
		});
	--Type select
		combo = {
			Label	= "NPC",
			Height	= 150,
			Options	= {},
		};
		for k,v in pairs(npcspawner.npcs) do 
			combo.Options[v] = {npc_spawnplatform_npc = k};
		end
		self.npclist = self:AddControl ( "ListBox", combo);
	--Weapon select
		combo = {
			Label		= "Weapon",
			Folder		= "spawnplatform",
			Options		= {},
		};
		for k ,v in pairs(npcspawner.weps) do 
			combo.Options[v] = {npc_spawnplatform_weapon = k};
		end
		self.weplist = self:AddControl( "ListBox", combo);
	--Skill select
		combo = {
			Label		= "Skill",
			Folder		= "spawnplatform",
			Options		= {
				["-1: Poor"]		= {npc_spawnplatform_skill = WEAPON_PROFICIENCY_POOR};
				["0: Average"]		= {npc_spawnplatform_skill = WEAPON_PROFICIENCY_AVERAGE};
				["1: Good"]			= {npc_spawnplatform_skill = WEAPON_PROFICIENCY_GOOD};
				["2: Very Good"]	= {npc_spawnplatform_skill = WEAPON_PROFICIENCY_VERY_GOOD};
				["3: Perfect"]		= {npc_spawnplatform_skill = WEAPON_PROFICIENCY_PERFECT};
			};
		};
		self.skilllist = self:AddControl("ListBox", combo);
	local pad = {Text = ""}
	self:AddControl("Label", pad)
	
	self:AddControl("Label", {
		Text = "Spawning:"
	})
	--Timer select
		self.delayslider= self:AddControl( "Slider",  {
			Label 		= "Spawn Delay",
			Type		= "Float",
			Min			= npcspawner.config.mindelay,
			Max			= 60,
			Command		= "npc_spawnplatform_delay",
			Description = "The delay between each NPC spawn."
		});
	--Timer Reduction
		self.delayslider= self:AddControl( "Slider",  {
			Label 		= "Decrease Delay Amount",
			Type		= "Float",
			Min			= 0,
			Max			= 2,
			Command		= "npc_spawnplatform_decrease",
			Description = "How much to decrease the delay by every time you kill every NPC spawned."
		});
	--Maximum select
		self.maxslider  = self:AddControl( "Slider",  {
			Label		= "Maximum In Action Simultaneously",
			Type		= "Integer",
			Min			= 1,
			Max			= npcspawner.config.maxinplay,
			Command		= "npc_spawnplatform_maximum",
			Description	= "The maximum NPCs allowed from the spawnpoint at one time."
		});
	--Maximum Ever
		self.maxslider  = self:AddControl( "Slider",  {
			Label		= "Maximum To Spawn",
			Type		= "Integer",
			Min			= 0,
			Max			= 100,
			Command		= "npc_spawnplatform_totallimit",
			Description	= "The maximum NPCs allowed from the spawnpoint in one lifetime. The spawnpoint will turn off when this number is reached."
		});
	--Autoremove select
		self:AddControl( "Checkbox", {
			Label		= "Remove All Spawned NPCs on Platform Remove",
			Command		= "npc_spawnplatform_autoremove",
			Description	= "If this is checked, all NPCs spawned by a platform will be removed with the platform."
		});
	self:AddControl("Label", pad)
	
	self:AddControl("Label", {
		Text = "On / Off:"
	})
	--Numpad on/off select
		self:AddControl( "Numpad", {
			Label		= "#Turn On",
			Label2		= "#Turn Off",
			Command		= "npc_spawnplatform_onkey",
			Command2	= "npc_spawnplatform_offkey",
			ButtonSize	= 22
		});
	--Toggleable select
		self:AddControl( "Checkbox", {
			Label		= "Toggle On/Off With Use",
			Command		= "npc_spawnplatform_toggleable",
			Description	= "If this is checked, pressing Use on the spawn platform toggles the spawner on and off."
		});
	--Active select
		self:AddControl( "Checkbox", {
			Label		= "Start Active",
			Command		= "npc_spawnplatform_active",
			Description	= "If this is checked, spawned or updated platforms will be live."
		})
		

	-- Spawn Pos Header
		self:AddControl("Label", pad)
		
		self:AddControl("Label", {
			Text = "Positioning:"
		})
	-- Nocollide
		self:AddControl( "Checkbox", {
			Label		= "No Collision Between Spawned NPCs",
			Command		= "npc_spawnplatform_nocollide",
			Description = "If this is checked, NPCs will not collide with any other NPCs spawned with this option on. This helps prevent stacking in the spawn area"
		});
	--Spawnheight select
		self:AddControl( "Slider",  {
			Label		= "Spawn Height Offset",
			Type		= "Float",
			Min			= 8,
			Max			= 128,
			Command 	= "npc_spawnplatform_spawnheight",
			Description	= "(Only change if needed) Height above spawn platform NPCs originate from."
		});
	--Spawnradius select
		self:AddControl( "Slider",  {
			Label		= "Spawn X/Y Radius",
			Type		= "Float",
			Min			= 0,
			Max			= 128,
			Command 	= "npc_spawnplatform_spawnradius",
			Description = "(Use 0 if confused) Radius in which NPCs spawn (use small radius unless on flat open area)."
		});
	--Another header
		self:AddControl("Label", pad)
		
		self:AddControl("Label", {
			Text = "Other:"
		})
	--Healthmul select
		self:AddControl( "Slider",  {
			Label		= "Health Multiplier",
			Type		= "Float",
			Min			= 0.5,
			Max			= 5,
			Command		= "npc_spawnplatform_healthmul",
			Description = "The multiplier applied to the health of all NPCs on spawn."
		});
	-- Custom Squad Picker
		self:AddControl( "Slider",  {
			Label		= "Squad Override",
			Type		= "Integer",
			Min			= 1,
			Max			= 10,
			Command 	= "npc_spawnplatform_squadoverride",
			Description = "Squad number override (if custom squads is checked)"
		});
	-- Custom Squad On/Off
		self:AddControl( "Checkbox", {
			Label		= "Use Custom Squad Indexes",
			Command		= "npc_spawnplatform_customsquads",
			Description	= "If this is checked, NPCs spawn under the squad defined by the override. Otherwise NPCs will be put in a squad with their spawnmates."
		});
end
