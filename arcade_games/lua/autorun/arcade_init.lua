-- Arcade Games Addon Initialization
if SERVER then return end

-- Create global namespace
ArcadeGames = ArcadeGames or {}
ArcadeGames.Games = {}
ArcadeGames.ActiveGame = nil
ArcadeGames.UI = nil
ArcadeGames.Debug = true -- Enable debug mode

-- Debug function
function ArcadeGames.DebugPrint(msg)
    if ArcadeGames.Debug then
        print("[Arcade Games] " .. msg)
    end
end

-- Load core files directly
ArcadeGames.DebugPrint("Loading core files directly...")

local function LoadFileDirectly(filePath)
    -- Try multiple possible paths
    local possiblePaths = {
        "addons/arcade_games/lua/" .. filePath,
        "lua/" .. filePath,
        filePath,
        -- Try with backslashes too (Windows paths)
        "addons\\arcade_games\\lua\\" .. string.gsub(filePath, "/", "\\"),
        "lua\\" .. string.gsub(filePath, "/", "\\"),
        string.gsub(filePath, "/", "\\")
    }
    
    local content = nil
    for _, path in ipairs(possiblePaths) do
        ArcadeGames.DebugPrint("Trying path: " .. path)
        content = file.Read(path, "GAME")
        if content then
            ArcadeGames.DebugPrint("Successfully loaded: " .. path)
            break
        end
    end
    
    if content then
        local success, errorMsg = pcall(function()
            RunString(content, filePath)
        end)
        
        if not success then
            ArcadeGames.DebugPrint("Error executing " .. filePath .. ": " .. errorMsg)
            return false
        end
        return true
    else
        ArcadeGames.DebugPrint("Failed to load: " .. filePath)
        
        -- Try to list files in directory to help diagnose
        local dir = string.match(filePath, "(.*)/[^/]*$") or ""
        local files, dirs = file.Find("addons/arcade_games/lua/" .. dir .. "/*", "GAME")
        
        if files and #files > 0 then
            ArcadeGames.DebugPrint("Files found in directory:")
            for _, f in ipairs(files) do
                ArcadeGames.DebugPrint("  - " .. f)
            end
        else
            ArcadeGames.DebugPrint("No files found in directory: addons/arcade_games/lua/" .. dir)
        end
        
        return false
    end
end

-- Try to load core files
local coreFilesLoaded = true
coreFilesLoaded = LoadFileDirectly("arcade/core/game_base.lua") and coreFilesLoaded
coreFilesLoaded = LoadFileDirectly("arcade/core/ui_manager.lua") and coreFilesLoaded
coreFilesLoaded = LoadFileDirectly("arcade/core/arcade_manager.lua") and coreFilesLoaded

-- Console command to open arcade
concommand.Add("arcade_open", function()
    if ArcadeGames and ArcadeGames.Manager then
        ArcadeGames.Manager:OpenMenu()
    else
        ArcadeGames.DebugPrint("Error: Manager not initialized")
    end
end)

if coreFilesLoaded then
    ArcadeGames.DebugPrint("Core files loaded successfully!")
else
    ArcadeGames.DebugPrint("ERROR: Some core files failed to load!")
    
    -- Try to list all mounted addons for debugging
    ArcadeGames.DebugPrint("Checking mounted addons:")
    local addons = engine.GetAddons()
    for _, addon in ipairs(addons) do
        if addon.mounted then
            ArcadeGames.DebugPrint("  - " .. addon.title)
        end
    end
    
    -- Check if our materials exist
    ArcadeGames.DebugPrint("Checking materials:")
    local materialPaths = {
        "materials/arcade/flappybird/bird.vmt",
        "materials/arcade/flappybird/pipe.vmt",
        "materials/arcade/flappybird/background.vmt"
    }
    
    for _, path in ipairs(materialPaths) do
        ArcadeGames.DebugPrint("  - " .. path .. ": " .. (file.Exists(path, "GAME") and "Found" or "Not Found"))
    end
    
    -- Check if we can list directories
    local files, dirs = file.Find("addons/*", "GAME")
    if files and #files > 0 or dirs and #dirs > 0 then
        ArcadeGames.DebugPrint("Addon directory listing:")
        for _, d in ipairs(dirs or {}) do
            ArcadeGames.DebugPrint("  - " .. d)
        end
    else
        ArcadeGames.DebugPrint("Cannot list addon directories")
    end
end

ArcadeGames.DebugPrint("Initialization complete. Use 'arcade_open' to play.")

--[[


Features Implemented
Modular Game System: Easy to add new games by extending the GameBase class
Performance Optimized: Games only run when active, proper cleanup
Persistent High Scores: Saves high scores to data files
Responsive Controls: Supports both keyboard and mouse input
Scalable UI: Games scale to fit the display panel
Pause/Resume Functionality: All games support pausing
Professional UI: Clean, organized interface with game selection

garrysmod/addons/arcade_games/
├── lua/
│   ├── autorun/
│   │   └── arcade_init.lua
│   ├── arcade/
│   │   ├── core/
│   │   │   ├── arcade_manager.lua
│   │   │   ├── game_base.lua
│   │   │   └── ui_manager.lua
│   │   └── games/
│   │       ├── pacman/
│   │       │   └── pacman.lua
│   │       ├── flappybird/
│   │       │   └── flappybird.lua
│   │       └── templerun/
│   │           └── templerun.lua
├── materials/
│   └── arcade/
│       ├── pacman/
│       │   ├── pacman.png
│       │   ├── ghost.png
│       │   ├── pellet.png
│       │   └── wall.png
│       ├── flappybird/
│       │   ├── bird.png
│       │   ├── pipe.png
│       │   └── background.png
│       └── templerun/
│           ├── runner.png
│           ├── obstacle.png
│           └── ground.png
└── addon.json


]]