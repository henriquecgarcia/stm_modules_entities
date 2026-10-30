
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

local DISABLE_SYSTEM = "gravity"

function ENT:Initialize()
	self:SetModel( "models/props/console_control_round.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMaxHealth( 500 )
	self:SetHealth( 500 )
	self:SetUseType( SIMPLE_USE )

	local GenPhys = self:GetPhysicsObject()
	if IsValid( GenPhys ) then
		GenPhys:Wake()
        GenPhys:EnableMotion( false )
	end

    hook.Run( "OnGravGenInitialized", self )
    self.Working = true
    self:SetPlayerRepairing(false)

    local disable_zones = StarTrekEntities.DisableZones
    if disable_zones then
        disable_zones:PrimePlayers()
        disable_zones:Rebuild(DISABLE_SYSTEM)
    end

    for _, ply in player.Iterator() do
        local success, deck, section = Star_Trek.Sections:DetermineSection( ply:GetPos() )
		if success and disable_zones then
            disable_zones:SetPlayerLocation(ply, deck, section)
		end
        self:ApplyGravity(ply, not success)
    end
end

function ENT:CanProperty(ply, property)
	if !ply:IsAdmin() && property == "editentity" then
		return false
	end
end
function ENT:CanTool(ply, tool)
	if tool == "permaprops" then
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
    hook.Run( "OnGravGenDamaged", self, dmg )

    if ( self:Health() <= 0 ) then
		local BoomBoom = ents.Create( "env_explosion" )
		BoomBoom:SetKeyValue( "spawnflags", 144 )
		BoomBoom:SetKeyValue( "iMagnitude", 15 )
		BoomBoom:SetKeyValue( "iRadiusOverride", 256 )
		BoomBoom:SetPos( self:GetPos() )
		BoomBoom:Spawn()
		BoomBoom:Fire( "explode", "", 0 )
		PrintMessage( HUD_PRINTCENTER, "Gravity Generator has been destroyed!" )
		self:Ignite( 10, 250 )
        self.Working = false
        hook.Run( "OnGravGenDestroyed", self )
	end
end

function ENT:Think()
    local now = CurTime()
    local health = self:Health()
	local maxHealth = self:GetMaxHealth()
	if health >= maxHealth then
		if self.ShockEnt and IsValid( self.ShockEnt ) then
			self.ShockEnt:Remove()
			self.ShockEnt = nil
		end
	else
		local hp_percent = health / maxHealth
		local time_interval = 60 * ( hp_percent ) -- Calculate time interval based on health percentage

		time_interval = math.Clamp( time_interval, 5, 60 ) -- Ensure the interval is between 5 and 60 seconds

		if (self.NextShockSound or 0) < now then
			self.NextShockSound = now + time_interval
			self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 75, 100, 0.5 )
		end
		if not self.ShockEnt or not IsValid( self.ShockEnt ) then
			local shockEnt = ents.Create( "pfx4_05~" )
			shockEnt:SetPos( self:GetPos() )
			shockEnt:SetAngles( self:GetAngles() )
			shockEnt:SetParent( self )
			shockEnt:Spawn()
			self.ShockEnt = shockEnt
		end
	end

    self:ThinkGravity()

	if self:GetPlayerRepairing() then
        if not self.Working then
            hook.Run( "OnGravGenRepaired", self )
            self.Working = true
        end
		self:SetPlayerRepairing( false )
	end

    self:NextThink( now + 0.25 )
    return true
end

function ENT:OnRemove()
    for k, v in player.Iterator() do
        self:ApplyGravity(v, false) -- Reset gravity for all players
    end
    hook.Run( "OnGravGenRemoved", self )
end

function ENT:ApplyGravity(ply, remove_grav)
    if not IsValid(ply) or ply == self then return end

    local disable_zones = StarTrekEntities.DisableZones
    local pLocator = disable_zones and disable_zones:GetPlayerLocation(ply) or {}
    local ShouldIgnore, OverWrite = hook.Run("ShouldIgnoreGravity", ply, pLocator)
    if ShouldIgnore then
        if OverWrite ~= false then
            remove_grav = self:Health() > 0
        else
            remove_grav = false
        end
    end

    if not remove_grav then
        ply:SetGravity(1)
        ply:SetFriction(1)
        return
    end
    -- Apply gravity to players (?)
    ply:SetGravity(1 / 6) -- 600 -> 100 -- 1/6th of the normal gravity?
    ply:SetFriction(1 / 8) -- 8 -> 1 -- 1/8th of the normal friction?
end

function ENT:ThinkGravity()
    local disable_zones = StarTrekEntities.DisableZones
    for k, v in player.Iterator() do
        local pLocator = disable_zones and disable_zones:GetPlayerLocation(v) or {}
        local deck = pLocator.deck or nil
        local section = pLocator.section or nil

        local should_remove_grav = false
        -- Not in the ship, remove grav!!!!!!!!!!
        if deck == nil or section == nil then
            should_remove_grav = true
        elseif disable_zones and disable_zones:IsDisabled(DISABLE_SYSTEM, deck, section) then
            should_remove_grav = true
        end

        if self:Health() <= 0 or not self.Working then
            should_remove_grav = true
        end

        self:ApplyGravity(v, should_remove_grav)
    end
end
