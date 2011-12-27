--[[
	~ Fading Door STool ~
	~ Based on Conna's, but this time it works. ~
	~ Lexi ~
--]]

--[[ Tool Related Settings ]]--
TOOL.Category = "Lexical Tools";
TOOL.Name = "#Fading Doors";

TOOL.ClientConVar["key"] = "5"
TOOL.ClientConVar["toggle"] = "0"
TOOL.ClientConVar["reversed"] = "0"

local function checkTrace(tr)
    return IsValid(tr.Entity) and not (tr.Entity:IsPlayer() or tr.Entity:IsNPC() or tr.Entity:IsVehicle());
end

if (CLIENT) then
	usermessage.Hook("FadingDoorHurrah!", function()
		GAMEMODE:AddNotify("Fading door has been created!", NOTIFY_GENERIC, 10);
		surface.PlaySound ("ambient/water/drip" .. math.random(1, 4) .. ".wav");
	end);
	language.Add("Tool_fading_doors_name", "Fading Doors");
	language.Add("Tool_fading_doors_desc", "Makes anything into a fadable door");
	language.Add("Tool_fading_doors_0", "Click on something to make it a fading door. Reload to set it back to normal");
	language.Add("Undone_fading_door", "Undone Fading Door");
	
	function TOOL.BuildCPanel(panel)
        panel:CheckBox("Reversed (Starts invisible, becomes solid)", "fading_doors_reversed");
	    panel:CheckBox("Toggle Active", "fading_doors_toggle");
        panel:AddControl("Numpad",
            {
                Label = "Button",
                Command = "fading_doors_key"
            }
        );
	end
	
	TOOL.LeftClick = checkTrace;
	
	return;
end	

local function fadeActivate(self)
	if (self.fadeActive) then return; end
	self.fadeActive = true;
	self.fadeMaterial = self:GetMaterial();
	self:SetMaterial("sprites/heatwave")
	self:DrawShadow(false)
	self:SetNotSolid(true)
	--self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	local phys = self:GetPhysicsObject();
	if (IsValid(phys)) then
		self.fadeMoveable = phys:IsMoveable();
		phys:EnableMotion(false);
	end
	if (WireLib) then
		Wire_TriggerOutput(self,  "FadeActive",  1);
	end
end

local function fadeDeactivate(self)
	if (not self.fadeActive) then return; end
	self.fadeActive = false;
	self:SetMaterial(self.fadeMaterial or "");
	self:DrawShadow(true);
	self:SetNotSolid(false);
	--self:SetCollisionGroup(COLLISION_GROUP_NONE);
	local phys = self:GetPhysicsObject();
	if (IsValid(phys)) then
		phys:EnableMotion(self.fadeMoveable or false);
	end
	if (WireLib) then
		Wire_TriggerOutput(self,  "FadeActive",  0);
	end
end

local function fadeToggleActive(self)
	if (self.fadeActive) then
		self:fadeDeactivate();
	else
		self:fadeActivate();
	end
end

--[[
	These are to prevent multiple concurrent on/off calls from glitching the door
--]]
local function fadeInputOn(self)
	if (self.fadeInputActive) then
		return;
	end
	self.fadeInputActive = true;
	self:fadeToggleActive();
end

local function fadeInputOff(self)
	if (not self.fadeInputActive) then
		return;
	end
	self.fadeInputActive = false;
	if (not self.fadeToggle) then
		self:fadeToggleActive();
	end
end

local function onDown(ply, ent)
	if (not (ent:IsValid() and ent.fadeToggleActive)) then
		return;
	end
	ent:fadeInputOn();
end
numpad.Register("Fading Doors onDown", onDown);


local function onUp(ply, ent)
	if (not (ent:IsValid() and ent.fadeToggleActive)) then
		return;
	end
	ent:fadeInputOff();
end
numpad.Register("Fading Doors onUp", onUp);

local function doWireInputs(ent)
    if (not WireLib.AddInputs) then
        ErrorNoHalt("Lexical Tools Wire Compatability script not loaded! No wire inputs have been added to this entity!\n");
        return;
    end
    WireLib.AddInputs(ent, {"Fade"});
end

local function doWireOutputs(ent)
    if (not WireLib.AddOutputs) then
        ErrorNoHalt("Lexical Tools Wire Compatability script not loaded! No wire outputs have been added to this entity!\n");
        return;
    end
    WireLib.AddOutputs(ent, {"FadeActive"}, {"If this entity is currently faded."});
end

local function TriggerInput(self, name, value, ...)
	if (name == "Fade") then
		if (value == 0) then
			if (self.fadePrevWireOn) then
				self.fadePrevWireOn = false;
				self:fadeInputOff();
			end
		else
			if (not self.fadePrevWireOn) then
				self.fadePrevWireOn = true;
				self:fadeInputOn();
			end
		end
	elseif (self.fadeTriggerInput) then
		return self:fadeTriggerInput(name, value, ...);
	end
