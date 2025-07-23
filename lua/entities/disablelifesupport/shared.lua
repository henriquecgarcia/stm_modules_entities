ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Author = "Void"

ENT.Spawnable = true
ENT.AdminOnly = true

ENT.PrintName = "No Life Support"
ENT.Category = "Star Trek Entities"

ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "DamageAmount", {
		KeyName = "DamageAmount",
		Edit = {
			type = "Int",
			title = "Damage Per Tick",
			category = "Damage Settings",
			order = 1,
			min = 1,
			max = 15,
		}
	} )
	self:NetworkVar( "Int", 1, "DamageSeconds", {
		KeyName = "DamageSeconds",
		Edit = {
			type = "Int",
			title = "Seconds Between Damage",
			category = "Damage Settings",
			order = 2,
			min = 1,
			max = 5,
		}
	} )
	self:NetworkVar( "Bool", 0, "EntireDeck", {
		KeyName = "EntireDeck",
		Edit = {
			type = "Boolean",
			title = "Damage Entire Deck (STM/Intrepid Only)?",
			category = "Damage Settings",
			order = 3,
		}
	} )

	if SERVER then
		self:SetDamageAmount( 2 )
		self:SetDamageSeconds( 1 )
		self:SetEntireDeck( false )
	end
end