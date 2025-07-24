if not SERVER then return end

local function CreateSQLTable()
	if sql.TableExists( "star_trek_entities" ) then return end

	sql.Query( [[
		CREATE TABLE star_trek_entities (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			ent_class INTEGER NOT NULL,
			ent_model TEXT NOT NULL,
			ent_pos TEXT NOT NULL,
			data TEXT
		)
	]] )
end

local function SelectSQLData( ent )
	if not IsValid( ent ) then return end

	local result = sql.QueryRow( "SELECT * FROM star_trek_entities WHERE ent_class = " .. sql.SQLStr( ent:GetClass() ) .. " AND ent_model = " .. sql.SQLStr( ent:GetModel() or ent:GetModel() ) )
	if not result then return end
	result.data = util.JSONToTable( result.data )
	if not result.data then
		print( "Failed to decode data for entity: " .. ent:GetClass() .. " with model: " .. ent:GetModel() )
		return nil
	end
	result.ent_pos = util.JSONToTable( result.ent_pos )
	if not result.ent_pos or #result.ent_pos ~= 2 then
		print( "Failed to decode position for entity: " .. ent:GetClass() .. " with model: " .. ent:GetModel() )
		return nil
	end
	result.ent_pos = {
		pos = Vector( result.ent_pos[1][1], result.ent_pos[1][2], result.ent_pos[1][3] ),
		ang = Angle( result.ent_pos[2][1], result.ent_pos[2][2], result.ent_pos[2][3] )
	}
	PrintTable(result)
	return result
end

local function RemoveSQLData( ent )
	local data = SelectSQLData( ent )
	if not data then return end

	sql.Query( "DELETE FROM star_trek_entities WHERE id = " .. sql.SQLStr( data.id ) )
end

local function SaveSQLData( ent )
	if not IsValid( ent ) then return end
	if not ent:GetModel() or ent:GetModel() == "" then return end

	local pos = ent:GetPos()
	local ang = ent:GetAngles()
	pos = { pos.x, pos.y, pos.z }
	ang = { ang.p, ang.y, ang.r }

	local data = {
		ent_class = ent:GetClass(),
		ent_model = ent:GetModel(),
		ent_pos = util.TableToJSON( { pos = pos, ang = ang } ),
		data = util.TableToJSON( ent:GetSaveTable() )
	}

	print( "Saving entity data for: " .. ent:GetClass() .. " with model: " .. ent:GetModel() )
	PrintTable(data)
	sql.Query( "INSERT INTO star_trek_entities (ent_class, ent_model, ent_pos, data) VALUES (" .. sql.SQLStr( data.ent_class ) .. ", " .. sql.SQLStr( data.ent_model ) .. ", " .. sql.SQLStr( data.ent_pos ) .. ", " .. sql.SQLStr( data.data ) .. ")" )
end

local savable_entities = {
	["commsarray"] = true,
	["disablelifesupport"] = true,
	["lifesupport"] = true,
	["gravgen"] = true,
}

local function ReloadStarTrekEntities()
	local result = sql.Query( "SELECT * FROM star_trek_entities" )
	if not result then
		print( "No entities found in the database." )
		return
	end

	for ent_class, _ in pairs( savable_entities ) do
		for _, ent in ipairs( ents.FindByClass( ent_class ) ) do
			if IsValid( ent ) and ent.SQL_ID then
				ent:Remove()
			end
		end
	end

	local ent_count = 0
	for _, row in ipairs( result ) do
		local ent = ents.Create( row.ent_class )
		if not IsValid( ent ) then continue end

		ent:SetModel( row.ent_model )
		local ent_pos = util.JSONToTable( row.ent_pos )
		if not ent_pos or table.Count(ent_pos) ~= 2 then
			print( "Failed to decode position for entity: " .. row.ent_class .. " with model: " .. row.ent_model )
			ent:Remove()
			continue
		end
		if not ent_pos.pos or not ent_pos.ang then
			print( "Invalid position data for entity: " .. row.ent_class .. " with model: " .. row.ent_model )
			ent:Remove()
			continue
		end
		ent_pos.pos = Vector( ent_pos.pos[1], ent_pos.pos[2], ent_pos.pos[3] )
		ent_pos.ang = Angle( ent_pos.ang[1], ent_pos.ang[2], ent_pos.ang[3] )
		ent:SetPos( ent_pos.pos )
		ent:SetAngles( ent_pos.ang )
		ent:Spawn()

		local data = util.JSONToTable( row.data )
		if data then
			for k, v in pairs( data ) do
				if ent[k] ~= nil then
					ent[k] = v
				end
			end
		end
		ent:Activate()
		-- ent:Freeze( true )

		ent.SQL_ID = row.id
		ent_count = ent_count + 1
	end
	print( "All entities loaded from the database. " .. ent_count .. " entities loaded." )
