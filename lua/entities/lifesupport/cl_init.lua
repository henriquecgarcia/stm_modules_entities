include( "shared.lua" )

surface.CreateFont( "SystemsHealth", {
	font = "Arial",
	extended = false,
	size = 35,
	weight = 1000,
    shadow = true,
    outline = false
} )

function ENT:Draw()
    self:DrawModel()
	if self:GetDisplayHealth() then
    local p = self:GetPos()
    local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang.y = LocalPlayer():EyeAngles().y - 90
		if LocalPlayer():GetPos():DistToSqr( self:GetPos() ) < 2048 * 2048 then
			local hp_percent = self:Health() / self:GetMaxHealth()
			hp_percent = hp_percent * 10000
			hp_percent = math.Round( hp_percent ) / 100
			hp_percent = hp_percent * 0.01 -- Convert to a percentage.
			cam.Start3D2D( p + Vector( 5, 0, 10 ), Angle( 0, ang.y, 90 ), .15 )
				draw.RoundedBox( 5, - 180, - 300, 350, 50, Color( 0, 0, 0, 230 ) )
				draw.RoundedBox( 5, - 180 + 2, - 300 + 2, math.Clamp( hp_percent * 350, 0, 350 ), 50 - 2, Color( 150, 0, 0, 230 ) )
				draw.DrawText( hp_percent * 100 .. "%", "SystemsHealth", 5, - 290, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
			cam.End3D2D()
		end
	end
end
