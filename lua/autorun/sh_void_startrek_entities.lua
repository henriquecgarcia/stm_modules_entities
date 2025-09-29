StarTrekEntities = StarTrekEntities or {}

function StarTrekEntities:Initialize()

	do
		local include_types = {
			["sv_"] = SERVER and include or function () end,
			["cl_"] = CLIENT and include or AddCSLuaFile,
			["sh_"] = function (file)
				if SERVER then
					AddCSLuaFile(file)
				end
				return include(file)
			end,
		}

		StarTrekEntities.Include = function (self, file, inc_type)
			inc_type = inc_type or "sh_"
			local func = include_types[inc_type]
			if not func then
				error("Invalid include type '" .. tostring(inc_type) .. "' for file '" .. tostring(file) .. "'")
				return
			end
			return func(file)
		end
	end
	StarTrekEntities:Include("startrek_entities/init.lua", "sh_")
end

if GAMEMODE then
	StarTrekEntities:Initialize()
else
	hook.Add("Initialize", "StarTrekEntities.Initialize", function()
		StarTrekEntities:Initialize()
	end)
end