TOOL.Category    = "Lexical Tools"
TOOL.Name        = "#Resizable Crates"
TOOL.ClientConVar["scale"] = "1"

if (CLIENT) then
	language.Add("Tool_crate_name", "Resizable Crates");
	language.Add("Tool_crate_desc", "Creates a crate of the speicified size with full collisions");
	language.Add("Tool_crate_0",    "Left click to spawn a Crate");
	language.Add("Undone_crate",    "Undone Crate");
	language.Add("gmod_crate",      "Crate");
	

	function TOOL.BuildCPanel(cp)
		cp:AddControl("Header", {
			Text = "#Tool_crate_name",
			Description = "#Tool_crate_desc"
		});
		cp:AddControl("Slider", {
			Label = "Scale",
			Type = "Integer",
			Min = 1,
			Max = 10,
			Command = "crate_Scale"
		});
	end
	function TOOL:LeftClick(tr)
		return tr.Hit;
	end
	return
end

// Left click

function TOOL:LeftClick(tr)
	if (not tr.Hit) then
		return false;
	end
	
	local ply = self:GetOwner();
	local scale = self:GetClientNumber("scale");
	-- Make sure the number is acceptable
	scale = math.floor(math.Clamp(scale, 1, 10));
	
	local angles = tr.HitNormal:Angle();
	angles.pitch = angles.pitch + 90;
	local ent = MakeCrate(ply, tr.HitPos, angles, scale);
	if (not ent) then return false; end
	ent:SetPos(tr.HitPos - tr.HitNormal * ent:OBBMins().z);
	
	undo.Create("crate");
	undo.AddEntity(ent);
	undo.SetPlayer(ply);
	undo.Finish();
	
	return true;
end

function MakeCrate(ply, pos, angles, scale, data)
	if (not ply:CheckLimit("props")) then
		return false;
	end
	if (data) then
		ent = duplicator.GenericDuplicatorFunction(ply, data); -- This is actually better than doing it manually
	else
		ent = ents.Create("gmod_crate");
		ent:SetModel("models/props/de_dust/du_crate_64x64.mdl");
		ent:SetPos(pos);
		ent:SetAngles(angles);
		ent:Spawn();
	end
	ent:SetScale(scale);
	ent:Think(); -- Update the boundries NOW
	
	ply:AddCount("props",   ent);
	ply:AddCleanup("props", ent);
	return ent;
end
duplicator.RegisterEntityClass("gmod_crate", MakeCrate, "Pos", "Ang", "Scale", "Data")