--[[
	NPC Spawn Platforms V2.1
	~ Lexi ~
--]]

require'datastream';

function printd(...)
	if (GetConVarNumber("developer") > 0) then
		print(...)
	end
end
function printd2(...)
	if (GetConVarNumber("developer") > 1) then
		print(...)
	end
end
npcspawner = {
	debug = function(...)
		if (npcspawner.config.debug == 1) then
			printd("Spawn Platforms Debug ("..(SERVER and "server" or "client")..")",...);
		end
	end;
	debug2 = function(...)
		if (npcspawner.config.debug == 1) then
			printd2("Spawn Platforms Debug (Level 2) ("..(SERVER and "server" or "client")..")",...);
		end
	end;
};
