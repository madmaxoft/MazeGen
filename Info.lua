-- Info.lua

-- Declares all the plugin information public





gPluginInfo =
{
	Description =
[[
Plugin for the [Cuberite](https://cuberite.org) Minecraft server that allows users to generate mazes.
Requires WorldEdit to be installed. To generate a maze, select an area using WorldEdit, then invoke the
`/mg` command, specifying parameters as needed.

The plugin can also be used through the server console, specifying the world and coords as parameters, rather
than reading them from a player's WorldEdit selection.
]],
	Commands =
	{
		["/mg"] =
		{
			Handler = handleMgCommand,
			HelpString = "Generates a maze",
			Permission = "mazegen.mg",
			ParameterCombinations=
			{
				{
					Params = "BlockType [CellSize] [ExtraPassagesPercent]",
					HelpString = "Generates a maze in the current WorldEdit selection. CellSize defaults to 3, ExtraPassagesPercent to 0",
				},
			}  -- ParameterCombinations
		}  -- "/mg" command
	},  -- Commands
	
	ConsoleCommands =
	{
		["mg"] =
		{
			Handler = handleMgConsoleCommand,
			ParameterCombinations=
			{
				{
					Params = "WorldName MinX MinY MinZ MaxX MaxY MaxZ BlockType [CellSize] [ExtraPassagesPercent]",
					Help = "Generates a maze in the specified area. CellSize defaults to 3, ExtraPassagesPercent to 0",
				},
			}  -- ParameterCombinations
		}  -- "mg" command
	},  -- ConsoleCommands
}
