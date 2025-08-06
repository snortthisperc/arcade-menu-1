-- Main manager for the arcade system

ArcadeGames.Manager = {}

function ArcadeGames.Manager:Initialize()
    -- Load all games
    self:LoadGames()
    
    print("[Arcade Games] Manager initialized with " .. table.Count(ArcadeGames.Games) .. " games")
end

function ArcadeGames.Manager:LoadGames()
    -- Load individual games with correct paths
    -- The issue is likely here - these paths need to be relative to the Lua folder
    print("[Arcade Games] Loading game: Pac-Man")
    include("arcade/games/pacman/pacman.lua")
    
    print("[Arcade Games] Loading game: Flappy Bird")
    include("arcade/games/flappybird/flappybird.lua")
    
    print("[Arcade Games] Loading game: Temple Run")
    include("arcade/games/templerun/templerun.lua")
end

function ArcadeGames.Manager:RegisterGame(game)
    ArcadeGames.Games[game.name] = game
    print("[Arcade Games] Registered game: " .. game.displayName)
end

function ArcadeGames.Manager:OpenMenu()
    if not ArcadeGames.UIManager then
        print("[Arcade Games] Error: UI Manager not loaded")
        return
    end
    
    ArcadeGames.UIManager:CreateMainMenu()
end

function ArcadeGames.Manager:CloseMenu()
    if ArcadeGames.ActiveGame then
        ArcadeGames.ActiveGame:Stop()
        ArcadeGames.ActiveGame = nil
    end
    
    if IsValid(ArcadeGames.UIManager.mainFrame) then
        ArcadeGames.UIManager.mainFrame:Close()
    end
end

-- Initialize the manager
ArcadeGames.Manager:Initialize()
