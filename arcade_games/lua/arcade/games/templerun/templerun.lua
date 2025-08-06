-- Temple Run Game Implementation

local TempleRunGame = {}
setmetatable(TempleRunGame, {__index = ArcadeGames.GameBase})

function TempleRunGame:New()
    local game = ArcadeGames.GameBase:New("templerun", "Temple Run")
    setmetatable(game, {__index = self})
    
    -- Game specific properties
    game.player = {
        x = 400, -- Center lane
        y = 500, -- Ground level
        lane = 1, -- 0=left, 1=center, 2=right
        jumping = false,
        sliding = false,
        jumpVelocity = 0,
        size = 30
    }
    
    game.obstacles = {}
    game.coins = {}
    game.lanes = {300, 400, 500} -- X positions for lanes
    game.speed = 300
    game.distance = 0
    game.jumpForce = -400
    game.gravity = 1200
    game.groundY = 500
    game.nextObstacle = 600
    game.nextCoin = 400
    
    return game
end

function TempleRunGame:OnStart()
    self.player.x = self.lanes[2]
    self.player.y = self.groundY
    self.player.lane = 1
    self.player.jumping = false
    self.player.sliding = false
    self.player.jumpVelocity = 0
    self.obstacles = {}
    self.coins = {}
    self.distance = 0
    self.speed = 300
    self.nextObstacle = 600
    self.nextCoin = 400
end

function TempleRunGame:OnThink(deltaTime)
    -- Increase speed over time
    self.speed = self.speed + deltaTime * 10
    self.distance = self.distance + self.speed * deltaTime
    self.score = math.floor(self.distance / 10)
    
    -- Update player physics
    self:UpdatePlayer(deltaTime)
    
    -- Spawn obstacles
    if self.nextObstacle <= self.gameHeight then
        self:SpawnObstacle()
        self.nextObstacle = self.nextObstacle + math.random(200, 400)
    end
    
    -- Spawn coins
    if self.nextCoin <= self.gameHeight then
        self:SpawnCoin()
        self.nextCoin = self.nextCoin + math.random(150, 300)
    end
    
    -- Update obstacles
    for i = #self.obstacles, 1, -1 do
        local obstacle = self.obstacles[i]
        obstacle.y = obstacle.y + self.speed * deltaTime
        
        -- Remove off-screen obstacles
        if obstacle.y > self.gameHeight + 50 then
            table.remove(self.obstacles, i)
        elseif self:CheckObstacleCollision(obstacle) then
            self:Stop()
            return
        end
    end
    
    -- Update coins
    for i = #self.coins, 1, -1 do
        local coin = self.coins[i]
        coin.y = coin.y + self.speed * deltaTime
        
        -- Remove off-screen coins
        if coin.y > self.gameHeight + 50 then
            table.remove(self.coins, i)
        elseif self:CheckCoinCollection(coin) then
            table.remove(self.coins, i)
            self.score = self.score + 10
        end
    end
    
    -- Reset spawn positions
    self.nextObstacle = self.nextObstacle - self.speed * deltaTime
    self.nextCoin = self.nextCoin - self.speed * deltaTime
end

function TempleRunGame:UpdatePlayer(deltaTime)
    -- Handle jumping
    if self.player.jumping then
        self.player.jumpVelocity = self.player.jumpVelocity + self.gravity * deltaTime
        self.player.y = self.player.y + self.player.jumpVelocity * deltaTime
        
        -- Land on ground
        if self.player.y >= self.groundY then
            self.player.y = self.groundY
            self.player.jumping = false
            self.player.jumpVelocity = 0
        end
    end
    
    -- Handle sliding timer
    if self.player.sliding then
        self.player.slideTimer = (self.player.slideTimer or 0) + deltaTime
        if self.player.slideTimer > 0.8 then
            self.player.sliding = false
            self.player.slideTimer = 0
        end
    end
    
    -- Smooth lane transitions
    local targetX = self.lanes[self.player.lane + 1]
    if self.player.x ~= targetX then
        local diff = targetX - self.player.x
        local moveSpeed = 800 * deltaTime
        if math.abs(diff) < moveSpeed then
            self.player.x = targetX
        else
            self.player.x = self.player.x + (diff > 0 and moveSpeed or -moveSpeed)
        end
    end
end

function TempleRunGame:SpawnObstacle()
    local lane = math.random(0, 2)
    local obstacleType = math.random(1, 3) -- 1=low, 2=high, 3=wide
    
    table.insert(self.obstacles, {
        x = self.lanes[lane + 1],
        y = -50,
        lane = lane,
        type = obstacleType,
        width = obstacleType == 3 and 60 or 30,
        height = obstacleType == 2 and 60 or 30
    })
