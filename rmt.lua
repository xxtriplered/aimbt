-- -----------------------------------
--  ___      _   _   _              --
-- / __| ___| |_| |_(_)_ _  __ _ ___--
-- \__ \/ -_)  _|  _| | ' \/ _` (_-<--
-- |___/\___|\__|\__|_|_||_\__, /__/--
--                         |___/    --
-- -----------------------------------
-- -----------------------------------
ALLYCOLOR = {0, 255, 255}     -- Color of the ESP of people on the same team
ENEMYCOLOR = {255, 0, 0}     -- Color of the ESP of people NOT on the same team
TRANSPARENCY = 0.5          -- Transparency of the ESP
HEALTHBAR_ACTIVATED = true  -- Renders the Healthbar

-- Aimbot Variables
local aimbotEnabled = true -- Set this to enable or disable the aimbot
local aimbotTeamCheck = true -- Set this to enable or disable checking for teammates
local aimbotKey = Enum.KeyCode.V -- The key that activates the aimbot

-- -----------------------------------

function createFlex()
    -- -----------------------------------------------------------------------------------
    -- [VARIABLES] // Changing may result in Errors!
    players = game:GetService("Players") -- Required for PF
    faces = {"Front", "Back", "Bottom", "Left", "Right", "Top"} -- Every possible Enum face
    currentPlayer = nil -- Used for the Team-Check
    lplayer = players.LocalPlayer -- The LocalPlayer
    -- -----------------------------------------------------------------------------------
    players.PlayerAdded:Connect(function(p)
        currentPlayer = p
        p.CharacterAdded:Connect(function(character) -- For when a new Player joins the game
            createESP(character)
        end)
    end)
    -- -----------------------------------------------------------------------------------
    function checkPart(obj)
        if (obj:IsA("Part") or obj:IsA("MeshPart")) and obj.Name ~= "HumanoidRootPart" then
            return true
        end
    end
    -- -----------------------------------------------------------------------------------
    function actualESP(obj)
        local box = Instance.new("BoxHandleAdornment")
        box.Size = obj.Size + Vector3.new(0.1, 0.1, 0.1)
        box.Transparency = TRANSPARENCY
        box.Adornee = obj
        box.AlwaysOnTop = true
        if currentPlayer.Team == players.LocalPlayer.Team then
            box.Color3 = Color3.new(ALLYCOLOR[1], ALLYCOLOR[2], ALLYCOLOR[3])
        else
            box.Color3 = Color3.new(ENEMYCOLOR[1], ENEMYCOLOR[2], ENEMYCOLOR[3])
        end
        box.Parent = obj

        for i = 0, 5 do
            surface = Instance.new("SurfaceGui", obj) -- Creates the SurfaceGui
            surface.Face = Enum.NormalId[faces[i + 1]] -- Adjusts the Face and chooses from the face table
            surface.AlwaysOnTop = true

            frame = Instance.new("Frame", surface) -- Creates the viewable Frame
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BorderSizePixel = 0
            frame.BackgroundTransparency = TRANSPARENCY
            if currentPlayer.Team == players.LocalPlayer.Team then -- Checks the Players Team
                frame.BackgroundColor3 = Color3.new(ALLYCOLOR[1], ALLYCOLOR[2], ALLYCOLOR[3]) -- If in the same Team
            else
                frame.BackgroundColor3 = Color3.new(ENEMYCOLOR[1], ENEMYCOLOR[2], ENEMYCOLOR[3]) -- If not in the same Team
            end
        end

        if HEALTHBAR_ACTIVATED then
            local humanoid = obj.Parent:FindFirstChild("Humanoid")
            if humanoid then
                local healthbar = Instance.new("BillboardGui")
                healthbar.Size = UDim2.new(3, 0, 0.2, 0)
                healthbar.Adornee = obj
                healthbar.Parent = obj.Parent

                local healthframe = Instance.new("Frame")
                healthframe.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
                healthframe.BackgroundColor3 = Color3.new(0, 1, 0)
                healthframe.Parent = healthbar

                humanoid.HealthChanged:Connect(function()
                    healthframe.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
                end)
            end
        end
    end
    -- -----------------------------------------------------------------------------------
    function createESP(character)
        if aimbotEnabled and aimbotTeamCheck and character:FindFirstChild("Humanoid") and currentPlayer.Team == players.LocalPlayer.Team then
            return
        end

        if character:FindFirstChild("Head") then -- Checks if there is a Head
            actualESP(character.Head) -- Runs the actual function
        end

        for _, obj in pairs(character:GetChildren()) do
            if checkPart(obj) then
                actualESP(obj)
            elseif obj:IsA("Folder") or obj:IsA("Accoutrement") then
                for _, obj2 in pairs(obj:GetDescendants()) do
                    if checkPart(obj2) then
                        actualESP(obj2)
                    end
                end
            end
        end
    end
    -- -----------------------------------------------------------------------------------
    for _, plr in pairs(players:GetPlayers()) do -- Gets all Players in the Game
        currentPlayer = plr
        if plr.Character then -- Finds their Character
            createESP(plr.Character)
        end
        plr.CharacterAdded:Connect(function(char) -- For when a new Player joins the game
            createESP(char)
        end)
    end
end

-- Create ESP
createFlex()

-- Aimbot
local mousemoverel = function(x, y)
    mousemoverel(x, y)
end

assert(mousemoverel, "missing dependency: mousemoverel")

-- Services
local inputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")

-- Variables
local camera = workspace.CurrentCamera
local wtvp = camera.WorldToViewportPoint
local localPlayer = players.LocalPlayer
local mousePos = inputService.GetMouseLocation
local isPressed = inputService.IsMouseButtonPressed
local curve = { player = nil, i = 0 }

-- Locals
local newVector2 = Vector2.new
local clamp = math.clamp

-- Functions
local function getClosest()
    local closest, player, position = math.huge, nil, nil
    for _, p in next, players:GetPlayers() do
        local character = p.Character
        if character and p.Team ~= localPlayer.Team then
            local pos, visible = wtvp(camera, character.Head.Position)
            pos = newVector2(pos.X, pos.Y)

            local magnitude = (pos - mousePos(inputService)).Magnitude
            if magnitude < closest and visible then
                closest = magnitude
                player = p
                position = pos
            end
        end
    end
    return player, position
end

local function quadBezier(t, p0, p1, o0)
    return (1 - t)^2 * p0 + 2 * (1 - t) * t * (p0 + (p1 - p0) * o0) + t^2 * p1
end

-- Connections
runService.Heartbeat:Connect(function(deltaTime)
    if aimbotEnabled and isPressed(inputService, aimbotKey) then
        local player, screen = getClosest()
        if player and screen then
            if curve.player ~= player then
                curve.player = player
                curve.i = 0
            end

            local mouse = mousePos(inputService)
            local delta = quadBezier(curve.i, mouse, screen, newVector2(0.5, 0)) - mouse
            mousemoverel(delta.X, delta.Y)

            curve.i = clamp(curve.i + deltaTime * 1.5, 0, 1)
        end
    else
        curve.player = nil
        curve.i = 0
    end
end)
