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
end
