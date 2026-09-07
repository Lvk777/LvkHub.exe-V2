-- Feature keybinds and per-feature settings live inside ••• menus.
-- ALTERADO: practiceAllowed sempre true.
return function(State, Registry, UI)
    local UIS = game:GetService("UserInputService")

    State.Keybinds = State.Keybinds or {}
    local K = State.Keybinds
    local listening = nil
    local activePanel = nil
    local activeFeature = nil
    local keyButton = nil

    local function rounded(obj, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 4)
        c.Parent = obj
    end

    local function practiceAllowed()
        -- ALTERADO: sempre true
        return true
    end

    local features = {
        { id = "Aimbot", page = "Combat", label = "Aimbot", guarded = false, get = function() return State.Combat.Aimbot end, set = function(v) State.Combat.Aimbot = v end },
        { id = "SilentAim", page = "Combat", label = "Silent Aim", guarded = false, get = function() return State.Combat.SilentAim end, set = function(v) State.Combat.SilentAim = v end },
        { id = "MagicBullets", page = "Combat", label = "Magic Bullets", guarded = false, get = function() return State.Combat.MagicBullets end, set = function(v) State.Combat.MagicBullets = v end },
        { id = "HitBoxes", page = "Combat", label = "HitBoxes", guarded = false, get = function() return State.Combat.HitBoxes end, set = function(v) State.Combat.HitBoxes = v end },
        { id = "Fly", page = "Movement", label = "Fly", get = function() return State.Movement.Fly end, set = function(v) State.Movement.Fly = v end },
        { id = "Speed", page = "Movement", label = "Speed", get = function() return State.Movement.Speed end, set = function(v) State.Movement.Speed = v end },
        { id = "Noclip", page = "Movement", label = "Noclip", get = function() return State.Movement.Noclip end, set = function(v) State.Movement.Noclip = v end },
        { id = "CarFly", page = "Vehicle", label = "CarFly", get = function() return State.Movement.CarFly end, set = function(v) State.Movement.CarFly = v end },
    }

    local function rowByLabel(page, labelText)
        if not page then return nil end
        for _, child in ipairs(page:GetChildren()) do
            if child:IsA("Frame") then
                for _, d in ipairs(child:GetChildren()) do
                    if d:IsA("TextLabel") and d.Text == labelText then return child, d end
                end
            end
        end
        return nil
    end

    local function repaint(feature)
        local row = rowByLabel(UI.Pages[feature.page], feature.label)
        if not row then return end
        local toggle = nil
        for _, d in ipairs(row:GetChildren()) do
            if d:IsA("TextButton") and d.Name ~= "LvkKeybindDots" and d:FindFirstChildWhichIsA("Frame") then
                toggle = d
                break
            end
        end
        if not toggle then return end
        local on = feature.get() == true
        toggle.BackgroundColor3 = on and UI.Accent or Color3.fromRGB(45, 45, 45)
        local mark = toggle:FindFirstChildWhichIsA("Frame")
        if mark then mark.BackgroundColor3 = on and Color3.fromRGB(235, 235, 235) or Color3.fromRGB(86, 86, 86) end
    end

    local function keyName(id)
        local key = K[id]
        return key and key.Name or "NONE"
    end

    local function refreshKeyButton()
        if keyButton and activeFeature then
            keyButton.Text = listening == activeFeature and "PRESS KEY" or keyName(activeFeature)
            keyButton.TextColor3 = listening == activeFeature and UI.Accent or Color3.fromRGB(220, 220, 228)
        end
    end

    local function openFeatureMenu(feature)
        listening = nil
        if activePanel and activePanel.Parent then activePanel:Destroy() end

        local panel = Instance.new("Frame")
        panel.Name = "LvkFeatureOptions"
        panel.Size = UDim2.fromOffset(236, 44)
        panel.BackgroundColor3 = Color3.fromRGB(17, 18, 22)
        panel.BorderSizePixel = 0
        panel.ZIndex = 100
        rounded(panel, 7)
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(62, 64, 76)
        stroke.Transparency = .12
        stroke.Parent = panel

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Position = UDim2.fromOffset(10, 5)
        title.Size = UDim2.new(1, -42, 0, 28)
        title.Font = Enum.Font.SourceSansSemibold
        title.TextSize = 14
        title.TextColor3 = Color3.fromRGB(238, 238, 242)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = feature.label .. " Options"
        title.ZIndex = 101
        title.Parent = panel

        local close = Instance.new("TextButton")
        close.AnchorPoint = Vector2.new(1, 0)
        close.Position = UDim2.new(1, -7, 0, 6)
        close.Size = UDim2.fromOffset(25, 22)
        close.BackgroundColor3 = Color3.fromRGB(34, 35, 42)
        close.BorderSizePixel = 0
        close.Text = "×"
        close.Font = Enum.Font.SourceSansBold
        close.TextSize = 16
        close.TextColor3 = Color3.fromRGB(215, 215, 222)
        close.ZIndex = 102
        close.Parent = panel
        rounded(close, 4)

        local y = 39
        local function addBaseRow(label, height)
            local h = height or 31
            local row = Instance.new("Frame")
            row.Position = UDim2.fromOffset(7, y)
            row.Size = UDim2.new(1, -14, 0, h)
            row.BackgroundColor3 = Color3.fromRGB(27, 28, 34)
            row.BorderSizePixel = 0
            row.ZIndex = 101
            row.Parent = panel
            rounded(row, 4)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Position = UDim2.fromOffset(8, 0)
            l.Size = UDim2.new(1, -16, 1, 0)
            l.Font = Enum.Font.SourceSans
            l.TextSize = 12
            l.TextColor3 = Color3.fromRGB(220, 220, 228)
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Text = label
            l.ZIndex = 102
            l.Parent = row
            y = y + h + 5
            return row, l
        end

        local keyRow, keyLabel = addBaseRow("Keybind")
        keyLabel.Size = UDim2.new(1, -92, 1, 0)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(1, .5)
        b.Position = UDim2.new(1, -7, .5, 0)
        b.Size = UDim2.fromOffset(78, 20)
        b.BackgroundColor3 = Color3.fromRGB(37, 38, 46)
        b.BorderSizePixel = 0
        b.Font = Enum.Font.Code
        b.TextSize = 10
        b.TextColor3 = Color3.fromRGB(220, 220, 228)
        b.ZIndex = 103
        b.Parent = keyRow
        rounded(b, 3)

        local function addSlider(label, get, set, min, max)
            local row, l = addBaseRow(label, 38)
            l.Size = UDim2.fromOffset(82, 38)
            local bar = Instance.new("Frame")
            bar.Position = UDim2.fromOffset(88, 16)
            bar.Size = UDim2.new(1, -143, 0, 6)
            bar.BackgroundColor3 = Color3.fromRGB(43, 44, 51)
            bar.BorderSizePixel = 0
            bar.Active = true
            bar.ZIndex = 103
            bar.Parent = row
            rounded(bar, 3)
            local fill = Instance.new("Frame")
            fill.Size = UDim2.fromScale(0, 1)
            fill.BackgroundColor3 = UI.Accent
            fill.BorderSizePixel = 0
            fill.ZIndex = 104
            fill.Parent = bar
            rounded(fill, 3)
            local knob = Instance.new("Frame")
            knob.AnchorPoint = Vector2.new(.5, .5)
            knob.Size = UDim2.fromOffset(10, 16)
            knob.BackgroundColor3 = Color3.fromRGB(242, 242, 245)
            knob.BorderSizePixel = 0
            knob.ZIndex = 105
            knob.Parent = bar
            rounded(knob, 5)
            local val = Instance.new("TextLabel")
            val.AnchorPoint = Vector2.new(1, .5)
            val.Position = UDim2.new(1, -7, .5, 0)
            val.Size = UDim2.fromOffset(44, 20)
            val.BackgroundColor3 = Color3.fromRGB(35, 36, 43)
            val.BorderSizePixel = 0
            val.Font = Enum.Font.Code
            val.TextSize = 9
            val.TextColor3 = Color3.fromRGB(220, 220, 228)
            val.ZIndex = 104
            val.Parent = row
            rounded(val, 3)

            local initial = tonumber(get()) or min
            local fractional = (max - min) <= 2 or math.abs(initial - math.floor(initial)) > .001
            local step = fractional and .01 or 1
            local dragging = false
            local function paint()
                local n = math.clamp(tonumber(get()) or min, min, max)
                local a = (n - min) / math.max(max - min, 1e-6)
                fill.Size = UDim2.new(a, 0, 1, 0)
                knob.Position = UDim2.new(a, 0, .5, 0)
                val.Text = fractional and string.format("%.2f", n) or tostring(math.floor(n + .5))
            end
            local function fromX(x)
                local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
                local n = min + (max - min) * a
                n = math.floor(n / step + .5) * step
                set(math.clamp(n, min, max))
                paint()
            end
            bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; fromX(i.Position.X) end end)
            knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; fromX(i.Position.X) end end)
            UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
            paint()
        end

        local function addToggle(label, get, set)
            local row, l = addBaseRow(label)
            l.Size = UDim2.new(1, -50, 1, 0)
            local t = Instance.new("TextButton")
            t.AnchorPoint = Vector2.new(1, .5)
            t.Position = UDim2.new(1, -7, .5, 0)
            t.Size = UDim2.fromOffset(34, 18)
            t.Text = ""
            t.BorderSizePixel = 0
            t.AutoButtonColor = false
            t.ZIndex = 103
            t.Parent = row
            rounded(t, 3)
            local function paint() t.BackgroundColor3 = get() and UI.Accent or Color3.fromRGB(48, 49, 57) end
            t.MouseButton1Click:Connect(function() set(not get()); paint() end)
            paint()
        end

        local function addDropdown(label, values, get, set)
            local row, l = addBaseRow(label)
            l.Size = UDim2.new(1, -96, 1, 0)
            local d = Instance.new("TextButton")
            d.AnchorPoint = Vector2.new(1, .5)
            d.Position = UDim2.new(1, -7, .5, 0)
            d.Size = UDim2.fromOffset(82, 20)
            d.BackgroundColor3 = Color3.fromRGB(37, 38, 46)
            d.BorderSizePixel = 0
            d.Font = Enum.Font.SourceSans
            d.TextSize = 11
            d.TextColor3 = Color3.fromRGB(225, 225, 232)
            d.ZIndex = 103
            d.Parent = row
            rounded(d, 3)
            local function paint() d.Text = tostring(get()) end
            d.MouseButton1Click:Connect(function()
                local i = table.find(values, get()) or 0
                set(values[i % #values + 1])
                paint()
            end)
            paint()
        end

        activePanel = panel
        activeFeature = feature.id
        keyButton = b
        refreshKeyButton()
        b.MouseButton1Click:Connect(function() listening = feature.id; refreshKeyButton() end)

        if feature.id == "Aimbot" then
            addSlider("Smoothness", function() return State.Combat.AimbotSmoothness or .32 end, function(v) State.Combat.AimbotSmoothness = v end, .05, 1)
            addSlider("FOV Radius", function() return State.Combat.AimFOV or 180 end, function(v) State.Combat.AimFOV = v end, 20, 800)
            addDropdown("Aim Part", { "Head", "Torso" }, function() return State.Combat.AimPart or "Head" end, function(v) State.Combat.AimPart = v end)
            addToggle("Wall Check", function() return State.Combat.WallCheck == true end, function(v) State.Combat.WallCheck = v end)
        elseif feature.id == "SilentAim" then
            addSlider("FOV Radius", function() return State.Combat.AimFOV or 180 end, function(v) State.Combat.AimFOV = v end, 20, 800)
            addDropdown("Aim Part", { "Head", "Torso" }, function() return State.Combat.AimPart or "Head" end, function(v) State.Combat.AimPart = v end)
            addToggle("Wall Check", function() return State.Combat.WallCheck == true end, function(v) State.Combat.WallCheck = v end)
        elseif feature.id == "MagicBullets" then
            addSlider("FOV Radius", function() return State.Combat.AimFOV or 180 end, function(v) State.Combat.AimFOV = v end, 20, 800)
            addDropdown("Aim Part", { "Head", "Torso" }, function() return State.Combat.AimPart or "Head" end, function(v) State.Combat.AimPart = v end)
            addToggle("Through Walls", function() return State.Combat.MagicThroughWalls == true end, function(v) State.Combat.MagicThroughWalls = v end)
        elseif feature.id == "HitBoxes" then
            addSlider("HitBox Size", function() return State.Combat.HitboxSize or 6 end, function(v) State.Combat.HitboxSize = v end, 2, 20)
        elseif feature.id == "Fly" then
            addSlider("Fly Speed", function() return State.Movement.FlySpeed or 65 end, function(v) State.Movement.FlySpeed = v end, 10, 200)
        elseif feature.id == "Speed" then
            addSlider("WalkSpeed", function() return State.Movement.SpeedValue or 32 end, function(v) State.Movement.SpeedValue = v end, 16, 150)
        elseif feature.id == "CarFly" then
            addSlider("CarFly Speed", function() return State.Movement.CarFlySpeed or 90 end, function(v) State.Movement.CarFlySpeed = v end, 20, 250)
        end

        local clear = Instance.new("TextButton")
        clear.Position = UDim2.fromOffset(7, y)
        clear.Size = UDim2.new(1, -14, 0, 25)
        clear.BackgroundColor3 = Color3.fromRGB(31, 32, 38)
        clear.BorderSizePixel = 0
        clear.Font = Enum.Font.SourceSans
        clear.TextSize = 11
        clear.TextColor3 = Color3.fromRGB(170, 175, 190)
        clear.Text = "CLEAR KEYBIND"
        clear.ZIndex = 101
        clear.Parent = panel
        rounded(clear, 4)
        y = y + 30
        clear.MouseButton1Click:Connect(function() K[feature.id] = nil; listening = nil; refreshKeyButton() end)

        panel.Size = UDim2.fromOffset(236, y + 3)

        close.MouseButton1Click:Connect(function()
            listening = nil
            if UI.CloseDockedPanel then UI.CloseDockedPanel(panel) else panel:Destroy() end
        end)

        if UI.OpenDockedPanel then UI.OpenDockedPanel(panel) else panel.Parent = UI.Gui end
    end

    local function addDots(feature)
        local page = UI.Pages[feature.page]
        local row, label = rowByLabel(page, feature.label)
        if not row or row:FindFirstChild("LvkKeybindDots") then return end
        if label then label.Size = UDim2.new(1, -82, 1, 0) end

        local dots = Instance.new("TextButton")
        dots.Name = "LvkKeybindDots"
        dots.AnchorPoint = Vector2.new(1, .5)
        dots.Position = UDim2.new(1, -43, .5, 0)
        dots.Size = UDim2.fromOffset(26, 20)
        dots.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
        dots.BorderSizePixel = 0
        dots.Text = "•••"
        dots.Font = Enum.Font.SourceSansBold
        dots.TextSize = 14
        dots.TextColor3 = Color3.fromRGB(195, 195, 205)
        dots.Parent = row
        rounded(dots, 4)
        dots.MouseButton1Click:Connect(function() openFeatureMenu(feature) end)
    end

    task.defer(function() for _, feature in ipairs(features) do addDots(feature) end end)
    task.delay(.5, function() for _, feature in ipairs(features) do addDots(feature) end end)

    UIS.InputBegan:Connect(function(input, _processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

        if listening then
            local id = listening
            listening = nil
            if input.KeyCode == Enum.KeyCode.Escape
                or input.KeyCode == Enum.KeyCode.Backspace
                or input.KeyCode == Enum.KeyCode.Delete
                or input.KeyCode == Enum.KeyCode.Unknown then
                K[id] = nil
            elseif K[id] == input.KeyCode then
                K[id] = nil
            else
                K[id] = input.KeyCode
            end
            refreshKeyButton()
            return
        end

        if UIS:GetFocusedTextBox() then return end

        for _, feature in ipairs(features) do
            local key = K[feature.id]
            if key and input.KeyCode == key then
                local nextValue = not feature.get()
                -- guarded removido, sempre permite
                feature.set(nextValue)
                repaint(feature)
                break
            end
        end
    end)
end
