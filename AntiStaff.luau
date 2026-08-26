-- AntiStaff.luau
-- Client-side Anti Staff Detector

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- STAFF LIST
--------------------------------------------------

local STAFF = {
	["LittleEczi"] = true,
	["Welaas"] = true,
	["lettersinthefire"] = true,
	["Milamybotak"] = true,
	["s0umadethis"] = true,
	["whosvqr"] = true
}

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local SOUND_ID = "rbxassetid://18980441222"
local ALERT_DURATION = 5

-- Overhead fade distance
-- 50+ studs = fully visible
-- 30 studs = fully invisible

local NAME_FADE_START = 50
local NAME_FADE_END = 30

--------------------------------------------------
-- SOUND
--------------------------------------------------

local bombSound = Instance.new("Sound")
bombSound.Name = "AntiStaffBombSound"
bombSound.SoundId = SOUND_ID
bombSound.Volume = 0.2
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
-- OVERHEAD STAFF TAG
--------------------------------------------------

local function createStaffTag(player)
	if not isStaff(player) then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	-- Remove old tag if one exists
	local oldTag = head:FindFirstChild("AntiStaffOverhead")

	if oldTag then
		oldTag:Destroy()
	end

	--------------------------------------------------
	-- BILLBOARD
	--------------------------------------------------

	local billboard = Instance.new("BillboardGui")

	billboard.Name = "AntiStaffOverhead"
	billboard.Adornee = head

	-- Wide enough for long usernames
	billboard.Size = UDim2.new(0, 300, 0, 48)

	-- Position above head
	billboard.StudsOffset = Vector3.new(0, 4.0, 0)

	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 1000000
	billboard.Parent = head

	--------------------------------------------------
	-- CONTAINER
	--------------------------------------------------

	local container = Instance.new("Frame")

	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)

	container.BackgroundTransparency = 1
	container.Parent = billboard

	--------------------------------------------------
	-- STAFF
	--------------------------------------------------

	local staffLabel = Instance.new("TextLabel")

	staffLabel.Name = "STAFF"

	staffLabel.Size = UDim2.new(1, 0, 0, 18)
	staffLabel.Position = UDim2.new(0, 0, 0, 0)

	staffLabel.BackgroundTransparency = 1

	staffLabel.Text = "STAFF"

	-- Darker red
	staffLabel.TextColor3 =
		Color3.fromRGB(200, 45, 45)

	staffLabel.TextSize = 16
	staffLabel.Font = Enum.Font.GothamBold

	staffLabel.TextStrokeTransparency = 0.35
	staffLabel.TextStrokeColor3 =
		Color3.fromRGB(0, 0, 0)

	staffLabel.TextXAlignment =
		Enum.TextXAlignment.Center

	staffLabel.Parent = container

	--------------------------------------------------
	-- DISPLAY NAME + USERNAME
	--------------------------------------------------

	local nameLabel = Instance.new("TextLabel")

	nameLabel.Name = "Name"

	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.Position = UDim2.new(0, 0, 0, 17)

	nameLabel.BackgroundTransparency = 1

	-- DisplayName (@Username)
	nameLabel.Text =
		player.DisplayName .. " (@" .. player.Name .. ")"

	-- Softer gray instead of white
	nameLabel.TextColor3 =
		Color3.fromRGB(190, 190, 190)

	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.Gotham

	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextStrokeColor3 =
		Color3.fromRGB(0, 0, 0)

	nameLabel.TextXAlignment =
		Enum.TextXAlignment.Center

	-- Never cut off long usernames
	nameLabel.TextTruncate =
		Enum.TextTruncate.None

	nameLabel.Parent = container
end

--------------------------------------------------
-- UPDATE OVERHEAD DISTANCE / FADE
--------------------------------------------------

