ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Author = "Void"

ENT.Spawnable = true
ENT.AdminOnly = true

ENT.PrintName = "Life Support System"
ENT.Category = "Star Trek Entities"

ENT.Editable = true

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "PlayerRepairing" )
    self:NetworkVar( "String", 0, "LifeModel", {
        KeyName = "LifeModel",
        Edit = {
            type = "String",
            title = "Entity Model:",
			category = "Model Settings",
            waitforenter = true,
        }
    } )
	self:NetworkVar( "Bool", 1, "DisableSupport", {
		KeyName = "DisableSupport",
		Edit = {
			type = "Boolean",
			title = "Disable Life Support",
			category = "Player Settings (When entity is destroyed.)",
			order = 0,
			min = 0,
			max = 1,
		}
	} )
	self:NetworkVar( "Int", 0, "DamageAmount", {
		KeyName = "DamageAmount",
		Edit = {
			type = "Int",
			title = "Damage Per Tick",
			category = "Player Settings (When entity is destroyed.)",
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
			category = "Player Settings (When entity is destroyed.)",
			order = 2,
			min = 1,
			max = 5,
		}
	} )
	self:NetworkVar( "Bool", 2, "DisplayHealth", {
		KeyName = "DisplayHealth",
		Edit = {
			type = "Boolean",
			title = "Display Health Bar",
			min = 0,
			max = 1,
		}
	} )

	self:NetworkVar( "Int", 2, "Health", {
		KeyName = "Health",
		Edit = {
			type = "Int",
			title = "Entity Health:",
			category = "Health Settings",
			min = 1,
			max = 10000,
		}
	} )

	self:NetworkVar( "Int", 3, "MaxHealth", {
		KeyName = "MaxHealth",
		Edit = {
			type = "Int",
			title = "Max Entity Health:",
			category = "Health Settings",
			min = 100,
			max = 10000,
		}
	} )

	if SERVER then
		self:SetDisableSupport( true )
		self:SetDamageAmount( 2 )
		self:SetDamageSeconds( 1 )
		self:SetDisplayHealth( true )

		self:SetMaxHealth( 200 )
		self:SetHealth( 200 )
	end
end

function ENT:Health()
	return self:GetHealth()
end

ENT.OriginalModel = ENT.OriginalModel or ENT.GetModel
function ENT:GetModel()
	if self:GetLifeModel() and self:GetLifeModel() ~= "" then
		return self:GetLifeModel()
	end
	return self:OriginalModel()
end