end
hook.Add( "InitPostEntity", "ReloadStarTrekEntities", function()
	timer.Simple(1, function()
		CreateSQLTable()
		ReloadStarTrekEntities()
	end )
end )

local safe_zones = {
	{ -- Turbo Lift [Halfway] + TP Buffer
		min = Vector(8258.139648, 572.089539, 13468.325195),
		max = Vector(7241.450195, -552.128723, 11847.990234)
	},
	{ -- Holodeck - The Void
		min = Vector( -2035.248779, -11788.853516, 13971.599609 ),
		max = Vector( -8471.815430, -5346.975098, 12336.586914 )
	},
	{ -- Holodeck - Waste Land
		min = Vector( 15300.295898, 14036.236328, 17559.767578 ),
		max = Vector( 2739.603027, 2675.925537, 11989.919922 ),
	},
	{ -- Holodeck - Holo lab
		min = Vector( -2365.034668, 2035.330322, 13131.249023 ),
		max = Vector( -5893.335449, 5428.146484, 12473.782227 ),
	},

	-- AUX AREAS!
	{
		min = Vector( -5950.541992, 5265.229492, 13124.010742 ),
		max = Vector( -13579.957031, 1857.106934, 12494.546875 ),
	},
	{
		min = Vector( -13567.231445, 6074.521484, 11368.706055 ),
		max = Vector( -2346.298584, 11287.033203, 15019.102539 ),
	},

	--[[
	{ -- Jefferies Tubes Deck 1 + Deck 2 (part far)
		min = Vector( 515.612061, -298.262665, 13143.922852 ),
		max = Vector( 701.765198, 306.156433, 13480.488281 ),
	},
	{ -- Jefferies Tubes Line 2->11 Cargo Bay [1]
		min = Vector( 308.404144, -252.220474, 13282.774414 ),
		max = Vector( 202.267166, -121.243828, 12028.001953 ),
	},
	{ -- Jefferies Tubes Line 2->11 Cargo Bay [2]
		min = Vector( 319.397217, 252.582672, 12019.697266 ),
		max = Vector( 195.434982, 115.439224, 13127.943359 ),
	},
	{ -- Jefferies Tubes Deck 2 (part near)
		min = Vector( 673.158142, -291.950500, 13317.923828 ),
		max = Vector( 122.818840, -129.512100, 13154.769531 ),
	},
	{ -- Jefferies Tubes Deck 3 (pt 1) [Turbo Lift]
		min = Vector( 196.611542, -283.776306, 12978.406250 ),
		max = Vector( 456.099548, -79.708206, 13193.854492 ),
	},
	{ -- Jefferies Tubes Deck 3 (pt 2) [Turbo Lift]
		min = Vector( 452.418640, -233.646851, 13117.790039 ),
		max = Vector( 337.003540, 280.271667, 12983.800781 ),
	},
	{ -- Jefferies Tubes Deck 3 (pt 3) [Turbo Lift]
		min = Vector( 337.003540, 280.271667, 12983.800781 ),
		max = Vector( 177.568771, 102.100716, 13164.157227 ),
	},
	{ -- Jefferies Tubes Deck 4 (pt 1) [Turbo Lift]
		min = Vector( 504.969238, 77.298592, 12985.849609 ),
		max = Vector( 23.326996, 483.349304, 12822.036133 ),
	},
	{ -- Jefferies Tubes Deck 4 (pt 2) [Turbo Lift]
		min = Vector( 23.326996, 483.349304, 12822.036133 ),
		max = Vector( 147.061447, -446.377350, 12953.959961 ),
	},
	{ -- Jefferies Tubes Deck 4 (pt 3) [Turbo Lift]
		min = Vector( 30.903198, -263.881958, 12941.212891 ),
		max = Vector( 286.910950, -121.433266, 12806.338867 ),
	},
	{ -- Deck 4 (pt 4) [Near TP]
		min = Vector( 475.769104, -429.521271, 12829.966797 ),
		max = Vector( -1784.618286, 1261.104858, 12973.960938 ),
	},
	{ -- Deck 4 (pt 5) [Security]
		min = Vector( 1201.564453, -637.483337, 13024.683594 ),
		max = Vector( 1341.373413, -494.433960, 12647.120117 ),
	},
	{ -- Jefferies Tubes Deck 5 (pt 1)
		min = Vector( 1320.623413, -624.742981, 12800.092773 ),
		max = Vector( -311.973633, 278.787689, 12674.935547 ),
	},
	{ -- Jefferies Tubes Deck 5 (pt 2)
		min = Vector( -647.112732, -83.988098, 12777.410156 ),
		max = Vector( 183.867371, -250.044586, 12666.375000 ),
	},
	{ -- Jefferies Tubes Deck 5 (pt 3)
		min = Vector( -207.583710, 188.589844, 12688.931641 ),
		max = Vector( -651.456909, 61.455784, 12993.793945 ),
	},

	--]]


	--- Testing with the entire ship:
	{
		min = Vector( -2188.804199, -1236.667847, 14246.653320 ),
		max = Vector( 2390.314209, 1144.067993, 11371.262695 ),
	}
}
hook.Add( "ShouldIgnoreLifeSupportDamage", "DisableLifeSupportDamage", function( ply, location_data )
	if not IsValid( ply ) or not ply:IsPlayer() then return end
	local pMovement = ply:GetMoveType()
	if pMovement == MOVETYPE_NOCLIP or pMovement == MOVETYPE_OBSERVER then return true end
	if ply:GetModel() == "models/player/startrek_female_spacesuit.mdl" then return true end
	local pos = ply:GetPos()
	if #location_data == 0 then
		for _, zone in ipairs( safe_zones ) do
			if pos:WithinAABox( zone.min, zone.max ) then
				return true, false -- Ignore damage, but don't overwrite life support.
			end
		end
	end
end )