local function updateStaffTags()

	local localCharacter = LocalPlayer.Character

	if not localCharacter then
		return
	end

	local localRoot =
		localCharacter:FindFirstChild("HumanoidRootPart")

	if not localRoot then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer and isStaff(player) then

			local character = player.Character
			local head =
				character and character:FindFirstChild("Head")

			if head then

				local tag =
					head:FindFirstChild("AntiStaffOverhead")

				if not tag then

					createStaffTag(player)

					tag =
						head:FindFirstChild("AntiStaffOverhead")
				end

				if tag then

					local distance =
						(localRoot.Position - head.Position).Magnitude

					--------------------------------------------------
					-- CALCULATE FADE
					--------------------------------------------------

					-- 50 studs = 0 transparency
					-- 30 studs = 1 transparency

					local fade =
						math.clamp(
							(NAME_FADE_START - distance)
								/
							(NAME_FADE_START - NAME_FADE_END),
							0,
							1
						)

					--------------------------------------------------
					-- FADE STAFF
					--------------------------------------------------

					local staffLabel =
						tag.Container:FindFirstChild("STAFF")

					if staffLabel then

						staffLabel.TextTransparency =
							fade

						-- Fade outline too
						staffLabel.TextStrokeTransparency =
							0.35 + (0.65 * fade)
					end

					--------------------------------------------------
					-- FADE NAME + NICK
					--------------------------------------------------

					local nameLabel =
						tag.Container:FindFirstChild("Name")

					if nameLabel then

						nameLabel.TextTransparency =
							fade

						-- Fade outline too
						nameLabel.TextStrokeTransparency =
							0.3 + (0.7 * fade)
					end

					-- Keep the billboard active so the fade
					-- can smoothly work in both directions
					tag.Enabled = true
				end
			end
		end
	end
end

--------------------------------------------------
-- PERMANENT RED HIGHLIGHT
--------------------------------------------------

local function highlightStaff(player)

	local character = player.Character

	if not character then
		return
	end

	local oldHighlight =
		character:FindFirstChild("AntiStaffHighlight")

	if oldHighlight then
		oldHighlight:Destroy()
	end

	local highlight = Instance.new("Highlight")

	highlight.Name = "AntiStaffHighlight"

	highlight.FillColor =
		Color3.fromRGB(255, 0, 0)

	highlight.OutlineColor =
		Color3.fromRGB(255, 0, 0)

	highlight.FillTransparency = 0.45
	highlight.OutlineTransparency = 0

	highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	highlight.Adornee = character
	highlight.Parent = character
end

--------------------------------------------------
-- REPOSITION NOTIFICATIONS
--------------------------------------------------

