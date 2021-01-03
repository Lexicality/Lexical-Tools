--[[
	Keypads - lua/autorun/keypad.lua
	Copyright 2018-2020 Lex Robinson

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]] --
local files = {
	"gui/derma_cvars.lua",
	"gui/NagLabel.lua",
	"gui/MinimumValueLabel.lua",
	"gui/KeypadPasswordNag.lua",
}

for _, file in ipairs(files) do
	if (SERVER) then
		AddCSLuaFile(file)
	else
		include(file)
	end
end

CreateConVar("keypad_min_length", 0, FCVAR_REPLICATED + FCVAR_ARCHIVE,
             "The minimum time keypads must remain on for")
CreateConVar("keypad_cracker_time", 15, FCVAR_REPLICATED + FCVAR_ARCHIVE,
             "How many seconds it takes to crack a keypad")
if SERVER then
	CreateConVar("keypad_fast_entry", 1, FCVAR_ARCHIVE,
             	"If the keypad's owner should be able to open it without a password")

	CreateConVar("sbox_maxkeypads", 10, FCVAR_ARCHIVE)

	CreateConVar("keypad_min_recharge", 2, FCVAR_ARCHIVE,
             	"The minimum time between keypad code attempts")
	-- Potentially a user could lock out a keypad for two and a half minutes, so don't let them
	CreateConVar("keypad_max_recharge", 30, FCVAR_ARCHIVE,
             	"The maximum time between keypad code attempts (to avoid long timer abuse)")

	-- This is a highly abusable mechanic, so disable it by default but let servers enable it if they trust their players
	CreateConVar("keypad_cracking_wire_output", 0, FCVAR_ARCHIVE,
             	"Add a wire output that shows if a keypad is being cracked")
end
