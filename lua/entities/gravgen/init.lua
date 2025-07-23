
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
    self:SetModel( "models/props/starwars/tech/cis_ship_switcher.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetMaxHealth( 500 )
    self:SetHealth( 500 )
    self:SetUseType( SIMPLE_USE )

    local GenPhys = self:GetPhysicsObject()
    if IsValid( GenPhys ) then
        GenPhys:Wake()
    end
end

function ENT:CanProperty(ply, property)
    if !ply:IsAdmin() && property == "editentity" then
        return false
    end
end

function ENT:Use( ply )
if !IsValid( ply ) then return end
if !ply:IsPlayer() then return end
if !ply:IsAdmin() then return end
local CheckString = string.EndsWith( self:GetGravModel(), ".mdl" )
	self:SetHealth( self:GetGravHealth() )
	self:SetMaxHealth( self:GetGravHealth() )
	if CheckString then
		self:SetModel( self:GetGravModel() )
	end
	self:PhysicsInit( SOLID_VPHYSICS ) -- Redo physics since the model was changed...I guess.
end

function ENT:OnTakeDamage( dmg )
    self:TakePhysicsDamage( dmg )
    if ( self:Health() <= 0 ) then return end
    self:SetHealth( math.Clamp( self:Health() - dmg:GetDamage(), 0, self:GetMaxHealth() ) )
    if ( self:Health() <= 0 ) then
    local BoomBoom = ents.Create( "env_explosion" )
        BoomBoom:SetKeyValue( "spawnflags", 144 )
        BoomBoom:SetKeyValue( "iMagnitude", 15 )
        BoomBoom:SetKeyValue( "iRadiusOverride", 256 )
        BoomBoom:SetPos( self:GetPos() )
        BoomBoom:Spawn()
        BoomBoom:Fire( "explode", "", 0 )
		if self:GetDisableGrav() then
			RunConsoleCommand( "sv_gravity", "100" )
		end
		if self:GetDisableFric() then
			RunConsoleCommand( "sv_friction", "1" )
		end
        PrintMessage( HUD_PRINTCENTER, "Gravity Generator has been destroyed!" )
        self:Ignite( 10, 250 )
    end
end

function ENT:Think()
    if self:GetPlayerRepairing() then
        for k, v in pairs( player.GetAll() ) do
            if self:Health() <= 0 then return end
            if self:Health() == self:GetMaxHealth() then
                timer.Simple( 1, function()
                    RunConsoleCommand( "sv_gravity", "600" )
                    RunConsoleCommand( "sv_friction", "8" )
                end )
            end
        end
        self:SetPlayerRepairing( false )
    end
end

function ENT:OnRemove()
    RunConsoleCommand( "sv_gravity", "600" )
    RunConsoleCommand( "sv_friction", "8" )
end
