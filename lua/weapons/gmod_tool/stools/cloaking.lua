--[[
	~ Cloaking STool ~
	~ Lexi ~
--]]

TOOL.Category = "Lexical Tools";
TOOL.Name = "Cloaking";

TOOL.ClientConVar["key"] = "5";
TOOL.ClientConVar["flicker"] = "0";
TOOL.ClientConVar["toggle"] = "1";
TOOL.ClientConVar["reversed"] = "0";
TOOL.ClientConVar["all"] = "1";
TOOL.ClientConVar["material"] = "sprites/heatwave";

local function checkTrace(tr)
	return (tr.Entity and tr.Entity:IsValid() and not (tr.Entity:IsPlayer() or tr.Entity:IsNPC() or tr.Entity:IsVehicle() or tr.HitWorld));
end

if (CLIENT) then
	usermessage.Hook("CloakingHurrah!", function()
		GAMEMODE:AddNotify("Entity is now cloakable!", NOTIFY_GENERIC, 10);
		surface.PlaySound ("ambient/water/drip" .. math.random(1, 4) .. ".wav");
	end);
	language.Add("Tool_cloaking_name", "Cloaking");
	language.Add("Tool_cloaking_desc", "Allows you to turn things invisible at the touch of a button");
	language.Add("Tool_cloaking_0", "Click on something to make it a cloakable. Reload to remove cloaking from something.");
	language.Add("Undone_cloaking", "Undone Cloaking");
	
	list.Set("CloakingMaterials", "Heatwave", "sprites/heatwave");
	list.Set("CloakingMaterials", "Light", "models/effects/vol_light001");
	
	function TOOL:BuildCPanel()
		self:AddControl("Header",   {Text = "#Tool_cloaking_name", Description = "#Tool_cloaking_desc"});
		self:AddControl("CheckBox", {Label = "Reversed (Starts invisible, becomes visible)", Command = "cloaking_reversed"});
		self:AddControl("CheckBox", {Label = "Flicker when damaged", Command = "cloaking_flicker"});
		self:AddControl("CheckBox", {Label = "Toggle Active", Command = "cloaking_toggle"});
		self:AddControl("CheckBox", {Label = "Cloak all constrained entities", Command = "cloaking_all"});
		self:AddControl("Numpad",   {Label = "Button", ButtonSize = "22", Command = "cloaking_key"});
		local options = {};
		for name, material in pairs(list.Get( "CloakingMaterials" )) do
			options[name] = { cloaking_material = material };
		end
		self:AddControl("Listbox", {Label = "Material:", MenuButton = 0, Height = 120, Options = options});
	end
	
	TOOL.LeftClick = checkTrace;
	
	return;
end	


local function cloakActivate(self)
	if (self.cloakActive) then return; end
	self.cloakActive = true;
	self.cloakPreviousMaterial = self:GetMaterial();
	self:SetMaterial(self.cloakMaterial)
	self:DrawShadow(false)
	if (WireLib) then
		Wire_TriggerOutput(self,  "CloakActive",  1);
	end
end

local function cloakDeactivate(self)
	if (not self.cloakActive) then return; end
	self.cloakActive = false;
	self:SetMaterial(self.cloakPreviousMaterial or "");
	self:DrawShadow(true);
end

local function cloakToggleActive(self)
	if (self.cloakActive) then
		self:cloakDeactivate();
	else
		self:cloakActivate();
	end
end

local function onDown(ply, ent)
	if (not (ent:IsValid() and ent.cloakToggleActive)) then
		return;
	end
	ent:cloakToggleActive();
end
numpad.Register("Cloaking onDown", onDown);

local function onUp(ply, ent)
	if (not (ent:IsValid() and ent.cloakToggleActive and not ent.cloakToggle)) then
		return;
	end
	ent:cloakToggleActive();
end
numpad.Register("Cloaking onUp", onUp);


--umsg.PoolString("CloakingHurrah!");
--[[ Wire Based Shit ]]--
local function doWireInputs(ent)
	local inputs = ent.Inputs;
	if (not inputs) then
		Wire_CreateInputs(ent, {"Cloak"});
		return;
	end
	local names, types, descs = {}, {}, {};
	local num;
	for _, data in pairs(inputs) do
		num = data.Num;
		names[num] = data.Name;
		types[num] = data.Type;
		descs[num] = data.Desc;
	end
	table.insert(names, "Cloak");
	WireLib.AdjustSpecialInputs(ent, names, types, descs);
end

local function doWireOutputs(ent)
	local outputs = ent.Outputs;
	if (not outputs) then
		Wire_CreateOutputs(ent, {"CloakActive"});
		return;
	end
	local names, types, descs = {}, {}, {};
	local num;
	for _, data in pairs(outputs) do
		num = data.Num;
		names[num] = data.Name;
		types[num] = data.Type;
		descs[num] = data.Desc;
	end
	table.insert(names, "CloakActive");
	WireLib.AdjustSpecialOutputs(ent, names, types, descs);
end

