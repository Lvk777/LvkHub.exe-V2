-- Visuals Preview V11
-- Client-only preview. Clones a managed TestPlayer into a ViewportFrame and mirrors the target-overlay visuals.
-- ALTERADO: agora usa Players reais.
return function(State, Registry, UI)
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer

    local cfg = State.Visuals._V5Config or {}
    State.Visuals.PreviewHealth = tonumber(State.Visuals.PreviewHealth) or 100

    local function rounded(o, r)
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 5); c.Parent = o
    end

    for _, name in ipairs({ "LvkHubVisualsDummyPreview", "LvkHubUnifiedPreviewV3", "LvkHubUnifiedPreviewV4", "LvkHubUnifiedPreviewV5", "LvkHubVisualPreview" }) do
        local old = UI.Gui:FindFirstChild(name)
        if old then old:Destroy() end
    end

    local frame = Instance.new("Frame")
    frame.Name = "LvkHubVisualsDummyPreview"
    frame.Size = UDim2.fromOffset(270, 360)
    frame.Position = UDim2.fromOffset(1400, 220)
    frame.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 170
    frame.Parent = UI.Gui
    rounded(frame, 8)
    local fs = Instance.new("UIStroke"); fs.Color = Color3.fromRGB(58, 61, 76); fs.Transparency = .08; fs.Parent = frame

    local header = Instance.new("Frame")
    header.Name = "Header"; header.Size = UDim2.new(1, 0, 0, 42); header.BackgroundColor3 = Color3.fromRGB(19, 20, 27)
    header.BorderSizePixel = 0; header.Active = true; header.ZIndex = 171; header.Parent = frame; rounded(header, 8)
    local accent = Instance.new("Frame")
    accent.Position = UDim2.fromOffset(8, 10); accent.Size = UDim2.fromOffset(3, 22); accent.BackgroundColor3 = UI.Accent
    accent.BorderSizePixel = 0; accent.ZIndex = 172; accent.Parent = header; rounded(accent, 2)
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1; title.Position = UDim2.fromOffset(18, 3); title.Size = UDim2.new(1, -26, 0, 20)
    title.Font = Enum.Font.SourceSansSemibold; title.TextSize = 14; title.TextColor3 = Color3.fromRGB(240, 240, 244)
    title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = "VISUALS PREVIEW"; title.ZIndex = 172; title.Parent = header
    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1; sub.Position = UDim2.fromOffset(18, 21); sub.Size = UDim2.new(1, -26, 0, 16)
    sub.Font = Enum.Font.SourceSans; sub.TextSize = 10; sub.TextColor3 = Color3.fromRGB(137, 142, 160)
    sub.TextXAlignment = Enum.TextXAlignment.Left; sub.Text = "TARGET DUMMY / DRAG"; sub.ZIndex = 172; sub.Parent = header

    local vp = Instance.new("ViewportFrame")
    vp.Position = UDim2.fromOffset(10, 50); vp.Size = UDim2.new(1, -20, 0, 232); vp.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
    vp.BorderSizePixel = 0; vp.Ambient = Color3.fromRGB(205, 205, 216); vp.LightColor = Color3.fromRGB(255, 255, 255)
    vp.LightDirection = Vector3.new(-1, -1, -1); vp.ZIndex = 171; vp.Parent = frame; rounded(vp, 6)
    local vg = Instance.new("UIGradient")
    vg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 36, 48)),
        ColorSequenceKeypoint.new(.55, Color3.fromRGB(19, 20, 28)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 12, 17)),
    }); vg.Rotation = 90; vg.Parent = vp

    local world = Instance.new("WorldModel"); world.Parent = vp
    local cam = Instance.new("Camera"); cam.FieldOfView = 34; cam.Parent = vp; vp.CurrentCamera = cam

    local overlay = Instance.new("Frame")
    overlay.Position = vp.Position; overlay.Size = vp.Size; overlay.BackgroundTransparency = 1; overlay.ZIndex = 180; overlay.ClipsDescendants = true; overlay.Parent = frame

    local function line(name)
        local f = Instance.new("Frame")
        f.Name = name; f.AnchorPoint = Vector2.new(.5, .5); f.BorderSizePixel = 0; f.Visible = false; f.ZIndex = 182; f.Parent = overlay
        return f
    end
    local function setLine(f, a, b, w, color, trans)
        local d = b - a
        if d.Magnitude < .01 then f.Visible = false return end
        f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
        f.Size = UDim2.fromOffset(d.Magnitude, w or 1)
        f.Rotation = math.deg(math.atan2(d.Y, d.X))
        f.BackgroundColor3 = color
        f.BackgroundTransparency = math.clamp((trans or 0) / 100, 0, 1)
        f.Visible = true
    end
    local function hide(list) for _, x in ipairs(list) do x.Visible = false end end

    local corners = {}; for i = 1, 8 do corners[i] = line("Corner" .. i) end
    local box3d = {}; for i = 1, 12 do box3d[i] = line("Box3D" .. i) end
    local bones = {}; for i = 1, 5 do bones[i] = line("Bone" .. i) end
    local tracer = line("Tracer")
    local snap = line("Snapline")
    local cross = { line("CrossL"), line("CrossR"), line("CrossT"), line("CrossB") }

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1; nameLabel.Position = UDim2.fromOffset(45, 4); nameLabel.Size = UDim2.fromOffset(160, 18)
    nameLabel.Font = Enum.Font.Code; nameLabel.TextSize = 10; nameLabel.TextStrokeTransparency = .15; nameLabel.Text = "PREVIEW DUMMY"
    nameLabel.Visible = false; nameLabel.ZIndex = 183; nameLabel.Parent = overlay
    local distLabel = nameLabel:Clone(); distLabel.Position = UDim2.fromOffset(82, 208); distLabel.Size = UDim2.fromOffset(90, 16); distLabel.Text = "25 studs"; distLabel.Parent = overlay

    local hpBack = Instance.new("Frame")
    hpBack.Position = UDim2.fromOffset(42, 24); hpBack.Size = UDim2.fromOffset(4, 178); hpBack.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
    hpBack.BorderSizePixel = 0; hpBack.Visible = false; hpBack.ZIndex = 183; hpBack.Parent = overlay
    local hpFill = Instance.new("Frame")
    hpFill.AnchorPoint = Vector2.new(0, 1); hpFill.Position = UDim2.new(0, 0, 1, 0); hpFill.Size = UDim2.fromScale(1, 1)
    hpFill.BorderSizePixel = 0; hpFill.ZIndex = 184; hpFill.Parent = hpBack

    local info = Instance.new("TextLabel")
    info.Position = UDim2.fromOffset(12, 290); info.Size = UDim2.new(1, -24, 0, 19); info.BackgroundTransparency = 1
    info.Font = Enum.Font.SourceSansSemibold; info.TextSize = 12; info.TextColor3 = Color3.fromRGB(232, 232, 238)
    info.TextXAlignment = Enum.TextXAlignment.Left; info.Text = "PREVIEW DUMMY / HP 100%"; info.ZIndex = 172; info.Parent = frame
    local hpSlider = Instance.new("Frame")
    hpSlider.Position = UDim2.fromOffset(12, 319); hpSlider.Size = UDim2.new(1, -24, 0, 8); hpSlider.BackgroundColor3 = Color3.fromRGB(39, 40, 48)
    hpSlider.BorderSizePixel = 0; hpSlider.Active = true; hpSlider.ZIndex = 172; hpSlider.Parent = frame; rounded(hpSlider, 4)
    local hpSliderFill = Instance.new("Frame")
    hpSliderFill.Size = UDim2.fromScale(1, 1); hpSliderFill.BorderSizePixel = 0; hpSliderFill.ZIndex = 173; hpSliderFill.Parent = hpSlider; rounded(hpSliderFill, 4)
    local hint = Instance.new("TextLabel")
    hint.Position = UDim2.fromOffset(12, 331); hint.Size = UDim2.new(1, -24, 0, 17); hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.SourceSans; hint.TextSize = 9; hint.TextColor3 = Color3.fromRGB(128, 133, 149)
    hint.TextXAlignment = Enum.TextXAlignment.Left; hint.Text = "drag HP • mirrors enabled visuals"; hint.ZIndex = 172; hint.Parent = frame

    local function healthColor(r)
        r = math.clamp(r, 0, 1)
        if r >= .5 then local t = (r - .5) / .5; return Color3.new(1 - t, 1, 0) end
        return Color3.new(1, r / .5, 0)
    end

    local draggingHP = false
    local function hpFromX(x)
        local a = math.clamp((x - hpSlider.AbsolutePosition.X) / math.max(1, hpSlider.AbsoluteSize.X), 0, 1)
        State.Visuals.PreviewHealth = math.floor(a * 100 + .5)
    end
    hpSlider.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingHP = true; hpFromX(i.Position.X) end end)
    UIS.InputChanged:Connect(function(i) if draggingHP and i.UserInputType == Enum.UserInputType.MouseMovement then hpFromX(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingHP = false end end)

    local dragging = false
    local startMouse, startPos
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; startMouse = i.Position; startPos = frame.Position end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - startMouse
            local v = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            local x = math.clamp(startPos.X.Offset + d.X, 0, math.max(0, v.X - frame.AbsoluteSize.X))
            local y = math.clamp(startPos.Y.Offset + d.Y, 0, math.max(0, v.Y - 38))
            frame.Position = UDim2.fromOffset(x, y)
        end
    end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    local previewSource = nil
    local previewModel = nil
    local previewHighlight = nil

    local function desiredTarget()
        local selected = State.Combat and State.Combat.SelectedBot
        if selected and Registry.IsBot(selected) then return selected end
        local list = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            local model = plr.Character
            if plr ~= LP and model and Registry.IsBot(model) then table.insert(list, model) end
        end
        table.sort(list, function(a, b) return a.Name < b.Name end)
        return list[1]
    end

    local function clearWorld()
        for _, x in ipairs(world:GetChildren()) do x:Destroy() end
        previewModel = nil; previewHighlight = nil
    end

    local function rebuild(model)
        clearWorld()
        previewSource = model
        if not model then return end
        local old = model.Archivable
        model.Archivable = true
        local ok, clone = pcall(function() return model:Clone() end)
        model.Archivable = old
        if not ok or not clone then return end
        clone.Name = "LvkHubPreviewAvatar"
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Tool") or d:IsA("Highlight") then
                d:Destroy()
            elseif d:IsA("BasePart") then
                d.Anchored = true; d.CanCollide = false; d.CanTouch = false; d.CastShadow = false
            end
        end
        clone.Parent = world
        previewModel = clone
        local okBox, cf, size = pcall(function() return clone:GetBoundingBox() end)
        if okBox then
            clone:PivotTo(CFrame.new(0, -cf.Position.Y + size.Y * .5, 0))
            local maxSize = math.max(size.X, size.Y, size.Z)
            local center = Vector3.new(0, size.Y * .47, 0)
            cam.CFrame = CFrame.lookAt(Vector3.new(0, size.Y * .50, math.max(6.8, maxSize * 1.75)), center)
        else
            cam.CFrame = CFrame.lookAt(Vector3.new(0, 2.5, 8), Vector3.new(0, 2.5, 0))
        end
        previewHighlight = Instance.new("Highlight")
        previewHighlight.Name = "LvkHubPreviewChams"
        previewHighlight.Adornee = clone
        previewHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        previewHighlight.Parent = world
    end

    local function cornerBox(color, trans)
        local l, r, t, b = 53, 197, 22, 207
        local cw, ch = 31, 39
        local pairs = {
            { Vector2.new(l, t), Vector2.new(l + cw, t) }, { Vector2.new(l, t), Vector2.new(l, t + ch) },
            { Vector2.new(r, t), Vector2.new(r - cw, t) }, { Vector2.new(r, t), Vector2.new(r, t + ch) },
            { Vector2.new(l, b), Vector2.new(l + cw, b) }, { Vector2.new(l, b), Vector2.new(l, b - ch) },
            { Vector2.new(r, b), Vector2.new(r - cw, b) }, { Vector2.new(r, b), Vector2.new(r, b - ch) },
        }
        for i, p in ipairs(pairs) do setLine(corners[i], p[1], p[2], 1, color, trans) end
    end

    local function box3D(color, trans)
        local a = { Vector2.new(62, 31), Vector2.new(190, 31), Vector2.new(190, 199), Vector2.new(62, 199) }
        local b = { Vector2.new(52, 22), Vector2.new(180, 22), Vector2.new(180, 190), Vector2.new(52, 190) }
        local edges = { { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 } }
        local idx = 1
        for _, e in ipairs(edges) do setLine(box3d[idx], a[e[1]], a[e[2]], 1, color, trans); idx = idx + 1 end
        for _, e in ipairs(edges) do setLine(box3d[idx], b[e[1]], b[e[2]], 1, color, trans); idx = idx + 1 end
        for i = 1, 4 do setLine(box3d[idx], a[i], b[i], 1, color, trans); idx = idx + 1 end
    end

    local lastTarget = nil
    local targetTimer = 0
    RunService.RenderStepped:Connect(function(dt)
        frame.Visible = State.Visuals.Preview == true and UI.Main.Visible == true
        if not frame.Visible then return end

        targetTimer = targetTimer + dt
        local target = desiredTarget()
        if target ~= lastTarget or targetTimer > .8 then
            targetTimer = 0
            if target ~= lastTarget then rebuild(target); lastTarget = target end
        end

        local hp = math.clamp((tonumber(State.Visuals.PreviewHealth) or 100) / 100, 0, 1)
        local hpc = healthColor(hp)
        info.Text = string.format("%s / HP %d%%", target and target.Name or "PREVIEW DUMMY", math.floor(hp * 100 + .5))
        hpSliderFill.Size = UDim2.new(hp, 0, 1, 0); hpSliderFill.BackgroundColor3 = hpc

        local esp = State.Visuals.ESP == true
        local targetBlue = UI.Accent
        local espColor = cfg.ESPVisibleColor or Color3.fromRGB(55, 235, 95)
        local chamsColor = esp and espColor or (cfg.ChamsColor or UI.Accent)

        if previewHighlight then
            previewHighlight.Enabled = (State.Visuals.Chams == true or esp)
            previewHighlight.FillColor = chamsColor
            previewHighlight.OutlineColor = chamsColor
            previewHighlight.FillTransparency = math.clamp((cfg.ChamsTransparency or 62) / 100, 0, 1)
            previewHighlight.OutlineTransparency = .05
        end

        if State.Visuals.Box3D then box3D(cfg.Box3DColor or UI.Accent, cfg.Box3DTransparency or 0) else hide(box3d) end

        local cornersOn = State.Visuals.CornerBox or esp or State.Visuals.ThermalCorner
        if cornersOn then
            local col = esp and espColor or (State.Visuals.ThermalCorner and (cfg.ThermalColor or Color3.fromRGB(255, 145, 60)) or (cfg.CornerColor or Color3.new(1, 1, 1)))
            local tr = esp and (cfg.ESPTransparency or 0) or (cfg.CornerTransparency or 0)
            cornerBox(col, tr)
        else hide(corners) end

        nameLabel.Visible = State.Visuals.NameDistance == true or esp
        distLabel.Visible = nameLabel.Visible
        if nameLabel.Visible then
            local col = esp and espColor or (cfg.NameColor or Color3.new(1, 1, 1))
            nameLabel.Text = target and target.Name or "PREVIEW DUMMY"
            nameLabel.TextColor3 = col; distLabel.TextColor3 = col
        end

        hpBack.Visible = State.Visuals.HealthBar == true or esp
        if hpBack.Visible then
            hpFill.Size = UDim2.new(1, 0, hp, 0); hpFill.BackgroundColor3 = hpc
        end

        if State.Visuals.Tracers then
            local origin = cfg.TracerOrigin or "Bottom"
            local from = origin == "Top" and Vector2.new(125, 0) or (origin == "Mouse" and Vector2.new(42, 116) or Vector2.new(125, 232))
            setLine(tracer, from, Vector2.new(125, 116), 1, cfg.TracerColor or Color3.new(1, 1, 1), cfg.TracerTransparency or 0)
        else tracer.Visible = false end

        if State.Visuals.Snapline then
            setLine(snap, Vector2.new(125, 232), Vector2.new(125, 116), 1, cfg.SnapColor or targetBlue, cfg.SnapTransparency or 0)
        else snap.Visible = false end

        if State.Visuals.CustomCrosshair then
            local c = Vector2.new(125, 116); local g = 6; local s = 8; local col = cfg.CrossColor or Color3.new(1, 1, 1); local tr = cfg.CrossTransparency or 0
            setLine(cross[1], Vector2.new(c.X - g - s, c.Y), Vector2.new(c.X - g, c.Y), 1, col, tr)
            setLine(cross[2], Vector2.new(c.X + g, c.Y), Vector2.new(c.X + g + s, c.Y), 1, col, tr)
            setLine(cross[3], Vector2.new(c.X, c.Y - g - s), Vector2.new(c.X, c.Y - g), 1, col, tr)
            setLine(cross[4], Vector2.new(c.X, c.Y + g), Vector2.new(c.X, c.Y + g + s), 1, col, tr)
        else hide(cross) end

        if State.Visuals.Skeleton then
            local c = cfg.SkeletonColor or Color3.new(1, 1, 1); local tr = cfg.SkeletonTransparency or 0
            local pts = { Vector2.new(125, 54), Vector2.new(125, 103), Vector2.new(86, 121), Vector2.new(164, 121), Vector2.new(103, 180), Vector2.new(147, 180) }
            setLine(bones[1], pts[1], pts[2], 1, c, tr); setLine(bones[2], pts[2], pts[3], 1, c, tr)
            setLine(bones[3], pts[2], pts[4], 1, c, tr); setLine(bones[4], pts[2], pts[5], 1, c, tr); setLine(bones[5], pts[2], pts[6], 1, c, tr)
        else hide(bones) end
    end)
end
