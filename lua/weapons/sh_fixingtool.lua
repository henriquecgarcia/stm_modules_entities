--[[------------------------------------------------------------
    ____________										   ___
    |		   |   									 	  |	  |
    |___	___|	__________   	__________			  |	  |
    	|	|	   /		  \	   /		  \		   	  |	  |
    	|	|	  |			   |  |			   |	  ____|   |
    	|	|	  |			   |  |			   |	 / 		  |
    	|	|	  |			   |  |			   |	|		  |
    	|___|	   \__________/    \__________/		 \________|

    Author: Tood/The Toodster.
    Contact: Discord - The Toodster#0001 || Steam - https://steamcommunity.com/id/freelancertood/
--]]------------------------------------------------------------

AddCSLuaFile()

SWEP.PrintName = "Repairing Tool"
SWEP.Slot = 2
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.Instructions = "Repair the grav gen, life support, power station and comms array by aiming at it and pressing left-click."
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Category = "Tood's Repair Tool"

SWEP.ViewModelFOV = 65
SWEP.ViewModelFlip = false
SWEP.UseHands = false
SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

-----------------------------------------

local RepairableEnts = {
    ["commsarray"] = true,
    ["lifesupport"] = true,
    ["gravgen"] = true,
    ["powerstation"] = true,
}

local CooldownActive = false
function SWEP:PrimaryAttack()
local ply = self.Owner
local PTrace = ply:GetEyeTrace().Entity
local PTHealth = PTrace:Health()
local PTMHealth = PTrace:GetMaxHealth()
    if IsValid( ply ) && ply:IsPlayer() then
        if PTrace:GetPos():DistToSqr( ply:EyePos() ) < 150 * 150 then
            if !ply.CooldownActive || ply.CooldownActive < CurTime() then
                if PTHealth >= PTMHealth then
                    PTrace:SetPlayerRepairing( false )
                    return
                else
                    if RepairableEnts[PTrace:GetClass()] then
                        PTrace:SetHealth( math.Clamp( PTHealth + math.Rand( 50, 100 ), 0, PTMHealth ) )
                        PTrace:SetPlayerRepairing( true )
                    end
                end
                ply.CooldownActive = CurTime() + 1
            end
        end
    end
    return true
end

function SWEP:SecondaryAttack()
    return false
end

function SWEP:Reload()
    return false
end