end

function TempleRunGame:SpawnCoin()
    local lane = math.random(0, 2)
    table.insert(self.coins, {
        x = self.lanes[lane + 1],
        y = -30,
        lane = lane,
        size = 15
    })
end

function TempleRunGame:CheckObstacleCollision(obstacle)
    local playerLeft = self.player.x - self.player.size/2
    local playerRight = self.player.x + self.player.size/2
    local playerTop = self.player.y - self.player.size/2
    local playerBottom = self.player.y + self.player.size/2
    
    local obsLeft = obstacle.x - obstacle.width/2
    local obsRight = obstacle.x + obstacle.width/2
    local obsTop = obstacle.y - obstacle.height/2
    local obsBottom = obstacle.y + obstacle.height/2
    
    -- Check if player can avoid obstacle
    if obstacle.type == 1 and self.player.sliding then
        return false -- Can slide under low obstacles
    elseif obstacle.type == 2 and self.player.jumping then
        return false -- Can jump over high obstacles
    end
    
    -- Check collision
    if playerRight > obsLeft and playerLeft < obsRight and
       playerBottom > obsTop and playerTop < obsBottom then
        return true
    end
    
    return false
end

function TempleRunGame:CheckCoinCollection(coin)
    local dist = math.sqrt((self.player.x - coin.x)^2 + (self.player.y - coin.y)^2)
    return dist < 25
end

function TempleRunGame:OnPaint(w, h)
    -- Draw background (moving ground effect)
    surface.SetDrawColor(139, 69, 19, 255) -- Brown ground
    surface.DrawRect(0, 0, w, h)
    
    -- Draw lane lines
    surface.SetDrawColor(101, 67, 33, 255) -- Darker brown
    for i = 1, 2 do
        local lineX = (self.lanes[i] + self.lanes[i+1]) / 2
        surface.DrawRect(lineX - 2, 0, 4, h)
    end
    
    -- Draw obstacles
    for _, obstacle in ipairs(self.obstacles) do
        if obstacle.type == 1 then
            surface.SetDrawColor(160, 82, 45, 255) -- Saddle brown (low obstacle)
        elseif obstacle.type == 2 then
            surface.SetDrawColor(105, 105, 105, 255) -- Dim gray (high obstacle)
        else
            surface.SetDrawColor(128, 0, 0, 255) -- Maroon (wide obstacle)
        end
        
        surface.DrawRect(
            obstacle.x - obstacle.width/2,
            obstacle.y - obstacle.height/2,
            obstacle.width,
            obstacle.height
        )
    end
    
    -- Draw coins
    surface.SetDrawColor(255, 215, 0, 255) -- Gold
    for _, coin in ipairs(self.coins) do
        surface.DrawRect(
            coin.x - coin.size/2,
            coin.y - coin.size/2,
            coin.size,
            coin.size
        )
    end
    
    -- Draw player
    local playerColor = Color(0, 100, 200, 255) -- Blue runner
    if self.player.sliding then
        playerColor = Color(0, 150, 0, 255) -- Green when sliding
    elseif self.player.jumping then
        playerColor = Color(200, 100, 0, 255) -- Orange when jumping
    end
    
    surface.SetDrawColor(playerColor.r, playerColor.g, playerColor.b, 255)
    local playerHeight = self.player.sliding and self.player.size/2 or self.player.size
    surface.DrawRect(
        self.player.x - self.player.size/2,
        self.player.y - playerHeight/2,
        self.player.size,
        playerHeight
    )
    
    -- Draw speed indicator
    draw.SimpleText("Speed: " .. math.floor(self.speed), "DermaDefault", 10, 70, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Distance: " .. math.floor(self.distance), "DermaDefault", 10, 90, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function TempleRunGame:OnKeyPress(key)
    if key == KEY_A or key == KEY_LEFT then
        -- Move left
        if self.player.lane > 0 then
            self.player.lane = self.player.lane - 1
        end
    elseif key == KEY_D or key == KEY_RIGHT then
        -- Move right
        if self.player.lane < 2 then
            self.player.lane = self.player.lane + 1
        end
    elseif key == KEY_W or key == KEY_UP or key == KEY_SPACE then
        -- Jump
        if not self.player.jumping and not self.player.sliding then
            self.player.jumping = true
            self.player.jumpVelocity = self.jumpForce
        end
    elseif key == KEY_S or key == KEY_DOWN then
        -- Slide
        if not self.player.jumping and not self.player.sliding then
            self.player.sliding = true
            self.player.slideTimer = 0
        end
    end
end

-- Register the game
local templeRunGame = TempleRunGame:New()
ArcadeGames.Manager:RegisterGame(templeRunGame)
