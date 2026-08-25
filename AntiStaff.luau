-- AntiStaff.luau
-- Anti Staff Detector

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- STAFF LIST
--------------------------------------------------

local STAFF = {
    ["LittleEczi"] = true,
    ["Welaas"] = true,
    ["lettersinthefire"] = true,
    ["milamybotak"] = true,
    ["s0umadethis"] = true,
    ["whosvqr"] = true
}

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local SOUND_ID = "rbxassetid://18980441222"
local ALERT_DURATION = 5

--------------------------------------------------
-- SOUND
--------------------------------------------------

local bombSound = Instance.new("Sound")
bombSound.Name = "AntiStaffBombSound"
bombSound.SoundId = SOUND_ID
bombSound.Volume = 0.3
bombSound.Parent = SoundService

--------------------------------------------------
-- NOTIFICATION GUI
--------------------------------------------------

local notificationGui
local notifications = {}

local function getNotificationGui()
    if notificationGui and notificationGui.Parent then
        return notificationGui
    end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "AntiStaffNotifications"
    notificationGui.ResetOnSpawn = false
    notificationGui.IgnoreGuiInset = true
    notificationGui.Parent = playerGui

    return notificationGui
end

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
    local character = player.Character

    if not character then
        return
    end

    local oldHighlight = character:FindFirstChild("AntiStaffHighlight")

    if oldHighlight then
        oldHighlight:Destroy()
    end

    local highlight = Instance.new("Highlight")

    highlight.Name = "AntiStaffHighlight"

    -- Strong red
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)

    -- Red glow / fill
    highlight.FillTransparency = 0.45
    highlight.OutlineTransparency = 0

    -- Visible through walls and objects
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    highlight.Adornee = character
    highlight.Parent = character
end

--------------------------------------------------
-- REPOSITION NOTIFICATIONS
--------------------------------------------------

local function repositionNotifications()
    for index, frame in ipairs(notifications) do
        if frame and frame.Parent then

            local targetPosition = UDim2.new(
                1,
                -25,
                1,
                -25 - ((index - 1) * 82)
            )

            TweenService:Create(
                frame,
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

--------------------------------------------------
-- SHOW NOTIFICATION
--------------------------------------------------

local function showNotification(displayName, username, alreadyHere)

    local gui = getNotificationGui()

    --------------------------------------------------
    -- MAIN FRAME
    --------------------------------------------------

    local frame = Instance.new("Frame")

    frame.Name = "StaffNotification"

    frame.Size = UDim2.new(0, 340, 0, 70)

    frame.AnchorPoint = Vector2.new(1, 1)

    -- Start off screen
    frame.Position = UDim2.new(
        1,
        370,
        1,
        -25
    )

    -- Dark notification like the screenshot
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    frame.BackgroundTransparency = 0.05

    frame.BorderSizePixel = 0

    frame.Parent = gui

    --------------------------------------------------
    -- CORNER
    --------------------------------------------------

    local corner = Instance.new("UICorner")

    corner.CornerRadius = UDim.new(0, 14)

    corner.Parent = frame

    --------------------------------------------------
    -- WARNING ICON
    --------------------------------------------------

    local icon = Instance.new("TextLabel")

    icon.Name = "WarningIcon"

    icon.Size = UDim2.new(0, 45, 0, 50)

    icon.Position = UDim2.new(
        0,
        10,
        0,
        10
    )

    icon.BackgroundTransparency = 1

    icon.Text = "⚠"

    icon.TextColor3 = Color3.fromRGB(255, 205, 0)

    icon.TextSize = 27

    icon.Font = Enum.Font.GothamBold

    icon.Parent = frame

    --------------------------------------------------
    -- DISPLAY NAME + USERNAME
    --------------------------------------------------

    local nameLabel = Instance.new("TextLabel")

    nameLabel.Name = "StaffName"

    nameLabel.Size = UDim2.new(
        1,
        -65,
        0,
        28
    )

    nameLabel.Position = UDim2.new(
        0,
        62,
        0,
        8
    )

    nameLabel.BackgroundTransparency = 1

    nameLabel.Text =
        displayName .. " (@" .. username .. ")"

    nameLabel.TextColor3 =
        Color3.fromRGB(245, 245, 245)

    nameLabel.TextSize = 17

    nameLabel.Font =
        Enum.Font.GothamBold

    nameLabel.TextXAlignment =
        Enum.TextXAlignment.Left

    nameLabel.TextTruncate =
        Enum.TextTruncate.AtEnd

    nameLabel.Parent = frame

    --------------------------------------------------
    -- MESSAGE
    --------------------------------------------------

    local messageLabel = Instance.new("TextLabel")

    messageLabel.Name = "Message"

    messageLabel.Size = UDim2.new(
        1,
        -65,
        0,
        28
    )

    messageLabel.Position = UDim2.new(
        0,
        62,
        0,
        34
    )

    messageLabel.BackgroundTransparency = 1

    if alreadyHere then
        messageLabel.Text =
            "Already on server. Be careful!"
    else
        messageLabel.Text =
            "Has joined the server. Be careful!"
    end

    messageLabel.TextColor3 =
        Color3.fromRGB(165, 165, 165)

    messageLabel.TextSize = 14

    messageLabel.Font =
        Enum.Font.Gotham

    messageLabel.TextXAlignment =
        Enum.TextXAlignment.Left

    messageLabel.TextTruncate =
        Enum.TextTruncate.AtEnd

    messageLabel.Parent = frame

    --------------------------------------------------
    -- ADD TO STACK
    --------------------------------------------------

    table.insert(
        notifications,
        1,
        frame
    )

    repositionNotifications()

    --------------------------------------------------
    -- SLIDE IN
    --------------------------------------------------

    TweenService:Create(
        frame,
        TweenInfo.new(
            0.4,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out
        ),
        {
            Position = UDim2.new(
                1,
                -25,
                1,
                -25
            )
        }
    ):Play()

    --------------------------------------------------
    -- REMOVE AFTER 5 SECONDS
    --------------------------------------------------

    task.delay(ALERT_DURATION, function()

        if not frame.Parent then
            return
        end

        local fadeOut = TweenService:Create(
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
                    370,
                    1,
                    frame.Position.Y.Offset
                )
            }
        )

        fadeOut:Play()

        fadeOut.Completed:Wait()

        for i, notification in ipairs(notifications) do

            if notification == frame then

                table.remove(
                    notifications,
                    i
                )

                break
            end
        end

        frame:Destroy()

        repositionNotifications()
    end)
