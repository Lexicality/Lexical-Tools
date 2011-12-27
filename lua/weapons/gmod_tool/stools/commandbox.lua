--[[
	~ Command Box STool ~
	~ Lexi ~
--]]

TOOL.Category    = "Lexical Tools"
TOOL.Name        = "#Command Box"
-- Bits of commands that aren't allowed to be sent
local disallowed = {
	"bind",
	"quit",
	"quti",
	"exit",
	"ent_fire",
	"rcon",
	"cl_",
	"net_",
	"mat_",
	"r_",
	"g_",
	"disconnect",
	"alias",
	"name"
}
TOOL.ClientConVar["model"] = "models/props_lab/reciever01a.mdl"
TOOL.ClientConVar["command"] = ""
TOOL.ClientConVar["key"] = "5"

cleanup.Register("commandboxes")

function TOOL:UpdateGhost(ent, ply) --( ent, player )
	if (not IsValid(ent)) then
		return;
	end
	local tr = ply:GetEyeTrace();
	if (not tr.Hit or (IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:GetClass() == "gmod_commandbox"))) then
		ent:SetNoDraw(true);
		return;
	end
	local angles = tr.HitNormal:Angle();
	angles.pitch = angles.pitch + 90;
	ent:SetAngles(angles);
	ent:SetPos(tr.HitPos - tr.HitNormal * ent:OBBMins().z);
	ent:SetNoDraw(false);
end

function TOOL:Think()
	if (SERVER and not SinglePlayer()) then return end
	if (CLIENT and SinglePlayer()) then return end
	local ent = self.GhostEntity;
	local model = string.lower(self:GetClientInfo("model"));
	if (not (IsValid(ent) and ent:GetModel() == model)) then
		self:MakeGhostEntity(model, vector_origin, Angle());
	end
	self:UpdateGhost(self.GhostEntity, self:GetOwner());
end

list.Set("CommandboxModels", "models/props_lab/reciever01a.mdl", {});
list.Set("CommandboxModels", "models/props_lab/monitor02.mdl", {});

local function canTool(tr)
	return tr.Hit and tr.HitWorld or (IsValid(tr.Entity) and not tr.Entity:IsPlayer())
end

if (CLIENT) then
	local messages = {
		"Commands cannot include the word '",
		"Updated Command Box",
		"Created Command Box"
	}
	usermessage.Hook("CommandBoxMessage", function(um)
		local message = um:ReadShort();
		if (message == 1) then
			local word = um:ReadShort();
			message = messages[message] .. disallowed[word] .. "'!";
		else
			message = messages[message];
		end
		GAMEMODE:AddNotify(message, NOTIFY_GENERIC, 10);
		surface.PlaySound ("ambient/water/drip" .. math.random(1, 4) .. ".wav");
	end);
	
	language.Add("Tool_commandbox_name", "Command Box Tool")
	language.Add("Tool_commandbox_desc", "Allows you to assign concommands to numpad keys.")
	language.Add("Tool_commandbox_0", "Left click to spawn a Command Box")
	
	// Other
	
	language.Add("Undone_commandbox", "Undone Command Box")
	language.Add("SBoxLimit_commandboxes", "You've hit the Command Boxes limit!")
	language.Add("Cleanup_commandboxes", "Command Boxes")
	language.Add("Cleaned_commandboxes", "Cleaned up all Command Boxes")
	TOOL.LeftClick = canTool;
	function TOOL.BuildCPanel(cp)
		cp:AddControl("Header", {Text = "#Tool_commandbox_name", Description = "#Tool_commandbox_desc"})
		
		cp:AddControl( "PropSelect", {
			Label = "Model:";
			ConVar = "commandbox_model";
			Category = "Models";
			Models = list.Get( "CommandboxModels" );
		});
		cp:AddControl("Numpad", {
			Label = "Key:";
			Command = "commandbox_key";
			ButtonSize = 22;
		});
		cp:AddControl("TextBox", {
			Label = "Command";
			MaxLength = "255";
			Command = "commandbox_command";
		});
	end
	return;
end

umsg.PoolString("CommandBoxMessage");
CreateConVar("sbox_maxcommandboxes", 10, FCVAR_NOTIFY)

local function msg(ply, num, num2)
	umsg.Start("CommandBoxMessage", ply)
	umsg.Short(num)
	if (num2) then
		umsg.Short(num2)
	end
	umsg.End();
end
function TOOL:LeftClick(tr)
	if (not canTool(tr)) then
		return false;
	end

	local ply = self:GetOwner();
	local model, command, key;
	key		= self:GetClientNumber("key");
	model	= self:GetClientInfo("model");
	command = self:GetClientInfo("command");
	
	local search = string.lower(command);
	for i, words in pairs(disallowed) do
		if (string.find(search, words)) then
			msg(ply, 1, i);
			return false;
		end
	end
	
	local ent = tr.Entity
	if (IsValid(ent) and ent:GetClass() == "gmod_commandbox" and ent:GetPlayer() == ply) then
		ent:SetCommand(command);
		ent:SetKey(key);
		msg(ply, 2);
		return true;
	end
		
	local angles = tr.HitNormal:Angle();
	angles.pitch = angles.pitch + 90;
	
	local box = MakeCommandBox(ply, tr.HitPos, angles, model, key, command);
	if (not box) then return false; end
	box:SetPos(tr.HitPos - tr.HitNormal * box:OBBMins().z);
	
	
	local weld;
	if (IsValid(ent) and not ent:IsWorld()) then
		weld = constraint.Weld(box, ent, 0, tr.PhysicsBone, 0);
		ent:DeleteOnRemove(box);
	else
		local phys = box:GetPhysicsObject();
		if (IsValid(phys)) then
			phys:EnableMotion(false);
		end
	end
	
	undo.Create("commandbox");
	undo.AddEntity(box);
	undo.AddEntity(weld);
	undo.SetPlayer(ply);
	undo.Finish();
	
	ply:AddCleanup("commandboxes", box);
	ply:AddCleanup("commandboxes", weld);
	
	msg(ply, 3);
	
	return true;
end
