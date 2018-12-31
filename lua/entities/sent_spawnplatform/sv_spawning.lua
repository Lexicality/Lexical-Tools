--[[
	NPC Spawn Platforms V2 - lua/entities/sent_spawnplatform/sv_spawning.lua
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

DEFINE_BASECLASS(ENT.Base);

local weaponsets = {
	weapon_rebel	= {"weapon_pistol", "weapon_smg1", "weapon_ar2", "weapon_shotgun"},
	weapon_combine	= {"weapon_smg1", "weapon_ar2", "weapon_shotgun"},
	weapon_citizen	= {"weapon_citizenpackage", "weapon_citizensuitcase", "weapon_none"}
};

--
-- gmod v14.04.19
-- garrysmod\gamemodes\sandbox\gamemode\commands.lua:288
--
local function InternalSpawnNPC( Player, Position, Normal, Class, Equipment, Angles, Offset )

	local NPCList = list.Get( "NPC" )
	local NPCData = NPCList[ Class ]

	-- Don't let them spawn this entity if it isn't in our NPC Spawn list.
	-- We don't want them spawning any entity they like!
	if ( not NPCData ) then
		if ( IsValid( Player ) ) then
			Player:SendLua( "Derma_Message( \"Sorry! You can't spawn that NPC!\" )" )
		end
	return end

	-- if ( NPCData.AdminOnly and not Player:IsAdmin() ) then return end

	local bDropToFloor = false

	--
	-- This NPC has to be spawned on a ceiling ( Barnacle )
	--
	if ( NPCData.OnCeiling and Vector( 0, 0, -1 ):Dot( Normal ) < 0.95 ) then
		return nil
	end

	--
	-- This NPC has to be spawned on a floor ( Turrets )
	--
	if ( NPCData.OnFloor and Vector( 0, 0, 1 ):Dot( Normal ) < 0.95 ) then
		return nil
	else
		bDropToFloor = true
	end

	if ( NPCData.NoDrop ) then bDropToFloor = false end

	--
	-- Offset the position
	--
	Offset = NPCData.Offset or Offset or 32
	Position = Position + Normal * Offset


	-- Create NPC
	local NPC = ents.Create( NPCData.Class )
	if ( not IsValid( NPC ) ) then return end

	NPC:SetPos( Position )

	-- Rotate to face player (expected behaviour)
	if (not Angles) then
		Angles = Angle( 0, 0, 0 )

		if ( IsValid( Player ) ) then
			Angles = Player:GetAngles()
		end

		Angles.pitch = 0
		Angles.roll = 0
		Angles.yaw = Angles.yaw + 180
	end

	if ( NPCData.Rotate ) then Angles = Angles + NPCData.Rotate end

	NPC:SetAngles( Angles )

	--
	-- This NPC has a special model we want to define
	--
	if ( NPCData.Model ) then
		NPC:SetModel( NPCData.Model )
	end

	--
	-- This NPC has a special texture we want to define
	--
	if ( NPCData.Material ) then
		NPC:SetMaterial( NPCData.Material )
	end

	--
	-- Spawn Flags
	--
	local SpawnFlags = bit.bor( SF_NPC_FADE_CORPSE, SF_NPC_ALWAYSTHINK )
	if ( NPCData.SpawnFlags ) then SpawnFlags = bit.bor( SpawnFlags, NPCData.SpawnFlags ) end
	if ( NPCData.TotalSpawnFlags ) then SpawnFlags = NPCData.TotalSpawnFlags end
	NPC:SetKeyValue( "spawnflags", SpawnFlags )

	--
	-- Optional Key Values
	--
	if ( NPCData.KeyValues ) then
		for k, v in pairs( NPCData.KeyValues ) do
			NPC:SetKeyValue( k, v )
		end
	end

	--
	-- This NPC has a special skin we want to define
	--
	if ( NPCData.Skin ) then
		NPC:SetSkin( NPCData.Skin )
	end

	--
	-- What weapon should this mother be carrying
	--

	-- Check if this is a valid entity from the list, or the user is trying to fool us.
	local valid = false
	for _, v in pairs( list.Get( "NPCUsableWeapons" ) ) do
		if v.class == Equipment then valid = true break end
	end

	if ( Equipment and Equipment ~= "none" and valid ) then
		NPC:SetKeyValue( "additionalequipment", Equipment )
		NPC.Equipment = Equipment
	end

	DoPropSpawnedEffect( NPC )

	NPC:Spawn()
	NPC:Activate()

	if ( bDropToFloor and not NPCData.OnCeiling ) then
		NPC:DropToFloor()
	end

	return NPC

end

local function legacySpawn(player, position, normal, class, weapon, angles, offset)
	local npc = ents.Create(class);
	if (not IsValid(npc)) then
		return nil;
	end
	npc:SetPos(position + normal * offset);
	npc:SetAngles(angles);
	if (weapon ~= "none") then
		npc:SetKeyValue("additionalequipment", weapon);
	end
	return npc;
end

local function rand()
	return math.random() * 2 - 1;
end

local function onremove(npc, platform)
	npcspawner.debug2("onremove", npc, platform);
	if (IsValid(platform)) then
		platform:NPCKilled(npc);
	end
end

function ENT:CheckOrientation()
	local _, data = self:GetSpawnClass();
	if (data) then
		local normal = self:GetSpawnNormal();

		if (data.OnCeiling and Vector(0, 0, -1):Dot(normal) < 0.95) then
			return false
		elseif (data.OnFloor and Vector(0, 0, 1):Dot(normal) < 0.95) then
			return false
		end
	end
	return true
end

function ENT:GetSpawnClass()
	local class = self:GetNPC();

	if (npcspawner.legacy[class]) then
		class = npcspawner.legacy[class];
	end

	local npcdata = list.Get('NPC')[class];
	if (not npcdata and npcspawner.config.sanity) then
		self:TurnOff();
		error(string.format("%s just tried to spawn NPC %q which is not on the NPC list!", self, class))
	end

	return class, npcdata;
end

function ENT:GetSpawnWeapon(npcdata)
	local weapon = self:GetNPCWeapon();
	if (weapon == 'weapon_none' or weapon == 'none') then
		weapon = nil;
	elseif (weaponsets[weapon]) then
		weapon = table.Random(weaponsets[weapon]);
	elseif (npcdata and npcdata.Weapons and (not weapon or weapon == '' or weapon == 'weapon_default')) then
		weapon = table.Random(npcdata.Weapons);
	end

	return weapon;
end

function ENT:GetSpawnNormal()
	return self:GetRight() * -1;
end

function ENT:GetSpawnLocation()
	local x, y, z = self:GetUp(), self:GetForward(), self:GetRight();

	local position = (x * rand() + y * rand()) * self:GetSpawnRadius();
	-- Face the NPC away from the centre of the platform
	local angles = Angle(0, position:Angle().y, 0)
	local offset = self:GetSpawnHeight();

	npcspawner.debug2("Offset:", position);
	npcspawner.debug2("Angles:", angles);
	npcspawner.debug2("Height:", offset);

	position = self:GetPos() + position;

	return position, angles, offset;
end

function ENT:ConfigureNPCSquad(npc)
	local squad;
	if (self:GetCustomSquad()) then
		squad = "squad" .. self:GetSquadOverride();
	else
		squad = tostring(self);
	end

	npcspawner.debug2("Squad:", squad);
	npc:SetKeyValue("squadname", squad);
end

function ENT:ConfigureNPCHealth(npc)
	local hp = npc:GetMaxHealth();
	local chp = npc:Health();
	-- Bug with nextbots
	if (chp > hp) then
		hp = chp;
	end
	hp = hp * self:GetNPCHealthMultiplier();
	npcspawner.debug2("Health:", hp);
	npc:SetMaxHealth(hp);
	npc:SetHealth(hp);
end

function ENT:ConfigureNPCWeapons(npc)
	if (npc.SetCurrentWeaponProficiency) then
		npc:SetCurrentWeaponProficiency(self:GetNPCSkillLevel());
	end
end

function ENT:ConfigureNPCCollisions(npc)
	if (self:GetNoCollideNPCs()) then
		npcspawner.debug2("Nocollided.");
		-- Collide with everything except interactive debris or debris
		npc:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS);
	end
end

function ENT:ConfigureNPCOwnership(npc)
	npc:CallOnRemove("NPCSpawnPlatform", onremove, self);
	self.NPCs[npc] = npc;
	duplicator.StoreEntityModifier(npc, self.__MODIFIER_ID, {
		id = self:GetCreationID(),
		myid = npc:GetCreationID(),
	});
end

function ENT:SpawnOne()
	local class, npcdata = self:GetSpawnClass();
	local weapon = self:GetSpawnWeapon();

	local ply = self:GetPlayer();
	if (npcspawner.config.callhooks == 1 and IsValid(ply)) then
		if (not gamemode.Call("PlayerSpawnNPC", ply, class, weapon)) then
			self.LastSpawn = CurTime() + 5; -- Disable spawning for 5 seconds so the user isn't spammed
			npcspawner.debug(ply, "has failed the PlayerSpawnNPC hook.");
			return false;
		elseif (npcdata.AdminOnly and not ply:IsAdmin()) then
			ply:ChatPrint("You may not spawn this NPC!");
			self:TurnOff();
			return false;
		end

	end

	npcspawner.debug(self, "is spawning a", class, "with a", weapon);

	local position, angles, offset = self:GetSpawnLocation();
	local normal = self:GetSpawnNormal();

	debugoverlay.Line(self:GetPos(), position, 10, color_white, true);
	debugoverlay.Axis(position, angles, 10, 10, true);
	debugoverlay.Line(position, position + normal * offset, 10, Color(255, 255, 0), true);

	local npc;
	if (npcdata) then
		npc = InternalSpawnNPC(ply, position, normal, class, weapon, angles, offset);
	else
		npc = legacySpawn(ply, position, normal, class, weapon, angles, offset);
	end

	if (not IsValid(npc)) then
		self:TurnOff();
		error("Failed to create a NPC of type '"..class.."'!");
	end

	npcspawner.debug2("NPC Entity:", npc);
	debugoverlay.Cross(npc:GetPos(), 10, 10, color_white, true);
	debugoverlay.Line(self:GetPos(), npc:GetPos(), 10, Color(255,0,0), true);
	timer.Simple(0.1, function() if (IsValid(npc)) then debugoverlay.Line(self:GetPos(), npc:GetPos(), 10, Color(0,255,0), true); end end)

	self:ConfigureNPCSquad(npc);
	self:ConfigureNPCHealth(npc);
	self:ConfigureNPCWeapons(npc);
	self:ConfigureNPCCollisions(npc);
	self:ConfigureNPCOwnership(npc);

	self.Spawned = self.Spawned + 1;
	self:TriggerWireOutput("ActiveNPCs", self.Spawned);

	self.TotalSpawned = self.TotalSpawned + 1;
	self:TriggerWireOutput("TotalNPCsSpawned", self.TotalSpawned);

	self.LastSpawn = CurTime();

	self:TriggerWireOutput("LastNPCSpawned", npc);

	self:TriggerOutput("OnNPCSpawned", self);
	self:TriggerWireOutput("OnNPCSpawned", 1);
	self:TriggerWireOutput("OnNPCSpawned", 0);

	if (npcspawner.config.callhooks == 1) then
		if (IsValid(ply)) then
			gamemode.Call("PlayerSpawnedNPC", ply, npc);
			if (CPPI) then
				npc:CPPISetOwner(ply);
			end
		end
	end

	if (self:GetDelayDecrease() > 0 and self.TotalSpawned % self:GetMaxNPCs() == 0) then
		npcspawner.debug(self.TotalSpawned.." NPCs spawned, decreasing delay ("..self:GetSpawnDelay()..") by "..self:GetDelayDecrease());
		self:SetSpawnDelay(math.max(self:GetSpawnDelay() - self:GetDelayDecrease(), npcspawner.config.mindelay));
	end

	if (self.TotalSpawned == self:GetMaxNPCsTotal()) then -- Since totallimit is 0 for off and totalspawned will always be > 0 at this point, shit works.
		npcspawner.debug("totallimit ("..self:GetMaxNPCsTotal()..") hit. Turning off.");
		self:TriggerOutput("OnLimitReached", self);
		self:TurnOff();
	end

	return true;
end

