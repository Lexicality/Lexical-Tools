DEFINE_BASECLASS "base_lexentity";

ENT.Type      = "anim";
ENT.PrintName = "Keypad";
ENT.Author    = "Robbis_1 (Killer HAHA), TomyLobo, Lex Robinson (Lexic)";
ENT.Contact   = "Robbis_1 and TomyLobo at Facepunch Studios";
ENT.CountKey  = "keypads"

ENT.Spawnable = true;
ENT.AdminOnly = false;

ENT.IsKeypad  = true;

ENT._NWVars = {
    {
        Type = "Int";
        Name = "PasswordDisplay";
    },
    {
        Type = "Bool",
        Name = "Secure";
        KeyName = "secure";
    },
    {
        Type = "Bool";
        Name = "Access";
    },
    {
        Type = "Bool";
        Name = "ShowAccess";
    },
    {
        Type = "Bool";
        Name = "Cracking";
    },
};
