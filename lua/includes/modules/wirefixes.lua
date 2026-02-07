--[[
	WireLib Additions
    Copyright 2013 Lex Robinson

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
]]
if not WireLib or WireLib.AddInputs then
	return;
end

--[[

	Adds functions to non-destructively add or remove
	 Wire inputs and outputs to and from an entity.

]]
local HasPorts = WireLib.HasPorts

local function CreateKeys(table)
	local ret = {}
	for _, key in pairs(table) do
		ret[key] = true
	end
	return ret
end

local function GetExistingPorts(ent_ports, exlcude)
	local names, types, descs = {}, {}, {}
	exlcude = exlcude or {}
	for name, port in pairs(ent_ports) do
		if not exlcude[name] then
			table.insert(names, name)
			table.insert(types, port.Type)
			table.insert(descs, port.Desc or false)
		end
	end
	for n, v in pairs(descs) do
		if not v then
			descs[n] = nil
		end
	end
	return names, types, descs
end

local function AddPorts(ent_ports, names, types, descs)
	types = types or {}
	descs = descs or {}

	local names_, types_, descs_ = GetExistingPorts(ent_ports)
	for n, name in pairs(names) do
		local i = #names_ + 1
		names_[i] = name
		types_[i] = types[n]
		descs_[i] = descs[n]
	end
	return names_, types_, descs_
end

function WireLib.AddSpecialInputs(ent, names, types, descs)
	if not (HasPorts(ent) and ent.Inputs) then
		return WireLib.CreateSpecialInputs(ent, names, types, descs)
	end
	names, types, descs = AddPorts(ent.Inputs, names, types, descs)
	return WireLib.AdjustSpecialInputs(ent, names, types, descs)
end

function WireLib.AddSpecialOutputs(ent, names, types, descs)
	if not (HasPorts(ent) and ent.Outputs) then
		return WireLib.CreateSpecialOutputs(ent, names, types, descs)
	end
	names, types, descs = AddPorts(ent.Outputs, names, types, descs)
	return WireLib.AdjustSpecialOutputs(ent, names, types, descs)
end

function Wire_RemoveInputs(ent, names)
	if not (HasPorts(ent) and ent.Inputs) then
		return
	end
	WireLib.AdjustSpecialInputs(ent,
		GetExistingPorts(ent.Inputs, CreateKeys(names)))
end

function Wire_RemoveOutputs(ent, names)
	if not (HasPorts(ent) and ent.Outputs) then
		return
	end
	WireLib.AdjustSpecialOutputs(ent,
		GetExistingPorts(ent.Outputs, CreateKeys(names)))
end

function Wire_AddInputs(ent, names, descs)
	return WireLib.AddSpecialInputs(ent, names, {}, descs)
end

function Wire_AddOutputs(ent, names, descs)
	return WireLib.AddSpecialOutputs(ent, names, {}, descs)
end

WireLib.AddInputs = Wire_AddInputs
WireLib.AddOutputs = Wire_AddOutputs
WireLib.RemoveInputs = Wire_RemoveInputs
WireLib.RemoveOutputs = Wire_RemoveOutputs
