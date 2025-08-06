-- Updated Flappy Bird game implementation
local FlappyBirdGame = {}
setmetatable(FlappyBirdGame, {__index = ArcadeGames.GameBase})

function FlappyBirdGame:New()
    local game = ArcadeGames.GameBase:New("flappybird", "Flappy Bird")
    setmetatable(game, {__index = self})
    
    -- Load materials with error handling
    game.materials = {
        bird = Material("arcade/flappybird/bird"),
        pipe = Material("arcade/flappybird/pipe"),
        background = Material("arcade/flappybird/background")
    }
    
    -- Check if materials loaded properly
    game.useTextures = true
    for name, mat in pairs(game.materials) do
        if mat:IsError() then
            game.useTextures = false
            print("[Arcade Games] Warning: Material " .. name .. " not found for Flappy Bird")
        end
    end
    
    -- Game specific properties
    game.bird = {
        x = 100,                -- Bird's horizontal position
        y = 300,                -- Bird's vertical position
        velocity = 0,           -- Current vertical velocity
        size = 40,              -- Bird sprite size
        rotation = 0,           -- Current rotation angle
        flapStrength = 0,       -- Visual flap animation strength
        flapTime = 0,           -- Time tracking for flap animation
        flapDuration = 0.3,     -- How long a flap animation lasts
        hitbox = 14             -- Smaller hitbox than visual size for more forgiving gameplay
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
    
    -- Game state
    game.gameStarted = false    -- Whether actual gameplay has started
    game.tutorialMode = true    -- Show tutorial on first load
    game.deathAnimation = false -- Death animation playing
    game.deathTimer = 0         -- Time tracking for death animation
    game.difficultyLevel = 1    -- Current difficulty level
    game.difficultyTimer = 0    -- Timer for increasing difficulty
    
    -- Performance optimization
    game.lastFrameTime = 0      -- For frame time smoothing
    game.frameTimeHistory = {}  -- Store recent frame times for smoothing
    
    return game
end

function FlappyBirdGame:Initialize()
    -- Reset game state
    self.gameStarted = false
    self.tutorialMode = true
    self.deathAnimation = false
    self.difficultyLevel = 1
    
    -- Precompute some values for performance
    self.bgWidth = self.gameWidth * 1.5
    self.groundY = self.gameHeight - self.groundHeight
end

function FlappyBirdGame:OnStart()
    -- Reset game state
    self.bird.y = 300
    self.bird.velocity = 0
    self.bird.rotation = 0
    self.pipes = {}
    self.nextPipeX = self.gameWidth + 100
    self.gameStarted = true
    self.tutorialMode = false
    self.deathAnimation = false
    self.difficultyLevel = 1
    self.difficultyTimer = 0
    self.score = 0
    
    -- Reset scrolling positions
    self.bgScroll = 0
    self.groundScroll = 0
    
    -- Add initial pipes
    self:SpawnPipe()
end

function FlappyBirdGame:OnThink(deltaTime)
    -- Smooth deltaTime to prevent physics glitches on lag spikes
    table.insert(self.frameTimeHistory, deltaTime)
    if #self.frameTimeHistory > 10 then
        table.remove(self.frameTimeHistory, 1)
    end
    
    local smoothDeltaTime = 0
    for _, dt in ipairs(self.frameTimeHistory) do
        smoothDeltaTime = smoothDeltaTime + dt
    end
    smoothDeltaTime = smoothDeltaTime / #self.frameTimeHistory
    
    -- Cap deltaTime to prevent physics glitches
    smoothDeltaTime = math.min(smoothDeltaTime, 0.05)
    
    -- Tutorial mode - bird just hovers
    if self.tutorialMode then
        self.bird.y = 300 + math.sin(CurTime() * 2) * 20
        self.bgScroll = (self.bgScroll + self.bgScrollSpeed * smoothDeltaTime) % self.bgWidth
        self.groundScroll = (self.groundScroll + self.pipeSpeed * smoothDeltaTime) % self.gameWidth
        return
    end
    
    -- Death animation
    if self.deathAnimation then
        self.deathTimer = self.deathTimer + smoothDeltaTime
        self.bird.velocity = self.bird.velocity + self.gravity * smoothDeltaTime
        self.bird.y = self.bird.y + self.bird.velocity * smoothDeltaTime
        self.bird.rotation = math.min(90, self.bird.rotation + 300 * smoothDeltaTime)
        
        -- End death animation when bird hits ground
        if self.bird.y > self.groundY - self.bird.size/2 then
            self.bird.y = self.groundY - self.bird.size/2
            
            -- Wait a moment then end the game
            if self.deathTimer > 1.5 then
                self:Stop()
            end
        end
        return
    end
    
    -- Update bird physics
    self.bird.velocity = self.bird.velocity + self.gravity * smoothDeltaTime
    self.bird.velocity = math.min(self.bird.velocity, self.terminalVelocity)
    self.bird.y = self.bird.y + self.bird.velocity * smoothDeltaTime
    
    -- Update bird rotation based on velocity
    local targetRotation = math.Clamp(self.bird.velocity * 0.1, -30, 90)
    self.bird.rotation = self.bird.rotation + (targetRotation - self.bird.rotation) * 5 * smoothDeltaTime
    
    -- Update flap animation
    if self.bird.flapTime > 0 then
        self.bird.flapTime = self.bird.flapTime - smoothDeltaTime
        self.bird.flapStrength = math.max(0, self.bird.flapTime / self.bird.flapDuration)
    end
    
    -- Check ground/ceiling collision
    if self.bird.y > self.groundY - self.bird.hitbox or self.bird.y < self.bird.hitbox then
        self:StartDeathAnimation()
        return
    end
    
    -- Increase difficulty over time
    self.difficultyTimer = self.difficultyTimer + smoothDeltaTime
    if self.difficultyTimer > 10 and self.difficultyLevel < 5 then
        self.difficultyLevel = self.difficultyLevel + 1
        self.difficultyTimer = 0
        self.pipeSpeed = self.pipeSpeed + 20
        self.pipeGap = math.max(120, self.pipeGap - 10)
    end
    
    -- Spawn pipes
    if self.nextPipeX <= self.gameWidth then
        self:SpawnPipe()
    end
    
    -- Update pipes
    for i = #self.pipes, 1, -1 do
        local pipe = self.pipes[i]
        pipe.x = pipe.x - self.pipeSpeed * smoothDeltaTime
        
        -- Check if bird passed pipe
        if not pipe.passed and pipe.x + self.pipeWidth < self.bird.x then
            pipe.passed = true
            self.score = self.score + 1
            -- Play score sound here if you add sounds
        end
        
        -- Remove off-screen pipes
        if pipe.x + self.pipeWidth < 0 then
            table.remove(self.pipes, i)
        end
        
        -- Check collision
        if self:CheckPipeCollision(pipe) then
            self:StartDeathAnimation()
            return
        end
    end
    
    -- Update scrolling backgrounds
    self.bgScroll = (self.bgScroll + self.bgScrollSpeed * smoothDeltaTime) % self.bgWidth
    self.groundScroll = (self.groundScroll + self.pipeSpeed * smoothDeltaTime) % self.gameWidth
    
    -- Reset pipe spawning when needed
    self.nextPipeX = self.nextPipeX - self.pipeSpeed * smoothDeltaTime
end

function FlappyBirdGame:SpawnPipe()
    -- Calculate gap position based on difficulty
    local minGapY = 100 + (5 - self.difficultyLevel) * 10
    local maxGapY = self.groundY - 100 - self.pipeGap - (5 - self.difficultyLevel) * 10
    local gapY = math.random(minGapY, maxGapY)
    
    table.insert(self.pipes, {
        x = self.gameWidth,
        gapY = gapY,
        passed = false
    })
    
    self.nextPipeX = self.gameWidth + self.pipeSpacing
end

function FlappyBirdGame:CheckPipeCollision(pipe)
    -- Use smaller hitbox than visual size for more forgiving gameplay
    local birdLeft = self.bird.x - self.bird.hitbox
    local birdRight = self.bird.x + self.bird.hitbox
    local birdTop = self.bird.y - self.bird.hitbox
    local birdBottom = self.bird.y + self.bird.hitbox
    
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

function FlappyBirdGame:StartDeathAnimation()
    self.deathAnimation = true
    self.deathTimer = 0
    -- Play death sound here if you add sounds
end

function FlappyBirdGame:OnPaint(w, h)
    -- Draw sky background
    if self.useTextures and not self.materials.background:IsError() then
        surface.SetMaterial(self.materials.background)
        surface.SetDrawColor(255, 255, 255, 255)
        
        -- Draw scrolling background
        local bgScale = h / 384 -- Assuming background is 384px tall
        local scaledWidth = 512 * bgScale -- Assuming background is 512px wide
        
        -- Draw multiple copies to fill the screen with parallax scrolling
        for i = 0, math.ceil(w / scaledWidth) + 1 do
            local xPos = i * scaledWidth - (self.bgScroll * bgScale) % scaledWidth
            surface.DrawTexturedRect(xPos, 0, scaledWidth, h - self.groundHeight)
        end
    else
        -- Fallback to color
        surface.SetDrawColor(135, 206, 235, 255) -- Sky blue
        surface.DrawRect(0, 0, w, h - self.groundHeight)
    end
    
    -- Draw pipes
    for _, pipe in ipairs(self.pipes) do
        if self.useTextures and not self.materials.pipe:IsError() then
            surface.SetMaterial(self.materials.pipe)
            surface.SetDrawColor(255, 255, 255, 255)
            
            -- Top pipe (flipped)
            surface.DrawTexturedRectUV(
                pipe.x, 0, 
                self.pipeWidth, pipe.gapY,
                0, 1, 1, 0 -- Flip UV coordinates
            )
            
            -- Bottom pipe
            surface.DrawTexturedRect(
                pipe.x, 
                pipe.gapY + self.pipeGap, 
                self.pipeWidth, 
                h - (pipe.gapY + self.pipeGap)
            )
        else
            -- Fallback to colored rectangles
            surface.SetDrawColor(0, 128, 0, 255) -- Green
            
            -- Top pipe
            surface.DrawRect(pipe.x, 0, self.pipeWidth, pipe.gapY)
            
            -- Bottom pipe
            surface.DrawRect(
                pipe.x, 
                pipe.gapY + self.pipeGap, 
                self.pipeWidth, 
                h - (pipe.gapY + self.pipeGap)
            )
        end
    end
    
    -- Draw ground
    surface.SetDrawColor(222, 184, 135, 255) -- Sandy brown
    surface.DrawRect(0, h - self.groundHeight, w, self.groundHeight)
    
    -- Draw ground detail lines for scrolling effect
    surface.SetDrawColor(205, 170, 125, 255) -- Darker sand
    for i = 0, math.ceil(w / 20) + 1 do
        local xPos = (i * 20 - self.groundScroll % 20)
        surface.DrawRect(xPos, h - self.groundHeight + 5, 10, 2)
    end
    
    -- Draw bird
    if self.useTextures and not self.materials.bird:IsError() then
        surface.SetMaterial(self.materials.bird)
        surface.SetDrawColor(255, 255, 255, 255)
        
        -- Save the current render state
        local mat = Matrix()
        mat:Translate(Vector(self.bird.x, self.bird.y, 0))
        mat:Rotate(Angle(0, 0, self.bird.rotation))
        
        -- Apply "flap" effect by scaling vertically
        local flapScale = 1 + self.bird.flapStrength * 0.2
        mat:Scale(Vector(1, flapScale, 1))
        
        mat:Translate(Vector(-self.bird.size/2, -self.bird.size/2, 0))
        
        cam.PushModelMatrix(mat)
        surface.DrawTexturedRect(0, 0, self.bird.size, self.bird.size)
        cam.PopModelMatrix()
    else
        -- Fallback to colored rectangle
        surface.SetDrawColor(255, 255, 0, 255) -- Yellow
        
        -- Save the current render state
        local mat = Matrix()
        mat:Translate(Vector(self.bird.x, self.bird.y, 0))
        mat:Rotate(Angle(0, 0, self.bird.rotation))
        mat:Translate(Vector(-self.bird.size/2, -self.bird.size/2, 0))
        
        cam.PushModelMatrix(mat)
        surface.DrawRect(0, 0, self.bird.size, self.bird.size)
        
        -- Draw eye
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(self.bird.size * 0.7, self.bird.size * 0.3, 5, 5)
        
        -- Draw beak
        surface.SetDrawColor(255, 165, 0, 255) -- Orange
        surface.DrawRect(self.bird.size * 0.8, self.bird.size * 0.5, 15, 8)
        
        cam.PopModelMatrix()
    end
    
    -- Draw tutorial if in tutorial mode
    if self.tutorialMode then
        -- Semi-transparent overlay
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(0, 0, w, h)
        
        -- Instructions
        draw.SimpleText("FLAPPY BIRD", "DermaLarge", w/2, h/4, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Press SPACE or LEFT CLICK to flap", "DermaDefault", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Avoid pipes and don't hit the ground", "DermaDefault", w/2, h/2 + 30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Press SPACE to start", "DermaLarge", w/2, h*3/4, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Draw "Game Over" if in death animation and bird has hit ground
    if self.deathAnimation and self.bird.y >= self.groundY - self.bird.size/2 then
        draw.SimpleText("GAME OVER", "DermaLarge", w/2, h/3, Color(255, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Score: " .. self.score, "DermaLarge", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        if self.score > self.highScore then
            draw.SimpleText("NEW HIGH SCORE!", "DermaDefault", w/2, h/2 + 40, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

function FlappyBirdGame:OnKeyPress(key)
    if key == KEY_SPACE or key == KEY_W or key == KEY_UP then
        if self.tutorialMode then
            self:OnStart()
        elseif self.gameStarted and not self.deathAnimation then
            self:Flap()
        end
    end
end

function FlappyBirdGame:OnMousePress(mouseCode, x, y)
    if mouseCode == MOUSE_LEFT then
        if self.tutorialMode then
            self:OnStart()
        elseif self.gameStarted and not self.deathAnimation then
            self:Flap()
        end
    end
end

function FlappyBirdGame:Flap()
    self.bird.velocity = self.jumpForce
    self.bird.flapTime = self.bird.flapDuration
    self.bird.flapStrength = 1
    -- Play flap sound here if you add sounds
end

-- Register the game
local flappyBirdGame = FlappyBirdGame:New()
ArcadeGames.Games["flappybird"] = flappyBirdGame
