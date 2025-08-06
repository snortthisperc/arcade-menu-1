-- Pac-Man Game Implementation

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
ArcadeGames.Manager:RegisterGame(pacmanGame)