end

--------------------------------------------------
-- BOMB ALERT
--------------------------------------------------

local function playBombAlert()

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

local function alertStaff(player, alreadyHere)

    if not isStaff(player) then
        return
    end

    -- Permanent red highlight
    highlightStaff(player)

    -- 5 second bomb sound
    playBombAlert()

    -- Screenshot-style notification
    showNotification(
        player.DisplayName,
        player.Name,
        alreadyHere
    )
end

--------------------------------------------------
-- CHARACTER / RESPAWN MONITOR
--------------------------------------------------

local function monitorStaffCharacter(player)

    if not isStaff(player) then
        return
    end

    player.CharacterAdded:Connect(function(character)

        character:WaitForChild(
            "Humanoid",
            10
        )

        task.wait(0.1)

        if player.Parent == Players then
            highlightStaff(player)
        end
    end)

    if player.Character then

        task.spawn(function()
            highlightStaff(player)
        end)

    end
end

--------------------------------------------------
-- NEW STAFF JOIN
--------------------------------------------------

Players.PlayerAdded:Connect(function(player)

    if not isStaff(player) then
        return
    end

    monitorStaffCharacter(player)

    task.spawn(function()

        task.wait(0.1)

        if player.Parent == Players then
            alertStaff(player, false)
        end

    end)
end)

--------------------------------------------------
-- STAFF LEAVES
--------------------------------------------------

Players.PlayerRemoving:Connect(function(player)

    if isStaff(player) then
        -- Nothing permanent is stored.
        -- If they join again, PlayerAdded fires
        -- and they receive another alert.
    end

end)

--------------------------------------------------
-- STAFF ALREADY IN SERVER
--------------------------------------------------

for _, player in ipairs(Players:GetPlayers()) do

    if player ~= LocalPlayer then

        if isStaff(player) then

            monitorStaffCharacter(player)

            task.spawn(function()

                task.wait(0.1)

                if player.Parent == Players then
                    alertStaff(player, true)
                end

            end)

        end
    end
end
