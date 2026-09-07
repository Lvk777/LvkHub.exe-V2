-- Dummy-only Target Info card inspired by Yokai's compact target panel.
-- ALTERADO: agora usa Players reais.
return function(State, Registry, UI)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")

    State.Visuals.TargetInfo = State.Visuals.TargetInfo == true
    State.Visuals.TargetInfoPinned = State.Visuals.TargetInfoPinned == true
    UI.Toggle(UI.Pages.Visuals, "Target Info", function() return State.Visuals.TargetInfo end, function(v) State.Visuals.TargetInfo = v end)

    local function rounded(obj, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 6)
        c.Parent = obj
    end

    local frame = Instance.new("Frame")
    frame.Name = "LvkHubDummyTargetInfo"
    frame.Size = UDim2.fromOffset(250, 118)
    frame.Position = UDim2.fromOffset(18, 18)
    frame.BackgroundColor3 = Color3.fromRGB(24, 23, 27)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 90
    frame.Parent = UI.Gui
    rounded(frame, 7)
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(48, 48, 57)
    border.Transparency = .2
    border.Parent = frame

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Color3.fromRGB(29, 28, 33)
    header.BorderSizePixel = 0
    header.Active = true
    header.ZIndex = 91
    header.Parent = frame
    rounded(header, 7)

    local icon = Instance.new("TextLabel")
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.fromOffset(10, 0)
    icon.Size = UDim2.fromOffset(22, 38)
    icon.Font = Enum.Font.SourceSansBold
    icon.TextSize = 17
    icon.TextColor3 = Color3.fromRGB(230, 230, 235)
    icon.Text = "◈"
    icon.ZIndex = 92
    icon.Parent = header

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(34, 0)
    title.Size = UDim2.new(1, -102, 1, 0)
    title.Font = Enum.Font.SourceSansSemibold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(225, 225, 230)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Target Info"
    title.ZIndex = 92
    title.Parent = header

    local pin = Instance.new("TextButton")
    pin.AnchorPoint = Vector2.new(1, .5)
    pin.Position = UDim2.new(1, -38, .5, 0)
    pin.Size = UDim2.fromOffset(26, 24)
    pin.BackgroundTransparency = 1
    pin.Text = "📌"
    pin.Font = Enum.Font.SourceSansBold
    pin.TextSize = 15
    pin.ZIndex = 94
    pin.Parent = header

    local dots = Instance.new("TextButton")
    dots.AnchorPoint = Vector2.new(1, .5)
    dots.Position = UDim2.new(1, -8, .5, 0)
    dots.Size = UDim2.fromOffset(26, 24)
    dots.BackgroundTransparency = 1
    dots.Text = "⋮"
    dots.Font = Enum.Font.SourceSansBold
    dots.TextSize = 20
    dots.TextColor3 = Color3.fromRGB(175, 175, 185)
    dots.ZIndex = 94
    dots.Parent = header

    local menu = Instance.new("Frame")
    menu.AnchorPoint = Vector2.new(1, 0)
    menu.Position = UDim2.new(1, -4, 0, 35)
    menu.Size = UDim2.fromOffset(164, 39)
    menu.BackgroundColor3 = Color3.fromRGB(27, 27, 32)
    menu.BorderSizePixel = 0
    menu.Visible = false
    menu.ZIndex = 100
    menu.Parent = frame
    rounded(menu, 5)
    local ms = Instance.new("UIStroke")
    ms.Color = Color3.fromRGB(55, 56, 66)
    ms.Transparency = .1
    ms.Parent = menu

    local invRow = Instance.new("TextButton")
    invRow.Position = UDim2.fromOffset(5, 5)
    invRow.Size = UDim2.new(1, -10, 1, -10)
    invRow.BackgroundColor3 = Color3.fromRGB(35, 35, 41)
    invRow.BorderSizePixel = 0
    invRow.AutoButtonColor = false
    invRow.Text = ""
    invRow.ZIndex = 101
    invRow.Parent = menu
    rounded(invRow, 4)

    local invText = Instance.new("TextLabel")
    invText.BackgroundTransparency = 1
    invText.Position = UDim2.fromOffset(8, 0)
    invText.Size = UDim2.new(1, -48, 1, 0)
    invText.Font = Enum.Font.SourceSans
    invText.TextSize = 12
    invText.TextColor3 = Color3.fromRGB(224, 224, 230)
    invText.TextXAlignment = Enum.TextXAlignment.Left
    invText.Text = "Inventory Viewer"
    invText.ZIndex = 102
    invText.Parent = invRow

    local invToggle = Instance.new("Frame")
    invToggle.AnchorPoint = Vector2.new(1, .5)
    invToggle.Position = UDim2.new(1, -8, .5, 0)
    invToggle.Size = UDim2.fromOffset(28, 18)
    invToggle.BorderSizePixel = 0
    invToggle.ZIndex = 102
    invToggle.Parent = invRow
    rounded(invToggle, 4)
    local invMark = Instance.new("Frame")
    invMark.AnchorPoint = Vector2.new(.5, .5)
    invMark.Position = UDim2.fromScale(.5, .5)
    invMark.Size = UDim2.fromOffset(18, 10)
    invMark.BorderSizePixel = 0
    invMark.ZIndex = 103
    invMark.Parent = invToggle
    rounded(invMark, 3)

    local avatar = Instance.new("ImageLabel")
    avatar.Position = UDim2.fromOffset(12, 48)
    avatar.Size = UDim2.fromOffset(58, 58)
    avatar.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    avatar.BorderSizePixel = 0
    avatar.ZIndex = 91
    avatar.Parent = frame
    rounded(avatar, 29)

    local display = Instance.new("TextLabel")
    display.BackgroundTransparency = 1
    display.Position = UDim2.fromOffset(82, 47)
    display.Size = UDim2.new(1, -94, 0, 22)
    display.Font = Enum.Font.SourceSansSemibold
    display.TextSize = 14
    display.TextColor3 = Color3.fromRGB(218, 218, 225)
    display.TextXAlignment = Enum.TextXAlignment.Left
    display.Text = "No target"
    display.ZIndex = 91
    display.Parent = frame

    local user = Instance.new("TextLabel")
    user.BackgroundTransparency = 1
    user.Position = UDim2.fromOffset(82, 66)
    user.Size = UDim2.new(1, -94, 0, 15)
    user.Font = Enum.Font.SourceSans
    user.TextSize = 10
    user.TextColor3 = Color3.fromRGB(130, 135, 150)
    user.TextXAlignment = Enum.TextXAlignment.Left
    user.Text = ""
    user.ZIndex = 91
    user.Parent = frame

    local hpBack = Instance.new("Frame")
    hpBack.Position = UDim2.fromOffset(82, 86)
    hpBack.Size = UDim2.new(1, -94, 0, 5)
    hpBack.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
    hpBack.BorderSizePixel = 0
    hpBack.ZIndex = 91
    hpBack.Parent = frame
    rounded(hpBack, 3)

    local hp = Instance.new("Frame")
    hp.Size = UDim2.fromScale(0, 1)
    hp.BackgroundColor3 = Color3.fromRGB(62, 204, 150)
    hp.BorderSizePixel = 0
    hp.ZIndex = 92
    hp.Parent = hpBack
    rounded(hp, 3)
    local hpGrad = Instance.new("UIGradient")
    hpGrad.Color = ColorSequence.new(Color3.fromRGB(71, 221, 163), Color3.fromRGB(42, 183, 139))
    hpGrad.Parent = hp

    local hpText = Instance.new("TextLabel")
    hpText.BackgroundTransparency = 1
    hpText.Position = UDim2.fromOffset(82, 94)
    hpText.Size = UDim2.new(1, -94, 0, 16)
    hpText.Font = Enum.Font.Code
    hpText.TextSize = 10
    hpText.TextColor3 = Color3.fromRGB(145, 150, 160)
    hpText.TextXAlignment = Enum.TextXAlignment.Left
    hpText.Text = "HP --"
    hpText.ZIndex = 91
    hpText.Parent = frame

    local dragging = false
    local startMouse, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startMouse = input.Position
            startPos = frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - startMouse
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local current = nil
    local thumbCache = {}
    local thumbPending = {}

    local function selectTarget()
        -- ALTERADO: escolhe o Player mais próximo usando a API existente
        local api = shared.LvkHubDummyAimAPI
        if api and type(api.ChooseTarget) == "function" then
            local m = api.ChooseTarget(false)
            if m and Registry.IsBot(m) then return m end
        end
        return nil
    end

    local function updateIdentity(model)
        -- ALTERADO: agora obtém o Player real a partir do model
        local sourceName = model and model.Name or "No target"
        local plr = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character == model then plr = p; break end
        end
        if not plr then
            avatar.Image = ""
            display.Text = sourceName
            user.Text = ""
            return
        end

        display.Text = plr.DisplayName
        user.Text = "@" .. plr.Name
        if thumbCache[plr.UserId] then
            avatar.Image = thumbCache[plr.UserId]
            return
        end
        if not thumbPending[plr.UserId] then
            thumbPending[plr.UserId] = true
            task.spawn(function()
                local ok, img = pcall(function()
                    return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                end)
                thumbPending[plr.UserId] = nil
                if ok then
                    thumbCache[plr.UserId] = img
                    if current == model then avatar.Image = img end
                end
            end)
        end
    end

    local function paintPin()
        pin.TextColor3 = State.Visuals.TargetInfoPinned and UI.Accent or Color3.fromRGB(165, 165, 178)
        pin.BackgroundTransparency = 1
    end

    local function paintInventoryToggle()
        local on = State.Combat.DummyInventoryVisible == true
        invToggle.BackgroundColor3 = on and UI.Accent or Color3.fromRGB(48, 49, 57)
        invMark.BackgroundColor3 = on and Color3.fromRGB(238, 238, 242) or Color3.fromRGB(86, 86, 90)
    end

    pin.MouseButton1Click:Connect(function()
        State.Visuals.TargetInfoPinned = not State.Visuals.TargetInfoPinned
        paintPin()
    end)
    dots.MouseButton1Click:Connect(function()
        menu.Visible = not menu.Visible
        paintInventoryToggle()
    end)
    invRow.MouseButton1Click:Connect(function()
        if current and Registry.IsBot(current) then State.Combat.SelectedBot = current end
        State.Combat.DummyInventoryVisible = not State.Combat.DummyInventoryVisible
        paintInventoryToggle()
    end)

    paintPin()
    paintInventoryToggle()

    local timer = 0
    RunService.RenderStepped:Connect(function(dt)
        local menuVisible = UI.Main and UI.Main.Visible == true
        frame.Visible = State.Visuals.TargetInfo == true and (State.Visuals.TargetInfoPinned == true or menuVisible)
        if not frame.Visible then
            menu.Visible = false
            return
        end

        timer = timer + dt
        if timer < .10 then return end
        timer = 0
        paintPin()
        paintInventoryToggle()

        local model = selectTarget()
        if model ~= current then
            current = model
            avatar.Image = ""
            menu.Visible = false
        end

        if not model then
            display.Text = "No target"
            user.Text = "Move a test dummy into FOV"
            avatar.Image = ""
            hp.Size = UDim2.new(0, 0, 1, 0)
            hpText.Text = "HP --"
            return
        end

        updateIdentity(model)
        local hum = Registry.HumanoidOf(model)
        local ratio = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1) or 0
        hp.Size = UDim2.new(ratio, 0, 1, 0)
        hpText.Text = string.format("HP %.0f / %.0f  •  %d%%", hum and hum.Health or 0, hum and hum.MaxHealth or 0, math.floor(ratio * 100 + .5))
    end)
end
