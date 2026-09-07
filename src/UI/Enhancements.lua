-- UI additions: Vehicle window + one stable draggable options panel below Combat.
return function(State, UI)
    local UIS=game:GetService("UserInputService")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")

    local function rounded(obj,r)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,r or 4)
        c.Parent=obj
    end

    ------------------------------------------------------------------------
    -- Vehicle window.
    ------------------------------------------------------------------------
    if not UI.Pages.Vehicle then
        local main=UI.Main
        local win=Instance.new("Frame")
        win.Name="VehicleWindow"
        win.Size=UDim2.fromOffset(220,37)
        win.Position=UDim2.fromOffset(16+6*230,55)
        win.BackgroundColor3=UI.Colors.Background
        win.BorderSizePixel=0
        win.ClipsDescendants=false
        win.Parent=main
        rounded(win,5)
        local stroke=Instance.new("UIStroke")
        stroke.Color=Color3.fromRGB(32,35,36)
        stroke.Parent=win

        local header=Instance.new("Frame")
        header.Name="Header"
        header.Size=UDim2.new(1,0,0,37)
        header.BackgroundColor3=UI.Colors.Background
        header.BorderSizePixel=0
        header.Active=true
        header.Parent=win
        rounded(header,5)

        local stripe=Instance.new("Frame")
        stripe.Size=UDim2.fromOffset(3,19)
        stripe.Position=UDim2.fromOffset(7,9)
        stripe.BorderSizePixel=0
        stripe.BackgroundColor3=UI.Accent
        stripe.Parent=header
        rounded(stripe,2)

        local title=Instance.new("TextLabel")
        title.BackgroundTransparency=1
        title.Position=UDim2.fromOffset(16,0)
        title.Size=UDim2.new(1,-48,1,0)
        title.Font=Enum.Font.SourceSansSemibold
        title.TextSize=16
        title.TextColor3=Color3.fromRGB(210,210,210)
        title.TextXAlignment=Enum.TextXAlignment.Left
        title.Text="Vehicle"
        title.Parent=header

        local arrow=Instance.new("TextButton")
        arrow.AnchorPoint=Vector2.new(1,.5)
        arrow.Position=UDim2.new(1,-8,.5,0)
        arrow.Size=UDim2.fromOffset(24,24)
        arrow.BackgroundTransparency=1
        arrow.BorderSizePixel=0
        arrow.Font=Enum.Font.SourceSansBold
        arrow.TextSize=17
        arrow.TextColor3=UI.Colors.Muted
        arrow.Text="▼"
        arrow.Parent=header

        local page=Instance.new("ScrollingFrame")
        page.Name="Vehicle"
        page.Position=UDim2.fromOffset(0,37)
        page.Size=UDim2.new(1,0,0,0)
        page.BackgroundColor3=UI.Colors.Background
        page.BorderSizePixel=0
        page.ScrollBarThickness=2
        page.ScrollBarImageColor3=UI.Accent
        page.AutomaticCanvasSize=Enum.AutomaticSize.Y
        page.CanvasSize=UDim2.new()
        page.Parent=win

        local pad=Instance.new("UIPadding")
        pad.PaddingTop=UDim.new(0,5)
        pad.PaddingBottom=UDim.new(0,5)
        pad.PaddingLeft=UDim.new(0,5)
        pad.PaddingRight=UDim.new(0,5)
        pad.Parent=page

        local list=Instance.new("UIListLayout")
        list.Padding=UDim.new(0,3)
        list.SortOrder=Enum.SortOrder.LayoutOrder
        list.Parent=page

        local expanded=true
        local function resize()
            if not expanded then
                page.Size=UDim2.new(1,0,0,0)
                win.Size=UDim2.fromOffset(220,37)
                return
            end
            local h=math.clamp(list.AbsoluteContentSize.Y+10,0,430)
            page.Size=UDim2.new(1,0,0,h)
            win.Size=UDim2.fromOffset(220,37+h)
        end
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
        task.defer(resize)
        arrow.MouseButton1Click:Connect(function()
            expanded=not expanded
            arrow.Text=expanded and "▼" or "▶"
            resize()
        end)

        local dragging=false
        local startMouse,startPos
        header.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging=true
                startMouse=input.Position
                startPos=win.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                local d=input.Position-startMouse
                win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
        end)

        UI.Pages.Vehicle=page
        UI.Windows.Vehicle=win
    end

    ------------------------------------------------------------------------
    -- Shared ••• settings panel owner.
    -- It is positioned ONCE under Combat and then the user is free to drag it.
    -- No per-frame position writes = no blinking/fighting between modules.
    ------------------------------------------------------------------------
    UI.ActiveDockedPanel=nil
    local dragInstalled=setmetatable({}, {__mode="k"})

    local function viewport()
        local cam=Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920,1080)
    end

    local function clampPanel(panel)
        if not panel or not panel.Parent then return end
        local v=viewport()
        local p=panel.AbsolutePosition
        local s=panel.AbsoluteSize
        local dx,dy=0,0
        if p.X<4 then dx=4-p.X end
        if p.Y<4 then dy=4-p.Y end
        if p.X+s.X>v.X-4 then dx=(v.X-4)-(p.X+s.X) end
        if p.Y+36>v.Y-4 then dy=(v.Y-4)-(p.Y+36) end
        if dx~=0 or dy~=0 then
            panel.Position=UDim2.new(panel.Position.X.Scale,panel.Position.X.Offset+dx,panel.Position.Y.Scale,panel.Position.Y.Offset+dy)
        end
    end

    local function placeDockedPanel(panel)
        if not panel or not panel.Parent then return end
        local combat=UI.Windows.Combat
        if not combat then return end
        local v=viewport()
        local ps=panel.AbsoluteSize
        local x=math.clamp(combat.AbsolutePosition.X,4,math.max(4,v.X-math.max(ps.X,214)-4))
        local y=combat.AbsolutePosition.Y+combat.AbsoluteSize.Y+10
        if y+math.max(ps.Y,44)>v.Y-4 then
            y=math.max(4,v.Y-math.max(ps.Y,44)-4)
        end
        panel.Position=UDim2.fromOffset(x,y)
    end

    local function makePanelDraggable(panel)
        if not panel or dragInstalled[panel] then return end
        dragInstalled[panel]=true
        panel.Active=true

        local dragging=false
        local startMouse,startPos
        panel.InputBegan:Connect(function(input)
            if input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            local localX=input.Position.X-panel.AbsolutePosition.X
            local localY=input.Position.Y-panel.AbsolutePosition.Y
            -- Header is the top 36 px. Leave the far-right close-button area alone.
            if localY>=0 and localY<=36 and localX>=0 and localX<panel.AbsoluteSize.X-34 then
                dragging=true
                startMouse=input.Position
                startPos=panel.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                local d=input.Position-startMouse
                panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 and dragging then
                dragging=false
                clampPanel(panel)
            end
        end)
    end

    function UI.CloseDockedPanel(panel)
        local current=UI.ActiveDockedPanel
        if panel and current~=panel then return end
        UI.ActiveDockedPanel=nil
        if current and current.Parent then
            pcall(function() current:Destroy() end)
        end
    end

    function UI.OpenDockedPanel(panel)
        if not panel then return end
        if UI.ActiveDockedPanel and UI.ActiveDockedPanel~=panel and UI.ActiveDockedPanel.Parent then
            pcall(function() UI.ActiveDockedPanel:Destroy() end)
        end
        UI.ActiveDockedPanel=panel
        panel.Parent=UI.Gui
        panel.Visible=UI.Main.Visible==true
        makePanelDraggable(panel)
        task.defer(placeDockedPanel,panel)
    end

    RunService.RenderStepped:Connect(function()
        local panel=UI.ActiveDockedPanel
        if panel and panel.Parent then
            -- Visibility only. Never rewrite Position here.
            panel.Visible=UI.Main.Visible==true
        elseif panel then
            UI.ActiveDockedPanel=nil
        end
    end)
end
