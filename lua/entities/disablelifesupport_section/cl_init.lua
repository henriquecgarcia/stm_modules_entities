include( "shared.lua" )

function ENT:Draw()
	self:DrawShadow( false )

	local cur_weapon = LocalPlayer():GetActiveWeapon()
	if !IsValid( cur_weapon ) or ( cur_weapon:GetClass() ~= "weapon_physgun" and cur_weapon:GetClass() ~= "gmod_tool" ) then return end

	self:DrawModel()

end