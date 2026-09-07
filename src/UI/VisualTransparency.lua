-- Adds draggable transparency sliders to Visuals ••• panels and applies them to local practice overlays.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")

    local T=State.Visuals._Transparency or {}
    State.Visuals._Transparency=T
    local titles={
        ["3D Box"]="Box3D", ["Chams"]="Chams", ["Corner Box"]="CornerBox",
        ["ESP"]="ESP", ["HealthBar"]="HealthBar", ["Name + Distance"]="NameDistance",
        ["Preview"]="Preview", ["Thermal Corner"]="ThermalCorner", ["Tracers"]="Tracers",
        ["Skeleton"]="Skeleton", ["Car ESP"]="CarESP",
    }
    for _,k in pairs(titles) do if T[k]==nil then T[k]=0 end end

    local function rounded(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 4); c.Parent=o end
    local function popupTitle(p)
        for _,d in ipairs(p:GetDescendants()) do
            if d:IsA("TextLabel") and titles[d.Text] then return d.Text end
        end
    end

    local function addSlider(p,key)
        if p:FindFirstChild("LvkTransparencyRow",true) then return end
        local body=nil
        for _,d in ipairs(p:GetChildren()) do if d:IsA("Frame") and d:FindFirstChildOfClass("UIListLayout") then body=d break end end
        if not body then return end
        local row=Instance.new("Frame"); row.Name="LvkTransparencyRow"; row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=Color3.fromRGB(27,28,34); row.BorderSizePixel=0; row.ZIndex=75; row.Parent=body; rounded(row,4)
        local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Position=UDim2.fromOffset(8,0); l.Size=UDim2.fromOffset(72,32); l.Font=Enum.Font.SourceSans; l.TextSize=12; l.TextColor3=Color3.fromRGB(222,222,228); l.TextXAlignment=Enum.TextXAlignment.Left; l.Text="Transparency"; l.ZIndex=76; l.Parent=row
        local bar=Instance.new("Frame"); bar.Position=UDim2.fromOffset(84,12); bar.Size=UDim2.new(1,-94,0,8); bar.BackgroundColor3=Color3.fromRGB(45,46,54); bar.BorderSizePixel=0; bar.Active=true; bar.ZIndex=76; bar.Parent=row; rounded(bar,4)
        local fill=Instance.new("Frame"); fill.BackgroundColor3=UI.Accent; fill.BorderSizePixel=0; fill.ZIndex=77; fill.Parent=bar; rounded(fill,4)
        local knob=Instance.new("Frame"); knob.AnchorPoint=Vector2.new(.5,.5); knob.Size=UDim2.fromOffset(12,12); knob.BackgroundColor3=Color3.fromRGB(245,245,248); knob.BorderSizePixel=0; knob.ZIndex=78; knob.Parent=bar; rounded(knob,6)
        local drag=false
        local function sync() local x=math.clamp((T[key] or 0)/100,0,1); fill.Size=UDim2.new(x,0,1,0); knob.Position=UDim2.new(x,0,.5,0) end
        local function setX(x) T[key]=math.floor(math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)*100+.5); sync() end
        bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; setX(i.Position.X) end end)
        UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then setX(i.Position.X) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
        sync()
    end

    local function inspectPanel()
        local p=UI.ActiveDockedPanel
        if not p or not p.Parent or p.Name~="VisualSettingsPopupV4" then return end
        local title=popupTitle(p); local key=title and titles[title]
        if key then addSlider(p,key) end
    end

    local function a(key) return math.clamp((T[key] or 0)/100,0,1) end
    local function starts(s,p) return s:sub(1,#p)==p end
    local timer=0
    RunService.RenderStepped:Connect(function(dt)
        timer+=dt
        if timer<.10 then return end
        timer=0
        inspectPanel()

        local overlay=UI.Gui.Parent and UI.Gui.Parent:FindFirstChild("LvkHubUnifiedVisualsV4")
        if overlay then
            for _,d in ipairs(overlay:GetDescendants()) do
                if d:IsA("Frame") then
                    if starts(d.Name,"Box3D") then d.BackgroundTransparency=a("Box3D")
                    elseif starts(d.Name,"Corner") then
                        local key=State.Visuals.ESP and "ESP" or (State.Visuals.ThermalCorner and "ThermalCorner" or "CornerBox")
                        d.BackgroundTransparency=a(key)
                    elseif starts(d.Name,"Bone") then d.BackgroundTransparency=a("Skeleton")
                    elseif d.Name=="Tracer" then d.BackgroundTransparency=a("Tracers")
                    elseif d.Name=="HealthBack" or d.Name=="HealthFill" then d.BackgroundTransparency=a(State.Visuals.ESP and "ESP" or "HealthBar") end
                elseif d:IsA("TextLabel") and (d.Name=="Name" or d.Name=="Distance") then
                    d.TextTransparency=a(State.Visuals.ESP and "ESP" or "NameDistance")
                end
            end
        end

        local tf=Workspace:FindFirstChild("TestPlayers")
        if tf then
            for _,m in ipairs(tf:GetChildren()) do
                if Registry.IsBot(m) then
                    local h=m:FindFirstChild("LvkHubUnifiedV4Chams")
                    if h and h:IsA("Highlight") then
                        local x=a(State.Visuals.ESP and "ESP" or "Chams")
                        h.FillTransparency=math.clamp(.58+x*.4,0,1)
                        h.OutlineTransparency=x
                    end
                end
            end
        end

        local vf=Workspace:FindFirstChild("Vehicles")
        if vf then
            for _,m in ipairs(vf:GetChildren()) do
                local h=m:FindFirstChild("LvkHubCarESPV4",true)
                if h and h:IsA("Highlight") then local x=a("CarESP"); h.FillTransparency=math.clamp(.82+x*.18,0,1); h.OutlineTransparency=x end
                local bb=m:FindFirstChild("LvkHubCarLabelV4",true)
                if bb then local txt=bb:FindFirstChildWhichIsA("TextLabel",true); if txt then txt.TextTransparency=a("CarESP") end end
            end
        end

        local preview=UI.Gui:FindFirstChild("LvkHubUnifiedPreviewV4")
        if preview then preview.BackgroundTransparency=math.min(.92,a("Preview")) end
    end)
end
