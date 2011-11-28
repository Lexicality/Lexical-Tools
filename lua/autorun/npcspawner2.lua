--[[
	NPC Spawn Platforms V2.1
	~ Lexi ~
--]]

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
local datastreamHooks;
if (SERVER) then
    datastreamHooks = {};
    hook.Add("AcceptStream", "NPCSpawner AcceptStream", function(ply, handle)
        if (dastreamHooks[handle]) then
            return ply:IsAdmin();
        end
    end);
end
-- Whoopsie garry! TODO: Remove when fixed
net.WriteVars[TYPE_STRING] = function(t,v) net.WriteByte(t) net.WriteString(v) end
net.ReadVars[TYPE_STRING] = function() return net.ReadString() end

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
    send = function(name, tab, who)
        if (net) then
            net.Start(name);
            net.WriteTable(tab);
            if (CLIENT) then
                net.SendToServer();
            elseif (who) then
                net.Send(who);
            else
                net.Broadcast();
            end
        elseif (datastream) then
            if (CLIENT) then
                datastream.StreamToServer(name, tab);
            else
                datastream.StreamToClients(who, name, tab);
            end
        else
            error("No transport functions available!");
        end
    end;
    recieve = function(name, callback)
        if (net) then
            net.Receive(name, function(len, who)
                callback(net.ReadTable(), who);
            end);
        elseif (datastream) then
            if (CLIENT) then
                datastream.Hook(name, function(_, _, _, data)
                    callback(data);
                end);
            else
                datastreamHooks[name] = true;
                datastream.Hook(name, function(who, _, _, _, data)
                    callback(data, who);
                end);
            end
        else
            error("No transport functions available!");
        end
    end;
};
