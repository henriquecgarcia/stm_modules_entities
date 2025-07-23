if not SERVER then return end

local life_support_status = true

function SetLifeSupportStatus(status)
    life_support_status = status
end

function GetLifeSupportStatus()
    return life_support_status
end


local players_location = {}

hook.Add("")