local function TriggerInput(self, name, value, ...)
	if (name == "Cloak") then
		if (value == 0) then
			if (self.cloakPrevWireOn) then
				self.cloakPrevWireOn = false;
				if (not self.cloakToggle) then
					self:cloakToggleActive();
				end
			end
		else
			if (not self.cloakPrevWireOn) then
				self.cloakPrevWireOn = true;
				self:cloakToggleActive();
			end
		end
	elseif (self.cloakTriggerInput) then
		return self:cloakTriggerInput(name, value, ...);
	end
end

local function PreEntityCopy(self)
	local info = WireLib.BuildDupeInfo(self)
	if (info) then
		duplicator.StoreEntityModifier(self, "WireDupeInfo", info);
	end
	if (self.wireSupportPreEntityCopy) then
		self:wireSupportEntityCopy();
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
	numpad.Remove(self.cloakUpNum);
	numpad.Remove(self.cloakDownNum);
end


-- Fer Duplicator
local function dooEet(ply, ent, stuff)
	if (ent.isCloakable) then
		ent:cloakDeactivate();
		onRemove(ent)
	else
		ent.isCloakable = true;
		ent.cloakActivate = cloakActivate;
		ent.cloakDeactivate = cloakDeactivate;
		ent.cloakToggleActive = cloakToggleActive;
		ent:CallOnRemove("Cloaking", onRemove);
		if (WireLib) then
			doWireInputs(ent);
			doWireOutputs(ent);
			ent.cloakTriggerInput = ent.cloakTriggerInput or ent.TriggerInput;
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
	ent.cloakUpNum = numpad.OnUp(ply, stuff.key, "Cloaking onUp", ent);
	ent.cloakDownNum = numpad.OnDown(ply, stuff.key, "Cloaking onDown", ent);
	ent.cloakToggle = stuff.toggle;
	ent.cloakMaterial = stuff.material;
	ent.cloakFlicker = stuff.flicker;
	if (stuff.reversed) then
		ent:cloakActivate();
	end
	duplicator.StoreEntityModifier(ent, "Lexical Cloaking", stuff);
	return true;
end

duplicator.RegisterEntityModifier("Lexical Cloaking", dooEet);

-- Legacy
duplicator.RegisterEntityModifier("Cloaking", function(ply, ent, Data) 
	return dooEet(ply, ent, {
		key = Data.Key;
		flicker = Data.Flicker;
		reversed = Data.Inversed;
		material = Data.Material;
		toggle = true;
	});
end);


local function doUndo(undoData, ent)
	if (IsValid(ent) and ent.isCloakable) then
		onRemove(ent);
		ent:cloakDeactivate();
		ent.isCloakable = false;
		if (WireLib) then
			ent.TriggerInput = ent.cloakTriggerInput;
			if (ent.Inputs) then
				Wire_Link_Clear(ent, "Cloak");
				ent.Inputs['Cloak'] = nil;
				WireLib._SetInputs(ent);
			end if (ent.Outputs) then
				local port = ent.Outputs['CloakActive']
				if (port) then
					for i,inp in ipairs(port.Connected) do -- From WireLib.lua: -- fix by Syranide: unlinks wires of removed outputs
						if (inp.Entity:IsValid()) then
							Wire_Link_Clear(inp.Entity, inp.Name)
						end
					end
				end
				ent.Outputs['CloakActive'] = nil;
				WireLib._SetOutputs(ent);
			end
		end
		return true;
	end
	return false;
end

hook.Add("EntityTakeDamage", "Cloaking Flicker Hook", function(ent)
	if (ent.isCloakable and ent.cloakFlicker and ent.cloakActive) then
		ent:cloakDeactivate();
		timer.Simple(0.05, ent.cloakActivate, ent);
	end
end);

local function massUndo(undoData)
	for i,ent in pairs(undoData.Entities) do
		doUndo(undoData, ent);
		undoData.Entities[i] = nil;
	end
end

function TOOL:LeftClick(tr)
	if (not checkTrace(tr)) then
		return false;
	end
	local ent = tr.Entity;
	local ply = self:GetOwner();
	local tab = {
		key      = self:GetClientNumber("key");
		toggle   = self:GetClientNumber("toggle") == 1;
		flicker  = self:GetClientNumber("flicker") == 1;
		reversed = self:GetClientNumber("reversed") == 1;
		material = self:GetClientInfo("material");
	};			
	undo.Create("cloaking");
	undo.SetPlayer(ply);
	undo.AddFunction(massUndo)
	if (self:GetClientNumber("all") == 0) then
		dooEet(ply, ent, tab);
		undo.AddEntity(ent);
	else
		for ent in pairs(constraint.GetAllConstrainedEntities(ent)) do
			dooEet(ply, ent, tab);
		undo.AddEntity(ent);
		end
	end
	undo.Finish();
	
	SendUserMessage("CloakingHurrah!", ply);
	return true
end

function TOOL:Reload(tr)
	return doUndo(_,tr.Entity);
end