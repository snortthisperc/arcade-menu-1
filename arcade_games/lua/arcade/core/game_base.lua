-- Base class for all arcade games

ArcadeGames.GameBase = {}
ArcadeGames.GameBase.__index = ArcadeGames.GameBase

function ArcadeGames.GameBase:New(name, displayName)
    local game = {}
    setmetatable(game, self)
    
    game.name = name
    game.displayName = displayName
    game.isRunning = false
    game.isPaused = false
    game.score = 0
    game.highScore = 0
    game.gameTime = 0
    game.lastThink = 0
    
    -- Game area dimensions (will be scaled to fit panel)
    game.gameWidth = 800
    game.gameHeight = 600
    
    -- Load high score
    game:LoadHighScore()
    
    return game
end

function ArcadeGames.GameBase:Initialize()
    -- Override in child classes
end

function ArcadeGames.GameBase:Start()
    self.isRunning = true
    self.isPaused = false
    self.score = 0
    self.gameTime = 0
    self.lastThink = CurTime()
    self:OnStart()
end

function ArcadeGames.GameBase:Stop()
    self.isRunning = false
    self:SaveHighScore()
    self:OnStop()
end

function ArcadeGames.GameBase:Pause()
    self.isPaused = not self.isPaused
    self:OnPause(self.isPaused)
end

function ArcadeGames.GameBase:Think()
    if not self.isRunning or self.isPaused then return end
    
    local currentTime = CurTime()
    local deltaTime = currentTime - self.lastThink
    self.lastThink = currentTime
    self.gameTime = self.gameTime + deltaTime
    
    self:OnThink(deltaTime)
end

function ArcadeGames.GameBase:Paint(w, h)
    -- Calculate scale to fit game area
    local scaleX = w / self.gameWidth
    local scaleY = h / self.gameHeight
    local scale = math.min(scaleX, scaleY)
    
    local gameW = self.gameWidth * scale
    local gameH = self.gameHeight * scale
    local offsetX = (w - gameW) / 2
    local offsetY = (h - gameH) / 2
    
    -- Draw game background
    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(offsetX, offsetY, gameW, gameH)
    
    -- Set up scaled drawing
    local oldMatrix = Matrix()
    oldMatrix:Scale(Vector(scale, scale, 1))
    oldMatrix:Translate(Vector(offsetX / scale, offsetY / scale, 0))
    
    cam.PushModelMatrix(oldMatrix)
    self:OnPaint(self.gameWidth, self.gameHeight)
    cam.PopModelMatrix()
    
    -- Draw UI overlay
    self:DrawUI(w, h)
end

function ArcadeGames.GameBase:DrawUI(w, h)
    -- Draw score
    draw.SimpleText("Score: " .. self.score, "DermaDefault", 10, 10, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("High Score: " .. self.highScore, "DermaDefault", 10, 30, Color(255, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    if self.isPaused then
        draw.SimpleText("PAUSED", "DermaLarge", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function ArcadeGames.GameBase:OnKeyPress(key)
    -- Override in child classes
end

function ArcadeGames.GameBase:OnMousePress(mouseCode, x, y)
    -- Override in child classes
end

function ArcadeGames.GameBase:LoadHighScore()
    self.highScore = tonumber(file.Read("arcade_" .. self.name .. "_highscore.txt", "DATA") or "0") or 0
end

function ArcadeGames.GameBase:SaveHighScore()
    if self.score > self.highScore then
        self.highScore = self.score
        file.Write("arcade_" .. self.name .. "_highscore.txt", tostring(self.highScore))
    end
end

-- Override these methods in child classes
function ArcadeGames.GameBase:OnStart() end
function ArcadeGames.GameBase:OnStop() end
function ArcadeGames.GameBase:OnPause(paused) end
function ArcadeGames.GameBase:OnThink(deltaTime) end
function ArcadeGames.GameBase:OnPaint(w, h) end
