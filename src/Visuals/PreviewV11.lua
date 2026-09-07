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
    hint.Font = Enum.Font.SourceSans
