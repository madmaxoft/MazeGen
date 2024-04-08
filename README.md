Plugin for the [Cuberite](https://cuberite.org) Minecraft server that allows users to generate mazes. Requires WorldEdit to be installed. To generate a maze, select an area using WorldEdit, then invoke the `/mg` command, specifying parameters as needed.

The plugin can also be used through the server console, specifying the world and coords as parameters, rather than reading them from a player's WorldEdit selection.

# Technical
Internally, the plugin uses the Recursive backtracker algorithm to generate the maze. Due to Lua having a limited stack depth of 100 levels only, instead of using the call-stack, the plugin keeps its own stack of cells to backtrack to. 

# Commands

### General
| Command | Permission | Description |
| ------- | ---------- | ----------- |
|/mg | mazegen.mg | Generates a maze|



# Permissions
| Permissions | Description | Commands | Recommended groups |
| ----------- | ----------- | -------- | ------------------ |
| mazegen.mg |  | `/mg` |  |
