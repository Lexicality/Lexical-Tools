--[[
	Fading Doors - lua\autorun\fading_doors.lua
    Copyright 2020 Lex Robinson

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
local prefix = "fading_doors_"

-- Replicated convars go here

if CLIENT then
	return
end

-- Server only convars go here
CreateConVar(
	prefix .. "mintime",
	0,
	FCVAR_ARCHIVE,
	"The minimum time a fading door must remain faded for",
	0
)
CreateConVar(
	prefix .. "physpersist",
	"false",
	FCVAR_ARCHIVE,
	"If unfrozen objects should be unfrozen when unfaded"
)

--- @param name string
--- @param oldVal string
--- @param newVal string
local function onChange(name, oldVal, newVal)
	fading_doors.SetConfig(string.sub(name, #prefix + 1), newVal)
end

local cvarNames = { "mintime", "physpersist" }

local function onInitialize()
	for _, name in pairs(cvarNames) do
		cvars.AddChangeCallback(prefix .. name, onChange, "Fading Doors Config")
		fading_doors.SetConfig(name, cvars.String(prefix .. name))
	end
end

hook.Add("Initialize", "Fading Doors Config", onInitialize)
