-- UI Manager for the arcade system

ArcadeGames.UIManager = {}

function ArcadeGames.UIManager:CreateMainMenu()
    if IsValid(self.mainFrame) then
        self.mainFrame:Remove()
    end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(1000, 700)
    frame:Center()
    frame:SetTitle("Arcade Games")
    frame:SetDeleteOnClose(true)
    frame:MakePopup()
    
    -- Game selection panel
    local gameList = vgui.Create("DScrollPanel", frame)
    gameList:SetPos(10, 30)
    gameList:SetSize(200, frame:GetTall() - 40)
    
    -- Game display panel
    local gamePanel = vgui.Create("DPanel", frame)
    gamePanel:SetPos(220, 30)
    gamePanel:SetSize(frame:GetWide() - 230, frame:GetTall() - 40)
    gamePanel:SetBackgroundColor(Color(50, 50, 50))
    
    -- Populate game list
    for name, game in pairs(ArcadeGames.Games) do
        local gameBtn = vgui.Create("DButton", gameList)
        gameBtn:SetText(game.displayName)
        gameBtn:SetSize(180, 40)
        gameBtn:Dock(TOP)
        gameBtn:DockMargin(5, 5, 5, 0)
        
        gameBtn.DoClick = function()
            self:LoadGame(game, gamePanel)
        end
    end
    
    -- Control instructions
    local controlsPanel = vgui.Create("DPanel", frame)
    controlsPanel:SetPos(220, frame:GetTall() - 80)
    controlsPanel:SetSize(frame:GetWide() - 230, 50)
    controlsPanel:SetBackgroundColor(Color(30, 30, 30))
    
    controlsPanel.Paint = function(self, w, h)
        surface.SetDrawColor(30, 30, 30, 255)
        surface.DrawRect(0, 0, w, h)
        
        draw.SimpleText("Controls: WASD/Arrow Keys to move, SPACE for actions, P to pause, ESC to return to menu", 
                       "DermaDefault", 10, 10, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    self.mainFrame = frame
    self.gamePanel = gamePanel
    self.controlsPanel = controlsPanel
    
    return frame
end

function ArcadeGames.UIManager:LoadGame(game, panel)
    -- Stop current game if running
    if ArcadeGames.ActiveGame then
        ArcadeGames.ActiveGame:Stop()
    end
    
    ArcadeGames.ActiveGame = game
    
    -- Clear panel
    panel:Clear()
    
    -- Create game container
    local gameContainer = vgui.Create("DPanel", panel)
    gameContainer:Dock(FILL)
    gameContainer:SetBackgroundColor(Color(0, 0, 0))
    
    -- Game paint function
    gameContainer.Paint = function(self, w, h)
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
            game:Stop()
            ArcadeGames.ActiveGame = nil
            panel:Clear()
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
    local buttonPanel = vgui.Create("DPanel", panel)
    buttonPanel:SetPos(0, panel:GetTall() - 40)
    buttonPanel:SetSize(panel:GetWide(), 40)
    buttonPanel:SetBackgroundColor(Color(40, 40, 40))
    
    local startBtn = vgui.Create("DButton", buttonPanel)
    startBtn:SetText("Start Game")
    startBtn:SetPos(10, 5)
    startBtn:SetSize(100, 30)
    startBtn.DoClick = function()
        game:Start()
        gameContainer:RequestFocus()
    end
    
    local pauseBtn = vgui.Create("DButton", buttonPanel)
    pauseBtn:SetText("Pause")
    pauseBtn:SetPos(120, 5)
    pauseBtn:SetSize(80, 30)
    pauseBtn.DoClick = function()
        game:Pause()
        gameContainer:RequestFocus()
    end
    
    local stopBtn = vgui.Create("DButton", buttonPanel)
    stopBtn:SetText("Stop")
    stopBtn:SetPos(210, 5)
    stopBtn:SetSize(80, 30)
    stopBtn.DoClick = function()
        game:Stop()
        gameContainer:RequestFocus()
    end
    
    -- Initialize game
    game:Initialize()
end
