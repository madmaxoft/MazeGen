-- MazeGen.lua

--[[
Implements the MazeGen class implementing the maze generation algorithm
Typical usage is:
MazeGen.generate(aPlayer, aBounds, aBlockType, aBlockMeta, aCellSize, aExtraPassagesPercent)
--]]





MazeGen = {}
MazeGen.__index = MazeGen

local gBlockTypesAndMetas = cBlockArea.baTypes + cBlockArea.baMetas





--- The main entrypoint to the maze generation
-- Generates the maze, entirely
function MazeGen.generate(aPlayer, aWorld, aBounds, aBlockType, aBlockMeta, aCellSize, aExtraPassagesPercent)
	local mg = MazeGen:new(aPlayer, aWorld, aBounds, aBlockType, aBlockMeta, aCellSize, aExtraPassagesPercent)
	mg:run()
end





--- Creates a new MazeGen object, initializes its members to the specified values
function MazeGen:new(aPlayer, aWorld, aBounds, aBlockType, aBlockMeta, aCellSize, aExtraPassagesPercent)
	local obj = {}
	setmetatable(obj, self)
	obj:init(aPlayer, aWorld, aBounds, aBlockType, aBlockMeta, aCellSize, aExtraPassagesPercent)
	return obj
end





--- Initializes the object, setting its members to the specified values
function MazeGen:init(aPlayer, aWorld, aBounds, aBlockType, aBlockMeta, aCellSize, aExtraPassagesPercent)
	assert((aPlayer == nil) or (tolua.type(aPlayer) == "cPlayer"))
	assert(tolua.type(aWorld) == "cWorld")
	assert(tolua.type(aBounds) == "cCuboid")
	assert(type(aBlockType) == "number")
	assert(type(aBlockMeta) == "number")
	assert(type(aCellSize) == "number")
	assert(type(aExtraPassagesPercent) == "number")
	
	self.mPlayer = aPlayer
	self.mWorld = aWorld
	self.mBounds = aBounds
	self.mBlockType = aBlockType
	self.mBlockMeta = aBlockMeta
	self.mCellSize = aCellSize
	self.mExtraPassagesPercent = aExtraPassagesPercent

	-- The CarveCuboid is used for carving walls, it is cached in order to avoid creating a new cCuboid for each carve
	self.mCarveCuboid = cCuboid()
	self.mCarveCuboid.p1.y = 0
	self.mCarveCuboid.p2.y = aBounds.p2.y - aBounds.p1.y
	
	--- The maze cells, used through the generation
	-- mCells[x][z] = {...} for each cell that is already processed
	self.mCells = {}

	-- The mCells dimensions
	self.mNumCellsX = math.floor(aBounds:DifX() / aCellSize)
	self.mNumCellsZ = math.floor(aBounds:DifZ() / aCellSize)
	
	-- The area which is imprinted into the world at the end
	self.mArea = self:createArea(aBounds)
end





function MazeGen:createArea()
	-- Create an empty area:
	local bounds = self.mBounds
	local area = cBlockArea()
	local sizeX = self.mNumCellsX * self.mCellSize + 1
	local sizeZ = self.mNumCellsZ * self.mCellSize + 1
	area:Create(sizeX, bounds:DifY() + 1, sizeZ, gBlockTypesAndMetas)
	area:Fill(gBlockTypesAndMetas, E_BLOCK_AIR, 0)
	local wall = cCuboid(
		Vector3i(0, 0, 0),
		Vector3i(sizeX - 1, bounds:DifY(), sizeZ - 1)
	)
	
	-- Add the walls between the cells:
	for x = 0, self.mNumCellsX do
		wall.p1.x = x * self.mCellSize
		wall.p2.x = wall.p1.x
		area:FillRelCuboid(wall, gBlockTypesAndMetas, self.mBlockType, self.mBlockMeta)
	end
	wall.p1.x = 0
	wall.p2.x = sizeX - 1
	for z = 0, self.mNumCellsZ do
		wall.p1.z = z * self.mCellSize
		wall.p2.z = wall.p1.z
		area:FillRelCuboid(wall, cBlockArea.baTypes + cBlockArea.baMetas, self.mBlockType, self.mBlockMeta)
	end
	return area
end





--- The directions in which a step can be made
local gDirection =
{
	{x = 1,  z = 0},
	{x = -1, z = 0},
	{x = 0,  z = 1},
	{x = 0,  z = -1},
}

--- Runs the maze generation on the current object
function MazeGen:run()
	self:prepareWorkspace()
	self:createMazeInArea()
	self:carveExtraPassages()
	self:writeArea()
end





