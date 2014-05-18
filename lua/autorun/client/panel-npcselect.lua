local PANEL = {};

AccessorFunc( PANEL, "m_ConVar", "ConVar" );

function PANEL:Init()
	local npcs = list.Get('NPC');

	-- Temp standin
	local ctrl = vgui.Create( "DListView" );
	ctrl:SetMultiSelect( false );
	ctrl:AddColumn( "#npcs" );
	ctrl:AddColumn( "#category" );

	for _, data in pairs( npcs ) do
		local line = ctrl:AddLine( data.Name, data.Category )
		line.nicename = data.Class;
	end

	ctrl:SetTall( 150 );
	ctrl:SortByColumn( 2, false )

	ctrl.OnRowSelected = function(ctrl, LineID, Line)
		RunConsoleCommand( self:GetConVar(), Line.nicename )
	end

	ctrl:SetParent( self )
	ctrl:Dock(FILL);
	self:SetTall(150);
	self.list = ctrl;

end

function PANEL:ControlValues( data )
	if ( data.command ) then
		self:SetConVar( data.command );
	end
end

-- TODO: Think hook!


vgui.Register( "NPCSelect", PANEL, "DPanel" )
