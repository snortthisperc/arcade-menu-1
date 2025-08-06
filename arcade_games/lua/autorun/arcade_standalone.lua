-- Arcade Games Standalone - All code in one file
if SERVER then return end

print("[Arcade Games] Loading standalone version...")

-- Create global namespace
ArcadeGames = ArcadeGames or {}
ArcadeGames.Games = {}
ArcadeGames.ActiveGame = nil
ArcadeGames.UI = nil

-- =============================================
-- GAME BASE CLASS
-- =============================================

ArcadeGames.GameBase = {}
ArcadeGames.GameBase.__index = ArcadeGames.GameBase
ArcadeGames.GameBase.STATE_TUTORIAL = 0
ArcadeGames.GameBase.STATE_PLAYING = 1
ArcadeGames.GameBase.STATE_PAUSED = 2
ArcadeGames.GameBase.STATE_GAME_OVER = 3

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

function ArcadeGames.GameBase:SetState(newState)
    local oldState = self.state
    self.state = newState
    self:OnStateChanged(oldState, newState)
end

function ArcadeGames.GameBase:SetupInputHandling(panel)
    panel.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE then
            -- Handle escape
            return
        elseif key == KEY_P then
            -- Handle pause
            return
        end
        
        -- Forward to game
        game:OnKeyPress(key)
    end
    
    panel.OnKeyCodeReleased = function(self, key)
        game:OnKeyRelease(key)
    end
    
    panel.OnMousePressed = function(self, mouseCode)
        local x, y = self:CursorPos()
        game:OnMousePress(mouseCode, x, y)
    end
    
    panel.OnMouseReleased = function(self, mouseCode)
        local x, y = self:CursorPos()
        game:OnMouseRelease(mouseCode, x, y)
    end
end

function ArcadeGames.GameBase:OnKeyRelease(key)
    -- Override in child classes
end

function ArcadeGames.GameBase:OnMouseRelease(mouseCode, x, y)
    -- Override in child classes
end

function ArcadeGames.GameBase:OnStateChanged(oldState, newState)
    -- Override in child classes
end

-- Override these methods in child classes
function ArcadeGames.GameBase:OnStart() end
function ArcadeGames.GameBase:OnStop() end
function ArcadeGames.GameBase:OnPause(paused) end
function ArcadeGames.GameBase:OnThink(deltaTime) end
function ArcadeGames.GameBase:OnPaint(w, h) end

-- =============================================
-- Enhanced UI Manager
-- =============================================

ArcadeGames.UIManager = {}

-- Color scheme
ArcadeGames.UIManager.Colors = {
    background = Color(20, 24, 35),     -- Dark blue-gray
    panel = Color(30, 34, 45),          -- Slightly lighter blue-gray
    accent = Color(65, 105, 225),       -- Royal blue
    text = Color(240, 240, 240),        -- Off-white
    textDark = Color(50, 50, 50),       -- Dark gray for text on light backgrounds
    highlight = Color(100, 180, 255),   -- Light blue highlight
    success = Color(100, 200, 100),     -- Green for success/start
    warning = Color(200, 150, 50),      -- Orange for warnings/pause
    danger = Color(200, 80, 80)         -- Red for danger/stop
}

-- Load UI materials
function ArcadeGames.UIManager:LoadMaterials()
    self.Materials = {
        gamePanel = Material("arcade/ui/game_panel_bg", "smooth"),
        menuBackground = Material("arcade/ui/menu_background", "smooth"),
        buttonNormal = Material("arcade/ui/button_normal", "smooth"),
        buttonHover = Material("arcade/ui/button_hover", "smooth"),
        buttonActive = Material("arcade/ui/button_active", "smooth")
    }
    
    -- Fallback to colored rectangles if materials aren't found
    self.useMaterials = true
    for name, mat in pairs(self.Materials) do
        if mat:IsError() then
            self.useMaterials = false
            print("[Arcade Games] Warning: Material " .. name .. " not found, using fallback colors")
            break
        end
    end
