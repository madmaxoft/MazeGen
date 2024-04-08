-- Main.lua

-- Implements the main entry point for the plugin





--- Some blocks won't render if the meta value is 0.
-- Here we keep a list of all of them with the first allowed meta value.
-- Please keep the list alphasorted.
local gDefaultMetas = {
	[E_BLOCK_CHEST]              = 2,
	[E_BLOCK_ENDER_CHEST]        = 2,
	[E_BLOCK_FURNACE]            = 2,
	[E_BLOCK_LADDER]             = 2,
	[E_BLOCK_LIT_FURNACE]        = 2,
	[E_BLOCK_NETHER_PORTAL]      = 1,
	[E_BLOCK_TORCH]              = 1,
	[E_BLOCK_TRAPPED_CHEST]      = 2,
	[E_BLOCK_REDSTONE_TORCH_ON]  = 1,
	[E_BLOCK_REDSTONE_TORCH_OFF] = 1,
	[E_BLOCK_WALLSIGN]           = 2,
	[E_BLOCK_WALL_BANNER]        = 2
}





--- Returns the block type (and block meta) from a string.
-- This can be something like "1", "1:0", "stone" and "stone:0".
function GetBlockTypeMeta(a_BlockString)
	local BlockID = tonumber(a_BlockString)

	-- Check if it was a normal number
	if (BlockID) then
		return BlockID, gDefaultMetas[BlockID] or 0, true
	end

	-- Check for block meta
	local HasMeta = string.find(a_BlockString, ":")

	-- Check if it was a name.
	local Item = cItem()
	if (not StringToItem(a_BlockString, Item)) then
		return false
	else
		if (HasMeta or (Item.m_ItemDamage ~= 0)) then
			return Item.m_ItemType, Item.m_ItemDamage
		else
			return Item.m_ItemType, gDefaultMetas[Item.m_ItemType] or 0, true
		end
	end
end




--- The main plugin entrypoint
function Initialize(aPlugin)
	-- Load the InfoReg shared library:
	dofile(cPluginManager:GetPluginsPath() .. "/InfoReg.lua")

	--Bind all the commands:
	RegisterPluginInfoCommands(gPluginInfo)
	RegisterPluginInfoConsoleCommands(gPluginInfo)

	return true
end
