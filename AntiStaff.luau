-- AntiStaff.luau
-- staff detector

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Staff usernames
local STAFF = {
    ["LittleEczi"] = true,
    ["Welaas"] = true,
    ["lettersinthefire"] = true,
    ["milamybotak"] = true,
    ["s0umadethis"] = true,
    ["whosvqr"] = true
}

-- Alert settings
local SOUND_ID = "rbxassetid://18980441222"
local ALERT_DURATION = 5

-- Keeps track of staff currently detected
local detectedStaff = {}

-- Notification stack
local notifications = {}

--------------------------------------------------
-- SOUND
--------------------------------------------------

local bombSound = Instance.new("Sound")
bombSound.Name = "AntiStaffBombSound"
bombSound.SoundId = SOUND_ID
bombSound.Volume = 0.5
bombSound.Parent = SoundService

--------------------------------------------------
-- STAFF CHECK
--------------------------------------------------

local function isStaff(player)
    return STAFF[player.Name] == true
end

--------------------------------------------------
-- PERMANENT RED HIGHLIGHT
--------------------------------------------------

local function highlightStaff(player)
    if not player.Character then
        return
    end

    local character = player.Character

    -- Remove an old copy if one exists
    local oldHighlight = character:FindFirstChild("AntiStaffHighlight")

    if oldHighlight then
        oldHighlight:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "AntiStaffHighlight"

    -- Red
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)

    -- Visibility
    highlight.FillTransparency = 0.35
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    -- Highlight the entire character
    highlight.Adornee = character
    highlight.Parent = character
end

--------------------------------------------------
-- NOTIFICATION STACK
--------------------------------------------------

local notificationContainer

local function getNotificationContainer()
    if notificationContainer and notificationContainer.Parent then
        return notificationContainer
    end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    notificationContainer = Instance.new("ScreenGui")
    notificationContainer.Name = "AntiStaffNotifications"
    notificationContainer.ResetOnSpawn = false
    notificationContainer.IgnoreGuiInset = true
    notificationContainer.Parent = playerGui

    return notificationContainer
end

local function repositionNotifications()
    for index, notification in ipairs(notifications) do
        if notification and notification.Parent then
            local targetPosition = UDim2.new(
                1,
                -20,
                1,
                -20 - ((index - 1) * 70)
            )

            TweenService:Create(
                notification,
                TweenInfo.new(
                    0.25,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ),
                {
                    Position = targetPosition
                }
            ):Play()
        end
    end
end

local function showNotification(playerName)
    local gui = getNotificationContainer()

    local frame = Instance.new("Frame")
    frame.Name = "StaffNotification"
    frame.Size = UDim2.new(0, 320, 0, 55)

    -- Start slightly off-screen
    frame.Position = UDim2.new(1, 340, 1, -20)

    frame.AnchorPoint = Vector2.new(1, 1)

    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0

    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 0, 0)
    stroke.Thickness = 2
    stroke.Parent = frame

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -20, 1, 0)
    text.Position = UDim2.new(0, 10, 0, 0)

    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(255, 255, 255)

    text.Text = playerName .. " has joined the server."

    text.TextSize = 18
    text.Font = Enum.Font.GothamBold
    text.TextXAlignment = Enum.TextXAlignment.Left

    text.Parent = frame

    -- Add to stack
    table.insert(notifications, 1, frame)

    -- Move existing notifications upward
    repositionNotifications()

    -- Slide this notification in
    TweenService:Create(
        frame,
        TweenInfo.new(
            0.35,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out
        ),
        {
            Position = UDim2.new(
                1,
                -20,
                1,
                -20
            )
        }
    ):Play()

    -- Remove after 5 seconds
    task.delay(ALERT_DURATION, function()
        if not frame.Parent then
            return
        end

        local fade = TweenService:Create(
            frame,
            TweenInfo.new(
                0.4,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.In
            ),
            {
                BackgroundTransparency = 1,
                Position = UDim2.new(
                    1,
                    340,
                    1,
                    frame.Position.Y.Offset
                )
            }
        )

        fade:Play()

        fade.Completed:Wait()

        -- Remove from notification list
        for i, notification in ipairs(notifications) do
            if notification == frame then
                table.remove(notifications, i)
                break
            end
        end

        frame:Destroy()

        -- Pull remaining notifications down
        repositionNotifications()
    end)
end

--------------------------------------------------
-- BOMB ALERT
--------------------------------------------------

local function playBombAlert()
    -- Stop any previous playback so every detection
    -- starts a fresh 5-second alert.
    bombSound:Stop()
    bombSound.TimePosition = 0
    bombSound:Play()

    task.delay(ALERT_DURATION, function()
        if bombSound.IsPlaying then
            bombSound:Stop()
        end
    end)
end

--------------------------------------------------
-- STAFF ALERT
--------------------------------------------------

local function alertStaff(player)
    if not isStaff(player) then
        return
    end

    -- Highlight immediately
    highlightStaff(player)

    -- Bomb alert
    playBombAlert()

    -- Bottom-right notification
    showNotification(player.Name)
end

--------------------------------------------------
-- CHARACTER HANDLING
--------------------------------------------------

local function monitorCharacter(player)
    if not isStaff(player) then
        return
    end

    player.CharacterAdded:Connect(function(character)
        -- Wait until the character is properly available
        character:WaitForChild("Humanoid", 10)

        task.wait(0.1)

        -- Reapply permanent highlight after respawn
        if player.Parent == Players then
            highlightStaff(player)
        end
    end)

    -- Highlight their current character
    if player.Character then
        task.spawn(function()
            highlightStaff(player)
        end)
    end
end

--------------------------------------------------
-- PLAYER JOIN
--------------------------------------------------

Players.PlayerAdded:Connect(function(player)
    if not isStaff(player) then
        return
    end

    -- New/rejoining staff member
    detectedStaff[player.UserId] = true

    monitorCharacter(player)

    -- Give Roblox a moment to establish the player
    task.spawn(function()
        task.wait(0.1)

        if player.Parent == Players then
            alertStaff(player)
        end
    end)
end)

--------------------------------------------------
-- PLAYER LEAVE
--------------------------------------------------

Players.PlayerRemoving:Connect(function(player)
    if isStaff(player) then
        -- Remove their detection state.
        -- This is important because if they rejoin,
        -- they will receive another alert.
        detectedStaff[player.UserId] = nil
    end
end)

--------------------------------------------------
-- DETECT STAFF ALREADY IN SERVER
--------------------------------------------------

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and isStaff(player) then
        detectedStaff[player.UserId] = true

        monitorCharacter(player)

        -- Alert staff who were already here
        task.spawn(function()
            task.wait(0.1)

            if player.Parent == Players then
                alertStaff(player)
            end
        end)
    end
end