end

-- Create a styled button
function ArcadeGames.UIManager:CreateStyledButton(parent, text, x, y, w, h)
    local btn = vgui.Create("DButton", parent)
    btn:SetText(text)
    btn:SetPos(x, y)
    btn:SetSize(w, h)
    btn:SetFont("DermaDefaultBold")
    btn:SetTextColor(self.Colors.text)
    btn:SetContentAlignment(5) -- Center
    
    -- Custom paint function for the button
    btn.Paint = function(self, w, h)
        local col = ArcadeGames.UIManager.Colors.panel
        
        if ArcadeGames.UIManager.useMaterials then
            local mat = ArcadeGames.UIManager.Materials.buttonNormal
            if self:IsDown() then
                mat = ArcadeGames.UIManager.Materials.buttonActive
                col = ArcadeGames.UIManager.Colors.accent
            elseif self:IsHovered() then
                mat = ArcadeGames.UIManager.Materials.buttonHover
                col = ArcadeGames.UIManager.Colors.highlight
            end
            
            surface.SetMaterial(mat)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(0, 0, w, h)
        else
            -- Fallback to colored rectangles
            if self:IsDown() then
                col = ArcadeGames.UIManager.Colors.accent
            elseif self:IsHovered() then
                col = ArcadeGames.UIManager.Colors.highlight
            end
            
            draw.RoundedBox(8, 0, 0, w, h, col)
            draw.RoundedBox(8, 2, 2, w-4, h-4, ArcadeGames.UIManager.Colors.panel)
        end
    end
    
    return btn
end

