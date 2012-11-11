--[[
	NPC Spawn Platforms V2.1
    Copyright (c) 2011-2012 Lex Robinson
    This code is freely available under the MIT License
--]]

--[[ Make the platform dupable ]]--
duplicator.RegisterEntityClass("sent_spawnplatform",  function(ply,  pos,  angles,  data)
    local ent = ents.Create("sent_spawnplatform");
    ent:SetAngles(angles);
    ent:SetPos(pos);
    for key, value in pairs(data) do
        if (key:sub(1, 2) == "k_") then
            ent:SetKeyValue(key:sub(3), value);
        end
    end
    ent:SetKeyValue("ply", ply:EntIndex());
    ent:Spawn();
    ent:Activate();
    ply:AddCount("sent_spawnplatform", ent);
    return ent;
end,  "Pos",  "Angle",  "Data");
AddCSLuaFile("shared.lua");
include('shared.lua');
local model1 = Model("models/props_c17/streetsign004e.mdl");
local model2 = Model("models/props_c17/streetsign004f.mdl");

local complextypes = {
        npc_citizen_medic = {
			class   = "npc_citizen", 
			kvs     = {
					citizentype = CT_REBEL, 
					spawnflags  = 131072
			}
        }, 
        npc_citizen_rebel = {
			class = "npc_citizen", 
			kvs = {
					citizentype = CT_REBEL
			}
        }, 
        npc_citizen_dt = {
			class = "npc_citizen", 
			kvs = {
					citizentype = CT_DOWNTRODDEN
			}
        }, 
        npc_citizen = {
			class = "npc_citizen", 
			kvs = {
					citizentype = CT_DEFAULT
			}
        }, 
		npc_citizen_refugee = {
			class = "npc_citizen", 
			kvs = {
					citizentype = CT_REFUGEE
			}
		}, 	
        npc_combine_e = {
			class = "npc_combine_s", 
			kvs = {
					model = "models/combine_super_soldier.mdl"
			}
        }, 
        npc_combine_p = {
			class = "npc_combine_s", 
			kvs = {
					model = "models/combine_soldier_prisonguard.mdl"
			}
        }
};
local weaponsets = {
	weapon_rebel	= {"weapon_pistol",  "weapon_smg1",  "weapon_ar2",  "weapon_shotgun"}, 
	weapon_combine	= {"weapon_smg1",  "weapon_ar2",  "weapon_shotgun"}, 
	weapon_citizen	= {"weapon_citizenpackage",  "weapon_citizensuitcase",  "weapon_none"}
};

-- Default Settings
ENT.k_npc				= "npc_combine_s";
ENT.k_weapon			= "weapon_smg1";
ENT.NPCs 				= {};
ENT.k_spawnheight		= 16;
ENT.k_spawnradius		= 16;
ENT.k_maximum			= 5;
ENT.k_delay				= 5;
ENT.k_onkey				= 2;
ENT.k_offkey			= 1;
ENT.k_healthmul			= 1;
ENT.k_toggleable		= 1;
ENT.k_autoremove		= 1;
ENT.k_squadoverride		= 1;
ENT.k_customsquads		= 0;
ENT.k_totallimit		= 0;
ENT.k_decrease			= 0;
ENT.k_active			= 0;
ENT.k_ply				= 0;
ENT.k_skill				= WEAPON_PROFICIENCY_AVERAGE;
ENT.Spawned             = 0;
ENT.LastSpawn           = 0;
ENT.LastChange          = 0;
ENT.TotalSpawned		= 0;

function ENT:SpawnFunction(ply,  tr)
	if (not tr.Hit) then return end
	local ent = ents.Create ("sent_spawnplatform");
	ent:SetPos (tr.HitPos + tr.HitNormal * 16);
	ent:Spawn();
	ent:Activate();
	return ent;
end

numpad.Register ("NPCSpawnerOn",  function(ply,  ent)
	npcspawner.debug("Numpad on called for", ent, "by", ply);
	if (IsValid(ent)) then
		ent:TurnOn();
	else
		npcspawner.debug("Invalid entity provided?!");
	end
end);