local function repositionNotifications()

	for index, frame in ipairs(notifications) do

		if frame and frame.Parent then

			local targetPosition =
				UDim2.new(
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

local function showNotification(
	displayName,
	username,
	alreadyHere
)

	local gui = getNotificationGui()

	--------------------------------------------------
	-- MAIN FRAME
	--------------------------------------------------

	local frame = Instance.new("Frame")

	frame.Name = "StaffNotification"

	frame.Size =
		UDim2.new(0, 340, 0, 70)

	frame.AnchorPoint =
		Vector2.new(1, 1)

	frame.Position =
		UDim2.new(
			1,
			370,
			1,
			-25
		)

	frame.BackgroundColor3 =
		Color3.fromRGB(18, 18, 18)

	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0

	frame.Parent = gui

	--------------------------------------------------
	-- CORNER
	--------------------------------------------------

	local corner = Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(0, 14)

	corner.Parent = frame

	--------------------------------------------------
	-- WARNING ICON
	--------------------------------------------------

	local icon = Instance.new("TextLabel")

	icon.Name = "WarningIcon"

	icon.Size =
		UDim2.new(0, 45, 0, 50)

	icon.Position =
		UDim2.new(
			0,
			10,
			0,
			10
		)

	icon.BackgroundTransparency = 1

	icon.Text = "⚠"

	icon.TextColor3 =
		Color3.fromRGB(255, 205, 0)

	icon.TextSize = 27
	icon.Font = Enum.Font.GothamBold

	icon.Parent = frame

	--------------------------------------------------
	-- DISPLAY NAME + USERNAME
	--------------------------------------------------

	local nameLabel = Instance.new("TextLabel")

	nameLabel.Name = "StaffName"

	nameLabel.Size =
		UDim2.new(
			1,
			-65,
			0,
			28
		)

	nameLabel.Position =
		UDim2.new(
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

	local messageLabel =
		Instance.new("TextLabel")

	messageLabel.Name = "Message"

	messageLabel.Size =
		UDim2.new(
			1,
			-65,
			0,
			28
		)

	messageLabel.Position =
		UDim2.new(
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
			Position =
				UDim2.new(
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

	task.delay(
		ALERT_DURATION,
		function()

			if not frame.Parent then
				return
			end

			local fadeOut =
				TweenService:Create(
					frame,
					TweenInfo.new(
						0.4,
						Enum.EasingStyle.Quad,
						Enum.EasingDirection.In
					),
					{
						BackgroundTransparency = 1,

						Position =
							UDim2.new(
								1,
								370,
								1,
								frame.Position.Y.Offset
							)
					}
				)

			fadeOut:Play()
			fadeOut.Completed:Wait()

			for i, notification in
				ipairs(notifications) do

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
		end
	)
end

--------------------------------------------------
-- BOMB ALERT
--------------------------------------------------

local function playBombAlert()

	bombSound:Stop()

	bombSound.TimePosition = 0

	bombSound:Play()

	task.delay(
		ALERT_DURATION,
		function()

			if bombSound.IsPlaying then
				bombSound:Stop()
			end
		end
	)
end

--------------------------------------------------
-- STAFF ALERT
--------------------------------------------------

local function alertStaff(
	player,
	alreadyHere
)

	if not isStaff(player) then
		return
	end

	highlightStaff(player)

	createStaffTag(player)

	playBombAlert()

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

	player.CharacterAdded:Connect(
		function(character)

			character:WaitForChild(
				"Humanoid",
				10
			)

			character:WaitForChild(
				"Head",
				10
			)

			task.wait(0.1)

			if player.Parent == Players then

				highlightStaff(player)

				createStaffTag(player)
			end
		end
	)

	if player.Character then

		task.spawn(
			function()

				local character =
					player.Character

				character:WaitForChild(
					"Head",
					10
				)

				highlightStaff(player)

				createStaffTag(player)
			end
		)
	end
end

--------------------------------------------------
-- NEW STAFF JOIN
--------------------------------------------------

Players.PlayerAdded:Connect(
	function(player)

		if not isStaff(player) then
			return
		end

		monitorStaffCharacter(player)

		task.spawn(
			function()

				task.wait(0.1)

				if player.Parent == Players then

					alertStaff(
						player,
						false
					)
				end
			end
		)
	end
)

--------------------------------------------------
-- STAFF LEAVES
--------------------------------------------------

Players.PlayerRemoving:Connect(
	function(player)

		if isStaff(player) then

			-- Nothing permanent is stored.
			-- If they join again, PlayerAdded fires
			-- and they receive another alert.

		end
	end
)

--------------------------------------------------
-- STAFF ALREADY IN SERVER
--------------------------------------------------

for _, player in
	ipairs(Players:GetPlayers()) do

	if player ~= LocalPlayer then

		if isStaff(player) then

			monitorStaffCharacter(player)

			task.spawn(
				function()

					task.wait(0.1)

					if player.Parent == Players then

						alertStaff(
							player,
							true
						)
					end
				end
			)
		end
	end
end

--------------------------------------------------
-- DISTANCE MONITOR
--------------------------------------------------

RunService.RenderStepped:Connect(
	function()
		updateStaffTags()
	end
)
