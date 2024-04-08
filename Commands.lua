-- Commands.lua

-- Implements the command handlers





--- Returns the player's current WE selection, or nil if none / no WE
-- The returned selection is always sorted
local function getWorldEditSelection(aPlayer)
	local sel = cCuboid()
	if not(cPluginManager:CallPlugin("WorldEdit", "GetPlayerCuboidSelection", aPlayer, sel)) then
		return nil
	end
	sel:Sort()
	return sel
end





--- Handler for the "/mg" command
-- Signature: /mg BlockType [CellSize] [ExtraPassagesPercent]
function handleMgCommand(aSplit, aPlayer)
	-- Check the BlockType:
	if not(aSplit[2]) then
		aPlayer:SendMessageFailure("Missing parameter: BlockType")
		return true
	end
	local blockType, blockMeta = GetBlockTypeMeta(aSplit[2])
	if (not blockType) then
		aPlayer:SendMessageFailure("Unknown block type \"" .. aSplit[2] .. "\"")
		return true
	end
	
	-- Check the CellSize:
	local cellSize = 3
	if (aSplit[3]) then
		cellSize = tonumber(aSplit[3])
		if not(cellSize) then
			aPlayer:SendMessageFailure("Invalid CellSize specification, expected a number")
			return true
		end
	end
	
	-- Check the ExtraPassagesPercent:
	local extraPassagesPercent = 0
	if (aSplit[4]) then
		extraPassagesPercent = tonumber(aSplit[4])
		if not(extraPassagesPercent) then
			aPlayer:SendMessageFailure("Invalid ExtraPassagesPercent specification, expected a number")
			return true
		end
	end

	-- Check the WE selection:
	local weSel = getWorldEditSelection(aPlayer)
	if not(weSel) then
		aPlayer:SendMessageFailure("Failed to query your WorldEdit selection.")
		return true
	end
	
	MazeGen.generate(aPlayer, aPlayer:GetWorld(), weSel, blockType, blockMeta, cellSize, extraPassagesPercent)
	aPlayer:SendMessageSuccess("Maze generated")
	return true
end





--- Handler for the "mg" console command
-- Signature: mg World MinX MinY MinZ MaxX MaxY MaxZ BlockType [CellSize] [ExtraPassagesPercent]
function handleMgConsoleCommand(aSplit)
	-- If no params, print usage:
	if not(aSplit[2]) then
		LOG("Usage: mg World MinX MinY MinZ MaxX MaxY MaxZ BlockType [CellSize] [ExtraPassagesPercent]")
		return true
	end
	
	-- Check the world:
	local world = cRoot:Get():GetWorld(aSplit[2])
	if not(world) then
		LOG("World " .. aSplit[2] .. " not found")
		return true
	end
	
	-- Read the coords:
	local minX = tonumber(aSplit[3])
	local minY = tonumber(aSplit[4])
	local minZ = tonumber(aSplit[5])
	local maxX = tonumber(aSplit[6])
	local maxY = tonumber(aSplit[7])
	local maxZ = tonumber(aSplit[8])
	if (not(minX) or not(minY) or not(minZ) or not(maxX) or not(maxY) or not(maxZ)) then
		-- TODO: Better error reporting
		LOG("Wrong coords")
		return true
	end
	
	-- Check the BlockType:
	if not(aSplit[9]) then
		LOG("Missing parameter: BlockType")
		return true
	end
	local blockType, blockMeta = GetBlockTypeMeta(aSplit[9])
	if (not blockType) then
		LOG("Unknown block type \"" .. aSplit[9] .. "\"")
		return true
	end
	
	-- Check the CellSize:
	local cellSize = 3
	if (aSplit[10]) then
		cellSize = tonumber(aSplit[10])
		if not(cellSize) then
			LOG("Invalid CellSize specification, expected a number")
			return true
		end
	end
	
	-- Check the ExtraPassagesPercent:
	local extraPassagesPercent = 0
	if (aSplit[11]) then
		extraPassagesPercent = tonumber(aSplit[11])
		if not(extraPassagesPercent) then
			LOG("Invalid ExtraPassagesPercent specification, expected a number")
			return true
		end
	end

	local bounds = cCuboid()
	bounds.p1.x = minX
	bounds.p1.y = minY
	bounds.p1.z = minZ
	bounds.p2.x = maxX
	bounds.p2.y = maxY
	bounds.p2.z = maxZ
	MazeGen.generate(nil, world, bounds, blockType, blockMeta, cellSize, extraPassagesPercent)
	LOG("Maze generated")
	return true
end
