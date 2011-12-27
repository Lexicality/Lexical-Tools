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
