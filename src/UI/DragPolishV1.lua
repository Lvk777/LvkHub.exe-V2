-- Adds a smooth drag guard so windows/panels do not jump when dragged against the top edge.
-- It does not continuously pin positions; it only participates while the user is actively dragging.
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
                dragging=true
                startMouse=input.Position
                startPos=frame.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                local d=input.Position-startMouse
                local v=viewport()
                local x=startPos.X.Offset+d.X
                local y=startPos.Y.Offset+d.Y
                -- Smooth edge stop instead of allowing a negative position and snapping later.
                x=math.clamp(x,-frame.AbsoluteSize.X+36,v.X-36)
                y=math.max(0,y)
                frame.Position=UDim2.fromOffset(x,y)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
        end)
    end

    local function scan()
        for _,w in pairs(UI.Windows or {}) do
            local h=w and w:FindFirstChild("Header")
            if w and h then attach(w,h) end
        end
        local target=UI.Gui:FindFirstChild("LvkHubDummyTargetInfo")
        if target then attach(target,target:FindFirstChild("Header") or target) end
        local preview=UI.Gui:FindFirstChild("LvkHubVisualsDummyPreview")
        if preview then attach(preview,preview:FindFirstChild("Header") or preview) end
        local panel=UI.ActiveDockedPanel
        if panel then attach(panel,panel) end
    end

    task.defer(scan)
    task.spawn(function()
        while task.wait(.20) do scan() end
    end)
end