end

local function PreEntityCopy(self)
	local info = WireLib.BuildDupeInfo(self)
	if (info) then
		duplicator.StoreEntityModifier(self, "WireDupeInfo", info);
	end
	if (self.wireSupportPreEntityCopy) then
		self:wireSupportPreEntityCopy();
	end
end

local function PostEntityPaste(self, ply, ent, ents)
	if (self.EntityMods and self.EntityMods.WireDupeInfo) then
		WireLib.ApplyDupeInfo(ply, self, self.EntityMods.WireDupeInfo, function(id) return ents[id]; end);
	end
	if (self.wireSupportPostEntityPaste) then
		self:wireSupportPostEntityPaste(ply, ent, ents);
	end
end
	

local function onRemove(self)
	numpad.Remove(self.fadeUpNum);
	numpad.Remove(self.fadeDownNum);
end

-- Fer Duplicator
local function dooEet(ply, ent, stuff)
	if (ent.isFadingDoor) then
		ent:fadeDeactivate();
		onRemove(ent)
	else
		ent.isFadingDoor = true;
		ent.fadeActivate = fadeActivate;
		ent.fadeDeactivate = fadeDeactivate;
		ent.fadeToggleActive = fadeToggleActive;
		ent.fadeInputOn = fadeInputOn;
		ent.fadeInputOff = fadeInputOff;
		ent:CallOnRemove("Fading Doors", onRemove);
		if (WireLib) then
			doWireInputs(ent);
			doWireOutputs(ent);
			ent.fadeTriggerInput = ent.fadeTriggerInput or ent.TriggerInput;
			ent.TriggerInput = TriggerInput;
			if (not (ent.IsWire or ent.addedWireSupport)) then -- Dupe Support
				ent.wireSupportPreEntityCopy = ent.PreEntityCopy;
				ent.PreEntityCopy = PreEntityCopy;
				ent.wireSupportPostEntityPaste = ent.PostEntityPaste;
				ent.PostEntityPaste = PostEntityPaste;
				ent.addedWireSupport = true
			end				
		end
	end
	ent.fadeUpNum = numpad.OnUp(ply, stuff.key, "Fading Doors onUp", ent);
	ent.fadeDownNum = numpad.OnDown(ply, stuff.key, "Fading Doors onDown", ent);
	ent.fadeToggle = stuff.toggle;
	if (stuff.reversed) then
		ent:fadeActivate();
	end
	duplicator.StoreEntityModifier(ent, "Fading Door", stuff);
	return true;
end

duplicator.RegisterEntityModifier("Fading Door", dooEet);

if (not FadingDoor) then
	local function legacy(ply, ent, data)
		return dooEet(ply, ent, {
			key      = data.Key;
			toggle   = data.Toggle;
			reversed = data.Inverse;
		});
	end
	duplicator.RegisterEntityModifier("FadingDoor", legacy);
end

local function doUndo(undoData, ent)
	if (IsValid(ent) and ent.isFadingDoor) then
		onRemove(ent); -- Get rid of the numpad inputs.
		ent:fadeDeactivate(); -- Ensure the doors are turned off when we remove 'em :D
		ent.isFadingDoor = false; -- We don't actually delete the fading door functions, to save time.
		duplicator.ClearEntityModifier(ent, "Fading Door"); -- Make sure we don't unexpectedly re-add removed doors when duped.
		-- [[ 'Neatly' remove the Wire inputs/outputs without disturbing the pre-existing ones. ]] --
		if (WireLib) then
			ent.TriggerInput = ent.fadeTriggerInput; -- Purge our input checker
			if (ent.Inputs) then
				Wire_Link_Clear(ent, "Fade");
				ent.Inputs['Fade'] = nil;
				WireLib._SetInputs(ent);
			end if (ent.Outputs) then
				local port = ent.Outputs['FadeActive']
				if (port) then
					for i,inp in ipairs(port.Connected) do -- From WireLib.lua: -- fix by Syranide: unlinks wires of removed outputs
						if (inp.Entity:IsValid()) then
							Wire_Link_Clear(inp.Entity, inp.Name)
						end
					end
				end
				ent.Outputs['FadeActive'] = nil;
				WireLib._SetOutputs(ent);
			end
		end
		return true;
	end
	return false;
end

function TOOL:LeftClick(tr)
	if (not checkTrace(tr)) then
		return false;
	end
	local ent = tr.Entity;
	local ply = self:GetOwner();
	dooEet(ply, ent, {
		key      = self:GetClientNumber("key");
		toggle   = self:GetClientNumber("toggle") == 1;
		reversed = self:GetClientNumber("reversed") == 1;
	});
	undo.Create("fading_door");
		undo.AddFunction(doUndo, ent);
		undo.SetPlayer(ply);
	undo.Finish();
	
	SendUserMessage("FadingDoorHurrah!", ply);
	return true
end

function TOOL:Reload(tr)
	return doUndo(_,tr.Entity);
end
