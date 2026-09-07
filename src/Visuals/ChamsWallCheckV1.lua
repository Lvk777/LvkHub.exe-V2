-- Chams wall-check/color owner for managed TestPlayers only.
-- IMPORTANT: this module is the ONLY final color owner for LvkHubUnifiedV5Chams.
-- Visibility is sampled at a fixed cadence and debounced to avoid red/green flicker
-- when a dummy is close to a wall/door edge.
-- ALTERADO: agora aceita Players reais.
return function(State, Registry, UI)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local UIS = game:GetService("UserInputService")
    local LP = Players.LocalPlayer

    local cfg = State.Visuals._V5Config or {}
    cfg.ChamsWallCheck = cfg.ChamsWallCheck ~= false
    cfg.ChamsColor = cfg.ChamsColor or Color3.fromRGB(55, 235, 95)
    cfg.ChamsHiddenColor = cfg.ChamsHiddenColor or Color3.fromRGB(245, 65, 65)
    State.Visuals._V5Config = cfg

    local rainbow = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    })

    local function round(o, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 4)
        c.Parent = o
    end

    ----------------------------------------------------------------------
    -- Stable character-origin wall check.
    ----------------------------------------------------------------------
    local function originPart()
        local ch = LP.Character
        return ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChildWhichIsA("BasePart")) or nil
    end

    local function rawVisibleFromCharacter(model)
        if not model or not Registry.IsBot(model) then return false end
        local origin = originPart()
        if not origin then return false end

        local samples = {
            model:FindFirstChild("Head"),
            model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso"),
            model:FindFirstChild("HumanoidRootPart"),
        }

        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local ex = { model }
        if LP.Character then table.insert(ex, LP.Character) end
        local cam = Workspace.CurrentCamera
        if cam then table.insert(ex, cam) end
        rp.FilterDescendantsInstances = ex
        rp.IgnoreWater = true

        -- If any representative body point is genuinely exposed from the
        -- character, consider the dummy visible. This is much more stable than
        -- testing only the head every render frame.
        for _, target in ipairs(samples) do
            if target and target:IsA("BasePart") then
                local dir = target.Position - origin.Position
                if dir.Magnitude < .05 or Workspace:Raycast(origin.Position, dir, rp) == nil then
                    return true
                end
            end
        end
        return false
    end

    local visibility = setmetatable({}, { __mode = "k" })
    local SAMPLE_INTERVAL = .10
    local REQUIRED_MATCHES = 2

    local function sampleVisibility(model)
        local raw = rawVisibleFromCharacter(model)
        local s = visibility[model]
        if not s then
            s = { stable = raw, candidate = raw, count = 0 }
            visibility[model] = s
            return raw
        end

        if raw == s.stable then
            s.candidate = raw
            s.count = 0
        elseif raw == s.candidate then
            s.count = s.count + 1
            if s.count >= REQUIRED_MATCHES then
                s.stable = raw
                s.count = 0
            end
        else
            s.candidate = raw
            s.count = 1
        end
        return s.stable
    end

    local function stableVisible(model)
        local s = visibility[model]
        if s then return s.stable end
        return sampleVisibility(model)
    end

    local function combatFocus(model)
        return State.Combat
            and State.Combat.SelectedBot == model
            and (State.Combat.Aimbot or State.Combat.SilentAim or State.Combat.MagicBullets or State.Combat.HitBoxes)
    end

    local function chamsColor(model)
        if combatFocus(model) then return UI.Accent end
        if cfg.ChamsWallCheck then
            return stableVisible(model) and cfg.ChamsColor or cfg.ChamsHiddenColor
        end
        return cfg.ChamsColor
    end

    shared.LvkHubDummyChamsVisibleFromCharacter = stableVisible
    shared.LvkHubDummyChamsColor = chamsColor

    ----------------------------------------------------------------------
    -- Extend the existing Chams ••• popup instead of creating a second row.
    ----------------------------------------------------------------------
    local patched = setmetatable({}, { __mode = "k" })

    local function addToggle(panel, y, label, get, set)
        local r = Instance.new("Frame")
        r.Position = UDim2.fromOffset(7, y)
        r.Size = UDim2.new(1, -14, 0, 31)
        r.BackgroundColor3 = Color3.fromRGB(27, 28, 34)
        r.BorderSizePixel = 0
        r.ZIndex = 160
        r.Parent = panel
        round(r, 4)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Position = UDim2.fromOffset(8, 0)
        l.Size = UDim2.new(1, -50, 1, 0)
        l.Font = Enum.Font.SourceSans
        l.TextSize = 12
        l.TextColor3 = Color3.fromRGB(222, 222, 228)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = label
        l.ZIndex = 161
        l.Parent = r
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(1, .5)
        b.Position = UDim2.new(1, -7, .5, 0)
        b.Size = UDim2.fromOffset(34, 18)
        b.Text = ""
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.ZIndex = 162
        b.Parent = r
        round(b, 3)
        local function paint() b.BackgroundColor3 = get() and UI.Accent or Color3.fromRGB(48, 49, 57) end
        b.MouseButton1Click:Connect(function() set(not get()); paint() end)
        paint()
        return y + 36
    end

    local function addColor(panel, y, label, get, set)
        local r = Instance.new("Frame")
        r.Position = UDim2.fromOffset(7, y)
        r.Size = UDim2.new(1, -14, 0, 38)
        r.BackgroundColor3 = Color3.fromRGB(27, 28, 34)
        r.BorderSizePixel = 0
        r.ZIndex = 160
        r.Parent = panel
        round(r, 4)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Position = UDim2.fromOffset(8, 0)
        l.Size = UDim2.fromOffset(74, 38)
        l.Font = Enum.Font.SourceSans
        l.TextSize = 12
        l.TextColor3 = Color3.fromRGB(222, 222, 228)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = label
        l.ZIndex = 161
        l.Parent = r
        local bar = Instance.new("Frame")
        bar.Position = UDim2.fromOffset(80, 11)
        bar.Size = UDim2.new(1, -90, 0, 16)
        bar.BackgroundColor3 = Color3.new(1, 1, 1)
        bar.BorderSizePixel = 0
        bar.Active = true
        bar.ZIndex = 162
        bar.Parent = r
        round(bar, 4)
        local g = Instance.new("UIGradient"); g.Color = rainbow; g.Parent = bar
        local k = Instance.new("Frame")
        k.AnchorPoint = Vector2.new(.5, .5)
        k.Size = UDim2.fromOffset(4, 22)
        k.BackgroundColor3 = Color3.fromRGB(248, 248, 250)
        k.BorderSizePixel = 0
        k.ZIndex = 163
        k.Parent = bar
        local dragging = false
        local function paint()
            local c = get()
            local h = typeof(c) == "Color3" and select(1, c:ToHSV()) or 0
            k.Position = UDim2.new(h, 0, .5, 0)
        end
        local function fromX(x)
            local h = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
            set(Color3.fromHSV(h, 1, 1)); paint()
        end
        bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; fromX(i.Position.X) end end)
        UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        paint()
        return y + 43
    end

    local function patchPopup(panel)
        if not panel or patched[panel] then return end
        local title = nil
        for _, c in ipairs(panel:GetChildren()) do
            if c:IsA("TextLabel") and c.Position.Y.Offset <= 8 then title = c break end
        end
        if not title or title.Text ~= "Chams" then return end
        patched[panel] = true
        panel:SetAttribute("LvkHubChamsWallCheckPatched", true)

        local nextY = 39
        for _, c in ipairs(panel:GetChildren()) do
            if c:IsA("Frame") and c.Position.Y.Offset >= 39 then
                nextY = math.max(nextY, c.Position.Y.Offset + c.Size.Y.Offset + 5)
                local l = c:FindFirstChildWhichIsA("TextLabel")
                if l and l.Text == "Color" then l.Text = "Visible" end
            end
        end
        nextY = addToggle(panel, nextY, "Wall Check", function() return cfg.ChamsWallCheck end, function(v)
            cfg.ChamsWallCheck = v
            table.clear(visibility)
        end)
        nextY = addColor(panel, nextY, "Hidden", function() return cfg.ChamsHiddenColor end, function(v) cfg.ChamsHiddenColor = v end)
        panel.Size = UDim2.fromOffset(panel.Size.X.Offset, math.max(panel.Size.Y.Offset, nextY + 3))
    end

    ----------------------------------------------------------------------
    -- Single final Chams owner.
    ----------------------------------------------------------------------
    local sampleTimer = 0
    local popupTimer = 0
    RunService.RenderStepped:Connect(function(dt)
        sampleTimer = sampleTimer + dt
        popupTimer = popupTimer + dt

        if popupTimer >= .10 then
            popupTimer = 0
            patchPopup(UI.ActiveDockedPanel)
        end

        if sampleTimer >= SAMPLE_INTERVAL then
            sampleTimer = 0
            for _, plr in ipairs(Players:GetPlayers()) do
                local model = plr.Character
                if model and Registry.IsBot(model) then sampleVisibility(model) else visibility[model] = nil end
            end
        end

        -- UnifiedTestVisualsV5 owns creation/enabling. This module only owns the
        -- FINAL Chams color when Chams itself is enabled. It intentionally does
        -- not scan/modify preview, self, gun, car, or old Highlight instances.
        if State.Visuals.Chams ~= true then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            local model = plr.Character
            if model and Registry.IsBot(model) then
                local h = model:FindFirstChild("LvkHubUnifiedV5Chams")
                if h and h:IsA("Highlight") then
                    local color = chamsColor(model)
                    h.Enabled = true
                    h.FillColor = color
                    h.OutlineColor = color
                    h.FillTransparency = math.clamp((cfg.ChamsTransparency or 62) / 100, 0, 1)
                end
            end
        end
    end)
end
