local PANEL = {};

DEFINE_BASECLASS "DPropertySheet";

AccessorFunc( PANEL, "m_ConVar", "ConVar" );

function PANEL:Init()
	local npcs = list.Get('NPC');

	local categories = {};

	for nicename, data in pairs(npcs) do
		local cat = data.Category or "Uncategorized";
		categories[cat] = categories[cat] or {};
		categories[cat][nicename] = data;
	end

	function onNPCSelected(_, _, line)
		RunConsoleCommand( self:GetConVar(), line.nicename )
	end

	local catNames = table.GetKeys(categories);
	table.sort(catNames);

	for _, category in ipairs(catNames) do
		local npcs = categories[category];

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