numpad.Register ("NPCSpawnerOff",  function(ply,  ent)
	npcspawner.debug("Numpad off called for",  ent,  "by",  ply);
	if (IsValid(ent)) then
		ent:TurnOff();
	else
		npcspawner.debug("Invalid entity provided?!");
	end
end);

function ENT:Initialize ()
	self:SetModel(model1);
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid	(SOLID_VPHYSICS);
	local phys = self:GetPhysicsObject();
	if (IsValid(phys)) then
		phys:Wake();
	else
		ErrorNoHalt("No physics object for ", tostring(self), " using model ", model1, "?\n");
	end
	self.LastSpawn  = 0;
	self:CheckActive();
	self.Spawned  = 0;
	self.NPCs   = {};
	if (WireLib) then
	--[[ People wanted wire control,  here is your wire control. ]]--
		WireLib.CreateSpecialInputs (self,  {
			"SetActive", 				-- active
			"SpawnOne",
			"NPCClass", 				-- npc
			"MaxActiveNPCs", 		-- maximum
			"SpawnDelay", 			-- delay
			"Weapon", 				-- weapon
			"HealthMultiplier", 		-- healthmul
			"MaxSpawnedNPCs", 		-- totallimit
			"DelayDecreaseAmount", 	-- decrease
			"RemoveNPCs", 
				},  {
			"NORMAL", 
			"NORMAL",
			"STRING", 
			"NORMAL", 
			"NORMAL", 
			"STRING", 
			"NORMAL", 
			"NORMAL", 
			"NORMAL", 
			"NORMAL"
			--[[
				}, {
			"Set the active state of the platform",
			"Force the spawning of a NPC",
			"Set the class of NPC to spawn",
			"Set the max number of active NPCs",
			"Set the spawn delay",
			"Set what weapon to give the NPCs",
			"Set the health multiplier for the NPCs",
			"Set how much to decrease the delay by every MaxActiveNPCs spawned",
			"Delete all NPCs currently spawned."				
			--]]
		});
		WireLib.CreateSpecialOutputs(self,  {
			"IsOn", 
			"ActiveNPCs", 
			"TotalNPCsSpawned", 
			"LastNPCSpawned", 
			"OnNPCSpawned"
				},  {
			"NORMAL",  "NORMAL",  "NORMAL",  "ENTITY",  "NORMAL"
			--[[	}, {
			"Is the platform on?",
			"The number of currently active NPCs",
			"The total number of NPCs spawned this active session",
			"The last NPC the platform spawned",
			"Triggered every time a NPC is spawned."--]]
		});
	end
	self.Ply = player.GetByID(tonumber(self.k_ply));
	if (not IsValid(self.Ply)) then return end
	numpad.OnDown (self.Ply,  self.k_onkey,   "NPCSpawnerOn",   self);
	numpad.OnDown (self.Ply,  self.k_offkey,  "NPCSpawnerOff",  self);
end

function ENT:Think()
	if (self.Spawned < 0) then self.Spawned = 0 end
	if (self._WireSpawnedActive) then
		Wire_TriggerOutput(self,  "OnNPCSpawned",  0);
		self._WireSpawnedActive = nil;
	end		
	if (self.k_active == 0 or self.Spawned >= self.k_maximum or self.LastSpawn + self.k_delay > CurTime()) then return end
	self:SpawnOne();
end
local function onremove(npc, platform)
		if (IsValid(platform)) then
			platform:NPCKilled(npc);
		end
	end
