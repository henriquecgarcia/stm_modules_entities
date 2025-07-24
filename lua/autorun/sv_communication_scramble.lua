if not SERVER then return end

-- Define combining characters (Zalgo style)
local zalgo_up = {"̍","̎","̄","̅","̿","̑","̆","̐","͒","͗","͑","̇","̈","̊","͂","̓","̈́","͊","͋","͌","̃","̂","̌","͐"}
local zalgo_mid = {"̕","̛","̀","́","͘","̡","̢","̧","̨","̴","̵","̶","͜","͝","͞","͟","͠","͢","̸","̷","͡"}
local zalgo_down = {"̖","̗","̘","̙","̜","̝","̞","̟","̠","̤","̥","̦","̩","̪","̫","̬","̭","̮","̯","̰","̱","̲","̳","̹","̺","̻","̼","ͅ","͇","͈","͉","͍","͎","͓","͔","͕","͖","͙","͚"}

-- Scramble text with intensity level (1–6)
function ScrambleText(text, intensity)
	if not text or text == "" then return "" end
	if intensity == 0 then return text end
	math.randomseed(os.time()) -- Seed random number generator
	intensity = math.Clamp(intensity, 1, 6) -- Ensure intensity is between 1 and 6
	local function getRandom(tbl, count)
		local out = ""
		for i = 1, count do
			out = out .. tbl[math.random(#tbl)]
		end
		return out
	end

	local result = ""
	for i = 1, #text do
		local char = text:sub(i, i)
		if char:match("%s") then
			result = result .. char -- don't glitch spaces
		else
			local up = getRandom(zalgo_up, intensity)
			local mid = getRandom(zalgo_mid, math.max(0, intensity - 2))
			local down = getRandom(zalgo_down, intensity)
			result = result .. char .. up .. mid .. down
		end
	end

	return result
end

local comms_status = {
	active = false,
	scrambled_level = 0,
}
hook.Add("CommunicationsArrayInitialized", "ActivateCommsSystem", function(ent)
	if not IsValid(ent) then return end
	comms_status.active = true
	print("Communications Array System Activated.")
	for _, ply in pairs(player.GetAll()) do
		if ply:IsAdmin() then
			ply:ChatPrint("Communications Array System Activated.")
		end
	end
end)

hook.Add("CommunicationsArrayDamaged", "HandleCommsDamage", function(ent, dmg, damage_level)
	if not IsValid(ent) then return end
	comms_status.scrambled_level = damage_level
	print("Communications Array Damaged. Scramble Level: " .. damage_level)
	for _, ply in pairs(player.GetAll()) do
		if ply:IsAdmin() then
			ply:ChatPrint("Communications Array Damaged. Scramble Level: " .. damage_level)
		end
	end
end)

hook.Add("CommunicationsArrayRepairing", "HandleCommsRepairing", function(ent, intensity)
	if not IsValid(ent) then return end

	comms_status.scrambled_level = intensity
	print("Communications Array Repairing. Scramble Level: " .. intensity)
	for _, ply in pairs(player.GetAll()) do
		if ply:IsAdmin() then
			ply:ChatPrint("Communications Array Repairing. Scramble Level: " .. intensity)
		end
	end
	comms_status.active = true -- Assume repairing means the system is still active
end)

hook.Add("CommunicationsArrayRemoved", "DeactivateCommsSystem", function(ent, aux)
	if not IsValid(ent) then return end
	comms_status.active = false
	comms_status.scrambled_level = 0
	print("Communications Array System Deactivated.")
	for _, ply in pairs(player.GetAll()) do
		if ply:IsAdmin() then
			ply:ChatPrint("Communications Array System Deactivated.")
		end
	end
end)

hook.Add("PlayerSay", "ScrambleChat", function(ply, text)
	if text[1] ~= "/" then return end -- Not my thing
	text = text:sub(2) -- Remove the slash
	local args = string.Explode(" ", text)
	if args[1] == "comms" then
		if not comms_status.active then
			ply:ChatPrint("Communications Array is not active.")
			return ""
		end
		if #args < 2 then
			ply:ChatPrint("Usage: /comms <message>")
			return ""
		end
		local message = table.concat(args, " ", 2)
		if not message or message == "" then
			ply:ChatPrint("Please provide a message to scramble.")
			return ""
		end
		local intensity = comms_status.scrambled_level or 0
		local scrambled_message = ScrambleText(message, intensity)
		BroadcastLua("chat.AddText(Color(255, 0, 0), '[Comms] " .. ply:Nick() .. "', Color(255, 255, 255), ': " .. scrambled_message .. "')")
		return ""
	end
end)