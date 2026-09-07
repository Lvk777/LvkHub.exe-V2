-- Popup drag polish: option panels move ONLY from their top title/header area.
-- Sliders/color bars never drag the whole panel.
return function(State, UI)
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")
    local installed=setmetatable({}, {__mode="k"})

    local function viewport()
        local cam=Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920,1080)
    end

    local function attach(frame,handle)
        if not frame or not handle or installed[frame] then return end
        installed[frame]=true
        handle.Active=true
        local dragging=false
        local startMouse,startPos
        handle.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging=true; startMouse=input.Position; startPos=frame.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                local d=input.Position-startMouse
                local vp=viewport()
                local x=math.clamp(startPos.X.Offset+d.X,0,math.max(0,vp.X-frame.AbsoluteSize.X))
                local y=math.clamp(startPos.Y.Offset+d.Y,0,math.max(0,vp.Y-36))
                frame.Position=UDim2.fromOffset(x,y)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
        end)
    end

    local function panelHandle(panel)
        local header=panel:FindFirstChild("Header")
        if header and header:IsA("GuiObject") then return header end
        local best=nil
        for _,c in ipairs(panel:GetChildren()) do
            if c:IsA("TextLabel") and c.AbsolutePosition.Y<=panel.AbsolutePosition.Y+38 then
                if not best or c.AbsolutePosition.Y<best.AbsolutePosition.Y then best=c end
            end
        end
        return best
    end

    local function scan()
        local panel=UI.ActiveDockedPanel
        if panel and panel.Parent then
            local h=panelHandle(panel)
            if h then attach(panel,h) end
        end
    end

    task.defer(scan)
    task.spawn(function()
        while task.wait(.12) do scan() end
    end)
end
