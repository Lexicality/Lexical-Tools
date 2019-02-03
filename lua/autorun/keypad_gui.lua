--[[
	Keypads - lua/autorun/keypad_gui.lua
	Copyright 2018 Lex Robinson

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
--]]

local files = {
	"gui/derma_cvars.lua",
	"gui/NagLabel.lua",
	"gui/MinimumValueLabel.lua",
	"gui/KeypadPasswordNag.lua",
};

for _, file in ipairs(files) do
	if (SERVER) then
		AddCSLuaFile(file);
	else
		include(file);
	end
end
