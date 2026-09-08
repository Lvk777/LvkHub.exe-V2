-- LvkHub.exe INVENTORY VIEWER V4
-- Read-only viewer for equipment already replicated to this client.
-- Replaces the legacy 4-slot Dummy Inventory presentation without changing server state.
return function(State, TargetProvider, UI)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")

    local LP = Players.LocalPlayer

    State.Combat = State.Combat or {}
    if State.Combat.DummyInventoryVisible == nil then State.Combat.DummyInventoryVisible = false end
    if State.Combat.InventoryViewerPinned == nil then State.Combat.InventoryViewerPinned = false end

    local function isTarget(model)
        return model ~= nil
            and TargetProvider ~= nil
            and type(TargetProvider.IsTarget) == "function"
            and TargetProvider.IsTarget(model) == true
    end

    local function rounded(obj, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 6)
        corner.Parent = obj
    end

    local function cleanName(objOrName)
        if TargetProvider
            and TargetProvider.Registry
            and type(TargetProvider.Registry.CleanInventoryLabel) == "function"
        then
            local ok, value = pcall(TargetProvider.Registry.CleanInventoryLabel, objOrName)
            if ok and type(value) == "string" and value ~= "" then return value end
        end

        local obj = typeof(objOrName) == "Instance" and objOrName or nil
        local raw = obj and obj.Name or tostring(objOrName or "")

        if obj then
            for _, attr in ipairs({"SourceModelName", "DisplayName", "ItemName", "ItemDisplayName"}) do
                local value = obj:GetAttribute(attr)
                if typeof(value) == "string" and value ~= "" then return value end
            end
        end

        local withoutUuid = raw:gsub(
            "^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]%-[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]%-[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]%-[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]%-[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]",
            ""
        )
        withoutUuid = withoutUuid:gsub("^[%s_%-]+", ""):gsub("[%s]+$", "")
        return withoutUuid ~= "" and withoutUuid or (raw ~= "" and raw or "Unknown")
    end

    local function ammoText(tool)
        if not tool or not tool:IsA("Tool") then return nil end
        local ammo = tool:FindFirstChild("Ammo")
        local mag = ammo and ammo:FindFirstChild("MagAmmo")
        if not mag or not mag:IsA("ValueBase") then return nil end

        local current = tonumber(mag.Value)
        if current == nil then return nil end

        local maximum = nil
        pcall(function() maximum = tonumber(mag.MaxValue) end)
        if maximum then
            return string.format("%.0f/%.0f", current, maximum)
        end
        return string.format("%.0f", current)
    end

    local function inventoryDetails(model)
        local details = {}
        local seen = {}

        local function add(obj, equipped)
            if #details >= 6 or not obj then return end
            local label = cleanName(obj)
            if label == "" then return end
            local key = string.lower(label)
            if seen[key] then
                if equipped then seen[key].equipped = true end
                if obj:IsA("Tool") then
                    local ammo = ammoText(obj)
                    if ammo then seen[key].ammo = ammo end
                end
                return
            end

            local item = {
                name = label,
                ammo = obj:IsA("Tool") and ammoText(obj) or nil,
                equipped = equipped == true,
                object = obj,
            }
            seen[key] = item
            table.insert(details, item)
        end

        if not model then return details end

        -- Equipped tools are replicated directly on Character.
        for _, obj in ipairs(model:GetChildren()) do
            if obj:IsA("Tool") then add(obj, true) end
        end

        -- Backpack inventory when Roblox exposes it to this client.
        local player = Players:GetPlayerFromCharacter(model)
        local backpack = player and player:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, obj in ipairs(backpack:GetChildren()) do
                if obj:IsA("Tool") then add(obj, false) end
                if #details >= 6 then break end
            end
        end

        -- Visual equipped-weapon fallback used by current game builds.
        if #details < 6 then
            local rig = model:FindFirstChild("WeaponRig")
            local weapon = rig and rig:FindFirstChild("Weapon")
            if weapon then
                for _, obj in ipairs(weapon:GetChildren()) do
                    if obj:IsA("Model") or obj:IsA("Tool") then add(obj, true) end
                    if #details >= 6 then break end
                end
            end
        end

        return details
    end

    ------------------------------------------------------------------------
    -- Keep legacy viewer hidden; its buttons/state remain compatible.
    ------------------------------------------------------------------------
    local legacy = UI.Gui:FindFirstChild("LvkHubDummyInventoryV3")
    if legacy then legacy.Visible = false end

    local previous = UI.Gui:FindFirstChild("LvkHubInventoryViewerV4")
    if previous then previous:Destroy() end

    local frame = Instance.new("Frame")
    frame.Name = "LvkHubInventoryViewerV4"
    frame.Size = UDim2.fromOffset(310, 340)
    frame.Position = UDim2.new(1, -328, 0, 286)
    frame.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 110
    frame.Parent = UI.Gui
    rounded(frame, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(70, 72, 88)
    stroke.Transparency = .12
    stroke.Parent = frame

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Color3.fromRGB(20, 21, 27)
    header.BorderSizePixel = 0
    header.Active = true
    header.ZIndex = 111
    header.Parent = frame
    rounded(header, 8)

    local accent = Instance.new("Frame")
    accent.Position = UDim2.fromOffset(8, 10)
    accent.Size = UDim2.fromOffset(3, 24)
    accent.BackgroundColor3 = Color3.fromRGB(119, 120, 255)
    accent.BorderSizePixel = 0
    accent.ZIndex = 112
    accent.Parent = header
    rounded(accent, 2)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(18, 0)
    title.Size = UDim2.new(1, -62, 1, 0)
    title.Font = Enum.Font.SourceSansSemibold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(240, 240, 244)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "INVENTORY VIEWER"
    title.ZIndex = 112
    title.Parent = header

    local pin = Instance.new("TextButton")
    pin.AnchorPoint = Vector2.new(1, .5)
    pin.Position = UDim2.new(1, -10, .5, 0)
    pin.Size = UDim2.fromOffset(30, 26)
    pin.BackgroundTransparency = 1
    pin.Text = "📌"
    pin.Font = Enum.Font.SourceSansBold
    pin.TextSize = 15
    pin.ZIndex = 114
    pin.Parent = header

    local targetLabel = Instance.new("TextLabel")
    targetLabel.Position = UDim2.fromOffset(12, 52)
    targetLabel.Size = UDim2.new(1, -92, 0, 24)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Font = Enum.Font.SourceSansSemibold
    targetLabel.TextSize = 12
    targetLabel.TextColor3 = Color3.fromRGB(180, 195, 255)
    targetLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetLabel.Text = "Target: AUTO"
    targetLabel.ZIndex = 111
    targetLabel.Parent = frame

    local nextButton = Instance.new("TextButton")
    nextButton.AnchorPoint = Vector2.new(1, 0)
    nextButton.Position = UDim2.new(1, -12, 0, 53)
    nextButton.Size = UDim2.fromOffset(64, 22)
    nextButton.BackgroundColor3 = Color3.fromRGB(35, 36, 44)
    nextButton.BorderSizePixel = 0
    nextButton.Font = Enum.Font.SourceSansSemibold
    nextButton.TextSize = 11
    nextButton.TextColor3 = Color3.fromRGB(220, 220, 228)
    nextButton.Text = "NEXT"
    nextButton.ZIndex = 112
    nextButton.Parent = frame
    rounded(nextButton, 4)

    local slotLabels = {}
    local slotMeta = {}
    for i = 1, 6 do
        local y = 82 + (i - 1) * 42
        local card = Instance.new("Frame")
        card.Position = UDim2.fromOffset(12, y)
        card.Size = UDim2.new(1, -24, 0, 36)
        card.BackgroundColor3 = Color3.fromRGB(23, 24, 30)
        card.BorderSizePixel = 0
        card.ZIndex = 111
        card.Parent = frame
        rounded(card, 6)

        local num = Instance.new("TextLabel")
        num.Position = UDim2.fromOffset(7, 6)
        num.Size = UDim2.fromOffset(28, 24)
        num.BackgroundColor3 = Color3.fromRGB(119, 120, 255)
        num.BorderSizePixel = 0
        num.Font = Enum.Font.SourceSansBold
        num.TextSize = 12
        num.TextColor3 = Color3.fromRGB(255, 255, 255)
        num.Text = tostring(i)
        num.ZIndex = 112
        num.Parent = card
        rounded(num, 5)

        local name = Instance.new("TextLabel")
        name.Position = UDim2.fromOffset(44, 0)
        name.Size = UDim2.new(1, -100, 1, 0)
        name.BackgroundTransparency = 1
        name.Font = Enum.Font.SourceSans
        name.TextSize = 13
        name.TextColor3 = Color3.fromRGB(225, 225, 232)
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Text = "Empty"
        name.ZIndex = 112
        name.Parent = card
        slotLabels[i] = name

        local meta = Instance.new("TextLabel")
        meta.AnchorPoint = Vector2.new(1, .5)
        meta.Position = UDim2.new(1, -8, .5, 0)
        meta.Size = UDim2.fromOffset(54, 20)
        meta.BackgroundTransparency = 1
        meta.Font = Enum.Font.Code
        meta.TextSize = 10
        meta.TextColor3 = Color3.fromRGB(145, 150, 170)
        meta.TextXAlignment = Enum.TextXAlignment.Right
        meta.Text = ""
        meta.ZIndex = 112
        meta.Parent = card
        slotMeta[i] = meta
    end

    ------------------------------------------------------------------------
    -- Dragging from the header remains available, without an on-screen label.
    ------------------------------------------------------------------------
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
            local delta = input.Position - startMouse
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local function targetList()
        local list = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            local model = plr.Character
            if plr ~= LP and model and isTarget(model) then table.insert(list, model) end
        end
        table.sort(list, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)
        return list
    end

    local override = nil
    nextButton.MouseButton1Click:Connect(function()
        local list = targetList()
        if #list == 0 then
            override = nil
            return
        end
        local idx = table.find(list, override) or table.find(list, State.Combat.SelectedBot) or 0
        override = list[idx % #list + 1]
    end)

    local function currentTarget()
        if override and isTarget(override) then return override end
        if State.Combat.SelectedBot and isTarget(State.Combat.SelectedBot) then return State.Combat.SelectedBot end

        local api = shared.LvkHubDummyAimAPI
        if api and type(api.ChooseTarget) == "function" then
            local ok, model = pcall(api.ChooseTarget, false)
            if ok and model and isTarget(model) then return model end
        end

        return targetList()[1]
    end

    local function paintPin()
        pin.TextColor3 = State.Combat.InventoryViewerPinned and UI.Accent or Color3.fromRGB(165, 165, 178)
    end

    pin.MouseButton1Click:Connect(function()
        State.Combat.InventoryViewerPinned = not State.Combat.InventoryViewerPinned
        paintPin()
    end)
    paintPin()

    local timer = 0
    RunService.RenderStepped:Connect(function(dt)
        -- Never allow the superseded 4-slot card to appear.
        if legacy and legacy.Parent and legacy.Visible then legacy.Visible = false end

        local menuVisible = UI.Main and UI.Main.Visible == true
        frame.Visible = State.Combat.DummyInventoryVisible == true
            and (State.Combat.InventoryViewerPinned == true or menuVisible)

        if not frame.Visible then return end

        timer += dt
        if timer < .12 then return end
        timer = 0
        paintPin()

        local model = currentTarget()
        if not model then
            targetLabel.Text = "Target: none"
            for i = 1, 6 do
                slotLabels[i].Text = "Empty"
                slotMeta[i].Text = ""
            end
            return
        end

        local plr = Players:GetPlayerFromCharacter(model)
        targetLabel.Text = "Target: " .. (plr and plr.Name or model.Name)

        local items = inventoryDetails(model)
        for i = 1, 6 do
            local item = items[i]
            if item then
                slotLabels[i].Text = item.name
                if item.ammo then
                    slotMeta[i].Text = item.ammo
                    slotMeta[i].TextColor3 = Color3.fromRGB(180, 195, 255)
                elseif item.equipped then
                    slotMeta[i].Text = "EQUIP"
                    slotMeta[i].TextColor3 = Color3.fromRGB(120, 205, 155)
                else
                    slotMeta[i].Text = ""
                end
            else
                slotLabels[i].Text = "Empty"
                slotMeta[i].Text = ""
            end
        end
    end)
end