function MazeGen:createMazeInArea()
	local numInQueue = 1
	local queue = {{x = 1, z = 1}}
	self.mCells[1][1] = true
	local available = {}
	local numAvailable = 0
	while (numInQueue > 0) do
		local current = queue[numInQueue]
		numInQueue = numInQueue - 1
		
		-- Collect all available neighbors:
		numAvailable = 0
		for dir = 1, 4 do
			local newX, newZ = current.x + gDirection[dir].x, current.z + gDirection[dir].z
			if (self:isCellFree(newX, newZ)) then
				numAvailable = numAvailable + 1
				available[numAvailable] = dir
			end
		end
		
		-- Pick one neighbor to continue to:
		if (numAvailable > 0) then
			local idx = math.random(1, numAvailable)
			assert(idx <= numAvailable)
			assert(idx > 0)
			local dir = gDirection[available[idx]]
			local newX, newZ = current.x + dir.x, current.z + dir.z
			self:carveWall(current.x, current.z, dir.x, dir.z)
			self.mCells[newX][newZ] = true
			if (numAvailable > 1) then
				-- There are multiple directions available, keep the current cell in the queue as well:
				numInQueue = numInQueue + 1
			end
			numInQueue = numInQueue + 1
			queue[numInQueue] = {x = newX, z = newZ}
		end
	end
end





--- Carves random extra passages between cells, according to mExtraPassagesPercent
function MazeGen:carveExtraPassages()
	-- Bail out fast if no extra passages requested:
	if (self.mExtraPassagesPercent == 0) then
		return
	end
	
	-- For each wall, decide whether to carve it or not:
	local epp = self.mExtraPassagesPercent
	for x = 1, self.mNumCellsX - 1 do
		for z = 1, self.mNumCellsZ - 1 do
			if (math.random(1, 100) < epp) then
				self:carveWall(x, z, 1, 0)
			end
			if (math.random(1, 100) < epp) then
				self:carveWall(x, z, 0, 1)
			end
		end
	end
end





-- Writes the maze in mArea into the world:
function MazeGen:writeArea()
	self.mArea:Write(self.mWorld, self.mBounds.p1)
end





--- Carves a wall between the specified cell and its neighbor specified by the direction offsets
-- aDirX, aDirZ can only be -1, 0 or 1, and exactly one of them is zero
function MazeGen:carveWall(aCellX, aCellZ, aDirX, aDirZ)
	-- Since this is a perf-critical code-path in a tight loop, no param checking is done
	if (aDirX == 1) then
		-- Carve the X+ wall:
		self.mCarveCuboid.p1.x = aCellX * self.mCellSize
		self.mCarveCuboid.p2.x = self.mCarveCuboid.p1.x
		self.mCarveCuboid.p1.z = (aCellZ - 1) * self.mCellSize + 1
		self.mCarveCuboid.p2.z = aCellZ * self.mCellSize - 1
	elseif (aDirX == -1) then
		-- Carve the X- wall:
		self.mCarveCuboid.p1.x = (aCellX - 1) * self.mCellSize
		self.mCarveCuboid.p2.x = self.mCarveCuboid.p1.x
		self.mCarveCuboid.p1.z = (aCellZ - 1) * self.mCellSize + 1
		self.mCarveCuboid.p2.z = aCellZ * self.mCellSize - 1
	elseif (aDirZ == 1) then
		-- Carve the Z+ wall:
		self.mCarveCuboid.p1.x = (aCellX - 1) * self.mCellSize + 1
		self.mCarveCuboid.p2.x = aCellX * self.mCellSize - 1
		self.mCarveCuboid.p1.z = aCellZ * self.mCellSize
		self.mCarveCuboid.p2.z = self.mCarveCuboid.p1.z
	else
		-- Carve the Z- wall:
		self.mCarveCuboid.p1.x = (aCellX - 1) * self.mCellSize + 1
		self.mCarveCuboid.p2.x = aCellX * self.mCellSize - 1
		self.mCarveCuboid.p1.z = (aCellZ - 1) * self.mCellSize
		self.mCarveCuboid.p2.z = self.mCarveCuboid.p1.z
	end
	self.mArea:FillRelCuboid(self.mCarveCuboid, gBlockTypesAndMetas, E_BLOCK_AIR, 0)
end





--- Returns whether the cell at the specified coords is free (has NOT been visited yet)
-- Returns false for out-of-range coords
function MazeGen:isCellFree(aCellX, aCellZ)
	if (
		(aCellX < 1) or
		(aCellX > self.mNumCellsX) or
		(aCellZ < 1) or
		(aCellZ > self.mNumCellsZ)
	) then
		return false
	end
	
	return (self.mCells[aCellX][aCellZ] == nil)
end





--- Prepares the workspace for the generation
-- Makes sure the mCells[x][z] is accessible for all coords
function MazeGen:prepareWorkspace()
	for x = 1, self.mNumCellsX do
		self.mCells[x] = {}
	end
end
