ENT.Type			= "anim";
if (WireLib) then
    DEFINE_BASECLASS("base_wire_entity");
else
    DEFINE_BASECLASS("base_gmodentity");
end
ENT.PrintName		= "Keypad";
ENT.Author			= "Robbis_1 (Killer HAHA), TomyLobo, Lex Robinson (Lexic)";
ENT.Contact			= "Robbis_1 and TomyLobo at Facepunch Studios";

ENT.Spawnable		= false;
ENT.AdminSpawnable	= false;

ENT.IsKeypad        = true;

function ENT:SetupDataTables()
    self:DTVar("Int", 0, "Password");
    self:DTVar("Bool", 0, "Secure");
    self:DTVar("Bool", 1, "Access");
    self:DTVar("Bool", 2, "ShowAccess");
end
