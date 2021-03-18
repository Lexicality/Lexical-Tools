--[[
	Lexical Tools - lua/autorun/server/lexical-tools.lua
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
]] --
local L10N_FOLDER = "resource/localization/"

--- Finds and `resource.AddFile`s all localisation files for all available languages
--- @param name string @eg "foo.properties"
function resource.AddL10nFile(name)
	local _, langFolders = file.Find(L10N_FOLDER .. "*", "GAME")
	for _, folder in pairs(langFolders) do
		local search = L10N_FOLDER .. folder .. "/" .. name
		if file.Exists(search, "GAME") then
			resource.AddFile(search)
		end
	end
end

hook.Add("Initialize", "Lexical Tools L10n", function()
	resource.AddL10nFile("lexical_tools.properties")
end)