local ang = Angle(0, 0, 0);
function ENT:SpawnOne()
	local class, kvs = self.k_npc, {};
	npcspawner.debug(self,  "is spawning a",  class);
	local cplex = complextypes[class]
	if (cplex) then
		class	= cplex.class;
		kvs 	= cplex.kvs;
	end
	local wep = (weaponsets[self.k_weapon]) and table.Random(weaponsets[self.k_weapon]) or self.k_weapon;
	if (npcspawner.config.callhooks == 1) then
		if (IsValid(self.Ply)) then
			if (not gamemode.Call("PlayerSpawnNPC", self.Ply, class, (wep ~= "weapon_none") and wep or nil)) then
				self.LastSpawn = CurTime() + 5; -- Disable spawning for 5 seconds so the user isn't spammed
				npcspawner.debug(self.Ply,  "has failed the PlayerSpawnNPC hook.");
				return false;
			end
		end
	end
	local npc = ents.Create(class);
	if (not IsValid(npc)) then
		self:TurnOff();
		error("Failed to create a NPC of type '"..class.."'!");
	end
	local pos = VectorRand() * self.k_spawnradius;
	pos.z = self.k_spawnheight;
	npcspawner.debug2("Offset:",  pos);
	npc:SetPos(self:GetPos() + pos);
	--[ Test rotational shit
	ang.y = pos:Angle().y
	npcspawner.debug2("Angles:",  ang);
	npc:SetAngles(ang);
	--]]
	npcspawner.debug2("Weapon:", wep);
	if (wep ~= "weapon_none") then
		npc:SetKeyValue("additionalequipment", wep);
	end
	local debugstr = "";
	for k, v in pairs(kvs) do
		npc:SetKeyValue(k, v);
		debugstr = debugstr.."\tKey = "..k.."; Value = "..v.."\n";
	end
	npcspawner.debug2("Keyvalues:\n", debugstr);
	-- 
	local squad = (self.k_customsquads == 1) and "squad"..self.k_squadoverride or tostring(self);
	npcspawner.debug2("Squad:", squad);
	npc:SetKeyValue("squadname", squad);
	npc:Spawn();
	local hp = npc:GetMaxHealth() * self.k_healthmul;
	npcspawner.debug2("Health:", hp);
	npc:SetMaxHealth(hp);
	npc:SetHealth(hp);
	npc:SetCurrentWeaponProficiency(self.k_skill);
	if (self.k_nocollide == 1) then
		npcspawner.debug2("Nocollided.");
		npc:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS); -- Collides with everything except interactive debris or debris
	end
	npc:CallOnRemove("NPCSpawnPlatform", onremove, self);
	npcspawner.debug2("NPC Entity:", npc);
	if (npcspawner.config.callhooks == 1)then
		if (IsValid(self.Ply)) then
			gamemode.Call("PlayerSpawnedNPC", self.Ply, npc);
		end
	end
	self.NPCs[npc] = npc;
	self.Spawned = self.Spawned + 1;
	self.TotalSpawned = self.TotalSpawned + 1;
	self.LastSpawn = CurTime();
	if (self.TotalSpawned % self.k_maximum == 0) then
		npcspawner.debug(self.TotalSpawned.." NPCs spawned,  decreasing delay ("..self.k_delay..") by "..self.k_decrease);
		self.k_delay = math.max(self.k_delay - self.k_decrease, npcspawner.config.mindelay);
	end
	if (Wire_TriggerOutput) then
		Wire_TriggerOutput(self,  "ActiveNPCs",  self.Spawned);
		Wire_TriggerOutput(self,  "TotalNPCsSpawned",  self.TotalSpawned);
		Wire_TriggerOutput(self,  "LastNPCSpawned",  npc);
		Wire_TriggerOutput(self,  "OnNPCSpawned",  1);
		Wire_TriggerOutput(self,  "OnNPCSpawned",  0);
		--self._WireSpawnedActive = true;
	end
	if (self.TotalSpawned == self.k_totallimit) then -- Since totallimit is 0 for off and totalspawned will always be > 0 at this point,  shit works.
		npcspawner.debug("totallimit ("..self.k_totallimit..") hit. Turning off.");
		self:TurnOff();
	end
end

function ENT:NPCKilled(npc)
	self.NPCs[npc] = nil;
	self.Spawned = self.Spawned - 1;
	if (Wire_TriggerOutput) then
		Wire_TriggerOutput(self,  "ActiveNPCs",  self.Spawned);
	end
end

function ENT:Use (activator,  caller)
	if (self.k_toggleable == 0 or self.LastChange + 1 > CurTime()) then
		return;
	end
	npcspawner.debug(self, "has been used by", activator, caller)
	self:Toggle();
end

function ENT:Toggle()
	if (self.k_active == 0) then
		npcspawner.debug(self, "has toggled from off to on.");
		self:TurnOn();
	else
		npcspawner.debug(self, "has toggled from on to off.");
		self:TurnOff();
	end
