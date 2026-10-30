AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

local DISABLE_SYSTEM = "lifesupport"

function ENT:Initialize()
	self:SetModel( "models/props/atmospherecontrol.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetPos( self:GetPos() ) -- This spawns underground in some maps so set to 100 then DropToFloor().
	self:SetHealth( 500 )
	self:SetMaxHealth( 500 )
	self:SetUseType( SIMPLE_USE )

	local SuppPhys = self:GetPhysicsObject()
	if IsValid( SuppPhys ) then
		SuppPhys:Wake()
		SuppPhys:EnableMotion( false )
	end

	hook.Run( "OnLifeSupportCreated", self )

	self.Working = true

	self:UpdateScannerData()

	local disable_zones = StarTrekEntities.DisableZones
	if disable_zones then
		disable_zones:PrimePlayers()
		disable_zones:Rebuild(DISABLE_SYSTEM)
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
	local CheckString = string.EndsWith( self:GetLifeModel(), ".mdl" )
	if CheckString then
		self:SetModel( self:GetLifeModel() )
	end
	self:PhysicsInit( SOLID_VPHYSICS ) -- Redo physics since the model was changed...I guess.

	self:Freeze( false )
end

function ENT:OnTakeDamage( dmg )
	self:TakePhysicsDamage( dmg )
	if ( self:Health() <= 0 ) then return end
	self:SetHealth( math.Clamp( self:Health() - dmg:GetDamage(), 0, self:GetMaxHealth() ) )
	self.last_hit_location = dmg:GetDamagePosition()
	self:UpdateScannerData()

	hook.Run( "OnLifeSupportDamage", self, dmg )

	if ( self:Health() <= 0 ) then

		local BoomBoom2 = ents.Create( "env_explosion" )
		BoomBoom2:SetKeyValue( "spawnflags", 144 )
		BoomBoom2:SetKeyValue( "iMagnitude", 15 )
		BoomBoom2:SetKeyValue( "iRadiusOverride", 256 )
		BoomBoom2:SetPos( self:GetPos() )
		BoomBoom2:Spawn()
		BoomBoom2:Fire( "explode", "", 0 )

		PrintMessage( HUD_PRINTCENTER, "Life Support System has been destroyed!" )

		self:Ignite( 20, 250 )

		self.Working = false

		hook.Run( "OnLifeSupportDestroyed", self )
	end
end

function ENT:UpdateScannerData()
	local health = self:Health()
	local maxHealth = self:GetMaxHealth()

	local status = health > 0 and "Active" or "Destroyed"

	local fun_message = ""
	if health <= 0 then
		fun_message = "System is offline. Please repair."
	elseif health <= maxHealth * 0.25 then
		fun_message = "Warning: System health is critically low! Failure imminent!"
	elseif health <= maxHealth * 0.5 then
		fun_message = "Caution: System health is below 50%. Consider repairs."
	elseif health <= maxHealth * 0.75 then
		fun_message = "System health is below 75%. Monitor closely."
	else
		fun_message = "System is operational."
	end

	self.ScannerData = "Status: " .. status .. "\n" .. fun_message .. "\n"

end

function ENT:DoDamage(ply)
	if not IsValid( ply ) then return end
	if not ply:IsPlayer() then return end

	-- ENT, ply, section, deck
	local should_damage = hook.Run( "ShouldIgnoreLifeSupportDamagePlayer", self, ply, nil, nil )
	if should_damage == true then return end

	local pMovement = ply:GetMoveType()
	if pMovement == MOVETYPE_NOCLIP or pMovement == MOVETYPE_OBSERVER then return end

	local dmg = DamageInfo()
	dmg:SetDamage( self:GetDamageAmount() )
	dmg:SetDamageType( DMG_RADIATION )
	dmg:SetAttacker( self )
	dmg:SetInflictor( self )

	ply:TakeDamageInfo( dmg )
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

	self:ThinkOxygen()

	if self:GetPlayerRepairing() then
		if not self.Working then
			hook.Run( "OnLifeSupportRepaired", self )
			self.Working = true
		end
		self:SetPlayerRepairing( false )
	end

	self:NextThink( now + 0.25 )
	return true
end

function ENT:OnRemove()
	hook.Run( "OnLifeSupportRemoved", self )
end


function ENT:DoOxygenDamage(ply)
	local disable_zones = StarTrekEntities.DisableZones
	local location = disable_zones and disable_zones:GetPlayerLocation(ply) or {}
	local ignoreDamage, overwriteLifeSupport = hook.Run("ShouldIgnoreLifeSupportDamage", ply, location)
	
	-- If the hook wants to handle damage itself, respect that decision
	if ignoreDamage then
		-- If overwriteLifeSupport is explicitly false, check if life support is working
		-- and allow damage if it's not working
		if overwriteLifeSupport == false then
			ignoreDamage = self:Health() > 0 -- If life support is working, ignore damage
		end
	end
	
	-- If we should ignore damage, return early
	if ignoreDamage == true then 
		return 
	end

	-- Deal oxygen deprivation damage
	local dmg = DamageInfo()
	dmg:SetDamage( self:GetDamageAmount() )
	dmg:SetDamageType( DMG_DROWN )
	dmg:SetAttacker( self )
	dmg:SetInflictor( self )

	ply:TakeDamageInfo( dmg )
end

function ENT:ThinkOxygen()
	-- Rate limiting: don't damage too frequently
	local now = CurTime()
	if (self.NextOxygenDamage or 0) > now then
		return
	end
	self.NextOxygenDamage = now + self:GetDamageSeconds()

	local disable_zones = StarTrekEntities.DisableZones

	-- Check each player for oxygen deprivation conditions
	for i, ply in player.Iterator() do
		if not IsValid(ply) or not ply:Alive() then
			continue
		end

		local playerLocation = disable_zones and disable_zones:GetPlayerLocation(ply) or nil
		local deck = playerLocation and playerLocation.deck or nil
		local sectionId = playerLocation and playerLocation.section or nil

		-- Check various conditions that would cause oxygen damage
		local shouldTakeDamage = false

		-- Is the player outside the ship (no location data)?
		if deck == nil or sectionId == nil then
			shouldTakeDamage = true
		-- Is the player in a disabled deck?
		elseif disable_zones and disable_zones:IsDisabled(DISABLE_SYSTEM, deck, sectionId) then
			shouldTakeDamage = true
		-- Is the life support system destroyed?
		elseif self:Health() <= 0 then
			shouldTakeDamage = true
		end
		
		-- Apply oxygen damage if any condition is met
		if shouldTakeDamage then
			self:DoOxygenDamage(ply)
		end
	end
end