-- Create the main menu with grid layout
function ArcadeGames.UIManager:CreateMainMenu()
    -- Load materials if not already loaded
    if not self.Materials then
        self:LoadMaterials()
    end
    
    -- Remove existing frame if it exists
    if IsValid(self.mainFrame) then
        self.mainFrame:Remove()
    end
    
    -- Create the main frame
    local frame = vgui.Create("DFrame")
    frame:SetSize(1200, 800)
    frame:Center()
    frame:SetTitle("Arcade Games Collection")
    frame:SetDeleteOnClose(true)
    frame:MakePopup()
    
    -- Custom paint function for the frame
    frame.Paint = function(self, w, h)
        if ArcadeGames.UIManager.useMaterials then
            surface.SetMaterial(ArcadeGames.UIManager.Materials.menuBackground)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(0, 0, w, h)
        else
            -- Fallback to colored background
            draw.RoundedBox(0, 0, 0, w, h, ArcadeGames.UIManager.Colors.background)
            draw.RoundedBox(0, 0, 0, w, 24, ArcadeGames.UIManager.Colors.panel)
        end
    end
    
    -- Title and header
    local headerPanel = vgui.Create("DPanel", frame)
    headerPanel:SetPos(10, 30)
    headerPanel:SetSize(frame:GetWide() - 20, 60)
    headerPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, ArcadeGames.UIManager.Colors.panel)
        draw.SimpleText("ARCADE GAMES COLLECTION", "DermaLarge", w/2, h/2, ArcadeGames.UIManager.Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Game grid container
    local gameGridContainer = vgui.Create("DScrollPanel", frame)
    gameGridContainer:SetPos(10, 100)
    gameGridContainer:SetSize(frame:GetWide() - 20, frame:GetTall() - 170)
    
    -- Style the scrollbar
    local scrollBar = gameGridContainer:GetVBar()
    scrollBar:SetWide(10)
    scrollBar.Paint = function(self, w, h) 
        draw.RoundedBox(0, 0, 0, w, h, ArcadeGames.UIManager.Colors.background) 
    end
    scrollBar.btnUp.Paint = function(self, w, h) 
        draw.RoundedBox(0, 0, 0, w, h, ArcadeGames.UIManager.Colors.panel) 
    end
    scrollBar.btnDown.Paint = function(self, w, h) 
        draw.RoundedBox(0, 0, 0, w, h, ArcadeGames.UIManager.Colors.panel) 
    end
    scrollBar.btnGrip.Paint = function(self, w, h) 
        draw.RoundedBox(4, 2, 0, w-4, h, ArcadeGames.UIManager.Colors.accent) 
    end
    
    -- Create game grid
    local gameGrid = vgui.Create("DIconLayout", gameGridContainer)
    gameGrid:SetPos(0, 0)
    gameGrid:SetSize(gameGridContainer:GetWide(), gameGridContainer:GetTall())
    gameGrid:SetSpaceX(20)
    gameGrid:SetSpaceY(20)
    
    -- Calculate panel size for 3 per row
    local panelWidth = (gameGrid:GetWide() - 40) / 3
    local panelHeight = panelWidth * 0.75 -- 4:3 aspect ratio
    
    -- Populate game grid
    for name, game in pairs(ArcadeGames.Games) do
        local gamePanel = gameGrid:Add("DPanel")
        gamePanel:SetSize(panelWidth, panelHeight)
        
        -- Game panel paint function
        gamePanel.Paint = function(self, w, h)
            if ArcadeGames.UIManager.useMaterials then
                surface.SetMaterial(ArcadeGames.UIManager.Materials.gamePanel)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawTexturedRect(0, 0, w, h)
            else
                -- Fallback to rounded rectangle
                draw.RoundedBox(16, 0, 0, w, h, ArcadeGames.UIManager.Colors.panel)
            end
            
            -- Game title
            draw.SimpleText(game.displayName, "DermaLarge", w/2, 30, ArcadeGames.UIManager.Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- High score
            draw.SimpleText("High Score: " .. game.highScore, "DermaDefault", w/2, h - 40, ArcadeGames.UIManager.Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Play button
        local playBtn = self:CreateStyledButton(gamePanel, "PLAY", panelWidth/2 - 50, panelHeight/2 - 20, 100, 40)
        playBtn.DoClick = function()
            self:LoadGame(game, frame)
        end
    end
    
    -- Footer with controls info
    local footerPanel = vgui.Create("DPanel", frame)
    footerPanel:SetPos(10, frame:GetTall() - 60)
    footerPanel:SetSize(frame:GetWide() - 20, 50)
    footerPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, ArcadeGames.UIManager.Colors.panel)
        draw.SimpleText("Controls: WASD/Arrow Keys to move, SPACE for actions, P to pause, ESC to return to menu", 
                       "DermaDefault", w/2, h/2, ArcadeGames.UIManager.Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    self.mainFrame = frame
    return frame
end

-- Load a game
function ArcadeGames.UIManager:LoadGame(game, parentFrame)
    -- Stop current game if running
    if ArcadeGames.ActiveGame then
        ArcadeGames.ActiveGame:Stop()
    end
    
    ArcadeGames.ActiveGame = game
    
    -- Hide the main menu frame
    if IsValid(parentFrame) then
        parentFrame:SetVisible(false)
    end
    
    -- Create game frame
    local gameFrame = vgui.Create("DFrame")
    gameFrame:SetSize(1000, 700)
    gameFrame:Center()
    gameFrame:SetTitle(game.displayName)
    gameFrame:SetDeleteOnClose(false)
    gameFrame:MakePopup()
    
    -- Custom paint function for the game frame
    gameFrame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, ArcadeGames.UIManager.Colors.background)
        draw.RoundedBox(0, 0, 0, w, 24, ArcadeGames.UIManager.Colors.panel)
    end
    
    -- Game container with rounded corners
    local gameContainer = vgui.Create("DPanel", gameFrame)
    gameContainer:SetPos(10, 34)
    gameContainer:SetSize(gameFrame:GetWide() - 20, gameFrame:GetTall() - 84)
    
    -- Game container paint function
    gameContainer.Paint = function(self, w, h)
        draw.RoundedBox(16, 0, 0, w, h, ArcadeGames.UIManager.Colors.panel)
        game:Paint(w, h)
    end
    
    -- Game think function
    gameContainer.Think = function(self)
        game:Think()
    end
    
    -- Input handling
    gameContainer:SetKeyboardInputEnabled(true)
    gameContainer:SetMouseInputEnabled(true)
    gameContainer:RequestFocus()
    
    gameContainer.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE then
            gameFrame:Close()
            if IsValid(parentFrame) then
                parentFrame:SetVisible(true)
            end
            game:Stop()
            ArcadeGames.ActiveGame = nil
            return
        elseif key == KEY_P then
            game:Pause()
            return
        end
        
        game:OnKeyPress(key)
    end
    
    gameContainer.OnMousePressed = function(self, mouseCode)
        local x, y = self:CursorPos()
        game:OnMousePress(mouseCode, x, y)
    end
    
    -- Control buttons
    local buttonPanel = vgui.Create("DPanel", gameFrame)
    buttonPanel:SetPos(10, gameFrame:GetTall() - 40)
    buttonPanel:SetSize(gameFrame:GetWide() - 20, 30)
    buttonPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, ArcadeGames.UIManager.Colors.panel)
    end
    
    -- Start button
    local startBtn = self:CreateStyledButton(buttonPanel, "Start Game", 10, 0, 100, 30)
    startBtn.Paint = function(self, w, h)
        local col = ArcadeGames.UIManager.Colors.success
        if self:IsDown() then
            col = Color(col.r * 0.8, col.g * 0.8, col.b * 0.8)
        elseif self:IsHovered() then
            col = Color(col.r * 1.2, col.g * 1.2, col.b * 1.2, 255)
        end
        draw.RoundedBox(6, 0, 0, w, h, col)
    end
    startBtn.DoClick = function()
        game:Start()
        gameContainer:RequestFocus()
    end
    
    -- Pause button
    local pauseBtn = self:CreateStyledButton(buttonPanel, "Pause", 120, 0, 80, 30)
    pauseBtn.Paint = function(self, w, h)
        local col = ArcadeGames.UIManager.Colors.warning
        if self:IsDown() then
            col = Color(col.r * 0.8, col.g * 0.8, col.b * 0.8)
        elseif self:IsHovered() then
            col = Color(col.r * 1.2, col.g * 1.2, col.b * 1.2, 255)
        end
        draw.RoundedBox(6, 0, 0, w, h, col)
    end
    pauseBtn.DoClick = function()
        game:Pause()
        gameContainer:RequestFocus()
    end
    
    -- Stop button
    local stopBtn = self:CreateStyledButton(buttonPanel, "Stop", 210, 0, 80, 30)
    stopBtn.Paint = function(self, w, h)
        local col = ArcadeGames.UIManager.Colors.danger
        if self:IsDown() then
            col = Color(col.r * 0.8, col.g * 0.8, col.b * 0.8)
        elseif self:IsHovered() then
            col = Color(col.r * 1.2, col.g * 1.2, col.b * 1.2, 255)
        end
        draw.RoundedBox(6, 0, 0, w, h, col)
    end
    stopBtn.DoClick = function()
        game:Stop()
        gameContainer:RequestFocus()
    end
    
    -- Return to menu button
    local menuBtn = self:CreateStyledButton(buttonPanel, "Return to Menu", buttonPanel:GetWide() - 120, 0, 110, 30)
    menuBtn.DoClick = function()
        gameFrame:Close()
        if IsValid(parentFrame) then
            parentFrame:SetVisible(true)
        end
        game:Stop()
        ArcadeGames.ActiveGame = nil
    end
    
    -- Handle frame close
    gameFrame.OnClose = function()
        if IsValid(parentFrame) then
            parentFrame:SetVisible(true)
        end
        game:Stop()
        ArcadeGames.ActiveGame = nil
    end
    
    -- Initialize game
    game:Initialize()
    
    return gameFrame
end

-- =============================================
-- ARCADE MANAGER
-- =============================================

ArcadeGames.Manager = {}

function ArcadeGames.Manager:Initialize()
    -- Load all games
    self:LoadGames()
    
    print("[Arcade Games] Manager initialized with " .. table.Count(ArcadeGames.Games) .. " games")
end

function ArcadeGames.Manager:LoadGames()
    -- Load Flappy Bird game
    local FlappyBirdGame = {}
    setmetatable(FlappyBirdGame, {__index = ArcadeGames.GameBase})
    
    function FlappyBirdGame:New()
        local game = ArcadeGames.GameBase:New("flappybird", "Flappy Bird")
        setmetatable(game, {__index = self})
        
        -- Create placeholder materials since the real ones aren't found
        game.materials = {
            bird = Material("gui/noicon"),
            pipe = Material("gui/noicon"),
            background = Material("gui/noicon")
        }
        
        -- Game specific properties
        game.bird = {
            x = 100,                -- Bird's horizontal position
            y = 300,                -- Bird's vertical position
            velocity = 0,           -- Current vertical velocity
            size = 40,              -- Bird sprite size
            rotation = 0,           -- Current rotation angle
            flapStrength = 0,       -- Visual flap animation strength
            flapTime = 0            -- Time tracking for flap animation
        }
        
        -- Game physics settings
        game.gravity = 1200         -- Gravity strength
        game.jumpForce = -400       -- Jump/flap force
        game.terminalVelocity = 600 -- Maximum falling speed
        
        -- Pipe settings
        game.pipes = {}             -- Array to store pipe objects
        game.pipeSpeed = 180        -- Horizontal pipe movement speed
        game.pipeGap = 170          -- Vertical gap between pipes
        game.pipeWidth = 80         -- Width of pipe sprites
        game.pipeSpacing = 300      -- Horizontal distance between pipe sets
        game.nextPipeX = 500        -- X position for next pipe spawn
        game.minPipeHeight = 80     -- Minimum height for pipe placement
        
        -- Background settings
        game.bgScroll = 0           -- Background scroll position
        game.bgScrollSpeed = 30     -- Background scroll speed
        game.groundHeight = 80      -- Height of ground area
        game.groundScroll = 0       -- Ground scroll position
        
        return game
    end
    
    function FlappyBirdGame:OnStart()
        self.bird.y = 300
        self.bird.velocity = 0
        self.pipes = {}
        self.nextPipeX = 400
    end
    
    function FlappyBirdGame:OnThink(deltaTime)
        -- Update bird physics
        self.bird.velocity = self.bird.velocity + self.gravity * deltaTime
        self.bird.y = self.bird.y + self.bird.velocity * deltaTime
        
        -- Check ground/ceiling collision
        if self.bird.y > self.gameHeight - self.bird.size or self.bird.y < self.bird.size then
            self:Stop()
            return
        end
        
        -- Spawn pipes
        if self.nextPipeX <= self.gameWidth then
            local gapY = math.random(100, self.gameHeight - 200)
            table.insert(self.pipes, {
                x = self.nextPipeX,
                gapY = gapY,
                passed = false
            })
            self.nextPipeX = self.nextPipeX + 300
        end
        
        -- Update pipes
        for i = #self.pipes, 1, -1 do
            local pipe = self.pipes[i]
            pipe.x = pipe.x - self.pipeSpeed * deltaTime
            
            -- Check if bird passed pipe
            if not pipe.passed and pipe.x + self.pipeWidth < self.bird.x then
                pipe.passed = true
                self.score = self.score + 1
            end
            
            -- Remove off-screen pipes
            if pipe.x + self.pipeWidth < 0 then
                table.remove(self.pipes, i)
            end
            
            -- Check collision
            if self:CheckPipeCollision(pipe) then
                self:Stop()
                return
            end
        end
        
        -- Reset pipe spawning when needed
        if #self.pipes == 0 or self.pipes[#self.pipes].x < self.gameWidth - 300 then
            self.nextPipeX = math.max(self.nextPipeX, self.gameWidth)
        end
    end
    
    function FlappyBirdGame:CheckPipeCollision(pipe)
        local birdLeft = self.bird.x - self.bird.size/2
        local birdRight = self.bird.x + self.bird.size/2
        local birdTop = self.bird.y - self.bird.size/2
        local birdBottom = self.bird.y + self.bird.size/2
        
        local pipeLeft = pipe.x
        local pipeRight = pipe.x + self.pipeWidth
        
        -- Check if bird is horizontally aligned with pipe
        if birdRight > pipeLeft and birdLeft < pipeRight then
            -- Check if bird is in the gap
            if birdTop < pipe.gapY or birdBottom > pipe.gapY + self.pipeGap then
                return true
            end
        end
        
        return false
    end
    
    function FlappyBirdGame:OnPaint(w, h)
        -- Draw background with color instead of texture
        surface.SetDrawColor(135, 206, 235, 255) -- Sky blue
        surface.DrawRect(0, 0, w, h)
        
        -- Draw pipes with color instead of texture
        surface.SetDrawColor(0, 128, 0, 255) -- Green
        for _, pipe in ipairs(self.pipes) do
            -- Top pipe
            surface.DrawRect(pipe.x, 0, self.pipeWidth, pipe.gapY)
            -- Bottom pipe
            surface.DrawRect(pipe.x, pipe.gapY + self.pipeGap, self.pipeWidth, h - (pipe.gapY + self.pipeGap))
        end
        
        -- Draw ground
        surface.SetDrawColor(222, 216, 149, 255) -- Sandy color
        surface.DrawRect(0, h - 50, w, 50)
        
        -- Draw bird
        surface.SetDrawColor(255, 255, 0, 255) -- Yellow
        
        -- Calculate bird rotation based on velocity
        self.bird.rotation = math.Clamp(self.bird.velocity * 0.1, -30, 30)
        
        -- Save the current render state
        local mat = Matrix()
        mat:Translate(Vector(self.bird.x, self.bird.y, 0))
        mat:Rotate(Angle(0, 0, self.bird.rotation))
        mat:Translate(Vector(-self.bird.size/2, -self.bird.size/2, 0))
        
        cam.PushModelMatrix(mat)
        surface.DrawRect(0, 0, self.bird.size, self.bird.size)
        cam.PopModelMatrix()
    end
    
    function FlappyBirdGame:OnKeyPress(key)
        if key == KEY_SPACE or key == KEY_W or key == KEY_UP then
            self.bird.velocity = self.jumpForce
        end
    end
    
    function FlappyBirdGame:OnMousePress(mouseCode, x, y)
        if mouseCode == MOUSE_LEFT then
            self.bird.velocity = self.jumpForce
        end
    end
    
    -- Register the game
    local flappyBirdGame = FlappyBirdGame:New()
    ArcadeGames.Games["flappybird"] = flappyBirdGame
    
    -- Add Pac-Man game (simplified version)
    local PacManGame = {}
    setmetatable(PacManGame, {__index = ArcadeGames.GameBase})
    
    function PacManGame:New()
        local game = ArcadeGames.GameBase:New("pacman", "Pac-Man")
        setmetatable(game, {__index = self})
        
        -- Game specific properties
        game.player = {x = 400, y = 300, dir = 0, nextDir = 0, speed = 100}
        game.ghosts = {}
        game.pellets = {}
        game.walls = {}
        game.cellSize = 20
        
        return game
    end
    
    function PacManGame:Initialize()
        self:CreateMaze()
        self:SpawnPellets()
        self:SpawnGhosts()
    end
    
    function PacManGame:CreateMaze()
        -- Simple maze layout (1 = wall, 0 = empty)
        self.maze = {
            {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
            {1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1},
            {1,0,1,1,0,1,1,1,0,1,1,0,1,1,1,0,1,1,0,1},
            {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
            {1,0,1,1,0,1,0,1,1,1,1,1,1,0,1,0,1,1,0,1},
            {1,0,0,0,0,1,0,0,0,1,1,0,0,0,1,0,0,0,0,1},
            {1,1,1,1,0,1,1,1,0,1,1,0,1,1,1,0,1,1,1,1},
            {0,0,0,1,0,1,0,0,0,0,0,0,0,0,1,0,1,0,0,0},
            {1,1,1,1,0,1,0,1,0,0,0,0,1,0,1,0,1,1,1,1},
            {0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0},
            {1,1,1,1,0,1,0,1,1,1,1,1,1,0,1,0,1,1,1,1},
            {0,0,0,1,0,1,0,0,0,0,0,0,0,0,1,0,1,0,0,0},
            {1,1,1,1,0,1,1,1,0,1,1,0,1,1,1,0,1,1,1,1},
            {1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1},
            {1,0,1,1,0,1,1,1,0,1,1,0,1,1,1,0,1,1,0,1},
            {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
            {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
        }
        
        -- Convert to world coordinates
        self.walls = {}
        for y = 1, #self.maze do
            for x = 1, #self.maze[y] do
                if self.maze[y][x] == 1 then
                    table.insert(self.walls, {
                        x = (x-1) * self.cellSize,
                        y = (y-1) * self.cellSize,
                        w = self.cellSize,
                        h = self.cellSize
                    })
                end
            end
        end
    end
    
    function PacManGame:SpawnPellets()
        self.pellets = {}
        for y = 1, #self.maze do
            for x = 1, #self.maze[y] do
                if self.maze[y][x] == 0 then
                    table.insert(self.pellets, {
                        x = (x-1) * self.cellSize + self.cellSize/2,
                        y = (y-1) * self.cellSize + self.cellSize/2,
                        collected = false
                    })
                end
            end
        end
    end
    
    function PacManGame:SpawnGhosts()
        self.ghosts = {
            {x = 200, y = 200, dir = 0, color = Color(255, 0, 0), speed = 80},
            {x = 300, y = 200, dir = 1, color = Color(255, 192, 203), speed = 80},
            {x = 400, y = 200, dir = 2, color = Color(0, 255, 255), speed = 80},
            {x = 500, y = 200, dir = 3, color = Color(255, 165, 0), speed = 80}
        }
    end
    
    function PacManGame:OnStart()
        self.player.x = 400
        self.player.y = 300
        self.player.dir = 0
        self.player.nextDir = 0
        self:SpawnPellets()
    end
    
    function PacManGame:OnThink(deltaTime)
        self:UpdatePlayer(deltaTime)
        self:UpdateGhosts(deltaTime)
        self:CheckCollisions()
        self:CheckWinCondition()
    end
    
    function PacManGame:UpdatePlayer(deltaTime)
        local dirs = {{1,0}, {0,1}, {-1,0}, {0,-1}} -- right, down, left, up
        
        -- Try to change direction
        if self.player.nextDir ~= self.player.dir then
            local nextX = self.player.x + dirs[self.player.nextDir + 1][1] * self.player.speed * deltaTime
            local nextY = self.player.y + dirs[self.player.nextDir + 1][2] * self.player.speed * deltaTime
            
            if not self:CheckWallCollision(nextX, nextY, 10) then
                self.player.dir = self.player.nextDir
            end
        end
        
        -- Move player
        local newX = self.player.x + dirs[self.player.dir + 1][1] * self.player.speed * deltaTime
        local newY = self.player.y + dirs[self.player.dir + 1][2] * self.player.speed * deltaTime
        
        if not self:CheckWallCollision(newX, newY, 10) then
            self.player.x = newX
            self.player.y = newY
        end
        
        -- Wrap around screen
        if self.player.x < 0 then self.player.x = self.gameWidth end
        if self.player.x > self.gameWidth then self.player.x = 0 end
    end
    
    function PacManGame:UpdateGhosts(deltaTime)
        local dirs = {{1,0}, {0,1}, {-1,0}, {0,-1}}
        
        for _, ghost in ipairs(self.ghosts) do
            -- Simple AI: random direction changes
            if math.random() < 0.02 then
                ghost.dir = math.random(0, 3)
            end
            
            local newX = ghost.x + dirs[ghost.dir + 1][1] * ghost.speed * deltaTime
            local newY = ghost.y + dirs[ghost.dir + 1][2] * ghost.speed * deltaTime
            
            if not self:CheckWallCollision(newX, newY, 10) then
                ghost.x = newX
                ghost.y = newY
            else
                ghost.dir = math.random(0, 3)
            end
            
            -- Wrap around screen
            if ghost.x < 0 then ghost.x = self.gameWidth end
            if ghost.x > self.gameWidth then ghost.x = 0 end
        end
    end
    
    function PacManGame:CheckWallCollision(x, y, radius)
        for _, wall in ipairs(self.walls) do
            if x + radius > wall.x and x - radius < wall.x + wall.w and
               y + radius > wall.y and y - radius < wall.y + wall.h then
                return true
            end
        end
        return false
    end
    
    function PacManGame:CheckCollisions()
        -- Check pellet collection
        for _, pellet in ipairs(self.pellets) do
            if not pellet.collected then
                local dist = math.sqrt((self.player.x - pellet.x)^2 + (self.player.y - pellet.y)^2)
                if dist < 15 then
                    pellet.collected = true
                    self.score = self.score + 10
                end
            end
        end
        
        -- Check ghost collision
        for _, ghost in ipairs(self.ghosts) do
            local dist = math.sqrt((self.player.x - ghost.x)^2 + (self.player.y - ghost.y)^2)
            if dist < 20 then
                self:Stop()
                return
            end
        end
    end
    
    function PacManGame:CheckWinCondition()
        local allCollected = true
        for _, pellet in ipairs(self.pellets) do
            if not pellet.collected then
                allCollected = false
                break
            end
        end
        
        if allCollected then
            self.score = self.score + 1000
            self:SpawnPellets() -- Restart level
        end
    end
    
    function PacManGame:OnPaint(w, h)
        -- Draw walls
        surface.SetDrawColor(0, 0, 255, 255)
        for _, wall in ipairs(self.walls) do
            surface.DrawRect(wall.x, wall.y, wall.w, wall.h)
        end
        
        -- Draw pellets
        surface.SetDrawColor(255, 255, 0, 255)
        for _, pellet in ipairs(self.pellets) do
            if not pellet.collected then
                surface.DrawRect(pellet.x - 2, pellet.y - 2, 4, 4)
            end
        end
        
        -- Draw player
        surface.SetDrawColor(255, 255, 0, 255)
        surface.DrawRect(self.player.x - 10, self.player.y - 10, 20, 20)
        
        -- Draw ghosts
        for _, ghost in ipairs(self.ghosts) do
            surface.SetDrawColor(ghost.color.r, ghost.color.g, ghost.color.b, 255)
            surface.DrawRect(ghost.x - 10, ghost.y - 10, 20, 20)
        end
    end
    
    function PacManGame:OnKeyPress(key)
        if key == KEY_W or key == KEY_UP then
            self.player.nextDir = 3
        elseif key == KEY_S or key == KEY_DOWN then
            self.player.nextDir = 1
        elseif key == KEY_A or key == KEY_LEFT then
            self.player.nextDir = 2
        elseif key == KEY_D or key == KEY_RIGHT then
            self.player.nextDir = 0
        end
    end
    
    -- Register the game
    local pacmanGame = PacManGame:New()
    ArcadeGames.Games["pacman"] = pacmanGame
    
    print("[Arcade Games] Games loaded successfully")
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

-- =============================================
-- CONSOLE COMMAND
-- =============================================

concommand.Add("arcade_open", function()
    if ArcadeGames.Manager then
        ArcadeGames.Manager:OpenMenu()
    else
        print("[Arcade Games] Error: Manager not initialized")
    end
end)

print("[Arcade Games] Standalone version loaded successfully! Use 'arcade_open' to play.")