end

function ENT:TurnOn()
	self.k_active = 1;
	self.TotalSpawned = 0;
	self.k_delay = self.Delay;
	if (Wire_TriggerOutput) then
		Wire_TriggerOutput(self,  "TotalNPCsSpawned",  self.TotalSpawned);
	end
	self:CheckActive();
end
function ENT:TurnOff()
	self.k_active = 0;
	self:CheckActive();
end

local color_on  = Color(0, 255, 0);
local color_off = Color(255, 0, 0);
local _, oldStyleGetColor, a, c;
function ENT:CheckActive()
	c, oldStyleGetColor, _, a = self:GetColor();
	if (self.k_active == 1) then
		self:SetModel (model1);
		self.LastSpawn = CurTime();
        if (oldStyleGetColor) then
            self:SetColor (0, 255, 0, a);
        else
            if (self.GetAlpha) then
                local a = self:GetAlpha();
                self:SetColor(color_on);
                self:SetAlpha(a);
            else
                c.r = 0;
                c.g = 255;
                c.b = 0;
                self:SetColor(c);
            end
        end
	else
		self:SetModel (model2);
        if (oldStyleGetColor) then
            self:SetColor (255, 0, 0, a);
        else
            if (self.GetAlpha) then
                local a = self:GetAlpha();
                self:SetColor(color_off);
                self:SetAlpha(a);
            else
                c.r = 255;
                c.g = 0;
                c.b = 0;
                self:SetColor(c);
            end
        end
	end
	if (Wire_TriggerOutput) then
		Wire_TriggerOutput(self,  "IsOn",  self.k_active);
	end
	self:SetNWString("active",  self.k_active);
	self.LastChange = CurTime();
end

local nwablekeys = {
	npc		= true, 
	weapon	= true, 
	maximum	= true, 
	delay	= true
}
-- Using keyvalues allows us to have a callback for each value,  should it be needed.
function ENT:KeyValue (key,  value)
	npcspawner.debug2("Key:", key, "Value:", value);
	if (key == "delay") then
		self.LastSpawn = CurTime();
		self.Delay = value;
		value = math.max(value,npcspawner.config.mindelay);
	elseif (key == "active") then
		self:CheckActive();
	end
	self["k_"..key] = tonumber(value) or value;
	if (nwablekeys[key]) then -- Only some keys need to be networked,  let's try to keep traffic as low as possible :D
		self:SetNWString(key,  value);
		self:UpdateLabel();
	end
end

function ENT:RemoveNPCs()
	npcspawner.debug(self, "is deleting its NPCs.");
	for ent in pairs(self.NPCs) do
		if IsValid(ent) then
			ent:Remove();
		end
	end
	self.Spawned = 0;
	if (Wire_TriggerOutput) then
		Wire_TriggerOutput(self,  "ActiveNPCs",  self.Spawned);
	end
end

function ENT:OnRemove()
	npcspawner.debug(self, "has been removed.");
	if (self.k_autoremove == 1) then
		self:RemoveNPCs();
	end
end

--[[ Wire based shit ]]--
function ENT:TriggerInput(name,  val)
	npcspawner.debug2(self, "has recieved wire input with name", name, "and value", val);
	if (name == "SetActive") then
		if (val == 0) then
			self:TurnOff();
		else
			self:TurnOn();
		end
	elseif (name == "RemoveNPCs") then
		if (val ~= 0) then
			self:RemoveNPCs();
		end
	elseif (name == "SpawnOne") then
		if (val ~= 0) then
			self:SpawnOne();
		end
	elseif (name == "NPCClass") then
		self:KeyValue("npc", val);
	elseif (name == "MaxActiveNPCs") then
		self:KeyValue("maximum", val);
	elseif (name == "SpawnDelay") then
		self:KeyValue("delay", val);
	elseif (name == "Weapon") then
		self:KeyValue("weapon", val);
	elseif (name == "HealthMultiplier") then
		self:KeyValue("healthmul", val);
	elseif (name == "MaxSpawnedNPCs") then
		self:KeyValue("totallimit", val);
	elseif (name == "DelayDecreaseAmount") then
		self:KeyValue("decrease", val);
	end
end
