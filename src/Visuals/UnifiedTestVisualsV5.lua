-- LvkHub.exe unified Visuals V5
-- LOCAL Workspace.TestPlayers dummies + Workspace.Vehicles only.
-- ESP wall check originates from the LocalPlayer character, not the camera.
-- ALTERADO: agora aceita Players reais.
return function(State, Registry, UI)
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")

    local LP = Players.LocalPlayer
    local page = UI.Pages.Visuals
    local parent = UI.Gui.Parent

    local cfg = State.Visuals._V5Config or {
        Box3DColor = Color3.fromRGB(119, 120, 255), Box3DTransparency = 0,
        ChamsColor = Color3.fromRGB(119, 120, 255), ChamsTransparency = 62,
        CornerColor = Color3.fromRGB(255, 255, 255), CornerTransparency = 0,
        ESPVisibleColor = Color3.fromRGB(55, 235, 95), ESPHiddenColor = Color3.fromRGB(245, 65, 65), ESPTransparency = 0, ESPWallCheck = true,
        NameColor = Color3.fromRGB(255, 255, 255), NameTransparency = 0,
        HealthTransparency = 0,
        ThermalColor = Color3.fromRGB(255, 145, 60), ThermalTransparency = 0,
        TracerColor = Color3.fromRGB(255, 255, 255), TracerTransparency = 0, TracerOrigin = "Bottom",
        SkeletonColor = Color3.fromRGB(255, 255, 255), SkeletonTransparency = 0,
        CarColor = Color3.fromRGB(60, 220, 180), CarTransparency = 84,
        PreviewAccent = Color3.fromRGB(119, 120, 255), PreviewTransparency = 0,
    }
    State.Visuals._V5Config = cfg

    local function rounded(obj, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 5)
        c.Parent = obj
    end

    local function drag(frame, handle)
        handle.Active = true
        local dragging = false
        local startMouse, startPos
        handle.InputBegan:Connect(function(input)
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
    end

    for _, name in ipairs({ "LvkHubUnifiedVisualsV3", "LvkHubUnifiedVisualsV4", "LvkHubUnifiedVisualsV5", "LvkHubUnifiedPreviewV3", "LvkHubUnifiedPreviewV4" }) do
        local old = parent:FindFirstChild(name) or UI.Gui:FindFirstChild(name)
        if old then pcall(function() old:Destroy() end) end
    end

    ------------------------------------------------------------------------
    -- Per-visual popup helpers.
    ------------------------------------------------------------------------
    UI.Section(page, "Visuals")
    local activePopup = nil
    local painters = {}

    local function closePopup()
        if activePopup then
            if UI.CloseDockedPanel and UI.ActiveDockedPanel == activePopup then UI.CloseDockedPanel(activePopup)
            elseif activePopup.Parent then activePopup:Destroy() end
        end
        activePopup = nil
    end

    local function newPopup(title)
        closePopup()
        local p = Instance.new("Frame")
        p.Name = "LvkVisualOptionsV5"
        p.Size = UDim2.fromOffset(236, 44)
        p.BackgroundColor3 = Color3.fromRGB(17, 18, 22)
        p.BorderSizePixel = 0
        p.ZIndex = 100
        rounded(p, 7)
        local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(65, 67, 80); st.Transparency = .12; st.Parent = p
        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.fromOffset(10, 5)
        titleLabel.Size = UDim2.new(1, -42, 0, 28)
        titleLabel.Font = Enum.Font.SourceSansSemibold
        titleLabel.TextSize = 14
        titleLabel.TextColor3 = Color3.fromRGB(238, 238, 242)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Text = title
        titleLabel.ZIndex = 101
        titleLabel.Parent = p
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
        close.Parent = p
        rounded(close, 4)
        close.MouseButton1Click:Connect(closePopup)
        activePopup = p
        return p
    end

    local function buildPopup(title, builder)
        local p = newPopup(title)
        local y = 39
        local function baseRow(label, h)
            h = h or 31
            local r = Instance.new("Frame")
            r.Position = UDim2.fromOffset(7, y)
            r.Size = UDim2.new(1, -14, 0, h)
            r.BackgroundColor3 = Color3.fromRGB(27, 28, 34)
            r.BorderSizePixel = 0
            r.ZIndex = 101
            r.Parent = p
            rounded(r, 4)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Position = UDim2.fromOffset(8, 0)
            l.Size = UDim2.new(1, -16, 1, 0)
            l.Font = Enum.Font.SourceSans
            l.TextSize = 12
            l.TextColor3 = Color3.fromRGB(222, 222, 228)
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Text = label
            l.ZIndex = 102
            l.Parent = r
            y = y + h + 5
            return r, l
        end

        local rainbow = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        })

        local function color(label, get, set)
            local r, l = baseRow(label, 38)
            l.Size = UDim2.fromOffset(74, 38)
            local bar = Instance.new("Frame")
            bar.Position = UDim2.fromOffset(80, 11)
            bar.Size = UDim2.new(1, -90, 0, 16)
            bar.BackgroundColor3 = Color3.new(1, 1, 1)
            bar.BorderSizePixel = 0
            bar.Active = true
            bar.ZIndex = 103
            bar.Parent = r
            rounded(bar, 4)
            local grad = Instance.new("UIGradient"); grad.Color = rainbow; grad.Parent = bar
            local knob = Instance.new("Frame")
            knob.AnchorPoint = Vector2.new(.5, .5)
            knob.Size = UDim2.fromOffset(4, 22)
            knob.BackgroundColor3 = Color3.fromRGB(248, 248, 250)
            knob.BorderSizePixel = 0
            knob.ZIndex = 104
            knob.Parent = bar
            local ks = Instance.new("UIStroke"); ks.Color = Color3.fromRGB(20, 20, 24); ks.Parent = knob
            local dragging = false
            local function paint()
                local c = get(); local h = typeof(c) == "Color3" and select(1, c:ToHSV()) or 0
                knob.Position = UDim2.new(h, 0, .5, 0)
            end
            local function fromX(x)
                local h = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
                set(Color3.fromHSV(h, 1, 1)); knob.Position = UDim2.new(h, 0, .5, 0)
            end
            bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; fromX(i.Position.X) end end)
            UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
            paint()
        end

        local function slider(label, get, set, min, max)
            local r, l = baseRow(label, 38)
            l.Size = UDim2.fromOffset(82, 38)
            local bar = Instance.new("Frame")
            bar.Position = UDim2.fromOffset(88, 16)
            bar.Size = UDim2.new(1, -143, 0, 6)
            bar.BackgroundColor3 = Color3.fromRGB(43, 44, 51)
            bar.BorderSizePixel = 0
            bar.Active = true
            bar.ZIndex = 103
            bar.Parent = r
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
            val.Parent = r
            rounded(val, 3)
            local initial = tonumber(get()) or min
            local fractional = (max - min) <= 2 or math.abs(initial - math.floor(initial)) > .001
            local step = fractional and .01 or 1
            local dragging = false
            local function paint()
                local n = math.clamp(tonumber(get()) or min, min, max)
                local a = (n - min) / math.max(max - min, 1e-6)
                fill.Size = UDim2.new(a, 0, 1, 0); knob.Position = UDim2.new(a, 0, .5, 0)
                val.Text = fractional and string.format("%.2f", n) or tostring(math.floor(n + .5))
            end
            local function fromX(x)
                local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
                local n = min + (max - min) * a
                n = math.floor(n / step + .5) * step
                set(math.clamp(n, min, max)); paint()
            end
            bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; fromX(i.Position.X) end end)
            knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; fromX(i.Position.X) end end)
            UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
            paint()
        end

        local function toggle(label, get, set)
            local r, l = baseRow(label)
            l.Size = UDim2.new(1, -50, 1, 0)
            local b = Instance.new("TextButton")
            b.AnchorPoint = Vector2.new(1, .5); b.Position = UDim2.new(1, -7, .5, 0); b.Size = UDim2.fromOffset(34, 18)
            b.Text = ""; b.BorderSizePixel = 0; b.AutoButtonColor = false; b.ZIndex = 103; b.Parent = r; rounded(b, 3)
            local function paint() b.BackgroundColor3 = get() and UI.Accent or Color3.fromRGB(48, 49, 57) end
            b.MouseButton1Click:Connect(function() set(not get()); paint() end); paint()
        end

        local function dropdown(label, values, get, set)
            local r, l = baseRow(label)
            l.Size = UDim2.new(1, -96, 1, 0)
            local b = Instance.new("TextButton")
            b.AnchorPoint = Vector2.new(1, .5); b.Position = UDim2.new(1, -7, .5, 0); b.Size = UDim2.fromOffset(82, 20)
            b.BackgroundColor3 = Color3.fromRGB(37, 38, 46); b.BorderSizePixel = 0; b.Font = Enum.Font.SourceSans; b.TextSize = 11; b.TextColor3 = Color3.fromRGB(225, 225, 232); b.ZIndex = 103; b.Parent = r; rounded(b, 3)
            local function paint() b.Text = tostring(get()) end
            b.MouseButton1Click:Connect(function() local i = table.find(values, get()) or 0; set(values[i % #values + 1]); paint() end); paint()
        end

        builder({ Color = color, Slider = slider, Toggle = toggle, Dropdown = dropdown })
        p.Size = UDim2.fromOffset(236, y + 3)
        if UI.OpenDockedPanel then UI.OpenDockedPanel(p) else p.Parent = UI.Gui end
    end

    local function visualToggle(label, get, set, builder)
        local f, t = UI.Row(page, label)
        t.Size = UDim2.new(1, -78, 1, 0)
        t.Active = true
        local dots = Instance.new("TextButton")
        dots.AnchorPoint = Vector2.new(1, .5); dots.Position = UDim2.new(1, -44, .5, 0); dots.Size = UDim2.fromOffset(26, 20)
        dots.BackgroundColor3 = Color3.fromRGB(34, 34, 40); dots.BorderSizePixel = 0; dots.Font = Enum.Font.SourceSansBold; dots.TextSize = 15; dots.TextColor3 = Color3.fromRGB(195, 195, 205); dots.Text = "•••"; dots.Parent = f; rounded(dots, 4)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(1, .5); b.Position = UDim2.new(1, -7, .5, 0); b.Size = UDim2.fromOffset(28, 18); b.Text = ""; b.BorderSizePixel = 0; b.AutoButtonColor = false; b.Parent = f; rounded(b, 3)
        local mark = Instance.new("Frame")
        mark.AnchorPoint = Vector2.new(.5, .5); mark.Position = UDim2.fromScale(.5, .5); mark.Size = UDim2.fromOffset(18, 10); mark.BorderSizePixel = 0; mark.Parent = b; rounded(mark, 2)
        local function paint()
            local on = get() == true
            b.BackgroundColor3 = on and UI.Accent or Color3.fromRGB(45, 45, 45)
            mark.BackgroundColor3 = on and Color3.fromRGB(238, 238, 240) or Color3.fromRGB(86, 86, 86)
        end
        local function flip() set(not get()); paint() end
        b.MouseButton1Click:Connect(flip)
        t.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then flip() end end)
        dots.MouseButton1Click:Connect(function() buildPopup(label, builder or function() end) end)
        table.insert(painters, paint); paint()
    end

    visualToggle("3D Box", function() return State.Visuals.Box3D end, function(v) State.Visuals.Box3D = v end, function(o)
        o.Color("Color", function() return cfg.Box3DColor end, function(v) cfg.Box3DColor = v end)
        o.Slider("Transparency", function() return cfg.Box3DTransparency end, function(v) cfg.Box3DTransparency = v end, 0, 100)
    end)
    visualToggle("Chams", function() return State.Visuals.Chams end, function(v) State.Visuals.Chams = v end, function(o)
        o.Color("Color", function() return cfg.ChamsColor end, function(v) cfg.ChamsColor = v end)
        o.Slider("Transparency", function() return cfg.ChamsTransparency end, function(v) cfg.ChamsTransparency = v end, 0, 100)
    end)
    visualToggle("Corner Box", function() return State.Visuals.CornerBox end, function(v) State.Visuals.CornerBox = v end, function(o)
        o.Color("Color", function() return cfg.CornerColor end, function(v) cfg.CornerColor = v end)
        o.Slider("Transparency", function() return cfg.CornerTransparency end, function(v) cfg.CornerTransparency = v end, 0, 100)
    end)
    visualToggle("ESP", function() return State.Visuals.ESP end, function(v) State.Visuals.ESP = v end, function(o)
        o.Toggle("Wall Check", function() return cfg.ESPWallCheck end, function(v) cfg.ESPWallCheck = v end)
        o.Color("Visible", function() return cfg.ESPVisibleColor end, function(v) cfg.ESPVisibleColor = v end)
        o.Color("Hidden", function() return cfg.ESPHiddenColor end, function(v) cfg.ESPHiddenColor = v end)
        o.Slider("Transparency", function() return cfg.ESPTransparency end, function(v) cfg.ESPTransparency = v end, 0, 100)
    end)

    local fovEnabled = false
    local originalFov = setmetatable({}, { __mode = "k" })
    visualToggle("FOVChanger", function() return fovEnabled end, function(v)
        fovEnabled = v
        local cam = Workspace.CurrentCamera
        if cam and not v and originalFov[cam] then cam.FieldOfView = originalFov[cam] end
    end, function(o)
        o.Slider("Field of View", function() return State.Visuals.FOV or 70 end, function(v) State.Visuals.FOV = v end, 40, 120)
    end)
    visualToggle("HealthBar", function() return State.Visuals.HealthBar end, function(v) State.Visuals.HealthBar = v end, function(o)
        o.Slider("Transparency", function() return cfg.HealthTransparency end, function(v) cfg.HealthTransparency = v end, 0, 100)
    end)
    visualToggle("Name + Distance", function() return State.Visuals.NameDistance end, function(v) State.Visuals.NameDistance = v end, function(o)
        o.Color("Color", function() return cfg.NameColor end, function(v) cfg.NameColor = v end)
        o.Slider("Transparency", function() return cfg.NameTransparency end, function(v) cfg.NameTransparency = v end, 0, 100)
    end)
    visualToggle("Preview", function() return State.Visuals.Preview end, function(v) State.Visuals.Preview = v end, function(o)
        o.Color("Accent", function() return cfg.PreviewAccent end, function(v) cfg.PreviewAccent = v end)
        o.Slider("Transparency", function() return cfg.PreviewTransparency end, function(v) cfg.PreviewTransparency = v end, 0, 100)
    end)
    visualToggle("Thermal Corner", function() return State.Visuals.ThermalCorner end, function(v) State.Visuals.ThermalCorner = v end, function(o)
        o.Color("Color", function() return cfg.ThermalColor end, function(v) cfg.ThermalColor = v end)
        o.Slider("Transparency", function() return cfg.ThermalTransparency end, function(v) cfg.ThermalTransparency = v end, 0, 100)
    end)
    visualToggle("Tracers", function() return State.Visuals.Tracers end, function(v) State.Visuals.Tracers = v end, function(o)
        o.Color("Color", function() return cfg.TracerColor end, function(v) cfg.TracerColor = v end)
        o.Slider("Transparency", function() return cfg.TracerTransparency end, function(v) cfg.TracerTransparency = v end, 0, 100)
        o.Dropdown("Origin", { "Bottom", "Top", "Mouse" }, function() return cfg.TracerOrigin end, function(v) cfg.TracerOrigin = v end)
    end)
    visualToggle("Skeleton", function() return State.Visuals.Skeleton end, function(v) State.Visuals.Skeleton = v end, function(o)
        o.Color("Color", function() return cfg.SkeletonColor end, function(v) cfg.SkeletonColor = v end)
        o.Slider("Transparency", function() return cfg.SkeletonTransparency end, function(v) cfg.SkeletonTransparency = v end, 0, 100)
    end)

    ------------------------------------------------------------------------
    -- Overlay primitives.
    ------------------------------------------------------------------------
    local gui = Instance.new("ScreenGui")
    gui.Name = "LvkHubUnifiedVisualsV5"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 998
    gui.Parent = parent

    local function line(name)
        local f = Instance.new("Frame")
        f.Name = name or "ESPLine"
        f.AnchorPoint = Vector2.new(.5, .5)
        f.BorderSizePixel = 0
        f.BackgroundColor3 = Color3.new(1, 1, 1)
        f.Visible = false
        f.Parent = gui
        return f
    end
    local function setLine(f, a, b, thickness, color, trans)
        if not f or not a or not b then if f then f.Visible = false end return end
        local d = b - a
        if d.Magnitude < .01 then f.Visible = false return end
        f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
        f.Size = UDim2.fromOffset(d.Magnitude, thickness or 1)
        f.Rotation = math.deg(math.atan2(d.Y, d.X))
        f.BackgroundColor3 = color
        f.BackgroundTransparency = math.clamp((trans or 0) / 100, 0, 1)
        f.Visible = true
    end
    local function hideLines(t) for _, x in ipairs(t) do x.Visible = false end end
    local function label(name)
        local t = Instance.new("TextLabel")
        t.Name = name or "ESPLabel"
        t.AnchorPoint = Vector2.new(.5, .5)
        t.BackgroundTransparency = 1
        t.Size = UDim2.fromOffset(220, 18)
        t.Font = Enum.Font.Code
        t.TextSize = 11
        t.TextStrokeTransparency = .25
        t.TextStrokeColor3 = Color3.new(0, 0, 0)
        t.Visible = false
        t.Parent = gui
        return t
    end

    local function healthColor(r)
        r = math.clamp(r, 0, 1)
        if r >= .5 then
            local t = (r - .5) / .5
            return Color3.new(1 - t, 1, 0)
        end
        local t = r / .5
        return Color3.new(1, t, 0)
    end

    local stores = setmetatable({}, { __mode = "k" })
    local function newStore(model)
        local s = { model = model }
        s.highlight = Instance.new("Highlight")
        s.highlight.Name = "LvkHubUnifiedV5Chams"
        s.highlight.Adornee = model
        s.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        s.highlight.Enabled = false
        s.highlight.Parent = model
        s.corner = {}; for i = 1, 8 do s.corner[i] = line("Corner" .. i) end
        s.box3d = {}; for i = 1, 12 do s.box3d[i] = line("Box3D" .. i) end
        s.skeleton = {}; for i = 1, 15 do s.skeleton[i] = line("Bone" .. i) end
        s.tracer = line("Tracer")
        s.name = label("Name")
        s.dist = label("Distance")
        s.healthBack = Instance.new("Frame")
        s.healthBack.BorderSizePixel = 0; s.healthBack.BackgroundColor3 = Color3.new(0, 0, 0); s.healthBack.Visible = false; s.healthBack.Parent = gui
        s.health = Instance.new("Frame")
        s.health.BorderSizePixel = 0; s.health.Visible = false; s.health.Parent = gui
        stores[model] = s
        return s
    end
    local function hideStore(s)
        s.highlight.Enabled = false
        hideLines(s.corner); hideLines(s.box3d); hideLines(s.skeleton)
        s.tracer.Visible = false; s.name.Visible = false; s.dist.Visible = false
        s.healthBack.Visible = false; s.health.Visible = false
    end
    local function destroyStore(model)
        local s = stores[model]; if not s then return end
        for _, v in pairs(s) do
            if typeof(v) == "Instance" then pcall(function() v:Destroy() end)
            elseif type(v) == "table" then for _, x in ipairs(v) do pcall(function() x:Destroy() end) end end
        end
        stores[model] = nil
    end

    local function validDummy(model)
        -- ALTERADO: aceita Players reais
        if not model or not model:IsA("Model") then return false end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character == model then return true end
        end
        return false
    end

    local function projectedBounds(model, cam)
        local root = Registry.RootOf(model); if not root then return nil end
        local rp, on = cam:WorldToViewportPoint(root.Position)
        if not on or rp.Z <= 0 then return nil end
        local ok, cf, size = pcall(function() return model:GetBoundingBox() end)
        if not ok then return nil end
        local hs = size / 2
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local points = {}; local allFront = true
        for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
            local wp = (cf * CFrame.new(hs.X * x, hs.Y * y, hs.Z * z)).Position
            local p = cam:WorldToViewportPoint(wp)
            local front = p.Z > 0; allFront = allFront and front
            table.insert(points, { screen = Vector2.new(p.X, p.Y), visible = front })
            if front then minX = math.min(minX, p.X); maxX = math.max(maxX, p.X); minY = math.min(minY, p.Y); maxY = math.max(maxY, p.Y) end
        end end end
        if not allFront or minX == math.huge then return nil end
        local w = math.clamp(maxX - minX, 8, cam.ViewportSize.X * 1.25)
        local h = math.clamp(maxY - minY, 12, cam.ViewportSize.Y * 1.25)
        return Vector2.new((minX + maxX) / 2, (minY + maxY) / 2), w, h, points
    end

    -- ESP visibility originates at the LocalPlayer's body. Camera position is not used.
    local function visibleFromPlayer(model, root)
        local ch = LP.Character
        local originPart = ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"))
        if not originPart or not root then return false end
        local origin = originPart.Position
        local dir = root.Position - origin
        if dir.Magnitude < .05 then return true end
        local ray = RaycastParams.new()
        ray.FilterType = Enum.RaycastFilterType.Exclude
        ray.FilterDescendantsInstances = { model, ch }
        ray.IgnoreWater = true
        return Workspace:Raycast(origin, dir, ray) == nil
    end

    local function updateCorners(lines, pos, w, h, color, trans)
        local l, r, t, b = pos.X - w / 2, pos.X + w / 2, pos.Y - h / 2, pos.Y + h / 2
        local cw, ch = w * .22, h * .22
        local p = {
            { Vector2.new(l, t), Vector2.new(l + cw, t) }, { Vector2.new(l, t), Vector2.new(l, t + ch) },
            { Vector2.new(r, t), Vector2.new(r - cw, t) }, { Vector2.new(r, t), Vector2.new(r, t + ch) },
            { Vector2.new(l, b), Vector2.new(l + cw, b) }, { Vector2.new(l, b), Vector2.new(l, b - ch) },
            { Vector2.new(r, b), Vector2.new(r - cw, b) }, { Vector2.new(r, b), Vector2.new(r, b - ch) },
        }
        for i, v in ipairs(p) do setLine(lines[i], v[1], v[2], 1, color, trans) end
    end

    local edges = { { 1, 2 }, { 2, 4 }, { 4, 3 }, { 3, 1 }, { 5, 6 }, { 6, 8 }, { 8, 7 }, { 7, 5 }, { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 } }
    local function update3D(lines, points, color, trans)
        for i, e in ipairs(edges) do
            local a, b = points[e[1]], points[e[2]]
            if a and b and a.visible and b.visible then setLine(lines[i], a.screen, b.screen, 1, color, trans) else lines[i].Visible = false end
        end
    end

    local bonesR15 = { { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" }, { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" }, { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" }, { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" }, { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" } }
    local bonesR6 = { { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" }, { "Torso", "Left Leg" }, { "Torso", "Right Leg" } }
    local function updateSkeleton(lines, model, cam, color, trans)
        hideLines(lines)
        local bones = model:FindFirstChild("UpperTorso") and bonesR15 or bonesR6
        for i, b in ipairs(bones) do
            local a = model:FindFirstChild(b[1]); local c = model:FindFirstChild(b[2])
            if a and c and a:IsA("BasePart") and c:IsA("BasePart") and lines[i] then
                local pa, va = cam:WorldToViewportPoint(a.Position); local pc, vc = cam:WorldToViewportPoint(c.Position)
                if va and vc and pa.Z > 0 and pc.Z > 0 then setLine(lines[i], Vector2.new(pa.X, pa.Y), Vector2.new(pc.X, pc.Y), 1, color, trans) end
            end
        end
    end

    local function tracerStart(cam)
        if cfg.TracerOrigin == "Top" then return Vector2.new(cam.ViewportSize.X / 2, 0) end
        if cfg.TracerOrigin == "Mouse" then local p = UIS:GetMouseLocation(); return Vector2.new(p.X, p.Y) end
        return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
    end

    ------------------------------------------------------------------------
    -- Draggable preview.
    ------------------------------------------------------------------------
    local preview = Instance.new("Frame")
    preview.Name = "LvkHubUnifiedPreviewV4"
    preview.Size = UDim2.fromOffset(252, 326)
    preview.Position = UDim2.fromOffset(18, 520)
    preview.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
    preview.BorderSizePixel = 0
    preview.Visible = false
    preview.ZIndex = 70
    preview.Parent = UI.Gui
    rounded(preview, 8)
    local pst = Instance.new("UIStroke"); pst.Color = Color3.fromRGB(70, 72, 88); pst.Transparency = .12; pst.Parent = preview
    local pHeader = Instance.new("Frame")
    pHeader.Name = "Header"; pHeader.Size = UDim2.new(1, 0, 0, 42); pHeader.BackgroundColor3 = Color3.fromRGB(20, 21, 27); pHeader.BorderSizePixel = 0; pHeader.ZIndex = 71; pHeader.Parent = preview; rounded(pHeader, 8)
    local pAccent = Instance.new("Frame")
    pAccent.Size = UDim2.fromOffset(3, 22); pAccent.Position = UDim2.fromOffset(8, 10); pAccent.BorderSizePixel = 0; pAccent.ZIndex = 72; pAccent.Parent = pHeader; rounded(pAccent, 2)
    local pTitle = Instance.new("TextLabel")
    pTitle.BackgroundTransparency = 1; pTitle.Position = UDim2.fromOffset(18, 3); pTitle.Size = UDim2.new(1, -26, 0, 20); pTitle.Font = Enum.Font.SourceSansSemibold; pTitle.TextSize = 14; pTitle.TextColor3 = Color3.fromRGB(238, 238, 242); pTitle.TextXAlignment = Enum.TextXAlignment.Left; pTitle.Text = "VISUALS PREVIEW"; pTitle.ZIndex = 72; pTitle.Parent = pHeader
    local pSub = Instance.new("TextLabel")
    pSub.BackgroundTransparency = 1; pSub.Position = UDim2.fromOffset(18, 21); pSub.Size = UDim2.new(1, -26, 0, 16); pSub.Font = Enum.Font.SourceSans; pSub.TextSize = 10; pSub.TextColor3 = Color3.fromRGB(135, 140, 158); pSub.TextXAlignment = Enum.TextXAlignment.Left; pSub.Text = "DRAG • LOCAL TEST TARGET"; pSub.ZIndex = 72; pSub.Parent = pHeader
    drag(preview, pHeader)

    local vp = Instance.new("ViewportFrame")
    vp.Position = UDim2.fromOffset(10, 50); vp.Size = UDim2.new(1, -20, 0, 208); vp.BackgroundColor3 = Color3.fromRGB(22, 23, 30); vp.BorderSizePixel = 0; vp.Ambient = Color3.fromRGB(200, 200, 210); vp.LightColor = Color3.fromRGB(255, 255, 255); vp.LightDirection = Vector3.new(-1, -1, -1); vp.ZIndex = 71; vp.Parent = preview; rounded(vp, 6)
    local wc = Instance.new("WorldModel"); wc.Parent = vp
    local pc = Instance.new("Camera"); pc.FieldOfView = 34; pc.Parent = vp; vp.CurrentCamera = pc
    local pName = Instance.new("TextLabel")
    pName.Position = UDim2.fromOffset(12, 265); pName.Size = UDim2.new(1, -24, 0, 20); pName.BackgroundTransparency = 1; pName.Font = Enum.Font.SourceSansSemibold; pName.TextSize = 13; pName.TextColor3 = Color3.fromRGB(235, 235, 240); pName.TextXAlignment = Enum.TextXAlignment.Left; pName.Text = "No test target"; pName.ZIndex = 72; pName.Parent = preview
    local pMeta = Instance.new("TextLabel")
    pMeta.Position = UDim2.fromOffset(12, 284); pMeta.Size = UDim2.new(1, -24, 0, 16); pMeta.BackgroundTransparency = 1; pMeta.Font = Enum.Font.Code; pMeta.TextSize = 10; pMeta.TextColor3 = Color3.fromRGB(150, 155, 170); pMeta.TextXAlignment = Enum.TextXAlignment.Left; pMeta.Text = "HP --  •  DIST --"; pMeta.ZIndex = 72; pMeta.Parent = preview
    local pHealthBack = Instance.new("Frame")
    pHealthBack.Position = UDim2.fromOffset(12, 305); pHealthBack.Size = UDim2.new(1, -24, 0, 7); pHealthBack.BackgroundColor3 = Color3.fromRGB(35, 36, 44); pHealthBack.BorderSizePixel = 0; pHealthBack.ZIndex = 72; pHealthBack.Parent = preview; rounded(pHealthBack, 4)
    local pHealth = Instance.new("Frame")
    pHealth.Size = UDim2.fromScale(1, 1); pHealth.BorderSizePixel = 0; pHealth.ZIndex = 73; pHealth.Parent = pHealthBack; rounded(pHealth, 4)

    local previewSource = nil
    local previewHighlight = nil
    local function clearPreviewWorld()
        for _, x in ipairs(wc:GetChildren()) do x:Destroy() end
        previewHighlight = nil
    end
    local function desiredPreviewTarget()
        if State.Combat and State.Combat.SelectedBot and Registry.IsBot(State.Combat.SelectedBot) then return State.Combat.SelectedBot end
        local list = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            local model = plr.Character
            if plr ~= LP and model and Registry.IsBot(model) then table.insert(list, model) end
        end
        table.sort(list, function(a, b) return a.Name < b.Name end)
        return list[1]
    end
    local function rebuildPreview(model)
        clearPreviewWorld(); previewSource = model
        if not model then return end
        local old = model.Archivable; model.Archivable = true
        local ok, clone = pcall(function() return model:Clone() end); model.Archivable = old
        if not ok or not clone then return end
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Tool") then d:Destroy()
            elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
        end
        clone.Parent = wc
        local ok2, cf, size = pcall(function() return clone:GetBoundingBox() end)
        if ok2 then
            clone:PivotTo(CFrame.new(0, size.Y * .5, 0) * cf.Rotation:Inverse())
            local d = math.max(7, math.max(size.X, size.Y, size.Z) * 2.15)
            pc.CFrame = CFrame.lookAt(Vector3.new(0, size.Y * .55, d), Vector3.new(0, size.Y * .5, 0))
        else pc.CFrame = CFrame.lookAt(Vector3.new(0, 1.5, 8), Vector3.new(0, 1.5, 0)) end
        previewHighlight = Instance.new("Highlight")
        previewHighlight.Adornee = clone; previewHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; previewHighlight.Parent = wc
    end

    ------------------------------------------------------------------------
    -- Vehicle ESP (controlled by Vehicle page state).
    ------------------------------------------------------------------------
    local cars = setmetatable({}, { __mode = "k" })
    local function carAnchor(m)
        return m:FindFirstChildWhichIsA("VehicleSeat", true) or m:FindFirstChild("Seat1", true) or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
    end
    local function ensureCar(m)
        if cars[m] and cars[m].h and cars[m].h.Parent then return cars[m] end
        local a = carAnchor(m); if not a then return nil end
        local h = Instance.new("Highlight")
        h.Name = "LvkHubCarESPV5"; h.Adornee = m; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Enabled = false; h.Parent = m
        local bb = Instance.new("BillboardGui")
        bb.Name = "LvkHubCarLabelV5"; bb.Adornee = a; bb.AlwaysOnTop = true; bb.MaxDistance = 0; bb.Size = UDim2.fromOffset(190, 26); bb.StudsOffsetWorldSpace = Vector3.new(0, 3, 0); bb.Enabled = false; bb.Parent = a
        local txt = Instance.new("TextLabel")
        txt.BackgroundTransparency = 1; txt.Size = UDim2.fromScale(1, 1); txt.Font = Enum.Font.GothamSemibold; txt.TextSize = 12; txt.TextStrokeTransparency = .35; txt.Parent = bb
        cars[m] = { h = h, bb = bb, t = txt, a = a }; return cars[m]
    end

    local carTimer = 0
    local previewTimer = 0
    local fovWas = false
    RunService.RenderStepped:Connect(function(dt)
        local cam = Workspace.CurrentCamera
        if not cam then return end

        for _, p in ipairs(painters) do p() end

        if originalFov[cam] == nil then originalFov[cam] = cam.FieldOfView end
        if fovEnabled then
            local wanted = math.clamp(State.Visuals.FOV or 70, 40, 120)
            if math.abs(cam.FieldOfView - wanted) > .01 then cam.FieldOfView = wanted end
        elseif fovWas and originalFov[cam] then cam.FieldOfView = originalFov[cam] end
        fovWas = fovEnabled

        preview.Visible = State.Visuals.Preview == true and UI.Main.Visible == true
        if preview.Visible then
            previewTimer = previewTimer + dt
            local target = desiredPreviewTarget()
            if target ~= previewSource or previewTimer >= 1 then previewTimer = 0; if target ~= previewSource then rebuildPreview(target) end end
            pAccent.BackgroundColor3 = cfg.PreviewAccent
            preview.BackgroundTransparency = math.clamp(cfg.PreviewTransparency / 100, .02, .96)
            if target and Registry.IsBot(target) then
                local hum = Registry.HumanoidOf(target); local root = Registry.RootOf(target)
                local ratio = hum and math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1) or 0
                local dist = root and (root.Position - cam.CFrame.Position).Magnitude or 0
                pName.Text = target.Name; pName.TextColor3 = cfg.NameColor; pName.TextTransparency = cfg.NameTransparency / 100
                pMeta.Text = string.format("HP %.0f/%.0f  •  %d studs", hum and hum.Health or 0, hum and hum.MaxHealth or 0, math.floor(dist + .5))
                pHealth.Size = UDim2.new(ratio, 0, 1, 0); pHealth.BackgroundColor3 = healthColor(ratio); pHealth.BackgroundTransparency = cfg.HealthTransparency / 100
                if previewHighlight then
                    previewHighlight.Enabled = State.Visuals.Chams or State.Visuals.ESP
                    local c = State.Visuals.ESP and cfg.ESPVisibleColor or cfg.ChamsColor
                    previewHighlight.FillColor = c; previewHighlight.OutlineColor = c
                    local tr = (State.Visuals.ESP and cfg.ESPTransparency or cfg.ChamsTransparency) / 100
                    previewHighlight.FillTransparency = math.clamp(tr, .08, .98); previewHighlight.OutlineTransparency = math.clamp(tr * .7, 0, .98)
                end
            else
                pName.Text = "No test target"; pMeta.Text = "HP --  •  DIST --"; pHealth.Size = UDim2.new(0, 0, 1, 0)
                if previewHighlight then previewHighlight.Enabled = false end
            end
        end

        local current = setmetatable({}, { __mode = "k" })
        -- ALTERADO: agora varre Players
        for _, plr in ipairs(Players:GetPlayers()) do
            local model = plr.Character
            if plr ~= LP and model and validDummy(model) then current[model] = true end
        end
        for m in pairs(stores) do if not current[m] then destroyStore(m) end end

        local any = State.Visuals.Box3D or State.Visuals.Chams or State.Visuals.CornerBox or State.Visuals.ESP or State.Visuals.HealthBar or State.Visuals.NameDistance or State.Visuals.ThermalCorner or State.Visuals.Tracers or State.Visuals.Skeleton
        local combatTargetActive = State.Combat and (State.Combat.Aimbot or State.Combat.SilentAim or State.Combat.MagicBullets or State.Combat.HitBoxes)
        local selected = State.Combat and State.Combat.SelectedBot or nil

        for model in pairs(current) do
            local s = stores[model] or newStore(model)
            if not any then hideStore(s) continue end
            local hum = Registry.HumanoidOf(model); local root = Registry.RootOf(model)
            local pos, w, h, points = projectedBounds(model, cam)
            local vis = visibleFromPlayer(model, root)
            local targeted = combatTargetActive and selected == model
            local espColor = targeted and UI.Accent or ((not cfg.ESPWallCheck or vis) and cfg.ESPVisibleColor or cfg.ESPHiddenColor)

            local chamsOn = State.Visuals.Chams or State.Visuals.ESP
            s.highlight.Enabled = chamsOn
            if chamsOn then
                local c = State.Visuals.ESP and espColor or cfg.ChamsColor
                local tr = (State.Visuals.ESP and cfg.ESPTransparency or cfg.ChamsTransparency) / 100
                s.highlight.FillColor = c; s.highlight.OutlineColor = c
                s.highlight.FillTransparency = math.clamp(tr, .05, .98); s.highlight.OutlineTransparency = math.clamp(tr * .7, 0, .98)
            end

            if not pos then
                hideLines(s.corner); hideLines(s.box3d); hideLines(s.skeleton); s.tracer.Visible = false; s.name.Visible = false; s.dist.Visible = false; s.healthBack.Visible = false; s.health.Visible = false
                continue
            end

            if State.Visuals.CornerBox or State.Visuals.ESP or State.Visuals.ThermalCorner then
                local c = State.Visuals.ESP and espColor or (State.Visuals.ThermalCorner and cfg.ThermalColor or cfg.CornerColor)
                local tr = State.Visuals.ESP and cfg.ESPTransparency or (State.Visuals.ThermalCorner and cfg.ThermalTransparency or cfg.CornerTransparency)
                updateCorners(s.corner, pos, w, h, c, tr)
            else hideLines(s.corner) end

            if State.Visuals.Box3D then update3D(s.box3d, points, cfg.Box3DColor, cfg.Box3DTransparency) else hideLines(s.box3d) end
            if State.Visuals.Skeleton then updateSkeleton(s.skeleton, model, cam, targeted and UI.Accent or cfg.SkeletonColor, cfg.SkeletonTransparency) else hideLines(s.skeleton) end
            if State.Visuals.Tracers then setLine(s.tracer, tracerStart(cam), pos, 1, targeted and UI.Accent or cfg.TracerColor, cfg.TracerTransparency) else s.tracer.Visible = false end

            if State.Visuals.NameDistance or State.Visuals.ESP then
                s.name.Position = UDim2.fromOffset(pos.X, pos.Y - h / 2 - 13); s.name.Text = model.Name; s.name.TextColor3 = State.Visuals.ESP and espColor or cfg.NameColor; s.name.TextTransparency = (State.Visuals.ESP and cfg.ESPTransparency or cfg.NameTransparency) / 100; s.name.Visible = true
                local dist = root and (root.Position - cam.CFrame.Position).Magnitude or 0
                s.dist.Position = UDim2.fromOffset(pos.X, pos.Y + h / 2 + 9); s.dist.Text = string.format("%d studs", math.floor(dist + .5)); s.dist.TextColor3 = s.name.TextColor3; s.dist.TextTransparency = s.name.TextTransparency; s.dist.Visible = true
            else s.name.Visible = false; s.dist.Visible = false end

            if (State.Visuals.HealthBar or State.Visuals.ESP) and hum then
                local ratio = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
                s.healthBack.Position = UDim2.fromOffset(pos.X - w / 2 - 7, pos.Y - h / 2); s.healthBack.Size = UDim2.fromOffset(4, h); s.healthBack.BackgroundTransparency = math.clamp(cfg.HealthTransparency / 100 + .2, 0, .95); s.healthBack.Visible = true
                s.health.Position = UDim2.fromOffset(pos.X - w / 2 - 6, pos.Y - h / 2 + h * (1 - ratio) + 1); s.health.Size = UDim2.fromOffset(2, math.max(0, h * ratio - 2)); s.health.BackgroundColor3 = healthColor(ratio); s.health.BackgroundTransparency = cfg.HealthTransparency / 100; s.health.Visible = true
            else s.healthBack.Visible = false; s.health.Visible = false end
        end

        carTimer = carTimer + dt
        if carTimer >= .45 then
            carTimer = 0
            local vf = Workspace:FindFirstChild("Vehicles")
            local live = setmetatable({}, { __mode = "k" })
            if vf then for _, m in ipairs(vf:GetChildren()) do if m:IsA("Model") then live[m] = true; ensureCar(m) end end end
            for m, s in pairs(cars) do if not live[m] or not m.Parent then if s.h then s.h:Destroy() end; if s.bb then s.bb:Destroy() end; cars[m] = nil end end
        end
        for m, s in pairs(cars) do
            local show = State.Visuals.CarESP == true and m.Parent ~= nil
            s.h.Enabled = show; s.bb.Enabled = show
            if show and s.a and s.a.Parent then
                local tr = cfg.CarTransparency / 100
                s.h.FillColor = cfg.CarColor; s.h.OutlineColor = cfg.CarColor; s.h.FillTransparency = math.clamp(tr, .05, .98); s.h.OutlineTransparency = math.clamp(tr * .5, 0, .98)
                s.t.TextColor3 = cfg.CarColor; s.t.TextTransparency = math.clamp(tr * .6, 0, .95)
                local dist = (s.a.Position - cam.CFrame.Position).Magnitude
                s.t.Text = string.format("%s  •  %d studs", m.Name:gsub("_", " "), math.floor(dist + .5))
            end
        end
    end)
end
