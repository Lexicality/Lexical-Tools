--[[
	NPC Spawn Platforms V2 - lua/autorun/client/panel-npcselect.lua
    Copyright 2009-2017 Lex Robinson

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

local PANEL = {};

DEFINE_BASECLASS "DPropertySheet";

AccessorFunc( PANEL, "m_ConVar", "ConVar" );

function PANEL:Init()
	local npcs = list.Get('NPC');

	function onNPCSelected(_, _, line)
		RunConsoleCommand( self:GetConVar(), line.nicename )
	end

	-- All tab
	local ctrl = vgui.Create( "DListView" );
	ctrl:SetMultiSelect( false );
	ctrl:AddColumn( "#npcs" );
	ctrl:AddColumn( "#category" );

	for nicename, data in pairs( npcs ) do
		local line = ctrl:AddLine( data.Name, data.Category or "Other" )
		line.nicename = nicename;
	end

	ctrl.OnRowSelected = onNPCSelected;
	ctrl:SortByColumn(2, false);
	self:AddSheet("#All", ctrl);

	local categories = {};

	for nicename, data in pairs(npcs) do
		local cat = data.Category or "Other";
		categories[cat] = categories[cat] or {};
		categories[cat][nicename] = data;
	end

	for category, npcs in SortedPairs(categories) do
		-- Temp standin
		local ctrl = vgui.Create( "DListView" );
		ctrl:SetMultiSelect( false );
		ctrl:AddColumn( "#npcs" );

		for nicename, data in pairs( npcs ) do
			local line = ctrl:AddLine( data.Name )
			line.nicename = nicename;
		end
		ctrl.OnRowSelected = onNPCSelected;

		ctrl:SortByColumn( 1, false )

		self:AddSheet(category, ctrl);
	end

	self:SetTall(200);
	self.list = ctrl;

end

function PANEL:ControlValues( data )
	if ( data.command ) then
		self:SetConVar( data.command );
	end
end

-- TODO: Think hook!

derma.DefineControl("NPCSpawnSelecter", "Selects a NPC fo' spawnin'", PANEL, "DPropertySheet")