concommand.Add( "star_trek_entities_save", function( ply, cmd, args )
	if not IsValid( ply ) or not ply:IsAdmin() then
		print( "You must be an admin to use this command." )
		return
	end

	local trace = ply:GetEyeTrace()
	if not trace.Entity or not trace.Entity:IsValid() or not savable_entities[trace.Entity:GetClass()] then
		print( "You must be looking at a valid Star Trek entity." )
		return
	end
	CreateSQLTable()

	local ent = trace.Entity
	local existing_data = SelectSQLData( ent )
	if existing_data then
		print( "Entity data already exists, removing old data." )
		RemoveSQLData( ent )
	end

	SaveSQLData( ent )
	local last_insert_id = sql.QueryValue( "SELECT last_insert_rowid()" )
	if not last_insert_id then
		print( "Failed to save entity data." )
		return
	end
	local data_saved = sql.Query( "SELECT * FROM star_trek_entities WHERE id = " .. sql.SQLStr( last_insert_id ) )
	if not data_saved then
		print( "Failed to retrieve saved entity data." )
		return
	end
	data_saved = data_saved[1] -- Get the first row of the result.
	data_saved.pos = util.JSONToTable( data_saved.ent_pos )
	if not data_saved.pos or table.Count(data_saved.pos) ~= 2 then
		print( "Failed to decode position for saved entity data." )
		return
	end
	data_saved.pos = {
		pos = Vector( data_saved.pos['pos'][1], data_saved.pos['pos'][2], data_saved.pos['pos'][3] ),
		ang = Angle( data_saved.pos['ang'][1], data_saved.pos['ang'][2], data_saved.pos['ang'][3] )
	}
	data_saved.data = util.JSONToTable( data_saved.data )
	if not data_saved.data then
		print( "Failed to decode data for saved entity." )
		return
	end
	ent:Remove() -- Remove the original entity after saving its data.
	print( "Entity data saved successfully with ID: " .. last_insert_id )

	local new_ent = ents.Create( ent:GetClass() )
	if not IsValid( new_ent ) then
		print( "Failed to create new entity for data." )
		return
	end

	new_ent:SetModel( data_saved.ent_model )
	new_ent:SetPos( data_saved.pos.pos )
	new_ent:SetAngles( data_saved.pos.ang )
	new_ent:Spawn()
	for k, v in pairs( data_saved.data ) do
		if new_ent[k] then
			new_ent[k] = v
		end
	end
	new_ent.SQL_ID = last_insert_id
	new_ent:Activate()

end )

concommand.Add( "star_trek_entities_load", function( ply, cmd, args )
	if not IsValid( ply ) or not ply:IsAdmin() then
		print( "You must be an admin to use this command." )
		return
	end

	CreateSQLTable()
	ReloadStarTrekEntities()
end )

concommand.Add( "star_trek_entities_remove", function( ply, cmd, args )
	if not IsValid( ply ) or not ply:IsAdmin() then
		print( "You must be an admin to use this command." )
		return
	end
	CreateSQLTable()
	local trace = ply:GetEyeTrace()
	if not trace.Entity or not trace.Entity:IsValid() or not savable_entities[trace.Entity:GetClass()] then
		print( "You must be looking at a valid Star Trek entity." )
		return
	end
	local data = SelectSQLData( trace.Entity )
	if not data then
		print( "No data found for the entity." )
		return
	end
	RemoveSQLData( trace.Entity )
	print( "Entity data removed." )
end )

hook.Add( "PostCleanupMap", "StarTrekEntitiesCleanup", function()
	timer.Simple(1, function()
		CreateSQLTable()
		ReloadStarTrekEntities()
	end )
end )